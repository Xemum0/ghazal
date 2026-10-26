import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, GzFormat, NameStyle;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/venue_model.dart';
import '../application/venue_providers.dart';
import 'venue_glyphs.dart';
import 'widgets/venue_hall.dart' show VenueClamp;
import 'widgets/venue_failure.dart';
import 'widgets/venue_money.dart' show QuietMoney;
import 'widgets/venue_sheets.dart' show VenueSheetHead;

/// CL-VENU-05 Policies and hall rules (sheet). Covers CA-VDET-06, CA-VDET-15, CA-VDET-17..19, CA-VDET-26, CA-SRCH-12, CA-SRCH-13.
///
/// Plain-language terms with absolute dates where relevant, plus the per-section facts families actually ask about. Three
/// segments: Terms, Hall rules by section, Good to know.
class ClVenu05Screen extends ConsumerStatefulWidget {
  const ClVenu05Screen({super.key});

  @override
  ConsumerState<ClVenu05Screen> createState() => _ClVenu05State();
}

class _ClVenu05State extends ConsumerState<ClVenu05Screen> {
  String _segment = 'terms';
  bool _segmentSeeded = false;
  Audience? _audience;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_segmentSeeded) {
      _segmentSeeded = true;
      final seg = context.gzNav.params['segment'];
      if (seg == 'rules' || seg == 'good') _segment = seg as String;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final params = VenueParams.of(context.gzNav.params);
    final brief = ref.watch(searchBriefProvider);
    final pick = ref.watch(venuePickProvider(params.venueId));
    final vkey = venueKeyOf(params, brief, pick);
    final view = ref.watch(venueViewProvider(vkey));
    final data = view.value;

    return Column(
      key: ValueKey<String>('venue.pol.${params.venueId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSheetPinnedHeader(
          child: VenueSheetHead(title: l.clientVenuePolTitle, onClose: () => context.gzNav.closeSheet()),
        ),
        if (view.isLoading && data == null)
          const Column(
            children: [
              GzSkeleton(blockSize: 56),
              SizedBox(height: GzSpace.s3),
              GzSkeletonText(lines: 6),
            ],
          )
        else if (data == null && view.hasError)
          VenueSheetFailure(error: view.error, onRetry: () => ref.invalidate(venueViewProvider(vkey)))
        else if (data == null)
          GzEmptyState(
            illustration: GzIllustrationName.noResult,
            title: l.clientVenuePackagesNone,
            action: GzStateAction(label: l.commonActionClose, variant: GzButtonVariant.primary, onPressed: () => context.gzNav.pop()),
          )
        else ...[
          GzIconTabs<String>(
            label: l.clientVenuePolTabsLabel,
            value: _segment,
            onChanged: (v) => setState(() => _segment = v),
            items: [
              GzIconTabItem<String>(value: 'terms', icon: GzIcons.document, label: l.clientVenuePolTabTerms),
              GzIconTabItem<String>(value: 'rules', icon: GzIcons.clipboard, label: l.clientVenuePolTabRules),
              GzIconTabItem<String>(value: 'good', icon: GzIcons.info, label: l.clientVenuePolTabGood),
            ],
          ),
          const SizedBox(height: GzSpace.s5),
          if (_segment == 'terms')
            _TermsPanel(view: data)
          else if (_segment == 'rules')
            _RulesPanel(view: data, audience: _audience, onAudience: (a) => setState(() => _audience = a))
          else
            _GoodPanel(view: data, audience: _audience ?? data.audience),
        ],
        const SizedBox(height: GzSpace.s4),
      ],
    );
  }
}

/// Terms: the venue's own terms in plain words, then the voucher terms (what the KD 2 is, reuse, forfeiture, credit voucher).
class _TermsPanel extends ConsumerWidget {
  const _TermsPanel({required this.view});

