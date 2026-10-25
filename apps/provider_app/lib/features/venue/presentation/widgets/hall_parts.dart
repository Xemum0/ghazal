// The pieces of the hall editor (web `HallParts.tsx`, `VenueProfile.tsx`): session rows and their sheet, facility rows (Included / Extra / Not
// offered), the per-section facts and the venue profile block.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import 'venue_fields.dart';

const List<int> kBufferMinutes = <int>[0, 30, 60, 90, 120];
const List<(String, String, String)> kSessionPresets = <(String, String, String)>[
  ('afternoon', '12:00', '16:00'),
  ('evening', '20:00', '01:00'),
  ('full', '10:00', '02:00'),
];

/// The facilities a hall states, in reading order (amenity ids of the taxonomy).
const List<String> kHallAmenities = <String>[
  'parking',
  'valet',
  'bridal-suite',
  'groom-room',
  'basic-decor',
  'buffet',
  'kosha',
  'sound-lighting',
  'prayer-room',
  'abaya-cloakroom',
  'separate-entrance',
  'female-security',
  'outside-catering',
  'outside-decor',
  'bukhoor-service',
];

IconData amenityIcon(String id) => switch (id) {
  'parking' => GzIcons.parking,
  'valet' => GzIcons.valet,
  'bridal-suite' => GzIcons.bed,
  'groom-room' => GzIcons.groom,
  'basic-decor' => GzIcons.decor,
  'buffet' => GzIcons.buffet,
  'kosha' => GzIcons.stage,
  'sound-lighting' => GzIcons.sound,
  'prayer-room' => GzIcons.prayer,
  'abaya-cloakroom' => GzIcons.dress,
  'separate-entrance' => GzIcons.door,
  'female-security' => GzIcons.shieldCheck,
  'outside-catering' => GzIcons.catering,
  'outside-decor' => GzIcons.flower,
  'bukhoor-service' => GzIcons.incense,
  _ => GzIcons.check,
};

// ---------------------------------------------------------------- sessions

class SessionRow extends StatelessWidget {
  const SessionRow({required this.session, required this.onOpen, super.key});

  final SessionInput session;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final name = session.name.of(context.gz.locale.languageCode);
    final line = l.hotelVenueSessionLine(kuwaitTime(f, session.start.toString()), kuwaitTime(f, session.end.toString()));
    return GzPressable(
      onPressed: onOpen,
      semanticLabel: '$name, $line',
      minHeight: GzSize.rowMin,
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
        padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GzUserText(name, role: GzTextRole.title, color: c.textPrimary),
                  const SizedBox(height: GzSpace.s1),
                  GzText(line, role: GzTextRole.bodyS, color: c.textStrong, figures: true),
                ],
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary, mirror: true),
          ],
        ),
      ),
    );
  }
}

class SessionSheet extends StatefulWidget {
  const SessionSheet({this.session, required this.onSave, this.onDelete, super.key});

  final SessionInput? session;
  final ValueChanged<SessionInput> onSave;
  final VoidCallback? onDelete;

  @override
  State<SessionSheet> createState() => _SessionSheetState();
}

class _SessionSheetState extends State<SessionSheet> {
  late String _ar = widget.session?.name.ar ?? '';
  late String _en = widget.session?.name.en ?? '';
  late String _start = (widget.session?.start ?? const LocalTime(20, 0)).toString();
  late String _end = (widget.session?.end ?? const LocalTime(1, 0)).toString();
  late int _before = widget.session?.bufferBeforeMin ?? 60;
  late int _after = widget.session?.bufferAfterMin ?? 60;

