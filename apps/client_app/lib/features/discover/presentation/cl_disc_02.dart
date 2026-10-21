import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Audience, VenueResult;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/brief_draft.dart';
import '../application/discover_filters.dart';
import '../application/discover_regions.dart';
import '../application/discover_search.dart';
import 'widgets/brief_panels_a.dart';
import 'widgets/brief_panels_b.dart';
import 'widgets/brief_rows.dart';
import 'widgets/discover_failure.dart';

/// CL-DISC-02 Your Brief (sheet). Covers CA-HOME-02 to 06, CA-ONB-08, CA-ONB-09, CA-FLT-01.
///
/// The single editor of the global Brief, opened from the Home card, the Results echo, Compare and Saved. Four 64 rows, each a glyph and its
/// value (Date, Area, Guests with the section glyph, Budget); each opens its focused picker inside the sheet. Under the rows a strip of the
/// halls that fit (photographs only). The footer is pinned: the one gold CTA with the live count, and "Clear"; it applies the draft.
/// Dismissing discards it. When a signed-in account already holds a different Brief, the merge variant asks which one to keep (nothing
/// preselected). States: default, date-not-decided, flexible-month, merge-conflict, loading, offline.
class ClDisc02Screen extends ConsumerStatefulWidget {
  const ClDisc02Screen({super.key});

  @override
  ConsumerState<ClDisc02Screen> createState() => _ClDisc02ScreenState();
}

class _ClDisc02ScreenState extends ConsumerState<ClDisc02Screen> {
  late BriefDraft _draft;
  BriefPanel? _panel;
  bool _merge = false;
  bool _init = false;
  bool _touched = false;

