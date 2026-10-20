import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// Tone of the system chrome: `dark` ink on light screens, `light` on photos (prototype `ChromeTone`).
enum GzChromeTone { dark, light }

Color _ink(GzChromeTone tone) => tone == GzChromeTone.dark ? GzPlaceholderColors.ink900 : GzPlaceholderColors.onDark;

/// The iOS status bar of the prototype device (`design/src/shell/device/StatusBar.tsx`): [height] 47, time in the left ear,
/// signal / wifi / battery in the right ear, a 160 wide notch gap between. Always LTR (the OS draws it from the system locale).
class GzHarnessStatusBar extends StatelessWidget {
  const GzHarnessStatusBar({required this.time, this.tone = GzChromeTone.dark, this.height = 47, super.key});

  final String time;
  final GzChromeTone tone;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = _ink(tone);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: IgnorePointer(
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      time,
                      style: TextStyle(
                        fontFamily: GzFonts.uiLatin,
                        fontFamilyFallback: const [GzFonts.uiArabic],
                        package: GzFonts.package,
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                        color: color,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 160),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomPaint(size: const Size(18, 12), painter: _SignalPainter(color)),
                      const SizedBox(width: 4),
                      CustomPaint(size: const Size(17, 12), painter: _WifiPainter(color)),
                      const SizedBox(width: 4),
                      CustomPaint(size: const Size(27, 13), painter: _BatteryPainter(color)),
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

/// The home indicator of the prototype device: 134x5 pill, 8 above the bottom edge, in a [height] 34 zone.
class GzHarnessHomeIndicator extends StatelessWidget {
  const GzHarnessHomeIndicator({this.tone = GzChromeTone.dark, this.height = 34, super.key});

  final GzChromeTone tone;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: height,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(color: _ink(tone), borderRadius: const BorderRadius.all(Radius.circular(999))),
              child: const SizedBox(width: 134, height: 5),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignalPainter extends CustomPainter {
  const _SignalPainter(this.color);

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
  bool shouldRepaint(_SignalPainter old) => old.color != color;
}

class _WifiPainter extends CustomPainter {
  const _WifiPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final outer = Path()
      ..moveTo(1.71, 4.21)
      ..arcToPoint(const Offset(15.29, 4.21), radius: const Radius.circular(9.6));
    final mid = Path()
      ..moveTo(3.97, 6.47)
      ..arcToPoint(const Offset(13.03, 6.47), radius: const Radius.circular(6.4));
    canvas
      ..drawPath(outer, stroke)
      ..drawPath(mid, stroke);
    final wedge = Path()
      ..moveTo(8.5, 11)
      ..lineTo(6.24, 8.74)
      ..arcToPoint(const Offset(10.76, 8.74), radius: const Radius.circular(3.2))
      ..close();
    canvas.drawPath(wedge, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WifiPainter old) => old.color != color;
}

class _BatteryPainter extends CustomPainter {
  const _BatteryPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas
      ..drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0.5, 0.5, 22, 12), const Radius.circular(3.5)), outline)
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
  bool shouldRepaint(_BatteryPainter old) => old.color != color;
}
