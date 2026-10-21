import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

import 'go_router_navigator.dart';
import 'nav_providers.dart';

/// The params a page was opened with: `GzParams` in `state.extra` (empty when none).
GzParams gzParamsOf(GoRouterState state) {
  final extra = state.extra;
  return extra is Map<String, Object?> ? extra : const <String, Object?>{};
}

/// A screen page: the Ghazal push transition, and the screen's own [GzNavigator] (params, back state) for everything below it.
/// `pageBuilder: (context, state) => gzScreenPage(state, MyScreen())`. Routes that only give a `builder:` get this page from
/// `buildGzRouter`.
Page<T> gzScreenPage<T>(GoRouterState state, Widget child) => GzPage<T>(
  key: state.pageKey,
  name: gzScreenIdOf(state.name),
  child: GzEntryScope(id: gzScreenIdOf(state.name), params: gzParamsOf(state), child: child),
);

/// A sheet page: [GzSheetPage] with the same entry scope. The options of `GzNavigator.openSheet` (title, dismissible) travel in a
/// [GzSheetExtra]. A sheet that is the first route (the shot harness, a deep link) draws over the canvas and the scrim.
Page<T> gzSheetPage<T>(GoRouterState state, Widget child) {
  final extra = state.extra;
  final options = extra is GzSheetExtra ? extra : null;
  return GzSheetPage<T>(
    key: state.pageKey,
    name: gzScreenIdOf(state.name),
    title: options?.options.title,
    dismissible: options?.options.dismissible ?? true,
    scrim: options?.scrim ?? true,
    child: GzEntryScope(id: gzScreenIdOf(state.name), params: gzParamsOf(state), child: child),
  );
}

/// What a screen is told about itself: [GzNavigatorScope] with a navigator that answers `params`, `currentId`, `canGoBack` and
/// `activeTab` for THIS screen and forwards every action to the app's navigator. Also the Android back rule of the tabs: back on the
/// root of any tab but the first goes to the first tab; back on the first tab root leaves the app.
class GzEntryScope extends ConsumerWidget {
  const GzEntryScope({required this.id, required this.params, required this.child, super.key});

  final String id;
  final GzParams params;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ref.read(gzNavigatorProvider);
    final spec = base is GoRouterNavigator ? base.spec : null;
    final isFirst = ModalRoute.of(context)?.isFirst ?? true;
    final root = spec?.isTabRoot(id) ?? false;
    final sheet = spec?.isSheet(id) ?? false;
    // The web StaticFrame says `canGoBack: !root && !sheet`: a screen that is the first route (the shot harness) still draws its back
    // button, like its reference. Pop never leaves a root, so the button is inert there.
    final entry = GzEntryNavigator(base, id: id, params: params, canGoBack: !isFirst || (!root && !sheet), tabHint: spec?.chrome[id]?.tab);
    Widget content = GzNavigatorScope(navigator: entry, child: child);
    final tabIndex = spec?.tabIndexOfRoot(id) ?? -1;
    if (spec != null && tabIndex > 0) {
      content = PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) base.switchTab(spec.tabs.first.id);
        },
        child: content,
      );
    }
    return content;
  }
}

/// The navigator a screen sees: [base] for every action, the screen's own answers for `params`, `currentId`, `canGoBack`, `activeTab`.
class GzEntryNavigator implements GzNavigator {
  const GzEntryNavigator(this.base, {required this.id, required this.params, required this.canGoBack, this.tabHint});

  final GzNavigator base;
  final String id;
  final String? tabHint;

  @override
  final GzParams params;
  @override
  final bool canGoBack;

  @override
  String get currentId => id;
  @override
  String? get activeTab => base.activeTab ?? tabHint;

  @override
  void push(String id, {GzParams params = const {}}) => base.push(id, params: params);
  @override
  void pop({int count = 1}) => base.pop(count: count);
  @override
  void replace(String id, {GzParams params = const {}}) => base.replace(id, params: params);
  @override
  void reset(String id, {GzParams params = const {}}) => base.reset(id, params: params);
  @override
  void switchTab(String tabId) => base.switchTab(tabId);
  @override
  String openSheet(String screenId, {GzSheetOptions options = const GzSheetOptions()}) => base.openSheet(screenId, options: options);
  @override
  String openSheetBuilder(WidgetBuilder builder, {GzSheetOptions options = const GzSheetOptions()}) =>
      base.openSheetBuilder(builder, options: options);
  @override
  void closeSheet([String? key]) => base.closeSheet(key);
  @override
  Future<GzDialogResult> openDialog(GzDialogSpec spec) => base.openDialog(spec);
  @override
  String toast(GzToastSpec spec) => base.toast(spec);
  @override
  void dismissToast([String? key]) => base.dismissToast(key);

  @override
  bool operator ==(Object other) =>
      other is GzEntryNavigator &&
      other.base == base &&
      other.id == id &&
      other.canGoBack == canGoBack &&
      other.tabHint == tabHint &&
      identical(other.params, params);

  @override
  int get hashCode => Object.hash(base, id, canGoBack, tabHint, identityHashCode(params));
}
