import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../foundation.dart';
import '../nav/gz_bar_button.dart';
import '../nav/gz_nav_scope.dart';

/// Share of the frame a sheet may take (direction section 3: at most 90% height), snapped to the 4-pt grid.
const double gzSheetMaxShare = 0.9;

/// A drag past this share of the sheet's height dismisses it.
const double gzSheetDismissShare = 0.3;

/// A release faster than this (dp/s) dismisses regardless of distance.
const double gzSheetFlick = 700;

/// Upward drags are rubber-banded by this factor.
const double gzSheetRubber = 0.15;

/// The footer slot of the enclosing sheet: a screen opened as a sheet pins its action row with [GzSheetFooter] without access to the
/// sheet itself (the web `SheetFooter` portal).
class GzSheetFooterNotifier extends ValueNotifier<Widget?> {
  GzSheetFooterNotifier() : super(null);

  bool _disposed = false;

  /// Ignored once the sheet that owns the slot has left.
  void publish(Widget? footer) {
    if (!_disposed) value = footer;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class GzSheetFooterSlot extends InheritedWidget {
  const GzSheetFooterSlot({required this.footer, required super.child, super.key});

  final GzSheetFooterNotifier footer;

  static GzSheetFooterNotifier? maybeOf(BuildContext context) => context.getInheritedWidgetOfExactType<GzSheetFooterSlot>()?.footer;

  @override
  bool updateShouldNotify(GzSheetFooterSlot oldWidget) => oldWidget.footer != footer;
}

/// Pins [child] under the body of the sheet that contains it (the primary action row), with the bottom spacing of the `footer`
/// argument. Outside a sheet (a static frame, a gallery) it renders in place.
class GzSheetFooter extends StatefulWidget {
  const GzSheetFooter({required this.child, super.key});

  final Widget child;

  @override
  State<GzSheetFooter> createState() => _GzSheetFooterState();
}

class _GzSheetFooterState extends State<GzSheetFooter> {
  GzSheetFooterNotifier? _slot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = GzSheetFooterSlot.maybeOf(context);
    if (next != _slot) {
      _release();
      _slot = next;
    }
    _publish();
  }

  @override
  void didUpdateWidget(GzSheetFooter old) {
    super.didUpdateWidget(old);
    _publish();
  }

  void _publish() {
    final slot = _slot;
    if (slot == null) return;
    // After the frame: a notifier must not change while the tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _slot == slot) slot.publish(widget.child);
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
  Widget build(BuildContext context) => _slot == null ? widget.child : const SizedBox.shrink();
}

/// Title at inline-start, close at inline-end (ADR 0014 D3). Min 48 high; the close target is 44.
class GzSheetHeader extends StatelessWidget {
  const GzSheetHeader({required this.title, this.onClose, this.closeLabel, super.key});

  final String title;
  final VoidCallback? onClose;
  final String? closeLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final role = GzAppScope.of(context) == GzAppKind.client ? GzTextRole.d1 : GzTextRole.uiTitle;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.controlMd),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.s2),
        child: Row(
          children: [
            Expanded(child: GzText(title, role: role, color: c.textStrong, header: true)),
            if (onClose != null) ...[
              const SizedBox(width: GzSpace.s3),
              GzBarButton(key: const ValueKey('gz:sheet.close'), icon: GzIcons.close, label: closeLabel ?? context.gzL10n.commonActionClose, onPressed: onClose),
            ],
          ],
        ),
      ),
    );
  }
}

/// The modal dimmer behind a sheet or dialog (scrim-modal). [opacity] (0..1) scales the token colour's alpha, and so does `1 - dim`
/// (the share of the sheet that has been dragged away). Painted as one colour, no `Opacity` layer.
class GzScrim extends StatelessWidget {
  const GzScrim({this.opacity = const AlwaysStoppedAnimation<double>(1), this.dim, super.key});

  final Animation<double> opacity;
  final ValueListenable<double>? dim;

  @override
  Widget build(BuildContext context) {
    final base = context.gz.colors.scrimModal;
    return AnimatedBuilder(
      animation: Listenable.merge([opacity, ?dim]),
      builder: (context, _) {
        final f = (opacity.value * (1 - (dim?.value ?? 0))).clamp(0.0, 1.0);
        return ColoredBox(color: base.withValues(alpha: base.a * f));
      },
    );
  }
}

/// Sheet (direction section 3): raised paper, top radius 20, handle 36 x 4 ink-300, padding 12 / 20 / 24 + the home-indicator inset,
/// elevation 3, at most 90% of the available height. Drag down on the handle or the title row to dismiss: past 30% of its height or
/// a flick over 700 dp/s it leaves, otherwise the critically damped settle spring (ADR 0017) brings it back, continuing the
/// finger's velocity. [dragProgress] (0..1) tells the scrim to dim with the drag.
///
/// This widget is the container; the rise, the scrim and the route are [showGzSheet] / [GzSheetPage]. Without [onRequestClose] (a
/// static frame, a gallery) it does not drag and has no close button.
class GzSheet extends StatefulWidget {
  const GzSheet({
    required this.child,
    this.title,
    this.footer,
    this.onRequestClose,
    this.dismissible = true,
    this.label,
    this.dragProgress,
    super.key,
  });

