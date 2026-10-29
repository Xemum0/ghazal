import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show AuthUser, ClientSession, profileRepositoryProvider, sessionProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, localeProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show Me, Sex, UpdateMeInput;

import '../../../app/state/state.dart';

/// The account as the server has it (name in both scripts, email, phone). Refetched after an edit.
final FutureProvider<Me?> profileMeProvider = FutureProvider<Me?>((ref) async {
  ref.watch(clientDataRevisionProvider);
  if (ref.watch(clientUserIdProvider) == null) return null;
  return ref.read(profileRepositoryProvider).getMe();
});

/// The first letter of a name in its own script, ignoring a leading Arabic `ال` (ADR 0015 D4).
String profileMonogramFor(String name) {
  final first = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).firstOrNull ?? '';
  final base = first.runes.length > 2 && first.startsWith('ال') ? first.substring(2) : first;
  return base.isEmpty ? '' : String.fromCharCode(base.runes.first).toUpperCase();
}

/// Who is looking: the name in the language of the screen (Arabic UI shows the Arabic name, English the Latin spelling when there is one).
class ProfileIdentity {
  const ProfileIdentity({required this.name, required this.monogram, required this.phone, required this.email});

  final String name;
  final String monogram;

  /// E.164, display only.
  final String phone;
  final String email;
}

final Provider<ProfileIdentity?> profileIdentityProvider = Provider<ProfileIdentity?>((ref) {
  final session = ref.watch(sessionProvider);
  if (session is! ClientSession) return null;
  final me = ref.watch(profileMeProvider).value;
  final english = ref.watch(localeProvider).languageCode == 'en';
  final user = session.user;
  final latin = me?.user.nameLatin;
  final name = english && latin != null && latin.isNotEmpty ? latin : (me?.user.name ?? user.name);
  final monogram = english && latin != null && latin.isNotEmpty ? profileMonogramFor(latin) : (user.monogram.isNotEmpty ? user.monogram : profileMonogramFor(name));
  return ProfileIdentity(name: name, monogram: monogram, phone: me?.user.phone ?? user.phone, email: me?.user.email ?? user.email ?? '');
});

/// Saves the name, the sex and the optional email (CL-PROF-03, CA-AUTH-14). Returns the refusal, or null when saved; the session follows.
Future<ApiProblem?> saveProfileDetails(WidgetRef ref, {required String name, required Sex sex, required String email}) async {
  try {
    final me = await ref.read(profileRepositoryProvider).updateMe(body: UpdateMeInput(name: name, sex: sex, email: email.isEmpty ? null : email));
    final session = ref.read(sessionProvider);
    if (session is ClientSession) {
      final u = session.user;
      ref.read(sessionProvider.notifier).setSession(
        ClientSession(
          user: AuthUser(id: u.id, name: me.user.name, phone: me.user.phone, monogram: me.user.monogram.isNotEmpty ? me.user.monogram : profileMonogramFor(me.user.name), email: me.user.email),
          phoneVerified: session.phoneVerified,
        ),
      );
    }
    ref.invalidate(profileMeProvider);
    return null;
  } on ApiProblem catch (e) {
    return e;
  }
}
