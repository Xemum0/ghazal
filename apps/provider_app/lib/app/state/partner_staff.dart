import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show partnerAccountRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart';

/// The venue's staff (the pool a visit representative or a redeemer is looked up in): one fetch shared by the features that need it.
final partnerStaffProvider = FutureProvider.autoDispose<List<StaffMember>>((ref) async {
  final list = await ref.watch(partnerAccountRepositoryProvider).listStaff();
  return list.staff;
});
