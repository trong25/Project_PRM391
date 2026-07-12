import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import 'voucher_screen.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  int _currentIndex = 0;

  final List<String> _titles = [
    "Đặt phòng",
    "Phòng",
    "Voucher",
    "Feedback",
  ];

  final List<Widget> _pages = const [
    Center(
      child: Text(
        "Đặt phòng",
        style: TextStyle(fontSize: 22),
      ),
    ),
    Center(
      child: Text(
        "Quản lý phòng",
        style: TextStyle(fontSize: 22),
      ),
    ),
    VoucherScreen(),
    Center(
      child: Text(
        "Feedback",
        style: TextStyle(fontSize: 22),
      ),
    ),
  ];

  final List<IconData> _icons = [
    Icons.calendar_month,
    Icons.hotel,
    Icons.confirmation_number,
    Icons.feedback,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(_icons[0]),
            label: _titles[0],
          ),
          BottomNavigationBarItem(
            icon: Icon(_icons[1]),
            label: _titles[1],
          ),
          BottomNavigationBarItem(
            icon: Icon(_icons[2]),
            label: _titles[2],
          ),
          BottomNavigationBarItem(
            icon: Icon(_icons[3]),
            label: _titles[3],
          ),
        ],
      ),
    );
  }
}