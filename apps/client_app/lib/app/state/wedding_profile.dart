import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show weddingRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode, GzLogger;
import 'package:ghazal_domain/ghazal_domain.dart';

import 'client_scope.dart';
import 'search_brief.dart';

final GzLogger _log = GzLogger('wedding-profile');

/// The onboarding answers of a guest (everything optional: the person may stop at any step). Persisted on the device (`gz.state.wedding`)
/// and sent with `putWeddingProfile` at the first sign-in that finds no profile on the server.
final NotifierProvider<WeddingDraftNotifier, WeddingProfileInput> weddingDraftProvider = NotifierProvider<WeddingDraftNotifier, WeddingProfileInput>(
  WeddingDraftNotifier.new,
);

class WeddingDraftNotifier extends Notifier<WeddingProfileInput> {
  static const String _key = 'wedding';

  @override
  WeddingProfileInput build() {
    final raw = ref.read(stateBoxProvider).getString(_key);
    if (raw == null) return const WeddingProfileInput();
    try {
      return WeddingProfileInput.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } on Object {
      return const WeddingProfileInput();
    }
  }

  bool get isEmpty => state.toJson().values.every((v) => v == null);

  /// Merges the non-null fields of [patch] into the draft.
  void patch(WeddingProfileInput patch) {
    state = merge(state, patch);
    ref.read(stateBoxProvider).setString(_key, jsonEncode(state.toJson()));
  }

  void clear() {
    state = const WeddingProfileInput();
    ref.read(stateBoxProvider).remove(_key);
  }

  /// The non-null fields of [b] over [a].
  static WeddingProfileInput merge(WeddingProfileInput a, WeddingProfileInput b) => WeddingProfileInput(
    role: b.role ?? a.role,
    brideName: b.brideName ?? a.brideName,
    partnerName: b.partnerName ?? a.partnerName,
    weddingDate: b.weddingDate ?? a.weddingDate,
    dateMode: b.dateMode ?? a.dateMode,
    guests: b.guests ?? a.guests,
    venueBudget: b.venueBudget ?? a.venueBudget,
    totalBudget: b.totalBudget ?? a.totalBudget,
    areaIds: b.areaIds ?? a.areaIds,
    searching: b.searching ?? a.searching,
  );
}

/// The couple's wedding profile as the server has it; null when the account has none yet (the empty state of My Wedding). A guest has no
/// server profile: the answers sit in [weddingDraftProvider] until the sign-in, when the draft is sent and cleared.
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
      return _syncDraft(repo);
    }
  }

  /// The first sign-in after onboarding as a guest: the draft becomes the account's profile.
  Future<WeddingProfile?> _syncDraft(WeddingRepository repo) async {
    final draft = ref.read(weddingDraftProvider);
    if (ref.read(weddingDraftProvider.notifier).isEmpty) return null;
    try {
      final created = await repo.putWeddingProfile(body: draft);
      ref.read(weddingDraftProvider.notifier).clear();
      _seedBriefOnce(ref.read(clientUserIdProvider), created);
      return created;
    } on ApiProblem catch (e) {
      if (e.isTransient) rethrow;
      _log.warning('the onboarding draft was refused (${e.code.wire}); it stays on the device');
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
          areaIds: p.areaIds,
          venueBudget: p.venueBudget,
        ),
      );

  /// Saves the answers of onboarding or of "Wedding info": a guest's go to the device draft (returns null); a signed-in client's replace
  /// the profile on the server (PUT). The blanks of the Brief are filled from the result. Throws `ApiProblem`.
  Future<WeddingProfile?> save(WeddingProfileInput input) async {
    if (ref.read(clientUserIdProvider) == null) {
      ref.read(weddingDraftProvider.notifier).patch(input);
      final d = ref.read(weddingDraftProvider);
      ref
          .read(searchBriefProvider.notifier)
          .fillBlanks(
            SearchBrief.fromWedding(
              weddingDate: d.weddingDate,
              dateMode: d.dateMode ?? DateMode.undecided,
              womenGuests: d.guests?.women,
              searching: d.searching ?? const <Audience>[],
              areaIds: d.areaIds ?? const <String>[],
              venueBudget: d.venueBudget,
            ),
          );
      return null;
    }
    final saved = await ref.read(weddingRepositoryProvider).putWeddingProfile(body: input);
    state = AsyncData(saved);
    _seedBrief(saved);
    return saved;
  }

  /// Changes some fields (PATCH). Falls back to a replace when the account has no profile yet. A guest's patch merges into the draft.
  Future<WeddingProfile?> patch(WeddingProfileInput input) async {
    if (ref.read(clientUserIdProvider) == null) return save(input);
    final repo = ref.read(weddingRepositoryProvider);
    final current = state.value ?? await future;
    final saved = current == null ? await repo.putWeddingProfile(body: input) : await repo.updateWeddingProfile(body: input);
    state = AsyncData(saved);
    return saved;
  }
}
