# ADR 0011: Gregorian primary, Hijri secondary, Sunday-first weeks, 12-hour Kuwait time

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-10-12 |
| Scope | All date, time, week and calendar rendering in the client app, hotel app, web prototype, push, WhatsApp, email and PDFs |
| Owner confirmation still needed | OQ-L-03 (Sunday-first, Thu-Sat peak band, 12-hour clock; validate with five venue managers and five couples), OQ-L-04 (who maintains the occasion table; Hijri line in Arabic only), OQ-T-10 (Hijri-dependent holiday pricing source) |
| Related ADRs | 0001 (absolute client time), 0002 (business day and session times), 0004 (day types for pricing), 0008 (hotel calendar), 0010 (digits and numbers), 0013 (idiom guard wording), 0014 (RTL calendar), 0022 (explicit calendar config) |
| Screens | CL-ONBD-04, CL-DISC-02, CL-VENU-03, CL-BOOK-01, CL-WEDD-01, HL-CALN-01..04, HL-TODY-01 |

## Context

NF-LOC-03 (re-sourced as IMPLIED by PDF §12 'dates and numbers'; the PRD never mentions Hijri) proposes 'Gregorian default, Hijri shown where it matters (holidays, Ramadan)'. The PRD does not say where Hijri matters, which week starts the calendar, or which clock. Research found:

- **CLDR** says `ar-KW` weeks start on Saturday (weekend Fri-Sat); Saudi is Sunday-first; the UAE is Monday-first with a Sat-Sun weekend. Intl in Chrome and Dart disagree on defaults, so week start must be explicit configuration. The brief asks for Sunday-start weeks.
- **Kuwait's working week is Sun-Thu**; weddings peak Thursday and Friday nights, Saturday strong, Sun-Wed discounted (domain assumption). With Sunday-first weeks, Thu-Fri-Sat becomes one contiguous 3-column block at the inline-end edge in both languages.
- **Hijri dates move.** Kuwait uses local moon sighting, so Umm al-Qura dates can be off by a day. Holiday pricing depends on them, but the client must not compute them.
- **Idiom trap.** In Arabic, ليلة الجمعة means Thursday night (the Islamic day begins at sunset); colloquial speech also says ليلة الخميس loosely. Never write 'ليلة' plus a weekday.
- **Time zone.** Asia/Kuwait is UTC+3 with no DST; travelling couples and expats must still see Kuwait time for events.
- **A wedding that starts 19:30 and ends 01:00** belongs to its start date (ADR 0002 D2).
- CLDR's single-letter Arabic weekday initials (ح ن ث ر خ ج س) are too cryptic; truncated stems are not words.
- The 2026/27 season: Ramadan 1448 begins about Mon 8 Feb 2027 and swallows National Day (Thu 25 Feb) and Liberation Day (Fri 26 Feb); Eid al-Fitr about 9-11 Mar; Eid al-Adha about 16-19 May. Interior-ministry bans in 2026 show dates can also change by authority order (ADR 0006 D7).

## Decision

**1. Calendar system.** Gregorian is primary everywhere. Hijri is secondary and appears in exactly two places: (a) occasion markers on calendars (Ramadan 1448 as a date range, Eid al-Fitr, Eid al-Adha, Isra and Miraj, Islamic New Year; Ashura is a quiet marker with no commentary; National Day 25 Feb and Liberation Day 26 Feb are Gregorian-fixed); (b) one muted line under the date on the selected-date confirmation and the booking summary in the Arabic UI only, for example `الخميس 14 يناير 2027 · 6 شعبان 1448 هـ`. Never in grids, cards, lists, push or the English UI. Values are Umm al-Qura (ICU `islamic-umalqura`); every marker carries `تقريبي` / `approx.` until the server record is marked announced. The occasion table is server data editable by Super Admin, and venues can edit their own holiday pricing and blocked dates (VD-PRC-03); it is not computed on-device.

