// Layout kit of the client-d gallery sections: the Flutter twin of the web gallery kit (design/src/system/domain-client/gallery/kit.tsx
// and gallery.css): a section head (khayt, serif title, note), specimens with a caption over a hairline, side-by-side cells.
// Literals are allowed here (ghazal_testing is exempt from the no-text-literal rule).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/src/foundation.dart';

/// English or Arabic by the language the page renders in.
String cdL(BuildContext context, String en, String ar) => context.gz.isAr ? ar : en;

/// `.gc-sec`: the khayt over the title (d2) and the note (body-s, secondary), then the specimens 32 apart.
Widget cdSection(BuildContext context, {required String title, required String note, required List<Widget> specimens}) {
  final c = context.gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Align(alignment: AlignmentDirectional.centerStart, child: SizedBox(width: GzSize.khaytWidth, height: GzStroke.khayt, child: ColoredBox(color: c.markKhayt))),
      const SizedBox(height: GzSpace.s2),
      GzText(title, role: GzTextRole.d2, color: c.textStrong, header: true),
      const SizedBox(height: GzSpace.s2),
      GzText(note, role: GzTextRole.bodyS, color: c.textSecondary),
      const SizedBox(height: GzSpace.s5),
      for (var i = 0; i < specimens.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s8), specimens[i]],
    ],
  );
}

/// `.gc-spec`: a state caption over a hairline, then the live components 24 apart (`ink` is the dark panel of the web `tone="ink"`).
Widget cdSpec(BuildContext context, String state, List<Widget> children, {bool ink = false}) {
  final gz = context.gz;
  final c = gz.colors;
  Widget stack = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s6), children[i]]],
  );
  if (ink) {
    stack = Container(padding: const EdgeInsets.all(GzSpace.s4), decoration: BoxDecoration(color: c.surfaceDark, borderRadius: GzRadius.mdAll), child: stack);
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.only(top: GzSpace.s2),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
        child: Text(state, style: gz.text(GzTextRole.caption).copyWith(color: c.textSecondary, fontWeight: gz.text(GzTextRole.title).fontWeight, decoration: TextDecoration.none)),
      ),
      const SizedBox(height: GzSpace.s3),
      stack,
    ],
  );
}

/// `.gc-cell`: a caption over one specimen (12 apart).
Widget cdCell(BuildContext context, String caption, Widget child) {
  final c = context.gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [GzText(caption, role: GzTextRole.caption, color: c.textSecondary), const SizedBox(height: GzSpace.s3), child],
  );
}
