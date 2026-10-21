import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show ImageRef, VenueSummary;

import '../brand/brand.dart';
import '../core/core.dart';
import '../foundation.dart';
import '../overlays/gz_photo.dart';
import 'gz_compare_parts.dart';

/// The photograph descriptor of an `ImageRef` for `GzPhoto` (`asset://...` from the mock, the served base URL otherwise).
String gzImageRefSrc(ImageRef ref) => ref.baseUrl ?? 'asset://ghazal_mock_api/images/${ref.id ?? ref.file}';

/// One column of the [GzCompareHeader]: a hall, its area name (already localised), one objective badge.
@immutable
class GzCompareHeaderColumn {
  const GzCompareHeaderColumn({required this.venue, this.areaName, this.badge, this.unlisted = false});

  final VenueSummary venue;
  final String? areaName;

  /// One objective badge: Best rated, Lowest price, Closest.
  final String? badge;

  /// The hall left the platform: the column reads "No longer listed" with Remove.
  final bool unlisted;
}

/// CompareHeader (web `CompareHeader`): 4:5 thumbnails, remove (a 24 disk in a 44 target), the serif name (2 to 4 lines, area and badge
/// bottom-aligned across the thirds), the area and one outline badge; optional tap-to-open and a pick control; collapses to 40 thumbs.
/// [pinned] is the screen's job (a pinned sliver); the widget draws the same box either way.
class GzCompareHeader extends StatelessWidget {
  const GzCompareHeader({
    required this.columns,
    this.compact = false,
    this.onOpen,
    this.pickedId,
    this.onPick,
    this.nameLines = 2,
    this.onRemove,
    this.pinned = false,
    super.key,
  }) : assert(nameLines >= 2 && nameLines <= 4);

  final List<GzCompareHeaderColumn> columns;

  /// The collapsed header (scroll-driven): thumbs shrink to 40 and the name keeps one line.
  final bool compact;

  /// Tap the photograph or the name to open the hall. Omit for a read-only header.
  final ValueChanged<String>? onOpen;

  /// The hall the couple chose (an ink check disk on its photograph; never gold). With [onPick] the disk is a control.
  final String? pickedId;
  final ValueChanged<String>? onPick;

  /// Lines of the name before it is cut: 2 (default), 3 or 4.
  final int nameLines;
  final ValueChanged<String>? onRemove;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceCanvas,
        border: Border(
          bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: GzCompareThirds(
        stretch: !compact,
        children: [for (final col in columns) _HeaderColumn(col: col, header: this)],
      ),
    );
  }
}

class _HeaderColumn extends StatelessWidget {
  const _HeaderColumn({required this.col, required this.header});

  final GzCompareHeaderColumn col;
  final GzCompareHeader header;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final lang = gz.locale.languageCode;
    final v = col.venue;
    final name = v.name.of(lang);
    final picked = header.pickedId == v.id;
    final canOpen = header.onOpen != null && !col.unlisted;
    final compact = header.compact;

