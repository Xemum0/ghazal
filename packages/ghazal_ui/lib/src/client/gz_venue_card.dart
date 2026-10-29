/// VenueCard (ADR 0018, direction section 3 "Venue card"): the unframed plate. Port of design/src/system/domain-client/VenueCard.tsx.
///
/// Variants: [GzVenueCardVariant.card] 4:5 (results, home rails, similar venues), `feature` (larger serif name and display price),
/// `list` 16:10, `compact` / `saved` / `compare` (72 x 88 thumbnail rows). States: default, pressed ([previewState]), focus (the
/// pressable ring), favourite, compared, loading, no photo, no reviews, governmental (ministry line, browse only), held or taken on
/// the date. Every client is signed in (ADR 0038), so there is no locked-price form. The card never fetches and never navigates: it takes data and callbacks.
library;

import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart'
    show Audience, BookingChannel, CardPrice, GalleryItem, GuestRange, LocalDate, LocalizedText, VenueBadge, VenueDayState, VenueSummary, VenueType;

import '../brand/brand.dart';
import '../core/core.dart';
import '../foundation.dart';
import '../overlays/overlays.dart';
import 'client_a_kit.dart';
import 'client_bits.dart';
import 'gz_service_tile.dart' show gzImageSrc;

part 'gz_venue_card_label.dart';
part 'gz_venue_card_media.dart';
part 'gz_venue_card_rows.dart';

enum GzVenueCardVariant { card, feature, list, compact, saved, compare }

class GzVenueCard extends StatelessWidget {
  const GzVenueCard({
    required this.venue,
    this.area,
    this.gallery = const [],
    this.price,
    this.availability,
    this.date,
    this.badge,
    this.audience = GzPriceAudience.member,
    this.tags = const [],
    this.guestRange,
    this.sponsored = false,
    this.variant = GzVenueCardVariant.card,
    this.favourite,
    this.onFavouriteChange,
    this.compared = false,
    this.onCompareChange,
    this.onOpen,
    this.selected = false,
    this.onSelect,
    this.priceDropped = false,
    this.carousel = false,
    this.loading = false,
    this.previewState,
    super.key,
  });

  final VenueSummary venue;

  /// The area name (the screen resolves `venue.areaId`).
  final LocalizedText? area;

  /// The photographs of the venue, used by [carousel] only (a summary carries the cover alone).
  final List<GalleryItem> gallery;

  /// The card price (ADR 0004 D6 grammar) of `VenueResult.price`.
  final CardPrice? price;

  /// Availability on the Brief date; null or unknown shows no line (no empty promise).
  final VenueDayState? availability;

  /// The Brief date, for the availability line.
  final LocalDate? date;
  final VenueBadge? badge;

  /// Deprecated, no effect (ADR 0038: there is no guest mode). Remove it at the call site.
  final GzPriceAudience audience;
  final List<Audience> tags;
  final GuestRange? guestRange;
  final bool sponsored;
  final GzVenueCardVariant variant;

  /// `saved` reads null as on (the card lives in the wishlist); the other variants read null as off.
  final bool? favourite;
  final ValueChanged<bool>? onFavouriteChange;
  final bool compared;
  final ValueChanged<bool>? onCompareChange;

  /// Opens the venue: the whole card is the target.
  final VoidCallback? onOpen;

  /// `compare` variant: chosen in the Replace sheet.
  final bool selected;
  final VoidCallback? onSelect;

  /// `saved` variant: a real earlier price (ADR 0018 D4) turns on the price-drop mark.
  final bool priceDropped;

  /// Photo dots (`list` and `feature`): swipe through [gallery].
  final bool carousel;
  final bool loading;

  /// Gallery only: show the pressed look without a pointer.
  final GzPreviewState? previewState;

  bool get _compact => variant == GzVenueCardVariant.compact || variant == GzVenueCardVariant.saved || variant == GzVenueCardVariant.compare;

  @override
  Widget build(BuildContext context) {
    if (loading) return _VenueSkeleton(variant: variant);
    final lang = context.gz.locale.languageCode;
    final name = venue.name.of(lang);
    final compare = variant == GzVenueCardVariant.compare;
    final Widget body = _compact ? _CompactRow(card: this, name: name) : _Plate(card: this, name: name);
    return RepaintBoundary(
      child: gzPressedPreview(
        previewState == GzPreviewState.pressed,
        GzPressable(
          onPressed: compare ? onSelect : onOpen,
          selected: compare ? selected : null,
          borderRadius: GzRadius.mdAll,
          minHeight: 0,
          minWidth: 0,
          child: Semantics(
            label: compare ? context.gzL10n.uiClientVenueCardSelect : context.gzL10n.uiClientVenueCardOpen(name),
            child: body,
          ),
        ),
      ),
    );
  }
}
