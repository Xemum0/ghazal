import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoRouteTransitionMixin;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show PageTransitionsBuilder, PageTransitionsTheme, PredictiveBackPageTransitionsBuilder, Theme;

import '../foundation.dart';

/// The forward and back transition of a page (web `gz-push-enter / gz-push-exit / gz-pop-enter / gz-pop-exit`, ADR 0017):
///
/// - the incoming page fades in and travels [GzMotion.distancePush] (24 dp) from the inline-end edge, over the slow duration
///   (320 ms) with the emphasised curve; a pop plays the same motion backwards (the leaving page returns to the inline-end edge);
/// - the page it covers fades out and travels 24 dp toward the inline-start edge (`secondaryAnimation`); it stays opaque underneath
///   (a canvas box), so the cross-fade never shows the window behind;
/// - the travel is direction-aware: the end edge is the right in LTR and the left in RTL;
/// - reduced motion removes the travel and keeps only a 120 ms cross-fade;
/// - [interactive] (an iOS swipe-back or an Android predictive back is in progress): no extra fade or travel; the platform
///   transition below it follows the finger.
class GzPageTransition extends StatefulWidget {
  const GzPageTransition({required this.animation, required this.secondaryAnimation, required this.child, this.interactive = false, super.key});

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;
  final bool interactive;

  @override
  State<GzPageTransition> createState() => _GzPageTransitionState();
}

class _GzPageTransitionState extends State<GzPageTransition> {
  static const Interval _reducedIn = Interval(0, 0.375); // 120 of 320 ms
  static const Interval _reducedOut = Interval(0.625, 1);

  CurvedAnimation? _primary;
  CurvedAnimation? _secondary;
  bool? _reducedBuilt;
  Animation<double>? _parentsBuilt;
  Animation<double>? _secondaryParentBuilt;

  void _build(bool reduced) {
    _primary?.dispose();
    _secondary?.dispose();
    _primary = CurvedAnimation(parent: widget.animation, curve: reduced ? _reducedIn : GzMotion.easeEmphasized, reverseCurve: reduced ? _reducedOut : null);
    _secondary = CurvedAnimation(parent: widget.secondaryAnimation, curve: reduced ? _reducedIn : GzMotion.easeEmphasized, reverseCurve: reduced ? _reducedOut : null);
    _reducedBuilt = reduced;
    _parentsBuilt = widget.animation;
    _secondaryParentBuilt = widget.secondaryAnimation;
  }

  @override
  void dispose() {
    _primary?.dispose();
    _secondary?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvas = context.gz.colors.surfaceCanvas;
    if (widget.interactive) return ColoredBox(color: canvas, child: widget.child);
    final reduced = GzReducedMotion.of(context);
    if (_reducedBuilt != reduced || _parentsBuilt != widget.animation || _secondaryParentBuilt != widget.secondaryAnimation) _build(reduced);
    final primary = _primary!;
    final secondary = _secondary!;
    // translateX is physical: toward inline-end = +24 in LTR, -24 in RTL.
    final end = Directionality.of(context) == TextDirection.rtl ? -GzMotion.distancePush : GzMotion.distancePush;

    final under = ColoredBox(
      color: canvas,
      child: AnimatedBuilder(
        animation: secondary,
        child: widget.child,
        builder: (context, child) => FadeTransition(
          opacity: ReverseAnimation(secondary),
          child: reduced ? child : Transform.translate(offset: Offset(-end * secondary.value, 0), child: child),
        ),
      ),
    );

    return FadeTransition(
      opacity: primary,
      child: AnimatedBuilder(
        animation: primary,
        child: under,
        builder: (context, child) => reduced ? child! : Transform.translate(offset: Offset(end * (1 - primary.value), 0), child: child),
      ),
    );
  }
}

