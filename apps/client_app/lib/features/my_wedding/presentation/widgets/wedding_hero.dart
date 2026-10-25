import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';


/// The one ink panel of My Wedding (a local build: the shared CountdownCard has no milestone ticks, no rule under the numeral and no
/// no-date, day-of or done form). Whole days only, never seconds, nothing ticks. The panel speaks in figures: the numeral in the display
/// face (or the word Today / Tomorrow), its unit, the thread with its six marks (365, 180, 30, 7, 1, 0, evenly spaced, not to scale),
/// and the date as a calendar fact. At a milestone one gold line draws under the numeral, once. No eyebrow, no sentence, no thread labels.
class WeddingHero extends StatelessWidget {
  const WeddingHero.count({required this.days, required this.eventDate, this.onDate, this.children = const <Widget>[], super.key})
    : _mode = _HeroMode.count,
      onSetDate = null;

  const WeddingHero.noDate({required this.onSetDate, super.key})
    : _mode = _HeroMode.noDate,
      days = 0,
      eventDate = null,
      onDate = null,
      children = const <Widget>[];

  const WeddingHero.done({required this.eventDate, this.onDate, super.key})
    : _mode = _HeroMode.done,
      days = 0,
      children = const <Widget>[],
      onSetDate = null;

  final _HeroMode _mode;
  final int days;
  final LocalDate? eventDate;
  final VoidCallback? onDate;
  final List<Widget> children;
  final VoidCallback? onSetDate;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: _mode == _HeroMode.count
          ? '${context.l10n.clientMyWeddingHeroDate}: ${context.l10n.clientMyWeddingHeroUnit(days)}'
          : context.l10n.clientMyWeddingHeroDate,
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.surfaceDark, borderRadius: GzRadius.mdAll),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s5, vertical: GzSpace.s6),
          child: switch (_mode) {
            _HeroMode.count => _count(context),
            _HeroMode.noDate => _noDate(context),
            _HeroMode.done => _done(context),
          },
        ),
      ),
    );
  }

  Widget _count(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final milestone = _milestone(days);
    final word = milestone == _Milestone.today
        ? l.clientMyWeddingHeroWordToday
        : milestone == _Milestone.tomorrow
        ? l.clientMyWeddingHeroWordTomorrow
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (word != null)
                  GzText(word, role: GzTextRole.d5, color: c.textOnDark, header: true)
                else
                  GzChromeBaseline(
                    style: context.gz.text(GzTextRole.countdown).copyWith(color: c.textOnDark),
                    child: Text(
                      f.integer(days),
                      style: context.gz.text(GzTextRole.countdown).copyWith(color: c.textOnDark),
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                    ),
                  ),
                if (milestone != null)
                  Container(
                    height: GzStroke.thread,
                    margin: const EdgeInsetsDirectional.only(top: GzSpace.s2),
                    color: c.markKhayt,
                  ),
              ],
            ),
            if (word == null) ...[
              const SizedBox(width: GzSpace.s4),
              Expanded(
                child: GzText(l.clientMyWeddingHeroUnit(days), role: GzTextRole.d1, color: c.textOnDark),
              ),
            ],
          ],
        ),
        const SizedBox(height: GzSpace.s4),
        _Thread(days: days),
        const SizedBox(height: GzSpace.s4),
        _dateFact(context),
        if (children.isNotEmpty) ...[
          const SizedBox(height: GzSpace.s2),
          Row(children: [for (final a in children) Expanded(child: a)]),
        ],
      ],
    );
  }

  Widget _noDate(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GzText(l.clientMyWeddingHeroDate, role: GzTextRole.d2, color: c.textOnDark, header: true),
              const SizedBox(height: GzSpace.s4),
              GzButton(variant: GzButtonVariant.primary, fullWidth: true, onDark: true, onPressed: onSetDate, label: l.clientMyWeddingHeroSetDate),
            ],
          ),
        ),
        const SizedBox(width: GzSpace.s3),
        GzIllustration(GzIllustrationName.calendar, size: GzIllustrationSize.lg, tone: GzIllustrationTone.onDark),
      ],
    );
  }

  Widget _done(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: GzText(l.clientMyWeddingDoneTitle, role: GzTextRole.d2, color: c.textOnDark, header: true),
            ),
            const SizedBox(width: GzSpace.s3),
            GzIllustration(GzIllustrationName.rings, size: GzIllustrationSize.md, tone: GzIllustrationTone.onDark),
          ],
        ),
        const SizedBox(height: GzSpace.s4),
        _dateFact(context),
      ],
    );
  }

  /// The date as a calendar fact (a 44-high button into the wedding file when [onDate] is set).
  Widget _dateFact(BuildContext context) {
    final c = context.gz.colors;
    final date = eventDate;
    if (date == null) return const SizedBox.shrink();
    final f = context.gzFormat;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GzIcon(GzIcons.calendar, size: GzIconSize.sm, color: c.textOnDark),
        const SizedBox(width: GzSpace.s2),
        Flexible(
          child: GzText(f.date(date.toString(), DateStyle.compact), role: GzTextRole.bodyS, color: c.textOnDark, figures: true),
        ),
        if (onDate != null) ...[const SizedBox(width: GzSpace.s1), GzIcon(GzIcons.chevronRight, size: GzIconSize.xs, color: c.textOnDarkMuted)],
      ],
    );
    final onTap = onDate;
    if (onTap == null) return Align(alignment: AlignmentDirectional.centerStart, child: row);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: GzPressable(
        onPressed: onTap,
        onDark: true,
        semanticLabel: context.l10n.clientMyWeddingHeroDate,
        builder: (context, st) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.touchMin),
          child: Align(alignment: AlignmentDirectional.centerStart, child: row),
        ),
      ),
    );
  }
}

