import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart' show Package, PlannerPackage, ServiceProvider, VenueDayState, VenueResult, VenueSummary;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import 'saved_parts.dart';

/// The one row language of the Saved tab (CL-SAVD-01): a 72 x 88 thumbnail, the serif name, one quiet meta line, the price line and, at the
/// end, the heart (or a selection mark at the start in select mode). Unframed, a hairline under every row but the last; the thumbnail and
/// text are the target (the heart sits beside it, never under it). Flow-local: the system compact card has no availability glyph, no
/// selection mode and no unlisted state (requests.md).
class SavedRow extends StatelessWidget {
  const SavedRow({
    required this.thumb,
    required this.body,
    required this.openLabel,
    this.aside,
    this.selecting = false,
    this.selected = false,
    this.onOpen,
    this.last = false,
    super.key,
  });

  final Widget thumb;
  final Widget body;
  final Widget? aside;
  final bool selecting;
  final bool selected;
  final String openLabel;
  final VoidCallback? onOpen;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final open = GzPressable(
      onPressed: onOpen,
      semanticLabel: openLabel,
      selected: selecting ? selected : null,
      minHeight: 0,
      minWidth: 0,
      borderRadius: GzRadius.smAll,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selecting) ...[ExcludeSemantics(child: _Mark(on: selected)), const SizedBox(width: GzSpace.s4)],
          ExcludeSemantics(child: thumb),
          const SizedBox(width: GzSpace.s4),
          Expanded(child: ExcludeSemantics(child: body)),
        ],
      ),
    );
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(
                  bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: open),
              if (aside != null && !selecting) ...[const SizedBox(width: GzSpace.s4), aside!],
            ],
          ),
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: (GzSize.thumbCompactHeight - GzSize.iconMd) / 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: GzRadius.xsAll,
          color: on ? c.controlToggleOn : c.controlBg,
          border: Border.all(color: on ? c.controlToggleOn : c.borderControl, width: GzStroke.icon),
        ),
        child: SizedBox.square(
          dimension: GzSize.iconMd,
          child: on
              ? Center(
                  child: GzIcon(GzIcons.check, size: GzIconSize.xs, color: c.controlToggleKnob),
                )
              : null,
        ),
      ),
    );
  }
}

Widget _name(BuildContext context, String name, {bool muted = false}) {
  final c = context.gz.colors;
  return GzText(name, role: GzTextRole.d1, color: muted ? c.textSecondary : c.textStrong, maxLines: 2);
}

/// A hall of the Saved tab.
class SavedVenueRow extends StatelessWidget {
  const SavedVenueRow({
    required this.row,
    required this.area,
    required this.hasDate,
    this.dateText,
    this.savingChanged = false,
    this.voucherId,
    this.onOpenVoucher,
    this.unlisted = false,
    this.selecting = false,
    this.selected = false,
    this.onOpen,
    this.onRemove,
    this.last = false,
    super.key,
  });

  final VenueResult row;
  final String? area;
  final bool hasDate;

