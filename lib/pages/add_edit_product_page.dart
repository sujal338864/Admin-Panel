// add_edit_product_page.dart
// ignore_for_file: unnecessary_type_check, unnecessary_null_comparison
// kmmkmk
import 'dart:io';
import 'dart:typed_data';

import 'package:admin_panel/models/variant_models.dart';
import 'package:admin_panel/models/spec_models.dart'; // ⬅️ SpecSection / SpecField
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/variant_models.dart';
import '../services/api_service.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// ---------------------- Page ----------------------
class AddEditProductPage extends StatefulWidget {
  final int? productId; // if provided → edit mode
  const AddEditProductPage({Key? key, this.productId}) : super(key: key);

  @override
  State<AddEditProductPage> createState() => _AddEditProductPageState();
}

class _AddEditProductPageState extends State<AddEditProductPage> {
  final _formKey = GlobalKey<FormState>();

  // basic product fields
  String name = '';
  String description = '';
  double price = 0.0;
  double offerPrice = 0.0;
  int stock = 0;
  int quantity = 1;

  int? selectedCategoryId;
  int? selectedSubcategoryId;
  int? selectedBrandId;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final offerPriceController = TextEditingController();
  final quantityController = TextEditingController();
  final parentVideoController = TextEditingController(); // parent video

  // Parent images
  List<File> imageFiles = [];
  List<Uint8List> imageBytes = [];
  List<String> parentImageUrls = [];

  bool isSaving = false;
  bool isLoading = false;
  bool isChildProduct = false;

  // data lists
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> filteredSubcategories = [];
  List<Map<String, dynamic>> filteredBrands = [];
  List<Map<String, dynamic>> brands = [];

  // Variant types / values loaded from API
  List<Map<String, dynamic>> variantTypes = []; // [{id, name}]
  Map<int, List<Map<String, dynamic>>> variantValuesByType = {}; // typeId -> [{id, value}]

  // ----- Variant system data -----
  List<Map<String, dynamic>> selectedVariantPes = []; // [{ "typeId": 1, "name": "Color", "values": ["Red","Blue"] }]
  List<VariantCombo> combos = []; // generated child combinations

  // ----- SPECIFICATIONS MODULE -----
  List<SpecSection> specSections = [];
  Map<int, TextEditingController> specControllers = {}; // fieldId -> controller
  bool isLoadingSpecs = false;
int? parentProductId;

final ScrollController _pageScrollCtrl = ScrollController();

Map<String, dynamic> normalizeSubcategory(Map<String, dynamic> s) {
  return {
    'SubcategoryID': _toIntSafe(s['SubcategoryID'] ?? s['subcategory_id']),
    'Name': s['Name'] ?? s['name'] ?? 'Unnamed',
    'CategoryID': _toIntSafe(s['CategoryID'] ?? s['category_id']),
  };
}


void _filterBrandsForSubcategory() {
  if (selectedSubcategoryId == null) {
    filteredBrands = [];
    selectedBrandId = null;
    return;
  }

  // Filter brands by subcategory
  filteredBrands = brands
      .where(
        (b) => _toIntSafe(b['SubcategoryID']) == selectedSubcategoryId,
      )
      .toList();

  // Remove duplicate brands
  final seen = <int>{};
  filteredBrands = filteredBrands.where((b) {
    final id = _toIntSafe(b['BrandID']);
    if (id == null) return false;
    if (seen.contains(id)) return false;
    seen.add(id);
    return true;
  }).toList();

  // If previously selected brand is not in list → reset
  final stillValid = filteredBrands.any(
    (b) => _toIntSafe(b['BrandID']) == selectedBrandId,
  );

  if (!stillValid) {
    selectedBrandId = null;
  }
}

int? _toIntSafe(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  try {
    return int.parse(v.toString());
  } catch (_) {
    return null;
  }
}

int? _getCategoryId(Map<String, dynamic> m) =>
    _toIntSafe(m['CategoryID'] ?? m['category_id']);

int? _getSubcategoryId(Map<String, dynamic> m) =>
    _toIntSafe(m['SubcategoryID'] ?? m['subcategory_id']);

int? _getBrandId(Map<String, dynamic> m) =>
    _toIntSafe(m['BrandID'] ?? m['brand_id']);

@override
void initState() {
  super.initState();
   debugPrint("🟡 AddEditProductPage opened with productId = ${widget.productId}");
  _initAll();
}
Future<void> _initAll() async {
  setState(() => isLoading = true);

  await loadData();

  if (widget.productId != null) {
    await loadExistingProduct(widget.productId!);
  } else {
    // create mode
    isChildProduct = false;
    parentProductId = null;
    await _loadSpecTemplateAndValues();
  }

  if (mounted) setState(() => isLoading = false);
}

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    offerPriceController.dispose();
    quantityController.dispose();
    parentVideoController.dispose();

