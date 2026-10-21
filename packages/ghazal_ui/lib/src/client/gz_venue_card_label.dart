part of 'gz_venue_card.dart';

/// The plate: media over the wall label (card, feature, list).
class _Plate extends StatelessWidget {
  const _Plate({required this.card, required this.name});

  final GzVenueCard card;
  final String name;

  @override
  Widget build(BuildContext context) {
    final feature = card.variant == GzVenueCardVariant.feature;
    final price = card.price;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VenueMedia(card: card, name: name),
        const SizedBox(height: GzSpace.s3),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeadRow(venue: card.venue, name: name, role: feature ? GzTextRole.d2 : GzTextRole.d1),
                const SizedBox(height: GzSpace.s1),
                _MetaLine(venue: card.venue, area: card.area, guestRange: card.guestRange, sponsored: card.sponsored, tags: card.tags),
              ],
            ),
            const SizedBox(height: GzSpace.s3),
            const GzDivider(),
            const SizedBox(height: GzSpace.s3),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Availability(venue: card.venue, availability: card.availability, date: card.date),
                if (_hasAvailability(card)) SizedBox(height: feature ? GzSpace.s2 : GzSpace.s1),
                if (price != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GzCardPriceLine(price: price, size: feature ? GzPriceLineSize.display : GzPriceLineSize.card, audience: card.audience),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

bool _isGovernment(VenueSummary v) => v.type == VenueType.governmental || v.channel == BookingChannel.externalLink;

bool _hasAvailability(GzVenueCard card) {
  if (_isGovernment(card.venue)) return true;
  final a = card.availability;
  return a != null && a != VenueDayState.unknown && card.date != null;
}

/// Name (serif, two lines) and the rating pinned to the end, baseline aligned.
class _HeadRow extends StatelessWidget {
  const _HeadRow({required this.venue, required this.name, required this.role});

  final VenueSummary venue;
  final String name;
  final GzTextRole role;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final average = venue.rating.average;
    final fresh = average == null || venue.rating.count == 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: GzChromeBaseline(
            style: context.gz.text(role),
            child: GzText(name, role: role, color: c.textPrimary, maxLines: 2, header: true),
          ),
        ),
        const SizedBox(width: GzSpace.s3),
        if (fresh)
          GzText(context.gzL10n.commonLabelNew, role: GzTextRole.bodyS, color: c.textSecondary, softWrap: false)
        else
          GzGlyphBaseline(glyphSize: GzSize.iconXs, child: GzRating(value: average, count: venue.rating.count)),
      ],
    );
  }
}

/// Area, guest range and the section marks on one wrapping line; the sponsored note sits at the end.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.venue, required this.area, required this.guestRange, required this.sponsored, required this.tags});

  final VenueSummary venue;
  final LocalizedText? area;
  final GuestRange? guestRange;
  final bool sponsored;
  final List<Audience> tags;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final range = guestRange == null ? null : '${f.integer(guestRange!.min)} – ${f.integer(guestRange!.max)}';
    final sections = tags.length >= 2 ? tags : const <Audience>[];
    final items = <Widget>[
      if (area != null) GzText(area!.of(lang), role: GzTextRole.bodyS, color: c.textSecondary),
      if (range != null) GzFactChip(icon: GzIcons.usersThree, label: l.uiSharedGuests, value: range, small: true, tone: GzFactTone.muted),
      for (final a in sections)
        if (_sectionIcon(a) != null) GzFactChip(icon: _sectionIcon(a)!, label: _sectionLabel(l, a), small: true, tone: GzFactTone.muted),
    ];
    final wrap = Wrap(spacing: GzSpace.s3, runSpacing: GzSpace.s1, crossAxisAlignment: WrapCrossAlignment.center, children: items);
    if (!sponsored) return items.isEmpty ? const SizedBox.shrink() : wrap;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: wrap),
        const SizedBox(width: GzSpace.s3),
        GzText(l.commonLabelSponsored, role: GzTextRole.caption, color: c.textSecondary, softWrap: false),
      ],
    );
  }
}

IconData? _sectionIcon(Audience a) => switch (a) {
  Audience.women => GzIcons.sectionWomen,
  Audience.men => GzIcons.sectionMen,
  Audience.mixed => GzIcons.sectionMixed,
  Audience.unknown => null,
};

String _sectionLabel(GzL10n l, Audience a) => switch (a) {
  Audience.women => l.uiClientVenueCardTagWomen,
  Audience.men => l.uiClientVenueCardTagMen,
  _ => l.uiClientVenueCardTagMixed,
};

/// The availability line: a gold-700 bead (free), an hourglass (on hold) or a crossed calendar (taken) and the date; a bank mark
/// for a government hall. The state word is the accessible name.
class _Availability extends StatelessWidget {
  const _Availability({required this.venue, required this.availability, required this.date});

  final VenueSummary venue;
  final VenueDayState? availability;
  final LocalDate? date;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    Widget row(Widget glyph, String word, Widget? text) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSpace.s6),
      child: Semantics(
        label: word,
        child: Row(
          children: [
            glyph,
            if (text != null) ...[const SizedBox(width: GzSpace.s2), Expanded(child: text)],
          ],
        ),
      ),
    );
    if (_isGovernment(venue)) {
      return row(GzIcon(GzIcons.bank, size: GzIconSize.xs, color: c.iconSecondary), l.uiClientVenueCardGovernment, null);
    }
    final a = availability;
    if (a == null || a == VenueDayState.unknown || date == null) return const SizedBox.shrink();
    final free = a == VenueDayState.available;
    final held = a == VenueDayState.held;
    final word = free ? l.commonAvailabilityAvailable : (held ? l.commonAvailabilityHeld : l.uiClientVenueCardBookedOnDate);
    final glyph = free
        ? GzBeadBox(color: c.textGoldInk)
        : GzIcon(held ? GzIcons.hourglass : GzIcons.calendarX, size: GzIconSize.xs, color: c.iconSecondary);
    return row(glyph, word, GzText(f.date(date!.toString(), DateStyle.short), role: GzTextRole.caption, color: c.textPrimary, figures: true));
  }
}
