// The package names of the signed-in venue: a request only carries its package id, the card shows the name.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show venuesRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalizedText;

import '../../../app/state/state.dart';

/// Package id to name for the active venue (empty for a service provider, whose requests carry no package).
final FutureProvider<Map<String, LocalizedText>> venuePackageNamesProvider = FutureProvider.autoDispose<Map<String, LocalizedText>>((ref) async {
  final ctx = ref.watch(partnerContextProvider);
  final id = ctx?.venueId;
  if (id == null) return const <String, LocalizedText>{};
  final detail = await ref.read(venuesRepositoryProvider).getVenue(venueId: id);
  return <String, LocalizedText>{for (final p in detail.packages) p.package.id: p.package.name};
});
