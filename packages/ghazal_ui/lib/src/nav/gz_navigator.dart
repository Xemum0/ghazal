import 'package:flutter/widgets.dart';

/// Params of a screen or sheet opened by inventory id.
typedef GzParams = Map<String, Object?>;

/// Options of a sheet (web `SheetOptions`).
@immutable
class GzSheetOptions {
  const GzSheetOptions({this.params = const {}, this.title, this.dismissible = true, this.onClose});

  /// Params for a screen opened by id.
  final GzParams params;

  /// Title row (title at inline-start, close at inline-end, ADR 0014 D3). Omit when the content draws its own header.
  final String? title;

  /// Scrim tap and drag-down dismiss. False for flows that must be answered (unsaved guard).
  final bool dismissible;

  /// Called once, after the sheet has left.
  final VoidCallback? onClose;
}

enum GzDialogTone { standard, destructive }

enum GzDialogResult { confirm, cancel }

/// What a dialog says (web `DialogSpec`). Words are passed in by the caller (they come from the app's catalogue).
@immutable
class GzDialogSpec {
  const GzDialogSpec({required this.title, this.body, this.icon, this.confirmLabel, this.cancelLabel, this.showCancel = true, this.tone = GzDialogTone.standard});

  final String title;
  final String? body;
  final IconData? icon;

  /// Default: the shared "Confirm".
  final String? confirmLabel;

  /// Default: the shared "Cancel".
  final String? cancelLabel;

  /// False: an acknowledgement, one button (web `cancelLabel: null`).
  final bool showCancel;
  final GzDialogTone tone;
}

enum GzToastTone { neutral, success, danger }

@immutable
class GzToastAction {
  const GzToastAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// What a toast says (web `ToastSpec`).
@immutable
class GzToastSpec {
  const GzToastSpec({required this.message, this.tone = GzToastTone.neutral, this.action, this.undo = false, this.icon});

  final String message;
  final GzToastTone tone;

  /// A single action (View). 44 hit target, gold on ink.
  final GzToastAction? action;

  /// Undo bar: the 2 dp gold line depletes over the undo token (8 s) and the toast stays that long; [action] runs on Undo.
  final bool undo;
  final IconData? icon;
}

/// The navigator contract of both apps (web `useNav()` / `NavApi`, `design/src/system/nav/types.ts`). Screens receive nothing but
/// params and this interface; the app's go_router adapter implements it (`GzNavigatorBase` does the overlay half).
///
/// Mapping to go_router (the integrator's adapter):
/// - [push] = `context.pushNamed(id, extra: params)` on the active tab's navigator;
/// - [pop] = `pop` [count] times, never below a root; [replace] = `replaceNamed`;
/// - [reset] = `goNamed(id)` and drop every stack (end of onboarding, sign-out); a tab root re-enters the tab host;
/// - [switchTab] = `StatefulNavigationShell.goBranch(index, initialLocation: index == currentIndex)`: re-selecting the active tab
///   pops it to its root AND bumps [GzScrollToTopSignal] (ADR 0007 D5);
/// - sheets, dialogs and toasts are routes/overlays of the root navigator (`showGzSheet`, `showGzDialog`, `GzToasts`).
///
/// Every call is safe to make when a screen is drawn outside the app (a static frame, a gallery): see [GzInertNavigator].
abstract interface class GzNavigator {
  /// A screen above the current one exists in this stack.
  bool get canGoBack;

  /// Params of the screen (or sheet) the scope is attached to.
  GzParams get params;

  /// Inventory id of that screen.
  String get currentId;

  /// The active tab id, or null outside the tab host (onboarding, static frames).
  String? get activeTab;

  /// Push a screen by inventory id onto the active stack (forward transition).
  void push(String id, {GzParams params = const {}});

  /// Pop [count] screens (default 1); never pops a root.
  void pop({int count = 1});

  /// Replace the top of the active stack (cross-fade).
  void replace(String id, {GzParams params = const {}});

  /// Reset the whole navigator to one screen.
  void reset(String id, {GzParams params = const {}});

  /// Activate a tab; re-selecting the active tab pops it to its root and scrolls it to top.
  void switchTab(String tabId);

  /// Open a screen of the registry as a sheet. Returns the sheet key.
  String openSheet(String screenId, {GzSheetOptions options = const GzSheetOptions()});

  /// Open a widget as a sheet. Returns the sheet key.
  String openSheetBuilder(WidgetBuilder builder, {GzSheetOptions options = const GzSheetOptions()});

  /// Close the top sheet, or the one with this key.
  void closeSheet([String? key]);

  /// Open a dialog; resolves with the choice (a back press or a scrim-less dismissal answers [GzDialogResult.cancel]).
  Future<GzDialogResult> openDialog(GzDialogSpec spec);

  /// Show a toast (or the undo bar). Returns its key.
  String toast(GzToastSpec spec);
  void dismissToast([String? key]);
}

/// Every call does nothing (web `INERT_NAV`): a screen is the same code in a static frame and in the app.
class GzInertNavigator implements GzNavigator {
  const GzInertNavigator();

  @override
  bool get canGoBack => false;
  @override
  GzParams get params => const {};
  @override
  String get currentId => '';
  @override
  String? get activeTab => null;
  @override
  void push(String id, {GzParams params = const {}}) {}
  @override
  void pop({int count = 1}) {}
  @override
  void replace(String id, {GzParams params = const {}}) {}
  @override
  void reset(String id, {GzParams params = const {}}) {}
  @override
  void switchTab(String tabId) {}
  @override
  String openSheet(String screenId, {GzSheetOptions options = const GzSheetOptions()}) => '';
  @override
  String openSheetBuilder(WidgetBuilder builder, {GzSheetOptions options = const GzSheetOptions()}) => '';
  @override
  void closeSheet([String? key]) {}
  @override
  Future<GzDialogResult> openDialog(GzDialogSpec spec) => Future<GzDialogResult>.value(GzDialogResult.cancel);
  @override
  String toast(GzToastSpec spec) => '';
  @override
  void dismissToast([String? key]) {}
}

/// Installs a [GzNavigator] for a subtree. [of] never returns null: outside a scope it is the inert navigator.
class GzNavigatorScope extends InheritedWidget {
  const GzNavigatorScope({required this.navigator, required super.child, super.key});

  final GzNavigator navigator;

  static GzNavigator of(BuildContext context) => maybeOf(context) ?? const GzInertNavigator();

  static GzNavigator? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GzNavigatorScope>()?.navigator;

  @override
  bool updateShouldNotify(GzNavigatorScope oldWidget) => oldWidget.navigator != navigator;
}
