import 'package:flutter/widgets.dart';

/// One slot of the enclosing sheet: a screen opened as a sheet hands its pinned header, its pinned footer or its fill request to the
/// sheet without access to the sheet itself (the web `SheetFooter` portal).
class GzSheetSlotNotifier<T> extends ValueNotifier<T?> {
  GzSheetSlotNotifier() : super(null);

  bool _disposed = false;

  /// Ignored once the sheet that owns the slot has left.
  void publish(T? value) {
    if (!_disposed) this.value = value;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// The three slots a sheet offers its content: the pinned header (self-drawn, no gutter), the pinned footer (the sheet adds the gutter
/// and the bottom padding) and the fill request (the sheet takes its full 90 % height).
class GzSheetSlots {
  final GzSheetSlotNotifier<Widget> header = GzSheetSlotNotifier<Widget>();
  final GzSheetSlotNotifier<Widget> footer = GzSheetSlotNotifier<Widget>();
  final GzSheetSlotNotifier<bool> fill = GzSheetSlotNotifier<bool>();

  void dispose() {
    header.dispose();
    footer.dispose();
    fill.dispose();
  }
}

/// The scope that carries a sheet's [GzSheetSlots] down to its content.
class GzSheetSlotScope extends InheritedWidget {
  const GzSheetSlotScope({required this.slots, required super.child, super.key});

  final GzSheetSlots slots;

  static GzSheetSlots? maybeOf(BuildContext context) => context.getInheritedWidgetOfExactType<GzSheetSlotScope>()?.slots;

  @override
  bool updateShouldNotify(GzSheetSlotScope oldWidget) => oldWidget.slots != slots;
}

/// Publishes [child] into one slot of the enclosing sheet; outside a sheet it renders [child] in place when [inPlace].
class _GzSheetPortal<T extends Object> extends StatefulWidget {
  const _GzSheetPortal({required this.select, required this.value, required this.inPlace, this.child});

  final GzSheetSlotNotifier<T> Function(GzSheetSlots slots) select;
  final T value;
  final bool inPlace;
  final Widget? child;

  @override
  State<_GzSheetPortal<T>> createState() => _GzSheetPortalState<T>();
}

class _GzSheetPortalState<T extends Object> extends State<_GzSheetPortal<T>> {
  GzSheetSlotNotifier<T>? _slot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final slots = GzSheetSlotScope.maybeOf(context);
    final next = slots == null ? null : widget.select(slots);
    if (next != _slot) {
      _release();
      _slot = next;
    }
    _publish();
  }

  @override
  void didUpdateWidget(_GzSheetPortal<T> old) {
    super.didUpdateWidget(old);
    _publish();
  }

  void _publish() {
    final slot = _slot;
    if (slot == null) return;
    // After the frame: a notifier must not change while the tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _slot == slot) slot.publish(widget.value);
    });
  }

  void _release() {
    final slot = _slot;
    if (slot == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => slot.publish(null));
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _slot == null && widget.inPlace ? (widget.child ?? const SizedBox.shrink()) : const SizedBox.shrink();
}

/// Pins [child] under the body of the sheet that contains it (the primary action row). The sheet supplies the gutter and the bottom
/// padding of the footer (and the safe-bottom inset): pass the bare button. Outside a sheet (a static frame, a gallery) it renders in place.
class GzSheetFooter extends StatelessWidget {
  const GzSheetFooter({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => _GzSheetPortal<Widget>(select: (s) => s.footer, value: child, inPlace: true, child: child);
}

/// Pins [child] between the handle and the body of the sheet that contains it: the header a screen opened as a sheet draws itself
/// (title row, a step bar, a search field). Unlike the `title` row it is self-drawn, so the sheet adds NO gutter to it (draw the 20
/// gutter yourself, like `GzSheetHeader`); the body below it scrolls under it. It joins the drag zone: a drag on it dismisses the
/// sheet. Outside a sheet it renders in place.
class GzSheetPinnedHeader extends StatelessWidget {
  const GzSheetPinnedHeader({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => _GzSheetPortal<Widget>(select: (s) => s.header, value: child, inPlace: true, child: child);
}

/// Asks the enclosing sheet to fill its height (about 90 % of the frame) with the body scrolling between the pinned header and the
/// pinned footer, instead of sizing to its content: for "a screen shown as a sheet" whose body changes height (a filter panel).
/// Place it anywhere in the screen; it draws nothing.
class GzSheetFill extends StatelessWidget {
  const GzSheetFill({super.key});

  @override
  Widget build(BuildContext context) => _GzSheetPortal<bool>(select: (s) => s.fill, value: true, inPlace: false);
}
