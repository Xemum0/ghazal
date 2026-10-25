// The real objects and the layout kit of the voucher gallery part A (sections 1 to 8 of design/src/gallery/voucher.tsx).
// ghazal_testing may hold string literals (tests and galleries are exempt from the no-text-literal rule).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show CreditVoucher, LocalizedText, ThreadMember, Voucher, VisitAppointment, VisitThread, WalletVoucher;
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/voucher/voucher.dart';
import 'package:path/path.dart' as p;

import '../world.dart';

/// A voucher with the names its card shows (the caller of the widget resolves them; a widget never looks anything up).
class VoucherSpecimen {
  const VoucherSpecimen(this.voucher, {this.target, this.package});

  final WalletVoucher voucher;
  final LocalizedText? target;
  final LocalizedText? package;
}

/// A visit with the names its card shows.
class VisitSpecimen {
  const VisitSpecimen(this.visit, {required this.venue, this.representative});

  final VisitAppointment visit;
  final LocalizedText venue;
  final ThreadMember? representative;
}

/// Everything the eight sections read, fetched once outside fake async through the repositories the apps use (the mock serves the
/// shared fixtures). Four of the web specimens belong to clients no persona can sign in as (the web fixtures read them by id), so those
/// are parsed from the very seed file the mock serves (`Voucher.seed.json`): a real fixture object, never hand-built.
class VoucherAData {
  VoucherAData._({required this.vouchers, required this.visits, required this.clientThread, required this.hotelThread});

  final Map<String, VoucherSpecimen> vouchers;
  final Map<String, VisitSpecimen> visits;
  final VisitThread clientThread;
  final VisitThread hotelThread;

  VoucherSpecimen v(String id) => vouchers[id] ?? (throw StateError('voucher $id'));
  VisitSpecimen visit(String id) => visits[id] ?? (throw StateError('visit $id'));

  static Future<VoucherAData> load(GzWorld world) async {
    final reem = world.repos('reem');
    final out = <String, VoucherSpecimen>{};
    for (final i in (await reem.vouchers.listVouchers(limit: 50)).items) {
      out[i.voucher.id] = VoucherSpecimen(i.voucher, target: i.target?.name, package: i.packageName);
    }
    final hotel = world.repos('hotel_manager', venueId: 'V01');
    // Thread members are read as `name` (Arabic) and `nameLatin`: an English response leads with the Latin spelling in `name`, so the
    // threads are fetched as the Arabic response, which carries both spellings untouched.
    final reemAr = world.repos('reem', language: 'ar');
    final hotelAr = world.repos('hotel_manager', venueId: 'V01', language: 'ar');
    final venueName = out['vch-GV-2611-K7QM']!.target;
    // Clients no persona signs in as: the same fixture rows the mock serves.
    final root = _root();
    final seed = (jsonDecode(File(p.join(root, 'packages/ghazal_mock_api/assets/seed/Voucher.seed.json')).readAsStringSync()) as List).cast<Map<String, Object?>>();
    final packages = {for (final m in (jsonDecode(File(p.join(root, 'packages/ghazal_mock_api/assets/seed/Package.seed.json')).readAsStringSync()) as List).cast<Map<String, Object?>>()) m['id']! as String: LocalizedText.fromJson((m['name']! as Map).cast<String, Object?>())};
    final venues = {for (final m in (jsonDecode(File(p.join(root, 'packages/ghazal_mock_api/assets/seed/Venue.seed.json')).readAsStringSync()) as List).cast<Map<String, Object?>>()) m['id']! as String: LocalizedText.fromJson((m['name']! as Map).cast<String, Object?>())};
    final providers = {for (final m in (jsonDecode(File(p.join(root, 'packages/ghazal_mock_api/assets/seed/ServiceProvider.seed.json')).readAsStringSync()) as List).cast<Map<String, Object?>>()) m['id']! as String: LocalizedText.fromJson((m['name']! as Map).cast<String, Object?>())};
    for (final id in ['vch-GV-2611-QD9X', 'vch-GV-2611-QY57', 'vch-GV-2608-D5QN', 'vch-GV-2611-M2WD']) {
      final row = seed.firstWhere((m) => m['id'] == id);
      final v = Voucher.fromJson(row);
      out[id] = VoucherSpecimen(v, target: v.targetType.value == 'provider' ? providers[v.venueOrProviderId] : venues[v.venueOrProviderId], package: packages[v.packageId]);
    }
    for (final i in (await hotel.partnerBookings.listRedeemedVouchers(limit: 50)).items) {
      if (i.voucher.id == 'vch-GV-2608-378X') out[i.voucher.id] = VoucherSpecimen(i.voucher, target: venueName, package: packages[i.voucher.packageId]);
    }
    // Visits.
    final visits = <String, VisitSpecimen>{};
    for (final r in (await reem.visits.listVisits(limit: 20)).items) {
      final t = await reemAr.visits.getVisitThread(visitId: r.visit.id);
      visits[r.visit.id] = VisitSpecimen(r.visit, venue: r.target.name, representative: t.thread.members?.firstWhere((m) => m.role.value == 'hotel_representative'));
    }
    final partner = (await hotel.partnerVisits.listPartnerVisits(limit: 20)).items;
    visits['visit-aurelia-rashed'] = VisitSpecimen(partner.firstWhere((x) => x.id == 'visit-aurelia-rashed'), venue: visits['visit-aurelia-reem']!.venue);
    return VoucherAData._(
      vouchers: out,
      visits: visits,
      clientThread: await reemAr.visits.getVisitThread(visitId: 'visit-aurelia-reem'),
      hotelThread: await hotelAr.partnerVisits.getPartnerVisitThread(visitId: 'visit-aurelia-reem'),
    );
  }

