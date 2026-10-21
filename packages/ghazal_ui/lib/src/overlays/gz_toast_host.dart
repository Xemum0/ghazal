import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import '../nav/gz_nav_scope.dart';
import '../nav/gz_navigator.dart';

/// A plain toast lives half the undo window (4 s); an undo toast lives exactly as long as its depleting line (8 s).
const Duration gzPlainToastDuration = Duration(milliseconds: 4000);

class _ToastEntry {
  _ToastEntry(this.key, this.spec);

  final String key;
  final GzToastSpec spec;
}

/// The one toast of the app (web `ToastHost` state): a new toast replaces the current one. Create it once (the host does) and share
/// it with a navigator adapter (`GzNavigatorBase`) or call `GzToasts.show(context, ...)`.
class GzToastController extends ChangeNotifier {
  _ToastEntry? _current;
  Timer? _timer;
  int _seq = 0;

  /// Height of the persistent bar the toast floats over (the tab bar, 56 + inset). A pinned [GzActionBar] reports its own height
  /// through [GzBarInsetRegistry] and wins while it is on screen.
  final ValueNotifier<double> bottomChrome = ValueNotifier<double>(0);

  /// The key of the toast on screen, or null.
  String? get currentKey => _current?.key;

  GzToastSpec? get currentSpec => _current?.spec;

  String show(GzToastSpec spec) {
    _timer?.cancel();
    final entry = _ToastEntry('t${++_seq}', spec);
    _current = entry;
    if (!spec.undo) _timer = Timer(gzPlainToastDuration, () => dismiss(entry.key));
    notifyListeners();
    return entry.key;
  }

  void dismiss([String? key]) {
    if (_current == null || (key != null && key.isNotEmpty && _current!.key != key)) return;
    _timer?.cancel();
    _current = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    bottomChrome.dispose();
    super.dispose();
  }
}

class GzToastScope extends InheritedWidget {
  const GzToastScope({required this.controller, required super.child, super.key});

  final GzToastController controller;

  static GzToastController? maybeOf(BuildContext context) => context.getInheritedWidgetOfExactType<GzToastScope>()?.controller;

  @override
  bool updateShouldNotify(GzToastScope oldWidget) => oldWidget.controller != controller;
}

/// The toast API: `GzToasts.show(context, message: ..., undo: true, action: GzToastAction(...))`. Needs a [GzToastHost] above the
/// context (the app installs one above the router); without one it does nothing and returns ''. (The prototype's `toast()`.)
abstract final class GzToasts {
  static String show(
    BuildContext context, {
    required String message,
    GzToastTone tone = GzToastTone.neutral,
    GzToastAction? action,
    bool undo = false,
    IconData? icon,
  }) {
    final controller = GzToastScope.maybeOf(context);
    if (controller == null) return '';
    return controller.show(GzToastSpec(message: message, tone: tone, action: action, undo: undo, icon: icon));
  }

  static void dismiss(BuildContext context, [String? key]) => GzToastScope.maybeOf(context)?.dismiss(key);
}

/// Toast host: wraps the app content and floats the one toast at the bottom, inside the gutters, 16 dp above the bar it floats over
/// (an action bar, else the tab bar, else the home-indicator inset). Enter 200 ms fade, exit 120 ms. Pass a [controller] to share it
/// with a navigator adapter; otherwise the host owns one.
class GzToastHost extends StatefulWidget {
  const GzToastHost({required this.child, this.controller, super.key});

  final Widget child;
  final GzToastController? controller;

  @override
  State<GzToastHost> createState() => _GzToastHostState();
}

class _GzToastHostState extends State<GzToastHost> {
  GzToastController? _own;
  final GzBarInsetRegistry _insets = GzBarInsetRegistry();

  GzToastController get _controller => widget.controller ?? (_own ??= GzToastController());

  @override
  void dispose() {
    _own?.dispose();
    _insets.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return GzToastScope(
      controller: controller,
      child: GzBarInsets(
        registry: _insets,
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            ListenableBuilder(
              listenable: Listenable.merge([controller, controller.bottomChrome, _insets]),
              builder: (context, _) {
                final bar = _insets.height > 0 ? _insets.height : (controller.bottomChrome.value > 0 ? controller.bottomChrome.value : safeBottom);
                return GzToastRegion(
                  barHeight: bar,
                  child: AnimatedSwitcher(
                    duration: GzReducedMotion.fade(context, GzMotion.durationBase),
                    reverseDuration: GzMotion.durationFast,
                    switchInCurve: GzMotion.easeStandard,
                    switchOutCurve: GzMotion.easeExit,
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                    layoutBuilder: (current, previous) => Stack(alignment: Alignment.bottomCenter, children: [...previous, ?current]),
                    child: _view(controller),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _view(GzToastController controller) {
    final entry = controller._current;
    if (entry == null) return const SizedBox.shrink(key: ValueKey('gz:toast.none'));
    final spec = entry.spec;
    final icon = spec.icon ??
        switch (spec.tone) {
          GzToastTone.neutral => null,
          GzToastTone.success => GzIcons.checkCircle,
          GzToastTone.danger => GzIcons.warningCircle,
        };
    if (spec.undo) {
      return GzUndoBar(
        key: ValueKey(entry.key),
        message: spec.message,
        onUndo: () {
          spec.action?.onPressed();
          controller.dismiss(entry.key);
        },
        onExpire: () => controller.dismiss(entry.key),
      );
    }
    return GzToast(
      key: ValueKey(entry.key),
      message: spec.message,
      icon: icon,
      actionLabel: spec.action?.label,
      onAction: spec.action == null
          ? null
          : () {
              spec.action!.onPressed();
              controller.dismiss(entry.key);
            },
    );
  }
}
