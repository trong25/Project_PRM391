// lib/screens/admin/user/user_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_provider.dart';
import 'add_edit_user_screen.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Nhân sự & Khách hàng'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Khách hàng'),
              Tab(text: 'Nhân viên'),
              Tab(text: 'Giám đốc CN'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _UserListTab(roleId: 'CUSTOMER'),
            _UserListTab(roleId: 'STAFF'),
            _UserListTab(roleId: 'ADMIN'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditUserScreen()));
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _UserListTab extends ConsumerWidget {
  final String roleId;
  const _UserListTab({Key? key, required this.roleId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider(roleId));

    return usersAsync.when(
      data: (users) {
        if (users.isEmpty) return const Center(child: Text('Không có dữ liệu'));
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(user.fullName),
              subtitle: Text(user.email ?? user.phone ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditUserScreen(user: user)));
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Lỗi: $err')),
    );
  }
}
