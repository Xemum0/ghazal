import 'package:flutter/widgets.dart';

/// A thread that follows the newest message while it is open. The first count it sees is the thread as it opened (no jump: the thread does
/// not open at its end, a web parity gap kept on purpose, see CL-MSGS-02); a later, bigger count is a message that was sent or came in, and
/// the list jumps to its end after the frame. With the real keyboard up the list is short, and a message sent from the composer used to land
/// below the fold, out of sight (simulator pass, 2026-10-26).
///
/// Use on the `State` of the thread body: hand [threadScroll] to `GzScreen.slivers(controller:)` and call [followNewest] with the row count
/// on every build of the loaded thread.
mixin FollowNewest<T extends StatefulWidget> on State<T> {
  final ScrollController threadScroll = ScrollController();
  int _shownCount = -1;

  @override
  void dispose() {
    threadScroll.dispose();
    super.dispose();
  }

  void _toEnd(int again) {
    if (!mounted || !threadScroll.hasClients) return;
    threadScroll.jumpTo(threadScroll.position.maxScrollExtent);
    if (again > 0) WidgetsBinding.instance.addPostFrameCallback((_) => _toEnd(again - 1));
  }

  void followNewest(int count) {
    final grew = _shownCount >= 0 && count > _shownCount;
    _shownCount = count;
    if (grew) WidgetsBinding.instance.addPostFrameCallback((_) => _toEnd(1));
  }
}
