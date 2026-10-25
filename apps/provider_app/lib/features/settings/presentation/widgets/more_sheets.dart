// The overlays of the More root (web `MoreParts.tsx`): the language sheet (two options in their own script), the venue switcher, the listing
// preview ("what couples see") and the account-type sheet. Each is the content of a `GzSheet`; the screen opens it with `openSheetBuilder`.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show localeProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show PartnerAccountType;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/state/state.dart';
import '../../../../l10n/l10n.dart';
import '../../application/settings_data.dart';

/// A glyph disk (the script glyph of a language, or an icon) the rows of these sheets share.
class _Disk extends StatelessWidget {
  const _Disk({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: GzSize.avatarSm,
    height: GzSize.avatarSm,
    alignment: Alignment.center,
    decoration: BoxDecoration(shape: BoxShape.circle, color: context.gz.colors.surfaceTint),
    child: child,
  );
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.children, required this.label, required this.onPressed, this.selected, this.minHeight = GzSize.rowMin});

  final List<Widget> children;
  final String label;
  final VoidCallback onPressed;
  final bool? selected;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: label,
      selected: selected,
      minHeight: minHeight,
      scale: 1,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
        child: ExcludeSemantics(child: Row(children: children)),
      ),
    );
  }
}

/// Two options in their own script with a glyph disk and a check on the current one. Choosing flips direction and text at once.
class LanguageContent extends ConsumerWidget {
  const LanguageContent({required this.onChosen, super.key});

  /// Called after the choice is made, with the language chosen (the screen closes the sheet and says "Language saved" in it).
  final ValueChanged<String> onChosen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.gz.colors;
    final current = context.gz.locale.languageCode;
    const options = [('ar', 'العربية', 'ع'), ('en', 'English', 'En')];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final o in options)
          _SheetRow(
            label: o.$2,
            selected: current == o.$1,
            onPressed: () {
              if (o.$1 != current) ref.read(localeProvider.notifier).setLocale(Locale(o.$1));
              onChosen(o.$1);
            },
            children: [
              _Disk(
                child: Directionality(textDirection: o.$1 == 'ar' ? TextDirection.rtl : TextDirection.ltr, child: GzText(o.$3, role: GzTextRole.label, color: c.textStrong)),
              ),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: Directionality(textDirection: o.$1 == 'ar' ? TextDirection.rtl : TextDirection.ltr, child: GzText(o.$2, color: c.textStrong)),
              ),
              if (current == o.$1) GzIcon(GzIcons.check, size: GzIconSize.sm, color: c.iconPrimary),
            ],
          ),
      ],
    );
  }
}

/// The venues of this account: a monogram, the name, the role held there and what waits (a clock and a count).
class VenueSwitcherContent extends ConsumerWidget {
  const VenueSwitcherContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final nav = GzNavigatorScope.of(context);
    final ctx = ref.watch(partnerContextProvider);
    final rows = (ref.watch(partnerMembershipsProvider).value ?? const []).where((m) => m.accountType == PartnerAccountType.venue).toList();
    String role(String r) => switch (r) {
      'reception' => l.hotelSettingsRoleReception,
      'manager' => l.hotelSettingsRoleManager,
      _ => l.hotelSettingsRoleOwner,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in rows)
          _SheetRow(
            minHeight: GzSize.rowQueue,
            label: m.accountName.of(lang),
            selected: m.accountId == ctx?.accountId && m.venueId == ctx?.venueId,
            onPressed: () async {
              nav.closeSheet();
              if (m.accountId != ctx?.accountId || m.venueId != ctx?.venueId) {
                final r = await ref.read(partnerContextProvider.notifier).switchTo(m.accountId, venueId: m.venueId, providerId: m.providerId);
                if (r.isSuccess) nav.toast(GzToastSpec(message: m.accountName.of(lang), tone: GzToastTone.success, icon: GzIcons.swap));
              }
            },
            children: [
              GzAvatar(name: m.accountName.of(lang), size: GzAvatarSize.sm, voice: GzAvatarVoice.sans),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GzUserText(m.accountName.of(lang), role: GzTextRole.d1, color: c.textStrong),
                    const SizedBox(height: GzSpace.s1),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: GzSpace.s3,
                      children: [
                        GzBadge(label: role(m.role.value), variant: GzBadgeVariant.quiet, bead: false),
                        if (m.pendingRequests > 0) GzFactChip(icon: GzIcons.clock, tone: GzFactTone.muted, small: true, label: context.gzL10n.commonStatusPending, value: f.integer(m.pendingRequests)),
                      ],
                    ),
                  ],
                ),
              ),
              if (m.accountId == ctx?.accountId && m.venueId == ctx?.venueId) Semantics(label: l.hotelSettingsSwitchCurrent, child: GzIcon(GzIcons.check, size: GzIconSize.sm, color: c.iconPrimary)),
            ],
          ),
      ],
    );
  }
}

