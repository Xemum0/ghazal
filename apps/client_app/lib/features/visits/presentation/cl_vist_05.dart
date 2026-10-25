import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, visitsRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show VisitCancelInput, VisitRescheduleInput, VisitThread;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/visits_view.dart';
import 'widgets/visit_widgets.dart';

/// CL-VIST-05 Change or cancel visit (sheet). Covers CA-VIS-04, CA-VIS-03.
///
/// Ask the hotel for another time, or cancel the visit with the consequence
/// stated: nothing is charged and nothing is lost, and the chat records the
/// change. Offline disables both actions in place. Closing the sheet returns
/// to the visit chat ('CL-VIST-03'); after a cancel, Done can open the list
/// ('CL-VIST-04').
/// States: default, ask-other-time, cancel-confirm, success, error, offline.
class ClVist05Screen extends ConsumerStatefulWidget {
  const ClVist05Screen({super.key});

  @override
  ConsumerState<ClVist05Screen> createState() => _ClVist05ScreenState();
}

enum _Step { main, ask, cancel, doneAsk, doneCancel }

class _ClVist05ScreenState extends ConsumerState<ClVist05Screen> {
  _Step _step = _Step.main;
  String? _reason;
  bool _busy = false;
  bool _failed = false;
  String? _date;
  DateTime? _slot;

  GzNavigator get _nav => context.gzNav;

  String get _visitId => (_nav.params['visitId'] as String?) ?? 'visit-aurelia-reem';

