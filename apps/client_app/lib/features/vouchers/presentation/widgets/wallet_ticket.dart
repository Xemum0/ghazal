import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../voucher_fmt.dart';
import 'voucher_parts.dart';

/// The status pill of a voucher (the shared `GzStatus` of the voucher states).
GzStatus gzStatusOfVoucher(WalletVoucher v) => switch (v.status) {
  VoucherStatus.unpaid => GzStatus.voucherUnpaid,
  VoucherStatus.active => v is CreditVoucher ? GzStatus.voucherCredit : GzStatus.voucherActive,
  VoucherStatus.bound => GzStatus.voucherBound,
  VoucherStatus.used => GzStatus.voucherUsed,
  VoucherStatus.forfeited => GzStatus.voucherForfeited,
  VoucherStatus.creditIssued => GzStatus.voucherCreditIssued,
  _ => GzStatus.voucherExpired,
};

/// The one fact of the stub: a glyph, the word that names it (read by assistive technology only) and its value.
class StubFact {
  const StubFact({required this.icon, required this.label, required this.value, this.accent = false});

  final IconData icon;
  final String label;
  final String value;
  final bool accent;
}

/// One voucher in the wallet (web `Ticket`): a paper ticket with a perforation and two notches. The top half is the one target that opens
/// the voucher: the venue (photograph or monogram, name), the event date as a fact, the saving as a figure and the state as a pill. The
/// bottom half (the stub) carries ONE fact, the date that matters for the state, and the actions that fit. No sentences, no gold fill.
class WalletTicket extends StatelessWidget {
  const WalletTicket({required this.item, this.stub, this.actions = const <Widget>[], this.onOpen, super.key});

  final WalletItem item;
  final StubFact? stub;
  final List<Widget> actions;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    final v = item.voucher;
    final credit = v is CreditVoucher;
    final name = credit ? context.gzL10n.commonVoucherCredit : voucherText(context, item.target?.name);
    final solo = stub == null && actions.isEmpty;
    final saving = v is Voucher ? (v.quoteFils.standard - v.quoteFils.voucher).clamp(0, 1 << 40) : 0;
    final who = Row(
      children: [
        if (credit)
          Container(
            width: GzSize.avatarMd,
            height: GzSize.avatarMd,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.surfaceTint, shape: BoxShape.circle),
            child: GzIcon(GzIcons.gift, size: GzIconSize.md, color: c.iconPrimary),
          )
        else
          VoucherThumb(name: name, cover: item.target?.cover, monogram: item.target?.monogram),
        const SizedBox(width: GzSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GzText(name, role: GzTextRole.d1, color: c.textStrong),
              const SizedBox(height: GzSpace.s1),
              if (credit)
                const GzAnyVenueMark()
              else
                GzFactRow(
                  children: [GzFactChip(icon: GzIcons.calendar, label: context.l10n.clientVouchersLabelEvent, value: f.dayMon((v as Voucher).eventDate.toString()), tone: GzFactTone.muted)],
                ),
            ],
          ),
        ),
      ],
    );
    final topInner = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        who,
        const SizedBox(height: GzSpace.s3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [if (saving > 0) Flexible(child: VoucherSaving(fils: saving)) else const SizedBox.shrink(), const SizedBox(width: GzSpace.s3), GzStatusPill(status: gzStatusOfVoucher(v))],
        ),
      ],
    );
    final side = BorderSide(color: c.borderStrong, width: GzStroke.hair);
    final top = Container(
      padding: GzSpace.panel,
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        border: Border(top: side, left: side, right: side, bottom: solo ? side : BorderSide.none),
        borderRadius: solo ? GzRadius.mdAll : const BorderRadius.vertical(top: Radius.circular(GzRadius.md)),
      ),
      child: topInner,
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: '$name ${v.code}',
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onOpen == null)
              ExcludeSemantics(child: top)
            else
              GzPressable(onPressed: onOpen, semanticLabel: '$name ${v.code}', borderRadius: GzRadius.mdAll, expand: true, minHeight: GzSize.rowMin, child: top),
            if (!solo) ...[
              ExcludeSemantics(
                child: SizedBox(height: GzSpace.s4, child: CustomPaint(painter: _Perf(ground: c.surfaceCanvas, fill: c.surfaceRaised, line: c.borderStrong))),
              ),
              Container(
                padding: GzSpace.panel,
                decoration: BoxDecoration(
                  color: c.surfaceRaised,
                  border: Border(bottom: side, left: side, right: side),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(GzRadius.md)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (stub != null)
                      GzFactRow(
                        children: [GzFactChip(icon: stub!.icon, label: stub!.label, value: stub!.value, tone: stub!.accent ? GzFactTone.accent : GzFactTone.muted)],
                      ),
                    if (actions.isNotEmpty) ...[
                      if (stub != null) const SizedBox(height: GzSpace.s3),
                      Row(
                        children: [
                          Expanded(child: actions.first),
                          for (final a in actions.skip(1)) ...[const SizedBox(width: GzSpace.s3), a],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The perforation: a dashed hairline through the middle and a half-disc notch of the ground colour at each edge.
class _Perf extends CustomPainter {
  const _Perf({required this.ground, required this.fill, required this.line});

  final Color ground;
  final Color fill;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    const r = GzRadius.sm;
    final cy = size.height / 2;
    canvas.drawRect(Offset.zero & size, Paint()..color = fill);
    final run = size.width - 2 * r;
    const dash = 3.0;
    final n = ((run + 2) / (dash + 2)).round();
    final gap = n > 1 ? (run - n * dash) / (n - 1) : 0.0;
    final ink = Paint()..color = line;
    for (var i = 0; i < n; i++) {
      canvas.drawRect(Rect.fromLTWH(r + i * (dash + gap), cy - GzStroke.hair / 2, dash, GzStroke.hair), ink);
    }
    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = GzStroke.hair;
    for (final left in [true, false]) {
      final dx = left ? 0.0 : size.width;
      final path = Path()
        ..moveTo(dx, cy - r)
        ..arcToPoint(Offset(dx, cy + r), radius: const Radius.circular(r), clockwise: left)
        ..close();
      canvas.drawPath(path, Paint()..color = ground);
      final arc = Path()
        ..moveTo(dx, cy - r + GzStroke.hair / 2)
        ..arcToPoint(Offset(dx, cy + r - GzStroke.hair / 2), radius: const Radius.circular(r - GzStroke.hair / 2), clockwise: left);
      canvas.drawPath(arc, stroke);
    }
  }

  @override
  bool shouldRepaint(_Perf old) => old.ground != ground || old.fill != fill || old.line != line;
}
