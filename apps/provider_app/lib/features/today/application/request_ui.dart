// What a hotel manager can do to a request from Today and Needs you (web `today/_components/actions.ts`, ADR 0008 D5-D7), wired to the real
// request actions: accept is two taps from the row (expand, Accept) with the 8 s Undo toast, after a confirm sheet (HL-DCSN-01) only when
// other requests wait on the date or the event is 14 days away or less (ADR 0008 D6). Reschedule and Decline open their sheets.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemMessage;
import 'package:ghazal_domain/ghazal_domain.dart' show PartnerRequestDetail, PartnerRequestRow;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';

class RequestUi {
  RequestUi(this.context, this.ref);

  final BuildContext context;
  final WidgetRef ref;

  GzNavigator get _nav => GzNavigatorScope.of(context);

  Map<String, Object?> _params(PartnerRequestRow r) => <String, Object?>{'bookingId': r.booking.id};

  Future<void> accept(PartnerRequestRow r) => _accept(r.booking.id, r.booking.version, r.booking.eventDate.toString(), r.otherRequestsSameDate);

  Future<void> acceptDetail(PartnerRequestDetail d) => _accept(d.booking.id, d.booking.version, d.booking.eventDate.toString(), d.otherRequestsSameDate);

  void declineDetail(PartnerRequestDetail d) => _nav.openSheet('HL-DCSN-02', options: GzSheetOptions(params: <String, Object?>{'bookingId': d.booking.id}));

  Future<void> _accept(String id, int version, String eventDate, int others) async {
    final f = context.gzFormat;
    final urgent = f.daysUntil(eventDate) <= 14;
    if (others > 0 || urgent) {
      _nav.openSheet('HL-DCSN-01', options: GzSheetOptions(params: <String, Object?>{'bookingId': id}));
      return;
    }
    final l = context.l10n;
    final gzL = context.gzL10n;
    final nav = _nav;
    final actions = ref.read(requestActionsProvider.notifier);
    final result = await actions.accept(id, version: version);
    result.when(
      success: (_) => nav.toast(
        GzToastSpec(
          message: l.hotelTodayAcceptedToast,
          tone: GzToastTone.success,
          undo: true,
          action: GzToastAction(label: l.commonActionUndo, onPressed: () => actions.undo()),
        ),
      ),
      failure: (p) => nav.toast(GzToastSpec(message: gzProblemMessage(gzL, p), tone: GzToastTone.danger)),
      gated: () {},
    );
  }

  void reschedule(PartnerRequestRow r) => _nav.openSheet('HL-DCSN-03', options: GzSheetOptions(params: _params(r)));
  void decline(PartnerRequestRow r) => _nav.openSheet('HL-DCSN-02', options: GzSheetOptions(params: _params(r)));
  void open(PartnerRequestRow r) => _nav.push('HL-BOOK-03', params: _params(r));
  void call(PartnerRequestRow r) => _nav.openSheet('HL-BOOK-04', options: GzSheetOptions(params: _params(r)));
  void compare(PartnerRequestRow r) => _nav.push('HL-BOOK-03', params: {..._params(r), 'conflict': true});
  void chat(PartnerRequestRow r, {String? conversationId}) =>
      _nav.push('HL-TODY-05', params: {'bookingId': r.booking.id, 'conversationId': conversationId});
}
