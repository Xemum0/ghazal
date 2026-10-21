/// Shared helpers of the client discovery cards (part A): image descriptors, the venue summary of a full venue, a baseline box
/// for a glyph-first row, and the pressed-preview scale. Nothing here is a widget other code builds screens from.
library;

import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Audience, LocalDate, LocalizedText, Venue, VenueSummary;

import '../foundation.dart';

/// The same for a gallery item (`GalleryItem` carries the same two fields as `ImageRef`).
String gzGalleryItemSrc(String? baseUrl, String file) => baseUrl ?? file;

/// The summary a card needs, from a full `Venue` (a screen that holds the detail passes it to the card as-is).
VenueSummary gzVenueSummaryOf(Venue v) => VenueSummary(
  id: v.id,
  slug: v.slug,
  name: v.name,
  type: v.type,
  style: v.style,
  tier: v.tier,
  stars: v.stars,
  channel: v.channel,
  status: v.status,
  governorateId: v.governorateId,
  areaId: v.areaId,
  address: v.address,
  geo: v.geo,
  tagline: v.tagline,
  cover: v.cover,
  hasVideo: v.hasVideo,
  rating: v.rating,
  voucherEnabled: v.voucherEnabled,
  flags: v.flags,
);

/// The whole-card pressed look of the gallery (`previewState: 'pressed'`): the real press scale from the tokens.
Widget gzPressedPreview(bool pressed, Widget child) => pressed ? Transform.scale(scale: GzMotion.scalePress, child: child) : child;

/// The four decisions of a brief (web `BriefField`).
enum GzBriefField { guests, date, area, budget }

/// The couple's brief as the cards read it: audience, guests, date, areas, budget. Every field may be empty (a skipped answer).
/// Areas arrive already resolved to names (a widget never looks anything up); the budget is an integer-fils range whose top is
/// null for an open budget (`KD 35,000+`).
@immutable
class GzBrief {
  const GzBrief({this.audience, this.guests, this.date, this.areas = const [], this.budgetMinFils, this.budgetMaxFils});

  final Audience? audience;
  final int? guests;

  /// A civil date.
  final LocalDate? date;
  final List<LocalizedText> areas;
  final int? budgetMinFils;
  final int? budgetMaxFils;

  GzBrief copyWith({
    Audience? audience,
    int? guests,
    LocalDate? date,
    List<LocalizedText>? areas,
    int? budgetMinFils,
    int? budgetMaxFils,
    bool openBudget = false,
  }) => GzBrief(
    audience: audience ?? this.audience,
    guests: guests ?? this.guests,
    date: date ?? this.date,
    areas: areas ?? this.areas,
    budgetMinFils: budgetMinFils ?? this.budgetMinFils,
    budgetMaxFils: openBudget ? null : (budgetMaxFils ?? this.budgetMaxFils),
  );
}
