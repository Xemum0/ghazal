import 'package:flutter/widgets.dart';

import '../foundation.dart';
import '../overlays/gz_dialog.dart';
import '../overlays/gz_sheet.dart';
import '../overlays/gz_toast_host.dart';
import 'gz_navigator.dart';

/// The overlay half of a [GzNavigator], done once: sheets, dialogs and toasts on the root navigator behind [navigatorKey] and the
/// shared [GzToastController]. The app's go_router adapter extends this and implements the stack half ([push], [pop], [replace],
/// [reset], [switchTab], [canGoBack], [params], [currentId], [activeTab]) plus [buildScreen] (inventory id to widget, for
/// `openSheet('CL-DISC-02')`), which keeps the adapter thin.
abstract class GzNavigatorBase implements GzNavigator {
  GzNavigatorBase({required this.navigatorKey, required this.toasts});

  /// The root navigator (`GoRouter(navigatorKey: ...)`).
  final GlobalKey<NavigatorState> navigatorKey;
  final GzToastController toasts;

  /// The screen of an inventory id, built for a sheet with its [params].
  Widget buildScreen(String id, GzParams params);

  final Map<String, GzSheetRoute<void>> _sheets = <String, GzSheetRoute<void>>{};
  int _seq = 0;

  @override
  String openSheet(String screenId, {GzSheetOptions options = const GzSheetOptions()}) =>
      openSheetBuilder((context) => buildScreen(screenId, options.params), options: options);

  @override
  String openSheetBuilder(WidgetBuilder builder, {GzSheetOptions options = const GzSheetOptions()}) {
    final nav = navigatorKey.currentState;
    final context = navigatorKey.currentContext;
    if (nav == null || context == null) return '';
    final key = 's${++_seq}';
    final route = GzSheetRoute<void>(
      builder: builder,
      title: options.title,
      dismissible: options.dismissible,
      scrim: _sheets.isEmpty,
      closeLabel: context.gzL10n.commonActionClose,
      settings: RouteSettings(name: 'sheet:$key'),
    );
    _sheets[key] = route;
    nav.push<void>(route).whenComplete(() {
      _sheets.remove(key);
      options.onClose?.call();
    });
    return key;
  }

  @override
  void closeSheet([String? key]) {
    final route = (key == null || key.isEmpty) ? (_sheets.isEmpty ? null : _sheets.values.last) : _sheets[key];
    if (route == null) return;
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    if (route.isCurrent) {
      nav.pop();
    } else if (route.isActive) {
      nav.removeRoute(route);
    }
  }

  @override
  Future<GzDialogResult> openDialog(GzDialogSpec spec) {
    final context = navigatorKey.currentContext;
    if (context == null) return Future<GzDialogResult>.value(GzDialogResult.cancel);
    return showGzDialog(context, spec);
  }

  @override
  String toast(GzToastSpec spec) => toasts.show(spec);

  @override
  void dismissToast([String? key]) => toasts.dismiss(key);
}
