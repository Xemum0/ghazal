import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

import 'nav_spec.dart';

/// Suffix of the root-level twin of a route that normally lives inside a tab branch: `CL-RVRW-01@root` is the same screen on the root
/// navigator (above the tab bar). [GoRouterNavigator.push] uses it when a screen above the bar is on top, because go_router cannot
/// push a branch route over a root-level page (the shell would be mounted twice).
const String kRootRouteSuffix = '@root';

/// Path prefix of those twins.
const String kRootPathPrefix = '/__root';

/// The inventory id behind a route name (strips [kRootRouteSuffix]).
String gzScreenIdOf(String? routeName) {
  final name = routeName ?? '';
  return name.endsWith(kRootRouteSuffix) ? name.substring(0, name.length - kRootRouteSuffix.length) : name;
}

/// Carries the options of a sheet opened by id (`openSheet`) to `gzSheetPage` through `GoRouterState.extra`, while still being the
/// plain `GzParams` map the screen reads.
class GzSheetExtra extends MapView<String, Object?> {
  GzSheetExtra(this.options, {this.scrim = true}) : super(options.params);

  final GzSheetOptions options;

  /// False for a sheet opened over another sheet (one scrim only).
  final bool scrim;
}

class _OpenSheet {
  _OpenSheet(this.key, {required this.viaRouter});

  final String key;
  final bool viaRouter;
}

/// The go_router adapter of [GzNavigator] (contract: `ghazal_ui` nav group). It owns the stack half; [GzNavigatorBase] does sheets,
/// dialogs and toasts on the root navigator.
///
/// Semantics ported from the prototype's `NavRoot` (`design/src/system/nav/NavProvider.tsx`):
/// - [push]: the new page goes on the ACTIVE tab's stack (go_router merges a branch route pushed from another branch into the current
///   one), screens that hide the bar and sheets go above the bar on the root navigator; pushing a tab root enters that tab at its root;
/// - [pop]: [count] screens, never below a root; [replace]: the top of the active stack;
/// - [reset]: one screen, every other tab stack dropped (a tab whose stack is dropped shows its root the next time it is selected);
/// - [switchTab]: restores the tab's stack; re-selecting the active tab pops it to its root and bumps its scroll-to-top signal.
class GoRouterNavigator extends GzNavigatorBase {
  GoRouterNavigator({required this.router, required this.spec, required super.toasts}) : super(navigatorKey: router.routerDelegate.navigatorKey) {
    scrollSignals = <ValueNotifier<int>>[for (final _ in spec.tabs) ValueNotifier<int>(0)];
  }

  final GoRouter router;
  final GzRouterSpec spec;

  /// One counter per tab (bumped when the active tab is re-selected); the tab shell hands each to its branch as a [GzScrollToTopSignal].
  late final List<ValueNotifier<int>> scrollSignals;

  StatefulNavigationShell? _shell;
  final Set<int> _stale = <int>{};
  final List<_OpenSheet> _sheets = <_OpenSheet>[];
  int _sheetSeq = 0;

  /// Called by the tab shell on every build: the shell that `switchTab` drives. [detachShell] when it leaves.
  void attachShell(StatefulNavigationShell shell) => _shell = shell;

  void detachShell(StatefulNavigationShell shell) {
    if (identical(_shell, shell)) _shell = null;
  }

  // ---------------------------------------------------------------- reading the stack

  List<RouteMatchBase> get _matches => router.routerDelegate.currentConfiguration.matches;

  /// True while a screen above the bar (hidden-bar screen, sheet, a page pushed over them) covers a mounted tab shell.
  bool get tabBarCovered => _rootPageOverShell;

  bool get _rootPageOverShell {
    final matches = _matches;
    return matches.isNotEmpty && matches.any((m) => m is ShellRouteMatch) && matches.last is! ShellRouteMatch;
  }

  /// True when removing [removed] top-level matches would leave a root-level page above the shell.
  bool _rootPageOverShellAfter(int removed) {
    final matches = _matches;
    if (!matches.any((m) => m is ShellRouteMatch) || matches.length <= removed) return false;
    return matches[matches.length - 1 - removed] is! ShellRouteMatch;
  }

  @override
  bool get canGoBack => router.canPop();

  @override
  GzParams get params {
    final extra = router.routerDelegate.currentConfiguration.extra;
    return extra is Map<String, Object?> ? extra : const <String, Object?>{};
  }

  @override
  String get currentId {
    final matches = router.routerDelegate.currentConfiguration;
    if (matches.isEmpty) return '';
    return gzScreenIdOf(matches.last.route.name);
  }

  @override
  String? get activeTab {
    final shell = _shell;
    if (shell == null) return null;
    final index = shell.currentIndex;
    return index >= 0 && index < spec.tabs.length ? spec.tabs[index].id : null;
  }

  // ---------------------------------------------------------------- stack operations

