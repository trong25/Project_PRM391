// lib/screens/admin/room/room_form_screen.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
  final _imagePicker = ImagePicker();

  String _nameRoom = '';
  String? _hotelId;
  String? _typeRoomId;
  String _status = 'Trống';
  List<String> _imageUrls = [];
  List<XFile> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _hotelId = widget.initialHotelId;
    if (widget.room != null) {
      _nameRoom = widget.room!.nameRoom;
      _hotelId = widget.room!.hotelId;
      _typeRoomId = widget.room!.typeRoomId;
      _status = widget.room!.status ?? 'Trống';
      _imageUrls = widget.room!.imageUrls.isNotEmpty
          ? List<String>.from(widget.room!.imageUrls)
          : [
        if (widget.room!.imageUrl != null &&
            widget.room!.imageUrl!.isNotEmpty)
          widget.room!.imageUrl!,
      ];
    }
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (images.isEmpty) return;
    setState(() => _selectedImages = [..._selectedImages, ...images]);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _hotelId == null ||
        _typeRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đầy đủ chi nhánh và loại phòng'),
        ),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    final api = ref.read(roomApiProvider);

    try {
      final finalImageUrls = List<String>.from(_imageUrls);
      if (_selectedImages.isNotEmpty) {
        final uploadedUrls = await api.uploadRoomImages(_selectedImages);
        finalImageUrls.addAll(uploadedUrls);
      }

      final room = RoomModel(
        roomId: widget.room?.roomId ?? '',
        nameRoom: _nameRoom,
        hotelId: _hotelId,
        typeRoomId: _typeRoomId,
        status: _status,
        imageUrl: finalImageUrls.isEmpty ? null : finalImageUrls.first,
        imageUrls: finalImageUrls,
      );

      if (widget.room == null) {
        await api.createRoom(room);
      } else {
        await api.updateRoom(widget.room!.roomId, room);
      }

      ref.invalidate(roomsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotelsAsync = ref.watch(hotelsProvider);
    final typeRoomsAsync = ref.watch(typeRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room == null ? 'Tạo phòng mới' : 'Sửa phòng'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _nameRoom,
                decoration: const InputDecoration(
                  labelText: 'Tên phòng (VD: P101)',
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Không được để trống'
                    : null,
                onSaved: (val) => _nameRoom = val!.trim(),
              ),
              const SizedBox(height: 16),
              hotelsAsync.when(
                data: (hotels) {
                  if (_hotelId != null &&
                      !hotels.any((h) => h.hotelId == _hotelId)) {
                    _hotelId = null;
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _hotelId,
                    decoration: const InputDecoration(
                      labelText: 'Chi nhánh khách sạn',
                    ),
                    items: hotels
                        .map(
                          (h) => DropdownMenuItem(
                        value: h.hotelId,
                        child: Text(h.name),
                      ),
                    )
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
                  if (_typeRoomId != null &&
                      !typeRooms.any((t) => t.typeRoomId == _typeRoomId)) {
                    _typeRoomId = null;
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _typeRoomId,
                    decoration: const InputDecoration(labelText: 'Loại phòng'),
                    items: typeRooms
                        .map(
                          (t) => DropdownMenuItem(
                        value: t.typeRoomId,
                        child: Text(t.typeRoom),
                      ),
                    )
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
                  DropdownMenuItem(value: 'Đang thuê', child: Text('Đang thuê')),
                  DropdownMenuItem(value: 'Dọn dẹp', child: Text('Dọn dẹp')),
                  DropdownMenuItem(value: 'Bảo trì', child: Text('Bảo trì')),
                ],
                onChanged: (val) => setState(() => _status = val!),
              ),
              const SizedBox(height: 20),
              _RoomImagePicker(
                imageUrls: _imageUrls,
                selectedImages: _selectedImages,
                onPickImages: _pickImages,
                onRemoveExistingImage: (index) {
                  setState(() => _imageUrls.removeAt(index));
                },
                onRemoveSelectedImage: (index) {
                  setState(() => _selectedImages.removeAt(index));
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSubmitting ? 'Đang lưu...' : 'Lưu thông tin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomImagePicker extends StatelessWidget {
  final List<String> imageUrls;
  final List<XFile> selectedImages;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveExistingImage;
  final ValueChanged<int> onRemoveSelectedImage;

  const _RoomImagePicker({
    required this.imageUrls,
    required this.selectedImages,
    required this.onPickImages,
    required this.onRemoveExistingImage,
    required this.onRemoveSelectedImage,
  });

  @override
  Widget build(BuildContext context) {
    final totalImages = imageUrls.length + selectedImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Ảnh phòng ($totalImages)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            OutlinedButton.icon(
              onPressed: onPickImages,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Chọn ảnh'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (totalImages == 0)
          const AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: BoxDecoration(),
              child: _ImagePlaceholder(),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: totalImages,
            itemBuilder: (context, index) {
              if (index < imageUrls.length) {
                return _ImageTile(
                  child: Image.network(
                    imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                  ),
                  onRemove: () => onRemoveExistingImage(index),
                );
              }

              final selectedIndex = index - imageUrls.length;
              return _ImageTile(
                child: _SelectedImagePreview(
                  image: selectedImages[selectedIndex],
                ),
                onRemove: () => onRemoveSelectedImage(selectedIndex),
              );
            },
          ),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;

  const _ImageTile({
    required this.child,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: child,
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton.filledTonal(
              tooltip: 'Xóa ảnh',
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
              style: IconButton.styleFrom(
                minimumSize: const Size(30, 30),
                fixedSize: const Size(30, 30),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedImagePreview extends StatelessWidget {
  final XFile image;

  const _SelectedImagePreview({required this.image});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return Image.file(File(image.path), fit: BoxFit.cover);
    }

    if (_isHeicImage(image.name)) {
      return _UnsupportedPreview(fileName: image.name);
    }

    return FutureBuilder(
      future: image.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        if (snapshot.hasError) {
          return const _ImagePlaceholder();
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _UnsupportedPreview extends StatelessWidget {
  final String fileName;

  const _UnsupportedPreview({required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 34,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              'HEIC',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

bool _isHeicImage(String fileName) {
  final lowerName = fileName.toLowerCase();
  return lowerName.endsWith('.heic') || lowerName.endsWith('.heif');
}
