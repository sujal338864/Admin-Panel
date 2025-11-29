// // ignore_for_file: use_build_context_synchronously

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// import '../services/api_service.dart';

// class CouponPage extends StatefulWidget {
//   const CouponPage({super.key});

//   @override
//   State<CouponPage> createState() => _CouponPageState();
// }

// class _CouponPageState extends State<CouponPage> {
//   List<Map<String, dynamic>> coupons = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     loadCoupons();
//   }

//   Future<void> loadCoupons() async {
//     setState(() => isLoading = true);
//     try {
//       final data = await ApiService.getCoupons();
//       setState(() {
//         coupons = data;
//         isLoading = false;
//       });
//     } catch (e) {
//       debugPrint('❌ Failed to load coupons: $e');
//       setState(() => isLoading = false);
//     }
//   }

//   Future<void> deleteCoupon(int id) async {
//     final success = await ApiService.deleteCoupon(id);
//     if (success) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Coupon deleted')),
//       );
//       loadCoupons();
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to delete')),
//       );
//     }
//   }

//   void openAddCouponForm() async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const AddCouponForm()),
//     );
//     if (result == true) {
//       loadCoupons(); // refresh if added
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Coupons'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: openAddCouponForm,
//           ),
//         ],
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : coupons.isEmpty
//               ? const Center(child: Text('No coupons found'))
//               : ListView.builder(
//                   itemCount: coupons.length,
//                   itemBuilder: (context, index) {
//                     final coupon = coupons[index];
//                     return Card(
//                       child: ListTile(
//                         title: Text(coupon['Code'] ?? 'No Code'),
//                         subtitle: Text(
//                           '${coupon['DiscountType']} - ${coupon['DiscountAmount']}',
//                         ),
//                         trailing: IconButton(
//                           icon: const Icon(Icons.delete, color: Colors.red),
//                           onPressed: () {
//                             deleteCoupon(coupon['CouponID'] as int);
//                           },
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//     );
//   }
// }


// class AddCouponForm extends StatefulWidget {
//   const AddCouponForm({super.key});

//   @override
//   State<AddCouponForm> createState() => _AddCouponFormState();
// }

// class _AddCouponFormState extends State<AddCouponForm> {
//   final _formKey = GlobalKey<FormState>();

//   String couponCode = '';
//   String discountType = 'Fixed';
//   double discountAmount = 0.0;
//   double minimumPurchase = 0.0;
//   DateTime? startDate;
//   DateTime? endDate;
//   String status = 'Active';

//   int? selectedCategoryId;
//   int? selectedSubcategoryId;
//   int? selectedProductId;

//   List<Map<String, dynamic>> categories = [];
//   List<Map<String, dynamic>> subcategories = [];
//   List<Map<String, dynamic>> products = [];

//   List<Map<String, dynamic>> filteredSubcategories = [];
//   List<Map<String, dynamic>> filteredProducts = [];

//   bool isSaving = false;

//   @override
//   void initState() {
//     super.initState();
//     loadDropdownData();
//   }

//  Future<void> loadDropdownData() async {
//   final cats = await ApiService.getCategories();
//   final prods = await ApiService.getProducts();

//   List<Map<String, dynamic>> subs = [];
//   if (cats.isNotEmpty) {
//     // Fetch subcategories of the first category by default
//     subs = await ApiService.getSubcategories(cats.first['CategoryID']);
//   }

//   if (!mounted) return;

//   setState(() {
//     categories = List<Map<String, dynamic>>.from(cats);
//     subcategories = List<Map<String, dynamic>>.from(subs);
//     products = List<Map<String, dynamic>>.from(prods);
//     filteredSubcategories = subcategories;
//     filteredProducts = products;
//   });
// }

//   Future<void> pickStartDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2030),
//     );
//     if (!mounted) return;
//     if (picked != null) {
//       setState(() => startDate = picked);
//     }
//   }

//   Future<void> pickEndDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2030),
//     );
//     if (!mounted) return;
//     if (picked != null) {
//       setState(() => endDate = picked);
//     }
//   }

//   Future<void> submit() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (startDate == null || endDate == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please pick start and end dates')),
//       );
//       return;
//     }

//     setState(() => isSaving = true);

//   final success = await ApiService.addCoupon(
//   code: couponCode,
//   discountType: discountType,
//   discountAmount: discountAmount,
//   minimumPurchase: minimumPurchase,
//   startDate: DateFormat('yyyy-MM-dd').format(startDate!),
//   endDate: DateFormat('yyyy-MM-dd').format(endDate!),
//   status: status,
//   categoryId: selectedCategoryId,
//   subcategoryId: selectedSubcategoryId,
//   productId: selectedProductId,
// );


//     if (!mounted) return;

//     setState(() => isSaving = false);

//     if (success) {
//       Navigator.pop(context, true);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to save coupon')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {

    
//   // Defensive filters:
// filteredSubcategories = selectedCategoryId == null
//     ? []
//     : subcategories
//         .where((s) =>
//             (s['CategoryID'] is int
//                 ? s['CategoryID']
//                 : int.tryParse('${s['CategoryID']}')) == selectedCategoryId)
//         .toList();

//  filteredSubcategories = subcategories
//         .where((s) => s['CategoryId'] == selectedCategoryId)
//         .toList();


