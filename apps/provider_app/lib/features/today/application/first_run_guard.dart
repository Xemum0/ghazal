// The two first-run sheets of Today (notifications, then app lock) open ONCE per run of the app, however many times Today is built.
//
// Why a guard: Today is built more than once right after sign-in (the router's own landing and the explicit landing both build it, and the
// outgoing one is still mounted for a frame). Every build of Today read the live `firstRun` param, so on a phone each one opened its own
// "Allow notifications" sheet: two stacked sheets, the first of them never answered, which then covered the tab bar. The guard hands the
// right to open the sheets to the first caller only; it lives in the app's container, so a new run of the app (or a test) starts fresh.
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds whether the first-run sheets were already opened in this container. Not reactive on purpose: nothing draws from it.
final class FirstRunGuard {
  bool _claimed = false;

  /// True for the first caller only.
  bool claim() {
    if (_claimed) return false;
    _claimed = true;
    return true;
  }
}

final Provider<FirstRunGuard> firstRunGuardProvider = Provider<FirstRunGuard>((ref) => FirstRunGuard());
