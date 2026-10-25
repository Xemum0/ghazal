import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GateReason, GateResume, WidgetSessionGate;
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../venue_glyphs.dart';
import 'venue_money.dart';

bool get _isApple => defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

/// MapsSheet: the directions chooser (CL-VENU-01 location block, CL-VENU-06): Google Maps, Apple Maps (Apple devices only) and Waze.
/// Choosing an app closes the sheet and says which app is opening (the hand-off itself is an F4 item).
class VenueMapsSheet extends StatelessWidget {
  const VenueMapsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = context.gzNav;
    final apps = <(String, IconData)>[
      (l.clientVenueMapsGoogle, GzIcons.map),
      if (_isApple) (l.clientVenueMapsApple, GzIcons.navigate),
      (l.clientVenueMapsWaze, GzIcons.car),
    ];
    void open(String label) {
      nav.closeSheet();
      nav.toast(GzToastSpec(message: l.clientVenueMapsOpening(label), icon: GzIcons.externalLink));
    }

    return Column(
      key: const ValueKey<String>('venue.maps'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < apps.length; i++)
          GzIconListRow(flush: true, chevron: true, last: i == apps.length - 1, icon: apps[i].$2, title: apps[i].$1, onPressed: () => open(apps[i].$1)),
      ],
    );
  }
}

/// ContactSheet (CL-VENU-01 "Contact", the browse-only path of ADR 0033): a guest reaches the venue through its own published channels
/// (phone and WhatsApp) and pays the venue directly at the standard price; no Ghazal object is created. Two rows and one button that
/// asks for the account (chat needs one).
class VenueContactSheet extends ConsumerWidget {
  const VenueContactSheet({required this.venueId, required this.phone, required this.venueName, super.key});

  final String venueId;
  final String? phone;
  final String? venueName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lc = context.gzL10n;
    final nav = context.gzNav;
    final f = context.gzFormat;
    final number = phone == null ? null : GzNum(f.phone(phone!), role: GzTextRole.figBodyS);
    void say(String message, IconData icon) {
      nav.closeSheet();
      nav.toast(GzToastSpec(message: message, icon: icon));
    }

    return Column(
      key: const ValueKey<String>('venue.contact'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzIconListRow(
          flush: true,
          icon: GzIcons.phone,
          title: lc.commonActionCall,
          trailing: number,
          chevron: false,
          onPressed: () => say(l.clientVenueContactCalling(venueName ?? ''), GzIcons.phone),
        ),
        GzIconListRow(
          flush: true,
          last: true,
          icon: GzIcons.whatsapp,
          title: lc.commonActionWhatsapp,
          trailing: number,
          chevron: false,
          onPressed: () => say(l.clientVenueContactWhatsapp, GzIcons.chat),
        ),
        const SizedBox(height: GzSpace.s4),
        GzButton(
          label: l.clientVenueContactChat,
          variant: GzButtonVariant.secondary,
          iconStart: GzIcons.chat,
          fullWidth: true,
          onPressed: () {
            nav.closeSheet();
            if (ref.requireSignIn(GateReason.chat, resume: GateResume('CL-MSGS-02', <String, Object?>{'venueId': venueId}))) {
              nav.push('CL-MSGS-02', params: <String, Object?>{'venueId': venueId});
            }
          },
        ),
      ],
    );
  }
}

/// The full list of facilities in a sheet: every facility with its name and its state, the extra ones with the price they start from.
class VenueFacilitiesSheet extends StatelessWidget {
  const VenueFacilitiesSheet({required this.items, required this.defs, super.key});

  final List<VenueAmenity> items;
  final List<AmenityDef> defs;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final f = context.gzFormat;
    AmenityDef? defOf(String id) => defs.where((d) => d.id == id).firstOrNull;
    const order = <AmenityState, int>{AmenityState.included: 0, AmenityState.extra: 1, AmenityState.notOffered: 2};
    final known = [
      for (final a in items)
        if (defOf(a.amenityId) != null) a,
    ]..sort((a, b) => (order[a.state] ?? 3).compareTo(order[b.state] ?? 3));
    return Column(
      key: const ValueKey<String>('venue.facilities'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < known.length; i++)
          () {
            final a = known[i];
            final off = a.state == AmenityState.notOffered;
            final name = context.bi(defOf(a.amenityId)!.label);
            final stateName = a.state == AmenityState.included ? l.clientVenueFacIncluded : (a.state == AmenityState.extra ? l.clientVenueFacExtra : l.clientVenueFacOff);
            return GzIconListRow(
              flush: true,
              last: i == known.length - 1,
              icon: GzIcons.byName[amenityGlyphName(a.amenityId)],
              title: name,
              tone: GzListRowTone.normal,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzIcon(
                    a.state == AmenityState.included ? GzIcons.check : (a.state == AmenityState.extra ? GzIcons.plus : GzIcons.minus),
                    size: GzIconSize.sm,
                    tone: a.state == AmenityState.included ? GzIconTone.success : GzIconTone.secondary,
                    semanticLabel: stateName,
                  ),
                  if (a.state == AmenityState.extra && a.from != null) ...[
                    const SizedBox(width: GzSpace.s2),
                    GzText(f.plain(f.money(a.from!.fils, const MoneyOptions(mode: MoneyMode.browse))), role: GzTextRole.figBodyS, color: c.textPrimary, figures: true),
                  ],
                ],
              ),
              chevron: false,
              autoDir: off,
            );
          }(),
      ],
    );
  }
}

