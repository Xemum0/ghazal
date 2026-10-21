import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The pinned action bar of CL-ONBD-01: [GzActionBar] with a widget (not a string) under the button, the quiet sign-in link
/// (the kit's `note` takes only text, requests.md). Same anatomy: canvas, 1 dp top rule, 12 + 52 + 8 + note + 12 + safe inset.
class ObdActionBar extends StatelessWidget {
  const ObdActionBar({required this.label, required this.onPressed, required this.note, super.key});

  final String label;
  final VoidCallback onPressed;
  final Widget note;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return ColoredBox(
      color: c.surfaceCanvas,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: MediaQuery.paddingOf(context).bottom),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GzButton(label: label, onPressed: onPressed, fullWidth: true),
                  const SizedBox(height: GzSpace.s2),
                  Center(child: note),
                ],
              ),
            ),
          ),
          PositionedDirectional(start: 0, end: 0, top: 0, height: GzStroke.hair, child: ColoredBox(color: c.borderHairline)),
        ],
      ),
    );
  }
}
