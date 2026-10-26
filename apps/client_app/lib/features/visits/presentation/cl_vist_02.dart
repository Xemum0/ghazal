import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_domain/ghazal_domain.dart' show VisitThread;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/visits_view.dart';
import 'widgets/visit_widgets.dart';

/// CL-VIST-02 Visit requested. Covers CA-VIS-02, CA-VIS-03, CA-NOTI-02.
///
/// Confirmation of the visit request that redirects into the group chat.
/// "Open chat" is the one gold action; two seconds after the request the chat
/// opens by itself unless the person taps Stay (never under reduced motion).
/// States: default, auto-redirecting, offline.
class ClVist02Screen extends ConsumerStatefulWidget {
  const ClVist02Screen({super.key});

  @override
  ConsumerState<ClVist02Screen> createState() => _ClVist02ScreenState();
}

class _ClVist02ScreenState extends ConsumerState<ClVist02Screen> {
  bool _stay = false;
  bool _armed = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _stay = true;
    super.dispose();
  }

  void _arm(void Function() openChat) {
    // The chat opens by itself after two seconds unless the person taps Stay (never under reduced motion).
    // `stay: true` (a frame or a deep link) keeps the confirmation open, like Stay.
    if (_armed || _stay || GzReducedMotion.of(context) || context.gzNav.params['stay'] == true) return;
    _armed = true;
    _timer = Timer(const Duration(seconds: 2), () {
      _timer = null;
      if (mounted && !_stay) openChat();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = context.gzNav;
    final visitId = (nav.params['visitId'] as String?) ?? 'visit-aurelia-reem';
    final thread = ref.watch(visitThreadProvider(visitId));
    return GzAsyncView<VisitThread>(
      value: thread,
      loading: const _RequestedSkeleton(),
      onRetry: () => ref.invalidate(visitThreadProvider(visitId)),
      data: (t) {
        void openChat() => nav.replace('CL-VIST-03', params: <String, Object?>{'visitId': t.visit.id});
        _arm(openChat);
        return GzScreen(
          top: const GzTopBar(back: GzTopBarBack.hide),
          bottom: GzActionBar(
            action: GzActionBarAction(label: l.clientVisitsOpenChat, iconEnd: GzIcons.chat, onPressed: openChat),
            secondary: GzActionBarAction(label: l.clientVisitsBackToVenue, onPressed: () => nav.push('CL-VENU-01', params: <String, Object?>{'venueId': t.visit.venueId})),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const GzIllustration(GzIllustrationName.successVisit, size: GzIllustrationSize.lg),
                    const SizedBox(width: GzSpace.s4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GzText(l.clientVisitsRequestedTitle, role: GzTextRole.d3, color: context.gz.colors.textStrong, header: true),
                          const SizedBox(height: GzSpace.s3),
                          MemberDiscs(members: t.thread.members ?? const []),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GzSpace.s6),
                Container(
                  key: const ValueKey<String>('visits.summary'),
                  padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
                  decoration: BoxDecoration(color: context.gz.colors.surfaceRaised, borderRadius: GzRadius.mdAll, border: Border.all(color: context.gz.colors.borderStrong, width: GzStroke.hair)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      VenueLineTile(venueId: t.visit.venueId),
                      const SizedBox(height: GzSpace.s4),
                      Container(
                        padding: const EdgeInsetsDirectional.only(top: GzSpace.s4),
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.gz.colors.borderHairline, width: GzStroke.hair))),
                        child: VisitFactsRow(slotStart: t.visit.slotStart, slotEnd: t.visit.slotEnd, visitors: t.visit.visitors, compact: true),
                      ),
                      if (t.visit.note != null && t.visit.note!.isNotEmpty) ...[
                        const SizedBox(height: GzSpace.s4),
                        // The web note is `dir=auto`: the glyph and the words follow the note's own script (an Arabic note in the English UI is a right-to-left row).
                        Directionality(
                          textDirection: gzFirstStrong(t.visit.note!) ?? Directionality.of(context),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GzIcon(GzIcons.chatText, size: GzIconSize.xs, color: context.gz.colors.iconSecondary),
                              const SizedBox(width: GzSpace.s2),
                              Expanded(child: GzUserText(t.visit.note!, role: GzTextRole.bodyS, color: context.gz.colors.textPrimary, maxLines: 2)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: GzSpace.s6),
                GzIconProgress(
                  label: l.clientVisitsStepsLabel,
                  steps: [
                    GzIconProgressStep(id: 'request', icon: GzIcons.send, label: l.clientVisitsStepRequest, state: GzKnotState.tied),
                    GzIconProgressStep(id: 'confirm', icon: GzIcons.calendarCheck, label: l.clientVisitsStepConfirm, state: GzKnotState.now),
                    GzIconProgressStep(id: 'way', icon: GzIcons.navigate, label: l.clientVisitsStepWay, state: GzKnotState.open),
                    GzIconProgressStep(id: 'arrival', icon: GzIcons.pin, label: l.clientVisitsStepArrival, state: GzKnotState.open),
                  ],
                ),
                if (!_stay && nav.params['stay'] != true) ...[
                  const SizedBox(height: GzSpace.s6),
                  Row(
                    children: [
                      Expanded(child: GzText(l.clientVisitsRedirecting, role: GzTextRole.bodyS, color: context.gz.colors.textSecondary, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      GzButton(key: const ValueKey<String>('visits.stay'), label: l.clientVisitsStay, variant: GzButtonVariant.tertiary, onPressed: () => setState(() => _stay = true)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RequestedSkeleton extends StatelessWidget {
  const _RequestedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          GzSkeleton(blockSize: 96),
          SizedBox(height: GzSpace.s4),
          GzSkeleton(blockSize: 140),
        ],
      ),
    );
  }
}
