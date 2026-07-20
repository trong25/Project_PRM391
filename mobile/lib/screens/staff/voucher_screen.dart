import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/discount_service.dart';
import 'add_voucher_screen.dart';
import 'edit_voucher_screen.dart';
import 'widgets/staff_bottom_nav_bar.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  final DiscountService service = DiscountService();

  List<dynamic> vouchers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final data = await service.getDiscounts();

      setState(() {
        vouchers = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tải dữ liệu: $e")),
      );
    }
  }

  Future<void> deleteVoucher(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa mã giảm giá"),
        content: const Text("Bạn có chắc muốn xóa mã giảm giá này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await service.deleteDiscount(vouchers.firstWhere((e) => e["discountId"] == id)["discountId"]);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xóa thành công")),
      );

      loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Xóa thất bại: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        bottomNavigationBar: StaffBottomNavBar(currentIndex: 2),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      bottomNavigationBar: const StaffBottomNavBar(currentIndex: 2),
      body: vouchers.isEmpty
          ? const Center(
        child: Text(
          "Chưa có mã giảm giá",
          style: TextStyle(fontSize: 18),
        ),
      )
          : RefreshIndicator(
        onRefresh: loadData,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: vouchers.length,
          itemBuilder: (context, index) {
            final voucher = vouchers[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voucher["code"] ?? "",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      voucher["description"] ?? "",
                      style: const TextStyle(fontSize: 15),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.discount,
                            size: 18, color: Colors.red),
                        const SizedBox(width: 6),
                        Text(
                          "Giảm: ${voucher["discountValue"]}",
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(Icons.category,
                            size: 18, color: Colors.blue),
                        const SizedBox(width: 6),
                        Text(
                          "Loại: ${voucher["discountType"]}",
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(Icons.inventory_2,
                            size: 18, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(
                          "Số lượng: ${voucher["quantity"]}",
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 18, color: Colors.green),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Từ ${voucher["startDate"]} đến ${voucher["endDate"]}",
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Chip(
                          label: Text(
                            voucher["status"] ?? "",
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor:
                          voucher["status"] == "Active"
                              ? Colors.green
                              : Colors.red,
                        ),

                        const Spacer(),

                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.orange,
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditVoucherScreen(
                                  voucher: voucher,
                                ),
                              ),
                            );

                            loadData();
                          },
                        ),

                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              deleteVoucher(voucher["discountId"]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddVoucherScreen(),
            ),
          );

          loadData();
        },
      ),
    );
  }
}
