import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_nav_scope.dart';

/// Scrolling without Material: no overscroll glow or stretch, no scrollbar, the platform physics (bounce on iOS, clamp on
/// Android) and drag with touch, mouse and stylus. [clamping] forces clamping physics (pull-to-refresh owns the overscroll).
class GzScrollBehavior extends ScrollBehavior {
  const GzScrollBehavior({this.clamping = false});

  final bool clamping;

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      clamping ? const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()) : super.getScrollPhysics(context);

  @override
  Set<PointerDeviceKind> get dragDevices => const {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.stylus, PointerDeviceKind.trackpad};
}

/// Screen (the scaffold a screen draws itself in; web `Screen`): a [top] bar above, ONE scrolling body without side padding, a
/// [bottom] bar below. The bars are plain column children (not sticky), the body is the only scroller and reports its offset to the
/// bars through [GzScreenScroll] (hairline, large-title collapse, transparent to solid). A transparent bar ([topOverlay]) overlays the
/// body instead of sitting above it.
///
/// Safe areas come from `MediaQuery` (the bars add their own insets, the body adds none). With the keyboard open the whole screen
/// shrinks above it and the bottom inset is spent, like `Scaffold.resizeToAvoidBottomInset`.
///
/// `GzScreen(child: ...)` scrolls one widget; `GzScreen.slivers(slivers: ...)` is for long lists (builder slivers).
class GzScreen extends StatefulWidget {
  const GzScreen({
    this.top,
    this.topOverlay = false,
    this.bottom,
    this.child,
    this.fixed = false,
    this.controller,
    this.padding,
    super.key,
  })  : slivers = null,
        assert(child != null || (top != null || bottom != null), 'A screen needs a body');

  const GzScreen.slivers({
    required List<Widget> this.slivers,
    this.top,
    this.topOverlay = false,
    this.bottom,
    this.controller,
    this.padding,
    super.key,
  })  : child = null,
        fixed = false;

  /// A [GzTopBar].
  final Widget? top;

  /// Draw [top] over the body (a transparent bar over a photograph) instead of above it.
  final bool topOverlay;

  /// A [GzActionBar] or any pinned footer.
  final Widget? bottom;
  final Widget? child;
  final List<Widget>? slivers;

  /// The body does not scroll (a map, a chat composer owns the scroll below it).
  final bool fixed;
  final ScrollController? controller;

  /// Padding around the body content inside the scroller (never side padding by default: screens own their gutters).
  final EdgeInsetsGeometry? padding;

  @override
  State<GzScreen> createState() => _GzScreenState();
}

class _GzScreenState extends State<GzScreen> {
  ScrollController? _own;
  int _offset = 0;
  int _signalSeen = 0;

  ScrollController get _controller => widget.controller ?? (_own ??= ScrollController());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final signal = GzScrollToTopSignal.of(context);
    if (signal != _signalSeen) {
      _signalSeen = signal;
      // Only the visible tab scrolls (a hidden tab's tickers are muted).
      if (signal > 0 && TickerMode.valuesOf(context).enabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_controller.hasClients) return;
          _controller.animateTo(0, duration: GzReducedMotion.movement(context, GzMotion.durationSlow), curve: GzMotion.easeStandard);
        });
      }
    }
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final next = n.metrics.pixels < 0 ? 0 : n.metrics.pixels.round();
    if (next != _offset) setState(() => _offset = next);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom;
    Widget body;
    if (widget.fixed && widget.child != null) {
      body = widget.child!;
    } else {
      final slivers = widget.slivers ?? [SliverToBoxAdapter(child: widget.child ?? const SizedBox.shrink())];
      body = NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ScrollConfiguration(
          behavior: const GzScrollBehavior(),
          child: CustomScrollView(
            controller: _controller,
            primary: false,
            slivers: widget.padding == null ? slivers : [SliverPadding(padding: widget.padding!, sliver: SliverMainAxisGroup(slivers: slivers))],
          ),
        ),
      );
    }
    final top = widget.top;
    final overlay = top != null && widget.topOverlay;
    Widget column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (top != null && !overlay) top,
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: body),
              if (overlay) PositionedDirectional(start: 0, end: 0, top: 0, child: top),
            ],
          ),
        ),
        if (widget.bottom != null) widget.bottom!,
      ],
    );
    if (keyboard > 0) {
      // The keyboard takes the bottom: the screen shrinks above it and the home-indicator inset is already covered.
      final padding = mq.padding.copyWith(bottom: (mq.padding.bottom - keyboard).clamp(0.0, double.infinity));
      column = MediaQuery(
        data: mq.copyWith(padding: padding, viewInsets: mq.viewInsets.copyWith(bottom: 0)),
        child: Padding(padding: EdgeInsets.only(bottom: keyboard), child: column),
      );
    }
    return GzScreenScroll(
      offset: _offset.toDouble(),
      child: ColoredBox(color: c.surfaceCanvas, child: column),
    );
  }
}
