import 'package:client_app/app/state/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

import 'voucher_model.dart';
import 'voucher_quote.dart' show voucherConfigProvider;

/// The signed-in client's vouchers in the server's wallet order (a ready credit voucher first, then the bound ones by state, the ended
/// credit vouchers last); a guest has none. Refetches after every write (`clientDataRevisionProvider`).
final FutureProvider<List<WalletItem>> walletProvider = FutureProvider.autoDispose<List<WalletItem>>((ref) async {
  ref.watch(clientDataRevisionProvider);
  if (!ref.watch(sessionProvider.select((s) => s.isSignedIn))) return const <WalletItem>[];
  final page = await ref.watch(vouchersRepositoryProvider).listVouchers(limit: 50);
  return page.items;
});

/// One voucher with its request, options and refund request. [id] is a voucher id or code.
final voucherDetailProvider = FutureProvider.autoDispose.family<VoucherDetail, String>((ref, id) async {
  ref.watch(clientDataRevisionProvider);
  return ref.watch(vouchersRepositoryProvider).getVoucher(voucherId: id);
});

/// The voucher id a screen is about: the `voucherId` param, else [fallback] (the hero voucher, so the harness opens any frame).
String voucherIdParam(Map<String, Object?> params, {String fallback = kVoucherHeroId}) {
  final v = params['voucherId'];
  return v is String && v.isNotEmpty ? v : fallback;
}

/// The bound vouchers of the wallet (a credit voucher is not tied to a venue, so quote matching ignores it).
List<Voucher> boundOf(List<WalletItem> items) => [
  for (final i in items)
    if (i.voucher case final Voucher v) v,
];

/// A voucher detail with the platform rules the screen prints next to it (fee, validity, reuse, confirm window, reply time).
typedef VoucherView = ({VoucherDetail detail, PlatformConfig config});

final voucherViewProvider = FutureProvider.autoDispose.family<VoucherView, String>((ref, id) async {
  final detail = await ref.watch(voucherDetailProvider(id).future);
  final config = await ref.watch(voucherConfigProvider.future);
  return (detail: detail, config: config);
});