  static String _root() {
    var dir = Directory.current.absolute;
    for (var i = 0; i < 8; i++) {
      if (File(p.join(dir.path, 'packages/contracts/fixtures/engine-cases.json')).existsSync()) return dir.path;
      dir = dir.parent;
    }
    throw StateError('repository root not found');
  }
}

/// The wallet voucher with the card props filled from a specimen.
Widget voucherCard(
  BuildContext context,
  VoucherSpecimen s, {
  GzVoucherCardVariant variant = GzVoucherCardVariant.full,
  VoidCallback? onOpen,
  VoidCallback? onCopy,
  VoidCallback? onShowFull,
}) {
  final lang = context.gz.locale.languageCode;
  return GzVoucherCard(
    voucher: s.voucher,
    variant: variant,
    targetName: s.target?.of(lang) ?? '',
    packageName: s.voucher is CreditVoucher ? null : s.package?.of(lang),
    onOpen: onOpen,
    onCopy: onCopy,
    onShowFull: onShowFull,
    // the web system gallery shows the stub start-aligned (screens centre it with a local override)
    centerStub: false,
  );
}

// ------------------------------------------------------------------------------------------------------------------ kit
String tr(BuildContext context, String en, String ar) => context.gz.isAr ? ar : en;

/// `Section` of the web kit: khayt, d2 title, note (gap 8), then the specimens (gap 32) after a gap of 20.
Widget gcSection(BuildContext context, {required String title, required String note, required List<Widget> specs}) {
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

/// `Spec`: a state caption over a hairline, then the live component(s) with a gap of 24 (12 under the caption). [ink] is the dark panel.
Widget gcSpec(BuildContext context, String state, List<Widget> children, {bool ink = false}) {
  final gz = context.gz;
  final c = gz.colors;
  Widget body = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s6), children[i]],
    ],
  );
  if (ink) {
    body = DecoratedBox(
      decoration: BoxDecoration(color: c.surfaceDark, borderRadius: GzRadius.mdAll),
      child: Padding(padding: const EdgeInsets.all(GzSpace.s4), child: body),
    );
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
        child: Text(state, style: gz.text(GzTextRole.caption).copyWith(color: c.textSecondary, fontWeight: gz.text(GzTextRole.title).fontWeight, decoration: TextDecoration.none)),
      ),
      const SizedBox(height: GzSpace.s3),
      body,
    ],
  );
}

/// `.gc-row`: side-by-side cells, gap 12, each `flex: 1`.
Widget gcRow(List<Widget> children) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: GzSpace.s3), Expanded(child: children[i])],
  ],
);
