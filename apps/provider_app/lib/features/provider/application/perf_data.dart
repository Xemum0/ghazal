// Reads of Listing performance (HL-PROV-07, web `provider/_components/perf.ts`): the range the person picked and the figures the API returns
// for it (`getListingPerformance`). No revenue anywhere: the client pays the provider directly and Ghazal does not see it.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show partnerGrowthRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart';

import '../../../app/state/state.dart';

enum RangeId { month, d30, d90, custom }

/// Days of data before today (the oldest day a custom range can start on) and the least span with enough data for a funnel.
const int kDataDays = 120;
const int kMinFunnelDays = 7;

@immutable
final class PerfArgs {
  const PerfArgs(this.listingId, this.from, this.to);
  final String listingId;
  final LocalDate from;
  final LocalDate to;

  int get days => from.daysUntil(to) + 1;

  @override
  bool operator ==(Object other) => other is PerfArgs && other.listingId == listingId && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(listingId, from, to);
}

/// The span of a range chip, ending today (this month runs from the 1st).
(LocalDate, LocalDate) spanOf(RangeId id, LocalDate today, (LocalDate, LocalDate)? custom) => switch (id) {
  RangeId.custom when custom != null => custom,
  RangeId.d30 => (today.addDays(-29), today),
  RangeId.d90 => (today.addDays(-89), today),
  _ => (LocalDate(today.year, today.month, 1), today),
};

final listingPerformanceProvider = FutureProvider.autoDispose.family<ListingPerformance, PerfArgs>((ref, a) async {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerGrowthRepositoryProvider).getListingPerformance(listingId: a.listingId, from: a.from, to: a.to);
});
