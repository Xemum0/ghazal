# Research: Kuwait / GCC market, culture, Arabic UX & RTL

> Produced by an independent analyst agent during the Understand phase (Oct 2026). Inputs to ADRs in `docs/decisions/`; where this file and an ADR disagree, **the ADR wins**.

## Key insights

- A Kuwaiti wedding is two events in two rooms (a ladies' reception and a men's reception), and hotels sell them as separate products. Real published example from a 5-star Kuwait hotel: ladies' weekday KWD 47 per guest, weekend 49, 200-650 guests; men-only KWD 30 per guest, 300-1,000 guests. The booking model must be venue > hall > date > session > up to two event sections (ladies / men / mixed), each with its own guest count and package. The PRD's 'women only / men only / mixed' filters are the visible tip of this.
- Price is per guest with a minimum guest count (hotels), flat per hall/night (independent halls, villas, chalets), or a flat ministry fee (government halls). Every price on every surface needs its unit, and cards should show an estimated total for the user's guest count. 'From 46 KD' without a unit is meaningless in this market.
- KNET (the dominant local debit rail) is sale-and-refund only through MyFatoorah: no authorise/capture, no hold, no iframe, always a full-page redirect to a KNET-hosted page. This settles PRD gap #8: request-mode venues should use approve-then-pay (a timed date hold after approval, then deposit), and instant-mode venues charge the deposit at the end of the flow. Never 'charge now, refund if rejected'.
- Digits: web Intl for ar-KW defaults to Eastern Arabic-Indic digits (and Saturday-first weeks, and a trailing-period currency symbol with RLM marks), whereas Dart/Flutter intl 'ar' defaults to Western digits. Cairo's Western digits are tabular by default (all 560 units wide) while its Arabic-Indic digits are wildly proportional (250-678 units; zero is a 250-unit dot). Poppins digits are proportional and the font has NO tnum feature. Decision: Western digits everywhere, pin the numbering system explicitly, and use Cairo's digits as the 'figures' voice for prices, calendars, stats and tables in both languages.
- Currency reads visually leftmost in both languages: Arabic 'logical number then currency' renders as 'د.ك 47' visually, and English is 'KD 47'. Designers drawing Arabic in visual-LTR thinking will put 'د.ك' on the wrong side. Browse surfaces show whole dinars when fils are 000; booking/payment/invoice/balance surfaces always show 3 decimals.
- Week start: CLDR says ar-KW weeks start on Saturday (weekend Fri-Sat); the brief says Sunday-start. Recommendation: Sunday-start, because the Thu-Fri-Sat peak band then forms one contiguous block at the inline-end edge in both languages, and it matches Kuwait's Sun-Thu working week. Make it a per-country setting, since CLDR shows UAE is Mon-first with a Sat-Sun weekend and the rest of the Gulf is Sat-first (Saudi Sun-first).
- Calendar intelligence for the 2026/27 season (today is Sat 10 Oct 2026): Ramadan 1448 is about Mon 8 Feb - Mon 8 Mar 2027 (Umm al-Qura; Kuwait uses local moon sighting, so plus or minus a day), Eid al-Fitr about 9-11 Mar, Kuwait National Day and Liberation Day (Thu 25 and Fri 26 Feb) fall INSIDE Ramadan, Eid al-Adha about 16 May. Peak is Thu/Fri nights (Saturday strong, Sun-Wed discount) from November to early February and again after Eid al-Fitr; outdoor and beach venues are viable roughly November to March.
- Regulatory shock is real: Kuwait's Interior Ministry banned weddings, parties and concerts from about 13 March to 24 April 2026 (regional security), and the Municipality froze temporary wedding-tent licences. The status model (Cancelled / Rejected / Refunded plus Reschedule) needs an 'authority order' reason and a venue-side bulk reschedule path; otherwise a single event strands hundreds of deposits.
- Arabic voice: clear modern Arabic with Gulf warmth; use the honorific plural possessive 'كم' (طلبكم, حجزكم) plus verbal-noun CTAs (متابعة, تأكيد الحجز). This removes the masculine/feminine imperative problem without asking users their gender and reads as respectful in the Gulf. Never write 'ليلة الخميس' (in Arabic idiom 'ليلة الجمعة' is Thursday night): always show weekday plus date plus time.
- Imagery and content rules specific to Kuwait: empty-room photography only (never guests), no alcohol (illegal in Kuwait; welcome drinks are mocktails), no mixed-gender dancing, no bare shoulders, no royal or national emblems, no religious phrases in transactional or error copy. Policy fields must be per section: photography in the ladies' hall (female photographers only or none), music policy including a 'no instruments' option, abaya cloakroom, prayer room, separate entrances, female security.
- Government halls (Ministry of Social Affairs): 76 halls, only 24 bookable as of late 2025, rental about KD 100 (a doubling to 200 under study) versus private halls above KD 1,000 per night, delivered as an empty hall (guests bring decor, catering, staff), booked through the ministry's own app. For Ghazal this is an information listing with a 'book via the ministry' hand-off and a vendor cross-sell (catering, decor), not a payment flow.
- WhatsApp is the real CRM: about 94% of Kuwaiti social-media users use it (Ipsos 2026) and venues answer there today. Consequences: WhatsApp OTP is the primary identity; every venue, comparison and booking summary needs a first-class Share-to-WhatsApp with a clean preview; 'Call/Chat client' in the hotel app should include wa.me deep links; the in-app chat has to beat WhatsApp's response time or couples leave.
- Libphonenumber's isValid() is allocation-based and rejects legitimate-looking Kuwaiti numbers (for example +965 6123 4567 is flagged INVALID, and 7xxx/8xxx numbers are invalid). Use a loose shape check, [2569]xxxxxxx or 41xxxxxx (8 digits), and let WhatsApp OTP delivery be the real validation. Always display 4+4 grouping (+965 5123 4567); libphonenumber's own grouping is inconsistent (512 34567 vs 9988 7766).
- Apple Pay launched in Kuwait on 6 Dec 2022 (CBK) and rides KNET debit cards; iOS is about 43% of Kuwaiti mobile (StatCounter, Jul 2026), so Kuwait is not 'Android-only'. Order payment methods by platform (iOS: Apple Pay, KNET, card; Android: KNET, Google Pay if enabled by MyFatoorah, card) and design a graceful 'transaction limit' state because bank-set online KNET limits may sit below a large deposit (unverified, validate).

## Recommendations

### Booking data model and flow entry (PRD gap #9)  _(confidence: medium)_

Model a booking as Venue > Hall > Date > Session (Afternoon 12:00-16:00, Evening 19:00-01:00; Evening is the default) with 1-2 Event Sections (Ladies / Men / Mixed). Start the booking flow with a single question 'What are you hosting?' (chips: الحفل النسائي, الحفل الرجالي, الاثنان) before date. Each section has its own hall, guest count and package; totals are summed. Mixed is last in every list and never the default.

*Why:* Hotels already sell ladies and men's receptions as separate per-guest packages with separate minimums and halls; families often book both on the same night. A single 'guest count + package' step would be wrong for the dominant case.

### Price unit and price display  _(confidence: high)_

Make price_unit a first-class field: per_guest (with min_guests), per_hall_night (flat), government_fee (flat). Every price shows its unit ('46 د.ك للضيف', 'KD 46 per guest', '2,800 د.ك لليلة'), minimum guests, and on cards an estimate for the user's chosen guest count ('Est. 16,100 د.ك for 350 guests'). Day type pricing: weekday (Sun-Wed) vs weekend (Thu-Sat) plus holiday/season overrides.

*Why:* Four Seasons-style published packages (47/49 per guest, minimum 200-300) and independent-hall flat rents make a bare 'from' number misleading; the PRD's 'starting price' needs a unit and minimum to be honest.

### Deposit and payment timing (PRD gap #8)  _(confidence: medium)_

Two modes, set per venue. Instant: pay deposit at the end of the flow, status Approved immediately. Request: send the request with NO payment; venue has a 24h SLA (nudge at 12h, expire at 48h); on approval the client sees 'Approved, deposit due' with a visible date-hold countdown (for example 24h), pays by Apple Pay / KNET / card, and only then is the date confirmed. Default deposit 30% of the package total (venue-configurable), balance due 14 days before the event. Expose 'Approved, awaiting deposit' as a sub-state of Approved, not a new top-level status.

*Why:* KNET via MyFatoorah is always an immediate sale (AuthorizeAndCapture) with a full-page redirect and no iframe; authorise-then-capture does not exist for the dominant local rail. Charging then refunding on rejection creates slow, trust-eroding KNET refunds.

### Government halls  _(confidence: medium)_

Render as a distinct venue type: flat ministry fee, 'Venue only, bring your own decor and catering', no packages, no instant booking, no live availability unless a data source exists, primary CTA 'Book through the Ministry of Social Affairs' (external) and secondary CTA 'Find catering and decor for this hall' (Ghazal vendors).

*Why:* The ministry owns booking and pricing (about KD 100, possibly 200) and the hall is empty by design; the unmet need is vendors, which is exactly Ghazal's Phase 2 marketplace.

### Digits, currency, dates, phone: one formatter  _(confidence: high)_

One shared formatter module. Digits: Western 0-9 in both languages, numbering system pinned explicitly (web: locale 'ar-u-nu-latn', and set lang='ar' not 'ar-KW'; Flutter: intl 'ar' already yields Western, verify built-in pickers). Money: AR '{n} د.ك' (no trailing period, NBSP, number wrapped in an LTR isolate), EN 'KD {n}'; browse = whole dinars when fils are 000 else 3 decimals; transactional = always 3 decimals. Dates: '12 نوفمبر 2026' / '12 Nov 2026', month names in Gulf style (يناير...ديسمبر), never numeric-only dates. Time: 12-hour with ص/م and AM/PM, always displayed in Asia/Kuwait. Phone: store E.164, display '+965 5123 4567' in an LTR isolate, loose validation.

*Why:* Prevents the three classic failures: ICU's Eastern-digit default on web, bidi scrambling of numbers inside Arabic strings, and inconsistent decimals in tables.

### Week start and calendar overlays  _(confidence: medium)_

Sunday-start weeks in both apps (setting: weekStartsOn=0 per country). Shade Thu-Sat as the contiguous peak band at the inline-end edge. Overlay occasion markers (Ramadan, Eid, National/Liberation Day, Isra and Miraj; Ashura is a quiet marker) sourced from Umm al-Qura with an approximate marker until officially announced. Hijri date appears only as a muted secondary line on the selected-date confirmation and booking summary in the Arabic UI, never in grids.

*Why:* Contiguous peak band is a pure layout win; Hijri matters for occasions, not for day-to-day scheduling, and Kuwait's moon sighting can differ by a day from the algorithmic calendar.

### Arabic voice and gender handling  _(confidence: high)_

UI Arabic = clear modern Arabic with Gulf warmth. System strings use the honorific plural possessive 'كم' (طلبكم، حجزكم، زفافكم) and verbal-noun CTAs (متابعة، تأكيد الحجز، إرسال الطلب، اختيار التاريخ); no gendered imperatives unless the user declared a role in onboarding. Light Khaleeji only in greetings, success moments and push (هلا، مبروك مقدماً، ما قصّرتوا), never dialect spelling in labels. Avoid 'ليلة + weekday', 'بالرفاء والبنين', exclamation marks except one 'مبروك' at confirmation, and religious phrases in payment or error text.

*Why:* About 68-70% of Kuwait's residents are non-Kuwaiti and many read Arabic as a second language; dialect orthography is not standardised; the primary user may be the bride, her mother or the groom, so gendered verbs would misfire.

### Numeric typography role (Cairo digits as 'figures')  _(confidence: high)_

Add a third type role 'figures': Cairo Western digits for prices, KPIs, calendar cells, times, counters, tables in BOTH languages. Poppins stays for English words. Arabic text sizes = English size x 1.08-1.10 rounded to whole px (Cairo's Arabic body height is 0.50em vs Poppins x-height 0.548em); Arabic minimum 13px; set explicit line-heights (Cairo's native line box is 1.874em, Poppins 1.5em). No letter-spacing, no italics, no uppercase transforms in Arabic; weights 400/500/600/700 only.

