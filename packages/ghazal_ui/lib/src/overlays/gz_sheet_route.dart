import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_sheet.dart';

/// The route of a sheet: the sheet rises 320 ms on the emphasised curve and leaves 200 ms on the exit curve (reduced motion keeps a
/// 120 ms fade); the scrim is the modal token and dims with the drag; a tap outside, the system back and Escape dismiss unless
/// [dismissible] is false; focus stays inside and returns to the opener. Built by [showGzSheet] and [GzSheetPage].
class GzSheetRoute<T> extends PopupRoute<T> {
  GzSheetRoute({
    required this.builder,
    this.title,
    this.header,
    this.footer,
    this.dismissible = true,
    this.label,
    this.scrim = true,
    this.fill = false,
    this.closeLabel,
    super.settings,
    super.traversalEdgeBehavior,
  });

  final WidgetBuilder builder;
  final String? title;

  /// A self-drawn pinned header (see [GzSheet.header]).
  final Widget? header;
  final Widget? footer;
  final bool dismissible;
  final String? label;

  /// false for a second sheet over a first (it draws no second dimmer).
  final bool scrim;

  /// Fill mode (see [GzSheet.fill]).
  final bool fill;
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
    // Never negative or NaN: the iOS keyboard animation reports in-between values (a spring can overshoot below 0 as the keyboard leaves),
    // and a negative bottom padding is a debug assertion in RenderPadding that took the whole route down (device pass, 2026-10-29).
    final keyboard = mq.viewInsets.bottom > 0 ? mq.viewInsets.bottom : 0.0;

    Widget sheet = GzSheet(
      title: route.title,
      header: route.header,
      footer: route.footer,
      dismissible: route.dismissible,
      label: route.label,
      fill: route.fill,
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
    // Always wrapped (unchanged while the keyboard is down): a wrapper that only exists while the keyboard is up would rebuild the whole
    // sheet, and the focused field with it, the moment the keyboard rises.
    final padding = keyboard > 0 ? mq.padding.copyWith(bottom: (mq.padding.bottom - keyboard).clamp(0.0, double.infinity)) : mq.padding;
    final insets = mq.viewInsets.copyWith(bottom: 0); // equal to the incoming insets while the keyboard is down
    return MediaQuery(data: mq.copyWith(padding: padding, viewInsets: insets), child: handled);
  }
}

/// Opens a sheet: `showGzSheet<T>(context, builder: (context) => ...)`. [builder] draws the body (it scrolls inside the sheet when
/// it is taller than 90%); [title] draws the title row with the close button, [footer] pins the action row, [fill] takes the full
/// 90 % height (see [GzSheet.fill]). The sheet supplies the 20 gutter and the bottom padding of the body and the footer. Resolves with the value
/// given to `Navigator.pop`, or null when dismissed.
Future<T?> showGzSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
  Widget? header,
  Widget? footer,
  bool dismissible = true,
  String? label,
  bool scrim = true,
  bool fill = false,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  final route = GzSheetRoute<T>(
    builder: builder,
    title: title,
    header: header,
    footer: footer,
    dismissible: dismissible,
    label: label,
    scrim: scrim,
    fill: fill,
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
    this.header,
    this.footer,
    this.dismissible = true,
    this.label,
    this.scrim = true,
    this.fill = false,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final String? title;
  final Widget? header;
  final Widget? footer;
  final bool dismissible;
  final String? label;
  final bool scrim;
  final bool fill;

  @override
  Route<T> createRoute(BuildContext context) => GzSheetRoute<T>(
        builder: (_) => child,
        title: title,
        header: header,
        footer: footer,
        dismissible: dismissible,
        label: label,
        scrim: scrim,
        fill: fill,
        closeLabel: context.gzL10n.commonActionClose,
        settings: this,
      );
}
