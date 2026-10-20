/// Headless screenshot harness and test helpers. This is the verification channel of the whole project (ADR 0036 item 7):
/// real fonts, the prototype's device chrome, a bounded settle, PNGs at the prototype's scale.
library;

export 'package:flutter_riverpod/misc.dart' show Override;
export 'src/device_chrome.dart';
export 'src/fonts.dart';
export 'src/harness.dart';
export 'src/shot_suite.dart';