*Why:* Measured from the font files: Poppins has no tnum or pnum features and its digit widths vary 320-635 units; Cairo Western digits are all 560 units (tabular by default) but its Arabic-Indic digits are 250-678 (not tabular).

### RTL icon, chart and gesture rules  _(confidence: medium)_

Adopt the mirror table in section 6.1 as the icon registry's 'mirror' flag. Mirror: back/forward chevrons and arrows, send, reply, undo/redo, external-link, list/sort glyphs, help (؟), switches, tab and stepper order, sliders, linear progress, calendar grids and month arrows, chronological chart axes, carousels, swipe-back edge. Never mirror: play/pause/seek and video scrubbers, clocks and circular refresh, checkmarks, calendar and phone glyphs, magnifier, pin, heart, star, share, plus/minus/close, chart-type icons, trend arrows, photos, maps, logos, digits. Charts: time/ordinal x-axes flow in reading direction (right-to-left in Arabic) inside this product for consistency with calendars and steppers, value axis never flips, endpoints always labelled with dates.

*Why:* Follows Material and Apple guidance for physical symbols versus reading-order elements. Chart mirroring is the one place Apple and Material disagree; consistency inside one app plus explicit date labels is the deciding argument.

### LTR data inside RTL screens  _(confidence: high)_

Phone, email, card number, IBAN, OTP, coupon codes, URLs, Civil ID: input has dir='ltr' and inputmode set; the label, helper and error stay in UI direction. Phone is one compound field '+965 | 5123 4567' (fixed non-interactive +965 chip in the MVP, LTR order in both languages). OTP boxes are LTR order (digit 1 on the left) in both languages. Wrap every inline number/Latin run in <bdi dir='ltr'> or an LRI...PDI isolate; never concatenate star + rating + count into one string, lay them out as separate items.

*Why:* Prevents reversed phone groups, flipped percent and minus signs, and mirrored parentheses; matches how WhatsApp delivers codes.

### Cultural content and imagery policy  _(confidence: medium)_

Photography: empty rooms and details only, moderation rule rejects identifiable people; avatars are monograms (single Arabic letter, no connected pair); no alcohol, no champagne towers, no royal portraits or emblems, no couple-touching imagery. Venue profiles carry per-section policy fields: photography (female photographers only / none / allowed), music (DJ / live / duff and nasheed only / none), abaya cloakroom, prayer room, separate entrances, female security, children and boys' age rule, outside catering and decor allowed, weather backup for outdoor.

*Why:* These are the questions Kuwaiti families actually ask; they are also the most common reasons a venue is excluded. Flagged as assumptions to validate with venue managers.

### Authority-order and mass-reschedule exception path  _(confidence: medium)_

Add 'Authority order' (قرار جهة رسمية) as a reason code on Cancelled/Rejected/Refunded and a hotel-app bulk action 'Reschedule events from date X to Y' with a pre-written client notification and fee-waiver flag. Record in docs/product/open-questions.md as an exception path of existing statuses, not new scope.

*Why:* Mar-Apr 2026 ban demonstrates the risk; without a path every affected venue handles hundreds of WhatsApp messages manually, which is exactly the pain Ghazal exists to remove.

### Seed content and clock  _(confidence: high)_

Use the seed pack in section 8 verbatim: fixed NOW = Thu 12 Nov 2026 16:00 Asia/Kuwait in both apps; client persona Reem Al-Dosari wedding Thu 14 Jan 2027 (63 days); her request to the fictional Aurelia Gulf Hotel (350 ladies guests, weekend rate 52, total 18,200.000, deposit 5,460.000) appears as the first pending request in the hotel app. 21 fictional venues across six governorates with Hawalli heaviest, four tiers plus government.

*Why:* One consistent story across both apps makes prototype review, screenshots and later Flutter fixtures coherent; the numbers are anchored to verified market data points.

## Risks & gaps

