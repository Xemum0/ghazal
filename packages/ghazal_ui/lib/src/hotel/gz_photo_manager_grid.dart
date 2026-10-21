import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import 'hotel_c_photo_cell.dart';

export 'hotel_c_photo_cell.dart' show GzPhotoStatus, GzPhotoTile;

/// PhotoManagerGrid: the listing's photos as a three-column 4:5 grid (HL-VENU-01, HA-VMGT-01). The first photo carries the Cover
/// marker; every tile shows its zone tag and, when it is not simply live, its status (In review, Rejected) as an icon + label chip.
/// The last cell is the Add tile. Reorder mode swaps the tile tap for a drag handle (the tile lifts and leaves a quiet hole; drop it
/// on another photo) and two plain Move earlier / Move later buttons, the accessible alternative to drag (ADR 0014 D4); "earlier"
/// is toward the inline-start, so the chevrons mirror with the language. Outside reorder mode a screen that passes [onSetCover] or
/// [onDelete] gets a selectable grid: a tap chooses a photo and an action row offers Make cover, Delete and Open; a delete leaves
/// an undo bar for 8 seconds and tells the screen ([onDelete]) only when it is final. Photos are empty rooms and details only: an
/// avatar or a face never appears here (ADR 0015).
class GzPhotoManagerGrid extends StatefulWidget {
  const GzPhotoManagerGrid({
    required this.items,
    this.reorder = false,
    this.onOpen,
    this.onMove,
    this.onReorder,
    this.onAdd,
    this.onSetCover,
    this.onDelete,
    this.imageOf,
    super.key,
  });

  final List<GzPhotoTile> items;

  /// Reorder mode: handles and Move earlier / Move later buttons instead of opening a photo.
  final bool reorder;
  final ValueChanged<String>? onOpen;

  /// A Move button: `by` is -1 (earlier) or 1 (later).
  final void Function(String id, int by)? onMove;

  /// A drop: the photo [id] was released on the cell at [toIndex] of the visible list.
  final void Function(String id, int toIndex)? onReorder;
  final VoidCallback? onAdd;

  /// Make the chosen photo the cover (the first one).
  final ValueChanged<String>? onSetCover;

  /// The final delete (after the undo window ran out or the grid left the screen).
  final ValueChanged<String>? onDelete;

  /// Galleries and tests: the picture of a tile (default: the tile's `src` through `GzPhoto`).
  final ImageProvider? Function(GzPhotoTile tile)? imageOf;

  @override
  State<GzPhotoManagerGrid> createState() => _GzPhotoManagerGridState();
}

class _GzPhotoManagerGridState extends State<GzPhotoManagerGrid> {
  static const int _columns = 3;
  String? _dragId;
  String? _selected;
  String? _pending;
  int _undoRun = 0;

  bool get _selectable => !widget.reorder && (widget.onSetCover != null || widget.onDelete != null);

  List<GzPhotoTile> get _visible => [
    for (final t in widget.items)
      if (t.id != _pending) t,
  ];

  @override
  void dispose() {
    final id = _pending;
    if (id != null) widget.onDelete?.call(id);
    super.dispose();
  }

  void _commit() {
    final id = _pending;
    if (id == null) return;
    setState(() => _pending = null);
    widget.onDelete?.call(id);
  }

