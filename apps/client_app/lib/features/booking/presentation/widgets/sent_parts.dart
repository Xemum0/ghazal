import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalDate;
import 'package:ghazal_ui/ghazal_ui.dart';

/// The one ink panel of an outcome screen (web `SuccessHero`): a drawing that settles once (640 ms, no confetti), the outcome in two words
/// and the thread under it. Edge to edge, the single dark surface of the screen.
class BookingSuccessHero extends StatelessWidget {
  const BookingSuccessHero({required this.illustration, required this.title, this.child, super.key});

  final GzIllustrationName illustration;
  final String title;

  /// The thread (`GzBookingThread` on dark) that completes the moment.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final reduced = GzReducedMotion.of(context);
    final art = GzIllustration(illustration, size: GzIllustrationSize.lg, tone: GzIllustrationTone.onDark);
    return Container(
      width: double.infinity,
      margin: const EdgeInsetsDirectional.only(bottom: GzSpace.s6),
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4, bottom: GzSpace.s8),
      color: c.surfaceDark,
      child: Column(
        children: [
          reduced
              ? art
              : TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: GzMotion.scaleKnotFrom, end: 1),
                  duration: GzMotion.durationSuccess,
                  curve: GzMotion.easeEmphasized,
                  builder: (context, v, child) => Transform.scale(scale: v, child: child),
                  child: art,
                ),
          const SizedBox(height: GzSpace.s3),
          Semantics(
            header: true,
            child: GzText(title, role: GzTextRole.d3, color: c.textOnDark, textAlign: TextAlign.center),
          ),
          if (child != null) ...[
            const SizedBox(height: GzSpace.s3),
            Container(
              padding: const EdgeInsetsDirectional.only(top: GzSpace.s4),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: c.borderOnDark, width: GzStroke.hair),
                ),
              ),
              child: child,
            ),
          ],
        ],
      ),
    );
  }
}

/// The planner offer, once: a quiet row that opens the planner and a close glyph that dismisses it (web `PlannerOffer`).
class BookingPlannerOffer extends StatelessWidget {
  const BookingPlannerOffer({required this.onYes, required this.onNo, super.key});

  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.gz.colors;
    return Container(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.s4, end: GzSpace.s1),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: c.borderStrong, width: GzStroke.hair),
      ),
      child: Row(
        children: [
          Expanded(
            child: GzPressable(
              onPressed: onYes,
              semanticLabel: l10n.clientBookingPlannerTitle,
              minWidth: 0,
              minHeight: GzSize.rowMin,
              scale: 1,
              borderRadius: GzRadius.smAll,
              child: Row(
                children: [
                  Container(
                    width: GzSize.avatarSm,
                    height: GzSize.avatarSm,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
                    child: Center(
                      child: GzIcon(GzIcons.staff, size: GzIconSize.md, color: c.iconPrimary),
                    ),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: GzText(l10n.clientBookingPlannerTitle, role: GzTextRole.title, color: c.textStrong),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(width: GzSpace.s1),
          GzIconButton(icon: GzIcons.close, iconSize: GzIconSize.sm, label: l10n.clientBookingPlannerNo, onPressed: onNo),
        ],
      ),
    );
  }
}

/// The notification pre-prompt before the system dialog: a bell drawing, one action, one way out (web `NotifPrompt`).
class BookingNotifPrompt extends StatelessWidget {
  const BookingNotifPrompt({required this.onYes, required this.onNo, super.key});

  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        const GzIllustration(GzIllustrationName.bell, size: GzIllustrationSize.lg),
        const SizedBox(height: GzSpace.s4),
        GzButton(label: l10n.clientBookingSentNotifYes, iconStart: GzIcons.bell, fullWidth: true, onPressed: onYes),
        const SizedBox(height: GzSpace.s2),
        GzButton(label: l10n.clientBookingSentNotifNo, variant: GzButtonVariant.tertiary, onPressed: onNo),
      ],
    );
  }
}

/// The event date as a line: full date, and in the Arabic UI only the muted Hijri line beneath it (ADR 0011).
class BookingDateLine extends ConsumerWidget {
  const BookingDateLine({required this.date, super.key});

  final LocalDate date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.gz.colors;
    final parts = ref.watch(gzFormatProvider).dateWithHijri(date.toString());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GzIcon(GzIcons.calendar, size: GzIconSize.md, color: c.iconSecondary),
        const SizedBox(width: GzSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GzText(parts.primary, role: GzTextRole.title, color: c.textStrong, figures: true),
              if (context.gz.isAr && parts.secondary != null) ...[
                const SizedBox(height: GzSpace.s1),
                GzText(parts.secondary!, role: GzTextRole.caption, color: c.textSecondary, figures: true),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
