import 'dart:async';

import 'package:flutter/foundation.dart' show Listenable, VoidCallback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GoRouterNavigator, goRouterNavigatorProvider, sessionProvider;
import 'package:ghazal_ui/ghazal_ui.dart' show GzNavigator;

/// A sheet the app raises by itself (nobody tapped for it): the Brief merge and the biometric offer after a sign-in. It is a request to
/// the [SheetQueue], which opens it at a calm moment and never over another sheet.
class QueuedSheet {
  const QueuedSheet({
    required this.id,
    required this.open,
    this.worthShowing,
    this.delay = Duration.zero,
    this.screen,
  });

  /// One per sheet: asking twice (a sign-in and a Home that mounts) is one sheet, and it opens once per run of the app.
  final String id;

  /// Opens the sheet on [nav] and returns its key (empty when nothing opened). [onClose] must run after the sheet has left.
  final String Function(GzNavigator nav, VoidCallback onClose) open;

  /// Asked just before opening, when the moment is calm: false drops the request (the two Briefs no longer differ, the offer was made).
  final FutureOr<bool> Function()? worthShowing;

  /// How long the calm moment must hold before the sheet opens (the web `setTimeout` of the prototype: 400 ms the merge, 900 ms the offer).
  final Duration delay;

  /// The one screen the sheet belongs to (the Brief merge: Home); null: any calm screen.
  final String? screen;
}

/// What the queue holds, for tests and the Demo tools.
class SheetQueueState {
  const SheetQueueState({this.waiting = const <String>[], this.showing});

  final List<String> waiting;
  final String? showing;
}

/// Screens where a sheet the person did not ask for would land on work in progress: the checkout (the explainer, the methods, the bank
/// page, the outcome) and the request steps. The payment success (`CL-PAYM-05`) is the calm moment after them.
bool sheetQueueBusyScreen(String id) {
  if (id.startsWith('CL-PAYM-')) return id != 'CL-PAYM-05';
  if (id.startsWith('CL-BOOK-0')) return id.length == 10 && '12345'.contains(id[9]);
  return false;
}

/// The one door for sheets the app opens on its own: they open **one at a time**, in the order they were asked, each at a calm
/// moment (the screen it belongs to is the visible one, no sheet is open, no checkout or request step is on screen) and after its own
/// delay; the next waits for the sheet before it to leave. A sheet whose moment does not come simply waits (the Brief merge waits for
/// Home, the offer for the first calm screen, which after a gate sign-in is the screen after the payment explainer was closed or paid).
///
/// The prototype opens both from the screen they belong to (`design/src/screens/client/discover/CL-DISC-01.tsx` the merge, only when
/// Home is the visible screen; `auth/_components/flow.ts` the offer 900 ms after the sign-in lands) and stacks them over whatever else
/// is open, including the resumed voucher sheet; the app does not stack.
final NotifierProvider<SheetQueue, SheetQueueState> sheetQueueProvider = NotifierProvider<SheetQueue, SheetQueueState>(SheetQueue.new);

class SheetQueue extends Notifier<SheetQueueState> {
  static const Duration _recheck = Duration(milliseconds: 600);

  final List<QueuedSheet> _waiting = <QueuedSheet>[];
  final Set<String> _opened = <String>{};
  String? _showing;
  Timer? _timer;
  String? _timerFor;
  Timer? _retry;
  Listenable? _routes;
  bool _disposed = false;

  @override
  SheetQueueState build() {
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
      _retry?.cancel();
      _routes?.removeListener(_evaluate);
    });
    // a sign-out ends what was promised to that person
    ref.listen(sessionProvider, (_, next) {
      if (!next.isSignedIn) _clear();
    });
    return const SheetQueueState();
  }

  /// Asks for [sheet] (once per [QueuedSheet.id] for the run of the app).
  void enqueue(QueuedSheet sheet) {
    if (_disposed || _opened.contains(sheet.id) || _showing == sheet.id || _waiting.any((w) => w.id == sheet.id)) return;
    _waiting.add(sheet);
    _publish();
    final nav = ref.read(goRouterNavigatorProvider);
    _routes ??= nav.router.routerDelegate..addListener(_evaluate);
    _evaluate();
  }

  void _clear() {
    _waiting.clear();
    _timer?.cancel();
    _retry?.cancel();
    _timerFor = null;
    _publish();
  }

  void _publish() => state = SheetQueueState(waiting: <String>[for (final w in _waiting) w.id], showing: _showing);

  bool _sheetOpen(GoRouterNavigator nav) => nav.hasOpenSheet || nav.spec.isSheet(nav.currentId);

  bool _eligible(QueuedSheet sheet, GoRouterNavigator nav) {
    final id = nav.currentId;
    if (id.isEmpty || _sheetOpen(nav) || sheetQueueBusyScreen(id)) return false;
    return sheet.screen == null || sheet.screen == id;
  }

  /// Looks at what is on screen and, if the first waiting sheet whose moment has come is not already counting down, starts its delay.
  /// Called when the router changes, when a sheet leaves, and while a sheet that is not the queue's holds the screen.
  void _evaluate() {
    if (_disposed || _showing != null || _waiting.isEmpty) return;
    final nav = ref.read(goRouterNavigatorProvider);
    QueuedSheet? next;
    for (final w in _waiting) {
      if (_eligible(w, nav)) {
        next = w;
        break;
      }
    }
    if (next == null) {
      _timer?.cancel();
      _timerFor = null;
      // a sheet closing does not change the router: look again soon while one is open
      if (_sheetOpen(nav)) {
        _retry?.cancel();
        _retry = Timer(_recheck, _evaluate);
      }
      return;
    }
    if (_timerFor == next.id) return;
    _timer?.cancel();
    final chosen = next;
    _timerFor = chosen.id;
    _timer = Timer(chosen.delay, () => _fire(chosen));
  }

  Future<void> _fire(QueuedSheet sheet) async {
    _timer = null;
    _timerFor = null;
    if (_disposed || !_waiting.contains(sheet)) return;
    final worth = await (sheet.worthShowing?.call() ?? true);
    if (_disposed || _showing != null || !_waiting.contains(sheet)) return;
    if (!worth) {
      _waiting.remove(sheet);
      _publish();
      _evaluate();
      return;
    }
    final nav = ref.read(goRouterNavigatorProvider);
    if (!_eligible(sheet, nav)) {
      _evaluate();
      return;
    }
    _waiting.remove(sheet);
    _opened.add(sheet.id);
    _showing = sheet.id;
    _publish();
    final key = sheet.open(nav, _closed);
    if (key.isEmpty) _closed();
  }

  void _closed() {
    if (_disposed) return;
    _showing = null;
    _publish();
    _evaluate();
  }
}
