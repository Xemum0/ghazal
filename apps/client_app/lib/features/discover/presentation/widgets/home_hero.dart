import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

/// The Maison hero of Home (direction 5 "Arch": the one place besides onboarding): the photograph with the arch crown, the wordmark and
/// the bell on one row on canvas, the khayt and the headline at the stage foot. The Brief card covers the last 24 of the photograph.
const double kHeroStage = 280;
const double kHeroOverlap = GzSpace.s6;
const double kHeroRow = GzSize.controlSm;
const double _apexIntoRow = GzSpace.s1;

/// The stage: Arabic display lines are taller (d4 is 44/60), so the Arabic stage is 16 taller and the headline never meets the crown.
double heroStage(bool arabic) => arabic ? kHeroStage + GzSpace.s4 : kHeroStage;

const String kHeroPhoto = 'asset://ghazal_mock_api/images/ballrooms-17-floral-arch-stage-draped-ceiling';

class HomeHero extends StatelessWidget {
  const HomeHero({required this.unread, required this.onBell, super.key});

  final int unread;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.l10n;
    final safeTop = MediaQuery.paddingOf(context).top;
    final arabic = gz.locale.languageCode == 'ar';
    final stage = heroStage(arabic);
    final apex = safeTop + kHeroRow - _apexIntoRow;
    return SizedBox(
      height: stage,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            top: apex,
            start: 0,
            end: 0,
            height: stage - apex + kHeroOverlap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const GzPhoto(src: kHeroPhoto, alignment: Alignment(0, -0.16), priority: true),
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  end: 0,
                  height: stage - apex,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [c.scrimClear, c.scrimClear, c.scrimMid, c.scrimLow, c.scrimBottom],
                        stops: const [0, 0.14, 0.30, 0.54, 1],
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(bottom: 0, start: 0, end: 0, height: kHeroOverlap, child: ColoredBox(color: c.scrimBottom)),
              ],
            ),
          ),
          PositionedDirectional(
            top: apex,
            start: 0,
            end: 0,
            height: GzShape.archRise,
            child: ExcludeSemantics(child: CustomPaint(painter: _CrownPainter(shoulder: c.surfaceCanvas, edge: c.markKhayt))),
          ),
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: Padding(
              padding: EdgeInsets.only(top: safeTop),
              child: HomeBarRow(unread: unread, onBell: onBell),
            ),
          ),
          PositionedDirectional(
            bottom: GzSpace.s6,
            start: GzSpace.gutter,
            end: GzSpace.gutter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const GzThreadRule(draw: GzDraw.mount),
                const SizedBox(height: GzSpace.s2),
                GzText(l.clientDiscoverHeroHeadline, role: GzTextRole.d4, color: c.textOnDark, header: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wordmark at inline-start, bell at inline-end: one 44 row; the bell's glyph sits on the gutter (its target overhangs by 10).
class HomeBarRow extends StatelessWidget {
  const HomeBarRow({required this.unread, required this.onBell, this.keyId = 'discover.bell', super.key});

  final int unread;
  final VoidCallback onBell;
  final String keyId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SizedBox(
      height: kHeroRow,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.s2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const GzWordmark(),
            Stack(
              children: [
                GzIconButton(key: ValueKey<String>(keyId), icon: GzIcons.bell, label: l.clientDiscoverBellUnread(unread), onPressed: onBell),
                if (unread > 0) const PositionedDirectional(top: GzSpace.s2, end: GzSpace.s2, child: IgnorePointer(child: GzThreadBead())),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The mini bar that takes over once the hero has scrolled away, so the bell is never out of reach.
class HomeBar extends StatelessWidget {
  const HomeBar({required this.unread, required this.onBell, super.key});

  final int unread;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final arabic = context.gz.locale.languageCode == 'ar';
    final on = GzScreenScroll.of(context) > heroStage(arabic) - GzSize.controlLg;
    return IgnorePointer(
      ignoring: !on,
      child: ExcludeSemantics(
        excluding: !on,
        child: AnimatedOpacity(
          opacity: on ? 1 : 0,
          duration: GzReducedMotion.fade(context, GzMotion.durationBase),
          curve: GzMotion.easeStandard,
          child: Container(
            decoration: BoxDecoration(
              color: c.surfaceCanvas,
              border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair)),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
              child: HomeBarRow(unread: unread, onBell: onBell, keyId: 'discover.bell.bar'),
            ),
          ),
        ),
      ),
    );
  }
}

/// The two shoulders of the arch (canvas) and its one hairline gold edge, from the arch path of the shape tokens.
class _CrownPainter extends CustomPainter {
  const _CrownPainter({required this.shoulder, required this.edge});

  final Color shoulder;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100;
    final sy = size.height / 100;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    final outside = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..cubicTo(p(100, 46).dx, p(100, 46).dy, p(72, 36).dx, p(72, 36).dy, p(50, 0).dx, p(50, 0).dy)
      ..cubicTo(p(28, 36).dx, p(28, 36).dy, p(0, 46).dx, p(0, 46).dy, 0, size.height)
      ..close();
    canvas.drawPath(outside, Paint()..color = shoulder);
    final line = Path()
      ..moveTo(0, size.height)
      ..cubicTo(p(0, 46).dx, p(0, 46).dy, p(28, 36).dx, p(28, 36).dy, p(50, 0).dx, p(50, 0).dy)
      ..cubicTo(p(72, 36).dx, p(72, 36).dy, p(100, 46).dx, p(100, 46).dy, size.width, size.height);
    canvas.drawPath(
      line,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = GzStroke.hair,
    );
  }

  @override
  bool shouldRepaint(_CrownPainter old) => old.shoulder != shoulder || old.edge != edge;
}
