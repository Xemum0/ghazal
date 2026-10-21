import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemKind, gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show ScreenState;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/booking_flow_providers.dart';

/// The five states of a step body (web: skeleton, error with retry, offline banner), inside a scroller: a stale value stays on screen
/// while it reloads, an offline answer keeps the stale content under the offline banner, an error shows the problem's own sentence with
/// retry. Never a spinner over the whole screen and never a blank.
class BookingAsync<T> extends StatelessWidget {
  const BookingAsync({
    required this.value,
    required this.data,
    required this.loading,
    this.onRetry,
    this.offlineBanner = true,
    this.offlineText,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget loading;
  final VoidCallback? onRetry;
  final bool offlineBanner;

  /// The offline banner sentence (default: "Offline. Draft saved.").
  final String? offlineText;

  @override
  Widget build(BuildContext context) {
    final state = ScreenState.from<T>(keepStale(value));
    return state.when(
      loading: () => Semantics(
        container: true,
        label: context.gzL10n.commonStateLoading,
        child: ExcludeSemantics(child: loading),
      ),
      data: data,
      empty: () => const SizedBox.shrink(),
      error: (p) => GzErrorState(kind: gzProblemKind(p), body: gzProblemMessage(context.gzL10n, p), onRetry: onRetry, fill: false),
      offline: (stale) => stale == null
          ? GzOfflineState(onRetry: onRetry, fill: false)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (offlineBanner)
                  GzBanner(message: offlineText ?? context.l10n.clientBookingOfflineBanner, tone: GzBannerTone.offline, shape: GzBannerShape.card),
                data(stale),
              ],
            ),
    );
  }
}

/// A skeleton row of a list (a name line and a figure line), gutter included.
class BookingSkeletonRows extends StatelessWidget {
  const BookingSkeletonRows({this.count = 3, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < count; i++)
            const Padding(
              padding: EdgeInsetsDirectional.only(bottom: GzSpace.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GzSkeleton(inlineSize: 160, blockSize: 24),
                  SizedBox(height: GzSpace.s2),
                  GzSkeleton(inlineSize: 96, blockSize: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
