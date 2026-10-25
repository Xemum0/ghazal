// The pieces of the More root (web `MoreParts.tsx`; text diet, ADR 0034): the listing card (monogram, name, status, language completeness as two
// threads or the listing counts, the billing and preview rows), the venue tiles (glyph, count, one word) and a ruled group of icon rows.
// No sentence is on the screen: counts, dates and glyphs say it, the long form is the accessible name.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/settings_model.dart';

enum CardState { live, review, draft }

/// One language of the completeness line: its script glyph, a thread filled to the share, the figure.
class CompletenessBar extends StatelessWidget {
  const CompletenessBar({required this.glyph, required this.arabic, required this.label, required this.pct, super.key});

  final String glyph;
  final bool arabic;
  final String label;
  final int pct;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    return Semantics(
      container: true,
      label: '$label ${f.plain(f.percent(pct))}',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.iconMd),
          child: Row(
            children: [
              Container(
                width: GzSize.pillMin,
                height: GzSize.pillMin,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
                child: Directionality(
                  textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
                  child: GzText(glyph, role: GzTextRole.caption, color: c.textStrong),
                ),
              ),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: ClipRRect(
                  borderRadius: GzRadius.pillAll,
                  child: SizedBox(
                    height: GzStroke.thread,
                    child: Row(
                      children: [
                        if (pct > 0) Expanded(flex: pct, child: ColoredBox(color: c.markKhayt, child: const SizedBox.expand())),
                        if (pct < 100) Expanded(flex: 100 - pct, child: ColoredBox(color: c.markTrack, child: const SizedBox.expand())),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: GzSpace.s3),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: GzSpace.s12),
                child: GzText(f.percent(pct), role: GzTextRole.figBodyS, textAlign: TextAlign.end),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The plan as one fact: the crown of a major hotel, the contract, or the end date of the plan.
class BillingFact extends StatelessWidget {
  const BillingFact({required this.billing, super.key});

  final Billing billing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final date = billing.endsOn == null ? '' : f.date(billing.endsOn.toString(), DateStyle.dayMonth);
    return switch (billing.status) {
      BillingStatus.exempt => GzFactChip(icon: GzIcons.crown, tone: GzFactTone.accent, label: l.hotelSettingsBillExempt),
      BillingStatus.contract => GzFactChip(icon: GzIcons.notes, label: l.commonBillingContract),
      BillingStatus.active => GzFactChip(icon: GzIcons.calendar, label: l.hotelSettingsBillEnds, value: date),
      BillingStatus.expiring => GzFactChip(icon: GzIcons.timer, tone: GzFactTone.accent, label: l.hotelSettingsBillEnds, value: date),
      BillingStatus.expired => GzFactChip(icon: GzIcons.clockOff, tone: GzFactTone.muted, label: l.hotelSettingsBillEnded, value: date),
      BillingStatus.none => const SizedBox.shrink(),
    };
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.children, this.onPressed, this.label});

  final List<Widget> children;
  final VoidCallback? onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final body = Container(
      constraints: const BoxConstraints(minHeight: GzSize.controlLg),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
      child: Row(children: children),
    );
    if (onPressed == null) return body;
    return GzPressable(onPressed: onPressed, semanticLabel: label, minHeight: GzSize.controlLg, scale: 1, child: body);
  }
}

class ListingCard extends StatelessWidget {
  const ListingCard({
    required this.name,
    required this.state,
    this.completeness,
    this.listings,
    this.billing,
    this.onBilling,
    this.onPreview,
    this.attention = false,
    super.key,
  });

  final String name;
  final CardState state;
  final ({int ar, int en})? completeness;
  final ({int live, int review})? listings;
  final Billing? billing;
  final VoidCallback? onBilling;
  final VoidCallback? onPreview;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final gzl = context.gzL10n;
    final f = context.gzFormat;
    final held = state != CardState.live;
    final status = switch (state) {
      CardState.live => GzStatus.listingActive,
      CardState.review => GzStatus.listingReview,
      CardState.draft => GzStatus.listingDraft,
    };
    return Semantics(
      container: true,
      label: l.hotelSettingsMoreListing,
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(GzSpace.s4),
              child: Row(
                children: [
                  ExcludeSemantics(child: GzAvatar(name: name, size: GzAvatarSize.sm, voice: GzAvatarVoice.sans)),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(child: GzUserText(name, role: GzTextRole.d1, color: c.textStrong)),
                  const SizedBox(width: GzSpace.s3),
                  GzStatusPill(status: status),
                ],
              ),
            ),
            if (completeness != null)
              _Block(
                label: l.hotelSettingsMoreCompleteness,
                children: [
                  CompletenessBar(glyph: 'ع', arabic: true, label: l.hotelSettingsMoreLangAr, pct: completeness!.ar),
                  const SizedBox(height: GzSpace.s2),
                  CompletenessBar(glyph: 'En', arabic: false, label: l.hotelSettingsMoreLangEn, pct: completeness!.en),
                ],
              )
            else if (listings != null)
              _Block(
                label: l.hotelSettingsMoreListings,
                children: [
                  Wrap(
                    spacing: GzSpace.s8,
                    runSpacing: GzSpace.s2,
                    children: [
                      GzIconStat(icon: GzIcons.megaphone, label: gzl.commonListingStatusActive, value: f.integer(listings!.live), layout: GzFactLayout.inline, accent: true),
                      GzIconStat(icon: GzIcons.clock, label: gzl.commonListingStatusReview, value: f.integer(listings!.review), layout: GzFactLayout.inline),
                    ],
                  ),
                ],
              ),
            if (billing != null)
              _CardRow(
                onPressed: onBilling,
                label: l.hotelSettingsMoreBilling,
                children: [
                  const GzIcon(GzIcons.receipt, size: GzIconSize.sm),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(child: GzText(l.hotelSettingsMoreBilling, role: GzTextRole.title, color: c.textStrong)),
                  BillingFact(billing: billing!),
                  if (attention) ...[
                    const SizedBox(width: GzSpace.s3),
                    Semantics(
                      label: l.hotelSettingsMoreBillingAttention,
                      child: Container(width: GzSpace.s2, height: GzSpace.s2, decoration: BoxDecoration(shape: BoxShape.circle, color: c.textDanger)),
                    ),
                  ],
                  if (onBilling != null) ...[const SizedBox(width: GzSpace.s3), GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary, mirror: true)],
                ],
              ),
            _CardRow(
              onPressed: held ? null : onPreview,
              label: held ? '${l.hotelSettingsMorePreview}. ${l.hotelSettingsMorePreviewHeld}' : l.hotelSettingsMorePreview,
              children: [
                GzIcon(GzIcons.eye, size: GzIconSize.sm, color: held ? c.iconDisabled : c.iconSecondary),
                const SizedBox(width: GzSpace.s3),
                Expanded(child: GzText(l.hotelSettingsMorePreview, role: GzTextRole.title, color: held ? c.textDisabled : c.textStrong)),
                if (!held) GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary, mirror: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.all(GzSpace.s4),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}

// ------------------------------------------------------------------------------------------------ tiles and groups

typedef MoreTile = ({String id, IconData icon, String title, int? count, VoidCallback onPress});

/// Three tiles to a row, equal at 360, 390 and 430 (the width is computed from the gutter and gap tokens).
class VenueTiles extends StatelessWidget {
  const VenueTiles({required this.title, required this.tiles, super.key});

  final String title;
  final List<MoreTile> tiles;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) return const SizedBox.shrink();
    final c = context.gz.colors;
    final f = context.gzFormat;
    return Semantics(
      container: true,
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
            child: GzSectionHeader(title: title, voice: GzHeaderVoice.partner),
          ),
          const SizedBox(height: GzSpace.s2),
          LayoutBuilder(
            builder: (context, box) {
              final size = ((box.maxWidth - 2 * GzSpace.gutter - 2 * GzSpace.s3) / 3).floorToDouble();
              return Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
                child: Wrap(
                  spacing: GzSpace.s3,
                  runSpacing: GzSpace.s3,
                  children: [
                    for (final t in tiles)
                      SizedBox(
                        width: size,
                        child: GzPressable(
                          onPressed: t.onPress,
                          semanticLabel: t.count == null ? t.title : '${t.title} ${f.integer(t.count!)}',
                          borderRadius: GzRadius.mdAll,
                          scale: 1,
                          child: Container(
                            constraints: const BoxConstraints(minHeight: GzSpace.s24),
                            padding: const EdgeInsets.all(GzSpace.s3),
                            decoration: BoxDecoration(
                              color: c.surfaceRaised,
                              borderRadius: GzRadius.mdAll,
                              border: Border.all(color: c.borderStrong, width: GzStroke.hair),
                            ),
                            child: ExcludeSemantics(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      GzIcon(t.icon, size: GzIconSize.md, color: c.iconPrimary),
                                      const Spacer(),
                                      if (t.count != null) GzText(f.integer(t.count!), role: GzTextRole.figBodyS, color: c.textSecondary),
                                    ],
                                  ),
                                  const SizedBox(height: GzSpace.s3),
                                  GzText(t.title, role: GzTextRole.bodyS, color: c.textStrong),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

typedef MoreRow = ({String id, IconData icon, String title, Widget? trailing, VoidCallback? onPress, bool danger, bool chevron});

MoreRow moreRow(String id, IconData icon, String title, {Widget? trailing, VoidCallback? onPress, bool danger = false, bool? chevron}) =>
    (id: id, icon: icon, title: title, trailing: trailing, onPress: onPress, danger: danger, chevron: chevron ?? onPress != null);

class MoreGroup extends StatelessWidget {
  const MoreGroup({required this.rows, this.title, super.key});

  final String? title;
  final List<MoreRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
              child: GzSectionHeader(title: title!, voice: GzHeaderVoice.partner),
            ),
            const SizedBox(height: GzSpace.s2),
          ],
          for (var i = 0; i < rows.length; i++)
            GzIconListRow(
              key: ValueKey<String>('more.${rows[i].id}'),
              title: rows[i].title,
              icon: rows[i].icon,
              trailing: rows[i].trailing,
              chevron: rows[i].chevron,
              onPressed: rows[i].onPress,
              tone: rows[i].danger ? GzListRowTone.danger : GzListRowTone.normal,
              flush: true,
              last: i == rows.length - 1,
            ),
        ],
      ),
    );
  }
}