- Poppins has no tabular-figure feature (verified from the font file) but the brief demands tabular figures; if the typography owner keeps Poppins for English numerals, price columns and calendar cells will not align. Needs an explicit decision (recommended: Cairo digits as the figures role).
- Web Intl and Dart intl disagree on default digits for Arabic (web ar-KW = Eastern, Dart ar = Western; Dart has only ar, ar_DZ, ar_EG). A prototype that uses lang='ar-KW' or native date/number inputs will show Eastern digits and a currency string with a trailing period and RLM marks; the Flutter built-in Material date/time pickers may follow different data and must be checked in the Flutter phase.
- Peak-day and seasonality claims (Thursday and Friday nights peak, Saturday strong, Sun-Wed discounted, deposit 30%, balance 14 days, session times, abaya cloakroom, female-photographer rules, boys' age limits, bukhoor restrictions) are domain knowledge, not verified in this session. No web source this session gave hard demand data by weekday; validate in 5-8 venue manager interviews before locking copy and filters.
- KNET facts: sale and refund only, full-page redirect, no iframe (verified in two gateway docs). Not verified: per-transaction and daily online limits set by banks (a KWD 3,000-6,000 deposit may exceed some limits), refund timing, and whether Google Pay is live in Kuwait via MyFatoorah. Design the 'limit exceeded' and 'payment pending' states regardless.
- Pricing anchors are partly old: the Kuwait Times figures are from June 2022 (4-star KD 13-17 per person, 5-star 28-33), the Gulf News article is much older (KD 35,000 middle-class average, 500-700 hotel guests). Four Seasons Kuwait prices are current published list prices but are one premium brand. Seed prices are plausible placeholders, not market truth.
- Government hall booking channel is unclear: results name both the 'Sahel' app (Al-Rai) and a 'Dar Al-Munasabat' booking system (Al-Anba snippet); fee level is in flux (100 to 200 KD under study) and eligibility (likely Kuwaiti citizens, lower income) is not confirmed. Do not promise availability or price for government halls.
- 'Mixed' events: sensitivity and legal posture vary by family and venue. If Ghazal surfaces mixed prominently it risks alienating the core audience; if it hides it, it loses expat and progressive segments. Recommended: present, neutral, last, never default; confirm with the owner.
- Kuwait sets Ramadan, Eid and Muharram by local moon sighting; Umm al-Qura dates can be off by a day. Any hard-coded blocked-date logic must be editable by venues and labelled approximate until announced.
- Three scope questions are touched by the cultural findings and must go to docs/product/open-questions.md, not into the design silently: dual-section booking (ladies plus men on one booking), family-contact on a booking (WhatsApp number of bride's mother/organiser), and non-wedding event types (henna night, engagement, milka/contract, Ramadan Gargee'an and Ghabga events) for villas and halls.
- Phase-4 GCC readiness: CLDR says UAE is Monday-first with a Sat-Sun weekend and Western digits by default, Saudi is Sunday-first, other Gulf locales are Saturday-first with Eastern digits; Oman, Qatar, Bahrain also differ in holidays and currency. Week start, weekend, digits, currency and phone rules must be per-country config from day one.

## Open questions for the owner

- Do you approve modelling a booking as up to two event sections (ladies' reception plus men's reception) on one booking, each with its own hall, guest count and package, instead of one guest count per booking?
- Confirm the deposit rule: approve-then-pay with a 24h date hold for request-mode venues and pay-at-end for instant-mode venues (KNET cannot pre-authorise). What default deposit percentage and balance-due window should venues start with (proposal: 30% and 14 days)?
- Will Ghazal list government (Ministry of Social Affairs) halls with a hand-off to the ministry's own booking, or take bookings itself (which probably requires a ministry agreement)? Same question for whether Ghazal takes payment for them at all.
- Sunday-start weeks (brief) versus Saturday-start (CLDR default for Kuwait): confirm Sunday-start, and confirm that Western digits (0-9) are the Arabic default with no user-facing switch in the MVP.
- Should 'Mixed event' appear as a full peer filter option, or as a quieter last option? Should the planner and vendor sections also expose gender-specific services (for example female photographers and makeup artists for the ladies' hall)?
- Is a 'family contact' (WhatsApp number of the bride's mother or organiser) on a booking acceptable scope? It reflects family decision-making but is not in the PRD.
- Should the product support non-wedding event types (henna night, engagement, milka/contract, Ramadan Gargee'an) for villas and halls, or stay strictly 'wedding'?
- Which payment methods are actually contracted through MyFatoorah at launch (KNET, Visa/Mastercard, Apple Pay, Google Pay), and what are the KNET per-transaction limits for the owner's merchant account?
- Who is the venue-side SLA owner: is a 24h response window with 12h nudge and 48h auto-expiry acceptable to partner venues, and what status should an expired request take (PRD has no 'Expired')?
- Do you accept the imagery rule of empty-room photography only (no guests, no people) for venue galleries, enforced by moderation, even though it makes venues' existing Instagram content unusable?
- May the product show the authority-order exception (venue-wide reschedule with fee waiver) given the March-April 2026 precedent, and who decides refund versus transfer of deposits in such cases?

---

## Full findings

# Ghazal Field Guide: Kuwait / GCC Culture, Arabic UX and RTL

Scope: Client Mobile App and Venue/Hotel Mobile App design phase. Prepared 10 Oct 2026 (a Saturday). All money in KWD.

Evidence tags used throughout:
- **[V]** verified from a source read this session (list in section 11).
- **[T]** verified by running tools this session (Node 23 Intl/ICU-CLDR, Dart `intl` source data, font files via fontTools, libphonenumber-js metadata).
- **[K]** domain knowledge or assumption. Treat as a hypothesis to validate in 5-8 venue-manager interviews before locking copy or filters.

Hard rule honoured: `BookingSaaS v2.3 Nulled.rar` was not opened, referenced or used.

---

## 0. The decisions that change the design (read this first)

1. **A Kuwaiti wedding is two events in two rooms** (ladies' reception, men's reception). Model Event Sections; do not model "a guest count". See 2.1.
2. **Price has units**: per guest with a minimum, flat per hall/night, or flat ministry fee. Show the unit everywhere and an estimated total for the user's guest count. See 2.5.
3. **KNET cannot hold a deposit** (sale and refund only, full-page redirect). Request-mode venues use approve-then-pay with a timed date hold. See 2.9.
4. **Western digits (0-9) everywhere**, numbering system pinned explicitly, Cairo digits as the "figures" voice. See 4.1 and 6.5.
5. **Currency**: AR `47 د.ك` (renders with the currency visually on the LEFT), EN `KD 47`; whole dinars when browsing, 3 decimals when transacting. See 4.4.
6. **Sunday-start weeks**, Thu-Sat peak band contiguous at the inline-end edge; CLDR default for Kuwait is Saturday-start so this must be an explicit setting. See 4.3.
7. **Arabic voice** = clear modern Arabic with Gulf warmth, honorific plural `كم` plus verbal-noun CTAs (no gendered imperatives), never "ليلة الخميس". See 3.
8. **Imagery**: empty rooms only, no people, no alcohol, per-section policy fields. See 2.8.
9. **Government halls** are an information-plus-handoff listing with a vendor cross-sell, not a payment flow. See 2.6.
10. **Calendar facts for this season**: Ramadan about 8 Feb to 8 Mar 2027 swallows Kuwait's National and Liberation Days; the March-April 2026 wedding ban proves that authority-order mass rescheduling is a real case. See 2.3.

---

## 1. Evidence base: what is verified and what is not

| Claim | Status | Source |
|---|---|---|
| 5-star Kuwait hotel publishes ladies' weekday KWD 47/guest, weekend 49/guest, 200-650 guests (min 200 small ballroom, 300 large); men-only KWD 30/guest, 300-1,000 guests (min 300 / 500); valet complimentary; ladies' includes bridal suite, 1 night Ambassador Suite with breakfast, 3-layer show cake, welcome mocktails; menus 12 cold + 12 hot + 10 dessert (weekday), 14+14+12 (weekend); men 10-15 salads/mezze, 10-15 hot, 10-12 desserts, juices, gahwa | [V] (real brand, do NOT reuse the name in seed content) | fourseasons.com Kuwait weddings packages (search extract; page itself blocked 403) |
| June 2022: 5-star hall hire KD 1,350 without services; cheapest party KD 3,000 including food; 4-star per person 13 to 17, 5-star 28 to 33; expat weddings about 250 guests at about KD 18/person (about KD 4,500); photography about KD 600; makeup and hair can exceed KD 300; Kuwaiti women-only receptions used to host about 600 guests, recently at most 400; some hotels impose minimum guests or mandatory full packages | [V] | Kuwait Times, "Pandemic, food price increases blamed for rising wedding costs" |
| Older Gulf News/Kuwait Times figures: middle-class Kuwaiti wedding about KD 35,000 (about USD 116,000), wealthy up to KD 1 million; hotel weddings typically 500-700 guests; about 1,000 invitation cards; about 6,000-9,000 weddings a year | [V] but dated, order-of-magnitude only | Gulf News (older article), Kuwait Times, Arabian Business headline |
| Historically separate celebrations: men in a hall or diwaniya, women in a hotel/hall | [V] | Kuwait Times (Apr 2026), e.gov.kw customs page, Arabia Weddings |
| Interior Ministry banned weddings, parties, concerts and theatre from about 13 Mar 2026 "until further notice"; Municipality stopped new temporary wedding-tent licences; permission reinstated Fri 24 Apr 2026 | [V] | Emarat Al-Youm (13 and 14 Mar 2026), Voice of Emirates (24 Apr 2026) |
| Government (Ministry of Social Affairs) wedding halls: 76 total, 24 bookable (Dec 2025); fee about KD 100 with a doubling to 200 under study; "empty hall" (guests supply decor, catering, labour); aimed at limited-income Kuwaitis; private halls exceed KD 1,000 per night; booking via the Ministry's app (named "Sahel" in Al-Rai; another report names "Dar Al-Munasabat") | [V] | Al-Rai (two articles), Al-Anba (search snippet) |
| KNET via MyFatoorah is always an immediate sale (AuthorizeAndCapture) plus refund, redirects to a KNET-hosted page, no iframe; no auth/capture, no recurring | [V] two gateway docs | developer.broadleafcommerce.com MyFatoorah KNET; support.paytabs.com KNET workflow |
| Apple Pay launched in Kuwait 6 Dec 2022 (CBK press release), works over KNET-issued cards | [V] | cbk.gov.kw; checkout.com "Apple Pay via KNET" |
| iOS 42.9% / Android 57.1% of Kuwaiti mobile (Jul 2026) | [V] | StatCounter |
| WhatsApp used by about 94% of Kuwaiti social-media users (Ipsos 2026); Instagram 3.0M, Snapchat 2.4M, internet 99% | [V] | Ipsos Spotlight Kuwait via search; DataReportal Digital 2026 Kuwait |
| Kuwaiti nationals about 30-32% of residents (1.55-1.57M of 4.9-5.1M); Asians about 41% of total | [V] | PACI via Kuwait Times (Jun 2025), Gulf News |
| Kuwait has no VAT in 2026 and none expected before 2028 | [V] | vatupdate.com (Jul 2026) |
| Phone rule: 8 digits, mobiles start 5, 6, 9 and 41xx; landlines 2xxx | [V] and [T] | sent.dm; libphonenumber-js metadata |
| Intl/CLDR, Dart intl, Cairo and Poppins measurements in section 4 and 6.5 | [T] | run locally |

What is **not** verified (all [K]): weekday demand ranking, deposit percentages, session times, per-section staffing and photography rules, abaya cloakroom, boys' age limits, bukhoor restrictions, KNET online limits, Google Pay availability.

---

## 2. Kuwaiti wedding culture and what it changes in the product

### 2.1 The two-room wedding (largest single design consequence)

- **Ladies' reception (الحفل النسائي)** is the headline event [V/K]: bride, kosha (stage), zaffa (procession), dinner buffet, evening start (about 9-10 pm) [K]. Men are absent, so dress, hair and cameras are different from any other venue type.
- **Men's reception (الحفل الرجالي)** is shorter, hosted by the groom and male relatives, often after Isha or at lunch (Friday lunch after Jumu'ah is common [K]); gahwa, dates, juice, then a heavy meal; frequently in a diwaniya or a separate hall [V/K].
- **Mixed (مختلط)** exists (some families, expats, corporate) but is a minority and a sensitive label [K]. Present it as a neutral option, **last** in every list, **never the default**, never auto-suggested to someone who picked ladies-only.
- Hotels sell them as **separate products** with separate per-guest prices and minimums (see section 1). Many families book **both on the same night** in adjacent halls with separate entrances [K].

**Product consequences**
1. Booking = Venue > **Hall** (ballroom) > **Date** > **Session** > **1-2 Event Sections** (ladies / men / mixed). Each section has its own hall, guest count, package, policies. A venue may own several halls (the real example has two ballrooms with different minimums).
2. Booking flow step 0 is one question: "What are you hosting?" with chips `الحفل النسائي` | `الحفل الرجالي` | `الاثنان` (Both) and a quiet `مختلط`. Everything downstream adapts (guest-count presets, packages, policies).
3. PRD filters "Women Only / Men Only / Mixed Event" are the visible tip. On venue cards show small section badges (نسائي، رجالي) rather than a filter-only concept.
4. Policy fields are **per section** (see 2.8 list). Never show a venue-wide "Photography allowed" toggle; show "Ladies' hall: female photographers only" and "Men's hall: allowed".
5. Gallery rule: ladies' hall galleries are empty-room only (see 2.8).

### 2.2 Decision-making: the bride's family and WhatsApp

- Hypothesis [K]: the bride with her mother and sisters drives the ladies' hall choice (look, kosha, food, flow); the groom's side drives the men's reception and signs off budget; the payer is typically the groom or his family but split payment is common; the decision runs for weeks across WhatsApp family groups.
- Product consequences:
  - **Share-to-WhatsApp is a core affordance** on venue detail, compare table and booking summary, via `https://wa.me/?text=` or the system share sheet, with a clean preview (image, Arabic name, area, "from X per guest", link). No emoji in the share text.
  - **Compare is a family-meeting artifact**: the 3-column table must be screenshot-friendly (one vertical scroll, no horizontal scroll at 360 px) and exportable as one image.
  - No hidden fees; many relatives will check numbers. Kuwait has no VAT [V], so quote totals without tax lines; show a "service charge included / not included" line if the venue adds one.
  - Privacy: do not ask for a bride photo; the onboarding "Bride/Groom profile" asks for names and role only. Avatars are monograms. Reviews show first name plus initial (نورة ع.) and allow "anonymous".
  - Open scope question: optional "family contact" (WhatsApp number of the bride's mother/organiser) on a booking. Not in the PRD; goes to `docs/product/open-questions.md`.

### 2.3 Calendar, demand and seasonality

**Week.** Kuwait's working week is Sun-Thu, weekend Fri-Sat [V]. Wedding nights: Thursday and Friday highest, Saturday strong, Sun-Wed discounted [K]. Hotels already split "weekday" vs "weekend" packages (47 vs 49 per guest in the real example) [V]. Price day types to support: weekday (Sun-Wed), weekend (Thu-Sat), holiday, season override (matches PRD 8.5 Pricing Engine).

**Idiom trap.** In Arabic, **"ليلة الجمعة" means Thursday night** (the Islamic day begins at sunset). Colloquial speech also says "ليلة الخميس" loosely. Never use "ليلة + weekday" in UI. Always: weekday + date + time, for example `الخميس 12 نوفمبر · 9:00 م`.

**Season.** Weddings concentrate from autumn to spring, excluding Ramadan [V search]. Summer highs routinely exceed 45 degrees (about 50 at peaks) and many families travel [V search], so summer is off-season for weddings; indoor ballrooms still run at lower volume [K]. Outdoor, beach, garden venues are viable roughly November to March, with October and April borderline [K]. Outdoor listings need an "indoor backup" field [K]. Dust and rain days occur in winter [K].

**Key dates, 2026/27 season.** Hijri dates from Umm al-Qura via ICU [T]; Kuwait uses local moon sighting so expect plus or minus one day; label approximate until announced.

| Occasion | Gregorian (weekday) | Note |
|---|---|---|
| Today (reference) | Sat 10 Oct 2026 | |
| New Year's Day | Fri 1 Jan 2027 | falls on weekend |
| Isra and Miraj (27 Rajab 1448) | Tue 5 Jan 2027 | public holiday, may bridge |
| Ramadan 1448 begins | Mon 8 Feb 2027 | weddings essentially stop |
| National Day / Liberation Day | Thu 25 Feb / Fri 26 Feb 2027 | **inside Ramadan** this year |
| Eid al-Fitr | about Tue 9 to Thu 11 Mar 2027 | strong demand just after Eid |
| Eid al-Adha | about Sun 16 to Wed 19 May 2027 | demand before summer travel |
| Islamic New Year / Ashura | about Sun 6 Jun / Tue 15 Jun 2027 | quiet marker, no commentary |

Ramadan inventory is still used by venues for non-wedding events (Ghabga, Gargee'an on about 14 Ramadan) [K], so "blocked" needs reasons: Ramadan, other event, maintenance. Quick action in hotel app: "Block Ramadan 1448".

**Seed occupancy pattern (hotel/hall, in season, Nov-Jan):** Thu about 90% booked, Fri about 85%, Sat about 55%, Sun-Wed 15-30%; Ramadan 2027 about 5%; post-Eid (from 12 Mar) Thu/Fri about 70%; summer Thu/Fri 20-30% indoor; beach/outdoor blocked mid-May to September.

**Regulatory shock (verified).** 13 Mar to 24 Apr 2026: weddings, parties, concerts banned; temporary tent licences frozen; some couples moved to restaurants/home or postponed [V]. Add an "Authority order" reason code and a venue bulk-reschedule action (see recommendations).

### 2.4 Guest counts and budgets (KWD)

- Ladies' receptions: hotel packages host 200-650 [V]; Kuwaiti women-only used to reach about 600 and now rarely exceed about 400 [V]. Men's: 300-1,000 [V]. Hotel weddings 500-700 total guests in older reporting [V, dated].
- Guest-count presets (sliders/chips): 100, 150, 200, 300, 400, 500, 650, 800, 1,000+ (brief caps capacity at 1,500).
- Budget anchors: modest KD 2,500-3,500 total (expat/small) [V]; 5-star ladies' 350 guests about KD 16,000-18,200 for food and hall alone (47-52 per guest); hall plus both receptions at a 5-star about KD 29,000 [derived]; the old middle-class average KD 35,000 [V, dated]; photography about 600, makeup 300+ [V].
- Onboarding budget bands (venue and food, KWD): under 5,000 | 5,000-10,000 | 10,000-20,000 | 20,000-35,000 | 35,000+. Label clearly "ميزانية القاعة والضيافة" / "Venue and catering budget" so it is not confused with total wedding spend.
- Budget manager categories worth adding as presets (flag as open question, PRD lists categories generically): venue and catering, bridal (dress, makeup, henna), photography and video, kosha and floral design, entertainment and zaffa, invitations and guest favours (توزيعات), transport and luxury cars, honeymoon, and an optional "mahr and gold" category.

### 2.5 Packages and pricing models

| Model | Used by | Price field | What the page must show |
|---|---|---|---|
| Per guest with minimum | hotels, resorts | price per guest by day type, min_guests per hall | unit, minimum, estimate for N guests, menu counts |
| Flat per hall/night, catering separate | independent halls, villas, chalets | flat price by day type | "Catering not included / outside caterer allowed" |
| Flat ministry fee | government halls | single fee | "Venue only" |
| Hybrid | beach/outdoor | setup flat plus per-guest | both lines |

**Typical inclusions [V/K]:** buffet (cold, hot, dessert counts), welcome drinks or mocktails, gahwa and tea, valet (complimentary in hotels [V]), security, basic decor and lighting, kosha (basic included, bespoke extra), bridal suite or room (غرفة العروس), groom room, show cake, sound and lighting, one complimentary suite night [V], 4-6 hour evening with overtime fees [K].
**Typical extras:** bespoke kosha, fresh florals, LED screens, zaffa troupe, female photographer (about KD 450-700, anchor 600 [V]), extra hour, show cake, bukhoor and oud service, Arabic coffee station, kids' corner, extra valet staff, extra suite night.
**Booking terms to model:** deposit percentage (default 30%), balance due 14 days before, cancellation policy template (Flexible / Moderate / Strict), instant vs request, response SLA 24h.

### 2.6 Government halls

Facts [V]: Ministry of Social Affairs, 76 halls, 24 bookable (Dec 2025), booking in the ministry's own app (reported as "Sahel" and as a "Dar Al-Munasabat" system), fee about KD 100 with a study to double to 200, empty hall (guests bring decor, catering, staff, labour), many built with donor funds, aimed at limited-income Kuwaitis, private halls exceed KD 1,000 per night.
Design: venue type `government`; badge `قاعة حكومية`; price shown as "رسوم الإيجار" flat; copy "القاعة فقط. الديكور والضيافة على المستأجر"; no packages; no instant booking; no live availability without a data source; CTA 1 "الحجز عبر وزارة الشؤون الاجتماعية" (external), CTA 2 "ابحثوا عن ضيافة وديكور لهذه القاعة" (Ghazal vendors). Do not name real government halls (they are named after real people); use area-based generic names.

### 2.7 Ceremony vs reception vs related events

- **Contract (عقد القران / الملجة)**: legal contract, often at court or mosque or home [K]; usually not venue-booked. **Henna night (ليلة الحناء)**, **engagement**, **zaffa**. Henna nights and small gatherings suit villas and chalets [K].
- The product (PRD) is "wedding venue" only. Event types beyond wedding (henna, engagement, milka, Ramadan events) are an open scope question; do not design them silently.
- Checklist items beyond the PRD's list (invitation, dress, venue, photographer, cake, music, flowers, transport) that Kuwaiti users expect [K]: contract date, henna night, zaffa, guest favours, makeup trial. Add as preset suggestions only after owner approval.

### 2.8 Imagery, modesty and content sensitivities

**Imagery rules (binding for seed photography and venue moderation)**
1. Empty rooms, tables, florals, kosha, lighting, buffet, exteriors, hands/rings/details only. No identifiable faces, no guests, no staff, in any gallery, review or ad. Ladies' hall interiors with people are never published.
2. No alcohol: no champagne towers, bar shots, cocktails (illegal in Kuwait). Welcome drinks shown as mocktails and juices.
3. No mixed-gender dancing or touching, no bare shoulders or revealing dress, no couple-embracing or kissing imagery, no heart-with-couple clichés.
4. No royal portraits, state emblems, or misuse of the flag; no mosque imagery as decoration; no Quranic verses used decoratively in UI.
5. No cross, Hindu or other-faith wedding iconography unless a venue explicitly serves that community.
6. Avatars: single-letter Arabic monogram (never a connected two-letter pair; if two letters are needed use ZWNJ or separate spans). Monogram colours stay in the three-colour palette.

**Content and entertainment sensitivities**
- Music is a real axis [K]: DJ/band, duff and nasheed ("no instruments") weddings, and no music. Model Music policy as a per-venue enumerated field with a "no instruments" value, shown neutrally.
- Zaffa and entertainment are normal; fireworks and pyrotechnics indoors are not; incense (bukhoor) can be restricted by hotel fire systems [K].
- Dress code per section (abayas often worn on arrival and removed inside ladies' halls [K], thobe or formal for men).
- Children: policy for boys' age in the ladies' hall [K].
- No religious phrases in payment, error, legal or discount copy. "إن شاء الله" only in warm, non-contractual moments. Avoid "بالرفاء والبنين" (dated, gender-biased); prefer "الله يبارك لكم" or "مبروك مقدماً".
- Push timing: quiet hours 23:00-08:00 Asia/Kuwait; no marketing push during Friday congregational prayer window (about 11:30-13:00); in Ramadan shift to after Maghrib [K].

**Amenity taxonomy** (use as one consistent icon-plus-label set; AR / EN):
- Space: قاعة نسائية / Ladies' hall; قاعة رجالية / Men's hall; مدخل منفصل / Separate entrance; جناح العروس / Bridal suite; غرفة العريس / Groom's room; الكوشة / Kosha (bridal stage); حديقة أو تراس / Garden or terrace; قاعة بديلة داخلية / Indoor backup.
- Services: بوفيه مشمول / Buffet included; ضيافة الاستقبال / Welcome drinks; قهوة وشاي / Gahwa and tea; فاليه / Valet; مواقف مجانية / Free parking; حراسة نسائية / Female security; غرفة العبايات / Abaya cloakroom; مصلى / Prayer room; تسهيلات لذوي الإعاقة / Accessibility; ركن الأطفال / Kids' corner.
- Production: صوت وإضاءة / Sound and lighting; شاشات LED / LED screens; ديكور أساسي مشمول / Basic decor included; سياسة الموسيقى / Music policy; سياسة التصوير / Photography policy; بخور مسموح / Bukhoor allowed.
- Policies: ضيافة خارجية مسموحة / Outside catering allowed; ديكور خارجي مسموح / Outside decor allowed; زي الحضور / Dress code; الأطفال / Children; ساعة الانتهاء / Cut-off time and overtime; الإلغاء / Cancellation.

### 2.9 Payments: KNET, cards, Apple Pay, cash

- **KNET** (Kuwaiti bank debit cards) via MyFatoorah: immediate sale, refund supported, **no authorise/capture, no recurring, no iframe**, always a full-page redirect to a KNET-hosted page where the customer enters card details [V]. UX consequences: open in a secure in-app browser; handle back-button, abandonment and timeout; show "Payment pending, checking status" and poll the server (never trust only the client redirect); idempotent confirmation; a clear "No amount was charged" failure state.
- **Cards** (Visa/Mastercard): 3-D Secure via the gateway; support authorise/capture there if ever needed, but the booking logic must not depend on it.
- **Apple Pay**: live in Kuwait since 6 Dec 2022 [V]; iOS is about 43% of devices [V]. Express checkout on the deposit step for iOS.
- **Order of methods** by platform: iOS Apple Pay, KNET, card; Android KNET, Google Pay (only if enabled for the merchant; verify), card. Cash: only "where the venue allows"; the booking still reserves the date with an expiry (status "awaiting cash deposit").
- **Limits** [K, validate]: bank-set online KNET limits may be below a typical deposit (a KD 5,460 deposit is possible). Design a "Transaction limit exceeded" state offering card, split into two payments, or bank transfer (venue-dependent).
- **Refunds**: show "Refund initiated" with an honest "usually a few working days, depends on your bank" note.
- **Resolution of PRD gap #8** (see recommendations): request-mode = approve then pay within a hold window (default 24h); instant-mode = pay at the end. Deposit default 30%, balance 14 days before; both venue-configurable. "Approved, awaiting deposit" is a sub-state of Approved. Date hold timer is visible and honest.
- **Amounts**: always 3 decimals in this flow (see 4.4). Never show estimated tax lines (no VAT) [V].

### 2.10 WhatsApp-centric behaviour

- WhatsApp OTP is the primary identity (PRD). Provide: 6-digit code, 60 s resend, "open WhatsApp" deep link, OTP boxes in LTR order; fallback paths for the roughly 6% of social users not on WhatsApp [V]: Apple/Google sign-in and email OTP.
- Identity is the phone number (WhatsApp-capable); email optional. Forms use a single "الاسم الكامل / Full name" field (Arabic names are often 4 parts; never force first/last), Arabic or Latin accepted.
- Deep links: `https://wa.me/96551234567` (digits only, no plus, no spaces). Hotel app "Call client" and "Chat" show tel: and WhatsApp.
- Venue staff already live in WhatsApp [K], so the in-app chat must offer quick replies, push with inline reply, read receipts and a visible "usually replies within X" so it beats WhatsApp.
- Booking updates may also be sent as WhatsApp template messages (PRD lists WhatsApp for marketing and notifications).
- Instagram (3.0M users) and Snapchat (2.4M) are discovery channels [V]; consider an "open venue on Instagram" link in venue details (low priority).

---

## 3. Language, tone and Arabic microcopy

### 3.1 Register decision

Ghazal Arabic = **clear modern Arabic with Gulf warmth**.
- Structure, labels, legal and payment text: simplified MSA. Reasons: about 70% of Kuwait's residents are non-Kuwaiti and many read Arabic as a second language [V]; dialect has no standard spelling (ج/ي variants); screen readers and text-to-speech need standard forms; legal clarity.
- Warm moments only (welcome, success, push, empty states, chat from staff): light Khaleeji. Safe set: هلا، يا هلا والله، ما قصّرتوا، تفضلوا، على راحتكم، مبروك مقدماً، الله يبارك لكم.
- Not in labels or buttons: شنو، وين، شلون، زين، الحين، جذي، تبي. They are fine in venue chat messages written by humans.
- English: warm, precise, never saccharine. "Your request is with the venue. They usually reply within 24 hours." No emoji, no "Welcome back".

### 3.2 Gender and address strategy

- Possessives use the honorific plural **`كم`**: طلبكم، حجزكم، موعدكم، زفافكم، حسابكم. It is respectful, gender-neutral, and natural for couples and families.
- CTAs are **verbal nouns** or noun phrases: متابعة، تأكيد الحجز، إرسال الطلب، اختيار التاريخ، مقارنة، حفظ في المفضلة. No `اختر/اختاري`.
- Plural imperatives (جرّبوا، راجعوا، ثبّتوا) are acceptable in notifications and empty states.
- Greeting without pronoun: `أهلاً وسهلاً`، with name: `أهلاً وسهلاً، ريم`. Avoid `حيّاك الله` (masculine).
- If onboarding records the user's role, gendered forms may be used only where a pronoun is unavoidable; always fall back to neutral.
- Hotel app: professional MSA, light Gulf flavour, same `كم` convention for client-facing strings; staff-facing labels are plain nouns.
- Honorifics: no `سمو/الشيخ` anywhere; `الأخ / الأخت` only in chat greetings by staff.

### 3.3 Glossary (use these terms; synonyms are search aliases only)

| English | Arabic UI term | Notes |
|---|---|---|
| Wedding | الزفاف / حفل الزفاف | "العرس" accepted in search |
| Wedding hall | قاعة (أفراح) | alias: صالة |
| Hotel | فندق | |
| Government hall | قاعة حكومية | |
| Beach | شاطئية | quick category "قاعات شاطئية" |
| Outdoor | في الهواء الطلق | |
| Luxury / VIP | فاخرة / VIP | keep "VIP" Latin |
| Ladies' reception | الحفل النسائي | avoid "حريمي" in UI (accept in search) |
| Men's reception | الحفل الرجالي | |
| Mixed event | حفل مختلط | |
| Bride / Groom | العروس / العريس | |
| Bridal room / suite | غرفة العروس / جناح العروس | |
| Groom's room | غرفة العريس | |
| Kosha | الكوشة | EN: "Kosha (bridal stage)" on first use |
| Zaffa | الزفّة | EN: "Zaffa (bridal procession)" |
| Buffet | بوفيه | |
| Valet | فاليه | |
| Security | الحراسة | |
| Decoration | الديكور | |
| Parking | مواقف السيارات | |
| Photography | التصوير | female photographer: مصوّرة |
| Guests (invited) | المدعوّون | "عدد المدعوين" for the count |
| Capacity | السعة | |
| Package | الباقة | |
| Extras | الإضافات | |
| Special requests | طلبات خاصة | |
| Deposit | العربون | standard and Gulf-natural |
| Remaining balance | المبلغ المتبقي | |
| Booking / Request | الحجز / الطلب | |
| Available / Booked / Unavailable | متاح / محجوز / غير متاح | |
| Instant booking | حجز فوري | |
| Compare | مقارنة | |
| Wishlist | المفضلة | |
| Wedding planner (service) | تنسيق الأعراس | person: منسّق/ـة الأعراس |
| Silver / Gold / Royal | الفضية / الذهبية / الملكية | agree with feminine "باقة" |
| Checklist / Budget / Countdown | قائمة المهام / الميزانية / العدّ التنازلي | |
| Messages / Profile | الرسائل / حسابي | |
| Hotel app tabs | اليوم / الحجوزات / التقويم / الرسائل / المزيد | |
| Pending requests | طلبات بانتظار الرد | |
| Accept / Decline / Reschedule | قبول / اعتذار / تغيير الموعد | "اعتذار" is softer than "رفض" |
| Call client | الاتصال بالعميل | |
| Blocked dates | تواريخ مغلقة | |
| Offers / Flash sale / Coupon | العروض / عرض لفترة محدودة / كوبون | |
| Analytics | الإحصائيات | views مشاهدات، clicks نقرات، conversion معدل التحويل، top packages أفضل الباقات |
| Staff / Bank info / Business hours | الموظفون / البيانات البنكية / ساعات العمل | roles: المدير، الاستقبال، المحاسب، التسويق |

### 3.4 Status and microcopy bank

Booking status chips (always icon plus label, never colour alone):
- Pending: `بانتظار الرد` / Awaiting reply
- Approved, awaiting deposit: `تمت الموافقة · بانتظار العربون` / Approved, deposit due
- Confirmed (Approved and paid): `مؤكد` / Confirmed
- Rejected: `اعتذرت القاعة` / Venue unable to host
- Cancelled: `ملغي` / Cancelled
- Completed: `مكتمل` / Completed
- Refunded: `تم الاسترداد` / Refunded

Patterns (calm, passive where possible, no exclamation marks except one "مبروك"):
- Request sent: `تم إرسال طلبكم. عادةً ترد القاعة خلال 24 ساعة.` / Your request has been sent. Venues usually reply within 24 hours.
- Payment failed: `تعذّر إتمام الدفع. لم يُخصم أي مبلغ.` / The payment could not be completed. No amount was charged.
- Empty search: `لا توجد قاعات مطابقة لخياراتكم. جرّبوا توسيع التاريخ أو المنطقة.` / No venues match. Try widening the date or area.
- Offline: `لا يوجد اتصال بالإنترنت. ما حفظتوه متاح للعرض.` / You're offline. Saved items are still available.
- Confirmation: `مبروك مقدماً، تم تأكيد حجزكم.` / Congratulations in advance, your booking is confirmed.
- Countdown (PRD milestones): 365 `باقي سنة على الزفاف` | 180 `باقي 6 أشهر` | 30 `باقي 30 يوماً` | 7 `باقي 7 أيام` | tomorrow `غداً زفافكم` | today `اليوم زفافكم، ألف مبروك`.
- Never use `ليلة الخميس`; use `مساء الخميس 14 يناير`.

Push notifications (AR / EN; fixed seed values):
1. `تم إرسال طلبكم إلى فندق أوريليا الخليج. سنُعلمكم فور ردّ القاعة.` / Your request was sent to Aurelia Gulf Hotel. We'll tell you as soon as the venue replies.
2. `وافقت القاعة على طلبكم. ثبّتوا الموعد بدفع العربون قبل 8:00 م غداً.` / The venue approved your request. Secure the date by paying the deposit before 8:00 PM tomorrow.
3. `تم استلام العربون (5,460.000 د.ك). حجزكم مؤكد، مبروك مقدماً.` / Deposit received (KD 5,460.000). Your booking is confirmed.
4. `المبلغ المتبقي 12,740.000 د.ك يُسدَّد قبل الحفل بـ 14 يوماً.` / The remaining KD 12,740.000 is due 14 days before your event.
5. `باقي 30 يوماً على زفافكم. راجعوا قائمة المهام.` / 30 days to go. Review your checklist.
6. `انخفض سعر الحفل النسائي في قصر النخيل ليوم الخميس 3 ديسمبر إلى 28 د.ك للضيف.` / Ladies' reception at Qasr Al-Nakheel on Thu 3 Dec dropped to KD 28 per guest.
7. Hotel app: `طلب حجز جديد · الحفل النسائي · الخميس 21 يناير · 350 مدعواً` / New request · Ladies' reception · Thu 21 Jan · 350 guests.

### 3.5 Arabic plurals (ICU categories verified [T]: zero, one, two, few for 3-10, many for 11-99, other for 100+; also 103 is few, 111 is many)

| Noun | one | two | few (3-10) | many (11-99) | other (100+) |
|---|---|---|---|---|---|
| ضيف / guest | ضيف واحد | ضيفان | {n} ضيوف | {n} ضيفاً | {n} ضيف |
| يوم / day | يوم واحد | يومان | {n} أيام | {n} يوماً | {n} يوم |
| قاعة / hall | قاعة واحدة | قاعتان | {n} قاعات | {n} قاعة | {n} قاعة |
| طلب / request | طلب واحد | طلبان | {n} طلبات | {n} طلباً | {n} طلب |
| حجز / booking | حجز واحد | حجزان | {n} حجوزات | {n} حجزاً | {n} حجز |
| تقييم / review | تقييم واحد | تقييمان | {n} تقييمات | {n} تقييماً | {n} تقييم |
| ساعة / hour | ساعة واحدة | ساعتان | {n} ساعات | {n} ساعة | {n} ساعة |

Rules: zero uses "لا {plural}" (لا طلبات). The dual changes to `-ين` after a preposition (`خلال يومين`, `لمدة ساعتين`), which ICU cannot express, so write those strings as explicit variants. Prefer the "label: value" pattern (`عدد المدعوين: 350`) to dodge grammar wherever a count is not the headline.

### 3.6 Search normalisation and synonyms (Arabic)

Normalise for matching only: strip tashkeel and tatweel; unify أ إ آ to ا; ى to ي; optional ة to ه; unify Eastern and Western digits; make "ال" optional; case-fold Latin. Synonym sets: قاعة / صالة / قصر / ديوانية (men's); فندق / هوتيل; نسائي / حريمي (search only) / ladies / women; رجالي / رجال / men; كوشة / كوشه / منصة; عروس / bride. Geographic alias table per area (examples): Mishref = مشرف / Mishrif / Meshref; Messila = المسيلة / Mesilah; Fintas = الفنطاس / Fintass; Funaitees = الفنيطيس / Fnaitees; Jleeb = جليب الشيوخ / Jleeb Al-Shuyoukh; Khaitan = خيطان / Kheitan; Mahboula = المهبولة / Mahbula; Egaila = العقيلة / Eqaila; Fahaheel = الفحيحيل / Fahaheil; Bneid Al-Qar = بنيد القار / Bnaid Al-Gar / Bneid Al-Gar; Salmiya = السالمية / Salmiyah.

### 3.7 Arabic typography and punctuation rules

- Use Arabic punctuation in Arabic copy: `،` `؛` `؟` and guillemets `« »`; the Latin comma only inside numbers.
- No letter-spacing (breaks joining), no italics (faux slant), no uppercase transforms; "eyebrow" labels that are uppercase-tracked in English use weight and colour only in Arabic.
- No justified text, no hyphenation. Use NBSP between number and unit (`350 مدعو`, `47 د.ك`).
- Brand: Arabic wordmark `غزل` in Arabic UI; Latin "Ghazal" in English UI. Venue names show the Arabic name in Arabic UI and the English name in English UI; Latin secondary line only when the venue is Latin-branded.

---

## 4. Numbers, dates, currency, phone, address

### 4.1 Digits policy (resolves digest gap #11)

**Decision: Western digits (0-9) in both languages, everywhere** (prices, dates, times, phones, OTP, counters). No user-facing switch in the MVP; the formatter keeps a `numberingSystem` parameter for a later setting.

Evidence [T unless noted]:
- Web ICU/CLDR: `ar-KW` and every Gulf locale except UAE default to **Eastern Arabic-Indic** digits (`‏٤٧٫٠٠٠ د.ك.‏`); `ar` and `ar-AE` default to Latin. So a prototype with `lang="ar-KW"` or native inputs silently shows Eastern digits.
- Dart `intl` (Flutter): only `ar`, `ar_DZ`, `ar_EG` exist; `ar` uses Western digits with `.` decimal and `,` group; `ar_EG` uses Eastern. `Locale('ar','KW')` falls back to `ar` (Western). Web and Flutter therefore disagree unless pinned.
- Cairo: Western digits are tabular by default (all advance 560 units); Arabic-Indic digits are proportional and very uneven (250 to 678; the zero is a 250-unit dot). Poppins has no Arabic-Indic digits at all.
- Safety: KNET page, WhatsApp OTP, civil-ID and bank apps use Western digits; Eastern forms of 4/5/6/7/9 are easy to misread in money.
- Market trend: Gulf banking/productivity apps lean Western; cultural/religious lean Eastern [V search].

Implementation: web `new Intl.NumberFormat('ar-u-nu-latn', …)` and set `<html lang="ar" dir="rtl">` (not `ar-KW`); avoid native `<input type=date|number>`; Flutter `ar` is already Western but verify Material date/time pickers.

### 4.2 Formatter spec (shared module; the only place numbers become strings)

```ts
const NBSP = ' ', LRI = '⁦', PDI = '⁩';
const loc = (lang) => (lang === 'ar' ? 'ar-u-nu-latn' : 'en-GB');
// browse: 0 decimals when fils == 000, else 3. exact: always 3.
export function money(amount, { lang, exact = false }) {
  const whole = Math.round(amount * 1000) % 1000 === 0;
  const n = new Intl.NumberFormat(loc(lang), {
    minimumFractionDigits: exact ? 3 : whole ? 0 : 3,
    maximumFractionDigits: 3,
  }).format(amount);
  return lang === 'ar' ? `${LRI}${n}${PDI}${NBSP}د.ك` : `KD${NBSP}${n}`;
}
```
Amounts are integers in fils internally (KWD has 1,000 fils; smallest coin 5 fils [K]; seed prices use multiples of 0.500). Use `KWD` (ISO) only on invoices and legal receipts.

### 4.3 Dates, weeks, time, Hijri

- **Gregorian is primary.** Month names, Gulf style [T]: يناير، فبراير، مارس، أبريل، مايو، يونيو، يوليو، أغسطس، سبتمبر، أكتوبر، نوفمبر، ديسمبر. Formats: AR `الخميس 12 نوفمبر 2026`, EN `Thursday 12 November 2026` (short `12 Nov 2026`). Never numeric-only (`12/11/2026` is ambiguous and scrambles in RTL). ISO only inside an LTR isolate in technical contexts.
- **Time:** 12-hour with `ص`/`م` and AM/PM, always **Asia/Kuwait (UTC+3, no DST)**, even if the device is elsewhere (label when different). Ranges as words: `من 7:00 م إلى 1:00 ص`.
- **Week start:** CLDR for `ar-KW` is **Saturday-first**, weekend Fri-Sat [T]; Saudi Sunday-first; UAE Monday-first with Sat-Sun weekend [T]. **Decision: Sunday-first** for Kuwait: matches the Sun-Thu working week, and Thu-Fri-Sat (peak) becomes one contiguous 3-column block at the inline-end edge in both languages (left in Arabic, right in English). Store as `weekStartsOn` and `weekend` per country config.
- **Weekday headers** (7-column grid, 3 letters, with full name for accessibility): أحد · اثن · ثلا · أرب · خمي · جمع · سبت (CLDR narrow single letters ح ن ث ر خ ج س are too cryptic). EN: Sun Mon Tue Wed Thu Fri Sat.
- **Hijri:** Umm al-Qura via ICU. Shown only (a) as occasion markers on calendars and (b) as a muted secondary line on the selected-date confirmation and booking summary in the Arabic UI, for example `الخميس 14 يناير 2027 · 6 شعبان 1448 هـ`. Never in grids. Approximate until announced (moon sighting can differ by a day).
- **Prototype clock:** fixed NOW = Thu 12 Nov 2026 16:00 Asia/Kuwait in both apps (peak-night hotel dashboard; client wedding Thu 14 Jan 2027 is 63 days away).

### 4.4 Currency (KWD)

- 3 decimals internally and in transactions. 1 dinar = 1,000 fils.
- **Arabic:** `47 د.ك` / `1,250.000 د.ك` (no trailing period; CLDR's `د.ك.` with RLM marks is not used). Logical order is number then currency, which **renders with the currency visually on the left**. Designers mocking Arabic in visual-LTR must place `د.ك` to the **left** of the digits. **English:** `KD 47` / `KD 1,250.000`. In both languages the currency sits visually left of the number; right-align amount columns on the number's right edge.
- Browse surfaces (cards, filters, ranges): whole dinars when fils are 000. Transactional surfaces (booking summary, deposit, balance, invoice, hotel revenue lists): always 3 decimals, tabular, one precision per column.
- Units: `47 د.ك للضيف`, `2,800 د.ك لليلة`; EN `KD 47 per guest`, `KD 2,800 per night`; minimum `الحد الأدنى 200 مدعو`.
- Ranges: AR `من 22 إلى 52 د.ك`; EN `KD 22 - 52`. Compact (`18.4K`/`18.4 ألف`) only on chart axes; money-critical numbers are never compacted.
- No VAT line [V]; show "service charge" only if a venue declares one.
- Kuwait IBAN: 30 characters (`KW` + 2 check digits + 4-letter bank code + 22 alphanumerics) [K]; hotel-app bank info field is LTR, uppercase, grouped by 4, validated by mod-97.

### 4.5 Phone numbers

- Country code +965; **8 digits**; mobiles start 5, 6, 9 (and 41xx); landlines start 2 [V/T]. Store E.164 (`+96551234567`). The MVP has a fixed non-interactive `+965` chip (GCC selector later).
- Display always **4+4**: `+965 5123 4567` (libphonenumber groups inconsistently: `512 34567`, `4123 4567`, `9988 7766` [T]). Render inside an LTR isolate.
- **Validation:** libphonenumber `isValid()` is range-allocation based: `+965 6123 4567` and `+965 9123 4567` return INVALID, `7xxxxxxx`/`8xxxxxxx` invalid, `5500 12345` style valid [T]. Use a loose shape check `^(?:[2569]\d{7}|41\d{6})$` plus `isPossible()`, and let WhatsApp OTP delivery be the true validation.
- Seed numbers: Kuwait has no reserved fictional range; use obviously patterned `5000 00NN` / `9000 00NN` style values in prototype fixtures, display-only, never real numbers.
- WhatsApp: `https://wa.me/965XXXXXXXX`; call: `tel:+965XXXXXXXX`.

### 4.6 Address, PACI and ID conventions

- Kuwait addresses are **Area, Block (قطعة), Street (شارع), optional Avenue (جادة), House/Building (منزل / قسيمة), Floor, Flat**. Block numbers repeat across areas, so the area is mandatory. PACI maintains the address system ("Kuwait Finder") with an 8-digit **automated address number (الرقم الآلي)**; the **Civil ID (الرقم المدني)** is a different 12-digit identifier. The colloquial "الرقم الآلي" is ambiguous, so label fields explicitly.
- Venues: show `Area · Block · Street` text plus a map pin; no PACI number needed. Provide a directions chooser (Google Maps, Apple Maps, Waze [K]).
- Home-service vendors (makeup, henna at home) need a delivery address with block/street/house; PACI address number optional.
- Do **not** collect Civil ID in the MVP (data minimisation; Kuwait's CITRA data-privacy regulation [K, verify]). If a venue contract requires it, collect off-app.

---

## 5. Bidi pitfalls (catalogue with fixes)

1. **Phone numbers in Arabic sentences** scramble (groups reverse, `+` jumps): wrap in `<bdi dir="ltr">` / LRI...PDI.
2. **Price with currency**: use the formatter; number in an LTR isolate, NBSP, then `د.ك`; no trailing period.
3. **Minus, plus, percent**: `-50.000`, `+15%` flip sides in RTL. Wrap the whole token in an LTR isolate; use `−` (U+2212) for negatives; for percent in Arabic copy write `15%` inside the isolate (CLDR's `٪؜` is Eastern-oriented).
4. **Ranges** `1,200 - 2,500` reorder. AR uses words (`من … إلى …`); EN uses an en dash; each number isolated.
5. **Latin brand names in Arabic strings** (`فندق Aurelia`): parentheses and trailing punctuation jump; isolate the Latin run; avoid ending a sentence with a Latin run; prefer the Arabic transliteration in Arabic UI.
6. **Dates** numeric-only scramble; use month names. **Times** isolated: `9:00 م`.
7. **Rating `4.8 (125)`**: do not concatenate; lay out star icon, rating, count as separate items so layout (not the bidi algorithm) controls order.
8. **Ellipsis**: end-truncation on Arabic cuts the visual left; do not truncate through a number or isolate; give names two lines before truncating.
9. **Inputs**: search and name fields use `dir="auto"`; LTR data fields use `dir="ltr"` (see 6.3).
10. **Digits visually smaller than Arabic ascenders** inside Arabic text: use Cairo for the digits (font stack Cairo first in Arabic), not a fallback.
11. **Currency symbol with trailing periods** (`د.ك.`) can mis-order against following LTR text; avoid the trailing period.
12. **Never mirror**: photos, maps, logos, QR codes, digits, Latin text.
13. **`lang`/locale**: `lang="ar"` plus pinned `-u-nu-latn`; avoid native date/number inputs (they re-introduce Eastern digits).

---

## 6. RTL design rules

### 6.1 Mirror table (icon registry `mirror` flag)

**Mirror (direction carries reading-order meaning):** back/forward arrows and chevrons (back points right in Arabic), list-row disclosure chevrons, next/previous, send, reply, forward, undo/redo, external-link/open-in-new, sign-in/sign-out arrows, text-line glyphs (list, sort, notes, menu with uneven lines), help question mark (`?` becomes `؟`), toggle switches (on = knob toward inline-end), segmented controls and tab order (first item at the right), steppers and breadcrumbs, linear progress fill (fills from inline-start, so right to left), sliders (min at inline-start), calendar grids (week starts at the right) and month previous/next arrows, rating-star row fill direction, page-indicator order, carousels (first item at the right), swipe-back (from the right edge), chronological chart x-axes.

**Never mirror (physical or non-directional):** play, pause, skip, rewind, fast-forward and video/audio scrubbers (Apple and Material both say media transport stays universal [V search]); clocks, timers, stopwatch, circular refresh and circular progress (clockwise stays clockwise); checkmark, plus, minus, close; calendar glyph; phone handset (decision: not mirrored); camera, image, microphone; magnifier (decision: not mirrored, matches iOS and the major social apps); location pin, compass, map; heart, star, bookmark, bell; share (use the box-and-up-arrow glyph); filter funnel and sliders-settings glyph; chart-type icons and trend arrows (up means more); digits and Latin text; photos, maps, logos.

**Judgement calls (documented):**
- **Charts**: time and ordinal x-axes flow in reading direction (right-to-left in Arabic) so a 7-day or 12-month bar chart agrees with the week strip, calendars and steppers in the same product; the value axis never flips (up is more), y-axis labels sit at the inline-start edge, every chart labels first and last date explicitly. Apple's guidance says graphs do not flip; Material says time mirrors but circular does not. This is the one place the two disagree, so the rule is documented as an ADR.
- **Voice notes in chat**: layout mirrors (play button at inline-start, duration at inline-end, fill grows away from the button) but the play triangle glyph never flips. Full-screen venue video and audio players keep an LTR scrubber.
- **Chat bubbles**: "own" messages align to inline-end (left in Arabic), as in iMessage; bubble tail follows.

### 6.2 Layout and structure

- Logical CSS only (`margin-inline-start`, `inset-inline-end`, `padding-inline`, `text-align: start`); the existing AGENTS.md rule stands.
- Bottom nav order mirrors (Discover at the right in Arabic). Back at the top-right with a right-pointing chevron.
- Primary action: full-width where possible. In two-button rows, primary sits at the inline-end side (left in Arabic).
- Peak band (Thu-Sat) at inline-end in both languages (see 4.3).
- Horizontal lists start scrolled to inline-start; the peeking card is at inline-end. Counters read `1 من 6` / `1 of 6` with LTR digits.
- Sheet header: title at inline-start, close at inline-end; drag handle centred. Swipe actions on rows: dragging toward inline-start reveals actions at inline-end.
- Screen push/pop and sheet-over-sheet transitions: enter from inline-end, exit toward inline-start; implement with a `--dir: 1 | -1` multiplier, not hard-coded signs.

### 6.3 Inputs with LTR data inside RTL screens

- Phone, email, card number, IBAN, OTP, coupon code, URL, Civil ID: element `dir="ltr"`, correct `inputmode`/`autocomplete`; label, helper and error stay in UI direction. Align the value to the screen's start edge (text-align right in Arabic via a UI-direction variable, not a left/right layout property; `match-parent` also works in modern Chrome).
- **Phone field** is one compound: fixed `+965` chip then 4+4 digits, LTR order in both languages, full width. Rationale: the number reads left-to-right and the eye does not have to jump.
- **OTP**: 6 boxes in LTR order in both languages, paste and one-time-code autofill, 60 s resend.
- Name fields `dir="auto"`; one full-name field.
- Keyboard: numeric keypad Western; Arabic keyboard for names and chat.

### 6.4 Gestures, carousels, sheets

Image galleries: first image at the right; swipe left to advance; shared-element expansion originates from the tapped card in either direction. iOS edge back-swipe starts at the right edge in Arabic; Android system back unchanged. Bottom sheets only drag vertically; any horizontal affordances use logical start/end.

### 6.5 Typography for both scripts (measured from the font files [T])

| Metric | Cairo (variable, wght 200-1000) | Poppins (Regular) |
|---|---|---|
| Arabic body-letter height (beh, heh, dal) | 0.500em | n/a |
| Alef / lam / kaf ascender | 0.717em | n/a |
| Deepest descenders (meem, yeh) | -0.332 / -0.430em | n/a |
| Latin x-height / cap height | 0.500 / 0.700em | 0.548 / 0.698em |
| Western digit height | 0.660em | 0.724em |
| Western digit width | all 560 (tabular by default) | 320 to 635 (proportional) |
| Arabic-Indic digits | present, 250-678 wide (not tabular) | absent |
| OpenType tnum / pnum / lnum | none needed (digits already tabular) | **none (only ss01-ss04)** |
| Native line box (hhea) | 1.874em | 1.500em (incl. gap) |

Consequences and rules:
- Arabic needs about **+8-10%** size to match Latin: AR size = EN size x 1.08-1.10 rounded to whole px (EN 16/24 body maps to AR 17/28); Arabic minimum 13px. Set explicit line-heights per language (AR body 1.65-1.75; headings 1.35-1.45; EN body 1.5); never `line-height: normal` for Cairo.
- Poppins cannot provide tabular figures. Add a **"figures" role**: Cairo Western digits for prices, KPIs, calendar cells, times, countdowns, table cells in both languages. Poppins remains for English words. This is a decision for the typography owner; record as an ADR.
- Font stacks: AR `Cairo, Poppins, system-ui`; EN `Poppins, Cairo, system-ui` (Arabic venue names inside English UI fall back to Cairo); figures `Cairo`.
- Weights: Cairo 400/500/600/700, Poppins 400/500/600. No Arabic italics. Keep Cairo variable with Arabic plus Latin subsets to respect the 2 s load NFR.

### 6.6 Motion

Direction-aware transitions (see 6.2); progress and stepper animations fill in reading direction; carousels settle in reading direction; media scrubbers and clocks never reverse. `prefers-reduced-motion` respected.

### 6.7 RTL QA checklist (every screen, both languages, 360/390/430)

1. Mirror registry respected (no back arrow pointing the wrong way, no mirrored play/clock/check).
2. No physical left/right in layout code; no hard-coded sign in animations.
3. Every number, price, phone, date and Latin run isolated; no scrambled order.
4. Currency visually left of number in both languages; one precision per column.
5. Arabic sizes and line-heights per 6.5; no clipping of descenders; no letter-spacing on Arabic.
6. LTR data fields behave (phone compound, OTP order, caret).
7. Calendar: Sunday at inline-start; Thu-Sat band at inline-end; month arrows correct.
8. Tab order, stepper, slider, progress, star fill mirror.
9. Photos, maps, logos not mirrored; no people in imagery.
10. Eastern digits appear nowhere (screenshot grep in Arabic).

---

## 7. Kuwait geography: areas by governorate (usable picker data)

Six governorates. Canonical Arabic is the key; English is the canonical transliteration; keep an alias table (see 3.6). Picker groups by governorate, searchable, defaulted by the onboarding "preferred area". "Kuwait City" in everyday speech means the Capital governorate cluster. Verified against Wikipedia "Areas of Kuwait" [V]; wedding relevance notes are [K].

| Governorate (AR / EN) | Areas (AR / EN) | Wedding-market note |
|---|---|---|
| العاصمة / Capital (Al Asimah) | شرق Sharq · بنيد القار Bneid Al-Qar · الشويخ Shuwaikh · الدسمة Dasma · كيفان Kaifan · الشامية Shamiya · الروضة Rawda · العديلية Adailiya · القادسية Qadsiya · المنصورية Mansouriya · السرة Surra · اليرموك Yarmouk · الصليبيخات Sulaibikhat · عبدالله السالم Abdullah Al-Salem · الدوحة Doha · النزهة Nuzha · الدعية Daiya | Gulf-front 5-star hotels (Sharq, Bneid Al-Qar), Shuwaikh business hotels |
| حولي / Hawalli | حولي Hawalli · السالمية Salmiya · الجابرية Jabriya · بيان Bayan · مشرف Mishref · الرميثية Rumaithiya · سلوى Salwa · الشعب Shaab · السلام Salam · حطين Hateen · الزهراء Zahra · الصديق Siddeeq · الشهداء Shuhada · البدع Bida'a · مبارك العبدالله (غرب مشرف) Mubarak Al-Abdullah | densest cluster of 4-5 star hotels and wedding halls (Salmiya, Jabriya, Mishref, Salwa) |
| الفروانية / Farwaniya | الفروانية Farwaniya · خيطان Khaitan · جليب الشيوخ Jleeb Al-Shuyoukh · العارضية Ardiya · الأندلس Andalus · الرابية Rabiya · العمرية Omariya · الرحاب Rehab · صباح الناصر Sabah Al-Nasser · إشبيلية Ishbiliya · الفردوس Ferdous · الضجيج Dajeej · عبدالله المبارك Abdullah Al-Mubarak · الري Al-Rai | large, value-priced halls |
| الأحمدي / Ahmadi | الأحمدي Ahmadi · الفحيحيل Fahaheel · المنقف Mangaf · المهبولة Mahboula · أبو حليفة Abu Halifa · الصباحية Sabahiya · الرقة Riqqa · الفنطاس Fintas · العقيلة Egaila · هدية Hadiya · الظهر Dhaher · الوفرة Wafra · الزور Zour · الخيران Khiran · مدينة صباح الأحمد البحرية Sabah Al-Ahmad Sea City · علي صباح السالم Ali Sabah Al-Salem | south coast: Fintas, Khiran, chalets and outdoor winter venues |
| الجهراء / Jahra | الجهراء Jahra · القصر Qasr · النعيم Naeem · العيون Oyoun · الواحة Waha · تيماء Taima · سعد العبدالله Saad Al-Abdullah · النسيم Nasseem · الصليبية Sulaibiya · كاظمة Kazma · العبدلي Abdali | large halls, tents and gardens |
| مبارك الكبير / Mubarak Al-Kabeer | مبارك الكبير Mubarak Al-Kabeer · القرين Qurain · العدان Adan · القصور Qusour · المسيلة Messila · صباح السالم Sabah Al-Salem · أبو فطيرة Abu Fatira · أبو الحصانية Abu Al-Hasaniya · الفنيطيس Funaitees · المسايل Masayel | Messila beach hotels and resorts, Qurain/Sabah Al-Salem halls |

Notes: Salwa, Mishref, Salmiya, Jabriya, Bayan are in **Hawalli** (not Mubarak Al-Kabeer); **Fintas and Khiran are in Ahmadi**; **Funaitees and Messila are in Mubarak Al-Kabeer** (Messila resort/beach area vs Masayel residential area); Bneid Al-Qar and Shuwaikh are in the Capital. Distance copy: Kuwait is small (most venues 10-45 minutes by car); show drive time with distance in Compare.

---

## 8. Seed content pack (all fictional; consistent across both apps)

**Disclaimers.** Names are invented; run a quick trademark and web check before any use outside the prototype. Prices are Kuwait-plausible placeholders anchored to section 1, not market truth. Do not use real brand names (for example the 5-star brand in section 1), royal-family names or titles, or real government hall names.

### 8.1 Naming conventions

- Hotels: brand-style name plus descriptor, AR transliteration primary in Arabic UI: `Aurelia Gulf Hotel` / `فندق أوريليا الخليج`. Ballrooms: evocative Kuwaiti heritage nouns (pearl, majlis, palm, sea): `قاعة الدانة / Danah Ballroom`.
- Independent halls: `قصر X للأفراح` (palace), `قاعة X الكبرى`, `مركز X للمؤتمرات والأفراح`. Suffix `للأفراح` or `للمناسبات`.
- Beach/outdoor: `منتجع`, `عزبة`, `جناح`, `حدائق`. Government: generic `قاعة الأفراح الحكومية، {area}`.
- Rules: Arabic primary; English transliteration with `Al-` and capitals; max about 24 characters on a card (two lines, then truncate); area as a secondary line; no real brands, no royal names, no mosque names, no religious words.
- Luxury level (PRD filter): `فاخر / Prestige`, `راقٍ / Signature`, `كلاسيكي / Classic`. (Do not reuse Silver/Gold/Royal for venues; those are planner tiers.) Plus `قاعة حكومية / Government`.

### 8.2 Tier price ranges (KWD)

| Tier | Typical venue | Ladies' reception | Men's | Min guests | Hall capacity |
|---|---|---|---|---|---|
| Prestige (5-star hotel / resort / villa) | hotels, Messila resort, private estate | 44-55 per guest (weekday to weekend); resort setup flat 1,500; villa flat 4,200-4,800 per night | 30-38 per guest | 150-300 | 300-800 (villa 220) |
| Signature (4-star hotel / premium hall) | Salmiya, Mishref, Jabriya | 27-38 per guest | 20-28 per guest | 200-300 | 400-1,200 |
| Classic (independent hall) | Farwaniya, Jahra, Ahmadi, Qurain | 20-27 per guest, or hall-only flat 1,400-2,800 (weekday lower) | 15-22 per guest | 250-300 | 450-900 |
| Government | Hateen, Sabah Al-Salem | flat 100 (study to double to 200) | same | n/a | 400-500, venue only |

Default deposit 30%; balance 14 days before; outdoor and beach winter-only.

### 8.3 Venue roster (21 venues; Hawalli heaviest)

Distribution by governorate: Hawalli 7, Capital 3, Mubarak Al-Kabeer 3, Ahmadi 3, Farwaniya 3, Jahra 2. Tiers: Prestige 4, Signature 7, Classic 8, Government 2. Each row is a fixture; ratings and review counts are placeholders (new venues may have none).

| ID | English / Arabic name | Type, tier | Area (Governorate) | Halls and capacity | Pricing (KWD) | Rating (n) |
|---|---|---|---|---|---|---|
| V01 | Aurelia Gulf Hotel / فندق أوريليا الخليج | Hotel 5-star, Prestige | Sharq (Capital) | Danah Ballroom قاعة الدانة 650; Majlis Hall قاعة المجلس 350 | Ladies weekday 46 / weekend 52 per guest, min 300 (Danah) / 200 (Majlis); Men 32 per guest, min 300; valet, bridal suite, 1 suite night, show cake, mocktails | 4.8 (212) |
| V02 | Madar Grand Hotel / فندق مدار جراند | Hotel 5-star, Prestige | Bneid Al-Qar (Capital) | Qamar قاعة القمر 800; Nujoum قاعة النجوم 400 | Ladies 44 / 50, min 250 / 150; Men 30 | 4.7 (167) |
| V03 | Nawar Beach Resort / منتجع نوّار الشاطئي | Beach resort, Prestige | Messila (Mubarak Al-Kabeer) | Seaview Hall 300 indoor; Lawn Terrace 450 outdoor | Ladies 49 / 55, min 150; outdoor setup flat 1,500; outdoor Nov-Mar | 4.9 (96) |
| V04 | Bayan Villa Estate / فيلا بيان الخاصة | Private villa, Prestige (VIP) | Bayan (Hawalli) | Garden 160 + Majlis 60 = 220 | Flat 4,200 per night, Thu-Sat 4,800; catering external | 4.9 (41) |
| V05 | Lumi Marina Hotel / فندق لومي مارينا | Hotel 4-star, Signature | Salmiya (Hawalli) | Marina Hall 500; Terrace Room 180 | Ladies 34 / 38, min 200; Men 24 | 4.5 (138) |
| V06 | Rawnaq Events Hotel / فندق رونق للمناسبات | Hotel 4-star, Signature | Shuwaikh (Capital) | Hall 600; Hall 300 | Ladies 31 / 35, min 200; Men 22, min 250 | 4.4 (89) |
| V07 | Jawharat Al-Salmiya Palace / قصر جوهرة السالمية للأفراح | Wedding hall, Signature | Salmiya (Hawalli) | Twin halls: Ladies 700; Men 500; separate entrances | Ladies 29 / 33, min 250; Men 21, min 200; hall-only 3,400 | 4.6 (224) |
| V08 | Wasl Convention and Wedding Centre / مركز وصل للمؤتمرات والأفراح | Convention and halls, Signature | Mishref (Hawalli) | Grand 1,200; Hall A 600; Hall B 450; Men's Majlis 500 | Ladies 27 / 31, min 300; Men 20, min 300; instant booking | 4.3 (158) |
| V09 | Qasr Al-Nakheel / قصر النخيل للأفراح | Wedding hall, Signature | Jabriya (Hawalli) | Ladies 550; Men 400 | Ladies 30 / 34, min 250; hall-only 3,800; weekday offer 28 | 4.6 (131) |
| V10 | Qurain Grand Hall / قاعة القرين الكبرى للأفراح | Wedding hall, Classic | Qurain (Mubarak Al-Kabeer) | Ladies 800; Men 600 | Hall-only 2,600 (weekday 1,800); catering 15-19 per guest | 4.2 (73) |
| V11 | Mahboula Crown Hall / قاعة التاج للأفراح | Wedding hall, Classic | Mahboula (Ahmadi) | Ladies 650; Men 450 | Ladies 24 / 27, min 250 | 4.3 (64) |
| V12 | Khiran Lagoon Estate / عزبة اللاجون | Outdoor and beach, Signature | Khiran (Ahmadi) | Outdoor 300; indoor backup majlis 120 | Flat 3,600, Thu-Sat 4,400; Nov-Mar | 4.7 (38) |
| V13 | Fintas Sea Pavilion / جناح البحر للمناسبات | Outdoor-mixed, Signature | Fintas (Ahmadi) | Pavilion 350 | Ladies 36 / 42, min 150; seasonal | 4.4 (52) |
| V14 | Khaitan Orchard Hall / قاعة بستان خيطان | Wedding hall, Classic | Khaitan (Farwaniya) | Ladies 700; Men 700 | Ladies 20 / 23, min 300; Men 15, min 300 | 4.1 (117) |
| V15 | Rai Grand Ballroom / قاعة الري الكبرى | Wedding hall, Classic | Al-Rai (Farwaniya) | Hall 900 | Hall-only 2,200 (weekday 1,500) | 4.0 (45) |
| V16 | Jleeb Family Hall / قاعة العائلة، جليب الشيوخ | Wedding hall, Classic | Jleeb Al-Shuyoukh (Farwaniya) | Hall 450 | Hall-only 1,400 (weekday 900) | 3.9 (29) |
| V17 | Taima Grand Palace / قصر تيماء الكبير | Wedding hall, Classic | Taima (Jahra) | Ladies 750; Men 500 | Ladies 22 / 25, min 300 | 4.2 (86) |
| V18 | Oyoun Garden Hall / قاعة حدائق العيون | Garden hall, Classic | Oyoun (Jahra) | Garden 400 | Flat 1,900; winter only | 4.0 (22) |
| V19 | Government Wedding Hall, Hateen / قاعة الأفراح الحكومية، حطين | Government | Hateen (Hawalli) | 400, venue only | Flat 100 (policy placeholder) | no reviews |
| V20 | Government Wedding Hall, Sabah Al-Salem / قاعة الأفراح الحكومية، صباح السالم | Government | Sabah Al-Salem (Mubarak Al-Kabeer) | 500, venue only | Flat 100 (policy placeholder) | no reviews |
| V21 | Salwa Pearl Hall / قاعة لؤلؤة سلوى | Wedding hall, Classic | Salwa (Hawalli) | Hall 500 | Hall-only 2,800 (weekday 2,200) | 4.1 (57) |

Worked totals (for card estimates, deposits): V01 ladies weekend 350 x 52 = 18,200.000 (deposit 30% = 5,460.000, balance 12,740.000); V01 ladies weekday 350 x 46 = 16,100.000; V01 men 400 x 32 = 12,800.000; V05 ladies weekend 300 x 38 = 11,400.000; V08 ladies weekday 400 x 27 = 10,800.000; V14 ladies weekend 400 x 23 = 9,200.000.

### 8.4 Package archetypes (AR / EN)

- `الحفل النسائي · أيام الأسبوع` Ladies' Reception, Weekday (Sun-Wed)
- `الحفل النسائي · نهاية الأسبوع` Ladies' Reception, Weekend (Thu-Sat)
- `الحفل النسائي المتكامل` Ladies' Signature Evening (kosha design, zaffa entrance, bridal suite, suite night)
- `الحفل الرجالي` Men's Reception; `غداء الرجال` Men's Lunch (optional whole-lamb rice, `غوزي`)
- `ليلة الزفاف المتكاملة` Full-Night Package (ladies and men, two halls)
- `إيجار القاعة فقط` Hall Only; `ليلة الفيلا` Villa Night; `رسوم الإيجار الحكومية` Government Rental Fee
- Extras with price ranges: bespoke kosha 1,800-6,500; florals 900-4,000; LED screens 350-900; zaffa troupe 350-900; female photographer 450-700; extra hour 250-600; show cake 180-420; bukhoor and oud 120-300; Arabic coffee station 150-350; kids' corner 200-450; extra valet staff 150-400; extra suite night 120-350.
- Policy templates: Flexible / Moderate / Strict (placeholders for cancellation windows).

### 8.5 Planner tiers (the PRD's differentiator)

| Tier | Arabic | One line (AR / EN) | Price (KWD) |
|---|---|---|---|
| Silver | الفضية | `تنسيق يوم الحفل` / Day-of coordination | 650 |
| Gold | الذهبية | `تخطيط وتنسيق` / Planning and styling | 1,900 |
| Royal | الملكية | `تصميم وإنتاج متكامل` / Full design and production | 5,500 |

Visual rule: signal the tier with one, two or three thread marks, not metallic colour coding (stays inside the three-colour palette). Deposit 25%.

### 8.6 Vendor price anchors (Phase 2 marketplace)

Bridal makeup 150-450 (300+ [V]); henna artist 80-250; photography 450-900 (about 600 [V]); videography 400-900; florals 900-4,000; cake 150-600; DJ 250-600; MC 200-500; luxury car 120-400; invitation cards 0.8-6 per card.

### 8.7 People and cross-app story

- **Client persona:** `ريم الدوسري` Reem Al-Dosari (monogram `ر`), wedding **Thu 14 Jan 2027** (63 days from NOW), budget band 20,000-35,000, ladies' guests about 350, men's about 400, preferred areas Salmiya and Sharq. She sends a request to V01 for the ladies' reception: 350 guests, weekend rate, total 18,200.000, deposit 5,460.000.
- **Hotel persona:** reception manager of Aurelia Gulf Hotel (V01); staff roles المدير، الاستقبال، المحاسب، التسويق. Fixed NOW = Thu 12 Nov 2026 16:00 Asia/Kuwait.
- **Hotel Today (V01):** Danah Ballroom, Ladies' reception 9:00 م, 420 guests (420 x 52 = 21,840.000); Majlis Hall, Men's reception 8:30 م, 310 guests (310 x 32 = 9,920.000). November booked value placeholder 214,600.000 across 16 events; deposits this week 21,860.000.
- **Pending requests (hotel app), oldest first:**
  1. ريم الدوسري, Ladies, Thu 14 Jan 2027, 350, 18,200.000, waiting 3h 20m.
  2. فيصل الرشيدي (Faisal Al-Rasheedi), Men's, Fri 22 Jan 2027, 400, 12,800.000, waiting 5h.
  3. مريم الكندري (Maryam Al-Kandari), Ladies, Thu 28 Jan 2027, 300, 15,600.000, waiting 7h.
  4. عبدالله الهاجري (Abdullah Al-Hajri), Full night (ladies 380, men 450), Fri 5 Feb 2027, 34,160.000 (19,760 + 14,400), waiting 9h.
  5. دانة الشمري (Dana Al-Shammari), Ladies, Sun 17 Jan 2027 (weekday), 250, 11,500.000, waiting 21h (close to the 24h SLA).
- Names are common Kuwaiti given names plus broad family names; no royal or prominent-family names. Avatars are single Arabic letters (`ر ف م ع د`).
- **Chat fixture:** Client `السلام عليكم، هل يوم الخميس 14 يناير متاح للحفل النسائي؟ عدد المدعوات تقريباً 350.` / Venue `وعليكم السلام ورحمة الله، هلا فيكم. نعم التاريخ متاح، وتقدرون تثبتونه بعربون 30% خلال 24 ساعة.`
- **Review fixtures:** `قاعة راقية والتنظيم ممتاز. فريق القاعة النسائية كان متعاوناً جداً من لحظة الدخول حتى نهاية الحفل، والبوفيه مرتب ومتنوع.` (4.8, reviewer `نورة ع.`) / "Refined hall, excellent organisation; the ladies' hall team were helpful from arrival to the very end and the buffet was varied and well kept." Critical 3.5: `الموقع ممتاز لكن الدخول للمواقف كان مزدحماً بعد العاشرة، ونتمنى زيادة عدد الموظفين في الفاليه.` Owner reply: `شكراً لكم على ملاحظاتكم القيّمة. تمت زيادة فريق الفاليه في الليالي المزدحمة، ويسعدنا استضافتكم مجدداً.` Rating categories: venue, food, service, value. No photos with people.
- **Offers (hotel app / home):** last-minute Thu 3 Dec 2026 open, ladies' reception 28 per guest at V09; midweek (Sun-Wed) 20% off; early bird 12 months ahead 10%; flash sale 48 hours; coupon code shown Latin and uppercase in both languages (`GHAZAL10`) inside an LTR isolate.
- **Availability fixture (V01):** follow the occupancy pattern in 2.3; Thu 12 Nov fully booked; Ramadan 2027 about 5%; the demo "available this week" list returns Sun-Wed gaps and one Saturday.

---

## 9. Proposed ADRs (to add under `docs/decisions/`) and doc fixes

1. Digits: Western 0-9, pinned numbering system, formatter module (4.1, 4.2).
2. Week start: Sunday, per-country config; Thu-Sat peak band (4.3).
3. Booking model: Venue > Hall > Date > Session > up to two Event Sections; approve-then-pay with timed hold; instant mode pay-at-end (2.1, 2.9).
4. Price units and display: per_guest, per_hall_night, government_fee; estimate for N guests (2.5).
5. Arabic voice: honorific plural `كم`, verbal-noun CTAs, light Khaleeji in warm moments (3).
6. Figures type role: Cairo digits; Arabic size ratio and line-height tokens (6.5).
7. Chart mirroring rule and media/voice-note exceptions (6.1).
8. Cultural content and imagery policy (2.8).
9. Currency, phone, date formats and bidi isolation helper (4, 5).
10. Authority-order reason code and bulk reschedule (2.3).

Doc fixes: `docs/design/00-brief.md` says "tabular figures for prices/dates/stats" and "Sunday-start weeks"; both need the clarifications above. `AGENTS.md` money rule should add "AR `د.ك` after the number with an LTR-isolated number and no trailing period; EN `KD`". `docs/product/00-source-digest.md` gap #11 (numerals) can be marked resolved; gaps #8, #9, #10 now have recommended resolutions pending owner approval.

---

## 10. Items that must go to `docs/product/open-questions.md` (not into the design silently)

Dual-section booking; family contact on a booking; non-wedding event types; government-hall hand-off; Authority-order exception path; expired-request status; guest-count and budget presets wording; extra checklist and budget presets (contract date, henna night, zaffa, favours, mahr and gold); Waze in directions chooser; Hijri secondary line; Instagram link on venue details.

---

## 11. Sources

- 5-star hotel wedding packages, Four Seasons Kuwait: https://www.fourseasons.com/kuwait/weddings/packages/ (extract via search; page blocked)
- Kuwait Times, wedding costs: https://kuwaittimes.com/pandemic-food-price-increases-blamed-for-rising-wedding-costs
- Kuwait Times, weddings downscaled amid ban: https://kuwaittimes.com/article/42231/kuwait/other-news/wedding-celebrations-downscaled-amid-ban/
- Gulf News, lavish and onerous weddings: https://gulfnews.com/amp/story/world%2Fgulf%2Fkuwait%2Fwedding-celebrations-in-kuwait-getting-more-lavish-more-onerous-1.1897167
- Voice of Emirates, weddings resumed 24 Apr 2026: https://www.voiceofemirates.com/en/news/2026/04/24/kuwait-resumes-weddings-and-events-following-improved-security-conditions/
- Emarat Al-Youm, ban 13 Mar 2026: https://www.emaratalyoum.com/politics/news/2026-03-13-1.2024738 and municipality tents 14 Mar: https://www.emaratalyoum.com/politics/news/2026-03-14-1.2025322
- Al-Rai, Social Affairs halls fees study: https://www.alraimedia.com/article/1751855 ; fee doubling debate: https://www.alraimedia.com/article/824007
- DataReportal Kuwait 2026: https://datareportal.com/reports/digital-2026-kuwait ; Ipsos Spotlight Kuwait 2026 (via search)
- StatCounter Kuwait mobile OS: https://gs.statcounter.com/os-market-share/mobile-/kuwait
- CBK Apple Pay launch: https://www.cbk.gov.kw/en/cbk-news/announcements-and-press-releases/press-releases/2022/12/202212080902-launching-apple-pay-service-having-met-all-the-legal-and-regulatory-requirements
- MyFatoorah KNET (Broadleaf docs): https://developer.broadleafcommerce.com/services/myfatoorah/knet ; PayTabs KNET: https://support.paytabs.com/en/support/solutions/articles/60000692059-knet-activation-and-workflow
- Areas of Kuwait: https://en.wikipedia.org/wiki/Areas_of_Kuwait
- Holidays: https://www.calendarlabs.com/holidays/kuwait/2027
- Population (PACI): https://gulfnews.com/world/gulf/kuwait/kuwaits-overall-population-falls-in-early-2025-as-number-of-citizens-rises-1.500270841
- No VAT: https://www.vatupdate.com/2026/07/24/kuwait-keeps-vat-off-the-table-no-adoption-in-the-2026-2030-fiscal-plan/
- RTL guidance (via search extracts): https://m2.material.io/design/usability/bidirectionality.html ; Apple RTL guidance
- Local verification this session: Node 23 Intl/CLDR (ar-KW, ar, ar-AE and Gulf locales, weekInfo, plural rules, Umm al-Qura dates); Dart intl `number_symbols_data.dart`; fontTools on Cairo[slnt,wght].ttf and Poppins-Regular.ttf from google/fonts; libphonenumber-js metadata.

Project files consulted: /Users/youcefs/Desktop/Desktop/ghzal/AGENTS.md, /Users/youcefs/Desktop/Desktop/ghzal/docs/product/00-source-digest.md, /Users/youcefs/Desktop/Desktop/ghzal/docs/design/00-brief.md, /Users/youcefs/Desktop/Desktop/ghzal/project.md, /Users/youcefs/Desktop/Desktop/ghzal/Ghazal_PRD_EN.pdf (pages 9-13). No files were written or modified.