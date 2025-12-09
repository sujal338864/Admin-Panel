import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

/// --------------------------------------------------------------
///                ADD / EDIT COUPON PAGE
/// --------------------------------------------------------------
class AddCouponForm extends StatefulWidget {
  final Map<String, dynamic>? editCoupon;

  const AddCouponForm({super.key, this.editCoupon});

  @override
  State<AddCouponForm> createState() => _AddCouponFormState();
}

class _AddCouponFormState extends State<AddCouponForm> {
  final _formKey = GlobalKey<FormState>();

  String couponCode = "";
  String discountType = "Fixed";
  double discountAmount = 0;
  double minimumPurchase = 0;
  DateTime? startDate;
  DateTime? endDate;
  String status = "Active";

  int? selectedCategoryId;
  int? selectedSubcategoryId;
  int? selectedProductId;

  List categories = [];
  List subcategories = [];
  List products = [];

  List filteredSubcategories = [];
  List filteredProducts = [];

  bool loadingDropDowns = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadEditData();
    loadDropDownData();
  }

  /// Load edit coupon data into fields
  void loadEditData() {
    if (widget.editCoupon == null) return;
    final c = widget.editCoupon!;

    couponCode = c["Code"] ?? "";
    discountType = c["DiscountType"] ?? "Fixed";
    discountAmount = (c["DiscountAmount"] ?? 0).toDouble();
    minimumPurchase = (c["MinimumPurchase"] ?? 0).toDouble();
    status = c["Status"] ?? "Active";

    startDate = DateTime.tryParse(c["StartDate"] ?? "");
    endDate = DateTime.tryParse(c["EndDate"] ?? "");

    selectedCategoryId = c["CategoryID"];
    selectedSubcategoryId = c["SubcategoryID"];
    selectedProductId = c["ProductID"];
  }

  /// Load dropdown lists
  Future<void> loadDropDownData() async {
    final cats = await ApiService.getCategories();
    final prods = await ApiService.getProducts();

    setState(() {
      categories = cats;
      products = prods;
      loadingDropDowns = false;
    });

    if (selectedCategoryId != null) {
      final subs = await ApiService.getSubcategories(selectedCategoryId!);
      setState(() {
        subcategories = subs;
        filteredSubcategories = subs;
        filteredProducts = products
            .where((p) => p["SubcategoryID"] == selectedSubcategoryId)
            .toList();
      });
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select start and end date")));
      return;
    }

    setState(() => saving = true);

    bool ok;
    if (widget.editCoupon == null) {
      ok = await ApiService.addCoupon(
        code: couponCode,
        discountType: discountType,
        discountAmount: discountAmount,
        minimumPurchase: minimumPurchase,
        startDate: DateFormat("yyyy-MM-dd").format(startDate!),
        endDate: DateFormat("yyyy-MM-dd").format(endDate!),
        status: status,
        categoryId: selectedCategoryId,
        subcategoryId: selectedSubcategoryId,
        productId: selectedProductId,
      );
    } else {
      ok = await ApiService.updateCoupon(
        id: widget.editCoupon!["CouponID"],
        code: couponCode,
        discountType: discountType,
        discountAmount: discountAmount,
        minimumPurchase: minimumPurchase,
        startDate: DateFormat("yyyy-MM-dd").format(startDate!),
        endDate: DateFormat("yyyy-MM-dd").format(endDate!),
        status: status,
        categoryId: selectedCategoryId,
        subcategoryId: selectedSubcategoryId,
        productId: selectedProductId,
      );
    }

    setState(() => saving = false);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save coupon")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editCoupon != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Coupon" : "Add Coupon"),
      ),

      body: loadingDropDowns
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [

                    TextFormField(
                      initialValue: couponCode,
                      decoration: const InputDecoration(labelText: "Coupon Code"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                      onChanged: (v) => couponCode = v,
                    ),

                    DropdownButtonFormField(
                      value: discountType,
                      decoration: const InputDecoration(labelText: "Discount Type"),
                      items: const [
                        DropdownMenuItem(value: "Fixed", child: Text("Fixed")),
                        DropdownMenuItem(value: "Percentage", child: Text("Percentage")),
                      ],
                      onChanged: (v) => setState(() => discountType = v!),
                    ),

                    TextFormField(
                      initialValue: discountAmount.toString(),
                      decoration: const InputDecoration(labelText: "Discount Amount"),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => discountAmount = double.tryParse(v) ?? 0,
                    ),

                    TextFormField(
                      initialValue: minimumPurchase.toString(),
                      decoration: const InputDecoration(labelText: "Minimum Purchase"),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => minimumPurchase = double.tryParse(v) ?? 0,
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: Text(startDate == null
                              ? "Start date"
                              : "Start: ${DateFormat("yyyy-MM-dd").format(startDate!)}"),
                        ),
                        TextButton(
                          child: const Text("Pick"),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (d != null) setState(() => startDate = d);
                          },
                        )
                      ],
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: Text(endDate == null
                              ? "End date"
                              : "End: ${DateFormat("yyyy-MM-dd").format(endDate!)}"),
                        ),
                        TextButton(
                          child: const Text("Pick"),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (d != null) setState(() => endDate = d);
                          },
                        )
                      ],
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField(
                      value: status,
                      decoration: const InputDecoration(labelText: "Status"),
                      items: const [
                        DropdownMenuItem(value: "Active", child: Text("Active")),
                        DropdownMenuItem(value: "Expired", child: Text("Expired")),
                      ],
                      onChanged: (v) => setState(() => status = v!),
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(labelText: "Category"),
                      items: categories.map((c) {
                        final id = c["CategoryID"] is int
                            ? c["CategoryID"]
                            : int.tryParse(c["CategoryID"].toString()) ?? 0;

                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(c["Name"].toString()),
                        );
                      }).toList(),
                      onChanged: (v) async {
                        selectedCategoryId = v;
                        selectedSubcategoryId = null;
                        selectedProductId = null;

                        final subs = await ApiService.getSubcategories(v!);
                        setState(() {
                          subcategories = subs;
                          filteredSubcategories = subs;
                          filteredProducts = [];
                        });
                      },
                    ),

                    DropdownButtonFormField<int>(
                      value: selectedSubcategoryId,
                      decoration: const InputDecoration(labelText: "Subcategory"),
                      items: filteredSubcategories.map((s) {
                        final id = s["SubcategoryID"] is int
                            ? s["SubcategoryID"]
                            : int.tryParse(s["SubcategoryID"].toString()) ?? 0;

                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(s["Name"].toString()),
                        );
                      }).toList(),
                      onChanged: (v) {
                        selectedSubcategoryId = v;
                        filteredProducts = products
                            .where((p) => p["SubcategoryID"] == v)
                            .toList();
                        setState(() {});
                      },
                    ),

                    DropdownButtonFormField<int>(
                      value: selectedProductId,
                      decoration: const InputDecoration(labelText: "Product"),
                      items: filteredProducts.map((p) {
                        final id = p["ProductID"] is int
                            ? p["ProductID"]
                            : int.tryParse(p["ProductID"].toString()) ?? 0;

                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(p["Name"].toString()),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => selectedProductId = v),
                    ),

                    const SizedBox(height: 25),

                    ElevatedButton(
                      onPressed: saving ? null : submit,
                      child: saving
                          ? const CircularProgressIndicator()
                          : Text(isEdit ? "Update Coupon" : "Save Coupon"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
