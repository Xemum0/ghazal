import 'package:flutter/services.dart' show KeyDownEvent, KeyEvent, KeyRepeatEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

/// Roving-focus keyboard model shared by the segmented control, tabs and the chip group (web `rovingIndex`). Arrow keys follow what
/// the person SEES: in an RTL screen ArrowLeft goes to the next item (the first item sits at the right). Home / End jump; disabled
/// items are skipped. Returns the new index, or null when the key is not ours (or there is nowhere to go).
int? gzRovingIndex(KeyEvent e, int index, List<bool> disabled, {required bool rtl, bool vertical = true}) {
  if (e is! KeyDownEvent && e is! KeyRepeatEvent) return null;
  final k = e.logicalKey;
  var delta = 0;
  if (k == LogicalKeyboardKey.arrowRight) {
    delta = rtl ? -1 : 1;
  } else if (k == LogicalKeyboardKey.arrowLeft) {
    delta = rtl ? 1 : -1;
  } else if (k == LogicalKeyboardKey.arrowDown && vertical) {
    delta = 1;
  } else if (k == LogicalKeyboardKey.arrowUp && vertical) {
    delta = -1;
  } else if (k == LogicalKeyboardKey.home) {
    return _firstEnabled(disabled, 0, 1);
  } else if (k == LogicalKeyboardKey.end) {
    return _firstEnabled(disabled, disabled.length - 1, -1);
  } else {
    return null;
  }
  return _firstEnabled(disabled, index + delta, delta);
}

int? _firstEnabled(List<bool> disabled, int from, int step) {
  final s = step < 0 ? -1 : 1;
  for (var i = from; i >= 0 && i < disabled.length; i += s) {
    if (!disabled[i]) return i;
  }
  return null;
}

/// A list of focus nodes that lives as long as the state; grows and shrinks with the option count.
class GzFocusNodes {
  final List<FocusNode> _nodes = [];

  FocusNode operator [](int i) {
    while (_nodes.length <= i) {
      _nodes.add(FocusNode(debugLabel: 'roving${_nodes.length}'));
    }
    return _nodes[i];
  }

  int get focusedIndex => _nodes.indexWhere((n) => n.hasFocus);

  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    _nodes.clear();
  }
}
