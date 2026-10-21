// Layout kit of the nav gallery: the Flutter twin of the web `Device` frame (design/src/shell/device) and the specimen furniture of
// design/src/system/nav/demo/NavGallery.tsx. Imports only the groups' own barrels (never ghazal_ui.dart). Literals are allowed here.
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/nav/nav.dart';
import 'package:ghazal_ui/src/overlays/overlays.dart';

/// Tone of the system chrome of a specimen: ink glyphs on a light surface, canvas glyphs over imagery.
enum NavChrome { dark, light, none }

/// The 360 / 390 / 430 frame widths of the device framework; 390 is the default.
const double navFrameWidth = 390;

/// One specimen: the frame in a hairline box (flat, radius 4, clipped) and its caption 12 below (`.ng-specimen`).
Widget navSpecimen(BuildContext context, String label, Widget frame) {
  final c = context.gz.colors;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: c.borderHairline, width: GzStroke.hair), borderRadius: GzRadius.xsAll),
        child: Padding(padding: const EdgeInsets.all(GzStroke.hair), child: ClipRRect(borderRadius: GzRadius.xsAll, child: frame)),
      ),
      const SizedBox(height: GzSpace.s3),
      SizedBox(width: navFrameWidth, child: GzText(label, role: GzTextRole.caption, color: c.textSecondary)),
    ],
  );
}

/// `.ng-section__head`: the 24 x 1 gold khayt over the section title (d2), 12 apart.
Widget navHeader(BuildContext context, String title) {
  final c = context.gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: GzSize.khaytWidth, height: GzStroke.khayt, child: ColoredBox(color: c.markKhayt)),
      const SizedBox(height: GzSpace.s3),
      // Measured on the reference crops: the English heading wraps at the 310 column, the Arabic one is laid out in the 392 frame box.
      SizedBox(width: context.gz.isAr ? navFrameWidth + 2 : 310, child: GzText(title, role: GzTextRole.d2, color: c.textStrong, header: true)),
    ],
  );
}

/// Physical left, whatever the language (the reference page lays the frames out from the left in Arabic too).
Widget _left(Widget child) => Align(alignment: const Alignment(-1, -1), child: child);

/// A section: specimens stacked with a 32 gap, laid out at their own width from inline-start and clipped to the section column (the
/// web page crops the 390 frames at its 310 column the same way).
Widget navSection(BuildContext context, String title, List<Widget> specimens) => ClipRect(
      child: UnconstrainedBox(
        alignment: const Alignment(-1, -1), // physical left: the web page lays the 390 frames from the left in both languages
        constrainedAxis: null,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: 432, // the widest specimen (the 430 frame and its hairline)
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _left(navHeader(context, title)),
              const SizedBox(height: GzSpace.s6),
              for (var i = 0; i < specimens.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s8), _left(specimens[i])],
            ],
          ),
        ),
      ),
    );

/// The prototype `Device`: a [width] x [height] screen, canvas, the status bar (47) and the home indicator (34) unless [chrome] is
/// none, safe areas published through `MediaQuery`. [children] fill a column (use `Expanded` for the web's `flex: 1` fillers);
/// [overlays] are absolute layers over the content (sheet, dialog, photo backdrop).
class NavDevice extends StatelessWidget {
  const NavDevice({
    required this.height,
    this.width = navFrameWidth,
    this.app = GzAppKind.client,
    this.chrome = NavChrome.dark,
    this.children = const [],
    this.underlays = const [],
    this.overlays = const [],
    this.bezel = false,
    super.key,
  });

  final double width;
  final double height;
  final GzAppKind app;
  final NavChrome chrome;
  final List<Widget> children;

