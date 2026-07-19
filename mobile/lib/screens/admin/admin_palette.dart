import 'package:flutter/material.dart';

/// Bảng màu riêng của khu vực Admin.
abstract final class AdminPalette {
  static const background = Color(0xFFF8F6FF);
  static const navy = Color(0xFF140B2D);

  static const gradient1 = LinearGradient(
    colors: [Color(0xFF00D9DD), Color(0xFFD8FF77)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const gradient2 = LinearGradient(
    colors: [Color(0xFFFF76E9), Color(0xFF007BFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const gradient3 = LinearGradient(
    colors: [Color(0xFFFFCF40), Color(0xFFFF7EA0)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const gradient4 = LinearGradient(
    colors: [Color(0xFF9462FF), Color(0xFFFF6565)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const gradient5 = LinearGradient(
    colors: [Color(0xFFADFFDB), Color(0xFF7EC7FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const gradient6 = LinearGradient(
    colors: [Color(0xFFFF8385), Color(0xFFA27EFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
