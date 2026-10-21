import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show FaqItem, MusicPolicy, PhotographyPolicy, PolicyFacts, RulePolicy;

import '../core/core.dart';
import '../foundation.dart';
import '../overlays/gz_accordion.dart';

/// One extra line of the policy list (children, dress code ...): a label and a value already in the current language.
@immutable
class GzPolicyTerm {
  const GzPolicyTerm({required this.label, required this.value});

  final String label;
  final String value;
}

/// PolicyList (web `PolicyList`, CL-VENU): per-section policy facts as plain labelled rows (icon and label at the start, the value at
/// the end), never a judgement: photography, music, entrance, cloakroom, prayer room, security, boys, outside catering and decor,
/// bukhoor, cut-off, an extra hour and the indoor backup, then the [extra] terms.
class GzPolicyList extends StatelessWidget {
  const GzPolicyList({required this.facts, this.extra = const [], super.key});

  final PolicyFacts facts;
  final List<GzPolicyTerm> extra;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    String rule(RulePolicy r) => switch (r) {
      RulePolicy.allowed => l.uiClientVenueInfoAllowed,
      RulePolicy.withApproval => l.uiClientVenueInfoApproval,
      _ => l.uiClientVenueInfoNotAllowed,
    };
    final rows = <(IconData, String, String)>[
      (
        GzIcons.camera,
        l.uiClientVenueInfoPhotography,
        switch (facts.photography) {
          PhotographyPolicy.femaleOnly => l.uiClientVenueInfoPhotoFemale,
          PhotographyPolicy.allowed => l.uiClientVenueInfoPhotoAllowed,
          _ => l.uiClientVenueInfoPhotoNone,
        },
      ),
      (
        GzIcons.music,
        l.uiClientVenueInfoMusic,
        switch (facts.music) {
          MusicPolicy.djOrBand => l.uiClientVenueInfoMusicBand,
          MusicPolicy.live => l.uiClientVenueInfoMusicLive,
          MusicPolicy.duffOnly => l.uiClientVenueInfoMusicDuff,
          _ => l.uiClientVenueInfoMusicNone,
        },
      ),
      (GzIcons.door, l.uiClientVenueInfoEntrance, facts.separateEntrance ? l.uiClientVenueInfoSeparate : l.uiClientVenueInfoNo),
      (GzIcons.dress, l.uiClientVenueInfoCloakroom, facts.abayaCloakroom ? l.uiClientVenueInfoAvailable : l.uiClientVenueInfoNo),
      (GzIcons.home, l.uiClientVenueInfoPrayer, facts.prayerRoom ? l.uiClientVenueInfoAvailable : l.uiClientVenueInfoNo),
      (GzIcons.shieldCheck, l.uiClientVenueInfoSecurity, facts.femaleSecurity ? l.uiClientVenueInfoSecurityFemale : l.uiClientVenueInfoNo),
      (
        GzIcons.guests,
        l.uiClientVenueInfoBoys,
        facts.boysMaxAge == null ? l.uiClientVenueInfoBoysAny : l.uiClientVenueInfoBoysUpTo(f.integer(facts.boysMaxAge!)),
      ),
      (GzIcons.catering, l.uiClientVenueInfoCatering, rule(facts.outsideCatering)),
      (GzIcons.decor, l.uiClientVenueInfoDecor, rule(facts.outsideDecor)),
      (GzIcons.sparkle, l.uiClientVenueInfoBukhoor, rule(facts.bukhoor)),
      (GzIcons.clock, l.uiClientVenueInfoCutOff, f.time('2000-01-01T${facts.cutOff}')),
      if (facts.extraHour != null) (GzIcons.clock, l.uiClientVenueInfoExtraHour, f.money(facts.extraHour!.fils)),
      if (facts.indoorBackup) (GzIcons.home, l.uiClientVenueInfoBackup, l.uiClientVenueInfoAvailable),
      for (final e in extra) (GzIcons.info, e.label, e.value),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (icon, label, value) in rows)
          Semantics(
            container: true,
            label: label,
            value: value,
            child: ExcludeSemantics(
              child: Container(
                constraints: const BoxConstraints(minHeight: GzSize.touchMin),
                padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PolicyLabel(icon: icon, label: label),
                    const SizedBox(width: GzSpace.s4),
                    Expanded(
                      child: GzText(value, role: GzTextRole.bodyS, color: c.textStrong, figures: true, textAlign: TextAlign.end),
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

/// FaqAccordion (web `FaqAccordion`): the shared accordion over a venue's own questions (single open by default).
class GzFaqAccordion extends StatelessWidget {
  const GzFaqAccordion({required this.items, this.defaultOpenId, this.multiple = false, super.key});

  final List<FaqItem> items;
  final String? defaultOpenId;
  final bool multiple;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    return GzAccordion(
      multiple: multiple,
      initialOpenIds: defaultOpenId == null ? const [] : [defaultOpenId!],
      items: [
        for (final q in items)
          GzAccordionItem(
            id: q.id,
            title: q.question.of(lang),
            content: SizedBox(
              width: double.infinity,
              child: Text(
                q.answer.of(lang),
                style: context.gz.text(GzTextRole.bodyS).copyWith(color: c.textPrimary, decoration: TextDecoration.none),
              ),
            ),
          ),
      ],
    );
  }
}

/// The icon and label of a policy row in the web's 88 wide box. A CSS flex item never breaks inside a word (`min-width: auto`): the label
/// wraps at spaces to the room beside the icon but grows to its longest word when that is wider, and the box then overflows into the
/// gap beside it. Laid out as a stack so nothing is clipped or flagged as overflowing.
class _PolicyLabel extends StatelessWidget {
  const _PolicyLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final style = gz.text(GzTextRole.caption).copyWith(color: c.textSecondary, decoration: TextDecoration.none);
    const room = GzSize.weekStrip - GzSize.iconSm - GzSpace.s2;
    var widest = 0.0;
    for (final word in label.split(' ')) {
      final tp = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: gz.textDirection,
        maxLines: 1,
      )..layout();
      if (tp.width > widest) widest = tp.width;
      tp.dispose();
    }
    final textWidth = widest > room ? widest : room;
    final tp = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: gz.textDirection,
    )..layout(maxWidth: textWidth);
    final textHeight = tp.height;
    tp.dispose();
    final boxHeight = textHeight > GzSize.iconSm ? textHeight : GzSize.iconSm;
    return SizedBox(
      width: GzSize.weekStrip,
      height: boxHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            start: 0,
            top: (boxHeight - GzSize.iconSm) / 2,
            child: GzIcon(icon, size: GzIconSize.sm, color: c.iconSecondary),
          ),
          PositionedDirectional(
            start: GzSize.iconSm + GzSpace.s2,
            top: (boxHeight - textHeight) / 2,
            width: textWidth,
            child: Text(label, style: style),
          ),
        ],
      ),
    );
  }
}
