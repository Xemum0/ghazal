import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Area, ServiceProvider;

import '../core/core.dart';
import '../foundation.dart';
import '../overlays/gz_photo.dart';
import 'client_bits.dart' show GzBaselineWrap;
import 'gz_service_tile.dart' show gzImageSrc;

enum GzVendorVariant { card, row }

enum GzVendorAudience { member, guest }

/// VendorCard (CA-SVC): a supplier, a portfolio strip, a monogram, the name, a rating or "New", the area, the from price with its unit,
/// plain facts and the verified mark. [GzVendorVariant.row] is the list form (no strip, no facts). A [GzVendorAudience.guest] sees
/// the standard price and the locked-voucher line (ADR 0007 D8). The whole card is one button; the save heart sits above it.
/// The area name comes from the caller ([area]): the widget never looks anything up.
class GzVendorCard extends StatelessWidget {
  const GzVendorCard({
    required this.vendor,
    this.area,
    this.audience = GzVendorAudience.member,
    this.favourite = false,
    this.onFavouriteChange,
    this.onOpen,
    this.variant = GzVendorVariant.card,
    this.loading = false,
    this.previewState,
    super.key,
  });

  final ServiceProvider vendor;
  final Area? area;
  final GzVendorAudience audience;
  final bool favourite;
  final ValueChanged<bool>? onFavouriteChange;
  final VoidCallback? onOpen;
  final GzVendorVariant variant;
  final bool loading;
  final GzPreviewState? previewState;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final lang = gz.locale.languageCode;
    if (loading) {
      return Semantics(
        container: true,
        label: l.commonStateLoading,
        child: _panel(
          context,
          const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 96),
              SizedBox(height: GzSpace.s3),
              GzSkeleton(inlineSize: 180, blockSize: 24),
              SizedBox(height: GzSpace.s3),
              GzSkeleton(inlineSize: 120, blockSize: 20),
            ],
          ),
        ),
      );
    }
    final name = vendor.name.of(lang);
    final row = variant == GzVendorVariant.row;
    final voucher = audience == GzVendorAudience.member ? vendor.fromVoucher : null;
    final locked = audience == GzVendorAudience.guest && vendor.fromVoucher != null;
    final rating = vendor.rating;
    final average = rating?.average;
    final head = Row(
      children: [
        GzAvatar(name: name, initial: gz.isAr ? vendor.monogram : null, size: GzAvatarSize.sm),
        const SizedBox(width: GzSpace.s3),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GzText(name, role: GzTextRole.d1, color: c.textStrong, maxLines: 2, header: true),
              const SizedBox(height: GzStroke.thread),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: GzSpace.s3,
                runSpacing: GzSpace.s1,
                children: [
                  if (area != null) GzText(area!.name.of(lang), role: GzTextRole.bodyS, color: c.textSecondary),
                  if (vendor.verified)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GzIcon(GzIcons.verified, size: GzIconSize.xs, color: c.iconSuccess),
                        const SizedBox(width: GzSpace.s1),
                        GzText(l.uiClientVendorVerified, role: GzTextRole.bodyS, color: c.textSuccess),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: GzSpace.s3),
        if (average != null) GzRating(value: average, count: rating!.count) else GzText(l.commonLabelNew, role: GzTextRole.bodyS, color: c.textSecondary),
      ],
    );
    final price = GzBaselineWrap(
      spacing: GzSpace.s2,
      runSpacing: GzSpace.s2,
      children: [
        GzPrice(fils: (voucher ?? vendor.from).fils, size: GzPriceSize.card, prefix: l.uiSharedFrom, was: voucher != null ? vendor.from.fils : null),
        GzText(vendor.fromUnit.of(lang), role: GzTextRole.caption, color: c.textSecondary),
        if (locked)
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                GzIcon(GzIcons.lock, size: GzIconSize.xs, color: c.iconSecondary),
                const SizedBox(width: GzSpace.s1),
                Flexible(child: GzText(l.uiSharedLockedVoucher, role: GzTextRole.caption, color: c.textSecondary)),
              ],
            ),
          ),
      ],
    );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!row) ...[
          Row(
            children: [
              for (final (i, img) in vendor.portfolio.take(3).indexed) ...[
                if (i > 0) const SizedBox(width: GzSpace.s1),
                Expanded(child: GzPhoto(src: gzImageSrc(img.file, img.baseUrl), alt: img.alt.of(lang), aspectRatio: GzLayout.aspect4x3, borderRadius: GzRadius.smAll)),
              ],
            ],
          ),
          const SizedBox(height: GzSpace.s3),
        ],
        head,
        const SizedBox(height: GzSpace.s3),
        Align(alignment: AlignmentDirectional.centerStart, child: price),
        if (!row) ...[
          if (vendor.femaleTeamForLadies) ...[
            const SizedBox(height: GzSpace.s3),
            Align(alignment: AlignmentDirectional.centerStart, child: GzTag(label: l.uiClientVendorFemaleTeam, icon: GzIcons.checkCircle)),
          ],
          const SizedBox(height: GzSpace.s3),
          Row(
            children: [
              GzIcon(GzIcons.clock, size: GzIconSize.xs, color: c.iconSecondary),
              const SizedBox(width: GzSpace.s1),
              Flexible(
                child: GzText(l.uiClientVendorReplies(l.commonCountHours(vendor.usuallyRepliesHours.round())), role: GzTextRole.caption, color: c.textSecondary, figures: true),
              ),
            ],
          ),
        ],
      ],
    );
    final pressedPreview = previewState == GzPreviewState.pressed;
    Widget card;
    if (pressedPreview) {
      card = Transform.scale(scale: GzMotion.scalePress, child: _panel(context, content, fill: c.surfaceQuiet));
    } else {
      card = GzPressable(
        onPressed: onOpen,
        semanticLabel: name,
        borderRadius: GzRadius.mdAll,
        minHeight: 0,
        minWidth: 0,
        builder: (context, st) => _panel(context, content, fill: st.pressed ? c.surfaceQuiet : null),
      );
    }
    return RepaintBoundary(
      child: Stack(
        children: [
          card,
          if (onFavouriteChange != null)
            PositionedDirectional(
              top: row ? GzSpace.s1 : GzSpace.s5,
              end: row ? GzSpace.s1 : GzSpace.s5,
              child: GzIconButton(
                variant: row ? GzIconButtonVariant.plain : GzIconButtonVariant.overImage,
                icon: GzIcons.heart,
                iconActive: GzIcons.heartFill,
                active: favourite,
                label: favourite ? l.commonA11yFavouriteRemove : l.commonA11yFavouriteAdd,
                onPressed: () => onFavouriteChange!(!favourite),
              ),
            ),
        ],
      ),
    );
  }

  Widget _panel(BuildContext context, Widget child, {Color? fill}) {
    final c = context.gz.colors;
    return Container(
      padding: const EdgeInsets.all(GzSpace.panelPad),
      decoration: BoxDecoration(color: fill ?? c.surfaceRaised, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
      child: child,
    );
  }
}
