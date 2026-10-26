import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DecimalOptions, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/services_providers.dart';
import '../services_glyphs.dart';
import 'serv_package_row.dart';
import 'serv_price_stack.dart';

/// Longer than this and the provider's words are clamped to two lines with a chevron (web ABOUT_CLAMP_CHARS).
const int _aboutClampChars = 60;
const List<int> _guestSteps = [50, 100, 150, 200, 250, 300, 350, 400, 500, 600, 800];

/// The body of CL-SERV-03 (web `VendorProfile`): hero, the wall label, the provider's words, Event, packages, how it works.
class ServProfileBody extends ConsumerStatefulWidget {
  const ServProfileBody({
    required this.vendor,
    required this.pkg,
    required this.guest,
    required this.date,
    required this.guests,
    required this.dateError,
    required this.heroIndex,
    required this.onHeroIndex,
    required this.onOpenPhoto,
    required this.onChoose,
    required this.onDate,
    required this.onGuests,
    required this.onAsk,
    required this.onAddBudget,
    required this.budgetFils,
    super.key,
  });

  final ServiceProvider vendor;
  final ProviderPackage? pkg;
  final bool guest;
  final LocalDate? date;
  final int? guests;
  final bool dateError;
  final int heroIndex;
  final ValueChanged<int> onHeroIndex;
  final ValueChanged<int> onOpenPhoto;
  final ValueChanged<String> onChoose;
  final ValueChanged<LocalDate> onDate;
  final ValueChanged<int?> onGuests;
  final VoidCallback onAsk;
  final VoidCallback onAddBudget;
  final int budgetFils;

  @override
  ConsumerState<ServProfileBody> createState() => _ServProfileBodyState();
}

class _ServProfileBodyState extends ConsumerState<ServProfileBody> {
  bool _aboutOpen = false;

  ServiceProvider get v => widget.vendor;

  int? _voucherOf(ProviderPackage p) => p.voucherPrice?.fils;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final name = context.bi(v.name);
    final images = <GzCarouselImage>[for (final p in v.portfolio) GzCarouselImage(src: gzImageSrc(p.file, p.baseUrl), alt: name)];
    final rating = v.rating;
    final areas = ref.watch(servicesAreasProvider).value;
    final area = areas?.areas.where((a) => a.id == v.areaId).firstOrNull?.name;
    final about = context.bi(v.about);
    final perPerson = v.packages.any((p) => p.priceStructure == PriceStructure.perPerson);
    final offers = [
      for (final p in v.packages)
        if (_voucherOf(p) != null) p,
    ];
    final best = offers.isEmpty ? null : offers.reduce((a, b) => _voucherOf(a)! <= _voucherOf(b)! ? a : b);
    final pkg = widget.pkg;

