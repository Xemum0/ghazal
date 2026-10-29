import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show venuesRepositoryProvider, weddingRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart';

import '../../../app/state/app_config.dart';

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
}

/// The five budget bands of the venue-and-catering question.
final FutureProvider<List<BudgetBand>> onboardingBudgetBandsProvider = FutureProvider<List<BudgetBand>>(
  (ref) => ref.watch(weddingRepositoryProvider).listBudgetBands(),
);

/// Occasion markers and the availability window (the calendar's upper bound).
final FutureProvider<AppConfig> onboardingConfigProvider = publicAppConfigProvider;

/// The roster's hall prices (dinars) for [guests] ladies: the data of the budget histogram (null guests: each hall's minimum).
final onboardingPricesProvider = FutureProvider.family<List<int>, int?>((ref, guests) async {
  final page = await ref.watch(venuesRepositoryProvider).searchVenues(guests: guests, audience: Audience.women, limit: 50);
  return <int>[
    for (final r in page.items)
      if (r.price != null) (r.price!.amount.fils / 1000).round(),
  ];
});
