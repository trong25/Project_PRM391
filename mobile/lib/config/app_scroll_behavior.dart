// lib/config/app_scroll_behavior.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// ScrollBehavior tùy chỉnh, cho phép vuốt/kéo bằng chuột, trackpad, stylus
/// (cần thiết cho Flutter Web/Desktop, vì mặc định chỉ hỗ trợ touch).
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}