    for (final c in specControllers.values) {
      c.dispose();
    }
  _pageScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
  try {
    final cats = await ApiService.getCategories();
    final brs = await ApiService.getBrands();
    final vTypes = await ApiService.getVariantTypes();

   final normalizedVT = <Map<String, dynamic>>[];

if (vTypes is List) {
  for (final e in vTypes) {
    final id = _toIntSafe(
      e['variant_type_id'] ??
      e['VariantTypeID'] ??
      e['id']
    );

    final name =
        e['variant_name'] ??
        e['VariantName'] ??
        e['variant_type'] ??
        e['name'] ??
        'Variant';

    if (id != null) {
      normalizedVT.add({
        'id': id,
        'name': name.toString(),
      });
    }
  }
}


    if (!mounted) return;

    setState(() {
      categories = cats.map<Map<String, dynamic>>((c) => {
            'CategoryID': _toIntSafe(c['CategoryID'] ?? c['category_id']),
            'Name': c['Name'] ?? c['name'] ?? 'Unnamed',
          }).toList();

      brands = brs.map<Map<String, dynamic>>((b) => {
            'BrandID': _toIntSafe(b['BrandID'] ?? b['brand_id']),
            'Name': b['Name'] ?? b['name'] ?? 'Unnamed',
            'SubcategoryID':
                _toIntSafe(b['SubcategoryID'] ?? b['subcategory_id']),
          }).toList();

      variantTypes = normalizedVT;
    });
  } catch (e) {
    debugPrint('❌ loadData error: $e');
  }
}

