// lib/screens/staff/feedback_list_screen.dart
// Màn hình danh sách Conversations cho Nhân viên — cập nhật theo schema mới

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/chat_room_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import 'widgets/staff_bottom_nav_bar.dart';

class FeedbackListScreen extends ConsumerStatefulWidget {
  const FeedbackListScreen({super.key});

  @override
  ConsumerState<FeedbackListScreen> createState() => _FeedbackListScreenState();
}

class _FeedbackListScreenState extends ConsumerState<FeedbackListScreen> {
  String? _selectedStatus; // null = tất cả

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    await ref.read(staffRoomsProvider.notifier).loadAndSubscribe(token: user.token);
  }

  List<ConversationModel> _filtered(List<ConversationModel> all) {
    if (_selectedStatus == null) return all;
    return all.where((c) => c.status == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffRoomsProvider);
    final filtered = _filtered(state.rooms);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterTabs(),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? _buildError(state.error!)
                      : filtered.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: () => ref.read(staffRoomsProvider.notifier).refresh(),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) =>
                                    _buildConversationCard(context, filtered[index]),
                              ),
                            ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const StaffBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Text(
        'Hỗ trợ khách hàng',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      (null,       'Tất cả'),
      ('Open',     'Chờ xử lý'),
      ('Pending',  'Đang xử lý'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedStatus == tab.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                tab.$2,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedStatus = tab.$1),
              backgroundColor: Colors.grey.shade100,
              selectedColor: AppTheme.primary,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConversationCard(BuildContext context, ConversationModel conv) {
    final hasUnread = conv.unreadCount > 0;

    Color statusColor;
    String statusLabel;
    switch (conv.status) {
      case 'Open':    statusColor = Colors.orange;        statusLabel = 'Chờ xử lý'; break;
      case 'Pending': statusColor = Colors.green;         statusLabel = 'Đang xử lý'; break;
      default:        statusColor = Colors.grey;          statusLabel = conv.status;
    }

    return GestureDetector(
      onTap: () => context.push(
        '/staff-chat/${conv.conversationId}',
        extra: {
          'conversationId': conv.conversationId,
          'customerName':   conv.customerName,
          'status':         conv.status,
        },
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasUnread
                ? AppTheme.primary.withOpacity(0.5)
                : const Color(0xFFE5E7EB),
            width: hasUnread ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: conv.status == 'Closed'
                      ? Colors.grey.shade200
                      : AppTheme.surface,
                  child: Text(
                    conv.customerName.isNotEmpty
                        ? conv.customerName[0].toUpperCase()
                        : 'K',
                    style: TextStyle(
                      color: conv.status == 'Closed'
                          ? Colors.grey
                          : AppTheme.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Status dot
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.customerName,
                          style: TextStyle(
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      // Status chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conv.lastMessagePreview.isEmpty ? 'Cuộc trò chuyện mới' : conv.lastMessagePreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasUnread ? AppTheme.textPrimary : AppTheme.textGray,
                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                  if (conv.staffName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        'NV: ${conv.staffName}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textGray),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Thời gian + badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (conv.lastMessageAt != null)
                  Text(
                    DateFormat('HH:mm').format(conv.lastMessageAt!),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textGray),
                  ),
                const SizedBox(height: 4),
                if (conv.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            _selectedStatus == null
                ? 'Chưa có cuộc trò chuyện nào'
                : 'Không có cuộc trò chuyện "${_selectedStatus}"',
            style: const TextStyle(color: AppTheme.textGray, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
          const SizedBox(height: 8),
          Text(error, style: const TextStyle(color: AppTheme.error)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
