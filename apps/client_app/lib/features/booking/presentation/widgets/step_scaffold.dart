import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show gzFormatProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/booking_actions.dart';
import '../../application/booking_flow_local.dart';
import '../../application/booking_flow_providers.dart';

/// The scaffold every step of the request flow draws itself in (web `StepScreen`), so the four steps feel like one place. Pinned top: the
/// venue name and the progress thread (a glyph per step, no words). The body opens with the step's serif title and an optional info
/// glyph. Pinned bottom: the action bar with the one gold action. Back is always safe (the draft autosaves); step 1 asks before leaving.
class BookingStepScaffold extends ConsumerStatefulWidget {
  const BookingStepScaffold({
    required this.step,
    required this.venueName,
    required this.title,
    required this.children,
    this.info,
    this.notice,
    this.action,
    this.summary,
    this.showBar = true,
    super.key,
  });

  final int step;
  final String venueName;
  final String title;

  /// The info glyph beside the title (a [GzInfoButton]).
  final Widget? info;

  /// A state line under the progress thread (offline, price error, a taken date).
  final Widget? notice;
  final List<Widget> children;
  final GzActionBarAction? action;
  final Widget? summary;

  /// False when the screen is one state that carries its own single action (the load error).
  final bool showBar;

  static const List<IconData> _icons = <IconData>[GzIcons.calendar, GzIcons.package, GzIcons.user, GzIcons.checklist];

  @override
  ConsumerState<BookingStepScaffold> createState() => _BookingStepScaffoldState();
}

class _BookingStepScaffoldState extends ConsumerState<BookingStepScaffold> {
  late final BookingFlowLocalNotifier _local = ref.read(bookingFlowLocalProvider.notifier);
  late final int _step = widget.step;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _local.markEntered(_step, on: true));
  }

  @override
  void dispose() {
    final local = _local;
    final step = _step;
    Future<void>.microtask(() => local.markEntered(step, on: false));
    super.dispose();
  }

  Future<void> _leave() async {
    final l10n = context.l10n;
    final nav = context.gzNav;
    final answer = await nav.openDialog(
      GzDialogSpec(
        title: l10n.clientBookingLeaveTitle,
        body: l10n.clientBookingLeaveBody,
        icon: GzIcons.bookmark,
        confirmLabel: l10n.clientBookingLeaveConfirm,
        cancelLabel: l10n.clientBookingLeaveKeep,
      ),
    );
    if (answer != GzDialogResult.confirm) return;
    // Back is always safe; a step opened with nothing behind it (a resumed draft) goes to the venue it is about.
    final venueId = ref.read(effectiveBookingDraftProvider).venueId;
    if (nav.canGoBack || venueId == null) {
      nav.pop();
    } else {
      nav.replace('CL-VENU-01', params: <String, Object?>{'venueId': venueId});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = ref.watch(gzFormatProvider);
    final c = context.gz.colors;
    final w = widget;
    ref.listen(bookingFlowProvider, (prev, next) {
      final flow = next.value;
      if (flow != null) syncBookingDraft(ref, flow);
    });
    final names = <String>[
      l10n.clientBookingEventTitle,
      l10n.clientBookingPackageTitle,
      l10n.clientBookingDetailsTitle,
      l10n.clientBookingReviewTitle,
    ];
    final steps = <GzIconProgressStep>[
      for (var i = 0; i < 4; i++)
        GzIconProgressStep(
          id: 'step${i + 1}',
          icon: BookingStepScaffold._icons[i],
          label: names[i],
          state: i + 1 < w.step ? GzKnotState.tied : (i + 1 == w.step ? GzKnotState.now : GzKnotState.open),
        ),
    ];
    final first = w.step == 1;
    return GzScreen(
      top: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GzTopBar(
            title: w.venueName,
            back: first ? GzTopBarBack.close : GzTopBarBack.auto,
            onBack: first ? _leave : null,
            backLabel: first ? context.gzL10n.commonActionClose : null,
            rule: false,
          ),
          ColoredBox(
            color: c.surfaceCanvas,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.s2),
              child: GzIconProgress(
                steps: steps,
                label: l10n.clientBookingStepsLabel,
                describe: l10n.clientBookingStepOf(f.integer(w.step), f.integer(4)),
                labels: GzProgressLabels.none,
                draw: GzDraw.mount,
              ),
            ),
          ),
        ],
      ),
      bottom: w.showBar && w.action != null ? GzActionBar(action: w.action!, summaryValue: w.summary) : null,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?w.notice,
            BookingHead(title: w.title, info: w.info),
            ...w.children,
          ],
        ),
      ),
    );
  }
}

/// The title row of a step (web `.bk-head`): the serif title at the start, an optional glyph or status at the end.
class BookingHead extends StatelessWidget {
  const BookingHead({required this.title, this.info, super.key});

  final String title;
  final Widget? info;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4, bottom: GzSpace.s2),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: GzSize.controlLg - GzSpace.s6),
        child: Row(
          children: [
            Expanded(
              child: GzText(title, role: GzTextRole.d3, color: context.gz.colors.textStrong, header: true),
            ),
            if (info != null) ...[const SizedBox(width: GzSpace.s3), info!],
          ],
        ),
      ),
    );
  }
}
