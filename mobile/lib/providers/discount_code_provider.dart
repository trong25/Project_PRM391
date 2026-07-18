// lib/providers/discount_code_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/discount_code_model.dart';
import '../services/discount_code_service.dart';

final discountCodeServiceProvider = Provider<DiscountCodeService>((ref) => DiscountCodeService());

final activeDiscountCodesProvider = FutureProvider<List<DiscountCodeModel>>((ref) async {
  final service = ref.watch(discountCodeServiceProvider);
  return service.getActiveDiscountCodes();
});
