import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'wd_common.dart' show WdGap, WdPad;

class WdConfirmLead extends ConsumerWidget {
  const WdConfirmLead({super.key, required this.confirmBy});

  final DateTime confirmBy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = context.gzNav;
    return GzConfirmWindow(deadline: confirmBy, onConfirm: () => nav.push('CL-BKNG-02'));
  }
}

/// Day-of mode: Directions, Call venue and Message planner beside the primary.
List<Widget> wdDayOfActions(BuildContext context) {
  final l = context.l10n;
  final nav = context.gzNav;
  return [
    GzButton(
      variant: GzButtonVariant.primary,
      iconStart: GzIcons.navigate,
      onPressed: () => nav.toast(GzToastSpec(message: l.clientMyWeddingDayDirectionsToast, icon: GzIcons.navigate)),
      label: l.clientMyWeddingDayDirections,
    ),
    GzIconButton(
      icon: GzIcons.phone,
      variant: GzIconButtonVariant.onScrim,
      disk: GzIconButtonDisk.lg,
      label: l.clientMyWeddingDayCall,
      onPressed: () => nav.toast(GzToastSpec(message: l.clientMyWeddingDayCallToast, icon: GzIcons.phone)),
    ),
    GzIconButton(
      icon: GzIcons.chat,
      variant: GzIconButtonVariant.onScrim,
      disk: GzIconButtonDisk.lg,
      label: l.clientMyWeddingDayMessage,
      onPressed: () => nav.push('CL-MSGS-01'),
    ),
  ];
}

/// One lead card: a drawing, a title and one verb (a quieter second verb when offered).
class WdLeadCard extends StatelessWidget {
  const WdLeadCard({
    super.key,
    required this.illustration,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.fact,
  });

  final GzIllustrationName illustration;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// One fact under the title (the day the voucher lapses).
  final (IconData, String)? fact;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: c.borderHairline, width: GzStroke.hair),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
        child: WdGap(
          children: [
            Row(
              children: [
                GzIllustration(illustration, size: GzIllustrationSize.md),
                const SizedBox(width: GzSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GzText(title, role: GzTextRole.d1, color: c.textStrong, maxLines: 2, header: true),
                      if (fact != null) ...[
                        const SizedBox(height: GzSpace.s2),
                        GzFactChip(icon: fact!.$1, label: fact!.$2, value: fact!.$2, small: true, tone: GzFactTone.muted),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            GzButton(variant: GzButtonVariant.primary, fullWidth: true, onPressed: onAction, label: actionLabel),
            if (secondaryLabel != null) GzButton(variant: GzButtonVariant.tertiary, fullWidth: true, onPressed: onSecondary, label: secondaryLabel!),
          ],
        ),
      ),
    );
  }
}

/// One tool tile: a glyph, one word and a figure.
class WdToolTile extends StatelessWidget {
  const WdToolTile({super.key, required this.icon, required this.label, this.value, this.share, required this.onPressed});

  final IconData icon;
  final String label;
  final String? value;
  final double? share;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: value == null ? label : '$label $value',
      builder: (context, st) => DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderHairline, width: GzStroke.hair),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GzIcon(icon, size: GzIconSize.md, color: c.iconSecondary),
              const SizedBox(height: GzSpace.s3),
              GzText(label, role: GzTextRole.caption, color: c.textSecondary),
              if (value != null) ...[const SizedBox(height: GzSpace.s1), GzText(value!, role: GzTextRole.price, color: c.textStrong, figures: true)],
              if (share != null) ...[
                const SizedBox(height: GzSpace.s2),
                Semantics(
                  label: label,
                  value: value,
                  child: ExcludeSemantics(child: WdMeter(share: share!.clamp(0.0, 1.0))),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The gold share of a tool tile (the checklist line, the budget bar): a 4 dp pill over the quiet track.
class WdMeter extends StatelessWidget {
  const WdMeter({super.key, required this.share});

  final double share;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return SizedBox(
      height: GzStroke.threadMax,
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.controlTrack, borderRadius: GzRadius.pillAll),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: share,
            child: DecoratedBox(
              decoration: BoxDecoration(color: context.gz.colors.markKhayt, borderRadius: GzRadius.pillAll),
              child: const SizedBox(height: GzStroke.threadMax),
            ),
          ),
        ),
      ),
    );
  }
}

/// The planner offer: the kosha drawing, one secondary action and the dismiss glyph. Dismissed for the session.
class WdPlannerOffer extends StatefulWidget {
  const WdPlannerOffer({super.key});

  @override
  State<WdPlannerOffer> createState() => _WdPlannerOfferState();
}

class _WdPlannerOfferState extends State<WdPlannerOffer> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final l = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GzIllustration(GzIllustrationName.kosha, size: GzIllustrationSize.md),
        const SizedBox(width: GzSpace.s4),
        Expanded(
          child: GzButton(
            variant: GzButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => context.gzNav.push('CL-PLAN-01'),
            label: l.clientMyWeddingPlannerOfferAction,
          ),
        ),
        const SizedBox(width: GzSpace.s2),
        GzIconButton(
          icon: GzIcons.close,
          iconSize: GzIconSize.sm,
          label: l.clientMyWeddingPlannerDismiss,
          onPressed: () => setState(() => _dismissed = true),
        ),
      ],
    );
  }
}

class WdHubSkeleton extends StatelessWidget {
  const WdHubSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const WdPad(
      child: WdGap(children: [GzSkeleton(blockSize: 220), GzSkeleton(blockSize: 64), GzSkeleton(blockSize: 64), GzSkeleton(blockSize: 120)]),
    );
  }
}
