// Kit of the client gallery page (web design/src/system/domain-client/gallery/kit.tsx and gallery.css): Section, Spec, Row and the
// story data every specimen reads. Real objects only: the venues, prices, availability and windows come from the in-process mock
// through the same repositories the apps use (GzWorld); the three stress venues are decoded with the real generated models from the
// shared stress fixture. ghazal_testing may hold string literals (galleries are exempt from the no-literal rule).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/src/client/client_a.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:path/path.dart' as p;

import '../world.dart';

/// The shared story brief (docs/product/fixtures.md): Thu 14 Jan 2027, ladies, 350 guests, Salmiya and Sharq, KD 20,000 - 35,000.
late ClientAData clientAData;

class ClientAData {
  ClientAData({
    required this.results,
    required this.areas,
    required this.governorates,
    required this.gallery,
    required this.windows,
    required this.stress,
    required this.venueNames,
    required this.brief,
    required this.weddingDate,
  });

  /// Every seeded venue as a result row for the story brief (price, availability, badge, tags, guest range).
  final Map<String, VenueResult> results;
  final Map<String, LocalizedText> areas;

  /// Governorate id to name, in the configured list order (ADR 0038: the region of a brief).
  final Map<String, LocalizedText> governorates;
  final Map<String, List<GalleryItem>> gallery;

  /// `live` (active, in seed order), `ended`, `scheduled` of the web gallery.
  final List<VoucherWindow> windows;
  final List<VenueSummary> stress;
  final Map<String, LocalizedText> venueNames;
  final GzBrief brief;
  final LocalDate weddingDate;

  VoucherWindow get ended => windows.firstWhere((w) => w.status == VoucherWindowStatus.ended);
  VoucherWindow get scheduled => windows.firstWhere((w) => w.status == VoucherWindowStatus.scheduled);
  List<VoucherWindow> get live => windows.where((w) => w.status == VoucherWindowStatus.active).toList();

  VenueResult result(String id) => results[id]!;

  static Future<ClientAData> load(GzWorld world) async {
    final reem = world.repos('reem');
    final date = LocalDate.parse('2027-01-14');
    final rows = <VenueResult>[];
    String? cursor;
    do {
      final page = await reem.venues.searchVenues(date: date, guests: 350, audience: Audience.women, limit: 20, cursor: cursor);
      rows.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    // Venues the story brief filters out (a hall for men only) still appear as category covers: add them from an unfiltered search.
    final unfiltered = await reem.venues.searchVenues(limit: 20);
    final results = {for (final r in [...unfiltered.items, ...rows]) r.venue.id: r};
    final areasResponse = await reem.venues.listAreas();
    final areaList = areasResponse.areas;
    final profile = await reem.wedding.getWeddingProfile();
    final v01 = await reem.venues.getVenue(venueId: 'V01', date: date, guests: 350, audience: Audience.women);
    final v09 = await reem.venues.getVenue(venueId: 'V09', date: date, guests: 350, audience: Audience.women);
    final manager = world.repos('hotel_manager', venueId: 'V01');
    final all = (await manager.partnerGrowth.listVoucherWindows()).windows;
    // The order of the web gallery: live = midweek, flash (V01), winter (V09); then the ended and the scheduled one.
    final byId = {for (final w in [...all, ...v09.windows]) w.id: w};
    final windows = [for (final id in ['vw-V01-midweek', 'vw-V01-flash', 'vw-V09-winter', 'vw-V01-autumn', 'vw-V01-early']) byId[id]!];

    final stressJson = json.decode(File(p.join(_root(), 'packages/contracts/fixtures/stress/venues.json')).readAsStringSync()) as Map<String, Object?>;
    final stress = [for (final v in stressJson['venues']! as List<Object?>) VenueSummary.fromJson(_withMockImages(v)! as Map<String, Object?>)];
    final names = {for (final r in rows) r.venue.id: r.venue.name};
    final areas = {for (final a in areaList) a.id: a.name};
    final governorates = {for (final g in areasResponse.governorates) g.id: g.name};
    // The Brief speaks about governorates: the profile's own list, else the governorates of its (older) areas, in list order, like the
    // web `briefGovernorates` (the story profile still lists Salmiya and Sharq, so it reads Capital and Hawalli).
    final areaGovernorate = {for (final a in areaList) a.id: a.governorateId};
    final picked = profile.governorateIds?.toSet() ?? {for (final id in profile.areaIds) if (areaGovernorate[id] != null) areaGovernorate[id]!};
    final brief = GzBrief(
      audience: Audience.women,
      guests: 350,
      date: profile.weddingDate,
      areas: [for (final g in areasResponse.governorates) if (picked.contains(g.id)) g.name],
      budgetMinFils: profile.venueBudget.min.fils,
      budgetMaxFils: profile.venueBudget.max.fils,
    );
    return ClientAData(
      results: results,
      areas: areas,
      governorates: governorates,
      gallery: {'V01': v01.venue.gallery},
      windows: windows,
      stress: stress,
      venueNames: names,
      brief: brief,
      weddingDate: profile.weddingDate,
    );
  }
}

/// The stress fixture is the shared contracts file (no image base URL); the mock API serves each image as `asset://ghazal_mock_api/
/// images/NAME`, so the same descriptor is added to every image object, as the API does for the seeded venues.
Object? _withMockImages(Object? node) {
  if (node is Map<String, Object?>) {
    final out = {for (final e in node.entries) e.key: _withMockImages(e.value)};
    final file = out['file'];
    if (file is String && out['baseUrl'] == null) out['baseUrl'] = 'asset://ghazal_mock_api/images/${p.basenameWithoutExtension(file)}';
    return out;
  }
  if (node is List<Object?>) return [for (final e in node) _withMockImages(e)];
  return node;
}

String _root() {
  var dir = Directory.current.absolute;
  for (var i = 0; i < 8; i++) {
    if (File(p.join(dir.path, 'packages/contracts/fixtures/engine-cases.json')).existsSync()) return dir.path;
    dir = dir.parent;
  }
  throw StateError('repository root not found');
}

/// `L(lang, en, ar)`.
String caL(BuildContext context, String en, String ar) => context.gz.isAr ? ar : en;

/// Web `Section`: khayt, d2 title, note (gap 8), then the specimens (gap 32) after a gap of 20.
Widget caSection(BuildContext context, {required String title, required String note, required List<Widget> specs}) {
  final c = context.gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(alignment: AlignmentDirectional.centerStart, child: GzThreadRule(draw: GzDraw.off)),
      const SizedBox(height: GzSpace.s2),
      GzText(title, role: GzTextRole.d2, color: c.textStrong, header: true),
      const SizedBox(height: GzSpace.s2),
      GzText(note, role: GzTextRole.bodyS, color: c.textSecondary),
      const SizedBox(height: GzSpace.s5),
      for (var i = 0; i < specs.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s8), specs[i]],
    ],
  );
}

/// Web `Spec`: a state caption over a hairline, then the live component(s) with a gap of 24 after a gap of 12.
Widget caSpec(BuildContext context, String state, List<Widget> children) {
  final gz = context.gz;
  final c = gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
        child: Text(
          state,
          style: gz.text(GzTextRole.caption).copyWith(color: c.textSecondary, fontWeight: gz.text(GzTextRole.title).fontWeight, decoration: TextDecoration.none),
        ),
      ),
      const SizedBox(height: GzSpace.s3),
      for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s6), children[i]],
    ],
  );
}

/// Web `Row`: side-by-side cells that stay side by side (flex 1, gap 12).
Widget caRow(List<Widget> children) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: GzSpace.s3), Expanded(child: children[i])],
  ],
);