    final nameText = col.unlisted ? l.uiClientCompareNoLonger : name;
    Widget nameWidget = Text(
      nameText,
      style: gz.text(GzTextRole.compareName).copyWith(color: canOpen ? c.textStrong : c.textPrimary, decoration: TextDecoration.none),
      maxLines: compact ? 1 : header.nameLines,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.start,
    );
    if (canOpen) {
      nameWidget = Semantics(
        button: true,
        label: name,
        excludeSemantics: true,
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => header.onOpen!(v.id), child: nameWidget),
      );
    }

    final thumb = _Thumb(col: col, header: header, name: name, picked: picked, size: compact ? GzSize.thumbSm : null);

    if (compact) {
      return Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3, vertical: GzSpace.s2),
        child: Row(
          children: [
            thumb,
            const SizedBox(width: GzSpace.s2),
            Expanded(child: nameWidget),
          ],
        ),
      );
    }

    final area = col.areaName;
    final badge = col.badge;
    return Padding(
      padding: const EdgeInsetsDirectional.all(GzSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          thumb,
          const SizedBox(height: GzSpace.s2),
          // The web text block is as tall as its content (the name's `flex: 1 1 auto` has no free height to take): areas of halls with
          // names of different lengths do not line up, and the column box (stretched by the row) just has room below.
          Align(
            alignment: AlignmentDirectional.topStart,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                nameWidget,
                if (area != null) ...[const SizedBox(height: GzSpace.s1), GzText(area, role: GzTextRole.caption, color: c.textSecondary)],
                if (badge != null) ...[const SizedBox(height: GzSpace.s1), _WrapBadge(label: badge)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.col, required this.header, required this.name, required this.picked, this.size});

  final GzCompareHeaderColumn col;
  final GzCompareHeader header;
  final String name;
  final bool picked;

  /// A fixed square (the collapsed header), else 4:5 over the column width.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final v = col.venue;
    final cover = v.cover;
    final compact = size != null;
    final canOpen = header.onOpen != null && !col.unlisted;
    final canPick = header.onPick != null && !col.unlisted;

    Widget disk(double d, {required Color bg, required Widget child}) => Container(
      width: d,
      height: d,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: c.scrimRingFab, spreadRadius: GzStroke.hair)],
      ),
      child: child,
    );

    final stack = Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: c.surfacePlaceholder),
        if (cover != null && !col.unlisted)
          GzPhoto(src: gzImageRefSrc(cover), alt: cover.alt.of(context.gz.locale.languageCode))
        else
          const Center(child: GzMonogram(size: GzMonogramSize.sm)),
        if (canOpen)
          Positioned.fill(
            child: GzPressable(semanticLabel: l.uiClientCompareOpen(name), onPressed: () => header.onOpen!(v.id), child: const SizedBox.expand()),
          ),
        if (!compact)
          PositionedDirectional(
            top: 0,
            end: 0,
            child: SizedBox.square(
              dimension: GzSize.touchMin,
              child: GzPressable(
                semanticLabel: l.uiClientCompareRemoveFrom(name),
                onPressed: () => header.onRemove?.call(v.id),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(GzSpace.s1),
                  child: Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: disk(
                      GzSize.iconMd,
                      bg: c.surfaceCanvas,
                      child: GzIcon(GzIcons.close, size: GzIconSize.xs, color: c.iconPrimary),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (canPick)
          PositionedDirectional(
            bottom: 0,
            end: 0,
            child: SizedBox.square(
              dimension: GzSize.touchMin,
              child: GzPressable(
                semanticLabel: picked ? l.uiClientCompareUnpick(name) : l.uiClientComparePick(name),
                selected: picked,
                onPressed: () => header.onPick!(v.id),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(GzSpace.s1),
                  child: Align(
                    alignment: AlignmentDirectional.bottomEnd,
                    child: disk(
                      GzSize.disk,
                      bg: picked ? c.surfaceDark : c.surfaceCanvas,
                      child: GzIcon(GzIcons.check, size: GzIconSize.xs, color: picked ? c.textOnDark : c.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    final clipped = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: GzRadius.xsAll,
        boxShadow: picked ? [BoxShadow(color: c.borderFocus, spreadRadius: GzStroke.focus)] : null,
      ),
      child: ClipRRect(borderRadius: GzRadius.xsAll, child: stack),
    );
    if (compact) return SizedBox.square(dimension: size, child: clipped);
    return AspectRatio(aspectRatio: GzLayout.aspect4x5, child: clipped);
  }
}

/// The outline badge of the header: a 106 wide column wraps a long label to two lines instead of overflowing (the web
/// `.gz-cmph__text .gz-badge { white-space: normal }`); otherwise the `GzBadge` outline anatomy.
class _WrapBadge extends StatelessWidget {
  const _WrapBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: GzRadius.xsAll,
        border: Border.all(color: c.borderStrong, width: GzStroke.hair),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: GzSize.pillMin),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2 + GzStroke.hair, vertical: GzSpace.s1 + GzStroke.hair),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GzBeadBox(),
              const SizedBox(width: GzSpace.s1),
              Flexible(
                child: GzText(label, role: GzTextRole.pill, color: c.textStrong),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
