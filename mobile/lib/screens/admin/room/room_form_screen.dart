// lib/screens/admin/room/room_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/room_model.dart';
import '../../../providers/room_provider.dart';

class RoomFormScreen extends ConsumerStatefulWidget {
  final RoomModel? room;
  final String? initialHotelId;

  const RoomFormScreen({super.key, this.room, this.initialHotelId});

  @override
  ConsumerState<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends ConsumerState<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _nameRoom = '';
  String? _hotelId;
  String? _typeRoomId;
  String _status = 'Trống';

  @override
  void initState() {
    super.initState();
    _hotelId = widget.initialHotelId;
    if (widget.room != null) {
      _nameRoom = widget.room!.nameRoom;
      _hotelId = widget.room!.hotelId;
      _typeRoomId = widget.room!.typeRoomId;
      _status = widget.room!.status ?? 'Trống';
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate() &&
        _hotelId != null &&
        _typeRoomId != null) {
      _formKey.currentState!.save();
      final api = ref.read(roomApiProvider);

      final newRoom = RoomModel(
        roomId: widget.room?.roomId ?? '',
        nameRoom: _nameRoom,
        hotelId: _hotelId,
        typeRoomId: _typeRoomId,
        status: _status,
      );

      try {
        if (widget.room == null) {
          await api.createRoom(newRoom);
        } else {
          await api.updateRoom(widget.room!.roomId, newRoom);
        }
        ref.invalidate(roomsProvider);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Vui lòng chọn đầy đủ Chi nhánh và Loại phòng')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotelsAsync = ref.watch(hotelsProvider);
    final typeRoomsAsync = ref.watch(typeRoomsProvider);

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.room == null ? 'Tạo phòng mới' : 'Sửa phòng')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _nameRoom,
                decoration:
                    const InputDecoration(labelText: 'Tên phòng (VD: P101)'),
                validator: (val) => val!.isEmpty ? 'Không được để trống' : null,
                onSaved: (val) => _nameRoom = val!,
              ),
              const SizedBox(height: 16),
              hotelsAsync.when(
                data: (hotels) {
                  // Đảm bảo selected value tồn tại trong danh sách
                  if (_hotelId != null &&
                      !hotels.any((h) => h.hotelId == _hotelId)) {
                    _hotelId = null;
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _hotelId,
                    decoration:
                        const InputDecoration(labelText: 'Chi nhánh khách sạn'),
                    items: hotels
                        .map((h) => DropdownMenuItem(
                            value: h.hotelId, child: Text(h.name)))
                        .toList(),
                    onChanged: (val) => setState(() => _hotelId = val),
                    validator: (val) => val == null ? 'Bắt buộc chọn' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => const Text('Lỗi tải danh sách khách sạn'),
              ),
              const SizedBox(height: 16),
              typeRoomsAsync.when(
                data: (typeRooms) {
                  // Đảm bảo selected value tồn tại
                  if (_typeRoomId != null &&
                      !typeRooms.any((t) => t.typeRoomId == _typeRoomId)) {
                    _typeRoomId = null;
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _typeRoomId,
                    decoration: const InputDecoration(labelText: 'Loại phòng'),
                    items: typeRooms
                        .map((t) => DropdownMenuItem(
                            value: t.typeRoomId, child: Text(t.typeRoom)))
                        .toList(),
                    onChanged: (val) => setState(() => _typeRoomId = val),
                    validator: (val) => val == null ? 'Bắt buộc chọn' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => const Text('Lỗi tải danh sách loại phòng'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: const [
                  DropdownMenuItem(value: 'Trống', child: Text('Trống')),
                  DropdownMenuItem(
                      value: 'Đang thuê', child: Text('Đang thuê')),
                  DropdownMenuItem(value: 'Dọn dẹp', child: Text('Dọn dẹp')),
                  DropdownMenuItem(value: 'Bảo trì', child: Text('Bảo trì')),
                ],
                onChanged: (val) => setState(() => _status = val!),
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