  /// The Brief date as the card says it ("14 Jan"), for the accessible sentence of the availability glyph.
  final String? dateText;
  final bool savingChanged;
  final String? voucherId;
  final VoidCallback? onOpenVoucher;
  final bool unlisted;
  final bool selecting;
  final bool selected;
  final VoidCallback? onOpen;
  final VoidCallback? onRemove;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final VenueSummary v = row.venue;
    final name = v.name.of(lang);
    if (unlisted) {
      return SavedRow(
        last: last,
        thumb: ClipRRect(
          borderRadius: GzRadius.smAll,
          child: SizedBox(
            width: GzSize.thumbCompactWidth,
            height: GzSize.thumbCompactHeight,
            child: ColoredBox(
              color: c.surfaceTintSoft,
              child: const Center(child: GzMonogram(size: GzMonogramSize.sm)),
            ),
          ),
        ),
        openLabel: name,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _name(context, name, muted: true),
            const SizedBox(height: GzSpace.s1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzIcon(GzIcons.eyeOff, size: GzIconSize.xs, color: c.iconSecondary),
                const SizedBox(width: GzSpace.s2),
                GzText(l.clientSavedCompareSavedUnlisted, role: GzTextRole.caption, color: c.textSecondary),
              ],
            ),
          ],
        ),
        aside: GzButton(label: context.gzL10n.commonActionRemove, variant: GzButtonVariant.tertiary, onPressed: onRemove),
      );
    }
    final avail = row.availability;
    final showAvail = hasDate && avail != null && avail != VenueDayState.unknown && avail != VenueDayState.closed;
    final status = avail == VenueDayState.available ? GzStatus.available : (avail == VenueDayState.held ? GzStatus.held : GzStatus.unavailable);
    final date = dateText;
    String availName() => switch (avail) {
      VenueDayState.available => l.clientSavedCompareSavedAvailFree(date ?? ''),
      VenueDayState.held => l.clientSavedCompareSavedAvailHeld,
      _ => l.clientSavedCompareSavedAvailBooked(date ?? ''),
    };
    return SavedRow(
      key: ValueKey<String>('saved.row.${v.id}'),
      last: last,
      selecting: selecting,
      selected: selected,
      onOpen: onOpen,
      openLabel: selecting ? (selected ? l.clientSavedCompareSavedDeselectRow(name) : l.clientSavedCompareSavedSelectRow(name)) : name,
      thumb: SavedThumb(venue: v),
      aside: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GzIconButton(
            key: ValueKey<String>('saved.heart.${v.id}'),
            icon: GzIcons.heart,
            iconActive: GzIcons.heartFill,
            active: true,
            label: context.gzL10n.commonA11yFavouriteRemove,
            onPressed: onRemove,
          ),
          if (voucherId != null)
            GzPressable(
              key: ValueKey<String>('saved.voucher.${v.id}'),
              onPressed: onOpenVoucher,
              semanticLabel: l.clientSavedCompareSavedVoucherReadyOpen(name),
              borderRadius: GzRadius.pillAll,
              child: const GzStatusIcon(status: GzStatus.voucherActive),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _name(context, name),
          const SizedBox(height: GzSpace.s1),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: GzSpace.s2,
            children: [
              if (area != null) GzText(area!, role: GzTextRole.caption, color: c.textSecondary),
              if (showAvail) GzStatusIcon(status: status, label: availName()),
              if (savingChanged)
                GzFactChip(icon: GzIcons.trendDown, tone: GzFactTone.accent, small: true, label: l.clientSavedCompareSavedSavingChanged),
            ],
          ),
          if (row.price != null) ...[const SizedBox(height: GzSpace.s1), GzCardPriceLine(price: row.price!)],
        ],
      ),
    );
  }
}

/// A service provider of the Saved tab.
class SavedVendorRow extends StatelessWidget {
  const SavedVendorRow({required this.vendor, required this.area, this.onOpen, this.onRemove, this.last = false, super.key});