/// What couples see: the cover photograph, the name, the area and the rating, in the order of the client's venue page.
class PreviewContent extends ConsumerWidget {
  const PreviewContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final nav = GzNavigatorScope.of(context);
    final venue = ref.watch(partnerVenueProvider).value?.venue;
    final areas = ref.watch(areasLookupProvider).value;
    if (venue == null) return const SizedBox(height: GzSpace.s24);
    final area = areas?[venue.areaId];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (venue.cover != null)
          SizedBox(
            height: 160,
            child: ClipRRect(borderRadius: GzRadius.mdAll, child: GzPhoto(src: gzImageSrc(venue.cover!.file, venue.cover!.baseUrl), alt: venue.cover!.alt.of(lang), priority: true)),
          ),
        const SizedBox(height: GzSpace.s4),
        GzUserText(venue.name.of(lang), role: GzTextRole.d2, color: c.textStrong),
        const SizedBox(height: GzSpace.s1),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: GzSpace.s3,
          children: [
            if (area != null) GzUserText(area.of(lang), role: GzTextRole.bodyS, color: c.textSecondary),
            if (venue.rating.average != null) GzRating(value: venue.rating.average!, count: venue.rating.count),
          ],
        ),
        const SizedBox(height: GzSpace.s4),
        GzButton(label: context.gzL10n.commonActionClose, variant: GzButtonVariant.secondary, fullWidth: true, onPressed: nav.closeSheet),
      ],
    );
  }
}

/// The two account types of the Partner app, a check on the one in use, and the way to add the other (A-06).
class AccountTypeContent extends ConsumerWidget {
  const AccountTypeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final nav = GzNavigatorScope.of(context);
    final lang = context.gz.locale.languageCode;
    final ctx = ref.watch(partnerContextProvider);
    final memberships = ref.watch(partnerMembershipsProvider).value ?? const [];
    final options = [
      (PartnerAccountType.venue, GzIcons.hotel, l.hotelSettingsAcctVenue),
      (PartnerAccountType.serviceProvider, GzIcons.megaphone, l.hotelSettingsAcctProvider),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final o in options)
          _SheetRow(
            minHeight: GzSize.rowQueue,
            label: o.$3,
            selected: ctx?.accountType == o.$1,
            onPressed: () async {
              nav.closeSheet();
              if (ctx?.accountType == o.$1) return;
              final target = memberships.where((m) => m.accountType == o.$1).firstOrNull;
              if (target == null) {
                nav.push('HL-PROV-01', params: {'account': ctx?.isProvider == true ? 'provider' : 'venue'});
                return;
              }
              final r = await ref.read(partnerContextProvider.notifier).switchTo(target.accountId, venueId: target.venueId, providerId: target.providerId);
              if (r.isSuccess) nav.toast(GzToastSpec(message: target.accountName.of(lang), tone: GzToastTone.success, icon: GzIcons.checkCircle));
            },
            children: [
              _Disk(child: GzIcon(o.$2, size: GzIconSize.md, color: c.iconPrimary)),
              const SizedBox(width: GzSpace.s3),
              Expanded(child: GzText(o.$3, role: GzTextRole.title, color: c.textStrong)),
              if (ctx?.accountType == o.$1) GzIcon(GzIcons.check, size: GzIconSize.sm, color: c.iconPrimary),
            ],
          ),
        const SizedBox(height: GzSpace.s3),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: GzButton(
            label: l.hotelSettingsAcctSetup,
            variant: GzButtonVariant.tertiary,
            iconStart: GzIcons.plus,
            onPressed: () {
              nav.closeSheet();
              nav.push('HL-PROV-01', params: {'account': ctx?.isProvider == true ? 'provider' : 'venue'});
            },
          ),
        ),
      ],
    );
  }
}
