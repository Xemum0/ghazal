// The hall editor of HL-VENU-04 (web `HallEditor`): name, capacity bounds, audiences and setting, sessions, facilities as Included / Extra / Not
// offered rows and per-section facts. It keeps its own draft and writes only on Save (the hall, and the venue's facilities when they changed).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/venue_data.dart';
import 'hall_parts.dart';
import 'venue_bits.dart';
import 'venue_fields.dart';
import 'venue_labels.dart';
import 'venue_profile.dart';

const List<Audience> _audiences = <Audience>[Audience.women, Audience.men, Audience.mixed];
const List<HallSetting> _settings = <HallSetting>[HallSetting.indoor, HallSetting.outdoor, HallSetting.mixed];
const List<int> _guestPresets = <int>[100, 150, 200, 300, 400, 500, 650, 800, 1000];
const int _guestHardCap = 1500;

class _Draft {
  _Draft(this.hall, List<VenueAmenity> amenities)
    : ar = hall.name.ar ?? '',
      en = hall.name.en ?? '',
      setting = hall.setting,
      capMax = hall.capacity.max,
      exclusive = hall.exclusiveDay,
      sessions = [for (final s in hall.sessions) sessionInputOf(s)],
      audiences = [for (final s in hall.sections) s.audience],
      mins = {for (final s in hall.sections) s.audience: s.minGuests},
      photo = {for (final s in hall.sections) s.audience: s.policy.photography},
      music = {for (final s in hall.sections) s.audience: s.policy.music},
      states = {for (final a in amenities) a.amenityId: a.state};

  final Hall hall;
  String ar;
  String en;
  HallSetting setting;
  int capMax;
  bool exclusive;
  List<SessionInput> sessions;
  List<Audience> audiences;
  Map<Audience, int> mins;
  Map<Audience, PhotographyPolicy> photo;
  Map<Audience, MusicPolicy> music;
  Map<String, AmenityState> states;

  String get signature =>
      '$ar|$en|${setting.value}|$capMax|$exclusive|${audiences.map((a) => '${a.value}:${mins[a]}:${photo[a]?.value}:${music[a]?.value}').join(',')}|'
      '${sessions.map((s) => '${s.id}:${s.name.ar}:${s.name.en}:${s.start}:${s.end}:${s.bufferBeforeMin}:${s.bufferAfterMin}').join(',')}|${(states.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((e) => '${e.key}:${e.value.value}').join(',')}';
}

class HallEditor extends ConsumerStatefulWidget {
  const HallEditor({required this.hall, required this.single, super.key});

  final Hall hall;
  final bool single;

  @override
  ConsumerState<HallEditor> createState() => _HallEditorState();
}

class _HallEditorState extends ConsumerState<HallEditor> {
  _Draft? _d;
  String _base = '';
  List<VenueAmenity> _amenities = const [];

  bool get _dirty => _d != null && _d!.signature != _base;

  bool _minBad(_Draft d, Audience a) => d.audiences.contains(a) && (d.mins[a] ?? 0) >= d.capMax;