  /// Absolute layers behind the column (a photograph).
  final List<Widget> underlays;
  final List<Widget> overlays;
  final bool bezel;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final mq = MediaQuery.of(context);
    final status = chrome != NavChrome.none;
    final screen = SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: bezel ? const BorderRadius.all(Radius.circular(48)) : BorderRadius.zero,
        child: MediaQuery(
          data: mq.copyWith(size: Size(width, height), padding: EdgeInsets.only(top: status ? GzLayout.safeTop : 0, bottom: status ? GzLayout.safeBottom : 0), viewInsets: EdgeInsets.zero),
          child: GzAppScope(
            app: app,
            child: ColoredBox(
              color: c.surfaceCanvas,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ...underlays,
                  Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                  ...overlays,
                  if (status) PositionedDirectional(start: 0, end: 0, top: 0, child: _StatusBar(light: chrome == NavChrome.light)),
                  if (status) PositionedDirectional(start: 0, end: 0, bottom: 0, child: _HomeIndicator(light: chrome == NavChrome.light)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!bezel) return screen;
    // Thin bezel (the player): 8 dp ink ring, hardware corner 56 outside, the notch.
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surfaceDark, borderRadius: const BorderRadius.all(Radius.circular(56)), boxShadow: GzElevation.e2),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            screen,
            DecoratedBox(
              decoration: BoxDecoration(color: c.surfaceDark, borderRadius: const BorderRadiusDirectional.vertical(bottom: Radius.circular(GzRadius.lg))),
              child: const SizedBox(width: 160, height: 28),
            ),
          ],
        ),
      ),
    );
  }
}

/// A photograph behind a transparent bar (`PhotoBackdrop`). The web image is not stretched to the frame: it keeps its natural 3:2 at
/// the frame width from the top edge, and the canvas shows below it.
class NavPhoto extends StatelessWidget {
  const NavPhoto({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) => ClipRect(
        child: OverflowBox(alignment: Alignment.topCenter, minHeight: 0, maxHeight: double.infinity, child: GzPhoto(src: 'asset://ghazal_mock_api/images/$id', aspectRatio: 3 / 2)),
      );
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.light});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? GzColors.light.iconOnDark : GzColors.light.iconPrimary;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: IgnorePointer(
        child: SizedBox(
          height: GzLayout.safeTop,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: 4),
            child: Row(
              children: [
                Expanded(child: Center(child: Text('4:00', style: GzType.en.statusbar.copyWith(color: color, decoration: TextDecoration.none)))),
                const SizedBox(width: 160),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomPaint(size: const Size(18, 12), painter: _Signal(color)),
                      const SizedBox(width: 4),
                      CustomPaint(size: const Size(17, 12), painter: _Wifi(color)),
                      const SizedBox(width: 4),
                      CustomPaint(size: const Size(27, 13), painter: _Battery(color)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator({required this.light});

  final bool light;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: SizedBox(
          height: GzLayout.safeBottom,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(color: light ? GzColors.light.iconOnDark : GzColors.light.iconPrimary, borderRadius: GzRadius.pillAll),
                child: const SizedBox(width: GzSize.homeIndicatorWidth, height: GzSize.homeIndicatorHeight),
              ),
            ),
          ),
        ),
      );
}

class _Signal extends CustomPainter {
  const _Signal(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    const bars = [(0.0, 8.0, 4.0), (5.0, 5.5, 6.5), (10.0, 3.0, 9.0), (15.0, 0.0, 12.0)];
    for (final b in bars) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(b.$1, b.$2, 3, b.$3), const Radius.circular(1)), p);
    }
  }

  @override
  bool shouldRepaint(_Signal old) => old.color != color;
}

class _Wifi extends CustomPainter {
  const _Wifi(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawPath(Path()..moveTo(1.71, 4.21)..arcToPoint(const Offset(15.29, 4.21), radius: const Radius.circular(9.6)), stroke)
      ..drawPath(Path()..moveTo(3.97, 6.47)..arcToPoint(const Offset(13.03, 6.47), radius: const Radius.circular(6.4)), stroke)
      ..drawPath(Path()..moveTo(8.5, 11)..lineTo(6.24, 8.74)..arcToPoint(const Offset(10.76, 8.74), radius: const Radius.circular(3.2))..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Wifi old) => old.color != color;
}

class _Battery extends CustomPainter {
  const _Battery(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(0.5, 0.5, 22, 12), const Radius.circular(3.5)),
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      )
      ..drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(2, 2, 19, 9), const Radius.circular(2)), Paint()..color = color);
    final cap = Path()
      ..moveTo(24, 4.5)
      ..lineTo(24, 8.5)
      ..arcToPoint(const Offset(25.5, 6.4), radius: const Radius.circular(2.2), clockwise: false)
      ..arcToPoint(const Offset(24, 4.5), radius: const Radius.circular(2.2), clockwise: false)
      ..close();
    canvas.drawPath(cap, Paint()..color = color.withValues(alpha: 0.5));
  }

  @override
  bool shouldRepaint(_Battery old) => old.color != color;
}
