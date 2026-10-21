import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True when the device has no connection. The first-start screens are bundled and work offline, but the sign-in link needs a connection
/// and says so. No connectivity source exists in the kit yet (requests.md): this stays false until the integrator binds it
/// (`obdOfflineProvider.overrideWithValue(...)`); tests and the offline frame override it.
final Provider<bool> obdOfflineProvider = Provider<bool>((ref) => false);