    return Column(
      key: ValueKey<String>('services.profile.${v.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (images.isNotEmpty) _hero(context, images, name),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s5, bottom: GzSpace.section),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The wall label.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: const GzThreadRule(draw: GzDraw.mount),
              ),
              const SizedBox(height: GzSpace.s3),
              GzText(name, role: GzTextRole.d3, color: c.textStrong),
              const SizedBox(height: GzSpace.s3),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: f.isArabic ? 30 : 26), // the web row is the line of its rating span: 30 in Arabic, 26 in English
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: GzFactRow(
                    children: [
                      if (rating != null)
                        GzRating(value: rating.average, count: rating.count)
                      else
                        GzFactChip(
                          icon: GzIcons.sparkle,
                          label: context.gzL10n.commonLabelNew,
                          value: context.gzL10n.commonLabelNew,
                          tone: GzFactTone.accent,
                        ),
                      if (area != null) GzFactChip(icon: GzIcons.pin, label: l.clientServicesArea, value: context.bi(area)),
                      if (v.verified) GzFactChip(icon: GzIcons.verified, label: l.clientServicesProfileVerified, tone: GzFactTone.accent),
                      if (v.femaleTeamForLadies) GzFactChip(icon: GzIcons.sectionWomen, label: l.clientServicesListFemaleTeam),
                      GzFactChip(
                        icon: GzIcons.clock,
                        label: l.clientServicesProfileReply,
                        value: f.plain(f.duration((v.usuallyRepliesHours * 3600000).round())).replaceFirst(RegExp(r'\s0\s(m|د)$'), ''),
                      ),
                    ],
                  ),
                ),
              ),
              if (best != null) ...[
                const SizedBox(height: GzSpace.s3 + GzSpace.s1),
                ServPriceStack(standard: best.price.fils, voucher: _voucherOf(best), categoryId: v.categoryId, guest: widget.guest, inline: true),
              ],
              const SizedBox(height: GzSpace.section),
              GzText(about, role: GzTextRole.body, color: c.textPrimary, maxLines: _aboutOpen ? null : 2),
              if (about.length > _aboutClampChars) ...[
                const SizedBox(height: GzSpace.s1),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: GzIconButton(
                    icon: _aboutOpen ? GzIcons.chevronUp : GzIcons.chevronDown,
                    iconSize: GzIconSize.sm,
                    label: _aboutOpen ? context.gzL10n.commonActionShowLess : l.clientServicesHubMoreHeading,
                    expanded: _aboutOpen,
                    onPressed: () => setState(() => _aboutOpen = !_aboutOpen),
                  ),
                ),
              ],
              const SizedBox(height: GzSpace.section),
              GzSectionHeader(title: l.clientServicesProfileEventTitle, draw: GzDraw.mount),
              const SizedBox(height: GzSpace.s4),
              _event(context, perPerson),
              const SizedBox(height: GzSpace.s4),
              Row(
                children: [
                  GzChip(label: l.clientServicesProfileAsk, iconStart: GzIcons.chat, onPressed: widget.onAsk),
                  const SizedBox(width: GzSpace.s2),
                  GzInfoButton(
                    title: l.clientServicesProfileEventInfoTitle,
                    label: l.clientServicesProfileEventInfoTitle,
                    paragraphs: [l.clientServicesProfileAvailabilityBody, if (best != null) l.clientServicesProfileEventNote],
                  ),
                ],
              ),
              const SizedBox(height: GzSpace.section),
              GzSectionHeader(title: l.clientServicesProfilePackagesTitle, draw: GzDraw.mount),
              const SizedBox(height: GzSpace.s4),
              for (var i = 0; i < v.packages.length; i++) ...[
                if (i > 0) const SizedBox(height: GzSpace.listGap),
                RepaintBoundary(
                  child: ServPackageRow(
                    pkg: v.packages[i],
                    categoryId: v.categoryId,
                    chosen: v.packages[i].id == pkg?.id,
                    onChoose: () => widget.onChoose(v.packages[i].id),
                    voucher: _voucherOf(v.packages[i]),
                    guest: widget.guest,
                    favourite: ref.watch(isFavouriteProvider((SavedType.package, v.packages[i].id))),
                    onFavourite: () => ref.read(favouritesProvider.notifier).toggle(SavedType.package, v.packages[i].id),
                  ),
                ),
              ],
              if (pkg != null) ...[
                const SizedBox(height: GzSpace.s4),
                GzIconListRow(
                  flush: true,
                  last: true,
                  icon: GzIcons.wallet,
                  title: l.clientServicesProfileBudgetTitle,
                  trailing: GzPrice(fils: widget.budgetFils, size: GzPriceSize.strong),
                  onPressed: widget.onAddBudget,
                ),
              ],
              if (best != null) ...[
                const SizedBox(height: GzSpace.section),
                ServHowStrip(
                  title: l.clientServicesHowTitle,
                  steps: [
                    (GzIcons.ticket, context.gzL10n.commonVoucher, l.clientServicesHowPayTitle(f.money(2000)), l.clientServicesHowPayBody),
                    (GzIcons.send, l.clientServicesHowRequestLabel, l.clientServicesHowRequestTitle, l.clientServicesHowRequestBody(_confirmHours())),
                    (GzIcons.receipt, l.clientServicesHowSettleLabel, l.clientServicesHowSettleTitle, l.clientServicesHowSettleBody),
                  ],
                ),
              ],
              const SizedBox(height: GzSpace.section),
              GzSectionHeader(title: l.clientServicesProfileReviewsTitle, draw: GzDraw.mount),
              const SizedBox(height: GzSpace.s4),
              if (rating != null) _score(context, rating.average, rating.count) else _unrated(context),
            ],
          ),
        ),
      ],
    );
  }

  /// The provider's score: the average in the large figure face, the star and the number of ratings (the review texts have no source yet).
  Widget _score(BuildContext context, double average, int count) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    const one = DecimalOptions(minFraction: 1, maxFraction: 1);
    return Semantics(
      container: true,
      label: context.gzL10n.commonA11yRating((average * 10).round() / 10, 5),
      child: ExcludeSemantics(
        child: Row(
          children: [
            gzFigText(context, f.number(average, one), role: GzTextRole.fig3xl, color: c.textStrong),
            const SizedBox(width: GzSpace.s4),
            const GzIcon(GzIcons.starFill, size: GzIconSize.sm, tone: GzIconTone.accent),
            const SizedBox(width: GzSpace.s1),
            gzFigText(context, '(${f.integer(count)})', role: GzTextRole.figBodyS, color: c.textSecondary),
          ],
        ),
      ),
    );
  }

  /// A provider with no rating yet: the empty shelf and the word "New".
  Widget _unrated(BuildContext context) {
    final word = context.gzL10n.commonLabelNew;
    return Row(
      children: [
        const GzIllustration(GzIllustrationName.shelf, size: GzIllustrationSize.md),
        const SizedBox(width: GzSpace.s4),
        GzFactChip(icon: GzIcons.sparkle, label: word, value: word, tone: GzFactTone.accent),
      ],
    );
  }

  String _confirmHours() {
    final hours = ref.watch(servicesConfirmHoursProvider).value;
    if (hours == null) return '';
    final f = ref.watch(gzFormatProvider);
    return f.plain(f.duration(hours * 3600000));
  }

  Widget _hero(BuildContext context, List<GzCarouselImage> images, String name) {
    // The web item is 4:3 of the 430 max width: the photograph is as wide as that at this height and is clipped at inline-end.
    final c = context.gz.colors;
    final index = widget.heroIndex.clamp(0, images.length - 1);
    final label = context.l10n.clientServicesProfileHeroLabel(name);
    return RepaintBoundary(
      child: SizedBox(
        height: GzLayout.maxWidth / GzLayout.aspect4x3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GzPager(
              mode: GzPagerMode.full,
              index: index,
              onIndexChanged: widget.onHeroIndex,
              label: label,
              children: [
                for (var i = 0; i < images.length; i++)
                  GzPressable(
                    onPressed: () => widget.onOpenPhoto(i),
                    semanticLabel: label,
                    scale: 1,
                    borderRadius: BorderRadius.zero,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: AlignmentDirectional.centerStart,
                        minWidth: GzLayout.maxWidth,
                        maxWidth: GzLayout.maxWidth,
                        child: GzPhoto(src: images[i].src, alt: '', fit: BoxFit.cover, priority: i == index),
                      ),
                    ),
                  ),
              ],
            ),
            if (images.length > 1) ...[
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                height: GzSpace.s24,
                child: IgnorePointer(
                  child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.scrimClear, c.scrimBottom]))),
                ),
              ),
              PositionedDirectional(
                start: GzSpace.gutter,
                end: GzSpace.gutter,
                bottom: GzSpace.s4,
                child: IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GzPagerProgress(count: images.length, index: index),
                      const SizedBox(height: GzSpace.s2),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: GzText(context.gzL10n.commonCounter(index + 1, images.length), role: GzTextRole.caption, color: c.textOnDark, semanticLabel: context.gzL10n.commonA11yPhotoCounter(index + 1, images.length)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _event(BuildContext context, bool perPerson) {
    final l = context.l10n;
    final nav = context.gzNav;
    final fmt = context.gzFormat;
    final steps = <int>{..._guestSteps, if (widget.guests != null) widget.guests!}.toList()..sort();
    final options = [
      GzSelectOption<String>(value: 'none', label: context.gzL10n.commonLabelNotDecided),
      for (final n in steps) GzSelectOption<String>(value: '$n', label: fmt.integer(n)),
    ];
    final selected = widget.guests == null ? 'none' : '${widget.guests}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GzDateField(
            value: widget.date?.toString(),
            placeholder: l.clientServicesQuoteDatePlaceholder,
            error: widget.dateError ? l.clientServicesQuoteDateError : null,
            onTap: () => nav.openSheetBuilder(
              (_) => GzDateFieldSheetContent(
                value: widget.date?.toString(),
                onConfirm: (d) {
                  if (d != null) widget.onDate(LocalDate.parse(d));
                  nav.closeSheet();
                },
              ),
              options: GzSheetOptions(title: l.clientServicesQuoteDatePlaceholder),
            ),
          ),
        ),
        if (perPerson) ...[
          const SizedBox(width: GzSpace.s3),
          SizedBox(
            width: 120,
            child: GzSelectRow<String>(
              label: '',
              options: options,
              values: [selected],
              startAdornment: const GzIcon(GzIcons.usersThree, size: GzIconSize.sm, tone: GzIconTone.secondary),
              onTap: () => nav.openSheetBuilder(
                (_) => GzPickerList<String>(
                  options: options,
                  selected: [selected],
                  onPick: (id) {
                    widget.onGuests(id == 'none' ? null : int.parse(id));
                    nav.closeSheet();
                  },
                ),
                options: GzSheetOptions(title: l.clientServicesQuoteGuests),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