**2. Patterns.** Dates are composed from explicit patterns, not ICU defaults.

| Form | Arabic | English |
|---|---|---|
| Full: `weekday d month y`, no comma | `الخميس 14 يناير 2027` | `Thursday 14 January 2027` |
| Short | `الخميس 14 يناير` | `Thu 14 Jan` |
| Compact | `14 يناير 2027` | `14 Jan 2027` |
| Month header | `يناير 2027` | `January 2027` |

The year is omitted only in the short form for dates inside the current year; it is always shown on confirmations, booking detail, invoices, the profile wedding date, month headers and any date in another year. Arabic months use the Gulf names (يناير فبراير مارس أبريل مايو يونيو يوليو أغسطس سبتمبر أكتوبر نوفمبر ديسمبر). Numeric-only dates (12/11/2026) are banned in UI and copy; ISO 8601 appears only inside an LTR isolate in technical or export contexts.

**3. Time.** 12-hour clock, always Asia/Kuwait (UTC+3, no DST; device time zone ignored; where the device zone differs, chat, push and booking detail add `بتوقيت الكويت` / `Kuwait time`). AR `9:00 م` / `9:00 ص`; EN `9:00 PM` (uppercase, regular NBSP; the formatter composes the suffix itself). Ranges: `من 7:00 م إلى 1:00 ص` / `7:00 PM – 1:00 AM`. The event date of a booking is the date its session starts, even when the session ends after midnight. Guest-side deadlines are absolute timestamps (`Expected reply by Sun 15 Nov, 6:00 PM`), never ticking counters. The hotel app may show operational countdowns in compact form: `5 س 20 د` / `5 h 20 m`.

**4. Week and weekend.** Sunday-first through explicit per-country config (`weekStartsOn: 0`, `weekend: [5, 6]`, `peakBand: [4, 5, 6]`), never read from the locale. Thu, Fri and Sat are the last three columns and form one contiguous peak band at the inline-end edge in both languages (left in Arabic), shaded with a Rose-tint wash, not gold. Which days count as weekday, weekend, holiday or season for pricing is venue data (PRD pricing engine, ADR 0004); the peak band is only the visual default. Weekday header: EN `Sun Mon Tue Wed Thu Fri Sat`; AR article-less full words `أحد اثنين ثلاثاء أربعاء خميس جمعة سبت` at the 13px caption token with the full name as accessible label (CLDR single letters are too cryptic and truncated stems are not words). Verify at 360px, where a cell is about 44px.

**5. Components.** Custom calendar and date-sheet components only: no native date inputs and no Material/Cupertino pickers, so digits, week start, the Hijri line and the time zone stay under the formatter. Client: single-date selection, month paging plus a 12-month jump sheet. Hotel: range select. Day states are never colour alone: booked or blocked = struck-through number, held by another request = corner mark, selected = gold fill with deep-ink number, past = 32% ink without strike. Occasion markers are a 2px Gold-ink underline across the date range plus a legend chip `رمضان 1448 (تقريبي)` / `Ramadan 1448 (approx.)`.

**6. Idiom guard.** Never 'ليلة' plus a weekday. Always weekday, date and time: `مساء الخميس 14 يناير`.

**7. Relative words** are used only for `اليوم / Today` and `غدًا / Tomorrow`; everything else is absolute. Countdown uses whole days (`باقي 63 يومًا` / `63 days to go`), never seconds.

**8. Prototype clock.** One clock provider injects NOW = Thu 12 Nov 2026 16:00 Asia/Kuwait in both apps. Occasion seed (Umm al-Qura, verified by running ICU):

| Occasion | Date |
|---|---|
| Isra and Miraj | Tue 5 Jan 2027 |
| Ramadan 1448 | begins Mon 8 Feb 2027, ends about Mon 8 Mar |
| National Day / Liberation Day | Thu 25 Feb / Fri 26 Feb 2027 (inside Ramadan) |
| Eid al-Fitr | about Tue 9 to Thu 11 Mar 2027 |
| Eid al-Adha | about Sun 16 to Wed 19 May 2027 |
| Islamic New Year | about Sun 6 Jun 2027 |
| Ashura | about Tue 15 Jun 2027 (quiet marker) |

