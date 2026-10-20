# ADR 0010: Western digits by default, KWD money rules, one shared formatter

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-10-12 |
| Scope | Every number, price, percentage, count, date and phone rendered by the client app, the hotel app and the web prototype; server-rendered PDFs and notifications |
| Owner confirmation still needed | OQ-L-01 (ship the Settings digit switch in the MVP), OQ-L-02 (KD in consumer English, KWD on documents), OQ-T-11 (switch visibility and server-side text) |
| Resolves | PRD gap 11 (numerals), PRD gap 12 (currency), conflicts CF-11 and CF-12; refines the CF-12 note that said 'KWD' in English |
| Related ADRs | 0004 (price grammar and precision), 0011 (dates and times), 0012 (phone and OTP), 0013 (copy rules), 0014 (bidi isolation), 0016 (figures role), 0022 (Dart module), 0024 (prototype handoff), 0025 (fixtures) |

## Context

The PRD (PDF §12) says only 'mirrored layouts, dates and numbers': it names no digit set and no switch. The matrix lines NF-LOC-03 and NF-LOC-04 were re-sourced on 2026-10-12 as IMPLIED with GAP notes; the switchable digit set is this design phase's proposal, not literal PRD text. NF-LOC-05 requires 'Kuwaiti dinar with three decimals through one shared formatter'. The PRD does not choose a default (CF-11) or a format (CF-12). Measured facts decide it:

- **Web and Dart disagree.** Chrome Intl formats `ar-KW` and every Gulf locale except the UAE with Eastern Arabic-Indic digits (`‏٤٧٫٠٠٠ د.ك.‏`), Saturday-first weeks and a trailing-period currency symbol with RLM marks. Dart/Flutter `intl` has only `ar`, `ar_DZ` and `ar_EG`; `ar` and `Locale('ar','KW')` yield Western digits. A prototype using `lang="ar-KW"` or native inputs silently shows Eastern digits.
- **Safety.** The KNET page, WhatsApp OTP, civil-ID and bank apps use Western digits; the Eastern forms of 4, 5, 6, 7 and 9 are easy to misread in money.
- **Type.** Cairo's Western digits are tabular (every advance is 560 units); its Arabic-Indic digits are proportional (250-678 units; the zero is a 250-unit dot). Poppins has no `tnum` feature and no Arabic-Indic digits (ADR 0016).
- **Bidi.** Numbers, minus, percent, ranges and Latin runs scramble inside Arabic strings unless isolated; the currency symbol with a trailing period mis-orders against following LTR text.
- **Money.** KWD has 1,000 fils; the smallest coin is 5 fils; seed prices use multiples of 0.500. Kuwait has no VAT.
- **GCC later.** UAE, Saudi, Qatar, Bahrain and Oman differ in digits, week start, currency exponent (KWD/BHD/OMR 3, AED/SAR/QAR 2) and phone rules, so everything must be per-country configuration.

## Decision

**1. Digits.** Western 0-9 in both languages for every number the apps render (prices, dates, times, counts, ratings, calendar cells, countdown, KPIs, phones, OTP). Separators are comma for thousands and dot for decimals in both languages. The locale is pinned, never inherited: web uses `<html lang="ar" dir="rtl">` with Intl locale `ar-u-nu-latn` (never `ar-KW`, `ar-SA`, `ar-EG`); Flutter uses locale `ar` (no `ar_KW` data exists).

**2. Switch (an owner-approvable proposal under NF-LOC-04, which is IMPLIED by 'numbers' in PDF §12; OQ-L-01).** The formatter takes `digitStyle: western | easternArabic`; `easternArabic` post-processes the formatted string (0-9 to ٠-٩, `,` to ٬, `.` to ٫). Default is western. The only UI is one Settings row `الأرقام / Digits` with options `0 1 2 3` and `٠ ١ ٢ ٣` (the one place both sets appear together), visible only while the UI language is Arabic, stored per account (guests: per device). It is never asked in onboarding and never inferred from the device locale. When Eastern is on, every rendered number converts (charts included) except machine-handled identifiers (phone, OTP, IBAN, card last-4, coupon, booking and invoice references, URLs) and generated PDFs (invoice, receipt), which stay Western. One numeral system per screen apart from those exceptions. Cairo's Eastern digits are not tabular, so aligned columns right-align on the number's edge and accept ragged digits; design review checks Eastern mode on five screens (home, venue details, booking review, hotel Today, hotel calendar), not on all.

