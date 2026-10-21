import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show CreditVoucher, Voucher, VoucherStatus, WalletVoucher;

import '../core/core.dart';
import '../foundation.dart';
import 'gz_qr_code.dart';

enum GzVoucherCardVariant { full, compact, slim }

/// The unbound mark of a credit voucher: a globe and "Any hall, hotel or service" on the rose tint, ink text (no gold fill).
/// Informative only.
class GzAnyVenueMark extends StatelessWidget {
  const GzAnyVenueMark({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.xsAll),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.pillMin),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzIcon(GzIcons.globe, size: GzIconSize.xs, color: c.textPrimary),
                const SizedBox(width: GzSpace.s1),
                Flexible(child: GzText(context.gzL10n.commonVoucherAnyVenue, role: GzTextRole.pill, color: c.textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// VoucherCard: the KD 2 voucher as a ticket (ADR 0033). Ink hairline, two halves cut by a perforation with two notches (they take
/// the surrounding [ground], default canvas), the QR drawn from the signed payload, the code as an LTR figure, the venue or
/// provider it is bound to, the bound quote (standard struck, voucher price) and the state pill. No gold fill: a voucher is a fact.
/// ADR 0034 text diet: glyphs and figures (ticket = voucher, tag = standard price), the words are accessible names.
///
/// [variant] `full` (voucher detail), `compact` (one wallet row, no QR; [onOpen] makes it one target) and `slim` (the voucher on its
/// own booking: QR, code, validity and the two actions). A credit voucher (`CreditVoucher`, support-granted, unbound) wears a gift
/// glyph and [GzAnyVenueMark] instead of a venue and a quote. A used, expired, forfeited or credit-issued voucher keeps its code and
/// mutes its QR. A widget never looks anything up: the caller passes [targetName] (venue or provider) and [packageName].
class GzVoucherCard extends StatelessWidget {
  const GzVoucherCard({
    required this.voucher,
    this.variant = GzVoucherCardVariant.full,
    this.targetName = '',
    this.packageName,
    this.onOpen,
    this.onCopy,
    this.onShowFull,
    this.ground,
    super.key,
  });

  /// A bound voucher or a credit voucher.
  final WalletVoucher voucher;
  final GzVoucherCardVariant variant;

  /// The venue or provider a bound voucher belongs to (display name in the viewer's language).
  final String targetName;
  final String? packageName;

  /// Opens the voucher (compact only: the row is one 44+ target).
  final VoidCallback? onOpen;
  final VoidCallback? onCopy;

  /// The full-screen QR view; omit to hide the button. Only a live voucher shows it.
  final VoidCallback? onShowFull;

  /// The colour behind the card, which the perforation notches take (default canvas).
  final Color? ground;

  bool get _credit => voucher is CreditVoucher;
  bool get _live => _credit ? voucher.status == VoucherStatus.active : voucher.status == VoucherStatus.bound || voucher.status == VoucherStatus.active;

  GzStatus get _state => switch (voucher.status) {
        VoucherStatus.unpaid => GzStatus.voucherUnpaid,
        VoucherStatus.active => _credit ? GzStatus.voucherCredit : GzStatus.voucherActive,
        VoucherStatus.bound => GzStatus.voucherBound,
        VoucherStatus.used => GzStatus.voucherUsed,
        VoucherStatus.forfeited => GzStatus.voucherForfeited,
        VoucherStatus.creditIssued => GzStatus.voucherCreditIssued,
        _ => GzStatus.voucherExpired,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.gzL10n;
    final v = voucher;
    final title = _credit ? l.commonVoucherCredit : targetName;
    final until = _validity(context);
    final label = [
      _credit ? l.commonVoucherCredit : l.commonVoucher,
      v.code,
      if (!_credit && targetName.isNotEmpty) targetName,
      _state.label(l),
      if (until != null) '${until.$2} ${GzBidi.strip(until.$3)}',
    ].join(', ');
    return switch (variant) {
      GzVoucherCardVariant.compact => _compact(context, title, until, label),
      GzVoucherCardVariant.slim => _slim(context, until, label),
      GzVoucherCardVariant.full => _full(context, title, until, label),
    };
  }

  /// (icon, label word, formatted date) of the validity fact: the day it was redeemed, else the day it stops being valid.
  (IconData, String, String)? _validity(BuildContext context) {
    final l = context.gzL10n;
    final f = context.gzFormat;
    final v = voucher;
    if (v.status == VoucherStatus.used && v.usedAt != null) return (GzIcons.checkDouble, l.uiVoucherCardUsedOn, f.date(v.usedAt!, DateStyle.compact));
    if (v.validUntil != null) return (GzIcons.calendar, l.uiVoucherCardValidUntil, f.date(v.validUntil!, DateStyle.compact));
    return null;
  }

  Widget _validityRow((IconData, String, String)? u) => u == null
      ? const SizedBox.shrink()
      : GzFactRow(children: [GzFactChip(icon: u.$1, label: u.$2, value: u.$3, small: true, tone: GzFactTone.muted)]);

  Widget _qrBox(BuildContext context, double size) {
    final c = context.gz.colors;
    return Container(
      decoration: BoxDecoration(color: c.surfaceCanvas, borderRadius: GzRadius.smAll, border: Border.all(color: c.borderHairline, width: GzStroke.hair)),
      padding: const EdgeInsets.all(GzSpace.s2),
      child: GzQrCode(payload: voucher.qr.payload, label: context.gzL10n.uiVoucherCardQrLabel(voucher.code), size: size, muted: !_live),
    );
  }

  Widget _code(BuildContext context) => GzNum(voucher.code, role: GzTextRole.figTitle, color: context.gz.colors.textStrong, maxLines: 2);

  /// A figures-voice line sits at the physical left in both languages (the web figure roles are `direction: ltr`).
  Widget _leftToRight(Widget child) => GzLtr(child: Align(alignment: AlignmentDirectional.centerStart, child: child));

  Widget _notValid(BuildContext context) {
    if (voucher.status != VoucherStatus.forfeited) return const SizedBox.shrink();
    final c = context.gz.colors;
    return Padding(
      padding: const EdgeInsets.only(top: GzSpace.s1),
      child: GzText.rich(
        TextSpan(
          children: [
            WidgetSpan(alignment: PlaceholderAlignment.middle, child: GzIcon(GzIcons.xCircle, size: GzIconSize.xs, color: c.iconDanger)),
            TextSpan(text: ' ${context.gzL10n.commonVoucherNotValidNote(24)}'),
          ],
        ),
        role: GzTextRole.caption,
        color: c.textSecondary,
      ),
    );
  }

  Widget _actions(BuildContext context) {
    if (onCopy == null && onShowFull == null) return const SizedBox.shrink();
    final l = context.gzL10n;
    return Padding(
      padding: const EdgeInsets.only(top: GzSpace.s4),
      child: Row(
        children: [
          if (onCopy != null) Expanded(child: GzButton(label: l.uiVoucherCardCopy, iconStart: GzIcons.copy, variant: GzButtonVariant.secondary, size: GzButtonSize.md, fullWidth: true, spill: true, onPressed: onCopy)),
          if (onCopy != null && onShowFull != null && _live) const SizedBox(width: GzSpace.s3),
          if (onShowFull != null && _live)
            Expanded(child: GzButton(label: l.uiVoucherCardFull, iconStart: GzIcons.qrCode, variant: GzButtonVariant.secondary, size: GzButtonSize.md, fullWidth: true, spill: true, onPressed: onShowFull)),
        ],
      ),
    );
  }

  /// The QR box and the code block: side by side when the code fits beside the QR, otherwise the block wraps under it and takes the
  /// whole width (the web `flex: 1 1 auto` item). The code is a figures voice: left to right, so it sits at the physical left.
  Widget _stub(BuildContext context, (IconData, String, String)? until, double qr) {
    final gz = context.gz;
    final codeStyle = GzFigures.inlineStyle(gz.locale, GzTextRole.figTitle);
    final code = TextPainter(text: TextSpan(text: voucher.code, style: codeStyle), textDirection: TextDirection.ltr, maxLines: 1)..layout();
    final codeWidth = code.width;
    code.dispose();
    final block = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _leftToRight(_code(context)),
        const SizedBox(height: GzSpace.s1),
        Align(alignment: AlignmentDirectional.centerStart, child: _validityRow(until)),
        _notValid(context),
      ],
    );
    final box = _qrBox(context, qr);
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, c) {
          final boxWidth = qr + 2 * (GzSpace.s2 + GzStroke.hair);
          final beside = boxWidth + GzSpace.s5 + codeWidth <= c.maxWidth;
          return beside
              ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [box, const SizedBox(width: GzSpace.s5), Expanded(child: block)])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [box, const SizedBox(height: GzSpace.s4), block]);
        },
      ),
    );
  }

  Widget _full(BuildContext context, String title, (IconData, String, String)? until, String label) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final v = voucher;
    final top = <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GzIcon(_credit ? GzIcons.gift : GzIcons.ticket, size: GzIconSize.md, color: c.iconSecondary),
          GzStatusPill(status: _state),
        ],
      ),
      const SizedBox(height: GzSpace.s4),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GzText(title, role: GzTextRole.d1, color: c.textStrong),
          if (_credit)
            const Padding(padding: EdgeInsets.only(top: GzSpace.s1), child: GzAnyVenueMark())
          else
            Padding(
              padding: const EdgeInsets.only(top: GzSpace.s1),
              child: GzFactRow(
                children: [
                  if (packageName != null) GzFactChip(icon: GzIcons.package, label: l.uiVoucherCardPackage, value: packageName, small: true, tone: GzFactTone.muted),
                  GzFactChip(icon: GzIcons.calendar, label: l.uiVoucherCardDate, value: f.date((v as Voucher).eventDate.toString(), DateStyle.short), small: true, tone: GzFactTone.muted),
                  if (v.guests != null && v.guests! > 0) GzFactChip(icon: GzIcons.usersThree, label: l.uiSharedGuests, value: f.integer(v.guests!), small: true, tone: GzFactTone.muted),
                ],
              ),
            ),
        ],
      ),
      if (!_credit) ...[const SizedBox(height: GzSpace.s4), _quote(context, voucher as Voucher)],
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: RepaintBoundary(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(child: _half(context, top: true, children: top)),
            ExcludeSemantics(child: SizedBox(height: GzSpace.s4, child: CustomPaint(painter: _PerfPainter(ground: ground ?? c.surfaceCanvas, fill: c.surfaceRaised, line: c.borderStrong)))),
            _half(context, top: false, children: [_stub(context, until, 144), _actions(context)]),
          ],
        ),
      ),
    );
  }

  /// One half of the ticket: raised surface, hairline on three sides (the perforation side stays open), 12 radius on the outer corners.
  Widget _half(BuildContext context, {required bool top, required List<Widget> children}) {
    final c = context.gz.colors;
    final side = BorderSide(color: c.borderStrong, width: GzStroke.hair);
    // A Container (not a DecoratedBox): its padding adds the border width, like the web border-box (content at 17).
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        border: Border(top: top ? side : BorderSide.none, bottom: top ? BorderSide.none : side, left: side, right: side),
        borderRadius: top ? const BorderRadius.vertical(top: Radius.circular(GzRadius.md)) : const BorderRadius.vertical(bottom: Radius.circular(GzRadius.md)),
      ),
      padding: const EdgeInsets.all(GzSpace.panelPad),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _quote(BuildContext context, Voucher v) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    Widget cell(String name, IconData icon, GzIconSize size, Color color, Widget price) => Semantics(
          label: name,
          container: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            // The web `dd` is a block: its line box holds the page line (28 in Arabic, 24 in English) around the inline price.
            children: [GzIcon(icon, size: size, color: color), Align(alignment: AlignmentDirectional.centerStart, child: GzInlineStrut(role: GzTextRole.body, child: price))],
          ),
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        cell(l.commonStandardPrice, GzIcons.offer, GzIconSize.xs, c.iconSecondary, GzStruckMoney(fils: v.quoteFils.standard)),
        const SizedBox(width: GzSpace.s6),
        cell(l.commonVoucherPrice, GzIcons.ticket, GzIconSize.sm, c.iconSuccess, GzMoney(fils: v.quoteFils.voucher, amountRole: GzTextRole.priceStrong, filsRole: GzTextRole.filsPrice)),
      ],
    );
  }

  Widget _slim(BuildContext context, (IconData, String, String)? until, String label) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: Container(
        decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
        padding: const EdgeInsets.all(GzSpace.panelPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: Column(
                children: [
                  _qrBox(context, 128),
                  const SizedBox(height: GzSpace.s4),
                  if (!_live) ...[GzStatusPill(status: _state), const SizedBox(height: GzSpace.s1)],
                  _code(context),
                  const SizedBox(height: GzSpace.s1),
                  if (until != null) Center(child: _validityRow(until)),
                  _notValid(context),
                ],
              ),
            ),
            _actions(context),
          ],
        ),
      ),
    );
  }

  Widget _compact(BuildContext context, String title, (IconData, String, String)? until, String label) {
    final c = context.gz.colors;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.rowMin),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4, vertical: GzSpace.s3),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
              child: SizedBox.square(dimension: GzSize.avatarMd, child: Center(child: GzIcon(_credit ? GzIcons.gift : GzIcons.ticket, size: GzIconSize.md, color: c.iconPrimary))),
            ),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GzText(title, role: GzTextRole.title, color: c.textStrong),
                  if (_credit) const GzAnyVenueMark(),
                  SizedBox(width: double.infinity, child: _leftToRight(GzNum(voucher.code, role: GzTextRole.figCaption, color: c.textSecondary))),
                  _validityRow(until),
                ],
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            GzStatusPill(status: _state),
          ],
        ),
      ),
    );
    final box = Container(
      decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
      child: onOpen == null
          ? Semantics(container: true, label: label, child: ExcludeSemantics(child: row))
          : GzPressable(onPressed: onOpen, semanticLabel: label, borderRadius: GzRadius.mdAll, child: row),
    );
    return RepaintBoundary(child: box);
  }
}

/// The perforation: the raised surface, a dashed hairline through the middle and a half-disc notch of [ground] at each edge that bites 8 dp into the card.
class _PerfPainter extends CustomPainter {
  const _PerfPainter({required this.ground, required this.fill, required this.line});

  final Color ground;
  final Color fill;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    const r = GzRadius.sm;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = fill);
    final cy = h / 2;
    // The dashed hairline between the notches: 3 dp dashes, a gap of about 2 dp stretched so both ends are dashes (what Chrome draws).
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
  bool shouldRepaint(_PerfPainter old) => old.ground != ground || old.fill != fill || old.line != line;
}
