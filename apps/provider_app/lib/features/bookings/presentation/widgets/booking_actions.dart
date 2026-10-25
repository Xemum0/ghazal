// What the Bookings screens can do with a request (web `actions.ts`, ADR 0008 D5-D8, ADR 0033 D3), wired to the real request actions and the
// sheets of the Decisions flow, reached by route NAME only.
//   Accept   two taps (open the card, Accept) with the 8 s Undo toast; the compact confirm sheet (HL-DCSN-01) first only when other requests wait
//            on the date or the event is 14 days away or less (ADR 0008 D6). Accepting starts the fixed 24 h confirm window.
//   Decline  the reason sheet (HL-DCSN-02)      Propose  HL-DCSN-03      Cancel  HL-DCSN-04 (revoke or cancel, by status)
//   Call     the contact sheet (HL-BOOK-04)     Chat     the request thread (HL-TODY-05)      Redeem  HL-BOOK-06 with the code
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemMessage;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/state/state.dart';
import '../../../../l10n/l10n.dart';

/// The name as an isolate (first strong direction), so an Arabic name does not reorder an English toast.
String isolate(String s) => String.fromCharCodes([0x2068, ...s.codeUnits, 0x2069]);

class BookingActions {
  BookingActions(this.context, this.ref);

  final BuildContext context;
  final WidgetRef ref;

  GzNavigator get _nav => GzNavigatorScope.of(context);

  Map<String, Object?> _params(Booking b, [Map<String, Object?> extra = const {}]) => <String, Object?>{'bookingId': b.id, ...extra};

  void open(Booking b, {bool conflict = false}) => _nav.push('HL-BOOK-03', params: _params(b, conflict ? {'conflict': true} : const {}));

  void propose(Booking b) => _nav.openSheet('HL-DCSN-03', options: GzSheetOptions(params: _params(b)));
  void decline(Booking b) => _nav.openSheet('HL-DCSN-02', options: GzSheetOptions(params: _params(b)));
  void cancel(Booking b) => _nav.openSheet('HL-DCSN-04', options: GzSheetOptions(params: _params(b)));
  void call(Booking b) => _nav.openSheet('HL-BOOK-04', options: GzSheetOptions(params: _params(b)));
  void chat(PartnerRequestRow r) => _nav.push('HL-TODY-05', params: {'bookingId': r.booking.id, 'conversationId': null});
  void chatBooking(Booking b, {String? conversationId}) => _nav.push('HL-TODY-05', params: {'bookingId': b.id, 'conversationId': conversationId});

  /// The Ghazal support conversation (the same one More > Support opens).
  void support() => _nav.push('HL-TODY-05', params: {'conversationId': 'conv-support-aurelia'});

  /// Opens the redeem screen with the voucher code of this request already in the field.
  void redeem(Booking b, {String? code}) => _nav.push('HL-BOOK-06', params: {'code': code, 'bookingId': b.id});

  Future<void> accept(PartnerRequestRow r) => acceptBooking(r.booking, r.otherRequestsSameDate);

  Future<void> acceptBooking(Booking b, int others) async {
    final f = context.gzFormat;
    final urgent = f.daysUntil(b.eventDate.toString()) <= 14;
    if (others > 0 || urgent) {
      _nav.openSheet('HL-DCSN-01', options: GzSheetOptions(params: _params(b)));
      return;
    }
    final l = context.l10n;
    final gzL = context.gzL10n;
    final nav = _nav;
    final actions = ref.read(requestActionsProvider.notifier);
    final result = await actions.accept(b.id, version: b.version);
    final first = b.clientName.trim().split(RegExp(r'\s+')).first;
    result.when(
      success: (_) => nav.toast(
        GzToastSpec(
          message: l.hotelBookingsAcceptedToast(isolate(first)),
          tone: GzToastTone.success,
          undo: true,
          action: GzToastAction(label: gzL.commonActionUndo, onPressed: () => actions.undo()),
        ),
      ),
      failure: (p) => nav.toast(GzToastSpec(message: gzProblemMessage(gzL, p), tone: GzToastTone.danger)),
      gated: () {},
    );
  }
}
