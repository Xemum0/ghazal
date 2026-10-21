import 'package:flutter/foundation.dart';
import 'package:ghazal_ui/ghazal_ui.dart' show GzAppKind;

/// Where a screen lives in the chrome (ported from `chromeFor` / `SHEET_SCREENS` of `design/src/system/nav/tabs.ts` by
/// `tools/gen-routes.mjs`, which checks the port against the TypeScript on every run).
@immutable
class GzScreenChrome {
  const GzScreenChrome({this.tab, this.tabBar = false, this.sheet = false});

  /// The tab that owns the screen (null: outside the tabs, such as onboarding, auth, access).
  final String? tab;

  /// The tab bar shows under the screen.
  final bool tabBar;

  /// The screen opens over another one as a sheet.
  final bool sheet;

  /// The screen lives inside its tab's branch (the bar stays, the branch keeps its stack). Everything else goes above the bar.
  bool get inBranch => !sheet && tabBar && tab != null;
}

/// One main tab: its id and the inventory id of its root screen.
@immutable
class GzTabSpec {
  const GzTabSpec(this.id, this.rootScreen);

  final String id;
  final String rootScreen;
}

/// Everything the router composition needs to know about an app (generated into `lib/app/app_router.dart` from the screen registry).
@immutable
class GzRouterSpec {
  const GzRouterSpec({
    required this.app,
    required this.tabs,
    required this.chrome,
    required this.paths,
    required this.startPath,
    required this.homePath,
    this.requireSession = false,
    this.publicPrefixes = const <String>[],
  });

  final GzAppKind app;

  /// Main tabs in inventory order (the bar mirrors in RTL; the order never changes).
  final List<GzTabSpec> tabs;

  /// Chrome per inventory id.
  final Map<String, GzScreenChrome> chrome;

  /// Router path per inventory id.
  final Map<String, String> paths;

  /// Location of a first start (onboarding for the client, access for the partner).
  final String startPath;

  /// Location of the first tab root: where a signed-in (or already onboarded) person starts.
  final String homePath;

  /// A signed-out person may only see [publicPrefixes] (the partner app: access flow). The client app is open to guests (ADR 0007).
  final bool requireSession;
  final List<String> publicPrefixes;

  int tabIndexOf(String tabId) => tabs.indexWhere((t) => t.id == tabId);

  /// Index of the tab whose root screen is [screenId], or -1.
  int tabIndexOfRoot(String screenId) => tabs.indexWhere((t) => t.rootScreen == screenId);

  bool isTabRoot(String screenId) => tabIndexOfRoot(screenId) >= 0;

  bool isSheet(String screenId) => chrome[screenId]?.sheet ?? false;
}