enum _HeroMode { count, noDate, done }

enum _Milestone { year, half, month, week, tomorrow, today }

_Milestone? _milestone(int days) {
  if (days <= 0) return _Milestone.today;
  return switch (days) {
    1 => _Milestone.tomorrow,
    7 => _Milestone.week,
    30 => _Milestone.month,
    180 => _Milestone.half,
    365 => _Milestone.year,
    _ => null,
  };
}

/// Six evenly spaced marks; each gap is [half line][mark][half line]. No labels: the milestones are the accessible name.
class _Thread extends StatelessWidget {
  const _Thread({required this.days});

  final int days;

  static const List<int> _marks = [365, 180, 30, 7, 1, 0];

  double _position() {
    if (days >= 365) return 0;
    if (days <= 0) return 5;
    for (var i = 0; i < 5; i++) {
      final a = _marks[i];
      final b = _marks[i + 1];
      if (days <= a && days > b) return i + (a - days) / (a - b);
      if (days == b) return (i + 1).toDouble();
    }
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final position = _position();
    Widget half(double h) {
      final share = ((position - h / 2) / 0.5).clamp(0.0, 1.0);
      final grow = (share * 1000).round();
      final bead = share > 0 && share < 1;
      return Expanded(
        child: Row(
          children: [
            Expanded(
              flex: grow == 0 ? 1 : grow,
              child: Container(height: GzStroke.thread, color: grow == 0 ? c.markTrackOnDark : c.markKhayt),
            ),
            if (bead)
              Transform.rotate(
                angle: 0.785,
                child: Container(width: GzSize.knotBead, height: GzSize.knotBead, color: c.markKhayt),
              ),
            Expanded(
              flex: 1000 - grow == 0 ? 1 : 1000 - grow,
              child: Container(height: GzStroke.thread, color: c.markTrackOnDark),
            ),
          ],
        ),
      );
    }

    Widget mark(int i) {
      final passed = position > i;
      final now = position == i;
      if (now) {
        return Transform.rotate(
          angle: 0.785,
          child: Container(width: GzSize.knotBead, height: GzSize.knotBead, color: c.markKhayt),
        );
      }
      return Container(width: GzStroke.thread, height: GzSize.knotCompact, color: passed ? c.markKhayt : c.markTrackOnDark);
    }

    return Semantics(
      image: true,
      label: '${l.clientMyWeddingHeroTimeline}: ${_marks.map(f.integer).join(', ')}',
      child: ExcludeSemantics(
        child: SizedBox(
          height: GzSize.knotCompact,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) half((2 * i - 1).toDouble()) else const Expanded(child: SizedBox.shrink()),
                mark(i),
                if (i < 5) half((2 * i).toDouble()) else const Expanded(child: SizedBox.shrink()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
