// lib/screens/admin/user/add_edit_user_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_management_model.dart';
import '../../../providers/user_provider.dart';

class AddEditUserScreen extends ConsumerStatefulWidget {
  final UserManagementModel? user;
  const AddEditUserScreen({Key? key, this.user}) : super(key: key);

  @override
  ConsumerState<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends ConsumerState<AddEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _password = '';
  String _roleId = 'STAFF';

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _fullName = widget.user!.fullName;
      _email = widget.user!.email ?? '';
      _phone = widget.user!.phone ?? '';
      _roleId = widget.user!.roleId ?? 'STAFF';
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final api = ref.read(userApiProvider);
      
      try {
        if (widget.user == null) {
          await api.createUser({
            'fullName': _fullName,
            'email': _email,
            'phone': _phone,
            'password': _password,
            'roleId': _roleId
          }, type: _roleId);
        } else {
          await api.updateUser(widget.user!.userId, {
            'fullName': _fullName,
            'email': _email,
            'phone': _phone,
            'roleId': _roleId
          });
        }
        
        ref.invalidate(usersProvider);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.user == null ? 'Tạo mới' : 'Chỉnh sửa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _fullName,
                decoration: const InputDecoration(labelText: 'Họ tên'),
                validator: (val) => val!.isEmpty ? 'Không được để trống' : null,
                onSaved: (val) => _fullName = val!,
              ),
              TextFormField(
                initialValue: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                onSaved: (val) => _email = val ?? '',
              ),
              TextFormField(
                initialValue: _phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                onSaved: (val) => _phone = val ?? '',
              ),
              if (widget.user == null)
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                  validator: (val) => val!.isEmpty ? 'Không được để trống' : null,
                  onSaved: (val) => _password = val!,
                ),
              DropdownButtonFormField<String>(
                value: _roleId,
                decoration: const InputDecoration(labelText: 'Vai trò'),
                items: const [
                  DropdownMenuItem(value: 'ADMIN', child: Text('Giám đốc chi nhánh')),
                  DropdownMenuItem(value: 'STAFF', child: Text('Nhân viên')),
                  DropdownMenuItem(value: 'CUSTOMER', child: Text('Khách hàng')),
                ],
                onChanged: (val) => setState(() => _roleId = val!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Lưu thông tin'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
