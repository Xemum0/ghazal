# Bilingual policy: language, numerals, dates, money, mirroring

> Status: binding for both apps, the prototype, server-originated messages and PDFs. Source: ADR 0010-0016 (numerals and currency, dates, phone and identifiers, Arabic voice, RTL registry, imagery, typography) plus the localization research. Every rule here is either enforced by a lint or a shared fixture, or listed in the QA checklist at the end. Arabic is a first-class design target: its own sizes, leading and copy, never a mirrored English frame.

## 1. What is pinned

| Topic | Rule |
|---|---|
| Languages | Arabic (RTL) and English (LTR) in all four products (NF-LOC-01). First launch uses the device language if it is `ar` or `en`, otherwise Arabic; asked again in onboarding. Runtime switch with no restart, scroll position and open sheets preserved (NF-LOC-06) |
| Locale tags | Web: `<html lang="ar" dir="rtl">`, `Intl` locale `ar-u-nu-latn` and `en-GB`. **Never** `ar-KW`, `ar-SA`, `ar-EG` (Chrome and Node give Eastern digits for those). Flutter: `Locale('ar')` and `Locale('en')`; `ar_KW` has no intl data |
| Time zone | Always Asia/Kuwait (UTC+3, no DST); the device zone is ignored. `Intl.DateTimeFormat` always receives an explicit `timeZone: 'Asia/Kuwait'` |
| Calendar | Gregorian primary; Sunday-first weeks and the weekend/peak band come from explicit per-country config (`weekStartsOn: 0`, `weekend: [5, 6]`, `peakBand: [4, 5, 6]`), never from the locale |
| Digits | Western 0-9 in both languages, comma thousands, dot decimals. A Settings row switches Arabic UI to Eastern digits (section 3) |
| Currency | KWD, 3 decimals, stored as integer fils; exponent from a per-country table (KWD, BHD, OMR 3; AED, SAR, QAR 2) |
| Content | All user-facing text exists in both languages, including push, WhatsApp, email, invoices and API-driven errors (NF-LOC-07). Venue-authored text requires both languages before publishing; nothing is machine-translated silently |

## 2. One formatter, no exceptions

`GzFormat` in Dart (`ghazal_core`) and the same API in TypeScript (`@ghazal/i18n` for the prototype and dashboards) turn every number, money amount, percent, range, date, time and phone into a string. UI code never calls `toFixed`, `toLocaleString`, `Intl.*` or `NumberFormat` directly (lint). ARB prose contains no literal digits except placeholders. Designers do not hand-type price strings.

Both implementations are tested against one fixture file, `packages/contracts/fixtures/format-cases.json` (input, locale, `digitStyle`, exact expected output including code points). Representative cases (`<LRI>` U+2066, `<PDI>` U+2069, `<NBSP>` U+00A0, `<MINUS>` U+2212):

| Call | Arabic | English |
|---|---|---|
| money 18,200,000 fils, browse | `<LRI>18,200<PDI><NBSP>د.ك` | `KD<NBSP><LRI>18,200<PDI>` |
| money 5,460,000 fils, exact | `<LRI>5,460.000<PDI><NBSP>د.ك` | `KD<NBSP><LRI>5,460.000<PDI>` |
| money -90,000 fils | `<LRI><MINUS>90.000<PDI><NBSP>د.ك` | `KD<NBSP><LRI><MINUS>90.000<PDI>` |
| per guest | `<LRI>46<PDI><NBSP>د.ك للضيف` | `KD<NBSP><LRI>46<PDI> per guest` |
| flat fee, rental | `رسوم الإيجار <LRI>100<PDI><NBSP>د.ك` | `KD<NBSP><LRI>100<PDI> rental fee` |
| estimate | `من <LRI>16,100<PDI><NBSP>د.ك لعدد <LRI>350<PDI> ضيفًا` | `From KD<NBSP><LRI>16,100<PDI> for <LRI>350<PDI> guests` |
| range | `من <LRI>22<PDI> إلى <LRI>52<PDI><NBSP>د.ك` | `KD<NBSP><LRI>22<PDI> – <LRI>52<PDI>` |
| percent | `<LRI>30%<PDI>` | `<LRI>30%<PDI>` |
| phone | `<LRI>+965 5000 0012<PDI>` | same |
| date, full | `الخميس 14 يناير 2027` | `Thursday 14 January 2027` |
| time | `9:00 م` | `9:00 PM` |