  bool get _named => _ar.trim().isNotEmpty && _en.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final nav = GzNavigatorScope.of(context);
    final slots = [for (final t in kTimeSlots) GzSelectOption<String>(value: t, label: kuwaitTime(f, t))];
    final presetName = {'afternoon': l.hotelVenuePresetAfternoon, 'evening': l.hotelVenuePresetEvening, 'full': l.hotelVenuePresetFull};
    List<GzChipOption<int>> minutes() => [
      for (final m in kBufferMinutes) GzChipOption<int>(value: m, label: m == 0 ? l.hotelVenueNone : l.commonCountMinutes(m)),
    ];
    return SheetColumn(
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzButton(
            label: l.commonActionSave,
            fullWidth: true,
            reason: _named ? null : l.hotelVenueSessionNameNeeded,
            onPressed: !_named
                ? null
                : () {
                    widget.onSave(
                      SessionInput(
                        id: widget.session?.id,
                        name: LocalizedText(ar: _ar.trim(), en: _en.trim()),
                        start: LocalTime.parse(_start),
                        end: LocalTime.parse(_end),
                        bufferBeforeMin: _before,
                        bufferAfterMin: _after,
                        weekdays: widget.session?.weekdays ?? const [0, 1, 2, 3, 4, 5, 6],
                      ),
                    );
                    nav.closeSheet();
                  },
          ),
          if (widget.onDelete != null) ...[
            const SizedBox(height: GzSpace.s3),
            GzButton(
              label: l.hotelVenueSessionDelete,
              variant: GzButtonVariant.destructive,
              iconStart: GzIcons.trash,
              fullWidth: true,
              onPressed: widget.onDelete,
            ),
          ],
        ],
      ),
      children: [
        if (widget.session == null)
          GzChipGroup<String>(
            label: l.hotelVenuePresetsLabel,
            layout: GzChipLayout.rail,
            value: [
              for (final p in kSessionPresets)
                if (p.$2 == _start && p.$3 == _end) p.$1,
            ].firstOrNull,
            onChanged: (id) {
              final p = kSessionPresets.where((x) => x.$1 == id).firstOrNull;
              if (p != null) {
                setState(() {
                  _start = p.$2;
                  _end = p.$3;
                });
              }
            },
            options: [for (final p in kSessionPresets) GzChipOption<String>(value: p.$1, label: presetName[p.$1]!)],
          ),
        BilingualField(
          label: l.hotelVenueSessionName,
          ar: _ar,
          en: _en,
          onAr: (v) => setState(() => _ar = v),
          onEn: (v) => setState(() => _en = v),
          maxLength: 40,
          required: false,
        ),
        PickRow<String>(label: l.hotelVenueSessionStart, value: _start, options: slots, onChanged: (v) => setState(() => _start = v)),
        PickRow<String>(
          label: l.hotelVenueSessionEnd,
          value: _end,
          options: slots,
          onChanged: (v) => setState(() => _end = v),
          helper: _end.compareTo(_start) <= 0 ? l.hotelVenueSessionAfterMidnight : null,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GzText(l.hotelVenueSessionSetup, role: GzTextRole.label, color: c.textPrimary),
            const SizedBox(height: GzSpace.s2),
            GzChipGroup<int>(
              label: l.hotelVenueSessionSetup,
              layout: GzChipLayout.rail,
              value: _before,
              onChanged: (v) => v == null ? null : setState(() => _before = v),
              options: minutes(),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GzText(l.hotelVenueSessionTeardown, role: GzTextRole.label, color: c.textPrimary),
            const SizedBox(height: GzSpace.s2),
            GzChipGroup<int>(
              label: l.hotelVenueSessionTeardown,
              layout: GzChipLayout.rail,
              value: _after,
              onChanged: (v) => v == null ? null : setState(() => _after = v),
              options: minutes(),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- facilities

/// The facilities as rows: glyph and name above, the state as the value; tapping opens the three-way picker.
class AmenityRows extends StatelessWidget {
  const AmenityRows({required this.ids, required this.labels, required this.states, required this.onChanged, super.key});

  final List<String> ids;
  final Map<String, LocalizedText> labels;
  final Map<String, AmenityState> states;
  final void Function(String id, AmenityState state) onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    final options = [
      GzSelectOption<AmenityState>(value: AmenityState.included, label: l.hotelVenueAmIncluded),
      GzSelectOption<AmenityState>(value: AmenityState.extra, label: l.hotelVenueAmExtra),
      GzSelectOption<AmenityState>(value: AmenityState.notOffered, label: l.hotelVenueAmNone),
    ];
    const ladiesOnly = {'separate-entrance', 'female-security'};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final id in ids)
          if (labels[id] != null)
            Builder(
              builder: (context) {
                final base = labels[id]!.of(lang);
                final name = ladiesOnly.contains(id) ? l.hotelVenueAmenityOf(base, l.hotelVenueAudWomen) : base;
                return PickRow<AmenityState>(
                  variant: GzSelectVariant.row,
                  label: name,
                  value: states[id] ?? AmenityState.notOffered,
                  sheetTitle: l.hotelVenueAmenityChoose(name),
                  options: options,
                  onChanged: (v) => onChanged(id, v),
                  startAdornment: GzIcon(amenityIcon(id), size: GzIconSize.md, color: context.gz.colors.iconSecondary),
                );
              },
            ),
      ],
    );
  }
}

// ---------------------------------------------------------------- section facts

class SectionFacts extends StatelessWidget {
  const SectionFacts({required this.audience, required this.photography, required this.music, required this.onChanged, super.key});

  final Audience audience;
  final PhotographyPolicy photography;
  final MusicPolicy music;
  final void Function(PhotographyPolicy photography, MusicPolicy music) onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final section = switch (audience) {
      Audience.men => l.hotelVenueSectionMen,
      Audience.mixed => l.hotelVenueSectionMixed,
      _ => l.hotelVenueSectionWomen,
    };
    return Container(
      padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: c.borderStrong, width: GzStroke.hair),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzText(section, role: GzTextRole.title, color: c.textStrong),
          const SizedBox(height: GzSpace.s4),
          GzText(l.hotelVenueFactPhoto, role: GzTextRole.label, color: c.textPrimary),
          const SizedBox(height: GzSpace.s2),
          GzChipGroup<PhotographyPolicy>(
            label: '$section: ${l.hotelVenueFactPhoto}',
            value: photography,
            onChanged: (v) => v == null ? null : onChanged(v, music),
            options: [
              GzChipOption(value: PhotographyPolicy.femaleOnly, label: l.hotelVenuePhotoFemale),
              GzChipOption(value: PhotographyPolicy.allowed, label: l.hotelVenuePhotoAllowed),
              GzChipOption(value: PhotographyPolicy.none, label: l.hotelVenuePhotoNone),
            ],
          ),
          const SizedBox(height: GzSpace.s4),
          GzText(l.hotelVenueFactMusic, role: GzTextRole.label, color: c.textPrimary),
          const SizedBox(height: GzSpace.s2),
          GzChipGroup<MusicPolicy>(
            label: '$section: ${l.hotelVenueFactMusic}',
            value: music,
            onChanged: (v) => v == null ? null : onChanged(photography, v),
            options: [
              GzChipOption(value: MusicPolicy.djOrBand, label: l.hotelVenueMusicDj),
              GzChipOption(value: MusicPolicy.live, label: l.hotelVenueMusicLive),
              GzChipOption(value: MusicPolicy.duffOnly, label: l.hotelVenueMusicDuff),
              GzChipOption(value: MusicPolicy.none, label: l.hotelVenueMusicNone),
            ],
          ),
        ],
      ),
    );
  }
}