## Consequences

- The Thu-Sat peak band is one block in both languages, which makes price tiers legible without colour. Hijri stays useful (occasions) without cluttering scheduling.
- Custom calendars are more Flutter work than `showDatePicker`, and need fixtures for week start, month names and the Hijri line (`GzCalendar`, ADR 0022 E).
- Sunday-first deviates from the CLDR default for Kuwait and must stay a config value (UAE is Monday-first, most Gulf locales Saturday-first, Saudi Sunday-first).
- 12-hour time overrides the 24-hour examples in the competitive-ux research; hotel staff get the same clock as couples.
- Ramadan and Eid dates are approximate until announced; blocked-date logic must be editable and labelled (the hotel Ramadan/Eid shortcuts are adjustable ranges, ADR 0008 D9).
- The API must ship holiday labels with Hijri pairs in pricing calendars; the apps only display them (ADR 0022 E, OQ-T-10).
- Doc follow-up: the brief item 'Sunday-start weeks' gains 'explicit config, Thu-Sat peak band at inline-end'.
- Backend: `event_date` is a DATE in Asia/Kuwait; session times are venue-local TIME ranges; everything else is timestamptz UTC (PL-CORE-11, ADR 0020).

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Saturday-first weeks (CLDR default for `ar-KW`) | Splits the Thu-Fri-Sat peak band across both edges; contradicts the brief |
| Monday-first or locale-driven week start | UAE only; week start must be explicit config, never inferred |
| Hijri as the primary calendar | Kuwait commerce, venues and the PRD run on Gregorian; Hijri is occasion-driven |
| Hijri line on cards, lists, push or English | Clutter; useful only on the Arabic confirmation and booking summary |
| Computing Hijri on the device | Moon sighting makes Umm al-Qura approximate; Super Admin maintains the table |
| 24-hour clock | Couples read `9:00 م`; one clock for couples and staff |
| Device time zone for events | Travelling couples and expats would see the wrong time; Kuwait time always |
| ICU default date patterns | Inconsistent across web and Dart; explicit patterns only |
| Native date pickers | Reintroduce Eastern digits and locale week start; custom components only |
| CLDR narrow weekday letters or truncated stems | Cryptic or not words; full article-less words with accessible labels |
| 'ليلة' plus weekday in copy | Ambiguous idiom (Thursday night) |
| Live second-by-second countdown | Anxiety; whole days and absolute timestamps |

## Related requirement IDs

| ID | Effect |
|---|---|
| NF-LOC-03 | Gregorian default, Hijri where it matters (occasion markers, Arabic summary line) |
| NF-LOC-02, NF-LOC-06 | Mirrored calendars; runtime language switch re-renders dates |
| CA-ONB-03, CA-HOME-02 | Wedding date entry and hero date row |
| CA-VDET-22, CA-BOOK-02 | Availability calendar and date step |
| CA-TOOL-17, CA-TOOL-18 | Countdown in whole days with milestone states |
| HA-CAL-01..03 | Month, week and day views, Sunday-first |
| VD-PRC-03 | Holiday pricing edited by venues and Super Admin |
| PL-CORE-11 | UTC storage, Asia/Kuwait rendering |
| CF-11 | Numerals interplay (ADR 0010) |

## Notes on conflicting inputs

- **Amendment 2026-10-12 (architecture README #6).** Hijri: the API ships the Gregorian-Hijri pair (ADR 0022 says the client never computes it) and the prototype computes it with ICU at noon Kuwait time; the example `6 شعبان 1448` for Thu 14 Jan 2027 is right only at noon (midnight gives 5 Sha'ban). The line is secondary and approximate until announced.