The English string is wrapped in isolates too (invisible in a left-to-right line, essential when an English fragment is embedded in Arabic). The estimate row shows a quirk to test: the guest count in the Arabic sentence goes through the ICU plural (section 6), so 350 renders `350 ضيفًا` (category `many`) while 300 renders `300 ضيف` (`other`). The seed text, ADR 0013 D7 and the glossary were corrected on 2026-10-12 to the same rule; the native reviewer confirms (OQ-L-06).

## 3. Digits and numerals

- **Default Western** because KNET, WhatsApp OTP, bank apps and the Civil ID all use them, Eastern 4/5/6/7/9 are easy to misread in money, and Cairo's Western digits are tabular (all 560 units wide) while its Eastern digits are not (250-678).
- **Switch (NF-LOC-04).** `GzFormat` takes `digitStyle: western | easternArabic`; the Eastern mode post-processes the final string (0-9 to ٠-٩, `,` to `٬`, `.` to `٫`), dates and times included: `18,200.000` becomes `١٨٬٢٠٠٫٠٠٠`. The only UI is one Settings row `الأرقام / Digits` with options `0 1 2 3` and `٠ ١ ٢ ٣`, visible only while the UI language is Arabic, stored per account (per device for guests), never asked in onboarding, never inferred from the device locale. With Eastern on, every rendered number converts (charts included) **except** machine-handled identifiers (phone, OTP, IBAN, card last four, coupon, booking and invoice references, URLs) and generated PDFs, which stay Western. One numeral system per screen apart from those exceptions. Design review checks Eastern mode on five screens (home, venue details, booking review, hotel Today, hotel calendar). Aligned columns right-align on the number's edge and accept ragged digits. If the owner drops the switch (OQ-L-01) only the Settings row disappears.
- **Input.** Every numeric, phone, OTP and amount field accepts Eastern-Arabic (U+0660-0669) and Persian (U+06F0-06F9) digits and normalises to ASCII on entry (client `TextInputFormatter`) and on receipt (server). Pasting an Eastern OTP works.
- **Money data.** `amount_fils` integers plus `currency: "KWD"` in analytics and fixtures, `{ fils, currency }` on the API wire ([api-conventions](api-conventions.md)); the server never formats money.

## 4. Money presentation

