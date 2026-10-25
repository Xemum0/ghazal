// HL-VIST-04 Mark arrival, sheet (web `HL-VIST-04.tsx`): on the day, the representative's half of the arrival confirmation that the client starts in
// the chat. "Mark arrived" sets Arrived and the chat welcomes the client; "No-show" is available from 30 minutes after the slot, flags Missed and
// informs Ghazal support. A visit has no money and a missed visit carries no penalty. Decisions are never queued. Requirements: HA-VIS-04, CA-VIS-05.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, gzProblemMessage, partnerVisitsRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show VisitThread;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/visits_data.dart';
import 'widgets/visits_bits.dart';

enum _Phase { idle, saving, arrived, missed }

class HlVist04Screen extends ConsumerStatefulWidget {
  const HlVist04Screen({super.key});

  @override
  ConsumerState<HlVist04Screen> createState() => _HlVist04ScreenState();
}

class _HlVist04ScreenState extends ConsumerState<HlVist04Screen> {
  _Phase _phase = _Phase.idle;
  String? _error;

  Future<void> _mark(String id, {required bool missed}) async {
    final gzL = context.gzL10n;
    setState(() {
      _phase = _Phase.saving;
      _error = null;
    });
    final repo = ref.read(partnerVisitsRepositoryProvider);
    final p = await visitWrite(() => missed ? repo.markVisitMissed(visitId: id) : repo.markVisitArrived(visitId: id));
    if (!mounted) return;
    ref.read(partnerDataRevisionProvider.notifier).bump();
    setState(() {
      if (p != null) {
        _phase = _Phase.idle;
        _error = gzProblemMessage(gzL, p);
      } else {
        _phase = missed ? _Phase.missed : _Phase.arrived;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nav = GzNavigatorScope.of(context);
    final id = (nav.params['visitId'] as String?) ?? kHeroConfirmedVisit;
    final value = ref.watch(partnerVisitThreadProvider(id));
    return GzAsyncView<VisitThread>(
      value: value,
      loading: const Padding(
        padding: EdgeInsets.only(bottom: GzSpace.s6),
        child: GzSkeleton(blockSize: 160),
      ),
      onRetry: () => ref.invalidate(partnerVisitThreadProvider(id)),
      data: (t) => _content(context, t),
    );
  }

  Widget _content(BuildContext context, VisitThread t) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final nav = GzNavigatorScope.of(context);
    final lang = context.gz.locale.languageCode;
    final v = t.visit;
    final now = ref.watch(clockProvider)();
    final name = firstName(v.clientName);
    final missedOpen = canFlagMissed(v, now);
    final missedFrom = v.slotStart.add(const Duration(minutes: 30));
    final busy = _phase == _Phase.saving;

    if (_phase == _Phase.arrived || _phase == _Phase.missed) {
      final arrived = _phase == _Phase.arrived;
      return VisitSheetShell(
        title: l.hotelVisitsArrivalTitle,
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GzButton(
              label: l.hotelVisitsOpenChat,
              size: GzButtonSize.cta,
              fullWidth: true,
              spill: true,
              iconStart: GzIcons.chat,
              onPressed: () {
                nav.closeSheet();
                nav.push('HL-VIST-03', params: <String, Object?>{'visitId': v.id});
              },
            ),
            const SizedBox(height: GzSpace.s3),
            GzButton(
              label: context.gzL10n.commonActionDone,
              variant: GzButtonVariant.tertiary,
              fullWidth: true,
              spill: true,
              onPressed: nav.closeSheet,
            ),
          ],
        ),
        children: [
          Semantics(
            liveRegion: true,
            child: Column(
              children: [
                const SizedBox(height: GzSpace.s4),
                Container(
                  width: GzSize.avatarMd,
                  height: GzSize.avatarMd,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: arrived ? c.statusSuccessBg : c.surfaceQuiet),
                  child: GzIcon(arrived ? GzIcons.check : GzIcons.clockOff, size: GzIconSize.md, color: arrived ? c.textSuccess : c.iconSecondary),
                ),
                const SizedBox(height: GzSpace.s4),
                GzText(
                  arrived ? l.hotelVisitsArrivedDoneTitle(name) : l.hotelVisitsMissedDoneTitle(name),
                  role: GzTextRole.uiTitle,
                  color: c.textStrong,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return VisitSheetShell(
      title: l.hotelVisitsArrivalTitle,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzButton(
            label: l.hotelVisitsMarkArrived,
            size: GzButtonSize.cta,
            fullWidth: true,
            spill: true,
            iconStart: GzIcons.pin,
            loading: busy,
            onPressed: busy ? null : () => _mark(v.id, missed: false),
          ),
          const SizedBox(height: GzSpace.s3),
          GzButton(
            label: l.hotelVisitsDidNotArrive,
            variant: GzButtonVariant.secondary,
            size: GzButtonSize.md,
            fullWidth: true,
            spill: true,
            iconStart: GzIcons.userMinus,
            reason: !missedOpen ? l.hotelVisitsMissedFrom(f.time(missedFrom)) : null,
            onPressed: (!missedOpen || busy)
                ? null
                : () async {
                    final r = await nav.openDialog(
                      GzDialogSpec(
                        title: l.hotelVisitsMissedDialogTitle,
                        body: l.hotelVisitsMissedDialogBody,
                        icon: GzIcons.warningCircle,
                        confirmLabel: l.hotelVisitsMissedCta,
                        cancelLabel: context.gzL10n.commonActionBack,
                        tone: GzDialogTone.destructive,
                      ),
                    );
                    if (r == GzDialogResult.confirm) await _mark(v.id, missed: true);
                  },
          ),
        ],
      ),
      children: [
        Row(
          children: [
            GzAvatar(name: name, initial: lang == 'ar' ? name.substring(0, 1) : null, size: GzAvatarSize.md, voice: GzAvatarVoice.sans),
            const SizedBox(width: GzSpace.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GzUserText(name, role: GzTextRole.uiTitle, color: c.textStrong, maxLines: 1),
                  GzText(f.dateTime(v.slotStart, DateStyle.short), role: GzTextRole.figBodyS, color: c.textSecondary, figures: true),
                ],
              ),
            ),
          ],
        ),
        if (_error != null)
          GzBanner(
            message: _error!,
            tone: GzBannerTone.danger,
            actionLabel: context.gzL10n.commonActionRetry,
            onAction: () => setState(() => _error = null),
          ),
      ],
    );
  }
}
