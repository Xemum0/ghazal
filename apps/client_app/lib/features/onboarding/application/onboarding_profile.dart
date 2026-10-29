import 'package:client_app/app/state/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzNavigatorProvider, profileRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, GzLogger;
import 'package:ghazal_domain/ghazal_domain.dart';

final GzLogger _log = GzLogger('onboarding');

/// The first letter of a name in its own script, ignoring a leading Arabic `ال` (ADR 0015 D4). Latin initials are capitals.
String obdMonogramFor(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final first = words.isEmpty ? '' : words.first;
  final base = first.runes.length > 2 && first.startsWith('ال') ? first.substring(2) : first;
  if (base.isEmpty) return '';
  return String.fromCharCode(base.runes.first).toUpperCase();
}

/// What the account already knows about the person: the name and the sex given at "About you". The first optional step starts from it
/// (the name filled in, the role suggested from the sex: OQ-R2-06). Null without a session.
final FutureProvider<({String name, Sex? sex})?> obdAccountProvider = FutureProvider<({String name, Sex? sex})?>((ref) async {
  if (ref.watch(clientUserIdProvider) == null) return null;
  final me = await ref.watch(profileRepositoryProvider).getMe();
  return (name: me.user.name, sex: me.user.sex);
});

/// The role a sex suggests for the wedding, as a convenience only: it is a chip the person can change (OQ-R2-06, ADR 0013).
WeddingRole? obdRoleForSex(Sex? sex) => switch (sex) {
  Sex.female => WeddingRole.bride,
  Sex.male => WeddingRole.groom,
  _ => null,
};

/// The answers of the optional steps (CL-ONBD-03 to 05), collected in memory as each step is confirmed and written once at the end
/// ([ObdCommit.finishOnboarding]). A skipped step writes nothing.
final NotifierProvider<ObdDraftNotifier, WeddingProfileInput> obdDraftProvider = NotifierProvider<ObdDraftNotifier, WeddingProfileInput>(ObdDraftNotifier.new);

class ObdDraftNotifier extends Notifier<WeddingProfileInput> {
  @override
  WeddingProfileInput build() => const WeddingProfileInput();

  bool get isEmpty => state.toJson().values.every((v) => v == null);

  /// Merges the non-null fields of [patch] into the draft.
  void patch(WeddingProfileInput patch) => state = merge(state, patch);

  void clear() => state = const WeddingProfileInput();

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
    governorateIds: b.governorateIds ?? a.governorateIds,
    searching: b.searching ?? a.searching,
  );
}

/// Writes onboarding answers (ADR 0007 D3, CA-ONB-08): each step confirmed puts its answers on the draft, never earlier, so Skip leaves the
/// draft untouched. Everything is a civil date, an integer or fils.
extension ObdCommit on WidgetRef {
  ObdDraftNotifier get _draft => read(obdDraftProvider.notifier);

  void commitAbout({required WeddingRole? role, required String name, required String partnerName}) => _draft.patch(
    WeddingProfileInput(
      // The neutral role until the couple says otherwise: no gendered form is ever chosen for them (ADR 0013 D2).
      role: role ?? read(obdDraftProvider).role ?? WeddingRole.family,
      brideName: name.trim().isEmpty ? null : name.trim(),
      partnerName: partnerName.trim().isEmpty ? null : partnerName.trim(),
    ),
  );

  void commitDate({required LocalDate? date, required DateMode mode}) => _draft.patch(WeddingProfileInput(weddingDate: date, dateMode: mode));

  void commitGuestsBudget({required int women, required int men, required MoneyRange? budget}) => _draft.patch(
    WeddingProfileInput(
      guests: GuestSplit(women: women, men: men),
      venueBudget: budget,
      searching: const <Audience>[Audience.women],
    ),
  );

  /// The last optional step is over (Done or Skip): the answers become the account's wedding profile and the global Brief, the stack is
  /// replaced by Home and the Face ID offer is queued for it. The Client app asks for no area (ADR 0038 D1): the Brief carries the date,
  /// guests, section and budget; the governorates are chosen in the Brief sheet on Home. Nothing is written when every step was skipped.
  Future<void> finishOnboarding() async {
    final d = read(obdDraftProvider);
    final nav = read(gzNavigatorProvider);
    final answered = !_draft.isEmpty;
    if (answered) {
      try {
        await read(weddingProfileProvider.notifier).patch(d);
      } on ApiProblem catch (e) {
        _log.warning('the onboarding answers were refused (${e.code.wire}); the Brief still takes them');
      }
      final women = d.guests?.women ?? 0;
      final date = d.weddingDate;
      read(searchBriefProvider.notifier).set(
        SearchBrief(
          date: date,
          guests: women > 0 ? women : null,
          audience: (d.searching?.isNotEmpty ?? false) ? d.searching!.first : Audience.women,
          budget: d.venueBudget,
          dateMode: date != null ? (d.dateMode ?? DateMode.exact) : DateMode.undecided,
        ),
      );
    }
    _draft.clear();
    nav.reset('CL-DISC-01');
    askBiometricOffer();
  }
}
