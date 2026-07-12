import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/discount_service.dart';

class EditVoucherScreen extends StatefulWidget {
  final Map<String, dynamic> voucher;

  const EditVoucherScreen({
    super.key,
    required this.voucher,
  });

  @override
  State<EditVoucherScreen> createState() => _EditVoucherScreenState();
}

class _EditVoucherScreenState extends State<EditVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  final DiscountService service = DiscountService();

  late TextEditingController codeController;
  late TextEditingController descriptionController;
  late TextEditingController discountValueController;
  late TextEditingController quantityController;

  late String discountType;
  late String status;

  late DateTime startDate;
  late DateTime endDate;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    codeController =
        TextEditingController(text: widget.voucher["code"]);

    descriptionController =
        TextEditingController(text: widget.voucher["description"]);

    discountValueController =
        TextEditingController(
            text: widget.voucher["discountValue"].toString());

    quantityController =
        TextEditingController(
            text: widget.voucher["quantity"].toString());

    discountType = widget.voucher["discountType"];

    status = widget.voucher["status"];

    startDate = DateTime.parse(widget.voucher["startDate"]);

    endDate = DateTime.parse(widget.voucher["endDate"]);
  }

  Future<void> pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        startDate = date;
      });
    }
  }

  Future<void> pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        endDate = date;
      });
    }
  }

  Future<void> updateVoucher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSaving = true;
    });

    try {
      await service.updateDiscount(
        widget.voucher["discountId"],
        {
          "code": codeController.text.trim(),
          "description": descriptionController.text.trim(),
          "discountType": discountType,
          "discountValue":
          double.parse(discountValueController.text),
          "startDate": startDate.toIso8601String(),
          "endDate": endDate.toIso8601String(),
          "quantity": int.parse(quantityController.text),
          "status": status,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cập nhật thành công"),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi: $e"),
        ),
      );
    }
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Không được để trống";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sửa Voucher"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [

            buildTextField(
              label: "Mã giảm giá",
              controller: codeController,
            ),

            buildTextField(
              label: "Mô tả",
              controller: descriptionController,
            ),

            DropdownButtonFormField(
              value: discountType,
              decoration: const InputDecoration(
                labelText: "Loại giảm giá",
                border: OutlineInputBorder(),
              ),
              items: const [

                DropdownMenuItem(
                  value: "PERCENT",
                  child: Text("PERCENT"),
                ),

                DropdownMenuItem(
                  value: "AMOUNT",
                  child: Text("AMOUNT"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  discountType = value!;
                });
              },
            ),

            const SizedBox(height: 15),

            buildTextField(
              label: "Giá trị giảm",
              controller: discountValueController,
              keyboardType: TextInputType.number,
            ),

            buildTextField(
              label: "Số lượng",
              controller: quantityController,
              keyboardType: TextInputType.number,
            ),

            ListTile(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              title: Text(
                startDate.toString().substring(0, 10),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: pickStartDate,
            ),

            const SizedBox(height: 15),

            ListTile(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              title: Text(
                endDate.toString().substring(0, 10),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: pickEndDate,
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField(
              value: status,
              decoration: const InputDecoration(
                labelText: "Trạng thái",
                border: OutlineInputBorder(),
              ),
              items: const [

                DropdownMenuItem(
                  value: "Active",
                  child: Text("Active"),
                ),

                DropdownMenuItem(
                  value: "Disable",
                  child: Text("Disable"),
                ),

                DropdownMenuItem(
                  value: "Expired",
                  child: Text("Expired"),
                ),

              ],
              onChanged: (value) {
                setState(() {
                  status = value!;
                });
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
                onPressed:
                isSaving ? null : updateVoucher,
                child: isSaving
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text(
                  "Lưu thay đổi",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}