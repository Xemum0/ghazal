import 'package:flutter/widgets.dart';
import 'package:qr_flutter/qr_flutter.dart' show QrCode, QrErrorCorrectLevel, QrImage;

import '../foundation.dart';

/// Quiet zone in modules, inside the box (the web `QUIET`): two modules, error correction M.
const int gzQrQuiet = 2;

/// The dark modules of the QR of [payload] (error correction M, smallest version that fits, the same call as the web
/// `qrcode(0, 'M')`): `count` per side and a row-major list of dark flags. Cached per payload (a wallet list repaints often).
({int count, List<bool> dark}) gzQrModules(String payload) {
  final hit = _cache[payload];
  if (hit != null) return hit;
  final qr = QrCode.fromData(data: payload, errorCorrectLevel: QrErrorCorrectLevel.M);
  final image = QrImage(qr);
  final n = image.moduleCount;
  final dark = <bool>[for (var r = 0; r < n; r++) for (var c = 0; c < n; c++) image.isDark(r, c)];
  if (_cache.length > 64) _cache.remove(_cache.keys.first);
  return _cache[payload] = (count: n, dark: dark);
}

final Map<String, ({int count, List<bool> dark})> _cache = {};

/// QrCode: the voucher's QR, generated from the signed payload (`gz:v1:<code>:<target>:<check>`) and drawn as square one-module
/// rectangles in the strongest ink token on the canvas token (never gold, never a tint): a scanner needs real contrast. The payload is
/// never shown as text, only [label] is the accessible name. [muted] draws the same art at the secondary ink (a used, expired or
/// forfeited voucher keeps its code but cannot be scanned; the card says why). The art is crisp at any [size] (edges snap).
class GzQrCode extends StatelessWidget {
  const GzQrCode({required this.payload, required this.label, this.size = 144, this.muted = false, super.key});

  /// The signed payload to encode (`Voucher.qr.payload`).
  final String payload;

  /// Accessible name; the payload itself is never exposed.
  final String label;

  /// Rendered edge in dp (default 144).
  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final modules = gzQrModules(payload);
    return Semantics(
      label: label,
      image: true,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(size),
          painter: _QrPainter(modules: modules, ground: c.surfaceCanvas, ink: muted ? c.textSecondary : c.textStrong),
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  const _QrPainter({required this.modules, required this.ground, required this.ink});

  final ({int count, List<bool> dark}) modules;
  final Color ground;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final n = modules.count;
    final edge = n + gzQrQuiet * 2;
    final unit = size.width / edge;
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    final paint = Paint()
      ..color = ink
      ..isAntiAlias = false;
    for (var r = 0; r < n; r++) {
      var c = 0;
      while (c < n) {
        if (!modules.dark[r * n + c]) {
          c++;
          continue;
        }
        var run = 1;
        while (c + run < n && modules.dark[r * n + c + run]) {
          run++;
        }
        // One rectangle per horizontal run: fewer draw calls, and adjacent modules never show a seam.
        canvas.drawRect(Rect.fromLTWH((c + gzQrQuiet) * unit, (r + gzQrQuiet) * unit, run * unit, unit), paint);
        c += run;
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.modules != modules || old.ground != ground || old.ink != ink;
}
