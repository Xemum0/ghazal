import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_mock_api/ghazal_mock_api.dart' show Scenario;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../data/mock_backend.dart';
import 'demo_control.dart';

/// The content of the demo tools sheet (`GzDemoTools` opens it as a sheet with the title row): story, persona, scenario, clock,
/// language and digits, and the backend mode. Dev builds only.
class GzDemoToolsSheet extends ConsumerWidget {
  const GzDemoToolsSheet({super.key});

  static String personaLabel(GzL10n l, String key) => switch (key) {
        'guest' => l.uiKitDemoPersonaGuest,
        'new_client' => l.uiKitDemoPersonaNewClient,
        'reem' => l.uiKitDemoPersonaReem,
        'hotel_manager' => l.uiKitDemoPersonaHotelManager,
        'hotel_admin' => l.uiKitDemoPersonaHotelAdmin,
        'provider' => l.uiKitDemoPersonaProvider,
        _ => key,
      };

  static String scenarioLabel(GzL10n l, String key) => switch (key) {
        Scenario.slow => l.uiKitDemoScenarioSlow,
        Scenario.error => l.uiKitDemoScenarioError,
        Scenario.offline => l.uiKitDemoScenarioOffline,
        Scenario.empty => l.uiKitDemoScenarioEmpty,
        Scenario.expired => l.uiKitDemoScenarioExpired,
        _ => l.uiKitDemoScenarioNone,
      };

  static String pointLabel(GzL10n l, String key) => switch (key) {
        'pending' => l.uiKitDemoPointPending,
        'approved' => l.uiKitDemoPointApproved,
        'confirmed' => l.uiKitDemoPointConfirmed,
        'redeemed' => l.uiKitDemoPointRedeemed,
        'completed' => l.uiKitDemoPointCompleted,
        'declined' => l.uiKitDemoPointDeclined,
        'expired' => l.uiKitDemoPointExpired,
        'lapsed' => l.uiKitDemoPointLapsed,
        'cancelled' => l.uiKitDemoPointCancelled,
        'counter_offer' => l.uiKitDemoPointCounterOffer,
        _ => key,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.gzL10n;
    final demo = ref.watch(demoProvider);
    final notifier = ref.read(demoProvider.notifier);
    final format = ref.watch(gzFormatProvider);
    final locale = ref.watch(localeProvider);
    final digits = ref.watch(digitStyleProvider);
    final env = ref.watch(appEnvProvider);
    final mock = ref.watch(mockBackendProvider);

    Widget section(String title, Widget body) => Padding(
          padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GzText(title, role: GzTextRole.uiTitle),
              const SizedBox(height: GzSpace.s2),
              body,
            ],
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(GzSpace.s4, GzSpace.s2, GzSpace.s4, GzSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          section(
            l.uiKitDemoModeTitle,
            GzText(
              mock != null ? l.uiKitDemoModeInProcess : l.uiKitDemoModeRemote(env.apiBaseUrl),
              role: GzTextRole.bodyS,
              color: context.gz.colors.textSecondary,
            ),
          ),
          section(
            l.uiKitDemoStoryTitle,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GzButton(label: l.uiKitDemoReset, variant: GzButtonVariant.secondary, onPressed: notifier.resetStory),
                const SizedBox(height: GzSpace.s3),
                GzChipGroup<String>(
                  label: l.uiKitDemoJumpTitle,
                  value: demo.point,
                  options: [for (final p in kDemoStoryPoints) GzChipOption(value: p, label: pointLabel(l, p))],
                  onChanged: (v) => v == null ? null : notifier.jumpTo(v),
                ),
              ],
            ),
          ),
          section(
            l.uiKitDemoPersonaTitle,
            GzChipGroup<String>(
              label: l.uiKitDemoPersonaTitle,
              value: demo.persona,
              options: [for (final p in kDemoPersonas) GzChipOption(value: p, label: personaLabel(l, p))],
              onChanged: (v) => v == null ? null : notifier.switchPersona(v),
            ),
          ),
          section(
            l.uiKitDemoScenarioTitle,
            GzChipGroup<String>(
              label: l.uiKitDemoScenarioTitle,
              value: demo.scenario,
              options: [for (final s in kDemoScenarios) GzChipOption(value: s, label: scenarioLabel(l, s))],
              onChanged: (v) => v == null ? null : notifier.forceScenario(v),
            ),
          ),
          section(
            l.uiKitDemoClockTitle,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (demo.storyNow != null)
                  GzText(l.uiKitDemoClockNow(format.dateTime(demo.storyNow!)), role: GzTextRole.bodyS, color: context.gz.colors.textSecondary, figures: true),
                const SizedBox(height: GzSpace.s2),
                Wrap(
                  spacing: GzSpace.s2,
                  runSpacing: GzSpace.s2,
                  children: [
                    GzButton(label: l.uiKitDemoAdvanceHour, variant: GzButtonVariant.secondary, onPressed: () => notifier.advance(const Duration(hours: 1))),
                    GzButton(label: l.uiKitDemoAdvanceDay, variant: GzButtonVariant.secondary, onPressed: () => notifier.advance(const Duration(hours: 24))),
                  ],
                ),
              ],
            ),
          ),
          section(
            l.uiKitDemoLanguageTitle,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GzChipGroup<String>(
                  label: l.uiKitDemoLanguageTitle,
                  value: locale.languageCode,
                  options: [
                    GzChipOption(value: 'ar', label: l.commonLanguageArabic),
                    GzChipOption(value: 'en', label: l.commonLanguageEnglish),
                  ],
                  onChanged: (v) => v == null ? null : ref.read(localeProvider.notifier).setLocale(Locale(v)),
                ),
                const SizedBox(height: GzSpace.s3),
                GzChipGroup<DigitStyle>(
                  label: l.uiKitDemoLanguageTitle,
                  value: digits,
                  options: [
                    GzChipOption(value: DigitStyle.western, label: l.uiKitDemoDigitsWestern),
                    GzChipOption(value: DigitStyle.easternArabic, label: l.uiKitDemoDigitsEastern),
                  ],
                  onChanged: (v) => v == null ? null : ref.read(digitStyleProvider.notifier).setStyle(v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
