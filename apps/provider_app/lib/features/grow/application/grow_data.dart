// Reads and writes of the grow flow (HL-GROW-01..04, 06): the voucher-price windows, the package catalog they lower, the soft dates, the editor
// draft that survives Back between the two steps, and analytics and reviews. Lists refetch after a write by watching `partnerDataRevisionProvider`.
import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart'
    show
        homeRepositoryProvider,
        partnerCalendarRepositoryProvider,
        partnerGrowthRepositoryProvider,
        partnerReviewsRepositoryProvider,
        partnerVenueRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, clockProvider, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import 'grow_model.dart';

/// Today as a civil date on the app's clock (the story clock in shots and tests).
final Provider<LocalDate> growTodayProvider = Provider<LocalDate>(
  (ref) => LocalDate.parse(ref.watch(gzFormatProvider).isoDay(ref.watch(clockProvider)())),
);

final FutureProvider<PackageCatalog> growCatalogProvider = FutureProvider.autoDispose<PackageCatalog>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerVenueRepositoryProvider).listPartnerPackages();
});

final FutureProvider<List<Hall>> growHallsProvider = FutureProvider.autoDispose<List<Hall>>(
  (ref) async => (await ref.read(partnerVenueRepositoryProvider).listPartnerHalls()).halls,
);

final FutureProvider<PartnerVenue> growVenueProvider = FutureProvider.autoDispose<PartnerVenue>(
  (ref) async => ref.read(partnerVenueRepositoryProvider).getPartnerVenue(),
);

final FutureProvider<PlatformConfig> growConfigProvider = FutureProvider.autoDispose<PlatformConfig>(
  (ref) async => (await ref.read(homeRepositoryProvider).getAppConfig()).config,
);

final FutureProvider<List<VoucherWindow>> growWindowsProvider = FutureProvider.autoDispose<List<VoucherWindow>>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  return (await ref.read(partnerGrowthRepositoryProvider).listVoucherWindows()).windows;
});

/// The unsold weekend dates of the next 60 days.
final FutureProvider<List<String>> growSoftDatesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  final s = await ref.read(partnerCalendarRepositoryProvider).getSoftDates();
  return [for (final d in s.dates) d.toString()];
});

/// The days of a month the venue cannot sell (a booking, a hold or a block): `YYYY-MM` in, ISO days out.
final growBusyProvider = FutureProvider.autoDispose.family<Set<String>, String>((ref, month) async {
  ref.watch(partnerDataRevisionProvider);
  final first = LocalDate.parse('$month-01');
  final last = LocalDate(first.year, first.month + 1, 1).addDays(-1);
  final cal = await ref.read(partnerCalendarRepositoryProvider).getPartnerCalendar(from: first, to: last);
  return {
    for (final d in cal.days)
      if (d.claims.isNotEmpty) d.date.toString(),
  };
});

/// The two language titles a window gets when the person leaves the suggestion.
({String en, String ar}) suggestedTitles() =>
    (en: lookupAppL10n(const Locale('en')).hotelGrowTitleSuggestion, ar: lookupAppL10n(const Locale('ar')).hotelGrowTitleSuggestion);

// ---------------------------------------------------------------- editor session

class GrowSessionState {
  const GrowSessionState({this.draft = const GrowDraft(), this.originList = false, this.highlight, this.openWindow});

  final GrowDraft draft;

  /// Where the editor was opened from, so Publish returns there.
  final bool originList;
  final String? highlight;

  /// The window to open in the actions sheet as soon as the list is on screen (the toast's View).
  final String? openWindow;

  GrowSessionState copyWith({GrowDraft? draft, bool? originList, Object? highlight = _keep, Object? openWindow = _keep}) => GrowSessionState(
    draft: draft ?? this.draft,
    originList: originList ?? this.originList,
    highlight: identical(highlight, _keep) ? this.highlight : highlight as String?,
    openWindow: identical(openWindow, _keep) ? this.openWindow : openWindow as String?,
  );
}

const Object _keep = Object();

final NotifierProvider<GrowSession, GrowSessionState> growSessionProvider = NotifierProvider<GrowSession, GrowSessionState>(GrowSession.new);

