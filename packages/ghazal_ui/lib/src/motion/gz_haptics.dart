/// Kinds of haptic feedback a component can ask for.
enum GzHapticKind { none, selection, light, medium, success, warning }

/// Haptic hook. ghazal_ui never imports the services channel: the app installs a handler once in bootstrap
/// (`GzHaptics.handler = (kind) => ...HapticFeedback...`). The default does nothing, so tests and the harness stay silent.
abstract final class GzHaptics {
  static void Function(GzHapticKind kind) handler = _none;

  static void fire(GzHapticKind kind) {
    if (kind != GzHapticKind.none) handler(kind);
  }

  static void _none(GzHapticKind kind) {}
}