  Future<void> _askOther(VisitThread t) async {
    if (_slot == null || _date == null || _busy) return;
    setState(() {
      _failed = false;
      _busy = true;
    });
    try {
      await ref.read(visitsRepositoryProvider).rescheduleVisit(visitId: _visitId, body: VisitRescheduleInput(slotStart: _slot!));
      ref.read(clientDataRevisionProvider.notifier).bump();
      if (mounted) setState(() => _step = _Step.doneAsk);
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _cancel() async {
    if (_reason == null || _busy) return;
    setState(() {
      _failed = false;
      _busy = true;
    });
    try {
      await ref.read(visitsRepositoryProvider).cancelVisit(visitId: _visitId, body: VisitCancelInput(reason: _reason));
      ref.read(clientDataRevisionProvider.notifier).bump();
      if (mounted) setState(() => _step = _Step.doneCancel);
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(visitThreadProvider(_visitId));
    return GzAsyncView<VisitThread>(
      value: thread,
      loading: const GzSkeleton(blockSize: 200),
      onRetry: () => ref.invalidate(visitThreadProvider(_visitId)),
      data: (t) {
        if (_step == _Step.doneAsk || _step == _Step.doneCancel) return _done(context, t);
        if (_step == _Step.ask) return _ask(context, t);
        if (_step == _Step.cancel) return _cancelStep(context, t);
        return _main(context, t);
      },
    );
  }

  Widget _shell(BuildContext context, {required String title, List<String>? info, required List<Widget> children, List<Widget>? footer}) {
    return Column(
      key: ValueKey<String>('visits.change.$_step'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The sheet frame: title block (8 above the title, 8 below), close top-aligned, then a 16 body gap.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [GzText(title, role: GzTextRole.d1, color: context.gz.colors.textStrong, header: true)],
                ),
              ),
            ),
            if (info != null) ...[const SizedBox(width: GzSpace.s1), GzInfoButton(title: title, paragraphs: info)],
            const SizedBox(width: GzSpace.s3),
            GzBarButton(icon: GzIcons.close, label: context.gzL10n.commonActionClose, onPressed: () => _nav.closeSheet()),
          ],
        ),
        const SizedBox(height: GzSpace.s2),
        ...children,
        // The body of the web frame ends with a 16 padding, then the footer (when there is one).
        const SizedBox(height: GzSpace.s4),
        ...?footer,
      ],
    );
  }

  Widget _main(BuildContext context, VisitThread t) {
    final l = context.l10n;
    final venueName = t.target.name.of(context.gz.locale.languageCode);
    return _shell(
      context,
      title: l.clientVisitsChangeTitle,
      info: [l.clientVisitsInfoNoFee, l.clientVisitsInfoRecord(venueName)],
      children: [
        VenueLineTile(venueId: t.visit.venueId, facts: VisitFactsRow(slotStart: t.visit.slotStart, slotEnd: t.visit.slotEnd, compact: true)),
        const SizedBox(height: GzSpace.s4),
        GzIconListRow(flush: true, icon: GzIcons.calendarDots, title: l.clientVisitsRowAsk, chevron: true, onPressed: () => setState(() => _step = _Step.ask)),
        GzIconListRow(flush: true, last: true, tone: GzListRowTone.danger, icon: GzIcons.calendarX, title: l.clientVisitsRowCancel, chevron: true, onPressed: () => setState(() => _step = _Step.cancel)),
      ],
    );
  }

  Widget _ask(BuildContext context, VisitThread t) {
    final l = context.l10n;
    final lc = context.gzL10n;
    return _shell(
      context,
      title: l.clientVisitsRowAsk,
      children: [
        if (_failed) ...[
          GzBanner(message: l.clientVisitsNothingChanged, tone: GzBannerTone.danger, actionLabel: lc.commonActionRetry, onAction: () => _askOther(t)),
          const SizedBox(height: GzSpace.s3),
        ],
        Flexible(
          child: SingleChildScrollView(
            child: VisitSlotPicker(
              venueId: t.visit.venueId,
              date: _date,
              slot: _slot,
              disabled: _busy,
              onChange: (d, s) => setState(() {
                _date = d;
                _slot = s;
              }),
            ),
          ),
        ),
      ],
      footer: [
        GzButton(key: const ValueKey<String>('visits.ask.send'), label: l.clientVisitsAskAction, fullWidth: true, loading: _busy, onPressed: _slot == null || _busy ? null : () => _askOther(t)),
        const SizedBox(height: GzSpace.s2),
        GzButton(label: lc.commonActionBack, variant: GzButtonVariant.tertiary, onPressed: () => setState(() => _step = _Step.main)),
      ],
    );
  }

  Widget _cancelStep(BuildContext context, VisitThread t) {
    final l = context.l10n;
    final venueName = t.target.name.of(context.gz.locale.languageCode);
    return _shell(
      context,
      title: l.clientVisitsRowCancel,
      info: [l.clientVisitsInfoNoFee, l.clientVisitsInfoRecord(venueName)],
      children: [
        if (_failed) ...[
          GzBanner(message: l.clientVisitsNothingChanged, tone: GzBannerTone.danger, actionLabel: context.gzL10n.commonActionRetry, onAction: _cancel),
          const SizedBox(height: GzSpace.s3),
        ],
        GzChipGroup<String>(
          label: l.clientVisitsPickReason,
          value: _reason,
          onChanged: (v) => setState(() => _reason = v),
          options: [
            GzChipOption(value: 'plans', label: l.clientVisitsReasonPlans),
            GzChipOption(value: 'other-venue', label: l.clientVisitsReasonOtherVenue),
            GzChipOption(value: 'other', label: l.clientVisitsReasonOther),
          ],
        ),
      ],
      footer: [
        GzButton(
          key: const ValueKey<String>('visits.cancel.confirm'),
          label: l.clientVisitsRowCancel,
          variant: GzButtonVariant.destructive,
          fullWidth: true,
          iconStart: GzIcons.calendarX,
          loading: _busy,
          onPressed: _reason == null || _busy ? null : _cancel,
        ),
        const SizedBox(height: GzSpace.s2),
        GzButton(label: l.clientVisitsKeepVisit, variant: GzButtonVariant.tertiary, onPressed: () => setState(() => _step = _Step.main)),
      ],
    );
  }

  Widget _done(BuildContext context, VisitThread t) {
    final l = context.l10n;
    final cancelled = _step == _Step.doneCancel;
    return _shell(
      context,
      title: l.clientVisitsChangeTitle,
      children: [
        GzEmptyState(
          key: const ValueKey<String>('visits.change.done'),
          fill: false,
          illustration: cancelled ? GzIllustrationName.calendar : GzIllustrationName.successRequest,
          title: cancelled ? l.clientVisitsDoneCancelTitle : l.clientVisitsDoneAskTitle,
          action: GzStateAction(label: context.gzL10n.commonActionDone, variant: GzButtonVariant.primary, onPressed: () => _nav.closeSheet()),
          secondary: cancelled ? GzStateAction(label: l.clientVisitsListTitle, onPressed: () {
            _nav.closeSheet();
            _nav.push('CL-VIST-04');
          }) : null,
        ),
      ],
    );
  }
}
