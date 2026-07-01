import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum AdminNavTab {
  home,
  revenue,
  rooms,
  account,
}

class AdminBottomNavigation extends StatelessWidget {
  final AdminNavTab currentTab;

  const AdminBottomNavigation({
    super.key,
    required this.currentTab,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentTab.index,
      onDestinationSelected: (index) {
        final tab = AdminNavTab.values[index];
        if (tab == currentTab) return;

        switch (tab) {
          case AdminNavTab.home:
            context.go('/admin');
            break;
          case AdminNavTab.revenue:
            context.go('/admin/revenue');
            break;
          case AdminNavTab.rooms:
            context.go('/admin/rooms');
            break;
          case AdminNavTab.account:
            context.go('/admin/account');
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: Icon(Icons.payments_outlined),
          selectedIcon: Icon(Icons.payments),
          label: 'Doanh thu',
        ),
        NavigationDestination(
          icon: Icon(Icons.hotel_outlined),
          selectedIcon: Icon(Icons.hotel),
          label: 'Phòng',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Tài khoản',
        ),
      ],
    );
  }
}