  void _delete(String id) {
    final earlier = _pending;
    if (earlier != null) widget.onDelete?.call(earlier);
    GzHaptics.fire(GzHapticKind.medium);
    setState(() {
      _pending = id;
      _selected = null;
      _undoRun++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.gzL10n;
    final items = _visible;
    final cells = <GzPhotoTile?>[...items, null];
    final rows = <List<GzPhotoTile?>?>[];
    for (var i = 0; i < cells.length; i += _columns) {
      rows.add(cells.sublist(i, i + _columns > cells.length ? cells.length : i + _columns));
    }
    GzPhotoTile? chosen;
    for (final t in items) {
      if (t.id == _selected) chosen = t;
    }
    final chosenIndex = chosen == null ? -1 : items.indexOf(chosen);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: GzSpace.s2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var k = 0; k < _columns; k++) ...[
                if (k > 0) const SizedBox(width: GzSpace.s2),
                Expanded(
                  child: k >= rows[r]!.length
                      ? const SizedBox.shrink()
                      : (rows[r]![k] == null ? _AddTile(onAdd: widget.onAdd) : _cell(context, rows[r]![k]!, items)),
                ),
              ],
            ],
          ),
        ],
        if (_selectable && chosen != null) ...[
          const SizedBox(height: GzSpace.s3),
          Wrap(
            spacing: GzSpace.s3,
            runSpacing: GzSpace.s2,
            children: [
              if (widget.onSetCover != null && chosenIndex > 0)
                GzButton(
                  label: l.uiHotelPhotosMakeCover,
                  variant: GzButtonVariant.secondary,
                  iconStart: GzIcons.image,
                  onPressed: () {
                    final id = chosen!.id;
                    setState(() => _selected = null);
                    widget.onSetCover!(id);
                  },
                ),
              if (widget.onOpen != null)
                GzButton(label: l.uiHotelPhotosOpenAction, variant: GzButtonVariant.tertiary, onPressed: () => widget.onOpen!(chosen!.id)),
              if (widget.onDelete != null)
                GzButton(
                  label: l.uiHotelPhotosDelete,
                  variant: GzButtonVariant.tertiary,
                  iconStart: GzIcons.close,
                  onPressed: () => _delete(chosen!.id),
                ),
            ],
          ),
        ],
        if (_pending != null) ...[
          const SizedBox(height: GzSpace.s3),
          GzUndoBar(message: l.uiHotelPhotosDeleted, runKey: _undoRun, onUndo: () => setState(() => _pending = null), onExpire: _commit),
        ],
      ],
    );
  }

  Widget _cell(BuildContext context, GzPhotoTile tile, List<GzPhotoTile> items) {
    final index = items.indexOf(tile);
    final image = widget.imageOf?.call(tile);
    final base = GzPhotoCellState(
      index: index,
      total: items.length,
      reorder: widget.reorder,
      selected: _selectable && _selected == tile.id,
      dimmed: _dragId == tile.id,
    );
    if (!widget.reorder) {
      return RepaintBoundary(
        child: GzPhotoCell(
          tile: tile,
          cell: base,
          image: image,
          onTap: () {
            if (_selectable) {
              setState(() => _selected = _selected == tile.id ? null : tile.id);
            } else {
              widget.onOpen?.call(tile.id);
            }
          },
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = w / GzLayout.aspect4x5;
        return DragTarget<String>(
          onWillAcceptWithDetails: (d) => d.data != tile.id,
          onAcceptWithDetails: (d) {
            GzHaptics.fire(GzHapticKind.selection);
            widget.onReorder?.call(d.data, index);
          },
          builder: (context, candidates, rejected) => RepaintBoundary(
            child: GzPhotoCell(
              tile: tile,
              image: image,
              cell: GzPhotoCellState(
                index: index,
                total: items.length,
                reorder: true,
                dimmed: _dragId == tile.id,
                highlighted: candidates.isNotEmpty,
              ),
              onMove: (by) => widget.onMove?.call(tile.id, by),
              grip: _Grip(
                tile: tile,
                index: index,
                total: items.length,
                size: Size(w, h),
                image: image,
                onStart: () {
                  GzHaptics.fire(GzHapticKind.light);
                  setState(() => _dragId = tile.id);
                },
                onEnd: () {
                  if (mounted) setState(() => _dragId = null);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The drag handle of one tile: a 44 dp target around the grip disk; dragging lifts a copy of the tile (scaled up, with elevation)
/// under the finger while the original stays behind as a quiet hole.
class _Grip extends StatelessWidget {
  const _Grip({
    required this.tile,
    required this.index,
    required this.total,
    required this.size,
    required this.image,
    required this.onStart,
    required this.onEnd,
  });

  final GzPhotoTile tile;
  final int index;
  final int total;
  final Size size;
  final ImageProvider? image;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final l = context.gzL10n;
    final handle = SizedBox(
      width: GzSize.touchMin,
      height: GzSize.touchMin,
      child: const Center(child: GzPhotoGripDisk()),
    );
    return Semantics(
      label: l.uiHotelPhotosDrag,
      container: true,
      child: Draggable<String>(
        data: tile.id,
        maxSimultaneousDrags: 1,
        dragAnchorStrategy: (draggable, ctx, position) => Offset(size.width / 2, size.height / 2),
        onDragStarted: onStart,
        onDragEnd: (_) => onEnd(),
        feedback: Directionality(
          textDirection: Directionality.of(context),
          child: Transform.scale(
            scale: 1.05,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: GzPhotoCell(
                tile: tile,
                image: image,
                cell: GzPhotoCellState(index: index, total: total, reorder: true, lifted: true),
              ),
            ),
          ),
        ),
        child: handle,
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    return AspectRatio(
      aspectRatio: GzLayout.aspect4x5,
      child: GzPressable(
        onPressed: onAdd ?? () {},
        semanticLabel: l.uiHotelPhotosAdd,
        borderRadius: GzRadius.mdAll,
        minWidth: 0,
        minHeight: 0,
        builder: (context, st) => Container(
          decoration: BoxDecoration(
            color: st.pressed ? c.controlTrack : c.surfaceQuiet,
            borderRadius: GzRadius.mdAll,
            border: Border.all(color: c.borderStrong, width: GzStroke.hair),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GzIcon(GzIcons.plus, size: GzIconSize.md, color: c.actionTertiaryLabel),
              const SizedBox(height: GzSpace.s2),
              GzText(l.uiHotelPhotosAdd, role: GzTextRole.caption, color: c.actionTertiaryLabel, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