Future<void> loadExistingProduct(int id) async {
  if (!mounted) return;

  setState(() => isLoading = true);

  try {
    final resp = await ApiService.getProductWithVariants(id);
    if (resp == null) throw Exception("Empty response");

    final Map<String, dynamic> parent =
        Map<String, dynamic>.from(resp["parent"] ?? {});
  
    final List<dynamic> children = resp["children"] ?? [];
  final int? parentIdFromApi = _toIntSafe(parent['parent_product_id']);

isChildProduct = parentIdFromApi != null;
parentProductId = isChildProduct ? parentIdFromApi : widget.productId;

debugPrint("🧠 isChildProduct = $isChildProduct");
debugPrint("🧠 parentProductId for specs = $parentProductId");

    debugPrint("🧠 isChildProduct = $isChildProduct");

    debugPrint("🟢 Editing productId=$id");
    debugPrint("🟢 Parent: $parent");

    // ---------- BASIC FIELDS ----------
    nameController.text = parent["name"]?.toString() ?? "";
    descriptionController.text = parent["description"]?.toString() ?? "";
    priceController.text = parent["price"]?.toString() ?? "0";
    offerPriceController.text = parent["offer_price"]?.toString() ?? "0";
    quantityController.text = parent["quantity"]?.toString() ?? "1";
    stock = _toIntSafe(parent["stock"]) ?? 0;

    parentVideoController.text =
        parent["video_url"]?.toString() ?? "";

    // ---------- CATEGORY / SUBCATEGORY / BRAND ----------
    selectedCategoryId = _toIntSafe(parent['category_id']);
    selectedSubcategoryId = _toIntSafe(parent['subcategory_id']);
    selectedBrandId = _toIntSafe(parent['brand_id']);

    // 🔥 LOAD SUBCATEGORIES FIRST (FIXES NULL ISSUE)
    if (selectedCategoryId != null) {
      final subs = await ApiService.getSubcategories(selectedCategoryId!);

      filteredSubcategories = subs.map<Map<String, dynamic>>((s) => {
            'SubcategoryID':
                _toIntSafe(s['SubcategoryID'] ?? s['subcategory_id']),
            'Name': s['Name'] ?? s['name'] ?? 'Unnamed',
            'CategoryID':
                _toIntSafe(s['CategoryID'] ?? s['category_id']),
          }).toList();
    }

    _filterBrandsForSubcategory();


    // ---------- IMAGES ----------
    parentImageUrls.clear();
    imageFiles.clear();
    imageBytes.clear();

    if (parent["images"] is List) {
      for (final img in parent["images"]) {
        final url = img["image_url"]?.toString();
        if (url != null && url.isNotEmpty) {
          parentImageUrls.add(url);
        }
      }
    }

    // ---------- VARIANTS ----------
   // ---------- VARIANTS ----------
combos.clear();
selectedVariantPes.clear();

for (final ch in children) {
  final Map chMap = ch as Map;

  combos.add(
    VariantCombo(
      selections: {},
      price: double.tryParse(chMap["price"]?.toString() ?? "") ?? 0,
      offerPrice:
          double.tryParse(chMap["offer_price"]?.toString() ?? "") ?? 0,
      stock: _toIntSafe(chMap["stock"]) ?? 0,
      sku: chMap["sku"]?.toString() ?? "",
      description: chMap["description"]?.toString() ?? "",
      useParentImages: true,
      videoUrl: chMap["video_url"]?.toString() ?? "",
    ),
  );
}
// 🔥 NOW parentProductId IS READY → load specs with values
await _loadSpecTemplateAndValues();

    debugPrint("🟣 Variants loaded: ${combos.length}");
    setState(() {});
  } catch (e, st) {
    debugPrint("❌ loadExistingProduct ERROR: $e");
    debugPrintStack(stackTrace: st);
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}
Future<void> _loadSpecTemplateAndValues() async {
  for (final c in specControllers.values) {
    c.dispose();
  }
  specControllers.clear();
  specSections.clear();

  if (!mounted) return;

  setState(() => isLoadingSpecs = true);

  try {
    final sections = await ApiService.getSpecSectionsWithFields();

   Map<int, String> existingValues = {};

if (parentProductId != null) {
  // 1️⃣ Load parent specs
  final parentVals = await ApiService.getProductSpecs(parentProductId!);

  // 2️⃣ If this is child → load its specs too
  Map<int, String> childVals = {};
  if (isChildProduct && widget.productId != null) {
    childVals = await ApiService.getProductSpecs(widget.productId!);
  }

  // 3️⃣ Merge → child overrides parent
  existingValues = Map.from(parentVals);
  existingValues.addAll(childVals);

  debugPrint("🟢 Parent Specs = $parentVals");
  debugPrint("🟢 Child Specs  = $childVals");
  debugPrint("🟢 FINAL MERGED = $existingValues");
}




    final ctrls = <int, TextEditingController>{};

    for (final sec in sections) {
      for (final field in sec.fields) {
        ctrls[field.fieldId] = TextEditingController(
          text: existingValues[field.fieldId] ?? '',
        );
      }
    }
    debugPrint("🧪 _loadSpecTemplateAndValues parentProductId = $parentProductId");

debugPrint("🔥 Spec sections fetched = ${sections.length}");
debugPrint("🔥 Sections = $sections");


    if (!mounted) return;

    setState(() {
      specSections = sections;
      specControllers = ctrls;
    });
  } catch (e, st) {
    debugPrint("❌ load specs error: $e");
    debugPrintStack(stackTrace: st);
  } finally {
    if (mounted) setState(() => isLoadingSpecs = false);
  }
}



  // ----------------- IMAGE PICK / COMPRESS -----------------
  Future<void> pickParentImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final resized = img.copyResize(decoded, width: 800);
          final compressedBytes =
              Uint8List.fromList(img.encodeJpg(resized, quality: 75));
          setState(() => imageBytes.add(compressedBytes));
        } else {
          setState(() => imageBytes.add(bytes));
        }
      } else {
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          picked.path,
          quality: 75,
          minWidth: 800,
        );
        if (compressedBytes != null) {
          final compressedFile = File('${picked.path}_compressed.jpg')
            ..writeAsBytesSync(compressedBytes);
          setState(() => imageFiles.add(compressedFile));
        } else {
          setState(() => imageFiles.add(File(picked.path)));
        }
      }
    } catch (e) {
      debugPrint('Parent image pick error: $e');
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => imageBytes.add(bytes));
      } else {
        setState(() => imageFiles.add(File(picked.path)));
      }
    }
  }
  

  /// CHILD VARIANT MULTI IMAGE
  Future<void> pickComboImage(VariantCombo combo) async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      combo.extraImages ??= [];

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final resized = img.copyResize(decoded, width: 800);
          final compressedBytes =
              Uint8List.fromList(img.encodeJpg(resized, quality: 75));
          combo.extraImages!.add(compressedBytes);
        } else {
          combo.extraImages!.add(bytes);
        }
      } else {
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          picked.path,
          quality: 75,
          minWidth: 800,
        );
        if (compressedBytes != null) {
          final f = File('${picked.path}_compressed.jpg')
            ..writeAsBytesSync(compressedBytes);
          combo.extraImages!.add(f);
        } else {
          combo.extraImages!.add(File(picked.path));
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint('Combo image pick error: $e');

      combo.extraImages ??= [];
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        combo.extraImages!.add(bytes);
      } else {
        combo.extraImages!.add(File(picked.path));
      }

      setState(() {});
    }
  }

  void _removeComboImage(VariantCombo combo, int index) {
    if (combo.extraImages == null) return;
    if (index < 0 || index >= combo.extraImages!.length) return;

    setState(() {
      combo.extraImages!.removeAt(index);
    });
  }

  /// ---------------------- VARIANT VALUES ----------------------
  Future<void> fetchValuesForType(int typeId) async {
    debugPrint("🔵 fetchValuesForType CALLED for typeId = $typeId");

    try {
      debugPrint("📡 Calling ApiService.getVariantValuesByType() ...");
      final all = await ApiService.getVariantValuesByType(typeId);

      debugPrint("📥 FULL variants response (${all.length} items):");
      for (var v in all) {
        debugPrint("   ➡ ${v.toString()}");
      }

      final filtered = all.where((v) {
        final vtId = int.tryParse(v['VariantTypeID'].toString()) ?? 0;
        return vtId == typeId;
      }).toList();

      debugPrint("🔍 Filtered variants for typeId=$typeId → ${filtered.length} items");

      final normalized = filtered.map((item) {
        final id = item['VariantID'];
        final rawVal = item['Variant'];

        debugPrint("   🔧 Normalizing: id=$id  |  value=$rawVal");

        return {
          'id': id,
          'value': rawVal?.toString() ?? '',
        };
      }).toList();

      debugPrint("✅ Final normalized variants list (${normalized.length} items):");
      for (var n in normalized) {
        debugPrint("   ✔ $n");
      }

      setState(() {
        variantValuesByType[typeId] = normalized;
      });

      debugPrint("💾 Saved to variantValuesByType[$typeId]");
    } catch (e, st) {
      debugPrint("❌ ERROR loading variants for typeId $typeId");
      debugPrint("❌ Error: $e");
      debugPrint("❌ Stacktrace: $st");

      setState(() => variantValuesByType[typeId] = []);
    }
  }

  void loadVariantTypes() async {
    debugPrint("🟦 Loading Variant TYPES...");

    try {
      variantTypes = await ApiService.getVariantTypes();
      debugPrint("🟩 Loaded ${variantTypes.length} variant types");
    } catch (e) {
      debugPrint("❌ ERROR loading variant types: $e");
    }

    setState(() {});
  }

  // ----------------- UI: Select Variant Types -----------------
  Future<void> openVariantTypeSelector() async {
    final currentSet = selectedVariantPes.map((p) => p['name'].toString()).toSet();
    final selectedMap = <int, bool>{};
    for (final vt in variantTypes) {
      selectedMap[vt['id'] as int] = currentSet.contains(vt['name']);
    }

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Select Variant Types'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: variantTypes.map((vt) {
                final id = vt['id'] as int;
                final name = vt['name']?.toString() ?? 'Variant';
                return CheckboxListTile(
                  title: Text(name),
                  value: selectedMap[id] ?? false,
                  onChanged: (v) => setState(() => selectedMap[id] = v ?? false),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newlySelected = <Map<String, dynamic>>[];
                for (final vt in variantTypes) {
                  final id = vt['id'] as int;
                  final name = vt['name']?.toString() ?? 'Variant';
                  if (selectedMap[id] == true) {
                    final existing = selectedVariantPes.firstWhere(
                      (e) => e['name'] == name || _toIntSafe(e['typeId']) == id,
                      orElse: () => {},
                    );
                    if (existing.isNotEmpty) {
                      newlySelected.add({
                        'typeId': id,
                        'name': name,
                        'values': List<String>.from(existing['values'] ?? []),
                      });
                    } else {
                      newlySelected.add(
                        {
                          'typeId': id,
                          'name': name,
                          'values': <String>[],
                        },
                      );
                    }
                  }
                }

                setState(() => selectedVariantPes = newlySelected);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  // ----------------- UI: Select values for a type -----------------
  Future<void> openValuesSelector(int pesIndex) async {
    final pes = selectedVariantPes[pesIndex];
    final typeId = _toIntSafe(pes['typeId']) ?? -1;
    if (typeId == -1) return;

    await fetchValuesForType(typeId);
    final list = variantValuesByType[typeId] ?? [];

    final selectedValuesSet = <String>{};
    final existing = pes['values'] ?? [];
    for (final e in existing) {
      selectedValuesSet.add(e.toString());
    }

    final tempMap = <String, bool>{};
    for (final v in list) {
      final val = v['value'].toString();
      tempMap[val] = selectedValuesSet.contains(val);
    }

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Select values for ${pes['name']}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: list.map((v) {
                final val = v['value'].toString();
                return CheckboxListTile(
                  title: Text(val),
                  value: tempMap[val] ?? false,
                  onChanged: (ch) => setState(() => tempMap[val] = ch ?? false),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final chosen =
                    tempMap.entries.where((e) => e.value).map((e) => e.key).toList();
                setState(() => selectedVariantPes[pesIndex]['values'] = chosen);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  // ----------------- Combination generator (cartesian) -----------------
  void generateCombinations() {
    combos.clear();
    if (selectedVariantPes.isEmpty) {
      setState(() {});
      return;
    }

    final lists = <List<String>>[];
    for (final p in selectedVariantPes) {
      final raw = p['values'] ?? [];
      final vals = <String>[];
      if (raw is List) {
        for (final v in raw) {
          vals.add(v?.toString() ?? '');
        }
      }
      lists.add(vals.isEmpty ? [''] : vals);
    }

    final prod = _cartesian(lists);
    for (final p in prod) {
      final sel = <String, String>{};
      for (var i = 0; i < p.length; i++) {
        final key =
            selectedVariantPes[i]['name']?.toString() ?? 'Variant${i + 1}';
        sel[key] = p[i];
      }
      combos.add(VariantCombo(selections: sel));
    }
    setState(() {});
  }

  List<List<T>> _cartesian<T>(List<List<T>> lists) {
    List<List<T>> result = [[]];
    for (var list in lists) {
      List<List<T>> temp = [];
      for (var r in result) {
        for (var item in list) {
          temp.add([...r, item]);
        }
      }
      result = temp;
    }
    return result;
  }

  // ----------------- SPEC HELPERS -----------------
Map<int, String> _buildDirectSpecMap() {
  final Map<int, String> map = {};

  for (final sec in specSections) {
    for (final field in sec.fields) {
      final ctrl = specControllers[field.fieldId];
      if (ctrl == null) continue;

      final value = ctrl.text.trim();
      if (value.isEmpty) continue;

      map[field.fieldId] = value;
    }
  }

  return map;
}


Widget _buildSpecificationSection() {
  return Card(
    margin: const EdgeInsets.only(top: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (isLoadingSpecs)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Loading specification template...'),
                ],
              ),
            )
         else if (specSections.isEmpty && !isLoadingSpecs)
  const Padding(
    padding: EdgeInsets.all(8.0),
    child: Text(
      'No specification template configured yet.',
      style: TextStyle(color: Colors.grey),
    ),
  )

          else
            Column(
              children: specSections.map((sec) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    Text(
                      sec.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),

                    ...sec.fields.map((field) {
                      final ctrl = specControllers[field.fieldId];

                      if (ctrl == null) return const SizedBox.shrink();

                      // 🔹 DROPDOWN FIELD
                      if (field.inputType == 'select' &&
                          field.options.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: DropdownButtonFormField<String>(
  value: ctrl.text.isEmpty ? null : ctrl.text,
  decoration: InputDecoration(
    labelText: field.name,
    border: const OutlineInputBorder(),
  ),
  items: field.options
      .map(
        (opt) => DropdownMenuItem(
          value: opt,
          child: Text(opt),
        ),
      )
      .toList(),
  onChanged: isChildProduct
      ? null
      : (v) => ctrl.text = v ?? '',
)

                        );
                      }
                      

                      // 🔹 TEXT FIELD (DEFAULT)
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: TextFormField(
  controller: ctrl,
  enabled: true,
  decoration: InputDecoration(
    labelText: field.name,
    border: const OutlineInputBorder(),
  ),
)

                      );
                    }).toList(),
  //                   if (isChildProduct)
  // Padding(
  //   padding: const EdgeInsets.only(bottom: 8),
  //   child: Text(
  //     'Specifications are inherited from parent product',
  //     style: TextStyle(
  //       color: Colors.grey,
  //       fontStyle: FontStyle.italic,
  //     ),
  //   ),
  // ),

                  ],
                );
              }).toList(),
            ),
            if (isChildProduct)
  Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      'Editing CHILD specifications',
      style: TextStyle(
        color: Colors.orange,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),

        ],
      ),
    ),
  );
}