**3. Input.** Every numeric, phone, OTP and amount input accepts Eastern-Arabic and Persian digits and normalises to Western on entry (client) and on receipt (server).

**4. One formatter.** Each codebase has exactly one module (`GzFormat` in Dart `ghazal_core`; the same API in the TS prototype) that turns numbers, money, percent, ranges, counts, dates, times and phones into strings. Both are tested against one shared fixture file `format-cases.json` (input, locale, digitStyle, exact output including code points). UI code never calls `toFixed`, `toLocaleString`, `Intl.*` or `NumberFormat` directly (lint). ARB prose contains no literal digits except placeholders. Designers do not hand-type price strings in mocks.

**5. Bidi safety.** Every numeric token the formatter returns is wrapped in an LTR isolate (U+2066 to U+2069; `<bdi dir="ltr">` in HTML). ICU's LRM/ALM/RLM marks are stripped. Negatives use U+2212 inside the isolate. Percent is `30%` (no space, never ٪). Ranges are words in Arabic (`من 22 إلى 52`) and an en dash with spaces in English, each number isolated. NBSP (U+00A0) sits between a number and its unit or currency. Rating, star and count are separate layout items, never one concatenated string.

**6. Money data.** Amounts are integers in fils (`amount_fils`) plus ISO `currency: "KWD"` everywhere (API, analytics, fixtures). No floats. Totals are computed on the server; the client only formats. The exponent comes from a per-country table (KWD/BHD/OMR 3, AED/SAR/QAR 2) so GCC expansion is configuration, not a rewrite.

**7. Currency string.** Arabic is `{n}{NBSP}د.ك` with no trailing period; English is `KD{NBSP}{n}`. In both languages the currency sits visually to the left of the number (Arabic logical order is number then currency, which RTL renders as `د.ك 47`). Mocks go through the formatter so nobody draws it by eye. `KWD` appears only on invoices and receipts, other generated legal documents, bank and payout settings, the gateway hand-off and the API. Consumer English uses `KD`, which is how Kuwait writes prices; this refines the CF-12 note that said KWD in English.

**8. Precision modes.**

| Mode | Where | Rule |
|---|---|---|
| `browse` | cards, shelves, filters, ranges, offers, budget manager hero and category totals, hotel Today KPIs | integer dinars when fils are zero, otherwise exactly three decimals, never two |
| `exact` | booking summary, deposit, balance, payment, refund, invoice, hotel booking detail, revenue and payout lists | always three decimals (`18,200.000`) |
| `axis` | chart ticks only | compact `18.4K` / `18.4 ألف` |

One precision per list, column or summary block: if any value in the set has fils, every value in it shows three decimals.

**9. Units and honesty.** A price never appears without its unit: `46 د.ك للضيف` / `KD 46 per guest`, `2,800 د.ك لليلة` / `KD 2,800 per night`, `رسوم الإيجار 100 د.ك` / `KD 100 rental fee` (the Arabic template puts the label first for flat fees; the formatter owns the template per unit); minimum `الحد الأدنى 200 ضيف` / `Minimum 200 guests`; estimate `من 16,100 د.ك لعدد 350 ضيفًا` / `From KD 16,100 for 350 guests`. A bare 'From KD X' with no unit or guest basis is forbidden. Kuwait has no VAT, so no tax lines; a service-charge line appears only when the venue declares one. Money-critical numbers are never compacted.

**Reference outputs** (the formatter is authoritative; these illustrate shape).

