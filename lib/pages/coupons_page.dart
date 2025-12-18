import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class CouponPage extends StatefulWidget {
  const CouponPage({super.key});

  @override
  State<CouponPage> createState() => _CouponPageState();
}

class _CouponPageState extends State<CouponPage> {
  List<Map<String, dynamic>> coupons = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCoupons();
  }

  Future<void> loadCoupons() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getCoupons();
      coupons = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint("❌ Failed to load coupons: $e");
    }
    if (mounted) setState(() => isLoading = false);
  }

  void openAddCouponForm({Map<String, dynamic>? coupon}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCouponForm(editCoupon: coupon),
      ),
    );

    if (result == true) loadCoupons();
  }

  Future<void> deleteCoupon(int id) async {
    final success = await ApiService.deleteCoupon(id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Coupon deleted')));
      loadCoupons();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Delete failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Coupons")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openAddCouponForm(),
        icon: const Icon(Icons.add),
        label: const Text("Add Coupon"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : coupons.isEmpty
              ? const Center(child: Text("No coupons found"))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Coupon Code")),
                      DataColumn(label: Text("Status")),
                      DataColumn(label: Text("Amount")),
                      DataColumn(label: Text("Valid Date")),
                      DataColumn(label: Text("Edit")),
                      DataColumn(label: Text("Delete")),
                    ],
                    rows: coupons.map((c) {
                      final id = c['coupon_id'];

                      final code = c['code'] ?? '—';
                      final status = c['status'] ?? '—';
                      final amount = c['discount_amount'] ?? '—';

                      final start = c['start_date'] != null
                          ? DateFormat('yyyy-MM-dd')
                              .format(DateTime.parse(c['start_date']))
                          : '—';

                      final end = c['end_date'] != null
                          ? DateFormat('yyyy-MM-dd')
                              .format(DateTime.parse(c['end_date']))
                          : '—';

                      return DataRow(cells: [
                        DataCell(Text(code.toString())),
                        DataCell(Text(status.toString())),
                        DataCell(Text(amount.toString())),
                        DataCell(Text("$start → $end")),
                        DataCell(
                          IconButton(
                            icon:
                                const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                openAddCouponForm(coupon: c),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon:
                                const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteCoupon(id),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
    );
  }
}

/* ============================================================
   ADD / EDIT COUPON FORM
============================================================ */

class AddCouponForm extends StatefulWidget {
  final Map<String, dynamic>? editCoupon;
  const AddCouponForm({super.key, this.editCoupon});

  @override
  State<AddCouponForm> createState() => _AddCouponFormState();
}

class _AddCouponFormState extends State<AddCouponForm> {
  final _formKey = GlobalKey<FormState>();

  String couponCode = '';
  String discountType = 'Fixed';
  double discountAmount = 0;
  double minimumPurchase = 0;
  String status = 'Active';

  DateTime? startDate;
  DateTime? endDate;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadEditData();
  }

  void loadEditData() {
    if (widget.editCoupon == null) return;

    final c = widget.editCoupon!;

    couponCode = c['code'] ?? '';
    discountType = c['discount_type'] ?? 'Fixed';
    discountAmount =
        double.tryParse(c['discount_amount']?.toString() ?? '0') ?? 0;
    minimumPurchase =
        double.tryParse(c['minimum_purchase']?.toString() ?? '0') ?? 0;
    status = c['status'] ?? 'Active';

    startDate = c['start_date'] != null
        ? DateTime.parse(c['start_date'])
        : null;

    endDate = c['end_date'] != null
        ? DateTime.parse(c['end_date'])
        : null;
  }

  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select start & end date")),
      );
      return;
    }

    setState(() => isSaving = true);

    final start = DateFormat('yyyy-MM-dd').format(startDate!);
    final end = DateFormat('yyyy-MM-dd').format(endDate!);

    bool success;

    if (widget.editCoupon == null) {
      success = await ApiService.addCoupon(
        code: couponCode,
        discountType: discountType,
        discountAmount: discountAmount,
        minimumPurchase: minimumPurchase,
        startDate: start,
        endDate: end,
        status: status,
      );
    } else {
      success = await ApiService.updateCoupon(
        id: widget.editCoupon!['coupon_id'],
        code: couponCode,
        discountType: discountType,
        discountAmount: discountAmount,
        minimumPurchase: minimumPurchase,
        startDate: start,
        endDate: end,
        status: status,
        categoryId: null,
        subcategoryId: null,
        productId: null,
      );
    }

    if (!mounted) return;
    setState(() => isSaving = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Save failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.editCoupon == null ? "Add Coupon" : "Edit Coupon"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: couponCode,
                  decoration:
                      const InputDecoration(labelText: "Coupon Code"),
                  onChanged: (v) => couponCode = v,
                  validator: (v) =>
                      v == null || v.isEmpty ? "Required" : null,
                ),

                DropdownButtonFormField(
                  value: discountType,
                  decoration:
                      const InputDecoration(labelText: "Discount Type"),
                  items: const [
                    DropdownMenuItem(
                        value: "Fixed", child: Text("Fixed")),
                    DropdownMenuItem(
                        value: "Percentage", child: Text("Percentage")),
                  ],
                  onChanged: (v) => setState(() => discountType = v!),
                ),

                TextFormField(
                  initialValue: discountAmount.toString(),
                  decoration:
                      const InputDecoration(labelText: "Discount Amount"),
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      discountAmount = double.tryParse(v) ?? 0,
                ),

                TextFormField(
                  initialValue: minimumPurchase.toString(),
                  decoration:
                      const InputDecoration(labelText: "Minimum Purchase"),
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      minimumPurchase = double.tryParse(v) ?? 0,
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(startDate == null
                        ? "Start Date: Not selected"
                        : "Start: ${DateFormat('yyyy-MM-dd').format(startDate!)}"),
                    TextButton(
                        onPressed: () => pickDate(true),
                        child: const Text("Pick"))
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(endDate == null
                        ? "End Date: Not selected"
                        : "End: ${DateFormat('yyyy-MM-dd').format(endDate!)}"),
                    TextButton(
                        onPressed: () => pickDate(false),
                        child: const Text("Pick"))
                  ],
                ),

                DropdownButtonFormField(
                  value: status,
                  decoration:
                      const InputDecoration(labelText: "Status"),
                  items: const [
                    DropdownMenuItem(
                        value: "Active", child: Text("Active")),
                    DropdownMenuItem(
                        value: "Expired", child: Text("Expired")),
                  ],
                  onChanged: (v) => setState(() => status = v!),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: isSaving ? null : submit,
                  child: isSaving
                      ? const CircularProgressIndicator()
                      : const Text("Save Coupon"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
