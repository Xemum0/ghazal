// CL-ONBD-02 Introduction: three swipeable slides, one promise each (CA-ONB-01). Port of CL-ONBD-02.tsx.
// Each slide is a drawing and at most five words. The first slide sits at inline-start (the right in Arabic) and swipes advance toward the
// left there; the 2 dp thread fills in reading direction. Skip goes straight to Home with an empty Brief; the last slide's Get started goes
// to the planning questions.
import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'widgets/thread_progress.dart';

const int _count = 3;

class ClOnbd02Screen extends ConsumerStatefulWidget {
  const ClOnbd02Screen({super.key});

  @override
  ConsumerState<ClOnbd02Screen> createState() => _ClOnbd02State();
}

class _ClOnbd02State extends ConsumerState<ClOnbd02Screen> {
  int _index = 0;

  void _skip() {
    ref.read(searchBriefProvider.notifier).clear();
    context.gzNav.reset('CL-DISC-01');
  }

  void _next() => _index == _count - 1 ? context.gzNav.push('CL-ONBD-03') : setState(() => _index = _index + 1);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.gz.colors;
    final slides = <(GzIllustrationName, String)>[
      (GzIllustrationName.onboardCompare, l10n.clientOnboardingIntroSlide1Title),
      (GzIllustrationName.onboardDates, l10n.clientOnboardingIntroSlide2Title),
      (GzIllustrationName.onboardVoucher, l10n.clientOnboardingIntroSlide3Title),
    ];
    final last = _index == _count - 1;
    return GzScreen(
      fixed: true,
      bottom: GzActionBar(
        action: GzActionBarAction(label: last ? l10n.clientOnboardingIntroStart : l10n.commonActionNext, onPressed: _next),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(top: MediaQuery.paddingOf(context).top, start: GzSpace.gutter, end: GzSpace.s3),
            child: SizedBox(
              height: GzSize.controlLg,
              child: Row(
                children: [
                  const GzWordmark(size: GzWordmarkSize.sm),
                  const Spacer(),
                  GzButton(label: l10n.commonActionSkip, variant: GzButtonVariant.tertiary, onPressed: _skip),
                ],
              ),
            ),
          ),
          Expanded(
            child: GzPager(
              label: l10n.clientOnboardingIntroLabel,
              index: _index,
              onIndexChanged: (i) => setState(() => _index = i),
              children: [
                for (final s in slides)
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GzIllustration(s.$1, size: GzIllustrationSize.hero),
                        const SizedBox(height: GzSpace.s8),
                        GzText(s.$2, role: GzTextRole.d3, color: c.textStrong, textAlign: TextAlign.center, header: true),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s6),
            child: ObdThreadProgress(count: _count, index: _index, label: l10n.commonCounter(_index + 1, _count)),
          ),
        ],
      ),
    );
  }
}