/// SelfReportSheet (CL-VENU-06 "Mark booked"): the date and the fee the couple paid on the official channel. Honest about what it is: a
/// record for the budget, the checklist and the countdown, not a Ghazal booking (that sentence is behind the (i)).
class VenueSelfReportSheet extends StatefulWidget {
  const VenueSelfReportSheet({required this.defaultDate, required this.defaultFils, required this.onSave, super.key});

  final LocalDate defaultDate;
  final int defaultFils;
  final void Function(LocalDate date, int fils) onSave;

  @override
  State<VenueSelfReportSheet> createState() => _VenueSelfReportSheetState();
}

class _VenueSelfReportSheetState extends State<VenueSelfReportSheet> {
  late LocalDate _date = widget.defaultDate;
  late String _fee = '${widget.defaultFils / 1000}';

  int? _fils(String raw) {
    final n = double.tryParse(context.gzFormat.normalizeDigits(raw).replaceAll(',', '.'));
    if (n == null || !n.isFinite) return null;
    return (n * 1000).round();
  }

  void _pickDate() {
    final nav = context.gzNav;
    nav.openSheetBuilder(
      (_) => GzDateFieldSheetContent(
        value: _date.toString(),
        onConfirm: (v) {
          if (v != null) setState(() => _date = LocalDate.parse(v));
          nav.closeSheet();
        },
      ),
      options: GzSheetOptions(title: gzDateFieldSheetTitle(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final fils = _fils(_fee);
    final valid = fils != null && fils > 0;
    return Column(
      key: const ValueKey<String>('venue.self-report'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzDateField(label: l.clientVenueGovSelfDate, value: _date.toString(), onTap: _pickDate),
        const SizedBox(height: GzSpace.s4),
        GzTextField(
          label: l.clientVenueGovSelfFee,
          value: _fee,
          onValueChange: (v) => setState(() => _fee = v),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          dir: GzFieldDir.ltr,
          startAdornment: GzText(f.moneyParts(0).currency, role: GzTextRole.caption),
        ),
        const SizedBox(height: GzSpace.s4),
        Row(
          children: [
            GzInfoButton(title: l.clientVenueGovSelfInfoTitle, paragraphs: [l.clientVenueGovSelfNote]),
            const SizedBox(width: GzSpace.s2),
            Expanded(
              child: GzButton(label: context.gzL10n.commonActionSave, fullWidth: true, onPressed: valid ? () => widget.onSave(_date, fils) : null),
            ),
          ],
        ),
      ],
    );
  }
}

/// A row of the venue sheets (the glyph rows of the package and policy sheets).
class SheetGlyphRow extends StatelessWidget {
  const SheetGlyphRow({required this.icon, required this.child, this.tone = GzIconTone.secondary, this.size = GzIconSize.md, super.key});

  final IconData icon;
  final Widget child;
  final GzIconTone tone;
  final GzIconSize size;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GzIcon(icon, size: size, tone: tone),
      const SizedBox(width: GzSpace.s3),
      Expanded(child: child),
    ],
  );
}

/// A voucher-saving explanation used by the package sheet's rate line.
Widget quietRate(BuildContext context, int fils) => QuietMoney(fils: fils);

/// The pinned footer of a venue sheet (web `.gzv-sf__foot`): a hairline above, 12 of air, then the actions.
class VenueFootRule extends StatelessWidget {
  const VenueFootRule({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      padding: const EdgeInsets.only(top: GzSpace.s3),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair)),
      ),
      child: child,
    );
  }
}

/// The header of the three venue sheets (web `SheetFrame`): the title at inline-start in the display face with 8 above it, top aligned
/// (not centred on the close button), close at inline-end, 8 below. The sheet supplies the handle; the gutter is drawn here.
class VenueSheetHead extends StatelessWidget {
  const VenueSheetHead({required this.title, required this.onClose, super.key});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.s2, bottom: GzSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
              child: GzText(title, role: GzTextRole.d1, color: c.textStrong, header: true),
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          GzBarButton(key: const ValueKey('gz:sheet.close'), icon: GzIcons.close, label: context.gzL10n.commonActionClose, onPressed: onClose),
        ],
      ),
    );
  }
}
