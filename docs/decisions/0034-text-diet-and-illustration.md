# ADR 0034: Text diet and illustration: icons, figures and drawings carry the screens, sentences are the exception

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-10-19 |
| Scope | Every user-facing screen of the Client app and the Partner app and the web prototype: copy volume, icon use, state screens, onboarding, and the new illustration layer of the design system |
| Owner confirmation still needed | OQ-L-19 (icon comprehension check with Kuwaiti readers before visual freeze; the one-word Arabic status labels are part of OQ-L-06) |
| Amends | ADR 0013 D4 (status chip words shortened to one word where Arabic allows) and D5 (message anatomy applies to the state title and the info sheet, not to a paragraph on the screen); ADR 0030 D2 and the direction anti-template list (adds a bounded illustration accent to the gold rule; allows centred single-purpose state screens; retires the "illustration-free blank") |
| Refines | ADR 0030 (visual direction), ADR 0013 (Arabic voice) |
| Related ADRs | 0003 (statuses), 0010 (numbers), 0014 (RTL mirroring registry, now also for illustrations), 0015 (imagery: no faces), 0017 (motion), 0023 (tokens), 0024 (Flutter subset), 0031, 0032, 0033 (voucher model) |
| Requirement IDs touched | CA-ONB-01 (the introductory screens are illustration-led), NF-LOC-01, NF-LOC-02 (Arabic and mirroring), NF-DSN-01 to NF-DSN-05, NF-DSN-09 (luxury, minimal, restrained gold, one component library), NF-DSN-08 (contrast). No requirement is removed or added; every screen keeps the IDs it declares |
| Screens | all; hero screens client home (CL-DISC-01), venue (CL-VENU-01), compare (CL-SAVD-04), voucher (CL-VCHR-03), request and confirm (CL-BOOK-05, 08, 09), partner today (HL-TODY-01, 02) and requests (HL-BOOK-01) |

## Context

On 2026-10-19 the owner reviewed the prototype and said the screens are too wordy: "reduce the text from the app design and make more icons and illustrative without the most need of texts". The census confirms it: the 134 built screens show 11,700 visible English words and 10,733 Arabic words (`docs/engineering/text-diet-baseline.json`), 481 on the Home screen and 604 on venue details. Most of it is explanation (captions under facts, subtitles under list rows, sentences under switches and buttons, catalogue error paragraphs) of things an icon, a figure or a drawing can say faster and in both scripts at once.

The existing direction (ADR 0030) is restrained and calm, which suits a diet: Maison identity, gold as a verb, hairline-first. Two of its rules needed a decision before the diet could be applied: the empty state was specified as an "illustration-free blank" and the anti-template list rejects centred layouts and decoration that carries no information. The owner's request reverses the first and the second can be kept if the new illustrations carry information and are used sparingly.

Constraints that stay: no faces and no people (ADR 0015), the voucher model (ADR 0033: no new money UI), Arabic written natively (ADR 0013), the Flutter-translatable subset (ADR 0024), WCAG 2.2 AA, 44 px targets, tokens as the only source of colour, space and motion.

## Decision

