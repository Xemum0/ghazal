# @gz/i18n

Messages (ICU MessageFormat JSON), the one formatter (`GzFormat`) and the i18n lint. Owner: i18n-owner. The React binding lives in `design/src/i18n`.

Rules this package implements: ADR 0010 (digits, money), 0011 (dates, week, time), 0012 (phone), 0013 (Arabic voice, plurals, lint), 0014 (bidi), 0024 D7 (key names).

## Messages

```
messages/<lang>/<namespace>.json      lang = en | ar; the two trees mirror each other exactly
messages/allow.json                   per-key lint exceptions (keep it nearly empty; give a reason)
templates/namespace.{en,ar}.json      what `new-namespace.mjs` copies
src/generated/namespaces.ts           GENERATED: namespace list + key types from the English JSON
```

Namespaces today: `common` (shared words), `client-shell`, `hotel-shell`. A screen agent adds `<app>-<flow>` (`client-booking`, `client-discover`, `hotel-bookings`, `server`):

```
node packages/i18n/scripts/new-namespace.mjs client-booking     # creates en + ar files, regenerates the types
pnpm i18n:check                                                  # must pass before you hand work back
```

Delete the five example keys the template creates, then write yours. Edit only your own namespace files; if you add or remove a file run `pnpm i18n:check --write` (it regenerates `src/generated/namespaces.ts`, which is the one generated file everyone shares).

### Format of a file

Flat object, key to string. No nesting, no dots.

```json
{
  "clientBookingReviewTitle": "Review your request",
  "clientBookingReviewGuests": "{count, plural, =0{No guests} one{# guest} other{# guests}}",
  "clientBookingReviewDeadline": "Pay by {deadline}",
  "clientBookingReviewPolicy": "Read the <link>cancellation policy</link> first."
}
```

**Keys** are camelCase `<feature><Screen><Element>` and start with the camelCase namespace (`client-booking` becomes `clientBooking`), so a key is unique across the app and `t('typo')` fails type-checking.

**Voice** (ADR 0013, the lint enforces what it can): Arabic is written natively in simplified MSA with the honorific plural `كم`; CTAs are verbal nouns (`متابعة`, never `اختر`); outcome, money status, next step; no exclamation marks, emoji or urgency; British English; one celebratory line per flow.

**Numbers and plurals.** Never type a digit in prose. Use `#` inside a plural or `{n, number}` anywhere else: both print through the Ghazal formatter (Western digits, comma grouping, an LTR isolate in Arabic, the Eastern switch). A bare `{count}` inside its own plural is an error (it prints an unformatted number). Arabic plurals supply `=0` (or `zero`), `=1`, `=2`, `few`, `many`, `other`; English supplies `=0` (optional), `one`, `other`. The dual after a preposition is `-ين` (`خلال يومين`), so write that as its own `=2` variant.

**Money, dates, times, phones are never formatted in a message.** Pass the finished string from `useFormat()`: `t('clientBookingReviewDeadline', { deadline: f.dateTime(payBy) })`. `{x, date}`, `{x, time}` and `{x, number, ::currency/KWD}` are errors.

**Rich text** uses tags, and the component supplies what each tag is: `<T ns="client-booking" k="clientBookingReviewPolicy" components={{ link: c => <a href="…">{c}</a> }} />`. The string, not the component, decides word order in each language.

**Latin in Arabic.** Arabic strings take no Latin letters except `Ghazal`, `VIP`, `IBAN`, `PACI`, `KNET`, `PDF`; `KD` and `KWD` are never allowed (write `د.ك` after the formatted number, which the formatter does). English strings take no Arabic script. Language names are the exception and live in code: `LANGUAGE_NATIVE_NAME`.

### `pnpm i18n:check`

Fails when a key exists in one language only; a namespace in one language only; ICU syntax is invalid; placeholder (and tag) sets differ; a plural lacks a required category for its language; a string holds a raw colour (`#fff`, `rgb(`), hard-coded left/right wording (`left`, `right`, `يمين`, `يسار`), Latin letters in Arabic (or KD/KWD), Arabic in English, a literal digit, `!`, emoji, a banned phrase from `docs/product/glossary.md` section 9 (`Book now`, `Rejected`, `ليلة` plus a weekday, `اختر`, `مدعو`, dialect words in labels, religious phrases in error/payment/legal copy), Latin `?` `;` `,` or tatweel in Arabic; a key is not camelCase or lacks the namespace prefix; or the generated file is stale. Warnings (do not fail): tanween written alef-first, straight apostrophes, Arabic more than 1.6 times the English length. `--write` regenerates the generated file. Rules live in `scripts/lib/check-lib.mjs` and are tested in `test/check.test.ts`.

## Formatter

```ts
import { createFormat } from '@gz/i18n'
const f = createFormat({ lang: 'ar', digitStyle: 'western', now })   // in the Studio: useFormat()
```

Pure functions bound to a language, a digit style (Arabic only; the Settings switch, default western), a country config (`KUWAIT`: UTC+3, Sunday-first, weekend Fri-Sat, peak band Thu-Sat, KWD with 3 decimals, +965) and an injected clock. UI code never calls `toFixed`, `toLocaleString` or `Intl.*`.

| Area | Functions |
|---|---|
| Money (input is integer fils) | `money(fils, {mode: browse\|exact, label: consumer\|legal, currency})`, `moneyParts` (integer, fraction, `fractionIsZero`, currency: for the quiet `.000`), `moneySet` (one precision per list), `moneyRange`, `moneyAxis` (`18.4K` / `18.4 ألف`), `priceUnit`, `flatFee`, `priceForGuests(fils, guests, none\|from\|est)`, `fromPriceMin`, `guests`, `minGuests` |
| Numbers | `number`, `integer`, `percent`, `numberRange`, `counter`, `plural`, `pluralCategory`, `list` |
| Dates and time | `date(d, full\|short\|compact\|monthYear\|dayMonth)`, `hijri`, `dateWithHijri`, `time`, `timeRange`, `dateTime`, `relativeDay`, `countdownDays`, `daysUntil`, `duration`, `ago`, `weekdayHeaders`, `weekdayLabels`, `monthGrid`, `civil`, `isoDay`, `addDays` |
| Phone | `phone` (`+965 5123 4567` in an isolate), `normalizePhone`, `isValidPhone`, `e164`, `telHref`, `whatsappHref` |
| Input | `normalizeDigits` (Eastern and Persian to Western; apply to every numeric, phone, OTP and amount input) |

Numeric tokens are wrapped in an LTR isolate (U+2066 .. U+2069) in Arabic output and bare in English; ICU's direction marks never appear; negatives use U+2212 inside the isolate; NBSP sits between a number and its unit or currency. `moneyParts` returns bare digits (no isolate) for components that wrap them in `<bdi dir="ltr">`.

Calendar data is data only: `monthGrid(2027, 1)` returns Sunday-first rows with `isWeekend` and `isPeak`; components mirror it with logical CSS, never by reversing arrays.

## Tests

`pnpm -F @gz/i18n test` (Vitest, this package only). `test/format-cases.json` is the golden table (exact strings with the invisible characters written as escapes) that the Dart `GzFormat` must also pass; it includes every example of ADR 0010 and 0011. `test/messages.test.ts` renders every shipped message in both languages and cross-checks `common.json` against the formatter so the two sets of words cannot drift. `test/check.test.ts` proves each lint rule fires.
