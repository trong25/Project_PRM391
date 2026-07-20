import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../services/discount_service.dart';

class CustomerVoucherScreen extends StatefulWidget {
  const CustomerVoucherScreen({super.key});

  @override
  State<CustomerVoucherScreen> createState() =>
      _CustomerVoucherScreenState();
}

class _CustomerVoucherScreenState
    extends State<CustomerVoucherScreen> {

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
      final data = await service.getActiveDiscounts();

      setState(() {
        vouchers = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "active":
        return Colors.green;
      case "inactive":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Voucher"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),

      body: vouchers.isEmpty
          ? const Center(
        child: Text(
          "Hiện chưa có voucher khả dụng",
          style: TextStyle(fontSize: 17),
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
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    /// CODE
                    Text(
                      voucher["code"] ?? "",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// DESCRIPTION
                    Text(
                      voucher["description"] ?? "",
                      style:
                      const TextStyle(fontSize: 15),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Icon(
                          Icons.discount,
                          color: Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Giảm ${voucher["discountValue"]}",
                          style: const TextStyle(
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.category,
                          color: Colors.blue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Loại: ${voucher["discountType"]}",
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          color: Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Số lượng: ${voucher["quantity"]}",
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Từ ${voucher["startDate"]}\nĐến ${voucher["endDate"]}",
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Chip(
                        backgroundColor: _statusColor(
                            voucher["status"] ?? ""),
                        label: Text(
                          voucher["status"] ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}