/// The page transition of both apps (replaces the platform default in the theme; see [gzPageTransitionsTheme]). The visuals are
/// [GzPageTransition]. On top of them each platform keeps its own back gesture:
///
/// - iOS and macOS: the Cupertino interactive back swipe from the inline-start edge (it mirrors in RTL by itself), with the
///   Cupertino slide and parallax while the finger is down (the gesture detector of `cupertino_ui` is private, so its transition is
///   used as the carrier and driven by the real animation only while a gesture is in progress);
/// - Android: predictive back ([PredictiveBackPageTransitionsBuilder], which needs `android:enableOnBackInvokedCallback="true"` in
///   the manifest) while the system gesture is in progress.
///
/// A programmatic push or pop is always the Ghazal fade and 24 dp travel.
class GzPageTransitionsBuilder extends PageTransitionsBuilder {
  const GzPageTransitionsBuilder();

  @override
  Duration get transitionDuration => GzMotion.durationSlow;

  @override
  Duration get reverseTransitionDuration => GzMotion.durationSlow;

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final gesturing = route.popGestureInProgress;
    final platform = Theme.of(context).platform;
    // The platform layer sees the real animations only while a gesture is in progress; otherwise it is at rest (page in place).
    final primary = gesturing ? animation : kAlwaysCompleteAnimation;
    final secondary = gesturing ? secondaryAnimation : kAlwaysDismissedAnimation;
    Widget inner = child;
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        inner = CupertinoRouteTransitionMixin.buildPageTransitions<T>(route, context, primary, secondary, child);
      case TargetPlatform.android:
        inner = const PredictiveBackPageTransitionsBuilder().buildTransitions<T>(route, context, primary, secondary, child);
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        break;
    }
    return GzPageTransition(animation: animation, secondaryAnimation: secondaryAnimation, interactive: gesturing, child: inner);
  }
}

/// A theme value for any `MaterialPageRoute` the host still creates; [GzPage] does not need it.
const PageTransitionsTheme gzPageTransitionsTheme = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: GzPageTransitionsBuilder(),
    TargetPlatform.iOS: GzPageTransitionsBuilder(),
    TargetPlatform.macOS: GzPageTransitionsBuilder(),
    TargetPlatform.windows: GzPageTransitionsBuilder(),
    TargetPlatform.linux: GzPageTransitionsBuilder(),
    TargetPlatform.fuchsia: GzPageTransitionsBuilder(),
  },
);

/// A page route with the Ghazal transition (320 ms both ways). Use it for `Navigator.push` outside the router.
class GzPageRoute<T> extends PageRoute<T> {
  GzPageRoute({this.builder, super.settings, this.maintainState = true, super.fullscreenDialog, super.allowSnapshotting = true});

  final WidgetBuilder? builder;

  @override
  final bool maintainState;

  /// The screen of the route (a page-based route reads it from its page, so a page update shows).
  @protected
  Widget buildContent(BuildContext context) => builder!(context);

  @override
  Duration get transitionDuration => GzMotion.durationSlow;

  @override
  Duration get reverseTransitionDuration => GzMotion.durationSlow;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  bool get opaque => true;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
      Semantics(scopesRoute: true, explicitChildNodes: true, child: buildContent(context));

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) =>
      const GzPageTransitionsBuilder().buildTransitions<T>(this, context, animation, secondaryAnimation, child);
}

/// A router page with the Ghazal transition: `pageBuilder: (context, state) => GzPage(key: state.pageKey, child: screen)`. It is a
/// plain Navigator `Page`, so ghazal_ui does not import go_router.
class GzPage<T> extends Page<T> {
  const GzPage({required this.child, this.maintainState = true, this.fullscreenDialog = false, super.key, super.name, super.arguments, super.restorationId});

  final Widget child;
  final bool maintainState;
  final bool fullscreenDialog;

  @override
  Route<T> createRoute(BuildContext context) => _PageBasedGzRoute<T>(this);
}

class _PageBasedGzRoute<T> extends GzPageRoute<T> {
  _PageBasedGzRoute(GzPage<T> page) : super(settings: page);

  GzPage<T> get _page => settings as GzPage<T>;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}
