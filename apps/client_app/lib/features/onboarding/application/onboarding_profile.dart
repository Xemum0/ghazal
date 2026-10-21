import 'package:client_app/app/state/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

/// The first letter of a name in its own script, ignoring a leading Arabic `ال` (ADR 0015 D4). Latin initials are capitals.
String obdMonogramFor(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final first = words.isEmpty ? '' : words.first;
  final base = first.runes.length > 2 && first.startsWith('ال') ? first.substring(2) : first;
  if (base.isEmpty) return '';
  return String.fromCharCode(base.runes.first).toUpperCase();
}

/// Writes onboarding answers (ADR 0007 D3, CA-ONB-08): each step confirmed puts its answers on the device draft, never earlier, so Skip
/// leaves the draft untouched. Everything is a fixture id, a civil date, an integer or fils.
extension ObdCommit on WidgetRef {
  WeddingDraftNotifier get _draft => read(weddingDraftProvider.notifier);

  void commitAbout({required WeddingRole? role, required String name, required String partnerName}) => _draft.patch(
        WeddingProfileInput(
          // The neutral role until the couple says otherwise: no gendered form is ever chosen for them (ADR 0013 D2).
          role: role ?? read(weddingDraftProvider).role ?? WeddingRole.family,
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

  /// Final step: stores the areas and publishes the global Brief from the answers (ADR 0007 D3).
  void finishOnboarding(List<String> areaIds) {
    _draft.patch(WeddingProfileInput(areaIds: areaIds));
    final d = read(weddingDraftProvider);
    final women = d.guests?.women ?? 0;
    final date = d.weddingDate;
    read(searchBriefProvider.notifier).set(
      SearchBrief(
        date: date,
        guests: women > 0 ? women : null,
        audience: (d.searching?.isNotEmpty ?? false) ? d.searching!.first : Audience.women,
        areaIds: areaIds,
        budget: d.venueBudget,
        dateMode: date != null ? (d.dateMode ?? DateMode.exact) : DateMode.undecided,
      ),
    );
  }
}
