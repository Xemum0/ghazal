import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show venuesRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart' show Audience, AreasResponse, DateMode, Governorate, GuestSplit, LocalDate, MoneyAmount, MoneyRange, WeddingProfile, WeddingProfileInput, WeddingRole;

import '../../../app/state/state.dart';

/// The open top band of the budget picker is the picker's own maximum (KD 60,000).
const int kBudgetMaxKd = 60000;
const int kBudgetStepKd = 500;
const List<(int, int?)> kBudgetBandsKd = <(int, int?)>[(0, 5000), (5000, 10000), (10000, 20000), (20000, 35000), (35000, null)];
const int kGuestsMax = 1500;

/// A budget as the profile stores it: an open top band is the picker's ceiling.
bool isOpenProfileBudget(int maxFils) => maxFils == 0 || maxFils >= kBudgetMaxKd * 1000;

/// Writes one edit of the wedding file (autosave per field) and the part of the Brief it feeds, so the countdown, the budget and the
/// recommendations follow (ADR 0007 D3, CA-PROF-02, CA-ONB-09). Returns the refusal, or null when saved.
Future<ApiProblem?> saveWedding(WidgetRef ref, WeddingProfileInput input) async {
  try {
    await ref.read(weddingProfileProvider.notifier).patch(input);
  } on ApiProblem catch (e) {
    return e;
  }
  final brief = ref.read(searchBriefProvider.notifier);
  if (input.weddingDate != null || input.dateMode == DateMode.undecided) {
    brief.update((b) => input.weddingDate == null ? b.copyWith(clearDate: true, dateMode: DateMode.undecided) : b.copyWith(date: input.weddingDate, dateMode: input.dateMode ?? DateMode.exact));
  }
  if (input.governorateIds != null) brief.update((b) => b.copyWith(governorateIds: input.governorateIds));
  if (input.venueBudget != null) brief.update((b) => b.copyWith(budget: input.venueBudget));
  if (input.guests != null) {
    brief.update((b) => b.copyWith(guests: (b.audience == Audience.men ? input.guests!.men : input.guests!.women), audience: b.audience ?? Audience.women));
  }
  return null;
}

/// Governorates (and the areas under them, for older profiles; `GET /areas`), read once.
final FutureProvider<AreasResponse> profileAreasProvider = FutureProvider<AreasResponse>((ref) => ref.watch(venuesRepositoryProvider).listAreas());

/// An account with no wedding profile yet edits an empty one; the first save creates it.
WeddingProfile blankWedding(String userId, LocalDate today) => WeddingProfile(
  id: '',
  userId: userId,
  role: WeddingRole.family,
  brideName: '',
  partnerName: null,
  weddingDate: today,
  dateMode: DateMode.undecided,
  guests: const GuestSplit(women: 0, men: 0),
  venueBudget: const MoneyRange(min: MoneyAmount(0), max: MoneyAmount(0)),
  totalBudget: MoneyAmount.zero,
  areaIds: const <String>[],
  governorateIds: const <String>[],
  searching: const <Audience>[],
);

/// The governorates a wedding profile names (ADR 0038): its own list when it has one, else the governorates of the areas an older profile
/// kept (the web `briefGovernorates`), in the order the list gives them.
List<String> profileGovernorateIds(WeddingProfile p, AreasResponse? areas) {
  final own = p.governorateIds;
  if (own != null) return <String>[for (final g in areas?.governorates ?? const <Governorate>[]) if (own.contains(g.id)) g.id];
  if (areas == null) return const <String>[];
  final ids = <String>{for (final a in areas.areas) if (p.areaIds.contains(a.id)) a.governorateId};
  return <String>[for (final g in areas.governorates) if (ids.contains(g.id)) g.id];
}
