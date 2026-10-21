/// VoucherWindowCard (Home shelves "Voucher price drops", venue details; ADR 0033, HL-GROW voucher windows): the one rose panel of the
/// client app. Port of design/src/system/domain-client/VoucherWindowCard.tsx.
///
/// A window is a time-boxed LOWER voucher price a venue offers on chosen event dates (it replaces the old offers and coupon codes: the
/// voucher is the code). The rate is a figure in the figures voice with its unit, the title is the venue's own words in the serif, the
/// conditions are plain facts (event window, weekdays, booking ends). Never an urgency counter. States: default, pressed
/// ([previewState]), ended and scheduled (muted, no action), loading.
library;

import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, GzFormat, NameStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalizedText, VoucherWindow, VoucherWindowStatus;

import '../core/core.dart';
import '../foundation.dart';
import 'client_a_kit.dart';

class GzVoucherWindowCard extends StatelessWidget {
  const GzVoucherWindowCard({required this.window, this.venueName, this.onOpen, this.loading = false, this.previewState, super.key});

  final VoucherWindow window;

  /// The venue's name (the screen resolves `window.venueId`).
  final LocalizedText? venueName;
  final VoidCallback? onOpen;
  final bool loading;

  /// Gallery only: show the pressed look without a pointer.
  final GzPreviewState? previewState;

  /// Weekday indexes as `Sun – Wed` when they run in a row, else a list. Names come from the formatter.
  static String weekdaySpan(GzFormat f, List<int> days) {
    final sorted = [...days]..sort();
    if (sorted.isEmpty) return '';
    final consecutive = [for (var i = 1; i < sorted.length; i++) sorted[i] == sorted[i - 1] + 1].every((e) => e);
    if (consecutive && sorted.length > 2) return '${f.weekdayName(sorted.first, NameStyle.short)} – ${f.weekdayName(sorted.last, NameStyle.short)}';
    return f.list([for (final d in sorted) f.weekdayName(d, NameStyle.short)]);
  }

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final lang = gz.locale.languageCode;
    const radius = GzRadius.mdAll;
    if (loading) {
      return Semantics(
        container: true,
        label: l.commonStateLoading,
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(color: c.surfaceTint, borderRadius: radius),
            child: const Padding(
              padding: GzSpace.panel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GzSkeleton(inlineSize: 96, blockSize: 20),
                  SizedBox(height: GzSpace.s2),
                  GzSkeleton(inlineSize: 200, blockSize: 28),
                  SizedBox(height: GzSpace.s2),
                  GzSkeleton(inlineSize: 160, blockSize: 20),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final win = window;
    final live = win.status == VoucherWindowStatus.active;
    final windowText = win.eventFrom != null && win.eventTo != null
        ? l.uiClientVoucherWindowEvents(
            l.uiClientVoucherWindowFromTo(f.date(win.eventFrom.toString(), DateStyle.compact), f.date(win.eventTo.toString(), DateStyle.compact)),
          )
        : (win.eventDates != null && win.eventDates!.isNotEmpty ? l.uiClientVoucherWindowEventsDates : null);
    final days = win.eventWeekdays;
    final daysText = days != null && days.isNotEmpty ? l.uiClientVoucherWindowEventsOn(weekdaySpan(f, days)) : null;
    final rate = win.voucherPerGuest ?? win.voucherFlat;
    final facts = <Widget>[
      for (final line in [windowText, daysText].whereType<String>()) GzText(line, role: GzTextRole.caption, color: c.textPrimary, figures: true),
      if (win.endsAt != null && live)
        GzText(l.uiClientVoucherWindowUntil(f.date(win.endsAt!, DateStyle.short)), role: GzTextRole.caption, color: c.textPrimary, figures: true),
      if (!live)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GzIcon(GzIcons.info, size: GzIconSize.xs, color: c.iconSecondary),
            const SizedBox(width: GzSpace.s1),
            GzText(win.status == VoucherWindowStatus.ended ? l.uiClientVoucherWindowEnded : l.uiClientVoucherWindowScheduled, role: GzTextRole.caption, color: c.textPrimary),
          ],
        ),
    ];
    final card = DecoratedBox(
      decoration: BoxDecoration(color: live ? c.surfaceTint : c.surfaceTintSoft, borderRadius: radius),
      child: Padding(
        padding: GzSpace.panel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzIcon(GzIcons.ticket, size: GzIconSize.xs, color: c.iconSecondary),
                const SizedBox(width: GzSpace.s2),
                GzText(l.uiClientVoucherWindowEyebrow, role: GzTextRole.label, color: c.textPrimary),
              ],
            ),
            if (rate != null) ...[
              const SizedBox(height: GzSpace.s2),
              GzPrice(fils: rate.fils, size: GzPriceSize.total, unit: win.voucherPerGuest != null ? GzPriceUnit.perGuest : GzPriceUnit.perNight),
            ],
            const SizedBox(height: GzSpace.s2),
            GzText(win.title.of(lang), role: GzTextRole.d1, color: c.textPrimary, header: true),
            const SizedBox(height: GzSpace.s2),
            GzText(venueName?.of(lang) ?? '', role: GzTextRole.bodyS, color: c.textPrimary),
            const SizedBox(height: GzSpace.s2),
            for (var i = 0; i < facts.length; i++) ...[if (i > 0) const SizedBox(height: GzStroke.thread), facts[i]],
            if (live) ...[
              const SizedBox(height: GzSpace.s2 + GzSpace.s1),
              GzButton(label: l.uiClientVoucherWindowView, variant: GzButtonVariant.tertiary, iconEnd: GzIcons.chevronRight, onPressed: onOpen),
            ],
          ],
        ),
      ),
    );
    return RepaintBoundary(
      child: Semantics(container: true, explicitChildNodes: true, child: gzPressedPreview(previewState == GzPreviewState.pressed, card)),
    );
  }
}
