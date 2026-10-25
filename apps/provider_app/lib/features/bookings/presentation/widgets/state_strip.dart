// StateStrip (web `States.tsx`, ADR 0034 section 5): a drawing (96) beside a title of at most three words and its facts, the paragraph behind an
// info glyph, the actions under it. A quiet panel for the outcome of a closed request on Booking detail. The shared EmptyState has no slot
// between the title and the actions, so this is a flow-local twin (filed in requests.md).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

class StateStrip extends StatelessWidget {
  const StateStrip({required this.illustration, required this.title, this.quietTitle = false, this.facts, this.infoTitle, this.info, this.actions = const [], super.key});

  final GzIllustrationName illustration;

  /// At most three words.
  final String title;

  /// The title only names the drawing for assistive technology (the page already says the word, as a status pill).
  final bool quietTitle;
  final Widget? facts;
  final String? infoTitle;
  final String? info;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
      decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderHairline, width: GzStroke.hair)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ExcludeSemantics(child: GzIllustration(illustration, size: GzIllustrationSize.md)),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (quietTitle)
                      Semantics(header: true, label: title, child: const SizedBox.shrink())
                    else
                      GzText(title, role: GzTextRole.title, color: c.textStrong, header: true),
                    if (!quietTitle && facts != null) const SizedBox(height: GzSpace.s2),
                    ?facts,
                  ],
                ),
              ),
              if (info != null) Align(alignment: AlignmentDirectional.topCenter, child: GzInfoButton(title: infoTitle ?? title, paragraphs: [info!])),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: GzSpace.s4),
            for (var i = 0; i < actions.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s2), actions[i]],
          ],
        ],
      ),
    );
  }
}
