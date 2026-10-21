// CL-AUTH-05 Biometric unlock (CA-AUTH-08). Port of CL-AUTH-05.tsx.
// Optional app lock, in surfaces of one screen: the pre-prompt SHEET offered once after the first sign-in (the method's glyph, its name,
// Turn on / Not now), the unlock SCREEN a returning person meets on launch (an arched doorway, the monogram and name, one Unlock button),
// the failed-fallback (three misses never lock the account, only the shortcut: try again, WhatsApp code, password) and the disabled
// Settings row when no biometrics are enrolled. Biometrics unlock a stored session; they never replace the first sign-in.
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/auth_actions.dart';
import '../application/auth_flow.dart';
import '../application/biometric.dart';
import 'widgets/auth_bits.dart';

enum _Mode { unlock, failedFallback, unavailable }

IconData _glyph(String method) => method == 'face' ? GzIcons.faceId : GzIcons.fingerprint;

/// The pre-prompt sheet body, opened once after the first sign-in by `finishSignIn` (`openSheetBuilder`).
Widget authBiometricPromptBuilder(BuildContext context) => const AuthBiometricSheet();

class AuthBiometricSheet extends ConsumerStatefulWidget {
  const AuthBiometricSheet({super.key});

  @override
  ConsumerState<AuthBiometricSheet> createState() => _AuthBiometricSheetState();
}

class _AuthBiometricSheetState extends ConsumerState<AuthBiometricSheet> {
  bool _busy = false;
  bool _enabled = false;

  Future<void> _turnOn() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await ref.read(biometricProvider).authenticate();
    if (!mounted) return;
    if (ok) ref.read(authFlowProvider.notifier).update((s) => s.copyWith(bioEnabled: true));
    setState(() {
      _busy = false;
      _enabled = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.gz.colors;
    final nav = context.gzNav;
    final method = ref.watch(biometricProvider).method ?? 'face';
    final name = l10n.clientAuthBioMethod(method);
    if (_enabled) {
      return GzSuccessState(
        illustration: GzIllustrationName.seal,
        title: l10n.clientAuthBioEnabledTitle,
        fill: false,
        size: GzIllustrationSize.lg,
        flush: true,
        action: GzStateAction(label: l10n.commonActionDone, onPressed: nav.closeSheet),
        secondary: GzStateAction(
          label: l10n.commonLabelSettings,
          onPressed: () => nav
            ..closeSheet()
            ..push('CL-PROF-05'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AuthEndShift(
              toStart: true,
              child: GzInfoButton(title: name, paragraphs: [l10n.clientAuthBioPromptDetail(method)]),
            ),
            const Spacer(),
            AuthEndShift(child: GzBarButton(icon: GzIcons.close, label: l10n.commonActionClose, onPressed: nav.closeSheet)),
          ],
        ),
        const SizedBox(height: GzSpace.s3),
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
            child: SizedBox(width: GzSize.illustrationMd, height: GzSize.illustrationMd, child: Center(child: GzIcon(_glyph(method), size: GzIconSize.lg, color: c.iconSecondary))),
          ),
        ),
        const SizedBox(height: GzSpace.s4),
        GzText(name, role: GzTextRole.d2, color: c.textStrong, textAlign: TextAlign.center, header: true),
        const SizedBox(height: GzSpace.s4 + GzSpace.s3),
        GzButton(label: l10n.clientAuthBioTurnOn, fullWidth: true, loading: _busy, onPressed: _turnOn),
        const SizedBox(height: GzSpace.s2),
        Center(child: GzButton(label: l10n.clientAuthSharedNotNow, variant: GzButtonVariant.tertiary, onPressed: _busy ? null : nav.closeSheet)),
      ],
    );
  }
}

class ClAuth05Screen extends ConsumerStatefulWidget {
  const ClAuth05Screen({super.key});

  @override
  ConsumerState<ClAuth05Screen> createState() => _ClAuth05State();
}