  GzNavigator get _nav => context.gzNav;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final params = _nav.params;
    final brief = ref.read(searchBriefProvider);
    final guests = ref.read(weddingProfileProvider).value?.guests;
    _draft = BriefDraft(
      brief: brief,
      split: brief.audience != Audience.mixed,
      women: guests?.women ?? brief.guests ?? 350,
      men: guests?.men ?? brief.guests ?? 400,
    );
    final focus = params['focus'];
    _panel = BriefPanel.values.where((p) => p.name == focus).firstOrNull;
    _merge = params['variant'] == 'merge';
  }

  void _set(BriefDraft Function(BriefDraft d) change) => setState(() {
    _touched = true;
    _draft = change(_draft);
  });

  void _apply(bool fromHome) {
    ref.read(searchBriefProvider.notifier).set(_draft.brief);
    final st = ref.read(discoverStateProvider);
    if (st.seeded) {
      ref.read(discoverStateProvider.notifier).replaceFilters(st.filters.copyWith(available: st.filters.available && _draft.brief.date != null));
    }
    _nav.closeSheet();
    if (fromHome) _nav.push('CL-DISC-03', params: <String, Object?>{'from': 'discover', 'available': _draft.brief.date != null});
  }

  /// The region search is its own screen: keep what is chosen, close the sheet, open it (CL-DISC-07 writes the areas back).
  void _openRegion() {
    ref.read(searchBriefProvider.notifier).set(_draft.brief);
    _nav.closeSheet();
    _nav.push('CL-DISC-07', params: const <String, Object?>{'from': 'brief'});
  }

  void _closePanel() {
    if (_panel == BriefPanel.guests && _draft.brief.guests == null) {
      _set((d) => d.copyWith(brief: d.brief.copyWith(guests: d.brief.audience == Audience.men && d.split ? d.men : d.women)));
    }
    setState(() => _panel = null);
  }

  void _keep(bool phone) {
    final profile = ref.read(weddingProfileProvider).value;
    if (!phone && profile != null) {
      ref
          .read(searchBriefProvider.notifier)
          .set(
            SearchBrief.fromWedding(
              weddingDate: profile.weddingDate,
              dateMode: profile.dateMode,
              womenGuests: profile.guests.women,
              searching: profile.searching,
              areaIds: profile.areaIds,
              venueBudget: profile.venueBudget,
            ),
          );
    }
    ref.read(discoverStateProvider.notifier).markMergeShown();
    _nav.closeSheet();
    _nav.toast(GzToastSpec(message: context.l10n.clientDiscoverRefreshed, tone: GzToastTone.success));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    // The couple's profile fills the Brief a moment after the sheet opens: until the person edits, the draft is the Brief.
    ref.listen<SearchBrief>(searchBriefProvider, (_, next) {
      if (!_touched && mounted) setState(() => _draft = _draft.copyWith(brief: next));
    });
    final areasResponse = ref.watch(areasProvider).value;
    final areas = areasResponse?.areas ?? const [];
    final profile = ref.watch(weddingProfileProvider).value;
    final b = _draft.brief;
    final fromHome = _nav.params['from'] == 'home';
    final count = ref.watch(briefCountProvider(b));
    final rowsAsync = ref.watch(discoverSearchProvider(DiscoverQuery(brief: b, filters: DiscoverFilters.defaultsFor(b))));
    final offline = (count.hasError && isOfflineError(count.error)) || (rowsAsync.hasError && isOfflineError(rowsAsync.error));
    final loading = count.isLoading && !count.hasValue && !count.hasError;
    final fit = <VenueResult>[for (final r in rowsAsync.value ?? const <VenueResult>[]) r];

    if (_merge) {
      final account = profile == null
          ? SearchBrief.empty
          : SearchBrief.fromWedding(
              weddingDate: profile.weddingDate,
              dateMode: profile.dateMode,
              womenGuests: profile.guests.women,
              searching: profile.searching,
              areaIds: profile.areaIds,
              venueBudget: profile.venueBudget,
            );
      return Column(
        key: const ValueKey<String>('discover.brief.sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzSheetHeader(title: l.clientDiscoverMergeTitle, onClose: () => _keep(true)),
          const SizedBox(height: GzSpace.s3),
          BriefMergePanel(phone: ref.read(searchBriefProvider), account: account, areas: areas, onKeep: _keep),
        ],
      );
    }

    final date = briefDateText(f, b);
    final names = briefAreaNames(areas, b.areaIds, lang);
    final sectionGlyph = switch (b.audience) {
      Audience.men => GzIcons.sectionMen,
      Audience.mixed => GzIcons.sectionMixed,
      Audience.women => GzIcons.sectionWomen,
      _ => null,
    };
    final rows = <(BriefPanel, IconData, String, String?, String, Widget?)>[
      (
        BriefPanel.date,
        briefDateIcon(b),
        l.clientShellBriefDate,
        date,
        _draft.later ? context.gzL10n.commonLabelNotDecided : l.clientDiscoverBriefChooseDate,
        null,
      ),
      (
        BriefPanel.area,
        GzIcons.pin,
        l.clientShellBriefArea,
        names.isEmpty ? null : names.join(f.isArabic ? '، ' : ', '),
        l.clientDiscoverBriefChooseArea,
        null,
      ),
      (
        BriefPanel.guests,
        GzIcons.usersThree,
        l.clientShellBriefGuests,
        b.guests == null || b.guests == 0 ? null : f.integer(b.guests!),
        l.clientDiscoverBriefAddGuests,
        b.guests != null && sectionGlyph != null ? GzIcon(sectionGlyph, size: GzIconSize.sm, color: c.iconSecondary) : null,
      ),
      (
        BriefPanel.budget,
        GzIcons.wallet,
        l.clientShellBriefBudget,
        b.budget == null ? null : briefBudgetText(f, b.budget!),
        l.clientDiscoverBriefSetBudget,
        null,
      ),
    ];
    final cta = loading || offline
        ? l.clientDiscoverCtaShow
        : (count.value == 0 && b.date != null)
        ? l.clientDiscoverCtaNearest
        : f.digits(l.clientDiscoverCtaCount(count.value ?? 0));
    final titles = <BriefPanel, String>{
      BriefPanel.date: l.clientDiscoverBriefDateTitle,
      BriefPanel.area: l.clientDiscoverBriefAreaTitle,
      BriefPanel.guests: l.clientDiscoverBriefGuestsTitle,
      BriefPanel.budget: l.clientDiscoverBriefBudgetTitle,
    };
    final panel = _panel;

    Widget panelBody() => switch (panel!) {
      BriefPanel.date => BriefDatePanel(draft: _draft, set: _set),
      BriefPanel.area => BriefAreaPanel(draft: _draft, set: _set, onOpenRegion: _openRegion),
      BriefPanel.guests => BriefGuestsPanel(draft: _draft, set: _set),
      BriefPanel.budget => BriefBudgetPanel(draft: _draft, set: _set),
    };

    final footer = panel == null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: GzSpace.s3),
              GzButton(
                key: const ValueKey<String>('discover.brief.cta'),
                label: cta,
                fullWidth: true,
                loading: loading,
                onPressed: () => _apply(fromHome),
              ),
              const SizedBox(height: GzSpace.s2),
              Center(
                child: GzButton(
                  key: const ValueKey<String>('discover.brief.clear'),
                  label: l.clientDiscoverBriefClear,
                  variant: GzButtonVariant.tertiary,
                  onPressed: () => _set((d) => d.copyWith(brief: SearchBrief.empty, later: false)),
                ),
              ),
            ],
          )
        : Padding(
            padding: const EdgeInsetsDirectional.only(top: GzSpace.s3),
            child: GzButton(
              key: const ValueKey<String>('discover.brief.done'),
              label: l.clientDiscoverBriefDone,
              fullWidth: true,
              onPressed: _closePanel,
            ),
          );

    // The sheet is 90% of the frame with the footer pinned at its foot (the web `useSheetFill`): the body takes what the grab zone, the
    // padding and the footer leave.
    final mq = MediaQuery.of(context);
    final cap = (mq.size.height * 0.9 / 4).floor() * 4.0;
    final footerHeight = GzSpace.sheetPadBottom + GzSpace.s3 + GzSize.controlCta + (panel == null ? GzSpace.s2 + GzSize.controlSm : 0);
    final bodyMin = cap - GzSpace.sheetPadTop - GzSpace.s5 - mq.padding.bottom - GzSpace.sheetPadBottom - footerHeight;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: bodyMin),
      child: Column(
        key: const ValueKey<String>('discover.brief.sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (panel != null)
            Row(
              children: [
                GzBarButton(
                  key: const ValueKey<String>('discover.brief.back'),
                  icon: GzIcons.back,
                  label: l.clientDiscoverBriefBack,
                  onPressed: () => setState(() => _panel = null),
                ),
                const SizedBox(width: GzSpace.s1),
                Expanded(
                  child: GzText(titles[panel]!, role: GzTextRole.d1, color: c.textStrong, header: true),
                ),
              ],
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: GzSize.controlMd),
              child: Row(
                children: [
                  Expanded(
                    child: GzText(l.clientDiscoverBriefTitle, role: GzTextRole.d1, color: c.textStrong, header: true),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  GzBarButton(
                    key: const ValueKey<String>('gz:sheet.close'),
                    icon: GzIcons.close,
                    label: context.gzL10n.commonActionClose,
                    onPressed: _nav.closeSheet,
                  ),
                ],
              ),
            ),
          if (offline)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s3),
              child: GzBanner(message: context.gzL10n.commonStateOffline, tone: GzBannerTone.offline, shape: GzBannerShape.card),
            ),
          if (panel == null) ...[
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                ),
              ),
              child: Column(
                children: [
                  for (final r in rows)
                    Builder(
                      builder: (context) => BriefRowTile(
                        key: ValueKey<String>('discover.brief.row.${r.$1.name}'),
                        icon: r.$2,
                        name: r.$3,
                        value: r.$4,
                        placeholder: r.$5,
                        chevron: true,
                        border: true,
                        inset: 0,
                        extra: r.$6,
                        onPressed: () => setState(() => _panel = r.$1),
                      ),
                    ),
                ],
              ),
            ),
            if (!loading && !offline && fit.isNotEmpty) _Preview(rows: fit, onTap: () => _apply(fromHome), label: l.clientDiscoverResultsTitle),
            if (rowsAsync.hasError && !offline) DiscoverFailure(error: rowsAsync.error!, onRetry: () => ref.invalidate(discoverSearchProvider)),
          ] else
            panelBody(),
          GzSheetFooter(child: footer),
        ],
      ),
    );
  }
}

/// The halls that fit: four photographs side by side (no captions) and the number beyond them. One button: it does what the CTA does.
class _Preview extends StatelessWidget {
  const _Preview({required this.rows, required this.onTap, required this.label});

  final List<VenueResult> rows;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final c = context.gz.colors;
    final shown = rows.take(4).toList();
    return GzPressable(
      key: const ValueKey<String>('discover.brief.preview'),
      onPressed: onTap,
      semanticLabel: '$label ${f.integer(rows.length)}',
      builder: (context, st) => Padding(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s5),
        child: SizedBox(
          height: 168,
          child: Row(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) const SizedBox(width: GzSpace.s2),
                Expanded(
                  child: ClipRRect(
                    borderRadius: GzRadius.smAll,
                    child: shown[i].venue.cover == null
                        ? ColoredBox(color: c.surfacePlaceholder)
                        : GzPhoto(src: shown[i].venue.cover!.baseUrl ?? shown[i].venue.cover!.file),
                  ),
                ),
              ],
              if (rows.length > shown.length)
                SizedBox(
                  width: GzSize.touchMin,
                  child: Center(
                    child: gzFigText(context, '+${f.integer(rows.length - shown.length)}', role: GzTextRole.figBodyS, color: c.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
