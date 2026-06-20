// lib/screens/admin/room/room_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/room_provider.dart';
import 'room_form_screen.dart';

class RoomManagementScreen extends ConsumerWidget {
  const RoomManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Phòng')),
      body: roomsAsync.when(
        data: (rooms) {
          if (rooms.isEmpty) return const Center(child: Text('Không có dữ liệu'));
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return ListTile(
                leading: const Icon(Icons.bed),
                title: Text('${room.nameRoom} - ${room.typeRoomName ?? ''}'),
                subtitle: Text('Chi nhánh: ${room.hotelName ?? ''}\nTrạng thái: ${room.status ?? ''}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => RoomFormScreen(room: room)));
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RoomFormScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