  final Widget child;

  /// Title row (a screen opened as a sheet draws its own header and passes none).
  final String? title;

  /// Pinned under the body (primary action row); gets the bottom spacing and the safe-bottom inset.
  final Widget? footer;

  /// Close button, drag-dismiss and the Escape key ask to close; called after a drag has left the screen.
  final VoidCallback? onRequestClose;

  /// false: the sheet must be answered (unsaved guard): no drag, no close button.
  final bool dismissible;

  /// Accessible name when there is no [title].
  final String? label;
  final ValueNotifier<double>? dragProgress;

  @override
  State<GzSheet> createState() => _GzSheetState();
}

class _GzSheetState extends State<GzSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _spring = AnimationController.unbounded(vsync: this)..addListener(_onSpring);
  final GlobalKey _sheetKey = GlobalKey();
  final GzSheetFooterNotifier _footerSlot = GzSheetFooterNotifier();
  double _offset = 0;
  bool _gone = false;

  bool get _draggable => widget.dismissible && widget.onRequestClose != null;

  void _onSpring() => _setOffset(_spring.value);

  void _setOffset(double dy) {
    if (dy == _offset) return;
    setState(() => _offset = dy);
    final h = _sheetKey.currentContext?.size?.height ?? 1;
    widget.dragProgress?.value = dy <= 0 ? 0 : (dy / h).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _spring.dispose();
    _footerSlot.dispose();
    super.dispose();
  }

  double _raw = 0;

  void _onStart(DragStartDetails d) {
    _spring.stop();
    _raw = _offset;
  }

  void _onUpdate(DragUpdateDetails d) {
    _raw += d.delta.dy;
    _setOffset(_raw < 0 ? _raw * gzSheetRubber : _raw);
  }

  void _onEnd(DragEndDetails d) {
    final h = _sheetKey.currentContext?.size?.height ?? 1;
    final dy = math.max(0.0, _offset);
    final v = d.velocity.pixelsPerSecond.dy;
    final leave = dy > h * gzSheetDismissShare || v > gzSheetFlick;
    final target = leave ? h : 0.0;
    if (GzReducedMotion.of(context)) {
      _setOffset(target);
      if (leave) _finish();
      return;
    }
    // Leaves from where the finger let go: the settle spring carries it the rest of the way out.
    _spring.value = _offset;
    _spring.animateWith(SpringSimulation(GzMotion.springSettle, _offset, target, leave ? math.max(v, 0) : v)).whenComplete(() {
      if (!mounted) return;
      _setOffset(target);
      if (leave) _finish();
    });
  }

  void _finish() {
    _gone = true;
    widget.onRequestClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final mq = MediaQuery.of(context);
    final safeBottom = mq.padding.bottom;
    final title = widget.title;
    final closeHandler = widget.dismissible ? widget.onRequestClose : null;

    final grab = SizedBox(
      key: const ValueKey('gz:sheet.grab'),
      height: GzSpace.s5,
      width: double.infinity,
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.borderStrong, borderRadius: GzRadius.pillAll),
          child: const SizedBox(width: GzSize.handleWidth, height: GzSize.handleHeight),
        ),
      ),
    );

    Widget dragZone = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [grab, if (title != null) GzSheetHeader(title: title, onClose: closeHandler)],
    );
    if (_draggable) {
      dragZone = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: _onStart,
        onVerticalDragUpdate: _onUpdate,
        onVerticalDragEnd: _onEnd,
        child: dragZone,
      );
    }

    final body = Flexible(
      child: GzSheetFooterSlot(
        footer: _footerSlot,
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.sheetPadBottom),
          child: widget.child,
        ),
      ),
    );

    final footer = ValueListenableBuilder<Widget?>(
      valueListenable: _footerSlot,
      builder: (context, slotted, _) {
        final f = widget.footer ?? slotted;
        if (f == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.sheetPadBottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [f]),
        );
      },
    );

    final panel = DecoratedBox(
      decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.sheetTop, boxShadow: GzElevation.e3),
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: GzSpace.sheetPadTop, bottom: safeBottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [dragZone, body, footer],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, box) {
        final cap = box.hasBoundedHeight ? (box.maxHeight * gzSheetMaxShare / 4).floor() * 4.0 : double.infinity;
        return Semantics(
          container: true,
          explicitChildNodes: true,
          scopesRoute: true,
          namesRoute: true,
          label: title ?? widget.label,
          role: SemanticsRole.dialog,
          child: Transform.translate(
            offset: Offset(0, _gone ? math.max(_offset, 0) : _offset),
            child: ConstrainedBox(
              key: _sheetKey,
              constraints: BoxConstraints(maxHeight: cap),
              child: panel,
            ),
          ),
        );
      },
    );
  }
}

