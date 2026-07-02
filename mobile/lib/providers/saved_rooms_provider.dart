// lib/providers/saved_rooms_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedRoomsNotifier extends StateNotifier<Set<String>> {
  SavedRoomsNotifier() : super(const {}) {
    _load();
  }

  static const _key = 'saved_rooms';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = (prefs.getStringList(_key) ?? []).toSet();
  }

  Future<void> toggle(String roomId) async {
    final next = Set<String>.from(state);
    if (next.contains(roomId)) {
      next.remove(roomId);
    } else {
      next.add(roomId);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }
}

final savedRoomsProvider =
    StateNotifierProvider<SavedRoomsNotifier, Set<String>>(
        (_) => SavedRoomsNotifier());
