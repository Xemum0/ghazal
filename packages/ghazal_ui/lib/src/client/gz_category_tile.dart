/// CategoryTile (Home quick categories, ADR 0018 B12): a 4:5 photograph, radius 12, with a single-purpose bottom scrim and the category
/// name in canvas text; never a coloured chip, never an icon grid. Port of design/src/system/domain-client/CategoryTile.tsx.
///
/// An optional count caption ("12 halls") sits under the name. [GzCategoryTilePlacement.under] moves the name below the plate (the
/// wall-label form) where a scrim would be too much. States: default, pressed, focus, selected (ink ring and check), no photo (branded
/// tint), loading.
library;

import 'package:flutter/widgets.dart';

import '../brand/brand.dart';
import '../core/core.dart';
import '../foundation.dart';
import '../overlays/overlays.dart';
import 'client_a_kit.dart';

enum GzCategoryTilePlacement { over, under }

class GzCategoryTile extends StatelessWidget {
  const GzCategoryTile({
    required this.label,
    this.image,
    this.caption,
    this.placement = GzCategoryTilePlacement.over,
    this.selected = false,
    this.onOpen,
    this.loading = false,
    this.previewState,
    super.key,
  });

  /// The category name, already in the current language.
  final String label;

  /// The photograph descriptor (`ImageRef` base URL or file); null shows the branded empty frame.
  final String? image;

  /// A small caption under the name ("12 halls"), already formatted.
  final String? caption;
  final GzCategoryTilePlacement placement;
  final bool selected;
  final VoidCallback? onOpen;
  final bool loading;

  /// Gallery only: show the pressed look without a pointer.
  final GzPreviewState? previewState;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final under = placement == GzCategoryTilePlacement.under;
    final plateShape = GzRadius.mdAll;
    if (loading) {
      return Semantics(
        container: true,
        label: context.gzL10n.commonStateLoading,
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: GzLayout.aspect4x5,
                child: DecoratedBox(decoration: BoxDecoration(color: c.surfacePlaceholder, borderRadius: plateShape)),
              ),
              if (under) ...[
                const SizedBox(height: GzSpace.s2),
                const Align(alignment: AlignmentDirectional.centerStart, child: GzSkeleton(inlineSize: 96, blockSize: 20)),
              ],
            ],
          ),
        ),
      );
    }
    final Widget photo = image != null
        ? ExcludeSemantics(child: GzPhoto(src: image!))
        : ColoredBox(color: c.surfaceTintSoft, child: const Center(child: GzMonogram(size: GzMonogramSize.sm)));
    final plate = AspectRatio(
      aspectRatio: GzLayout.aspect4x5,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: plateShape,
            child: ColoredBox(
              color: c.surfacePlaceholder,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  photo,
                  if (!under)
                    PositionedDirectional(
                      start: 0,
                      end: 0,
                      bottom: 0,
                      child: _Scrim(label: label, caption: caption),
                    ),
                  if (selected)
                    PositionedDirectional(
                      top: GzSpace.s2,
                      end: GzSpace.s2,
                      child: ExcludeSemantics(
                        child: DecoratedBox(
                          decoration: BoxDecoration(shape: BoxShape.circle, color: c.controlToggleOn),
                          child: SizedBox.square(dimension: GzSize.iconMd, child: Center(child: GzIcon(GzIcons.check, size: GzIconSize.xs, color: c.controlToggleKnob))),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (selected)
            PositionedDirectional(
              start: -(GzStroke.thread + GzStroke.focusOffset),
              end: -(GzStroke.thread + GzStroke.focusOffset),
              top: -(GzStroke.thread + GzStroke.focusOffset),
              bottom: -(GzStroke.thread + GzStroke.focusOffset),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: c.surfaceDark, width: GzStroke.thread),
                    borderRadius: BorderRadius.circular(GzRadius.md + GzStroke.thread + GzStroke.focusOffset),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        plate,
        if (under) ...[
          const SizedBox(height: GzSpace.s2),
          GzText(label, role: GzTextRole.title, color: c.textStrong),
          if (caption != null) ...[
            const SizedBox(height: GzStroke.hair),
            GzText(caption!, role: GzTextRole.caption, color: c.textPrimary),
          ],
        ],
      ],
    );
    final pressed = previewState == GzPreviewState.pressed;
    return RepaintBoundary(
      child: gzPressedPreview(
        pressed,
        GzPressable(onPressed: onOpen, semanticLabel: label, selected: selected ? true : null, borderRadius: plateShape, minHeight: 0, minWidth: 0, child: body),
      ),
    );
  }
}

/// The name and caption over the photograph: the 0.72 scrim fades in over the 40 above the text and is solid under it (stops in dp,
/// not percent), so name and caption stay 4.5:1 on the brightest ivory hall.
class _Scrim extends StatelessWidget {
  const _Scrim({required this.label, required this.caption});

  final String label;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: GzSpace.s10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.scrimClear, c.scrimBottom]),
              ),
            ),
          ),
          ColoredBox(
            color: c.scrimBottom,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.s3, end: GzSpace.s3, bottom: GzSpace.s3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GzText(label, role: GzTextRole.title, color: c.textOnDark),
                  if (caption != null) ...[
                    const SizedBox(height: GzSpace.s1),
                    GzText(caption!, role: GzTextRole.caption, color: c.textOnDark),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
