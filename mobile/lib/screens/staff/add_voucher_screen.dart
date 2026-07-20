import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/discount_service.dart';

class AddVoucherScreen extends StatefulWidget {
  const AddVoucherScreen({super.key});

  @override
  State<AddVoucherScreen> createState() => _AddVoucherScreenState();
}

class _AddVoucherScreenState extends State<AddVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  final DiscountService service = DiscountService();

  final TextEditingController codeController = TextEditingController();
  final TextEditingController descriptionController =
  TextEditingController();
  final TextEditingController discountValueController =
  TextEditingController();
  final TextEditingController quantityController =
  TextEditingController();

  String discountType = "PERCENT";
  String status = "Active";

  DateTime? startDate;
  DateTime? endDate;

  bool isSaving = false;

  Future<void> pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        startDate = DateTime(date.year, date.month, date.day);
      });
    }
  }

  Future<void> pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      initialDate: startDate ?? DateTime.now(),
    );

    if (date != null) {
      setState(() {
        // A voucher remains usable for the whole selected end date.
        endDate = DateTime(
          date.year,
          date.month,
          date.day,
          23,
          59,
          59,
          999,
        );
      });
    }
  }

  Future<void> saveVoucher() async {
    if (!_formKey.currentState!.validate()) return;

    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chọn ngày bắt đầu và ngày kết thúc"),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await service.createDiscount({
        "code": codeController.text.trim(),
        "description": descriptionController.text.trim(),
        "discountType": discountType,
        "discountValue":
        double.parse(discountValueController.text.trim()),
        "startDate": startDate!.toIso8601String(),
        "endDate": endDate!.toIso8601String(),
        "quantity": int.parse(quantityController.text.trim()),
        "status": status,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Thêm mã giảm giá thành công"),
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
        title: const Text("Thêm Voucher"),
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
                startDate == null
                    ? "Chọn ngày bắt đầu"
                    : startDate.toString().substring(0, 10),
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
                endDate == null
                    ? "Chọn ngày kết thúc"
                    : endDate.toString().substring(0, 10),
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
                onPressed: isSaving ? null : saveVoucher,
                child: isSaving
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text(
                  "Lưu",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
