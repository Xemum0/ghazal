import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

enum StripTone { neutral, pending, success, danger }

/// StateStrip: the state of the request under the Booking Thread, in a glyph (or, for a finished request, a drawing), a title of at most
/// three words and facts (ADR 0034). The paragraph that survived is behind [info]. Quiet panel, no fill colour: tone reaches the glyph only.
class StateStrip extends StatelessWidget {
  const StateStrip({
    required this.icon,
    this.tone = StripTone.neutral,
    this.illustration,
    this.plain = false,
    this.title,
    this.facts,
    this.info,
    this.actions = const <Widget>[],
    super.key,
  });

  final IconData icon;
  final StripTone tone;
  final GzIllustrationName? illustration;
  final bool plain;
  final String? title;
  final Widget? facts;
  final GzInfoButton? info;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final glyphColor = switch (tone) {
      StripTone.neutral => c.iconSecondary,
      StripTone.pending => c.iconAccent,
      StripTone.success => c.iconSuccess,
      StripTone.danger => c.iconDanger,
    };
    // A drawing with nothing but actions: the actions sit beside the drawing, not under it.
    final beside = illustration != null && title == null && facts == null && actions.isNotEmpty;
    return Container(
      padding: GzSpace.panel,
      decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.mdAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (illustration != null) ...[
                ExcludeSemantics(child: GzIllustration(illustration!, size: GzIllustrationSize.lg)),
                const SizedBox(width: GzSpace.s3),
              ] else if (!plain) ...[
                Container(
                  width: GzSize.touchMin,
                  height: GzSize.touchMin,
                  decoration: BoxDecoration(color: c.surfaceRaised, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: GzIcon(icon, size: GzIconSize.md, color: glyphColor),
                ),
                const SizedBox(width: GzSpace.s3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null) GzText(title!, role: GzTextRole.title, color: tone == StripTone.danger ? c.textDanger : c.textStrong),
                    if (title != null && facts != null) const SizedBox(height: GzSpace.s2),
                    ?facts,
                    if (beside) ...[
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(height: GzSpace.s3),
                        Align(alignment: AlignmentDirectional.centerStart, child: actions[i]),
                      ],
                    ],
                  ],
                ),
              ),
              if (info != null) Align(alignment: AlignmentDirectional.topEnd, child: info),
            ],
          ),
          if (actions.isNotEmpty && !beside) ...[
            const SizedBox(height: GzSpace.s4),
            Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[if (i > 0) const SizedBox(width: GzSpace.s3), Expanded(child: actions[i])],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// ConfirmTimer (approved states): the 24 hour window as a figure and a line (ADR 0034). Hours and minutes, never seconds; the bar shows
/// how much of the window has passed and never turns red; what the hold means is behind the info glyph.
class ConfirmTimer extends StatelessWidget {
  const ConfirmTimer({required this.deadline, required this.now, super.key});

  final DateTime deadline;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final leftMin = deadline.difference(now).inMinutes.clamp(0, 24 * 60);
    if (deadline.difference(now) <= Duration.zero) return const SizedBox.shrink();
    final lastHour = leftMin <= 60;
    final passed = (1 - leftMin / (24 * 60)).clamp(0.0, 1.0);
    // The unit words come from the formatter's own duration (`24 h`, `40 m`): only its first unit word is the unit asked for.
    String unit(int ms) => RegExp(r'[^\d\s\u00a0\u2066-\u2069\u0660-\u0669]+').firstMatch(f.duration(ms))?.group(0) ?? '';
    final hours = leftMin ~/ 60;
    final minutes = leftMin % 60;
    final value = hours > 0
        ? '${f.integer(hours)} ${unit(3600000)}${minutes > 0 ? ' ${f.integer(minutes)} ${unit(60000)}' : ''}'
        : '${f.integer(minutes)} ${unit(60000)}';
    return Semantics(
      container: true,
      label: l.clientBookingsConfirmWindow,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(GzSpace.panelPad, GzSpace.panelPad, GzSpace.panelPad, GzSpace.s5),
        decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.mdAll),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: GzSize.touchMin,
                  height: GzSize.touchMin,
                  decoration: BoxDecoration(color: c.surfaceRaised, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: GzIcon(lastHour ? GzIcons.timer : GzIcons.hourglass, size: GzIconSize.md, color: c.iconAccent),
                ),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Semantics(
                      label: '${l.clientBookingsConfirmLeft} $value',
                      excludeSemantics: true,
                      child: GzText(value, role: GzTextRole.kpi, color: c.textStrong, figures: true, softWrap: false),
                    ),
                  ),
                ),
                GzInfoButton(title: l.clientBookingsConfirmInfoTitle, paragraphs: [l.clientBookingsConfirmInfo]),
              ],
            ),
            const SizedBox(height: GzSpace.s3),
            Semantics(
              label: l.clientBookingsConfirmWindow,
              value: value,
              child: ClipRRect(
                borderRadius: GzRadius.pillAll,
                child: SizedBox(
                  height: GzStroke.threadMax,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (passed * 1000).round(),
                        child: ColoredBox(color: c.markKhayt),
                      ),
                      Expanded(
                        flex: ((1 - passed) * 1000).round(),
                        child: ColoredBox(color: c.markTrack),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pay the venue, then show the code: the coin with its two words, an arrow, and the QR glyph (its word is the accessible name).
class PaySteps extends StatelessWidget {
  const PaySteps({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.touchMin),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: Column(
              children: [
                GzIcon(GzIcons.coins, size: GzIconSize.md, color: c.iconPrimary),
                const SizedBox(height: GzSpace.s1),
                GzText(l.clientBookingsStepPay, role: GzTextRole.bodyS, color: c.textStrong, textAlign: TextAlign.center),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(top: GzSpace.s1),
            child: GzIcon(GzIcons.arrowRight, size: GzIconSize.sm, color: c.iconSecondary),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: GzIcon(GzIcons.qrCode, size: GzIconSize.md, color: c.iconPrimary, semanticLabel: l.clientBookingsStepShow),
            ),
          ),
        ],
      ),
    );
  }
}