// filteredProducts = selectedSubcategoryId == null
//     ? []
//     : products
//         .where((p) =>
//             (p['SubcategoryID'] is int
//                 ? p['SubcategoryID']
//                 : int.tryParse('${p['SubcategoryID']}')) == selectedSubcategoryId)
//         .toList();

//     return Scaffold(
//       appBar: AppBar(title: const Text('Add Coupon')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: SingleChildScrollView(
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 TextFormField(
//                   decoration: const InputDecoration(labelText: 'Coupon Code'),
//                   onChanged: (v) => couponCode = v,
//                   validator: (v) => v == null || v.isEmpty ? 'Required' : null,
//                 ),
//                 DropdownButtonFormField<String>(
//                   decoration: const InputDecoration(labelText: 'Discount Type'),
//                   value: discountType,
//                   items: const [
//                     DropdownMenuItem(value: 'Fixed', child: Text('Fixed')),
//                     DropdownMenuItem(value: 'Percentage', child: Text('Percentage')),
//                   ],
//                   onChanged: (v) => setState(() => discountType = v!),
//                 ),
//                 TextFormField(
//                   decoration: const InputDecoration(labelText: 'Discount Amount'),
//                   keyboardType: TextInputType.number,
//                   onChanged: (v) => discountAmount = double.tryParse(v) ?? 0.0,
//                   validator: (v) => v == null || v.isEmpty ? 'Required' : null,
//                 ),
//                 TextFormField(
//                   decoration: const InputDecoration(labelText: 'Minimum Purchase'),
//                   keyboardType: TextInputType.number,
//                   onChanged: (v) => minimumPurchase = double.tryParse(v) ?? 0.0,
//                   validator: (v) => v == null || v.isEmpty ? 'Required' : null,
//                 ),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         startDate == null
//                             ? 'Start Date: Not selected'
//                             : 'Start: ${DateFormat('yyyy-MM-dd').format(startDate!)}',
//                       ),
//                     ),
//                     TextButton(onPressed: pickStartDate, child: const Text('Pick Start'))
//                   ],
//                 ),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         endDate == null
//                             ? 'End Date: Not selected'
//                             : 'End: ${DateFormat('yyyy-MM-dd').format(endDate!)}',
//                       ),
//                     ),
//                     TextButton(onPressed: pickEndDate, child: const Text('Pick End'))
//                   ],
//                 ),
//                 DropdownButtonFormField<String>(
//                   decoration: const InputDecoration(labelText: 'Status'),
//                   value: status,
//                   items: const [
//                     DropdownMenuItem(value: 'Active', child: Text('Active')),
//                     DropdownMenuItem(value: 'Expired', child: Text('Expired')),
//                   ],
//                   onChanged: (v) => setState(() => status = v!),
//                 ),
// DropdownButtonFormField<int>(
//   decoration: const InputDecoration(labelText: 'Category'),
//   value: selectedCategoryId != null &&
//           categories.any((c) =>
//               (c['id'] is int
//                   ? c['id']
//                   : int.tryParse('${c['id']}')) == selectedCategoryId)
//       ? selectedCategoryId
//       : null,
//   items: categories.map((c) {
//     final id = c['id'] is int ? c['id'] : int.tryParse('${c['id']}') ?? 0;
//     return DropdownMenuItem<int>(
//       value: id,
//       child: Text('${c['name']}'),
//     );
//   }).toList(),
//   onChanged: (v) {
//     setState(() {
//       selectedCategoryId = v;
//       selectedSubcategoryId = null;
//       selectedProductId = null;
//     });
//   },
// ),

// DropdownButtonFormField<int>(
//   decoration: const InputDecoration(labelText: 'Subcategory'),
//   value: selectedSubcategoryId != null &&
//           filteredSubcategories.any(
//               (s) => s['Id'] == selectedSubcategoryId)
//       ? selectedSubcategoryId
//       : null,
//   items: filteredSubcategories.map((s) {
//     return DropdownMenuItem<int>(
//       value: s['Id'] as int,
//       child: Text('${s['Name']}'),
//     );
//   }).toList(),
//   onChanged: (v) {
//     setState(() {
//       selectedSubcategoryId = v;
//       selectedProductId = null;
//     });
//   },
// ),

// const SizedBox(height: 20),
// DropdownButtonFormField<int>(
//   decoration: const InputDecoration(labelText: 'Product'),
//   value: selectedProductId != null &&
//           filteredProducts.any((p) =>
//               (p['ProductID'] is int
//                   ? p['ProductID']
//                   : int.tryParse('${p['ProductID']}')) ==
//               selectedProductId)
//       ? selectedProductId
//       : null,
//   items: filteredProducts.map((p) {
//     final id = p['ProductID'] is int
//         ? p['ProductID']
//         : int.tryParse('${p['ProductID']}') ?? 0;
//     return DropdownMenuItem<int>(
//       value: id,
//       child: Text('${p['Name']}'),
//     );
//   }).toList(),
//   onChanged: (v) {
//     setState(() {
//       selectedProductId = v;
//     });
//   },
// ),

//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: isSaving ? null : submit,
//                   child: isSaving
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         )
//                       : const Text('Save Coupon'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
