import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The params CL-BOOK-01 takes to start a request that is already bound to [v] (the quote is prefilled and locked): web `requestParams`.
Map<String, Object?> requestParamsOf(Voucher v) => <String, Object?>{
  if (v.targetType == VoucherTargetType.venue) 'venueId': v.venueOrProviderId else 'providerId': v.venueOrProviderId,
  'voucherId': v.id,
  'date': v.eventDate.toString(),
  if (v.hallId != null) 'hallId': v.hallId,
  if (v.guests != null) 'guests': v.guests,
  'fresh': true,
};

/// Opens the request flow bound to [v] (a ready voucher: Send request; a released one: Use again).
void openRequestFor(GzNavigator nav, Voucher v) => nav.push('CL-BOOK-01', params: requestParamsOf(v));

/// The params of the detail screen of the venue or provider a voucher is for.
({String id, Map<String, Object?> params}) detailRouteOf(VoucherTargetType type, String targetId) => type == VoucherTargetType.provider
    ? (id: 'CL-SERV-03', params: <String, Object?>{'providerId': targetId, 'vendorId': targetId})
    : (id: 'CL-VENU-01', params: <String, Object?>{'venueId': targetId});