class _ClAuth05State extends ConsumerState<ClAuth05Screen> {
  late _Mode _mode;
  bool _busy = false;
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    _mode = switch (context.gzNav.params['mode']) {
      'failed-fallback' => _Mode.failedFallback,
      'unavailable' => _Mode.unavailable,
      _ => _Mode.unlock,
    };
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await ref.read(biometricProvider).authenticate();
    if (!mounted) return;
    if (ok) {
      context.gzNav.reset('CL-DISC-01');
    } else {
      setState(() {
        _busy = false;
        _mode = _Mode.failedFallback;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.gz.colors;
    final nav = context.gzNav;
    final method = ref.watch(biometricProvider).method;

    if (_mode == _Mode.unavailable || method == null) {
      return GzScreen(
        top: GzTopBar(title: l10n.commonLabelSettings, onBack: nav.pop),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
          child: GzListRow(
            title: l10n.clientAuthBioUnavailableRow,
            leading: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceQuiet),
              child: SizedBox(width: GzSize.avatarSm, height: GzSize.avatarSm, child: Center(child: GzIcon(GzIcons.faceId, size: GzIconSize.md, color: c.iconDisabled))),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzInfoButton(title: l10n.clientAuthBioUnavailableRow, paragraphs: [l10n.clientAuthBioUnavailableDetail]),
                const SizedBox(width: GzSpace.s2),
                GzSwitch(label: l10n.clientAuthBioUnavailableRow, checked: false, disabled: true),
              ],
            ),
            last: true,
          ),
        ),
      );
    }

    final failed = _mode == _Mode.failedFallback;
    final session = ref.watch(sessionProvider);
    final user = session is ClientSession ? session.user : null;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final name = (user?.name.isNotEmpty ?? false) ? user!.name : (ar ? 'ريم الدوسري' : 'Reem Al-Dosari');
    final monogram = (user?.monogram.isNotEmpty ?? false) ? user!.monogram : authMonogramFor(name);
    final glyph = _glyph(method);

    return GzScreen.slivers(
      bottom: GzActionBar(action: GzActionBarAction(label: failed ? l10n.commonActionRetry : l10n.clientAuthBioUnlock, iconEnd: glyph, loading: _busy, onPressed: _unlock)),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Semantics(
            container: true,
            label: l10n.clientAuthBioTitle,
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: MediaQuery.paddingOf(context).top, bottom: GzSpace.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: GzSpace.s16, child: Center(child: GzWordmark(size: GzWordmarkSize.md))),
                  const SizedBox(height: GzSpace.s6),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const GzIllustration(GzIllustrationName.doorway, size: GzIllustrationSize.hero),
                        const SizedBox(height: GzSpace.s6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GzAvatar(name: name, initial: monogram, size: GzAvatarSize.md),
                            const SizedBox(width: GzSpace.s3),
                            Flexible(child: GzText(name, role: GzTextRole.d2, color: c.textStrong, header: true)),
                          ],
                        ),
                        if (failed) ...[
                          const SizedBox(height: GzSpace.s6),
                          AuthInlineNote(tone: AuthNoteTone.info, icon: glyph, message: l10n.clientAuthBioFailedTitle, detail: l10n.clientAuthBioFailedDetail, detailTitle: l10n.clientAuthBioFailedTitle),
                          const SizedBox(height: GzSpace.s3),
                          GzButton(label: l10n.clientAuthSharedUseCode, variant: GzButtonVariant.secondary, iconStart: GzIcons.whatsapp, fullWidth: true, onPressed: () => nav.openSheet('CL-AUTH-01', options: const GzSheetOptions(params: <String, Object?>{'reason': 'none'}))),
                          const SizedBox(height: GzSpace.s3),
                          GzButton(label: l10n.clientAuthSharedUsePassword, variant: GzButtonVariant.tertiary, onPressed: () => nav.push('CL-AUTH-04', params: const <String, Object?>{'mode': 'signin'})),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
