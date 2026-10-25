import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show profileRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart' show Me, UpdateMeInput;

import '../../../app/state/state.dart';

/// Configuration the screens read (never typed into a message): the web `APP_VERSION`, the biometric method of the platform, the
/// marketing blackout and the two quiet-hour windows (ADR 0007 D11, ADR 0015 D8).
const String kProfileAppVersion = '1.0.0';
const String kBiometricMethod = 'face';
const int kMarketingBlackoutDays = 7;
const int kMaxMarketingPerWeek = 2;
const int kConfirmWindowHours = 24;

/// A quiet-hour window as two civil times (hour, minute).
typedef QuietWindow = ({(int, int) from, (int, int) to});
const QuietWindow kQuietMarketing = (from: (22, 0), to: (9, 0));
const QuietWindow kQuietAlerts = (from: (23, 0), to: (8, 0));

enum NotifChannel { push, whatsapp, email }

/// What the phone itself keeps (the OS permission is not ours) and the usage-data switch. In memory: a device setting.
class DeviceSettings {
  const DeviceSettings({this.shareUsage = true, this.osNotificationsDenied = false, this.biometricOn = false});

  final bool shareUsage;
  final bool osNotificationsDenied;

  /// The app-lock opt-in as Settings knows it (the auth flow keeps its own copy until the shared state exists: requests.md).
  final bool biometricOn;

  DeviceSettings copyWith({bool? shareUsage, bool? osNotificationsDenied, bool? biometricOn}) => DeviceSettings(
    shareUsage: shareUsage ?? this.shareUsage,
    osNotificationsDenied: osNotificationsDenied ?? this.osNotificationsDenied,
    biometricOn: biometricOn ?? this.biometricOn,
  );
}

final NotifierProvider<DeviceSettingsNotifier, DeviceSettings> deviceSettingsProvider = NotifierProvider<DeviceSettingsNotifier, DeviceSettings>(
  DeviceSettingsNotifier.new,
);

class DeviceSettingsNotifier extends Notifier<DeviceSettings> {
  @override
  DeviceSettings build() => const DeviceSettings();

  void setShareUsage(bool on) => state = state.copyWith(shareUsage: on);

  void setBiometric(bool on) => state = state.copyWith(biometricOn: on);

  /// The OS permission as the platform reports it (the shot harness uses `denied`).
  void setOsDenied(bool denied) => state = state.copyWith(osNotificationsDenied: denied);
}

/// The account that asked to be deleted after the event (ADR 0007 D12), as an ISO day; null while none.
final NotifierProvider<DeletionAfterNotifier, String?> profileDeletionAfterProvider = NotifierProvider<DeletionAfterNotifier, String?>(DeletionAfterNotifier.new);

class DeletionAfterNotifier extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(clientUserIdProvider);
    return null;
  }

  void schedule(String? isoDay) => state = isoDay;
}

/// The preferences of CL-PROF-04. Marketing is the one the server keeps (`marketingOptIn`); the rest is the app's own.
class NotifPrefs {
  const NotifPrefs({
    this.confirmWindow = true,
    this.voucherExpiry = true,
    this.visitReminders = true,
    this.milestones = true,
    this.marketing = false,
    this.offers = true,
    this.priceDrops = true,
    this.newVenues = true,
    this.reminderChannels = const <NotifChannel>{NotifChannel.push, NotifChannel.whatsapp},
    this.marketingChannels = const <NotifChannel>{NotifChannel.push},
  });

  final bool confirmWindow;
  final bool voucherExpiry;
  final bool visitReminders;
  final bool milestones;
  final bool marketing;
  final bool offers;
  final bool priceDrops;
  final bool newVenues;
  final Set<NotifChannel> reminderChannels;
  final Set<NotifChannel> marketingChannels;

  NotifPrefs copyWith({
    bool? confirmWindow,
    bool? voucherExpiry,
    bool? visitReminders,
    bool? milestones,
    bool? marketing,
    bool? offers,
    bool? priceDrops,
    bool? newVenues,
    Set<NotifChannel>? reminderChannels,
    Set<NotifChannel>? marketingChannels,
  }) => NotifPrefs(
    confirmWindow: confirmWindow ?? this.confirmWindow,
    voucherExpiry: voucherExpiry ?? this.voucherExpiry,
    visitReminders: visitReminders ?? this.visitReminders,
    milestones: milestones ?? this.milestones,
    marketing: marketing ?? this.marketing,
    offers: offers ?? this.offers,
    priceDrops: priceDrops ?? this.priceDrops,
    newVenues: newVenues ?? this.newVenues,
    reminderChannels: reminderChannels ?? this.reminderChannels,
    marketingChannels: marketingChannels ?? this.marketingChannels,
  );
}

final AsyncNotifierProvider<NotifPrefsNotifier, NotifPrefs> notifPrefsProvider = AsyncNotifierProvider<NotifPrefsNotifier, NotifPrefs>(NotifPrefsNotifier.new);

class NotifPrefsNotifier extends AsyncNotifier<NotifPrefs> {
  /// The problem of the last refused save (the screen shows its retry banner).
  ApiProblem? lastProblem;

  @override
  Future<NotifPrefs> build() async {
    ref.watch(clientUserIdProvider);
    final Me me = await ref.read(profileRepositoryProvider).getMe();
    return NotifPrefs(marketing: me.marketingOptIn);
  }

  /// Applies [next] at once; the marketing master is saved on the server and rolled back when refused. Returns true when kept.
  Future<bool> apply(NotifPrefs next) async {
    final before = state.value ?? const NotifPrefs();
    state = AsyncData(next);
    lastProblem = null;
    if (next.marketing == before.marketing) return true;
    try {
      await ref.read(profileRepositoryProvider).updateMe(body: UpdateMeInput(marketingOptIn: next.marketing));
      return true;
    } on ApiProblem catch (e) {
      lastProblem = e;
      state = AsyncData(before);
      return false;
    }
  }
}