| Rule | Detail |
|---|---|
| Modes | `browse` (cards, shelves, filters, ranges, offers, budget hero, hotel Today KPIs): integer dinars when fils are zero, otherwise exactly three decimals, never two. `exact` (booking summary, deposit, balance, payment, refund, invoice, hotel booking detail, revenue and payout lists): always three decimals. `axis` (chart ticks only): `18.4K` / `18.4 ألف`. One precision per list, column or summary block |
| Currency token | Arabic `{n}{NBSP}د.ك`, no trailing period (CLDR's `د.ك.` mis-orders against following LTR text). English `KD{NBSP}{n}`. In both languages the currency sits **visually left** of the number (Arabic logical order is number then currency, which RTL renders as `د.ك 47`). `KWD` appears only on invoices and receipts, other legal documents, bank and payout settings, the gateway hand-off and the API. This refines the matrix note NF-LOC-05 (OQ-L-02) |
| Units | A price never appears without its unit or guest basis: `46 د.ك للضيف`, `2,800 د.ك لليلة`, `رسوم الإيجار 100 د.ك`, `الحد الأدنى 200 ضيف`. A bare "From KD X" is forbidden. The formatter owns the template per unit (the Arabic flat-fee template puts the label first) |
| Compaction | Money-critical numbers are never compacted; no `k` outside chart axes |
| Negatives and percent | U+2212 inside the isolate; `30%` with no space, never `٪` |
| Ranges | Arabic uses words (`من 22 إلى 52`), English an en dash with spaces; every number isolated |

## 5. Dates, time, calendars

| Topic | Rule |
|---|---|
| Patterns | Composed explicitly, never ICU defaults (which insert an Arabic comma). Full `weekday d month y`: `الخميس 14 يناير 2027` / `Thursday 14 January 2027`. Short: `الخميس 14 يناير` / `Thu 14 Jan`. Compact: `14 يناير 2027` / `14 Jan 2027`. Month header: `يناير 2027` / `January 2027`. The year is omitted only in the short form inside the current year; always shown on confirmations, booking detail, invoices, month headers and dates in another year |
| Months (Arabic, Gulf names) | يناير فبراير مارس أبريل مايو يونيو يوليو أغسطس سبتمبر أكتوبر نوفمبر ديسمبر |
| Banned | Numeric-only dates (`12/11/2026`) in UI and copy; ISO 8601 only inside an LTR isolate in technical contexts; **"ليلة" plus a weekday** (in Arabic ليلة الجمعة means Thursday night). Use `مساء الخميس 14 يناير` |
| Time | 12-hour: `9:00 م` / `9:00 PM` (uppercase, NBSP); ranges `من 7:00 م إلى 1:00 ص` / `7:00 PM – 1:00 AM`. The formatter composes the suffix itself. Where the device zone differs, chat, push and booking detail add `بتوقيت الكويت` / `Kuwait time`. The event date of a booking is the date its session starts even when the session ends after midnight |
| Deadlines | Guest-side deadlines are absolute (`Expected reply by Fri 13 Nov, 12:40 PM`). Relative words only `اليوم / Today` and `غدًا / Tomorrow`. Countdown uses whole days (`باقي 63 يومًا`). The hotel app may show operational countdowns compactly (`5 س 20 د` / `5 h 20 m`) |
| Week | Sunday first. Headers: EN `Sun Mon Tue Wed Thu Fri Sat`; AR article-less full words `أحد اثنين ثلاثاء أربعاء خميس جمعة سبت` at 13 px with the full name as accessible label. Thu, Fri, Sat are the last three columns and form one contiguous band at the inline-end edge (left in Arabic), washed with Rose tint, not gold. Pricing day types are venue data; the band is only the visual default |
| Hijri | Secondary only, in two places: (a) occasion markers on calendars (Ramadan 1448 as a range, Eid al-Fitr, Eid al-Adha, Isra and Miraj, Islamic New Year; Ashura is a quiet marker with no commentary; National Day 25 Feb and Liberation Day 26 Feb are Gregorian-fixed); (b) one muted line under the date on the selected-date confirmation and the booking summary in the **Arabic UI only**: `الخميس 14 يناير 2027 · 6 شعبان 1448 هـ`. Never in grids, cards, lists, push or the English UI. Umm al-Qura; every marker carries `تقريبي` / `approx.` until the server record is `announced` |
| Components | Custom calendar and date-sheet only (no native date inputs, no Material or Cupertino pickers) so digits, week start, the Hijri line and the time zone stay under the formatter. Day states are never colour alone: unavailable = struck-through number, held = corner mark, selected = gold fill with deep-ink number, past = 32% ink |
| Prototype clock | One clock provider injects NOW = Thu 12 Nov 2026, 16:00 Asia/Kuwait in both apps |
| Seed occasions | Isra and Miraj Tue 5 Jan 2027; Ramadan 1448 starts Mon 8 Feb 2027 (ends about Mon 8 Mar); National Day Thu 25 Feb and Liberation Day Fri 26 Feb fall inside Ramadan; Eid al-Fitr about Tue 9 to Thu 11 Mar; Eid al-Adha about Sun 16 to Wed 19 May; Islamic New Year about Sun 6 Jun; Ashura about Tue 15 Jun |

Where Hijri comes from is an open inconsistency: ADR 0011 says Umm al-Qura through ICU, ADR 0022 says the client never computes Hijri. Working call: the API ships holiday labels and the Hijri pair with pricing calendars and booking snapshots, the apps display them, and the prototype computes the pair with ICU `islamic-umalqura` from the civil date. **Time-zone trap:** 14 Jan 2027 is 6 Sha'ban; building a `Date` at Kuwait midnight and formatting it in another zone gives 5 Sha'ban. Always pass the civil date at noon or an explicit `timeZone: 'Asia/Kuwait'`.

## 6. Language and voice

| Topic | Arabic | English |
|---|---|---|
| Register | Clear modern Arabic with Gulf warmth. Labels, buttons, legal, payment and errors are simplified MSA. Light Khaleeji only in welcomes, success, push, empty states and staff chat: هلا، يا هلا والله، ما قصّرتوا، تفضلوا، على راحتكم، مبروك مقدمًا، الله يبارك لكم. Never in labels: شنو، وين، شلون، زين، الحين، جذي، تبي | British spelling, second person, sentence case, warm, precise, calm |
| Address | Honorific plural possessive `كم` (طلبكم، حجزكم، موعدكم، زفافكم). CTAs are verbal nouns (متابعة، إرسال الطلب، تأكيد الحجز، اختيار التاريخ، مقارنة); never `اختر / اختاري`. Plural imperatives (جرّبوا، راجعوا) only in notifications and empty states. No honorifics (سمو، الشيخ). Greeting once, on Home only: `أهلاً وسهلاً، ريم` | `Hello, Reem`, never "Welcome back" |
| Message anatomy | Outcome first, money status second, next step third, passive and calm: `تعذّر إتمام الدفع. لم يُخصم أي مبلغ.` One celebratory line per flow, at confirmation: `مبروك مقدمًا، تم تأكيد حجزكم.` | `The payment could not be completed. No amount was charged.` |
| Never | Exclamation marks, emoji, urgency (Hurry, Only N left, Don't miss out), blaming the user, religious phrases in payment, error, legal or discount text, `بالرفاء والبنين`, `حيّاك الله`, `حريمي`, `مدعو / مدعوات`, `عزيزي العميل` | Oops, dream wedding, Welcome back |
| Punctuation | `،` `؛` `؟` and `« »`; Latin comma only inside numbers; NBSP between a number and its unit; no tatweel; no tashkeel except the fathatan (ـًا, written before the alef: يومًا) and shadda in glossary words; Latin brand names are transliterated in the Arabic UI (`فندق أوريليا الخليج`) | |
| Brand and names | Wordmark `غزل` in the Arabic UI, `Ghazal` in English. Venue names show the Arabic name in the Arabic UI and the English name in English | |

**Glossary** (canonical; synonyms are search aliases only; full list in `docs/research/kuwait-localization.md` 3.3): الحفل النسائي Ladies' reception, الحفل الرجالي Men's reception, مختلط Mixed (last, never default), الكوشة Kosha, الزفّة Zaffa, جناح العروس Bridal suite, العربون Deposit, المبلغ المتبقي Remaining balance, الباقة Package, الإضافات Extras, طلب حجز Request to book, متاح / محجوز / غير متاح, حجز فوري Instant booking, المفضلة Saved, مقارنة Compare, تنسيق الأعراس Wedding planning, الفضية / الذهبية / الملكية (planner tiers only), قبول / اعتذار / تغيير الموعد Accept / Decline / Reschedule, تواريخ مغلقة Blocked dates. **Guests are `ضيف / ضيوف` everywhere** (`عدد الضيوف`, `للضيف`); `مدعو` is a search alias. Client-facing "not accepted" is `لم يُقبل الطلب`; the hotel button is `اعتذار`.

**Plurals.** ICU categories for `ar` follow CLDR on the last two digits, not on magnitude: `zero` n = 0; `one` n = 1; `two` n = 2; `few` n mod 100 in 3-10; `many` n mod 100 in 11-99; `other` everything else (100, 101, 102, 200, 300, 400, 1,000). So 103 is few, 111 is many, **350 and 650 are many** (`350 ضيفًا`) while **300 and 400 are other** (`300 ضيف`). Every plural message supplies `one`, `two`, `few`, `many`, `other` and `zero` as `لا {noun}`. After a preposition the dual becomes `-ين` (`خلال يومين`), so those strings are explicit variants. Prefer `label: value` (`عدد الضيوف: 350`) where a count is not the headline. Seed text was regenerated through this rule (`350 ضيفًا`); the Kuwaiti reader confirms it (OQ-L-06).

Authoring: copy is written natively in each language, never machine-translated or mirrored word for word. Keys are camelCase `<feature><Screen><Element>`. The English ARB part carries descriptions and placeholder metadata; the Arabic part only strings. Compare-table cells budget 14 characters in English and 12 in Arabic.

## 7. Typography per script (ADR 0016)

| Role | English (Poppins, Cairo fallback) | Arabic (Cairo only) |
|---|---|---|
| caption | 12/16 | 13/20 |
| small | 14/20 | 15/24 |
| body | 16/24 | 17/28 |
| title-3 | 20/28 | 22/32 |
| title-2 | 24/32 | 26/36 |
| title-1 | 32/40 | 35/48 |
| display-2 / display-1 | 40/48, 48/56 | 44/60, 52/68 |

Static self-hosted subsets only (Cairo 400/500/600/700, Poppins 400/500/600), no runtime font fetching. **Figures role:** prices, KPIs, calendar cells, times, counters, ratings, table cells and step counters use Cairo's Western digits in both languages; English figures are 1.09 times the neighbouring Poppins size rounded to whole pixels (14 to 15, 16 to 17, 20 to 22, 24 to 26, 32 to 35); Arabic figures equal the text size. Arabic: letter-spacing 0, no italics or synthetic bold, no uppercase transform, no justification, no hyphenation, explicit pixel line heights (body 1.65-1.75, headings at least 1.35). Minimums: 12 px English, 13 px Arabic. Text scales to 200% with reflow; display roles clamp at 1.2. Gold is never a text colour.

## 8. Mirroring

**Layout.** Logical properties only (`margin-inline-start`, `inset-inline-end`, `text-align: start`; Flutter `EdgeInsetsDirectional`, `PositionedDirectional`, `AlignmentDirectional`). No physical left/right and no hard-coded sign in animations: a `--dir: 1 | -1` multiplier drives all horizontal motion. Tabs and bottom navigation mirror (first tab at the right). Back is a chevron at the inline-start. Push enters from inline-end. In two-button rows the primary sits at the inline-end (left in Arabic). Bottom sheets drag vertically only; title at inline-start, close at inline-end, handle centred. Horizontal shelves start at inline-start with the peeking card at inline-end. Counters read `1 من 6` / `1 of 6` with LTR digits.

**Icon registry.** Every icon carries a `mirror` flag; an icon without one fails lint; Flutter uses `matchTextDirection` from the same registry.

| Mirror | Never mirror |
|---|---|
| Back and forward chevrons and arrows (back points right in Arabic), list-row disclosure chevrons, next and previous, send, reply, forward, undo and redo, external link, sign-in and sign-out, text-line glyphs (list, sort, notes, menu), help `?` (renders `؟`), switches (on = knob toward inline-end), segmented controls, tab and bottom-nav order, steppers and breadcrumbs, linear progress, sliders (min at inline-start), calendar grids and month arrows, rating-star row fill, page indicators, carousels | Play, pause, skip, rewind and every audio or video scrubber; clocks, timers, circular refresh and circular progress; check, plus, minus, close; calendar glyph; phone handset; camera, image, microphone; magnifier; location pin, compass, map; heart, star, bookmark, bell; share (box with up arrow); filter funnel and settings sliders; chart-type icons and trend arrows (up means more); digits and Latin text; photos, maps, logos, QR codes |

**Gestures.** No swipe-to-reveal row actions in v1 (ambiguous when mirrored, inaccessible): every action has a visible control or a long-press menu, and the hotel request card has none. iOS edge back-swipe starts at the right edge in Arabic (system behaviour, never overridden). Galleries start with the first image at the right and advance with a leftward swipe. Hotel calendar range select (long-press then drag, with a tap-to-select mode for accessibility) mirrors with the week.

**Charts and time axes (recorded exception).** Time and ordinal axes run in reading direction, so earlier-to-later is right-to-left in Arabic, matching the mirrored calendar, week strip, stepper and timeline in the same product (NF-LOC-02 breaks the tie between Apple and Material guidance). The value axis never flips; y labels sit at the inline-start edge; horizontal bars grow from inline-start; every chart labels its first and last date and has a table twin; digits stay Western and LTR. To be validated with five Kuwaiti users (OQ-L-05).

**Media and chat.** Voice-note layout mirrors (play at inline-start, duration at inline-end) but the play triangle never flips; full-screen video keeps an LTR scrubber. Own bubbles align to inline-end (left in Arabic) and the tail follows. Message text sits in a `dir="auto"` container.

## 9. Identifiers, names, addresses, search

| Topic | Rule |
|---|---|
| Phone | Store E.164 (`+96551234567`). Fixed non-interactive `+965` chip in the MVP. Loose shape check `^(?:[2569]\d{7}\|41\d{6})$` plus `isPossible`, never libphonenumber `isValid` (it rejects real Kuwaiti numbers); WhatsApp OTP delivery is the real validation. Display `+965 5123 4567` (4+4, own formatter) in an LTR isolate. One compound field, LTR order in both languages, numeric keypad, value aligned to the start edge by a direction variable. `tel:+965XXXXXXXX`, `https://wa.me/965XXXXXXXX` (digits only). Prototype phones are patterned `+965 5000 00NN`, display-only, never tappable |
| LTR-data fields | Phone, email, OTP, IBAN, coupon code, URL, booking and invoice reference: `dir="ltr"`, correct `inputmode` and `autocomplete`. OTP is six boxes in LTR order in both languages, with paste and one-time-code autofill, 60 s resend. Coupon codes are Latin uppercase. IBAN is uppercase, grouped by 4, mod-97 validated, masked except the last four, re-authentication to edit |
| Names | One `الاسم الكامل / Full name` field, `dir="auto"`, Arabic or Latin, no first/last split. Monogram = first letter of the name in its own script (ignoring `ال`), an Arabic letter in its isolated form, never a connected pair |
| Address | Area (mandatory), Block (قطعة), Street (شارع), optional Avenue (جادة), House or Building (منزل / قسيمة), Floor, Flat. Venues show `Area · Block · Street` plus a map pin; no PACI number; directions offer Google Maps, Apple Maps (iOS) and Waze. Phase 2 vendors may take the PACI address number, labelled `الرقم الآلي للعنوان (PACI)`. Civil ID is not collected |
| Areas | Six governorates (العاصمة، حولي، الفروانية، الأحمدي، الجهراء، مبارك الكبير), searchable, multi-select, canonical names from Super Admin area data (SA-AREA-01) with a search-only alias table (Mishref = مشرف / Mishrif / Meshref; Bneid Al-Qar = بنيد القار / Bnaid Al-Gar; Salmiya = السالمية / Salmiyah; "Kuwait City" maps to the Capital areas) |
| Arabic search normalisation | Strip tashkeel and tatweel; unify أ إ آ to ا; ى to ي; optional ة to ه; optional ال; Eastern to Western digits; Latin case-fold. Server `name_norm` columns with trigram GIN; the client applies the same function to the query |
| Guests and budget | Guest count is a stepper plus presets (100, 150, 200, 300, 400, 500, 650, 800, 1,000+; cap 1,500). Budget bands: under 5,000, 5,000-10,000, 10,000-20,000, 20,000-35,000, 35,000+, labelled `ميزانية القاعة والضيافة` / `Venue and catering budget` |
| Share text | Image, name in the UI language, area, the "From" price with its basis, and a link; no emoji |

## 10. Bidi pitfalls

| Pitfall | Example | Fix |
|---|---|---|
| Phone inside an Arabic sentence scrambles | `+965 5123 4567` | LTR isolate via the formatter |
| Minus, plus, percent flip sides | `-50.000`, `+15%` | Whole token isolated; U+2212; `15%` |
| Ranges reorder | `1,200 - 2,500` | Arabic words, English en dash, each number isolated |
| Latin brand in Arabic text | `فندق Aurelia` | Use the Arabic transliteration; isolate any remaining Latin run; never end a sentence on it |
| Rating concatenated | `4.8 (125)` | Star, number, count as separate layout items |
| Ellipsis cuts through a number | truncated price | Never truncate through an isolate; names get two lines first |
| Eastern digits creep in | `ar-KW`, native date or number inputs | Pinned locale; custom components; screenshot grep in Arabic |
| Currency with trailing period | `د.ك.` | No period |
| Digits look small beside Arabic | Poppins fallback digits | Figures role in Cairo |
| Time-zone day shift | Hijri 5 vs 6 Sha'ban | Civil date at noon or explicit `timeZone` |
| Hand-written plural | `350 ضيف` | ICU plural with all five categories |
| Mirrored what must not mirror | play, clock, check, photos, maps | Icon registry flag |

## 11. Server-originated and runtime behaviour

- Push, WhatsApp templates, email and invoice PDFs are rendered **server-side in the user's saved locale** from `packages/i18n/messages/server`; the API sends `data.link` HTTPS links and error `code`s, never prose. PDFs and WhatsApp templates use Western digits and `KWD` on invoices.
- Notification timing is not a language rule but travels with the locale: marketing never between 22:00 and 09:00, at most two per week, none in the last 7 days (ADR 0007); transactional pushes are silent between 23:00 and 08:00 (ADR 0015); no marketing push Fridays 11:30-13:00; in Ramadan marketing moves to after Maghrib. The two quiet-hour values differ between ADRs and are config until OQ-L-15 is answered.
- Switching language rebuilds the theme (typography differs per script), flips direction at once, re-renders formatter output, preserves scroll and open sheets where possible, and persists per account.
- Native strings: `ar.lproj` and `en.lproj` `InfoPlist.strings` (Face ID, location, camera, photos, microphone), `CFBundleLocalizations`, Android `locales_config.xml`.

## 12. Enforcement and QA

- **Lint (CI `i18n:check`):** identical key and placeholder sets in both languages; every Arabic plural has all five categories; no Latin letters in Arabic strings outside an allow-list (KD, KWD, brand names, codes); no literal digits in prose; warn when `len(ar) / len(en) > 1.6`; no `Text('literal')`; the Dart guardrail bans `EdgeInsets.only(left|right`, `Alignment.centerLeft|centerRight`, `Positioned(left|right`, `TextAlign.left|right`.
- **Tests:** shared fixtures for the formatter (both codebases), plural cases, phone and IBAN validators, digit normaliser, search normaliser. Goldens run both locales at 360, 390, 430 and text scales 1.0 and 2.0; Arabic at 360 with 2.0 is mandatory ([design-to-code](design-to-code.md)).
- **Every screen, both languages, three widths:** (1) mirror registry respected; (2) no physical left/right, no hard-coded sign; (3) numbers, prices, phones, dates and Latin runs isolated and unscrambled; (4) currency visually left of the number, one precision per column; (5) Arabic sizes and leading per section 7, no clipped descenders, no letter-spacing; (6) LTR fields behave (phone compound, OTP order, caret); (7) calendar: Sunday at inline-start, Thursday-Saturday band at inline-end, month arrows correct; (8) tabs, stepper, slider, progress and star fill mirror; (9) photos, maps, logos not mirrored, no people in imagery; (10) no Eastern digits unless the Settings switch is on; (11) every Arabic string read by a native Kuwaiti reviewer before visual freeze (OQ-L-06).

Next: [security-privacy](security-privacy.md).