List<Map<String, dynamic>> _buildVariantsPayload() {
  return combos.map((combo) {
    return {
      'selections': combo.selections.entries.map((e) {
        return {
          'value': e.value,
        };
      }).toList(),
      'price': combo.price,
      'offerPrice': combo.offerPrice,
      'stock': combo.stock,
      'quantity': quantity,
      'sku': combo.sku,
      'description': combo.description,
      'videoUrl': combo.videoUrl,
      'combinationKey': combo.selections.values.join('-'),
    };
  }).toList();
}
List<Map<String, dynamic>> _buildChildVariantsImages() {
  return combos.map((combo) {
    return {
      'comboKey': combo.selections.values.join('-'),
      'useParentImages': combo.useParentImages,
      'images': combo.extraImages ?? [],
    };
  }).toList();
}


Future<void> saveProduct() async {

//   // 🔴 ENSURE SPEC CONTROLLERS ARE READY
// if (specSections.isNotEmpty && specControllers.isEmpty) {
//   debugPrint("⚠️ Spec controllers empty → rebuilding");
//   await _loadSpecTemplateAndValues();
// }
// final parentSpecs = _collectSpecsToSave();
// debugPrint("🧪 COLLECTED SPECS = $parentSpecs");

  if (!_formKey.currentState!.validate()) return;

  setState(() => isSaving = true);

  try {
    int? finalProductId;

    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final price = double.tryParse(priceController.text) ?? 0.0;
    final offerPrice = double.tryParse(offerPriceController.text) ?? 0.0;
    final quantity = int.tryParse(quantityController.text) ?? 1;

    final parentJson = {
      'name': name,
      'description': description,
      'categoryId': selectedCategoryId,
      'subcategoryId': selectedSubcategoryId,
      'brandId': selectedBrandId,
      'price': price,
      'offerPrice': offerPrice,
      'quantity': quantity,
      'stock': stock,
      'videoUrl': parentVideoController.text.trim(),
    };

    // 🔥 BUILD CHILD DATA
    final variantsPayload = _buildVariantsPayload();
    final childVariants = _buildChildVariantsImages();

    // ---------------- CREATE ----------------
    if (widget.productId == null) {
      final resp = await ApiService.uploadProductWithVariants(
        parentJson: parentJson,
        variantsPayload: variantsPayload,   // ✅ NOT EMPTY
        parentImageFiles: imageFiles,
        parentImageBytes: imageBytes,
        childVariants: childVariants,       // ✅ NOT EMPTY
      );

  finalProductId = resp['parentProductId'];

final List<dynamic> childIds = resp['childProductIds'] ?? [];

for (int i = 0; i < combos.length && i < childIds.length; i++) {
  combos[i].childProductId = childIds[i];
}

debugPrint("🧠 Parent ID = $finalProductId");
debugPrint("🧠 Child IDs = $childIds");

    }
    // ---------------- UPDATE ----------------
    else {
      if (isChildProduct) {
        await ApiService.updateChildProduct(
          productId: widget.productId!,
          data: {
            'name': name,
            'price': price,
            'offerPrice': offerPrice,
            'quantity': quantity,
            'stock': stock,
            'sku': '',
          },
          images: imageFiles.isNotEmpty ? imageFiles : null,
        );
      } else {
        await ApiService.updateParentProduct(
          productId: widget.productId!,
          data: parentJson,
          images: imageFiles.isNotEmpty ? imageFiles : null,
        );
      }

      finalProductId = widget.productId;
    }

 // ================= SAVE SPECS (FINAL) =================
// ================= DIRECT SPEC SAVE =================

final Map<int, String> specsMap = _buildDirectSpecMap();

if (specsMap.isNotEmpty) {
  final specsList = specsMap.entries.map((e) => {
    'fieldId': e.key,
    'value': e.value,
  }).toList();

  await ApiService.saveProductSpecs(
    productId: isChildProduct
        ? widget.productId!          // save to child
        : (widget.productId ?? finalProductId!), // save to parent
    specs: specsList,
  );
}

if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Product saved successfully")),
  );
  Navigator.pop(context);
}

  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Save failed: $e")),
      );
    }
  } finally {
    if (mounted) setState(() => isSaving = false);
  }
}


  /// ---------------------- UI BUILD ----------------------
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'Add Product' : 'Edit Product'),
      ),
    body: SingleChildScrollView(
  controller: _pageScrollCtrl,

        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // Parent image picker
                ElevatedButton.icon(
                  onPressed: pickParentImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Pick Images (Parent)'),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // existing network images (optional – you can add preview if you want)
                      // ...parentImageUrls.map(
                      //   (url) => Padding(
                      //     padding: const EdgeInsets.all(4.0),
                      //     child: ClipRRect(
                      //       borderRadius: BorderRadius.circular(8),
                      //       child: Image.network(
                      //         url,
                      //         width: 100,
                      //         height: 100,
                      //         fit: BoxFit.cover,
                      //       ),
                      //     ),
                      //   ),
                      // ),

                      ...imageFiles.map(
                        (f) => Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              f,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      ...imageBytes.map(
                        (b) => Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              b,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Basic fields
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    prefixIcon: Icon(Icons.text_fields),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                // Parent YouTube URL
                TextFormField(
                  controller: parentVideoController,
                  decoration: const InputDecoration(
                    labelText: 'Parent Video URL (YouTube)',
                    prefixIcon: Icon(Icons.video_library),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Parent Price',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: offerPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Parent Offer Price',
                        prefixIcon: Icon(Icons.local_offer),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Stock (parent)',
                    prefixIcon: Icon(Icons.inventory),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => stock = int.tryParse(value) ?? 0,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    prefixIcon: Icon(Icons.production_quantity_limits),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Category / Subcategory / Brand
DropdownButtonFormField<int>(
  decoration: const InputDecoration(
    labelText: 'Category',
    border: OutlineInputBorder(),
  ),
  value: categories.any(
    (c) => _getCategoryId(c) == selectedCategoryId,
  )
      ? selectedCategoryId
      : null,
  items: categories.map((c) {
    final id = _getCategoryId(c);
    if (id == null) return null;
    return DropdownMenuItem(
      value: id,
      child: Text(c['Name'].toString()),
    );
  }).whereType<DropdownMenuItem<int>>().toList(),
  onChanged: (v) => onCategoryChanged(v!),
),



                const SizedBox(height: 12),
            DropdownButtonFormField<int>(
  decoration: const InputDecoration(
    labelText: 'Subcategory',
    border: OutlineInputBorder(),
  ),
  value: filteredSubcategories.any(
    (s) => _getSubcategoryId(s) == selectedSubcategoryId,
  )
      ? selectedSubcategoryId
      : null,
  items: filteredSubcategories.map((s) {
    final id = _getSubcategoryId(s);
    if (id == null) return null;
    return DropdownMenuItem(
      value: id,
      child: Text(s['Name'].toString()),
    );
  }).whereType<DropdownMenuItem<int>>().toList(),
  onChanged: onSubcategoryChanged,
),


                const SizedBox(height: 12),
DropdownButtonFormField<int>(
  decoration: const InputDecoration(
    labelText: 'Brand',
    border: OutlineInputBorder(),
  ),
  value: filteredBrands.any(
    (b) => _getBrandId(b) == selectedBrandId,
  )
      ? selectedBrandId
      : null,
  items: filteredBrands.map((b) {
    final id = _getBrandId(b);
    if (id == null) return null;
    return DropdownMenuItem(
      value: id,
      child: Text(b['Name'].toString()),
    );
  }).whereType<DropdownMenuItem<int>>().toList(),
  onChanged: (v) => setState(() => selectedBrandId = v),
),




                const SizedBox(height: 20),

                // VARIANT HEADER
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Variant Types & Values',
                        style:
                            TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: openVariantTypeSelector,
                      child: const Text('Select Variant Types'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: generateCombinations,
                      child: const Text('Generate Combinations'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Selected variant PES
                ...selectedVariantPes.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final pes = entry.value;
                  final valuesList = <String>[];
                  if (pes['values'] is List) {
                    for (final v in pes['values']) {
                      valuesList.add(v?.toString() ?? '');
                    }
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  pes['name']?.toString() ?? 'Variant',
                                  style:
                                      const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              TextButton(
                                onPressed: () => openValuesSelector(idx),
                                child: const Text('Select values'),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setState(() {
                                  selectedVariantPes.removeAt(idx);
                                  combos.clear();
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: valuesList
                                .map((v) => Chip(label: Text(v)))
                                .toList(),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  String newVal = '';
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Add custom value'),
                                      content: TextField(
                                        onChanged: (t) => newVal = t,
                                        decoration:
                                            const InputDecoration(hintText: 'Value'),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (newVal.trim().isNotEmpty) {
                                              final list =
                                                  List<String>.from(
                                                      selectedVariantPes[idx]
                                                              ['values'] ??
                                                          []);
                                              list.add(newVal.trim());
                                              setState(() =>
                                                  selectedVariantPes[idx]
                                                      ['values'] = list);
                                            }
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Add'),
                                        )
                                      ],
                                    ),
                                  );
                                },
                                child: const Text('+ Add Custom Value'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 16),

                if (combos.isNotEmpty)
                  const Text(
                    'Generated Variant Combinations',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 8),

                // Variant combinations + MULTI IMAGE + VIDEO
                ...combos.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final combo = entry.value;
                  final extraImgs = combo.extraImages ?? [];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            combo.selections.entries
                                .map((e) => '${e.key}: ${e.value}')
                                .join(' | '),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Button + thumbnails row
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => pickComboImage(combo),
                                icon: const Icon(Icons.photo),
                                label: const Text('Add Image'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (extraImgs.isNotEmpty)
                            SizedBox(
                              height: 90,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: extraImgs.length,
                                itemBuilder: (context, i) {
                                  final imgObj = extraImgs[i];
                                  Widget imageWidget;

                                  if (imgObj is Uint8List) {
                                    imageWidget = Image.memory(
                                      imgObj,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    );
                                  } else if (imgObj is File) {
                                    imageWidget = Image.file(
                                      imgObj,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    );
                                  } else {
                                    imageWidget =
                                        const Icon(Icons.image_not_supported);
                                  }

                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(right: 8.0),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: imageWidget,
                                        ),
                                        Positioned(
                                          top: -8,
                                          right: -8,
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              size: 18,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _removeComboImage(combo, i),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: combo.price.toString(),
                                  decoration: const InputDecoration(
                                    labelText: 'Price',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) =>
                                      combo.price = double.tryParse(v) ?? 0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue:
                                      combo.offerPrice.toString(),
                                  decoration: const InputDecoration(
                                    labelText: 'Offer Price',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => combo.offerPrice =
                                      double.tryParse(v) ?? 0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: combo.stock.toString(),
                                  decoration: const InputDecoration(
                                    labelText: 'Stock',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) =>
                                      combo.stock = int.tryParse(v) ?? 0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: combo.sku,
                                  decoration: const InputDecoration(
                                    labelText: 'SKU',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (v) => combo.sku = v,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: combo.description,
                            decoration: const InputDecoration(
                              labelText: 'Variant Description',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            onChanged: (v) => combo.description = v,
                          ),
                          const SizedBox(height: 8),

                          // Variant YouTube URL
                          TextFormField(
                            initialValue: combo.videoUrl ?? '',
                            decoration: const InputDecoration(
                              labelText: 'Variant Video URL (YouTube)',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => combo.videoUrl = v.trim(),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Text('Use parent images:'),
                              const SizedBox(width: 8),
                              Switch(
                                value: combo.useParentImages,
                                onChanged: (v) =>
                                    setState(() => combo.useParentImages = v),
                              ),
                              const Spacer(),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    setState(() => combos.removeAt(idx)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 24),

                // Specifications section
                _buildSpecificationSection(),

                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.save),
                    label: Text(
                      widget.productId == null
                          ? 'Save Product'
                          : 'Update Product',
                      style: const TextStyle(fontSize: 18),
                    ),
                    onPressed: isSaving ? null : saveProduct,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // helpers reused from earlier code for category/subcategory change (unchanged)
void onCategoryChanged(int value) async {
  setState(() {
    selectedCategoryId = value;
    selectedSubcategoryId = null;
    selectedBrandId = null;
    filteredSubcategories = [];
    filteredBrands = [];
  });

  final subs = await ApiService.getSubcategories(value);

  if (!mounted) return;

 setState(() {
  filteredSubcategories = subs.map<Map<String, dynamic>>((s) => {
        'SubcategoryID':
            _toIntSafe(s['SubcategoryID'] ?? s['subcategory_id']),
        'Name': s['Name'] ?? s['name'] ?? 'Unnamed',
        'CategoryID': _toIntSafe(s['CategoryID'] ?? s['category_id']),
      }).toList();
});

}


  void onSubcategoryChanged(int? value) async {
    if (value == null) return;

    setState(() {
      selectedSubcategoryId = value;
      selectedBrandId = null;
    });

    filteredBrands = brands
        .where((b) => _toIntSafe(b["SubcategoryID"]) == value)
        .toList();

    // REMOVE DUPLICATE BRANDS
    final seen = <int>{};
    filteredBrands = filteredBrands.where((b) {
      final id = _toIntSafe(b["BrandID"]);
      if (id == null) return false;
      if (seen.contains(id)) return false;
      seen.add(id);
      return true;
    }).toList();

    setState(() {});
  }
}
