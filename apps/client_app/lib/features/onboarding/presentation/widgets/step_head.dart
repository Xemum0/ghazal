import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The heading block of a profile step: the title is the client hero headline (display d2), a noun phrase of at most three words, no lead
/// line. A step may carry one drawing at inline-end (the head becomes a row, the drawing centred against the title).
class ObdStepHead extends StatelessWidget {
  const ObdStepHead({required this.title, this.art, super.key});

  final String title;
  final GzIllustrationName? art;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final text = GzText(title, role: GzTextRole.d2, color: c.textStrong, header: true);
    if (art == null) return text;
    return Row(
      children: [
        Expanded(child: text),
        const SizedBox(width: GzSpace.s4),
        GzIllustration(art!, size: GzIllustrationSize.lg),
      ],
    );
  }
}