  final ServiceProvider vendor;
  final String? area;
  final VoidCallback? onOpen;
  final VoidCallback? onRemove;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lg = context.gzL10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final f = context.gzFormat;
    final name = vendor.name.of(lang);
    final shot = vendor.portfolio.isEmpty ? null : vendor.portfolio.first;
    // Two prices on the same basis; a voucher is only sold when the saving beats the fee, so a small saving shows the standard price alone.
    final voucher = vendor.fromVoucher != null && vendor.fromVoucher!.fils < vendor.from.fils ? vendor.fromVoucher : null;
    final saving = voucher == null ? 0 : vendor.from.fils - voucher.fils;
    final showVoucher = voucher != null;
    final rating = vendor.rating;
    return SavedRow(
      key: ValueKey<String>('saved.row.${vendor.id}'),
      last: last,
      onOpen: onOpen,
      openLabel: name,
      thumb: SavedThumb(image: shot),
      aside: GzIconButton(
        key: ValueKey<String>('saved.heart.${vendor.id}'),
        icon: GzIcons.heart,
        iconActive: GzIcons.heartFill,
        active: true,
        label: lg.commonA11yFavouriteRemove,
        onPressed: onRemove,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _name(context, name),
          const SizedBox(height: GzSpace.s1),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: GzSpace.s2,
            children: [
              if (area != null) GzText(area!, role: GzTextRole.caption, color: c.textSecondary),
              if (rating != null)
                GzRating(value: rating.average, count: rating.count)
              else
                GzText(lg.commonLabelNew, role: GzTextRole.caption, color: c.textSecondary),
            ],
          ),
          const SizedBox(height: GzSpace.s1),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: GzSpace.s2,
            children: [
              GzPrice(
                fils: showVoucher ? voucher.fils : vendor.from.fils,
                size: GzPriceSize.card,
                prefix: l.clientSavedCompareSavedFrom,
                was: showVoucher ? vendor.from.fils : null,
              ),
              GzText(vendor.fromUnit.of(lang), role: GzTextRole.caption, color: c.textSecondary),
              if (showVoucher)
                _SavingChip(
                  label: lg.commonSaveAmount(f.money(saving, const MoneyOptions(mode: MoneyMode.browse))),
                  text: f.money(saving, const MoneyOptions(mode: MoneyMode.browse)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavingChip extends StatelessWidget {
  const _SavingChip({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.statusSuccessBg, borderRadius: GzRadius.xsAll),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2, vertical: GzSpace.s1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzText(text, role: GzTextRole.pill, color: c.statusSuccessText, figures: true),
                const SizedBox(width: GzSpace.s1),
                GzIcon(GzIcons.trendDown, size: GzIconSize.xs, color: c.statusSuccessText, mirror: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A saved hall package (the hall's cover, the package and hall names, both prices).
class SavedHallPackageRow extends StatelessWidget {
  const SavedHallPackageRow({required this.pkg, required this.venue, this.onOpen, this.onRemove, this.last = false, super.key});

  final Package pkg;
  final VenueSummary venue;
  final VoidCallback? onOpen;
  final VoidCallback? onRemove;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final name = pkg.name.of(lang);
    return SavedRow(
      key: ValueKey<String>('saved.row.${pkg.id}'),
      last: last,
      onOpen: onOpen,
      openLabel: name,
      thumb: SavedThumb(venue: venue),
      aside: GzIconButton(
        key: ValueKey<String>('saved.heart.${pkg.id}'),
        icon: GzIcons.heart,
        iconActive: GzIcons.heartFill,
        active: true,
        label: context.gzL10n.commonA11yFavouriteRemove,
        onPressed: onRemove,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _name(context, name),
          const SizedBox(height: GzSpace.s1),
          GzText(venue.name.of(lang), role: GzTextRole.caption, color: c.textSecondary),
          const SizedBox(height: GzSpace.s1),
          GzPriceCompare(
            standard: pkg.standardFils,
            voucher: pkg.voucherFils,
            structure: pkg.priceStructure,
            variant: GzPriceCompareVariant.inline,
            showNet: false,
          ),
        ],
      ),
    );
  }
}

/// A saved planner tier (its photograph, the tier name with its marks and the from price).
class SavedPlannerRow extends StatelessWidget {
  const SavedPlannerRow({required this.pkg, this.onOpen, this.onRemove, this.last = false, super.key});

  final PlannerPackage pkg;
  final VoidCallback? onOpen;
  final VoidCallback? onRemove;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final name = pkg.name.of(lang);
    return SavedRow(
      key: ValueKey<String>('saved.row.${pkg.id}'),
      last: last,
      onOpen: onOpen,
      openLabel: name,
      thumb: SavedThumb(image: pkg.image),
      aside: GzIconButton(
        key: ValueKey<String>('saved.heart.${pkg.id}'),
        icon: GzIcons.heart,
        iconActive: GzIcons.heartFill,
        active: true,
        label: context.gzL10n.commonA11yFavouriteRemove,
        onPressed: onRemove,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _name(context, name),
          const SizedBox(height: GzSpace.s1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GzText(l.clientSavedCompareSavedPlannerLabel, role: GzTextRole.caption, color: c.textSecondary),
              const SizedBox(width: GzSpace.s2),
              for (var i = 0; i < pkg.marks; i++) ...[if (i > 0) const SizedBox(width: GzSpace.s1), const GzThreadBead()],
            ],
          ),
          const SizedBox(height: GzSpace.s1),
          GzPrice(fils: pkg.from.fils, size: GzPriceSize.card, prefix: l.clientSavedCompareSavedFrom),
        ],
      ),
    );
  }
}

/// The loading rows: static shapes in the row's measure.
class SavedRowsSkeleton extends StatelessWidget {
  const SavedRowsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.gzL10n.commonStateLoading,
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (var i = 0; i < 4; i++)
              const Padding(
                padding: EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GzSkeleton(variant: GzSkeletonVariant.block, inlineSize: GzSize.thumbCompactWidth, blockSize: GzSize.thumbCompactHeight),
                    SizedBox(width: GzSpace.s4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GzSkeleton(inlineSize: 160, blockSize: 28),
                        SizedBox(height: GzSpace.s1),
                        GzSkeleton(inlineSize: 96, blockSize: 20),
                        SizedBox(height: GzSpace.s1),
                        GzSkeleton(inlineSize: 176, blockSize: 24),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