  Future<void> _save() async {
    final d = _d!;
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final actions = ref.read(venueActionsProvider.notifier);
    final h = widget.hall;
    final sections = <HallSection>[];
    for (final a in _audiences.where(d.audiences.contains)) {
      final old = h.sections.where((s) => s.audience == a).firstOrNull ?? h.sections.first;
      sections.add(
        HallSection(
          audience: a,
          minGuests: d.mins[a] ?? 100,
          maxGuests: d.capMax,
          policy: old.policy.copyWith(photography: d.photo[a] ?? PhotographyPolicy.allowed, music: d.music[a] ?? MusicPolicy.none),
        ),
      );
    }
    final low = sections.map((s) => s.minGuests).reduce((a, b) => a < b ? a : b);
    final res = await actions.saveHall(
      h.id,
      hallInputOf(
        h,
        name: LocalizedText(ar: d.ar.trim(), en: d.en.trim()),
        setting: d.setting,
        capacity: GuestRange(min: low, max: d.capMax),
        exclusiveDay: d.exclusive,
        sections: sections,
        sessions: d.sessions,
      ),
    );
    if (!mounted) return;
    if (!res.isSuccess) return toastResult(context, res);
    final changed = d.states.entries.any((e) => _amenities.where((a) => a.amenityId == e.key).firstOrNull?.state != e.value);
    if (changed) {
      final next = <VenueAmenity>[];
      final seen = <String>{};
      for (final a in _amenities) {
        next.add(VenueAmenity(amenityId: a.amenityId, state: d.states[a.amenityId] ?? a.state, from: a.from, note: a.note, audience: a.audience));
        seen.add(a.amenityId);
      }
      for (final e in d.states.entries) {
        if (!seen.contains(e.key)) next.add(VenueAmenity(amenityId: e.key, state: e.value));
      }
      final r = await actions.saveAmenities(VenueAmenities(amenities: next));
      if (!mounted) return;
      if (!r.isSuccess) return toastResult(context, r);
    }
    _base = d.signature;
    nav.toast(GzToastSpec(message: l.hotelVenueToastHallSaved, icon: GzIcons.checkCircle));
    nav.pop();
  }

