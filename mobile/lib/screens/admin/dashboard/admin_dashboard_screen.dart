// lib/screens/admin/dashboard/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/room_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _selectedHotel = 'all';
  String _selectedTimeFrame = 'month';

  @override
  Widget build(BuildContext context) {
    final revenueAsync = ref.watch(revenueProvider({
      'hotelId': _selectedHotel,
      'timeFrame': _selectedTimeFrame,
    }));
    final hotelsAsync = ref.watch(hotelsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Giám đốc')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTimeFrame,
                    decoration: const InputDecoration(labelText: 'Khung thời gian'),
                    items: const [
                      DropdownMenuItem(value: 'day', child: Text('Hôm nay')),
                      DropdownMenuItem(value: 'month', child: Text('Tháng này')),
                      DropdownMenuItem(value: 'year', child: Text('Năm nay')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTimeFrame = val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: hotelsAsync.when(
                    data: (hotels) {
                      return DropdownButtonFormField<String>(
                        value: _selectedHotel,
                        decoration: const InputDecoration(labelText: 'Chi nhánh'),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('Toàn hệ thống')),
                          ...hotels.map((h) => DropdownMenuItem(value: h.hotelId, child: Text(h.name))).toList(),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedHotel = val);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => const Text('Lỗi tải CN'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            revenueAsync.when(
              data: (revenue) {
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Text('DOANH THU', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 16),
                        Text(
                          '${revenue.toStringAsFixed(0)} VNĐ',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Lỗi tải doanh thu: $err'),
            ),
          ],
        ),
      ),
    );
  }
}
