// NeedQueue: the rows of the Needs-you queue, shared by Today (requests, visits and listings, compact) and the full queue (HL-TODY-02, every type).
// One request row at a time opens in place as the full triage card, so Accept is two taps from the list (ADR 0008 D6). Every other item opens its
// object (a thread, a visit, a booking, a review) and the weekly calendar check confirms in place.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/state/state.dart';
import '../../application/request_ui.dart';
import '../../application/today_data.dart';
import '../../application/venue_packages.dart';
import 'need_row.dart';

/// The weekly calendar check, confirmed in place for this run of the app (no endpoint carries it yet: requests.md).
final NotifierProvider<CalendarConfirmed, bool> calendarConfirmedProvider = NotifierProvider<CalendarConfirmed, bool>(CalendarConfirmed.new);

class CalendarConfirmed extends Notifier<bool> {
  @override
  bool build() => false;

  void confirm() => state = true;
}

class NeedQueue extends ConsumerStatefulWidget {
  const NeedQueue({required this.entries, this.initiallyOpen, this.detail = false, super.key});

  final List<NeedItem> entries;

  /// The booking id of the request that is open on arrival.
  final String? initiallyOpen;
  final bool detail;

  @override
  ConsumerState<NeedQueue> createState() => _NeedQueueState();
}

class _NeedQueueState extends ConsumerState<NeedQueue> {
  String? _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initiallyOpen;
  }

  void _openObject(NeedItem e) {
    final nav = GzNavigatorScope.of(context);
    switch (e.kind) {
      case NeedKind.message:
        nav.push('HL-TODY-05', params: {'conversationId': e.item.conversationId, 'bookingId': e.item.bookingId});
      case NeedKind.visit:
        nav.push('HL-VIST-02', params: {'visitId': e.item.visitId});
      case NeedKind.review:
        nav.push('HL-GROW-06', params: {'reviewId': e.item.reviewId});
      case NeedKind.request || NeedKind.awaiting:
        nav.push('HL-BOOK-03', params: {'bookingId': e.item.bookingId});
      case NeedKind.calendar:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = RequestUi(context, ref);
    final provider = ref.watch(partnerContextProvider)?.isProvider ?? false;
    final names = ref.watch(venuePackageNamesProvider).value ?? const {};
    final entries = widget.entries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < entries.length; i++)
          Builder(
            builder: (context) {
              final e = entries[i];
              final r = e.request;
              final isOpen = !provider && e.kind == NeedKind.request && r != null && _open == r.booking.id;
              if (isOpen) {
                return Padding(
                  padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GzRequestCard(
                        request: r,
                        packageName: r.booking.sections.isEmpty ? null : names[r.booking.sections.first.packageId],
                        state: GzRequestCardState.viewed,
                        inlineUndo: false,
                        onOpen: () => ui.open(r),
                        onAccept: () {
                          setState(() => _open = null);
                          ui.accept(r);
                        },
                        onReschedule: () => ui.reschedule(r),
                        onDecline: () => ui.decline(r),
                        onChat: () => ui.chat(r),
                        onCall: () => ui.call(r),
                        onCompare: () => ui.compare(r),
                      ),
                      const SizedBox(height: GzSpace.s1),
                      Center(
                        child: GzIconButton(
                          icon: GzIcons.chevronUp,
                          iconSize: GzIconSize.sm,
                          label: context.gzL10n.commonActionShowLess,
                          onPressed: () => setState(() => _open = null),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return NeedRow(
                entry: e,
                detail: widget.detail,
                expandable: !provider,
                last: i == entries.length - 1,
                onPressed: () {
                  if (!provider && e.kind == NeedKind.request && r != null) {
                    setState(() => _open = _open == r.booking.id ? null : r.booking.id);
                  } else {
                    _openObject(e);
                  }
                },
                onConfirm: () => ref.read(calendarConfirmedProvider.notifier).confirm(),
              );
            },
          ),
      ],
    );
  }
}
