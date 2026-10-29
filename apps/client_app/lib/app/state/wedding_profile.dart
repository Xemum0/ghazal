import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show weddingRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode;
import 'package:ghazal_domain/ghazal_domain.dart';

import 'client_scope.dart';
import 'search_brief.dart';

/// The couple's wedding profile as the server has it; null when the account has none yet (the empty state of My Wedding). The optional
/// steps after the account is created (CL-ONBD-03 to 05) write it step by step with [WeddingProfileNotifier.patch].
final AsyncNotifierProvider<WeddingProfileNotifier, WeddingProfile?> weddingProfileProvider =
    AsyncNotifierProvider<WeddingProfileNotifier, WeddingProfile?>(WeddingProfileNotifier.new);

class WeddingProfileNotifier extends AsyncNotifier<WeddingProfile?> {
  /// The account whose profile already seeded the Brief: once per account per run, so "Clear all" in the Brief sheet does not bring the
  /// profile back on the next refetch.
  String? _seededFor;

  @override
  Future<WeddingProfile?> build() async {
    final userId = ref.watch(clientUserIdProvider);
    if (userId == null) return null;
    final repo = ref.read(weddingRepositoryProvider);
    try {
      final profile = await repo.getWeddingProfile();
      _seedBriefOnce(userId, profile);
      return profile;
    } on ApiProblem catch (e) {
      if (e.code != ApiProblemCode.notFound) rethrow;
      return null;
    }
  }

  /// The first profile of this account (sign-in, or the first successful GET): fills the blanks of the Brief. A field the person already
  /// set is never overwritten (`fillBlanks`), and an account seeds once.
  void _seedBriefOnce(String? userId, WeddingProfile p) {
    if (userId == null || _seededFor == userId) return;
    _seededFor = userId;
    _seedBrief(p);
  }

  void _seedBrief(WeddingProfile p) => ref
      .read(searchBriefProvider.notifier)
      .fillBlanks(
        SearchBrief.fromWedding(
          weddingDate: p.weddingDate,
          dateMode: p.dateMode,
          womenGuests: p.guests.women,
          searching: p.searching,
          governorateIds: p.governorateIds ?? const <String>[],
          venueBudget: p.venueBudget,
        ),
      );

  /// Replaces the profile with the answers of "Wedding info" (PUT). The blanks of the Brief are filled from the result. Throws `ApiProblem`.
  Future<WeddingProfile?> save(WeddingProfileInput input) async {
    final saved = await ref.read(weddingRepositoryProvider).putWeddingProfile(body: input);
    state = AsyncData(saved);
    _seedBrief(saved);
    return saved;
  }

  /// Changes some fields (PATCH). Falls back to a replace when the account has no profile yet (the first optional step of onboarding).
  Future<WeddingProfile?> patch(WeddingProfileInput input) async {
    final repo = ref.read(weddingRepositoryProvider);
    final current = state.value ?? await future;
    final saved = current == null ? await repo.putWeddingProfile(body: input) : await repo.updateWeddingProfile(body: input);
    state = AsyncData(saved);
    return saved;
  }
}