| Input | Arabic UI | English UI |
|---|---|---|
| 18,200,000 fils, browse | `18,200 د.ك` (number isolated, NBSP before د.ك) | `KD 18,200` |
| 5,460,000 fils, exact | `5,460.000 د.ك` | `KD 5,460.000` |
| 18,500 fils, browse | `18.500 د.ك` | `KD 18.500` |
| 46,000 fils per guest | `46 د.ك للضيف` | `KD 46 per guest` |
| range 22,000-52,000 fils | `من 22 إلى 52 د.ك` | `KD 22 – 52` |
| 30 percent | `30%` | `30%` |
| 350 guests | `350 ضيفًا` | `350 guests` |
| -50,000 fils, exact | `−50.000 د.ك` (U+2212 inside the isolate) | `KD −50.000` (U+2212 inside the isolate) |

## Consequences

- The web prototype and Flutter produce identical strings; digit leaks and bidi scrambles are caught by fixtures instead of screenshots. Money is exact (integer fils).
- Eastern mode adds QA surface and a known tabular-figure limitation. If the owner drops the switch (OQ-L-01) the formatter keeps the parameter and only the Settings row disappears.
- Designers must request new price shapes from the formatter owner instead of improvising.
- English consumer surfaces say KD while generated documents say KWD; both are allow-listed in the i18n lint (ADR 0013 item 9).
- Doc follow-ups: AGENTS.md money rule should add 'AR د.ك after an LTR-isolated number, no trailing period; EN KD'; digest gaps 11 and 12 can be marked resolved.
- Current repo state: `design/scripts/snap.mjs` launches Playwright with locale `ar-KW`; it must change to `ar` (ADR 0022 E, ADR 0025 item 6).
- Server-originated text (push, WhatsApp, email) and PDFs follow the user's saved locale and digit style except identifiers and PDFs (item 2).
- The `format-cases.json` fixture lives in `packages/contracts/fixtures/` and is asserted by both Vitest and `flutter test` (ADR 0025 item 4).

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Eastern Arabic-Indic digits by default | Misread-prone in money; not tabular in Cairo; disagrees with KNET, WhatsApp OTP and bank apps |
| Inherit the device or `ar-KW` locale | Web shows Eastern digits and a trailing-period currency with RLM marks; Dart shows Western; the two would drift |
| Native `Intl`/`NumberFormat` calls in UI code | Scatters digit and bidi decisions; replaced by one linted module |
| No user-facing digit switch | The PRD does not literally require one (NF-LOC-04 is IMPLIED); the row is cheap, defaults to Western and the owner may drop it (OQ-L-01) |
| Ask for the digit style in onboarding | Adds friction for a rare preference; one Settings row, Arabic UI only |
| `KWD` in consumer English | Kuwait writes `KD`; `KWD` stays on legal and technical surfaces |
| CLDR `د.ك.` with RLM and ALM marks | Trailing period mis-orders against LTR text; marks are stripped |
| Floating-point amounts | Rounding errors; integer fils only |
| Compact 'k' notation for prices | Unfamiliar and fragile in bidi; allowed only on chart axes |
| Poppins digits for aligned columns | Proportional and without `tnum`; the figures role in Cairo (ADR 0016) |

## Related requirement IDs

| ID | Effect |
|---|---|
| NF-LOC-04 | Digit switch (Settings row, formatter parameter) |
| NF-LOC-05 | Money through one shared formatter, three decimals |
| NF-LOC-02, NF-LOC-03, NF-LOC-07 | Mirroring and bidi safety; dates (ADR 0011); server-originated text |
| CA-CARD-05, CA-BOOK-09, CA-BOOK-13 | Card price, Review amounts, invoices |
| HA-DASH-02, HA-ANLY-04, HA-BOOK-09 | Revenue and payment amounts in the hotel app |
| PL-CORE-07 | Generated PDFs stay Western and say KWD |
| CF-11, CF-12 | Resolved here |

## Notes on conflicting inputs

- **Amendment 2026-10-12 (architecture README #3).** Money wire shape is layered: database columns `*_fils`, the API `Money` object `{ fils, currency }` (ADR 0020, 0027), analytics properties flat (`amount_fils`, `currency`). One concept, three spellings by layer.