  void _openSession(SessionInput? s) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final d = _d!;
    String? key;
    key = nav.openSheetBuilder(
      (_) => SessionSheet(
        session: s,
        onSave: (next) => setState(() => d.sessions = s == null ? [...d.sessions, next] : [for (final x in d.sessions) identical(x, s) ? next : x]),
        onDelete: s == null
            ? null
            : () {
                setState(
                  () => d.sessions = [
                    for (final x in d.sessions)
                      if (!identical(x, s)) x,
                  ],
                );
                nav.closeSheet(key);
              },
      ),
      options: GzSheetOptions(title: s == null ? l.hotelVenueSessionNewTitle : l.hotelVenueSessionEditTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final lang = context.gz.locale.languageCode;
    final venue = ref.watch(partnerVenueProvider).value?.venue;
    final labels = ref.watch(venueAmenityLabelsProvider).value ?? const <String, LocalizedText>{};
    final amen = venue?.amenities;
    if (_d == null && amen != null) {
      _amenities = amen;
      _d = _Draft(widget.hall, amen);
      _base = _d!.signature;
    }
    final d = _d;
    if (d == null) return const FormSkeleton();
    final saving = ref.watch(venueActionsProvider).busy.contains('save:hall');
    final namesMissing = d.ar.trim().isEmpty || d.en.trim().isEmpty;
    final noAudience = d.audiences.isEmpty;
    final anyMinBad = _audiences.any((a) => _minBad(d, a));
    final noSession = !d.exclusive && d.sessions.isEmpty;
    final problem = namesMissing
        ? l.hotelVenueNameRequired
        : noAudience
        ? l.hotelVenueAudAtLeastOne
        : anyMinBad
        ? l.hotelVenueMinAboveMax
        : noSession
        ? l.hotelVenueSessionNeeded
        : null;
    final amenityIds = [...kHallAmenities, if (d.setting != HallSetting.indoor) 'indoor-backup'];
    final name = LocalizedText(ar: d.ar, en: d.en).of(lang);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await confirmDiscard(context, dirty: true) && context.mounted) nav.pop();
      },
      child: GzScreen(
        top: GzTopBar(title: l.hotelVenueHallEditTitle, subtitle: name),
        bottom: venueSaveBar(context, dirty: _dirty, problem: problem, saving: saving, onSave: _save),
        child: VenuePage(
          children: [
            if (widget.single) const VenueProfile(),
            VenueSection(
              title: l.hotelVenueFieldName,
              children: [
                BilingualField(
                  label: l.hotelVenueFieldName,
                  ar: d.ar,
                  en: d.en,
                  maxLength: 60,
                  onAr: (v) => setState(() => d.ar = v),
                  onEn: (v) => setState(() => d.en = v),
                ),
              ],
            ),
            VenueSection(
              title: l.hotelVenueSecCapacity,
              children: [
                GuestPicker(
                  label: l.hotelVenueCapMax,
                  value: d.capMax,
                  min: 10,
                  max: _guestHardCap,
                  step: 10,
                  presets: _guestPresets,
                  onChanged: (v) => setState(() => d.capMax = v),
                ),
                for (final a in d.audiences)
                  GuestPicker(
                    label: l.hotelVenueCapMin(audienceLabel(l, a)),
                    value: d.mins[a] ?? 100,
                    min: 10,
                    max: _guestHardCap,
                    step: 10,
                    presets: _guestPresets,
                    error: _minBad(d, a) ? l.hotelVenueMinAboveMax : null,
                    onChanged: (v) => setState(() => d.mins[a] = v),
                  ),
              ],
            ),
            VenueSection(
              title: l.hotelVenueSecHallAudience,
              children: [
                GzChipGroup<Audience>.multiple(
                  label: l.hotelVenueAudienceAllowed,
                  values: d.audiences,
                  onChanged: (next) => setState(() {
                    d.audiences = [
                      for (final a in _audiences)
                        if (next.contains(a)) a,
                    ];
                    for (final a in d.audiences) {
                      d.mins.putIfAbsent(a, () => 100);
                      d.photo.putIfAbsent(a, () => PhotographyPolicy.allowed);
                      d.music.putIfAbsent(a, () => MusicPolicy.none);
                    }
                  }),
                  options: [for (final a in _audiences) GzChipOption<Audience>(value: a, label: audienceLabel(l, a))],
                ),
                if (noAudience) FormError(l.hotelVenueAudAtLeastOne),
                GzChipGroup<HallSetting>(
                  label: l.hotelVenueSettingLabel,
                  value: d.setting,
                  onChanged: (v) => v == null ? null : setState(() => d.setting = v),
                  options: [for (final s in _settings) GzChipOption<HallSetting>(value: s, label: settingLabel(l, s))],
                ),
              ],
            ),
            VenueSection(
              title: l.hotelVenueSecSessions,
              children: [
                GzToggleRow(title: l.hotelVenueExclusiveTitle, divider: false, checked: d.exclusive, onChanged: (v) => setState(() => d.exclusive = v)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (final s in d.sessions) SessionRow(session: s, onOpen: () => _openSession(s))],
                ),
                if (noSession) FormError(l.hotelVenueSessionNeeded),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: GzButton(
                    label: l.hotelVenueSessionAdd,
                    variant: GzButtonVariant.secondary,
                    iconStart: GzIcons.plus,
                    onPressed: () => _openSession(null),
                  ),
                ),
              ],
            ),
            VenueSection(
              title: l.hotelVenueSecFacilities,
              children: [AmenityRows(ids: amenityIds, labels: labels, states: d.states, onChanged: (id, s) => setState(() => d.states[id] = s))],
            ),
            if (d.audiences.isNotEmpty)
              VenueSection(
                title: l.hotelVenueSecSections,
                children: [
                  for (final a in d.audiences)
                    SectionFacts(
                      audience: a,
                      photography: d.photo[a] ?? PhotographyPolicy.allowed,
                      music: d.music[a] ?? MusicPolicy.none,
                      onChanged: (p, m) => setState(() {
                        d.photo[a] = p;
                        d.music[a] = m;
                      }),
                    ),
                ],
              ),
            GzListRow(
              flush: true,
              last: true,
              leading: const GzIcon(GzIcons.clipboard, size: GzIconSize.md),
              title: l.hotelVenueLinkRules,
              chevron: true,
              onPressed: () => nav.push('HL-VENU-06', params: {'hallId': widget.hall.id}),
            ),
          ],
        ),
      ),
    );
  }
}
