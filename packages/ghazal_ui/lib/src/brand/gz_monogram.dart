import 'package:flutter/widgets.dart';

import '../foundation.dart';

const String _kLetterLatin = 'G';
const String _kLetterArabic = '\u063a';

enum GzMonogramSize { sm, md, lg }

enum GzMonogramScript { latin, arabic }

enum GzMonogramForm { bare, tile }

/// Monogram: the brand initial on the thread (direction section 7, "app-icon study"): one letter, G or غ, in the display serif in
/// ink-900, with the gold-500 thread running along its baseline and ending in a knot. A fixed LTR mark (brand marks never mirror).
/// `tile` sets it on a rose-100 square (the app-icon and splash form); `bare` is the mark alone. Sizes 40 / 56 / 80.
class GzMonogram extends StatelessWidget {
  const GzMonogram({this.size = GzMonogramSize.md, this.script, this.form = GzMonogramForm.bare, super.key});

  final GzMonogramSize size;

  /// The letter. Default follows the language: G in English, غ in Arabic.
  final GzMonogramScript? script;
  final GzMonogramForm form;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final arabic = (script ?? (gz.isAr ? GzMonogramScript.arabic : GzMonogramScript.latin)) == GzMonogramScript.arabic;
    final (double box, double base, double thick, double knot, GzTextRole role) = switch (size) {
      GzMonogramSize.sm => (GzSize.avatarSm, 13.0, GzStroke.icon, GzSpace.s1, GzTextRole.d2),
      GzMonogramSize.md => (GzSize.avatarMd, 19.0, GzStroke.icon, GzSpace.s1, GzTextRole.d3),
      GzMonogramSize.lg => (GzSpace.s20, 30.0, GzStroke.thread, GzSize.knotBead, GzTextRole.d4),
    };
    final style = GzType.style(Locale(arabic ? 'ar' : 'en'), role).copyWith(color: c.textStrong, decoration: TextDecoration.none);
    final thread = PositionedDirectional(
      start: 0,
      end: 0,
      bottom: base,
      height: thick,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: ColoredBox(color: c.markKhayt)),
          PositionedDirectional(
            end: 0,
            top: (thick - knot) / 2,
            child: Transform.rotate(angle: 0.7853981633974483, child: SizedBox.square(dimension: knot, child: ColoredBox(color: c.markKhayt))),
          ),
        ],
      ),
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Semantics(
        label: 'Ghazal',
        image: true,
        excludeSemantics: true,
        child: Container(
          width: box,
          height: box,
          decoration: form == GzMonogramForm.tile ? BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.mdAll) : null,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              thread,
              Text(arabic ? _kLetterArabic : _kLetterLatin, style: style, softWrap: false),
            ],
          ),
        ),
      ),
    );
  }
}