  @override
  void push(String id, {GzParams params = const {}}) {
    if (spec.isTabRoot(id)) {
      _enter(id, params);
      return;
    }
    final chrome = spec.chrome[id];
    final branchRoute = chrome != null && chrome.inBranch;
    final name = branchRoute && _rootPageOverShell ? '$id$kRootRouteSuffix' : id;
    unawaited(router.pushNamed<Object?>(name, extra: params));
  }

  @override
  void pop({int count = 1}) {
    for (var i = 0; i < (count < 1 ? 1 : count); i++) {
      if (!router.canPop()) return;
      router.pop();
    }
  }

  /// Takes the screens at the top of the stack whose id satisfies [test] off it AT ONCE (the sign-in screens and the gate sheet after a
  /// sign-in), so the next `push` is made against the stack that is really left. [pop] cannot do this: go_router removes a popped page from
  /// its configuration only after the page's exit animation, so `pop(); push()` in one go pushes onto the pages that were just popped and
  /// they come back under the new screen. Only imperative pages (pushed screens and sheets) are removed, never the last one. Returns how
  /// many were dropped; their `push` futures complete (a sheet's `onClose` runs).
  int popWhile(bool Function(String id) test) {
    final delegate = router.routerDelegate;
    var list = delegate.currentConfiguration;
    final dropped = <ImperativeRouteMatch>[];
    while (list.matches.length > 1) {
      final top = list.matches.last;
      if (top is! ImperativeRouteMatch || !test(gzScreenIdOf(top.route.name))) break;
      list = list.remove(top);
      dropped.add(top);
    }
    if (dropped.isEmpty) return 0;
    delegate.currentConfiguration = list;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    delegate.notifyListeners();
    for (final match in dropped) {
      match.complete(null);
    }
    return dropped.length;
  }

  @override
  void replace(String id, {GzParams params = const {}}) {
    if (spec.isTabRoot(id)) {
      _enter(id, params);
      return;
    }
    final chrome = spec.chrome[id];
    final branchRoute = chrome != null && chrome.inBranch;
    final name = branchRoute && _rootPageOverShellAfter(1) ? '$id$kRootRouteSuffix' : id;
    unawaited(router.replaceNamed<Object?>(name, extra: params));
  }

  @override
  void reset(String id, {GzParams params = const {}}) {
    _enter(id, params, dropOtherStacks: true);
  }

  /// `go` to [id]; with [dropOtherStacks] every other tab shows its root the next time it is selected (the prototype's `reset`).
  void _enter(String id, GzParams params, {bool dropOtherStacks = false}) {
    final chrome = spec.chrome[id];
    final branch = spec.isTabRoot(id) ? spec.tabIndexOfRoot(id) : (chrome != null && chrome.inBranch ? spec.tabIndexOf(chrome.tab!) : -1);
    if (dropOtherStacks) {
      _stale
        ..clear()
        ..addAll(<int>[
          for (var i = 0; i < spec.tabs.length; i++)
            if (i != branch) i,
        ]);
    }
    _stale.remove(branch);
    router.goNamed(id, extra: params);
  }

  @override
  void switchTab(String tabId) {
    final index = spec.tabIndexOf(tabId);
    if (index < 0) return;
    final shell = _shell;
    if (shell == null) {
      router.goNamed(spec.tabs[index].rootScreen);
      return;
    }
    final active = shell.currentIndex == index && !_rootPageOverShell;
    final fresh = active || _stale.remove(index);
    shell.goBranch(index, initialLocation: fresh);
    if (active) scrollSignals[index].value++;
  }

  // ---------------------------------------------------------------- sheets (screens go through the router, widgets through the base)

  @override
  Widget buildScreen(String id, GzParams params) => const SizedBox.shrink(); // never used: openSheet is routed, see below

  @override
  String openSheet(String screenId, {GzSheetOptions options = const GzSheetOptions()}) {
    final key = 'r${++_sheetSeq}'; // the base numbers its own sheets s1, s2 ...: never share a key
    final scrim = _sheets.isEmpty;
    _sheets.add(_OpenSheet(key, viaRouter: true));
    router.pushNamed<Object?>(screenId, extra: GzSheetExtra(options, scrim: scrim)).whenComplete(() {
      _sheets.removeWhere((s) => s.key == key);
      options.onClose?.call();
    });
    return key;
  }

  @override
  String openSheetBuilder(WidgetBuilder builder, {GzSheetOptions options = const GzSheetOptions()}) {
    late final String key;
    key = super.openSheetBuilder(
      builder,
      options: GzSheetOptions(
        params: options.params,
        title: options.title,
        dismissible: options.dismissible,
        onClose: () {
          _sheets.removeWhere((s) => s.key == key);
          options.onClose?.call();
        },
      ),
    );
    if (key.isNotEmpty) _sheets.add(_OpenSheet(key, viaRouter: false));
    return key;
  }

  @override
  void closeSheet([String? key]) {
    final target = (key == null || key.isEmpty) ? _sheets.lastOrNull : _sheets.where((s) => s.key == key).firstOrNull;
    if (target == null) return;
    if (target.viaRouter) {
      if (router.canPop()) router.pop();
    } else {
      super.closeSheet(target.key);
    }
  }
}
