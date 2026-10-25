// The sample codes of the redeem screen's demo chips (web `sampleCodes`): one live code per outcome, read from the partner's own lists.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show partnerBookingsRepositoryProvider;

import '../../../app/state/state.dart';
import 'bookings_data.dart';

class SampleCodes {
  const SampleCodes({this.ready, this.notConfirmed, this.used});
  final String? ready;
  final String? notConfirmed;
  final String? used;
}

final sampleCodesProvider = FutureProvider.autoDispose<SampleCodes>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  final repo = ref.read(partnerBookingsRepositoryProvider);
  final ready = await repo.listRedeemableVouchers(limit: 5);
  final used = await repo.listRedeemedVouchers(limit: 5);
  final split = await ref.watch(bookingsSplitProvider(kSegAwaiting).future);
  return SampleCodes(
    ready: ready.items.map((r) => r.voucher.code).firstOrNull,
    used: used.items.map((r) => r.voucher.code).firstOrNull,
    notConfirmed: split.awaiting.map((r) => r.voucher?.code).whereType<String>().firstOrNull,
  );
});