/// The route of a sheet: the sheet rises 320 ms on the emphasised curve and leaves 200 ms on the exit curve (reduced motion keeps a
/// 120 ms fade); the scrim is the modal token and dims with the drag; a tap outside, the system back and Escape dismiss unless
/// [dismissible] is false; focus stays inside and returns to the opener. Built by [showGzSheet] and [GzSheetPage].
class GzSheetRoute<T> extends PopupRoute<T> {
  GzSheetRoute({
    required this.builder,
    this.title,
    this.footer,
    this.dismissible = true,
    this.label,
    this.scrim = true,
    this.closeLabel,
    super.settings,
    super.traversalEdgeBehavior,
  });

  final WidgetBuilder builder;
  final String? title;
  final Widget? footer;
  final bool dismissible;
  final String? label;

  /// false for a second sheet over a first (it draws no second dimmer).
  final bool scrim;
  final String? closeLabel;

  final ValueNotifier<double> _drag = ValueNotifier<double>(0);

  @override
  Duration get transitionDuration => GzMotion.durationSlow;

  @override
  Duration get reverseTransitionDuration => GzMotion.durationBase;

  @override
  bool get barrierDismissible => dismissible;

  @override
  Color? get barrierColor => null; // the scrim is painted by the layer (it dims with the drag)

  @override
  String? get barrierLabel => closeLabel;

  @override
  void dispose() {
    _drag.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return PopScope(
      canPop: dismissible,
      child: _SheetLayer<T>(route: this, animation: animation),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) => child;
}

class _SheetLayer<T> extends StatefulWidget {
  const _SheetLayer({required this.route, required this.animation});

  final GzSheetRoute<T> route;
  final Animation<double> animation;

  @override
  State<_SheetLayer<T>> createState() => _SheetLayerState<T>();
}

class _SheetLayerState<T> extends State<_SheetLayer<T>> {
  late final CurvedAnimation _rise = CurvedAnimation(parent: widget.animation, curve: GzMotion.easeEmphasized, reverseCurve: GzMotion.easeExit.flipped);
  late final CurvedAnimation _fade = CurvedAnimation(parent: widget.animation, curve: GzMotion.easeStandard);
  late final CurvedAnimation _reducedFade = CurvedAnimation(parent: widget.animation, curve: const Interval(0, 0.375), reverseCurve: const Interval(0.625, 1));

  @override
  void dispose() {
    _rise.dispose();
    _fade.dispose();
    _reducedFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final reduced = GzReducedMotion.of(context);
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom;

    Widget sheet = GzSheet(
      title: route.title,
      footer: route.footer,
      dismissible: route.dismissible,
      label: route.label,
      dragProgress: route._drag,
      onRequestClose: () => Navigator.of(context).maybePop(),
      child: Builder(builder: route.builder),
    );
    sheet = reduced
        ? FadeTransition(opacity: _reducedFade, child: sheet)
        : SlideTransition(position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(_rise), child: sheet);

    final content = Stack(
      fit: StackFit.expand,
      children: [
        if (route.scrim)
          IgnorePointer(
            child: GzScrim(opacity: reduced ? _reducedFade : _fade, dim: route._drag),
          ),
        Align(alignment: Alignment.bottomCenter, child: Padding(padding: EdgeInsets.only(bottom: keyboard), child: sheet)),
      ],
    );
    final handled = CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        if (route.dismissible) const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).maybePop(),
      },
      child: FocusScope(autofocus: true, child: content),
    );
    if (keyboard > 0) {
      final padding = mq.padding.copyWith(bottom: (mq.padding.bottom - keyboard).clamp(0.0, double.infinity));
      return MediaQuery(data: mq.copyWith(padding: padding, viewInsets: mq.viewInsets.copyWith(bottom: 0)), child: handled);
    }
    return handled;
  }
}

/// Opens a sheet: `showGzSheet<T>(context, builder: (context) => ...)`. [builder] draws the body (it scrolls inside the sheet when
/// it is taller than 90%); [title] draws the title row with the close button, [footer] pins the action row. Resolves with the value
/// given to `Navigator.pop`, or null when dismissed.
Future<T?> showGzSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
  Widget? footer,
  bool dismissible = true,
  String? label,
  bool scrim = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  final route = GzSheetRoute<T>(
    builder: builder,
    title: title,
    footer: footer,
    dismissible: dismissible,
    label: label,
    scrim: scrim,
    closeLabel: context.gzL10n.commonActionClose,
    settings: routeSettings,
  );
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(route);
}

/// A router page that shows a sheet (`pageBuilder: (context, state) => GzSheetPage(key: state.pageKey, child: screen)`): a plain
/// Navigator `Page`, so ghazal_ui does not import go_router. The sheet is its own route over the screen below.
class GzSheetPage<T> extends Page<T> {
  const GzSheetPage({
    required this.child,
    this.title,
    this.footer,
    this.dismissible = true,
    this.label,
    this.scrim = true,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final String? title;
  final Widget? footer;
  final bool dismissible;
  final String? label;
  final bool scrim;

  @override
  Route<T> createRoute(BuildContext context) => GzSheetRoute<T>(
        builder: (_) => child,
        title: title,
        footer: footer,
        dismissible: dismissible,
        label: label,
        scrim: scrim,
        closeLabel: context.gzL10n.commonActionClose,
        settings: this,
      );
}
