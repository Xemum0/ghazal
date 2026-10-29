import 'dart:ui' show VoidCallback;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_config.dart';

/// Opens an address outside the app (the platform's browser or store). The only place the app calls the platform for a link: tests and
/// the shot harness override it with a recorder, so nothing real is launched.
typedef ExternalUrlOpener = Future<bool> Function(Uri uri);

final Provider<ExternalUrlOpener> openExternalUrlProvider = Provider<ExternalUrlOpener>(
  (ref) => (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// The Partner app's store page, from the public configuration (`AppConfig.partnerAppUrl`, OQ-R2-04); null while it loads or when none is set.
final Provider<Uri?> partnerAppUrlProvider = Provider<Uri?>((ref) {
  final raw = ref.watch(publicAppConfigProvider).value?.partnerAppUrl;
  return raw == null || raw.isEmpty ? null : Uri.tryParse(raw);
});

/// What the provider note does when it is tapped (CA-SVC-20: CL-SERV-01 footer, CL-PROF-01 row): opens the Partner app's store page. Null
/// (an inert note) until the address is known.
extension PartnerNoteAction on WidgetRef {
  VoidCallback? partnerNoteOpener() {
    final url = watch(partnerAppUrlProvider);
    if (url == null) return null;
    return () => read(openExternalUrlProvider)(url);
  }
}
