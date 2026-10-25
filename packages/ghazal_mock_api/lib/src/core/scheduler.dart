/// Delayed work of the mock (the payment gateway answering, the scripted chat replies). With [autoRun] the tasks fire on real timers, which is
/// what makes the demo feel alive; tests use [flush] to run everything pending at once, in due order, without waiting.
library;

import 'dart:async';

class _Task {
  _Task(this.id, this.due, this.run);
  final int id;
  final Duration due;
  final FutureOr<void> Function() run;
  Timer? timer;
}

class Scheduler {
  Scheduler({this.autoRun = true});

  /// Fire tasks on real timers. When false they wait for [flush].
  bool autoRun;

  final _tasks = <_Task>[];
  var _seq = 0;

  int get pending => _tasks.length;

  /// Run [task] after [delay] (real time when [autoRun], otherwise on [flush]).
  void after(Duration delay, FutureOr<void> Function() task) {
    final t = _Task(_seq++, delay, task);
    _tasks.add(t);
    if (autoRun) {
      t.timer = Timer(delay, () async {
        if (_tasks.remove(t)) await t.run();
      });
    }
  }

  /// Runs every pending task now, shortest delay first, including tasks the tasks schedule (bounded to 100 rounds).
  Future<void> flush() async {
    for (var round = 0; round < 100 && _tasks.isNotEmpty; round++) {
      final batch = [..._tasks]
        ..sort((a, b) {
          final c = a.due.compareTo(b.due);
          return c != 0 ? c : a.id.compareTo(b.id);
        });
      _tasks.clear();
      for (final t in batch) {
        t.timer?.cancel();
        await t.run();
      }
    }
  }

  void clear() {
    for (final t in _tasks) {
      t.timer?.cancel();
    }
    _tasks.clear();
  }
}