class GrowSession extends Notifier<GrowSessionState> {
  @override
  GrowSessionState build() => const GrowSessionState();

  void patch(GrowDraft Function(GrowDraft d) fn) => state = state.copyWith(draft: fn(state.draft).copyWith(dirty: true));

  /// A fresh draft (optionally with some fields set); the default covers the first voucher package at its standing price.
  void reset(GrowDraft draft) => state = state.copyWith(draft: draft);

  void setOrigin({required bool list}) => state = state.copyWith(originList: list);

  void requestOpen(String? id) => state = state.copyWith(openWindow: id);

  void highlight(String? id) => state = state.copyWith(highlight: id);
}

// ---------------------------------------------------------------- writes

final NotifierProvider<GrowActions, ActionsState> growActionsProvider = NotifierProvider<GrowActions, ActionsState>(GrowActions.new);

class GrowActions extends Notifier<ActionsState> {
  final IntentKeys _keys = IntentKeys();

  @override
  ActionsState build() => const ActionsState();

  Future<ActionResult<T>> _run<T>(String key, Future<T> Function() call, {String? intent}) async {
    state = ActionsState(busy: {...state.busy, key});
    try {
      final value = await call();
      if (intent != null) _keys.done(intent);
      state = ActionsState(busy: {...state.busy}..remove(key));
      ref.read(partnerDataRevisionProvider.notifier).bump();
      return ActionSuccess(value);
    } on ApiProblem catch (p) {
      if (intent != null && !p.isTransient) _keys.done(intent);
      state = ActionsState(busy: {...state.busy}..remove(key), lastProblem: p);
      return ActionFailure(p);
    }
  }

  Future<ActionResult<VoucherWindow>> publish(VoucherWindowInput body) => _run(
    'publish',
    () => ref.read(partnerGrowthRepositoryProvider).createVoucherWindow(body: body, idempotencyKey: _keys.keyFor('window:new')),
    intent: 'window:new',
  );

  Future<ActionResult<Review>> reply(String id, String text, WireLang origin) => _run(
    'reply:$id',
    () => ref
        .read(partnerReviewsRepositoryProvider)
        .replyToReview(
          reviewId: id,
          body: ReplyInput(text: text, origin: origin),
          idempotencyKey: _keys.keyFor('reply:$id'),
        ),
    intent: 'reply:$id',
  );

  Future<ActionResult<void>> report(String id, ReportReviewInputReason reason) async {
    final res = await _run<void>(
      'report:$id',
      () => ref
          .read(partnerReviewsRepositoryProvider)
          .reportReview(
            reviewId: id,
            body: ReportReviewInput(reason: reason),
            idempotencyKey: _keys.keyFor('report:$id'),
          ),
      intent: 'report:$id',
    );
    if (res.isSuccess) ref.read(reportedReviewsProvider.notifier).add(id);
    return res;
  }

  Future<ActionResult<VoucherWindow>> end(String id) => _run(
    'end:$id',
    () => ref.read(partnerGrowthRepositoryProvider).endVoucherWindow(windowId: id, idempotencyKey: _keys.keyFor('window:end:$id')),
    intent: 'window:end:$id',
  );
}

// ---------------------------------------------------------------- analytics and reviews

typedef AnSpan = ({LocalDate from, LocalDate to});

final analyticsProvider = FutureProvider.autoDispose.family<PartnerAnalytics, AnSpan>((ref, span) async {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerGrowthRepositoryProvider).getPartnerAnalytics(from: span.from, to: span.to);
});

final growReviewsProvider = FutureProvider.autoDispose<List<Review>>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  final repo = ref.read(partnerReviewsRepositoryProvider);
  final out = <Review>[];
  String? cursor;
  do {
    final page = await repo.listPartnerReviews(cursor: cursor, limit: 50);
    out.addAll(page.items);
    cursor = page.nextCursor;
  } while (cursor != null && out.length < 200);
  return out;
});

/// Reviews this venue reported in this run (the contract's Review carries no "reported" flag: the screen remembers what it sent).
final NotifierProvider<ReportedReviews, Set<String>> reportedReviewsProvider = NotifierProvider<ReportedReviews, Set<String>>(ReportedReviews.new);

class ReportedReviews extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  void add(String id) => state = {...state, id};
}
