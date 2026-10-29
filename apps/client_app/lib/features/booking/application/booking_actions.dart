import 'package:client_app/app/state/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_ui/ghazal_ui.dart' show GzNavigator, GzSheetOptions;

import 'booking_flow_local.dart';
import 'booking_flow_model.dart';
import 'booking_hero.dart';

/// The four steps by inventory id (the progress thread, the Edit links): event, package, details, review. CL-BOOK-03 (Extras) is retired
/// (ADR 0038, CA-SVC-19), so the third step is CL-BOOK-04.
const List<String> kBookingStepIds = <String>['CL-BOOK-01', 'CL-BOOK-02', 'CL-BOOK-04', 'CL-BOOK-05'];

/// Root screen of each main tab (web `tabRoot`): where the flow ends.
const Map<String, String> kBookingTabRoots = <String, String>{'discover': 'CL-DISC-01', 'my-wedding': 'CL-WEDD-01', 'messages': 'CL-MSGS-01'};

/// The params a voucher purchase needs for this quote (CL-VCHR-01 binds one venue and its quote at purchase).
Map<String, Object?> bookingVoucherParams(FlowModel flow, String from) => <String, Object?>{
  'venueId': flow.venue.id,
  'hallId': flow.section.hall.id,
  'packageId': flow.section.effective?.pkg.id,
  'date': flow.date.toString(),
  'guests': flow.section.guests,
  'from': from,
};

/// Edits the draft; while it is empty the hero story is the base, so a step opened directly keeps working.
void patchBookingDraft(WidgetRef ref, BookingDraft Function(BookingDraft current) change) {
  ref.read(bookingDraftProvider.notifier).patch((cur) => change(cur.venueId == null ? heroDraft() : cur));
}

/// Get a voucher (the commit moment of ADR 0033): the voucher purchase sheet opens with the exact quote (every client is signed in,
/// ADR 0038).
void getBookingVoucher(GzNavigator nav, FlowModel flow, String from) {
  nav.openSheet('CL-VCHR-01', options: GzSheetOptions(params: bookingVoucherParams(flow, from)));
}

/// Change the quote the voucher is bound to (CL-VCHR-04, where the saving test is re-run).
void changeBookingVoucher(GzNavigator nav, FlowModel flow, String from) => nav.openSheet(
  'CL-VCHR-04',
  options: GzSheetOptions(params: <String, Object?>{...bookingVoucherParams(flow, from), 'voucherId': flow.voucher?.id}),
);

/// Where an Edit link goes: back to the step if its screen is still on the stack, else a replacement.
void goBookingStep(WidgetRef ref, GzNavigator nav, {required int from, required int to}) {
  final target = kBookingStepIds[to - 1];
  if (to < from && ref.read(bookingFlowLocalProvider).entered.contains(to)) {
    nav.pop(count: from - to);
  } else {
    nav.replace(target);
  }
}

/// The flow is over: reset the navigator to the tab asked for (optionally with one screen on top so Back lands in a real place), then
/// clear the draft and this flow's memory.
void leaveBookingFlow(WidgetRef ref, GzNavigator nav, String tab, {String? thenId, Map<String, Object?> thenParams = const <String, Object?>{}}) {
  nav.reset(kBookingTabRoots[tab] ?? 'CL-DISC-01');
  if (thenId != null) nav.push(thenId, params: thenParams);
  ref.read(bookingDraftProvider.notifier).reset();
  ref.read(bookingFlowLocalProvider.notifier).reset();
}

/// Makes the draft say what the flow model resolved (the voucher found in the wallet binds date, hall, package and guests; a step opened
/// directly keeps the session and audience too), so what is sent is what the screens showed. No write while the hero story stands in.
void syncBookingDraft(WidgetRef ref, FlowModel flow) {
  final v = flow.voucher;
  if (flow.demo || v == null) return;
  final draft = ref.read(bookingDraftProvider);
  final sec = flow.section;
  final want = draft.copyWith(
    venueId: flow.venue.id,
    voucherId: v.id,
    eventDate: flow.date,
    hallId: sec.hall.id,
    packageId: v.packageId,
    guests: sec.guests,
    audience: flow.audience,
    sessionId: sec.sessionId,
  );
  if (want != draft) ref.read(bookingDraftProvider.notifier).patch((_) => want);
}
