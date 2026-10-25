import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show homeRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart';

/// The public app configuration (limits, voucher price, support contacts): one fetch shared by every feature that needs it.
final FutureProvider<AppConfig> publicAppConfigProvider = FutureProvider<AppConfig>((ref) => ref.watch(homeRepositoryProvider).getAppConfig());
