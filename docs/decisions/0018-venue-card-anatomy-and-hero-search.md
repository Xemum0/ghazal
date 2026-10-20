# ADR 0018: Venue card anatomy and the hero-search 'brief card'

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-10-12 |
| Scope | Client app: venue card (results, home rails, wishlist, similar venues), compact variant, government-hall variant, Home hero search, quick categories |
| Owner confirmation still needed | OQ-L-10 (contextual Book button satisfies CA-CARD-11), OQ-B-15 and OQ-L-13 ('No booking fee' line), OQ-L-02 (KD vs KWD) |
| Related ADRs | 0002 (government variant, section tags), 0004 (price grammar), 0007 (the Brief), 0009 (compare control, compact variant), 0010 (units and formats), 0011 (date pill), 0012 (area picker, guest presets, budget bands), 0013 (labels), 0015 (no faces, tags), 0016 (figures), 0017 (motion) |
| Screens | CL-DISC-01, CL-DISC-02, CL-DISC-03, CL-SAVD-01, CL-SAVD-02, CL-VENU-06 |

## Context

The PRD lists a venue card with photo, video, rating and review count, price, capacity, area, availability badge, favourite, compare and a Book action (CA-CARD-01..13), and a Home hero search accepting date, area, budget and guests (CA-HOME-01..06). Research found:

- The brief wants image-led restraint; 'Book' on every list card competes with the photograph, and Booking.com-style badge density is for a different product. The PRD's Book button can still be honoured contextually.
- A bare 'From KD X' is meaningless in a per-guest market; the card needs unit, guest basis and, when a Brief exists, a date-aware price and availability line (ADR 0004 D6).
- Onboarding already captured date, guests, budget and area, so asking again on Home is friction. Wedding Spot shows 'Starting at $X for N guests'; the hero should be a prefilled summary of the Brief, not an empty form (competitive-ux).
- Airbnb's pill (64px, three segments) and Four Seasons' 52px booking fields show compact search works; a wedding is one date, so a single date, not a range.
- A card carousel fights horizontal shelves and the RTL edge-swipe and costs scroll performance; the gallery lives on details.
- Social-proof badges that are not in the PRD ('Couples' choice', 'Most booked') are unverifiable and CMA-sensitive.
- Ladies and men's arrangements must be scannable without opening a venue; government halls need a distinct variant with no live availability.
- Rating: a venue with no reviews shows `جديد` / `New`, never 0.0 (CA-CARD-03/04).

## Decision

**A. Card anatomy** (results list, home rails, wishlist, similar venues). Unframed: no border, no shadow, 12px image radius; 24px between cards in lists, 32px between shelves.

**1. Image** 4:5, a single cover photo (no card carousel in the MVP: it fights horizontal shelves and the RTL edge-swipe and costs scroll performance; the gallery lives on details). Overlays are solid Off-White 32px disks inside 44px targets: heart at top inline-end (favourite, CA-CARD-09), compare control at top inline-start (CA-CARD-10; selected = Ink-filled check; a fourth add opens a 'Replace one' sheet). Bottom inline-start: at most one badge, a solid Off-White pill. Bottom inline-end: a small play affordance when the venue has a video (CA-CARD-02), never autoplay.

**2. Badge priority, one only:** active offer (`خصم 15%` / `-15%`), then instant booking (`حجز فوري` / `Instant booking`), then Featured. A paid placement also shows its disclosure `إعلان` / `Sponsored` (MK-SUB-04) as 12px muted text at the end of the meta line; the disclosure is not a badge and is never dropped by the one-badge cap. Social-proof badges that are not in the PRD ('Couples' choice', 'Most booked') are not designed.

**3. Text, top to bottom:**

1. name (16/22 medium, AR 17/28) wrapped to two lines before truncating, with rating pinned to inline-end as separate items: star icon, number, `(212)` in figures; a venue with no reviews shows `جديد` / `New`, never 0.0 (CA-CARD-03/04);
2. `Area · guest range` (14 muted; EN `Salmiya · 200 – 700 guests`, AR `السالمية · من 200 إلى 700 ضيف`; the range runs from the smallest hall minimum to the largest hall capacity; CA-CARD-06/07);
3. section tags, non-interactive 24px hairline chips (`نسائي` `رجالي`, `مختلط` only if the venue offers it), omitted when the venue has a single arrangement;
4. price line;
5. availability line, icon plus label, never colour alone: `متاح الخميس 14 يناير` / Available Thu 14 Jan, `محجوز مؤقتًا` / On hold, `محجوز في تاريخكم` / Booked on your date; omitted entirely when no date is set (no empty promise).

**4. Price line** (figures role for amount and guest count; the unit rules of ADR 0010 apply). Per-guest venue with a guest count only: `From KD 16,100 for 350 guests`; with a date and guests: `KD 18,200 for 350 guests`, no 'From' (ADR 0004 D6 owns the grammar; lowest matching package for the date's day type times the larger of the guest count and the hall minimum; below the minimum: `From KD 9,200 for 200 guests (minimum)`). Per-guest venue without a guest count: `From KD 46 per guest`. Flat venues: `KD 2,800 per night` (`From` only if several packages). Government halls: `KD 100 rental fee`. Offers: the new price with the old price struck through only when the old price is the real price in force during the previous 28 days. The deposit never appears on the card. No urgency counters and no 'only N left'.

**5. Targets.** The whole card opens details (CA-CARD-12). The PRD Book action (CA-CARD-11) is honoured contextually: a trailing 44px `حجز` / `Book` text button on the availability line appears only on results cards when a date is set and the venue is available, and starts booking with date and guests carried over; elsewhere the details screen carries a sticky Book bar. This is a recorded interpretation (OQ-L-10).

**6. Government-hall variant.** Single meta tag `قاعة حكومية` / Government, price `رسوم الإيجار 100 د.ك`, availability line replaced by `الحجز عبر وزارة الشؤون الاجتماعية` / Booked through the Ministry of Social Affairs (no live availability, no instant booking, no Book button).

**7. Compact variant** for wishlist and compare tray: 72 x 88 thumbnail (about 4:5, on the 4-pt grid), name, area, price line; no tags, no availability line.

**8. Rail card width** is 72% of the viewport snapped to 4px (280 at 390, 260 at 360, 308 at 430) so the next card peeks at inline-end. Skeleton: static 4:5 block plus four text blocks.

**B. Hero search ('brief card'), Home (CA-HOME-01..06).**

**9.** A hero image zone of about 300px with the brief card overlapping its bottom by about 88px; a hint of the first shelf stays visible at 844px height. The card is a solid Off-White surface, 1px hairline, 12px radius, no blur and no shadow, 16px padding. Rows are 64px: label 12px muted (AR 13) above the value 16px (AR 17). Row 1 Date (full width, a single date, not a range); row 2 Area and Guests side by side with a hairline divider; row 3 Budget as range text. Every row is a button that opens a sheet (calendar sheet per ADR 0011; governorate area picker per ADR 0012, multi-select; guest presets plus stepper; budget bands plus slider with a mirrored histogram); there are no free-text fields on the hero.

**10.** It is a prefilled summary of the onboarding brief (CA-ONB-08), editable in place, and persists on the device for guests. Skipped answers show muted placeholders (`اختيار التاريخ` / Choose date). The budget row is labelled `ميزانية القاعة والضيافة` / Venue and catering budget.

**11.** One gold primary button, 52px, deep-ink label, showing a live count, never the word Search: `عرض 38 قاعة` / `Show 38 halls`; with no network or no count yet it reads `عرض القاعات` / `Show halls`. Submitting opens results with the entered parameters as removable filter chips (CA-HOME-06, CA-SRCH-20).

**12.** Below the card: Home shelves follow the IA ADR (ADR 0007); quick categories (CA-HOME-07) are six 4:5 image tiles with a subtle single-purpose scrim and a text label, no coloured chips.

```text
Venue card (390 wide, unframed)
+---------------------------+
| [compare]           [heart] |   4:5 image, 12px radius
|                           |
| [one badge]        [play] |
+---------------------------+
Name (2 lines)         * 4.8 (212)
Salmiya · 200 – 700 guests
[ladies] [men]            (tags only when more than one arrangement)
KD 18,200 for 350 guests          (date and guests set; guests only: 'From KD 16,100 for 350 guests')
Available Thu 14 Jan          [Book]  (only with a date and availability)
```

## Consequences

- Every price states its basis; ladies and men arrangements are scannable without opening a venue; the hero is an editable summary instead of an empty form; the image stays the hero.
- A five-line text block makes cards taller than minimal marketplace cards, so fewer cards fit per screen; compensated by omitting the tags and availability lines when they carry no information.
- Computing a per-guest estimate needs guest count, date, day type and hall minimum on the list endpoint; the backend must return it already computed in fils.
- The Book button is contextual, which deviates from a literal reading of CA-CARD-11 and needs owner confirmation (OQ-L-10).
- The card shows fewer social-proof devices than competitors by design.
- Analytics: `venue_impression` and `venue_card_tapped` carry `surface`, `position` and `placement` (organic, featured, sponsored, offer) per ADR 0019.
- The compact variant is shared by Saved and the Compare tray (ADR 0009); the government variant also feeds Compare's 'Official channel' column.
- Offers on cards need the 28-day prior-price rule from the honesty constraints (ADR 0004 D4).

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Card carousel of photos (Airbnb dots) | Fights horizontal shelves and the RTL edge-swipe; scroll cost; gallery lives on details |
| Several badges per card (Booking.com density) | One badge maximum; priority offer, instant, featured |
| 'Couples' choice' and 'Most booked' badges | Unverifiable and CMA-sensitive; not in the PRD |
| A permanent Book button on every card | Image-led restraint; contextual button only with a date and availability |
| Bare 'From KD X' | Meaningless without unit and guests; forbidden (ADR 0010 item 9) |
| An empty search form on Home | Asks again what onboarding captured; a prefilled editable brief card |
| A date range in the hero | A wedding is one date (venues book per date and session) |
| A 'Search' button | A live count ('Show 38 halls') is more informative |
| Coloured category chips | Rainbow chips are a brief anti-pattern; image tiles with a scrim |
| Framed cards with shadows | Unframed image cards, hairlines instead of shadows |
| Showing the deposit on the card | Deposit belongs to Review and detail; the card shows the price |

## Related requirement IDs

| ID | Effect |
|---|---|
| CA-HOME-01..08 | Hero search, six quick categories (image tiles) |
| CA-SRCH-20 | Hero submit opens results with removable chips |
| CA-CARD-01..13 | Card photo, video affordance, rating, review count, price, capacity, area, availability badge, favourite, compare, Book, open details, badges |
| CA-ONB-08 | Brief prefilled and persisted locally for guests |
| CA-CMP-10 | Book from the comparison view uses the same carry-over |
| MK-SUB-04 | 'Sponsored' disclosure |
| CF-20 | Single starting-price figure |
| CF-15 | Home categories are curated shortcuts |
