// CL-PROF-02 Wedding info. Port of CL-PROF-02.tsx. Requirements: CA-PROF-02, CA-ONB-03 .. 09, CA-TOOL-17.
// The wedding file, viewable and editable at any time: rings and the days to go on top, one glyph row per answer (role, date, guests,
// venue budget, governorates) and the two name fields. Every field is optional. Autosave per field with a quiet "Saved" toast, no Save button.
// An edit writes the profile and the part of the Brief it feeds. If a booking sits on another date a strip names the hotel and offers
// "Use date". The Brief budget and the total wedding budget are different numbers: the second lives in My Wedding.
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, MoneyMode, MoneyOptions, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show DateMode, Governorate, LocalDate, WeddingProfile, WeddingProfileInput, WeddingRole;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../application/profile_activity.dart';
import '../application/wedding_edit.dart';
import 'widgets/profile_parts.dart';
import 'widgets/wedding_sheets.dart';

class ClProf02Screen extends ConsumerWidget {
  const ClProf02Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(gzFormatProvider);
    final userId = ref.watch(clientUserIdProvider) ?? '';
    return GzScreen(
      top: GzTopBar(title: context.l10n.clientProfileWedTitle),
      child: GzAsyncView<WeddingProfile?>(
        value: ref.watch(weddingProfileProvider),
        loading: const _Skeleton(),
        onRetry: () => ref.invalidate(weddingProfileProvider),
        data: (p) => _Body(profile: p ?? blankWedding(userId, LocalDate.parse(f.isoDay(f.now())))),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.gzL10n.commonStateLoading,
    container: true,
    child: Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, start: GzSpace.gutter, end: GzSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 96),
          for (var i = 0; i < 5; i++) ...[const SizedBox(height: GzSpace.s3), const GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 64)],
        ],
      ),
    ),
  );
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.profile});

  final WeddingProfile profile;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late final TextEditingController _name = TextEditingController(text: widget.profile.brideName);
  late final TextEditingController _partner = TextEditingController(text: widget.profile.partnerName ?? '');
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _partnerFocus = FocusNode();
  late String _nameShown = widget.profile.brideName;
  late String _partnerShown = widget.profile.partnerName ?? '';

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) _saveName();
    });
    _partnerFocus.addListener(() {
      if (!_partnerFocus.hasFocus) _savePartner();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _partner.dispose();
    _nameFocus.dispose();
    _partnerFocus.dispose();
    super.dispose();
  }

  void _saved() => context.gzNav.toast(GzToastSpec(message: context.gzL10n.commonStateSaved, icon: GzIcons.check));

  Future<void> _write(WeddingProfileInput input) async {
    final nav = context.gzNav;
    final failed = context.l10n.clientProfileSharedSaveFailed;
    final saved = context.gzL10n.commonStateSaved;
    final problem = await saveWedding(ref, input);
    nav.toast(problem == null ? GzToastSpec(message: saved, icon: GzIcons.check) : GzToastSpec(message: failed, tone: GzToastTone.danger));
  }

  void _saveName() {
    final v = _nameShown.trim();
    if (v == widget.profile.brideName || v.isEmpty) return;
    _write(WeddingProfileInput(brideName: v));
  }

  void _savePartner() {
    final v = _partnerShown.trim();
    if (v == (widget.profile.partnerName ?? '') || v.isEmpty) return;
    _write(WeddingProfileInput(partnerName: v));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = ref.watch(gzFormatProvider);
    final nav = context.gzNav;
    final lang = context.gz.locale.languageCode;
    final p = widget.profile;
    final none = context.gzL10n.commonLabelNotDecided;
    final undecided = p.dateMode == DateMode.undecided;
    final iso = undecided ? null : p.weddingDate.toString();
    final exact = iso != null && p.dateMode == DateMode.exact;
    final hijri = exact ? f.dateWithHijri(iso).secondary : null;
    final dateValue = iso == null ? none : (exact ? f.date(iso, DateStyle.full) : f.date(iso, DateStyle.monthYear));
    final women = p.guests.women;
    final men = p.guests.men;
    final budget = p.venueBudget;
    final hasBudget = budget.min.fils > 0 || budget.max.fils > 0;
    const browse = MoneyOptions(mode: MoneyMode.browse);
    final budgetValue = !hasBudget ? none : (isOpenProfileBudget(budget.max.fils) ? l.clientDiscoverBriefBudgetOver(f.money(budget.min.fils, browse)) : f.moneyRange(budget.min.fils, budget.max.fils, browse));
    final areas = ref.watch(profileAreasProvider).value;
    final regionIds = profileGovernorateIds(p, areas);
    final regionNames = <String>[
      for (final id in regionIds)
        for (final g in areas?.governorates ?? const <Governorate>[]) if (g.id == id) g.name.of(lang),
    ];
    final regionValue = regionNames.isEmpty ? none : regionNames.join(lang == 'ar' ? '، ' : ', ');
    final partnerLabel = switch (p.role) {
      WeddingRole.bride => l.clientProfileWedPartnerGroom,
      WeddingRole.groom => l.clientProfileWedPartnerBride,
      WeddingRole.family || WeddingRole.planner => l.clientProfileWedPartnerCouple,
      _ => l.clientProfileWedPartnerDefault,
    };
    final roleIcon = switch (p.role) {
      WeddingRole.bride => GzIcons.dress,
      WeddingRole.groom => GzIcons.groom,
      WeddingRole.planner => GzIcons.clipboard,
      _ => GzIcons.team,
    };
    final daysToGo = iso == null ? 0 : f.daysUntil(iso);

    // A booking on another date than the wedding file.
    final request = ref.watch(profileActivityProvider).value?.request;
    final bookingDate = request?.booking.eventDate;
    final differs = request != null && bookingDate != null && iso != null && bookingDate.toString() != iso;

    Widget guestsAnswer() => women + men > 0
        ? GzFactRow(
            children: [
              if (women > 0) GzFactChip(icon: GzIcons.sectionWomen, value: f.integer(women), label: l.clientProfileWedLadies),
              if (men > 0) GzFactChip(icon: GzIcons.sectionMen, value: f.integer(men), label: l.clientProfileWedMen),
            ],
          )
        : Text(none);

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: kProfPad,
            child: Row(
              children: [
                const GzIllustration(GzIllustrationName.rings, size: GzIllustrationSize.md),
                if (daysToGo > 0) ...[
                  const SizedBox(width: GzSpace.s6),
                  GzIconStat(icon: GzIcons.countdown, value: f.integer(daysToGo), unit: l.clientProfileWedDaysUnit(daysToGo), label: l.clientProfileWedCountdown, layout: GzFactLayout.inline, accent: true),
                ],
              ],
            ),
          ),
          if (differs) ...[
            const SizedBox(height: GzSpace.s6),
            Padding(
              padding: kProfPad,
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4, vertical: GzSpace.s3),
                decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.smAll),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        GzIcon(GzIcons.hotel, size: GzIconSize.sm, color: c.iconSecondary),
                        const SizedBox(width: GzSpace.s2),
                        Expanded(child: GzText(request.target.name.of(lang), color: c.textStrong)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GzFactChip(icon: GzIcons.calendar, value: f.date(bookingDate.toString(), DateStyle.full), label: l.clientProfileWedDate),
                        GzButton(
                          label: l.clientProfileWedDiffersAction,
                          variant: GzButtonVariant.tertiary,
                          onPressed: () async {
                            final msg = l.clientProfileWedDateUpdated;
                            final problem = await saveWedding(ref, WeddingProfileInput(weddingDate: bookingDate, dateMode: DateMode.exact));
                            if (problem == null) nav.toast(GzToastSpec(message: msg, tone: GzToastTone.success));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: GzSpace.s6),
          ProfPickRow(
            icon: roleIcon,
            label: l.clientProfileWedRole,
            answer: Text(roleLabel(context, p.role)),
            last: true,
            onPressed: () => openWeddingSheet(context, title: l.clientProfileWedRole, child: RoleSheet(profile: p, onSaved: _saved)),
          ),
          const SizedBox(height: GzSpace.s6),
          Padding(
            padding: kProfPad,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GzTextField(label: l.clientProfileWedName, value: _name.text, onValueChange: (v) => _nameShown = v, focusNode: _nameFocus, autofillHints: const [AutofillHints.name]),
                const SizedBox(height: GzSpace.s4),
                GzTextField(label: partnerLabel, value: _partner.text, onValueChange: (v) => _partnerShown = v, focusNode: _partnerFocus),
              ],
            ),
          ),
          const SizedBox(height: GzSpace.s6),
          ProfPickRow(
            icon: GzIcons.calendar,
            label: l.clientProfileWedDate,
            answer: GzText(dateValue, role: GzTextRole.title, color: iso == null ? c.textSecondary : c.textStrong, figures: true),
            sub: hijri,
            empty: iso == null,
            onPressed: () => openWeddingSheet(context, title: l.clientProfileWedDate, fill: true, child: DateSheet(profile: p, onSaved: _saved)),
          ),
          ProfPickRow(
            icon: GzIcons.guests,
            label: l.clientProfileWedGuests,
            answer: guestsAnswer(),
            empty: women + men == 0,
            onPressed: () => openWeddingSheet(context, title: l.clientProfileWedGuests, child: GuestsSheet(profile: p, onSaved: _saved)),
          ),
          ProfPickRow(
            icon: GzIcons.coins,
            label: l.clientProfileWedBudget,
            answer: GzText(budgetValue, role: GzTextRole.title, color: hasBudget ? c.textStrong : c.textSecondary, figures: true),
            empty: !hasBudget,
            onPressed: () => openWeddingSheet(context, title: l.clientProfileWedBudget, fill: true, child: BudgetSheet(profile: p, onSaved: _saved)),
          ),
          ProfPickRow(
            icon: GzIcons.pin,
            label: l.clientProfileWedGovernorates,
            answer: Text(regionValue),
            empty: regionNames.isEmpty,
            onPressed: () => openWeddingSheet(context, title: l.clientProfileWedGovernorates, fill: true, child: GovernoratesSheet(profile: p, onSaved: _saved)),
          ),
          GzIconListRow(
            icon: GzIcons.wallet,
            title: l.clientProfileWedTotal,
            trailing: p.totalBudget.fils > 0 ? GzText(f.money(p.totalBudget.fils), role: GzTextRole.figBody, color: c.textSecondary, figures: true) : null,
            chevron: true,
            last: true,
            onPressed: () => nav.push('CL-WEDD-03'),
          ),
        ],
      ),
    );
  }
}
