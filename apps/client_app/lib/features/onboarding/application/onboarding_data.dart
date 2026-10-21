import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show homeRepositoryProvider, venuesRepositoryProvider, weddingRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart';

/// The hero story of the onboarding screens (web `weddingProfile` fixture, Reem and Fahad): what an opened-without-params screen shows.
abstract final class ObdStory {
  static const WeddingRole role = WeddingRole.bride;
  static const String nameAr = 'ريم الدوسري';
  static const String nameEn = 'Reem Al-Dosari';
  static const String partnerAr = 'فهد الشمري';
  static const String partnerEn = 'Fahad Al-Shammari';
  static const LocalDate date = LocalDate(2027, 1, 14);
  static const int guestsWomen = 350;
  static const int guestsMen = 400;
  static const int budgetMinFils = 20000000;
  static const int budgetMaxFils = 35000000;
  static const List<String> areas = <String>['salmiya', 'sharq'];
}

/// Governorates and areas of Kuwait (reference data, public).
final FutureProvider<AreasResponse> onboardingAreasProvider = FutureProvider<AreasResponse>((ref) => ref.watch(venuesRepositoryProvider).listAreas());

/// The five budget bands of the venue-and-catering question.
final FutureProvider<List<BudgetBand>> onboardingBudgetBandsProvider = FutureProvider<List<BudgetBand>>(
  (ref) => ref.watch(weddingRepositoryProvider).listBudgetBands(),
);

/// Occasion markers and the availability window (the calendar's upper bound).
final FutureProvider<AppConfig> onboardingConfigProvider = FutureProvider<AppConfig>((ref) => ref.watch(homeRepositoryProvider).getAppConfig());

/// Every hall of the roster (no Brief): the area of each, to tell which areas have halls.
final FutureProvider<List<VenueResult>> onboardingRosterProvider = FutureProvider<List<VenueResult>>((ref) async {
  final page = await ref.watch(venuesRepositoryProvider).searchVenues(limit: 50);
  return page.items;
});

/// The roster's hall prices (dinars) for [guests] ladies: the data of the budget histogram (null guests: each hall's minimum).
final onboardingPricesProvider = FutureProvider.family<List<int>, int?>((ref, guests) async {
  final page = await ref.watch(venuesRepositoryProvider).searchVenues(guests: guests, audience: Audience.women, limit: 50);
  return <int>[
    for (final r in page.items)
      if (r.price != null) (r.price!.amount.fils / 1000).round(),
  ];
});

/// The live count of halls the area choice shows on Home (the same query the Brief runs). The key is the comma-joined area ids (a record
/// holding a list is not value-equal, so it cannot key a family).
final onboardingHallCountProvider = FutureProvider.family<int, (String, int?)>((ref, q) async {
  final ids = q.$1.isEmpty ? null : q.$1.split(',');
  final result = await ref.watch(venuesRepositoryProvider).countVenues(areaIds: ids, guests: q.$2, audience: Audience.women);
  return result.count;
});