1. **A text diet is binding policy** (`docs/design/02-text-diet.md`). Word budgets per element: screen title <= 3 words, section title <= 2 (3 max), button <= 2 with the verb first, field label <= 2, caption or helper <= 6 and only when it prevents an error, status = icon + one word (Arabic <= 2), toast and state titles <= 4, onboarding <= 5, list rows <= 3 with no subtitle by default. A screen shows at most 35 visible words (45 for a form) excluding authored content and data values.
2. **Facts are icon plus value, no label** (guests, area, session, rating, price, capacity, distance, time left). The label is the accessible name. `FactChip` and `FactRow` implement it. Statuses are icon plus one word (`StatusPill`, `StatusIcon`); time is a fact, not part of the label.
3. **Three kinds of paragraph survive**: legal consent, cancellation and voucher terms, and error recovery. They are not on the screen by default; an info icon (`InfoButton`) opens a sheet (`InfoSheet`). Everything else is deleted or turned into an icon, a fact or a number. ADR 0013 D5's message anatomy (outcome, money status, next step) now applies to the sheet; the visible state title is the outcome only.
4. **Icon-only controls only for universal glyphs** (heart, share, phone, chat, close, search, filter, calendar, pin, camera, back, more, compare scale), always with an accessible name and a 44 px target. Never icon-only for money, accept or decline, delete, pay or confirm: those keep one word.
5. **An illustration layer joins the system** (`design/src/system/illustration/`): one component, `Illustration` (name, size `sm 64 / md 96 / lg 144 / hero 200`, tone, decorative or labelled), and about 60 inline-SVG drawings in one hand: a constant 1.5 px Ink line (non-scaling at every size), a Rose tint for one quiet base shape, generous negative space, tokens only (`--gz-illus-*`, no hex), no gradients, no shadows, no people, no faces, no hands, no emoji. The set is Gulf wedding objects and calm architecture (arched doorway, chandelier, fanous, dallah and finjan, bouquet, rings, tiered cake, invitation, voucher ticket, QR frame, kosha stage, beach and garden arches, hall seen from the door), plus compositions for onboarding (3), empty states (8), success states (5), partner tasks (5) and error states.
6. **Gold in an illustration is bounded.** Each drawing carries at most one small gold accent (a dot, a flame, a knot: 8 px or less, part of the drawing, never interactive). This is an explicit exception to the "gold is a verb" lint of ADR 0030 D2 for drawings only; the lint for UI chrome is unchanged, and an illustration never sits as an additional gold block beside the one gold primary action.
7. **State screens may centre.** An empty, success, error or offline state and an onboarding slide are single-purpose compositions (illustration, title, one action) and may be centred; content screens remain start-aligned (the anti-template rule against centred-everything stands for them). The previous "illustration-free blank" (`EmptyState` as a start-aligned icon in a disk plus a sentence) is retired. `EmptyState`, `SuccessState` and `ErrorState` are rebuilt around `Illustration` with a title of at most four words and one action; existing props stay accepted so callers keep building, and an `icon` is mapped to the matching illustration.
8. **Components that serve the diet**: `FactChip`, `FactRow`, `IconStat`, `InfoButton`, `InfoSheet`, `IconTabs`, `IconSegmented`, `StatusIcon`, `IconProgress`, `IconListRow`, `OnboardingSlide`; `BookingThread` gains an icon per knot and a label on the active knot only; `VoucherCard`, `PriceCompare`, `RequestCard` and `KpiTile` gain compact, figure-led forms. The icon registry gains the glyphs the diet needs (ruler, sun, moon, per-guest, package, timer, route, women, men and mixed section symbols, cooking pot, and others), each with an ADR 0014 mirror flag.
9. **Mirroring for drawings** reuses the ADR 0014 mechanism: a drawing that has reading-direction meaning (key, car, route, group chat, magnifier, dallah, oud) is flagged in the illustration registry and flips through the shared `gz-mirror` class in Arabic; everything else never flips (clocks, rings, QR, hangers, symmetric architecture).
10. **Measured targets**: at least 45% fewer visible words than the baseline overall and per screen, in English and Arabic; at least 55% on the hero screens; requirement coverage must not drop (checked by `prd-tracer` per flow). Gauge: `node design/scripts/wordcount.mjs --lang both --only <prefixes>`.
11. **Tokens.** New tokens (`size.illustration.*`, `stroke.illustration`, `color.sys.illus.*`) are added through `packages/design-tokens/src/tokens.json`; the contrast gate is unchanged (drawings are decorative and exempt; informative glyphs keep their pairs).
12. **Flutter handoff.** A drawing is a vector asset: its SVG is exported with the token colours resolved and drawn at a fixed stroke in dp (the prototype's non-scaling stroke). Components are specified by their gallery pages. No Lottie, no raster.
13. **Order of work.** The system owner ships the policy, the illustration layer, the icons and the components; flow agents then adopt them screen by screen and report before and after word counts.

## Consequences

- Screens become shorter and calmer and read the same in both scripts. The cost is learnability: a glyph can be ambiguous. The mitigations are in the policy (accessible names always, one word kept where a glyph is not universal, the info icon for anything that must be explained) and in OQ-L-19 (a comprehension check with Kuwaiti readers before visual freeze).
- About 40 percent of the `common` and flow messages become unused; the system owner trims the common ones in the same change and flow agents trim theirs. `pnpm i18n:check` keeps English and Arabic in parity throughout.
- ADR 0013 D4 chip words are shortened (Arabic keeps two words where one would be ungrammatical). The status table in `01-direction.md` section 4 (knot labels) is unchanged; only the visible label policy changes.
- The direction doc stays binding for look; `02-text-diet.md` is binding for copy volume. A reviewer rejects a screen on either.
- Illustration is now a maintained asset family: new drawings must follow the hand rules (one accent, 1.5 px, no people) and appear in the gallery before use.
- Photography is unchanged on venue and service content; it is only the onboarding intro, empty and success states that move from photo or text to drawing.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Shorten copy only, no illustration | Fixes word count but not the "wordy" feel on empty and success screens, and wastes the chance to give both scripts one visual language |
| Icon-only everywhere | Unsafe for money and decisions, hostile to screen readers without names, and ambiguous for fewer-than-universal glyphs |
| Stock illustration pack | Cannot be one hand with the Maison look, brings people and faces (ADR 0015), and fails the anti-template list |
| Photography for empty and success states | Venue photography is the product; using it for "nothing here" dilutes it and cannot say "error" or "offline" |
| Animated illustration (Lottie) | Violates ADR 0017 (nothing loops), costs Flutter weight, and adds a motion budget with no information |
| Gold used freely in drawings | Breaks "gold is a verb" and competes with the primary action; one bounded accent keeps the signature without the noise |
| Emoji as icons | Rejected by ADR 0030 (anti-template list) and inconsistent across platforms |
