import 'package:flutter/widgets.dart';

/// Which app is drawn (web `AppKind`; the Partner app keeps the `hotel` id on the web). Only a few components differ: the large
/// title face, the sheet and dialog title face and the empty-state title face (client serif, partner UI face).
enum GzAppKind { client, partner }

/// Installs the [GzAppKind] for a subtree. Without one, [of] answers [GzAppKind.client].
class GzAppScope extends InheritedWidget {
  const GzAppScope({required this.app, required super.child, super.key});

  final GzAppKind app;

  static GzAppKind of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GzAppScope>()?.app ?? GzAppKind.client;

  @override
  bool updateShouldNotify(GzAppScope oldWidget) => oldWidget.app != app;
}

/// What a [GzScreen] tells the bars around it: the scroll offset of its body (hairline under the bar, large-title collapse, the
/// transparent bar turning solid). Gallery specimens wrap a bar in `GzScreenScroll(offset: 48, child: ...)` to force a state.
class GzScreenScroll extends InheritedWidget {
  const GzScreenScroll({required this.offset, required super.child, super.key});

  final double offset;

  /// The offset of the nearest screen body (0 outside a screen).
  static double of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GzScreenScroll>()?.offset ?? 0;

  @override
  bool updateShouldNotify(GzScreenScroll oldWidget) => oldWidget.offset != offset;
}

/// What sits under the screen's bottom edge (web `BottomChromeContext`): a [GzActionBar] adds the home-indicator inset only when
/// no tab bar below already does.
class GzBottomChrome extends InheritedWidget {
  const GzBottomChrome({required this.tabBar, required super.child, super.key});

  final bool tabBar;

  static bool tabBarOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GzBottomChrome>()?.tabBar ?? false;

  @override
  bool updateShouldNotify(GzBottomChrome oldWidget) => oldWidget.tabBar != tabBar;
}

/// Registry of the pinned bottom bars of the visible screen, so a floating toast sits above them (web `BarInsetContext`).
/// The host owns one; [GzActionBar] reports its height while it is on screen.
class GzBarInsetRegistry extends ChangeNotifier {
  final Map<Object, double> _heights = {};
  bool _disposed = false;

  /// The tallest reported bar (0 when none).
  double get height => _heights.values.fold(0.0, (a, b) => a > b ? a : b);

  void report(Object key, double height) {
    if (_disposed || _heights[key] == height) return;
    _heights[key] = height;
    notifyListeners();
  }

  void clear(Object key) {
    if (_disposed) return;
    if (_heights.remove(key) != null) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class GzBarInsets extends InheritedWidget {
  const GzBarInsets({required this.registry, required super.child, super.key});

  final GzBarInsetRegistry registry;

  static GzBarInsetRegistry? maybeOf(BuildContext context) => context.getInheritedWidgetOfExactType<GzBarInsets>()?.registry;

  @override
  bool updateShouldNotify(GzBarInsets oldWidget) => oldWidget.registry != registry;
}

/// Bumped when the active tab is re-selected: the root [GzScreen] of that tab scrolls to top (ADR 0007 D5).
class GzScrollToTopSignal extends InheritedWidget {
  const GzScrollToTopSignal({required this.signal, required super.child, super.key});

  final int signal;

  static int of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GzScrollToTopSignal>()?.signal ?? 0;

  @override
  bool updateShouldNotify(GzScrollToTopSignal oldWidget) => oldWidget.signal != signal;
}
