import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemKind, gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode;
import 'package:ghazal_domain/ghazal_domain.dart' show BookingChannel, CompareColumn, LocalizedText;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/saved_data.dart';
import 'widgets/compare_parts.dart';

/// CL-SAVD-04 Compare (pushed, tab bar hidden). Covers CA-CMP-04..12, CA-BOOK-01, CA-VCH-02.
///
/// System back returns to 'CL-SAVD-01' (or the tray's screen).
///
/// Three equal columns at 360 to 430, no label column, no sideways scroll (the shared `GzCompareTable`): the Brief echo as three facts and
/// a pencil, the header, a two-glyph switch (differences | all) on differences by default, best-in-row marks, and a footer of three
/// one-word actions aligned to the thirds (Voucher, Dates, Official). The hall's price is requested with a voucher: there is no Request or
/// Book here. States: default, loading, fewer-than-two, no-date, offline, error.
class ClSavd04Screen extends ConsumerStatefulWidget {
  const ClSavd04Screen({super.key});

  @override
  ConsumerState<ClSavd04Screen> createState() => _ClSavd04ScreenState();
}

class _ClSavd04ScreenState extends ConsumerState<ClSavd04Screen> {
  bool _diff = true;
  String? _picked;
  bool _seeded = false;

  GzNavigator get _nav => context.gzNav;

  @override
  void initState() {
    super.initState();
    // A shared compare link (/compare?ids=a,b,c) opens the table for a signed-in client who never saved.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _seeded) return;
      _seeded = true;
      final raw = _nav.params['ids'];
      if (raw is String && raw.isNotEmpty) {
        final ids = raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).take(kCompareMax).toList();
        if (ids.length >= 2) ref.read(compareProvider.notifier).setAll(ids);
      }
    });
  }

  void _action(String id, GzCompareActionKind kind, SearchBrief brief) {
    switch (kind) {
      case GzCompareActionKind.official:
        _nav.push('CL-VENU-06', params: <String, Object?>{'venueId': id});
      case GzCompareActionKind.dates:
        _nav.openSheet('CL-VENU-03', options: GzSheetOptions(params: <String, Object?>{'venueId': id}));
      case GzCompareActionKind.notify:
        _nav.push('CL-VENU-01', params: <String, Object?>{'venueId': id});
      case GzCompareActionKind.voucher:
        // Get voucher: CL-VCHR-01 carries the date and guests of the Brief and binds the voucher to this hall.
        setState(() => _picked = id);
        ref.read(bookingDraftProvider.notifier).start(venueId: id, eventDate: brief.date, guests: brief.guests, audience: brief.audience);
        final params = <String, Object?>{'venueId': id, 'eventDate': brief.date?.toString(), 'guests': brief.guests, 'from': 'compare'};
        _nav.openSheet('CL-VCHR-01', options: GzSheetOptions(params: params));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lg = context.gzL10n;
    final lang = context.gz.locale.languageCode;
    final brief = ref.watch(searchBriefProvider);
    final ids = ref.watch(compareProvider.select((s) => s.venueIds));
    final areas = ref.watch(savedAreaNamesProvider).value ?? const {};
    final async = ids.length < 2 ? null : ref.watch(compareColumnsProvider((ids, brief)));
    final loading = async != null && async.isLoading && !async.hasValue && !async.hasError;
    final error = async != null && async.hasError && !async.hasValue ? async.error : null;
    final problem = error is ApiProblem ? error : (error == null ? null : const ApiProblem(status: 0, code: ApiProblemCode.unknown));
    final offline = problem?.isOffline ?? false;
    final columns = async?.value?.columns ?? const <CompareColumn>[];
    final fewer = ids.length < 2;
    final showKey = !loading && error == null && !fewer;
    final originName = _originName(areas, brief, lang);

    Widget content;
    if (problem != null) {
      content = Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
        child: offline
            ? GzOfflineState(fill: false, onRetry: () => ref.invalidate(compareColumnsProvider((ids, brief))))
            : GzErrorState(
                key: const ValueKey<String>('compare.error'),
                kind: gzProblemKind(problem),
                body: gzProblemMessage(lg, problem),
                fill: false,
                onRetry: () => ref.invalidate(compareColumnsProvider((ids, brief))),
              ),
      );
    } else if (fewer) {
      content = CompareFewer(venueId: ids.isEmpty ? null : ids.first, onBrowse: _nav.pop);
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (brief.audience != null || brief.guests != null || brief.date != null)
            CompareBriefFacts(brief: brief, onEdit: () => _nav.openSheet('CL-DISC-02')),
          if (loading)
            const CompareSkeleton()
          else
            GzCompareTable(
              key: const ValueKey<String>('compare.table'),
              columns: columns,
              origin: originName,
              date: brief.date,
              guests: brief.guests,
              areaNames: {for (final e in areas.entries) e.key: e.value.of(lang)},
              grid: true,
              pinned: true,
              pickedId: _picked,
              onPick: (id) => setState(() => _picked = _picked == id ? null : id),
              differencesOnly: _diff,
              onDifferencesOnlyChange: (v) => setState(() => _diff = v),
              onRemove: (id) {
                ref.read(compareProvider.notifier).remove(id);
                if (_picked == id) setState(() => _picked = null);
              },
              onOpen: (id) {
                final col = columns.where((k) => k.venue.id == id).firstOrNull;
                _nav.push(
                  col?.channel == BookingChannel.externalLink ? 'CL-VENU-06' : 'CL-VENU-01',
                  params: <String, Object?>{'venueId': id, 'from': 'compare'},
                );
              },
              onAction: (id, kind) => _action(id, kind, brief),
            ),
        ],
      );
    }

    return GzScreen(
      bottom: showKey && columns.isNotEmpty
          ? GzCompareBar(columns: columns, hasDate: brief.date != null, pickedId: _picked, onAction: (id, kind) => _action(id, kind, brief))
          : null,
      top: GzTopBar(
        title: l.clientSavedCompareCompareTitle,
        actions: [
          if (showKey)
            GzTopBarAction(
              icon: GzIcons.info,
              label: l.clientSavedCompareKeyTitle,
              onPressed: () => _nav.openSheetBuilder((_) => const CompareKeySheet()),
            ),
          GzTopBarAction(
            icon: GzIcons.share,
            label: lg.commonActionShare,
            onPressed: () => _nav.toast(GzToastSpec(message: l.clientSavedCompareCompareLinkCopied, tone: GzToastTone.success)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (offline) GzBanner(message: lg.commonStateOffline, tone: GzBannerTone.offline),
          content,
          const SizedBox(height: GzSpace.s6),
        ],
      ),
    );
  }

  String _originName(Map<String, LocalizedText> areas, SearchBrief brief, String lang) {
    // The Brief names governorates, not areas (ADR 0038): "Drive from" counts from the default reference point.
    return areas['salmiya']?.of(lang) ?? '';
  }
}