  final VenueView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final repo = ref.watch(homeRepositoryProvider);
    return Column(
      key: const ValueKey<String>('venue.pol.terms'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: l.clientVenueTermsVenueTitle(context.bi(view.venue.name)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GzIcon(GzIcons.venue, size: GzIconSize.md, tone: GzIconTone.secondary),
              const SizedBox(width: GzSpace.s3),
              Expanded(child: VenueClamp(text: context.bi(view.venue.policies.terms), limit: 104)),
            ],
          ),
        ),
        const SizedBox(height: GzSpace.s5),
        Semantics(
          container: true,
          label: l.clientVenueTermsVoucherTitle,
          child: FutureBuilder<PlatformConfig>(
            future: repo.getAppConfig().then((r) => r.config),
            builder: (context, snap) {
              final cfg = snap.data;
              final fee = cfg == null ? 'KD 2' : context.gzFormat.money(cfg.voucherFeeFils);
              final days = cfg == null ? '' : context.gzL10n.commonCountDays(cfg.voucherReuseDays);
              final hours = cfg == null ? '' : context.gzL10n.commonCountHours(cfg.confirmWindowHours);
              final terms = <(IconData, String)>[
                (GzIcons.ticket, l.clientVenueTermsVoucherFee(fee)),
                (GzIcons.link, l.clientVenueTermsVoucherBound),
                (GzIcons.receipt, l.clientVenueTermsDirect),
                (GzIcons.refresh, l.clientVenueTermsVoucherReuse(days)),
                (GzIcons.timer, l.clientVenueTermsVoucherConfirm(hours)),
              ];
              return Container(
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    top: BorderSide(color: context.gz.colors.borderHairline, width: GzStroke.hair),
                  ),
                ),
                padding: const EdgeInsetsDirectional.only(top: GzSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < terms.length; i++) ...[
                      if (i > 0) const SizedBox(height: GzSpace.s4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GzIcon(terms[i].$1, size: GzIconSize.md, tone: GzIconTone.secondary),
                          const SizedBox(width: GzSpace.s3),
                          Expanded(child: _Fig(text: terms[i].$2)),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Hall rules by section: Ladies | Men segmented control, then the section facts as glyph chips.
class _RulesPanel extends StatelessWidget {
  const _RulesPanel({required this.view, required this.audience, required this.onAudience});

  final VenueView view;
  final Audience? audience;
  final ValueChanged<Audience> onAudience;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sections = view.hall.sections;
    final active = (audience != null && sections.any((s) => s.audience == audience))
        ? audience!
        : (sections.where((s) => s.audience == view.audience).firstOrNull ?? sections.first).audience;
    final section = sections.where((s) => s.audience == active).firstOrNull ?? sections.first;
    return Column(
      key: const ValueKey<String>('venue.pol.rules'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sections.length > 1)
          GzIconSegmented<Audience>(
            label: l.clientVenuePolRulesLabel,
            value: active,
            onChanged: onAudience,
            options: [
              for (final s in sections)
                GzIconSegmentedOption<Audience>(value: s.audience, icon: audienceGlyph(s.audience), label: audienceName(l, s.audience)),
            ],
          ),
        if (sections.length > 1) const SizedBox(height: GzSpace.s5),
        _RuleChips(facts: section.policy),
      ],
    );
  }
}

/// Good to know: children policy, dress code, working hours, closures.
class _GoodPanel extends StatelessWidget {
  const _GoodPanel({required this.view, required this.audience});

  final VenueView view;
  final Audience audience;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final children = audience == Audience.men ? view.venue.policies.children.men : view.venue.policies.children.women;
    Widget fact({required IconData icon, required String label, required Widget child}) => Padding(
      padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s4),
      child: Semantics(
        container: true,
        label: label,
        child: Container(
          decoration: BoxDecoration(
            border: BorderDirectional(
              bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
            ),
          ),
          padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GzIcon(icon, size: GzIconSize.md, tone: GzIconTone.secondary),
              const SizedBox(width: GzSpace.s3),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
    return Column(
      key: const ValueKey<String>('venue.pol.good'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        fact(
          icon: GzIcons.guests,
          label: l.clientVenuePolChildren,
          child: GzText(context.bi(children), role: GzTextRole.bodyS, color: c.textPrimary),
        ),
        fact(
          icon: GzIcons.dress,
          label: l.clientVenuePolDress,
          child: GzText(context.bi(view.venue.policies.dressCode), role: GzTextRole.bodyS, color: c.textPrimary),
        ),
        fact(
          icon: GzIcons.clock,
          label: l.clientVenuePolHours,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final r in view.venue.hours.rules)
                _Fig(text: l.clientVenuePolHoursLine(_dayNames(f, r.days), _clock(f, r.open), _clock(f, r.close))),
            ],
          ),
        ),
        if (view.venue.hours.closures.isNotEmpty)
          fact(
            icon: GzIcons.calendarX,
            label: l.clientVenuePolClosures,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final x in view.venue.hours.closures)
                  _Fig(
                    text: l.clientVenuePolClosureLine(
                      context.bi(x.label),
                      f.date(x.from.toString(), DateStyle.dayMonth),
                      f.date(x.to.toString(), DateStyle.dayMonth),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A line of translated prose with figure islands (numbers stay LTR tabular inside the sentence).
class _Fig extends StatelessWidget {
  const _Fig({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(children: GzFigures.spans(context, text, role: GzTextRole.bodyS)),
    style: context.gz.text(GzTextRole.bodyS).copyWith(color: context.gz.colors.textPrimary, decoration: TextDecoration.none),
  );
}

/// Consecutive weekdays read as `Sun – Thu`, otherwise listed.
String _dayNames(GzFormat f, List<int> days) {
  final sorted = [...days]..sort();
  var contiguous = sorted.length > 2;
  for (var i = 1; i < sorted.length && contiguous; i++) {
    if (sorted[i] != sorted[i - 1] + 1) contiguous = false;
  }
  String name(int d) => f.weekdayName(d, NameStyle.short);
  if (contiguous && sorted.length > 2) return '${name(sorted.first)} – ${name(sorted.last)}';
  return f.list([for (final d in sorted) name(d)]);
}

String _clock(GzFormat f, LocalTime t) => f.plain(f.time('2027-01-01T$t'));

/// The per-section facts as glyph chips: present = shown, a rule is its word and a mark.
class _RuleChips extends StatelessWidget {
  const _RuleChips({required this.facts});

  final PolicyFacts facts;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    String ruleLabel(RulePolicy r) => switch (r) {
      RulePolicy.allowed => l.clientVenueRuleAllowed,
      RulePolicy.withApproval => l.clientVenueRuleApproval,
      _ => l.clientVenueRuleNot,
    };
    IconData ruleMark(RulePolicy r) => switch (r) {
      RulePolicy.allowed => GzIcons.check,
      RulePolicy.withApproval => GzIcons.verified,
      _ => GzIcons.minus,
    };
    final chips = <Widget>[
      GzFactChip(
        icon: GzIcons.camera,
        label: l.clientVenueRulePhotography,
        value: switch (facts.photography) {
          PhotographyPolicy.femaleOnly => l.clientVenueRulePhotoFemale,
          PhotographyPolicy.allowed => l.clientVenueRuleAllowed,
          _ => l.clientVenueRuleNone,
        },
      ),
      GzFactChip(
        icon: GzIcons.music,
        label: l.clientVenueRuleMusic,
        value: switch (facts.music) {
          MusicPolicy.djOrBand => l.clientVenueRuleMusicBand,
          MusicPolicy.live => l.clientVenueRuleMusicLive,
          MusicPolicy.duffOnly => l.clientVenueRuleMusicDuff,
          _ => l.clientVenueRuleNone,
        },
      ),
      if (facts.separateEntrance) GzFactChip(icon: GzIcons.door, label: l.clientVenueRuleEntrance),
      if (facts.abayaCloakroom) GzFactChip(icon: GzIcons.dress, label: l.clientVenueRuleCloakroom),
      if (facts.prayerRoom) GzFactChip(icon: GzIcons.prayer, label: l.clientVenueRulePrayer),
      if (facts.femaleSecurity) GzFactChip(icon: GzIcons.shieldCheck, label: l.clientVenueRuleSecurity),
      if (facts.indoorBackup) GzFactChip(icon: GzIcons.home, label: l.clientVenueRuleBackup),
      if (facts.boysMaxAge != null)
        GzFactChip(
          icon: GzIcons.guests,
          label: l.clientVenueRuleBoys,
          valueWidget: GzText('≤${f.integer(facts.boysMaxAge!)}', role: GzTextRole.figBodyS, color: context.gz.colors.textStrong, figures: true),
        ),
      GzFactChip(
        icon: GzIcons.catering,
        label: '${l.clientVenueRuleCatering}: ${ruleLabel(facts.outsideCatering)}',
        valueWidget: GzIcon(ruleMark(facts.outsideCatering), size: GzIconSize.xs, tone: GzIconTone.secondary),
      ),
      GzFactChip(
        icon: GzIcons.decor,
        label: '${l.clientVenueRuleDecor}: ${ruleLabel(facts.outsideDecor)}',
        valueWidget: GzIcon(ruleMark(facts.outsideDecor), size: GzIconSize.xs, tone: GzIconTone.secondary),
      ),
      GzFactChip(
        icon: GzIcons.incense,
        label: '${l.clientVenueRuleBukhoor}: ${ruleLabel(facts.bukhoor)}',
        valueWidget: GzIcon(ruleMark(facts.bukhoor), size: GzIconSize.xs, tone: GzIconTone.secondary),
      ),
      GzFactChip(
        icon: GzIcons.clock,
        label: l.clientVenueRuleCutoff,
        valueWidget: GzText(
          f.plain(f.time('2027-01-01T${facts.cutOff}')),
          role: GzTextRole.figBodyS,
          color: context.gz.colors.textStrong,
          figures: true,
        ),
      ),
      if (facts.extraHour != null)
        GzFactChip(
          icon: GzIcons.plus,
          label: l.clientVenueRuleExtraHour,
          valueWidget: QuietMoney(fils: facts.extraHour!.fils),
        ),
    ];
    return GzFactRow(label: context.l10n.clientVenuePolicyRules, children: chips);
  }
}

// Edges (inventory navigatesTo): 'CL-VENU-01' (Back to venue returns to the detail; nothing else leaves this sheet).
