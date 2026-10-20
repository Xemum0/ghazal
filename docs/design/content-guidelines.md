# Content guidelines (checkable)

> The one place the definition of done (`docs/engineering/definition-of-done.md` B2), ADR 0013 and ADR 0015 mean when they say "the content guidelines". It consolidates rules that already live elsewhere; where a rule has an owner, the owner wins and this page links to it. Created 2026-10-12 by the review pass. Owner of the Arabic words: ADR 0013. Owner of imagery: ADR 0015 (status `proposed-needs-owner`, so the imagery rules are a working assumption).

## 1. Voice

| Rule | Source |
|---|---|
| Arabic is written natively, never translated word for word; clear modern Arabic with light Gulf warmth only in welcomes, success, push and empty states; dialect words only in staff-typed chat | ADR 0013 D1, D2 |
| Honorific plural possessive `كم` (طلبكم، حجزكم، زفافكم، حسابكم); CTAs are verbal nouns, never `اختر / اختاري` | ADR 0013 D2 |
| Outcome first, money status second, next step third; passive and calm; no blame | ADR 0013 D5 |
| English is British, calm, precise; one celebratory line per flow, at confirmation | ADR 0013 D5, glossary section 9 |
| Chip words for statuses are fixed (Pending / بانتظار الرد, Not accepted / لم يُقبل الطلب, ...) | ADR 0013 D4 |
| Plurals use the CLDR categories by last two digits (`350 ضيفًا`, `300 ضيف`) | ADR 0013 D7 |

## 2. Banned in any string, either language

The authoritative table is `docs/product/glossary.md` section 9. In short: exclamation marks and emoji; urgency or scarcity words and counters (`Hurry`, `Only N left`, `Don't miss out`, `2 Thursdays left`); `Welcome back`, `Oops`, `dream wedding`; `Book now` (use `Request to book`); `Rejected` in client UI; `No booking fee` before OQ-B-15; `ليلة` before a weekday, `بالرفاء والبنين`, `حيّاك الله`, `حريمي`, `مدعو / مدعوات`, `عزيزي العميل`, religious phrases in payment, error, legal or discount copy; Silver, Gold or Royal as a venue package name; lorem ipsum; real brands, real royal or government names, real phone numbers.

## 3. Numbers, money, dates (checked by the formatter, not by hand)

Western digits 0-9 in both languages; `KD` in consumer English, `د.ك` after an LTR-isolated number in Arabic, `KWD` only on invoices, bank settings and the API; every price states its unit and guest basis, and the one price grammar is ADR 0004 D6; times are 12-hour with AM/PM (`م` / `ص` in Arabic); weeks start on Sunday; Gregorian first, Hijri only as a secondary line (ADR 0010, ADR 0011).

## 4. Names and seed content

Venue names are at most about 24 characters on a card, never a real brand, never a royal or mosque name; areas come from the picker list; phones are `+965 5000 00NN`, display-only; the shared story, roster, clock and money are in [seed-rulebook.md](seed-rulebook.md).

## 5. Imagery (ADR 0015, working assumption)

No identifiable human faces anywhere: empty halls, details, architecture; avatars are monograms; chat media is private between participants and carries a report action; per-section policy facts (photography allowed, music type) are shown as plain labelled facts, never as judgements.

## 6. How it is checked

Today (before the foundation PR): the author reads the Arabic screenshot and checks strings against this page and glossary section 9. After the foundation PR: `pnpm i18n:check` covers key and placeholder parity, plural categories, Latin letters in Arabic strings, literal digits in prose and the length ratio (ADR 0013 D9); banned phrases are a lint list generated from glossary section 9. A native Kuwaiti reader reviews every Arabic string before visual freeze (OQ-L-06).
