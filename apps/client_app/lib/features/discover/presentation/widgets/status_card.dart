import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, GzFormat, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show HomeStatusCard, HomeStatusKind;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

/// The one urgency-ranked card under the Brief card (ADR 0007 D4, ADR 0033 D3): a drawing, a one-word pill, the venue's name and the one
/// fact that matters as glyph and value. The whole card is one button (the disclosure chevron at inline-end); it never carries a second
/// action, so the gold CTA of the Brief card stays the only verb on Home.
class HomeStatusCardView extends ConsumerWidget {
  const HomeStatusCardView({required this.card, required this.briefDate, required this.count, required this.eventDate, this.onOpen, super.key});

  final HomeStatusCard card;

  /// The Brief date (kind `brief-set`).
  final String? briefDate;

  /// Halls free on the Brief date in the Brief's areas (kind `brief-set`).
  final int count;

  /// The date of a confirmed request (kind `confirmed`).
  final String? eventDate;
  final VoidCallback? onOpen;

  static GzIllustrationName artOf(HomeStatusKind k) => switch (k) {
    HomeStatusKind.noDate => GzIllustrationName.calendar,
    HomeStatusKind.briefSet => GzIllustrationName.hall,
    HomeStatusKind.voucherReady => GzIllustrationName.voucher,
    HomeStatusKind.pending => GzIllustrationName.envelope,
    HomeStatusKind.approved => GzIllustrationName.invitation,
    HomeStatusKind.confirmed => GzIllustrationName.seal,
    HomeStatusKind.visitSoon => GzIllustrationName.doorway,
    HomeStatusKind.unknown => GzIllustrationName.calendar,
  };

  static GzStatus? pillOf(HomeStatusKind k) => switch (k) {
    HomeStatusKind.voucherReady => GzStatus.voucherActive,
    HomeStatusKind.pending => GzStatus.pending,
    HomeStatusKind.approved => GzStatus.approved,
    HomeStatusKind.confirmed => GzStatus.confirmed,
    HomeStatusKind.visitSoon => GzStatus.visitConfirmed,
    _ => null,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.gz.colors;
    final l = context.l10n;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final now = ref.watch(clockProvider)();
    final kind = card.kind;
    final target = card.target?.name.of(lang) ?? '';
    var title = target;
    final facts = <Widget>[];
    var spoken = '';
    switch (kind) {
      case HomeStatusKind.noDate || HomeStatusKind.unknown:
        title = l.clientDiscoverStatusNoDate;
      case HomeStatusKind.briefSet:
        final date = briefDate == null ? '' : f.date(briefDate!, DateStyle.short);
        title = f.digits(l.clientDiscoverStatusBrief(count));
        if (date.isNotEmpty) facts.add(GzFactChip(icon: GzIcons.calendar, label: l.clientDiscoverA11yDate, value: date));
        spoken = date;
      case HomeStatusKind.voucherReady:
        break;
      case HomeStatusKind.pending || HomeStatusKind.approved:
        final time = card.deadline == null ? '' : timeLeft(f, card.deadline!, now);
        if (time.isNotEmpty) {
          facts.add(GzFactChip(icon: GzIcons.timer, label: l.clientDiscoverA11yTimeLeft, value: time, tone: kind == HomeStatusKind.approved ? GzFactTone.accent : GzFactTone.normal));
        }
        spoken = time;
      case HomeStatusKind.confirmed:
        final date = eventDate == null ? '' : f.date(eventDate!, DateStyle.short);
        if (date.isNotEmpty) facts.add(GzFactChip(icon: GzIcons.calendar, label: l.clientDiscoverA11yDate, value: date));
        spoken = date;
      case HomeStatusKind.visitSoon:
        final slot = card.deadline ?? now;
        final same = f.isoDay(slot) == f.isoDay(now);
        final day = same ? context.gzL10n.commonLabelToday : context.gzL10n.commonLabelTomorrow;
        final time = f.time(slot);
        facts
          ..add(GzFactChip(icon: GzIcons.calendar, label: l.clientDiscoverA11yDate, value: day))
          ..add(GzFactChip(icon: GzIcons.clock, label: l.clientDiscoverA11yTime, value: time));
        spoken = '$day $time';
    }
    final pill = pillOf(kind);
    return GzPressable(
      onPressed: onOpen,
      semanticLabel: <String>[GzBidi.strip(title), if (spoken.isNotEmpty) GzBidi.strip(spoken)].join('. '),
      builder: (context, st) => Container(
        key: const ValueKey<String>('discover.status'),
        constraints: const BoxConstraints(minHeight: GzSize.briefRow),
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s3, bottom: GzSpace.s3, start: GzSpace.s3, end: GzSpace.panelPad),
        decoration: BoxDecoration(
          color: st.pressed ? c.surfaceQuiet : c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
        ),
        child: Row(
          children: [
            ExcludeSemantics(child: GzIllustration(artOf(kind), size: GzIllustrationSize.sm)),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pill != null) ...[GzStatusPill(status: pill), const SizedBox(height: GzSpace.s2)],
                  Text.rich(
                    TextSpan(children: GzFigures.spans(context, title, role: GzTextRole.body)),
                    style: context.gz.text(GzTextRole.body).copyWith(color: c.textStrong, fontWeight: context.gz.text(GzTextRole.title).fontWeight, decoration: TextDecoration.none),
                  ),
                  if (facts.isNotEmpty) ...[const SizedBox(height: GzSpace.s2), GzFactRow(children: facts)],
                ],
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
          ],
        ),
      ),
    );
  }

  /// A reply or confirm window is hours and minutes (`24 h`, `20 h 40 m`) in the formatter's own unit letters; beyond two days the
  /// compact duration (days).
  static String timeLeft(GzFormat f, DateTime deadline, DateTime now) {
    final ms = deadline.difference(now).inMilliseconds.clamp(0, 1 << 40);
    if (ms >= 48 * 3600000) return f.duration(ms);
    String unit(int unitMs) => GzBidi.strip(f.duration(unitMs).split(' ').first).replaceAll(RegExp(r'[\d\u00a0]+'), '');
    final minutes = ms ~/ 60000;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final mm = '${f.integer(m)} ${unit(60000)}';
    return h > 0 ? '${f.integer(h)} ${unit(3600000)}${m > 0 ? ' $mm' : ''}' : mm;
  }
}
