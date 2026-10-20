# ADR 0032: Design-pass implementation notes (token pipeline, icon weight, carousel direction, class namespaces)

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-10-13 |
| Scope | Records what the parallel design-pass agents built where it differs from, or fills a gap in, ADR 0014, 0016, 0023, 0024 and 0030 |
| Owner confirmation still needed | None. Revisit at design freeze |
| Amends | ADR 0023 D1 and D2 (generator, source layout); ADR 0014 D4 (carousel sentence); ADR 0030 (icon weight) |
| Related ADRs | 0003, 0014, 0016, 0023, 0024, 0030, 0031 |

## Context

The design-pass agents (tokens, system components, device framework, Studio, i18n, fixtures) built in parallel and reported deviations and open decisions in `docs/engineering/requests.md`. The integrator pass resolved the code side; this ADR records the decisions so they are not re-litigated and the Flutter port knows them.

## Decision

1. **Token source and generator (amends ADR 0023 D1, D2).** The source is ONE file, `packages/design-tokens/src/tokens.json` (DTCG-style `$value` / `$type`, reasons in `$extensions.ghazal.reason`), not one file per namespace. The generator is in-house (`scripts/build.mjs`), the fallback ADR 0023 already documents, not Style Dictionary. It emits `dist/tokens.css`, `tokens.ts`, `tokens.flat.json`, `icons.ts`, `dart/gz_tokens.dart` and `design/src/styles/typography.roles.css`. Dart output is plain `const` plus a `GzColors` ThemeExtension. Extra tokens were added with reasons (motion ease linear, push-reverse, favourite peak, type roles for figures and prices, and in the integrator pass: underline-press scale, toggle travel, shake distance, activity duration, scrim-top-bar gradient, compact thumbnail, photo inset, pager dots, chat media, chart geometry). Signed twins (`push-reverse`, `shake-reverse`, `toggle.travel-reverse`) exist because CSS cannot negate a token without `calc`.
2. **Icon weight (ADR 0030, direction 2.6).** The product weight is Phosphor **Regular** (16/256 of the viewBox = exactly 1.5 px at 24, the value of `stroke.icon`). Light (1.125 px at 24) stays in the registry for comparison only. `defaultWeight` in `packages/design-tokens/icons/manifest.json` is the one switch. The 16 px optical step-up is no longer needed and was removed from `Icon`.
3. **Icon additions.** `clock-off` (expired, missed), `check-double` (completed, read receipt), `pause`, `drag-handle`, and the amenity glyphs `prayer`, `parking`, `accessible`, `incense`, `stage`, `armchair`. Phosphor has no clock-off: it is drawn from `hourglass-simple-low` (time run out). Registry gate: every glyph is `<path>` only and carries a mirror flag (none of the new ones mirror).
4. **Carousels in Arabic (clarifies ADR 0014 D4).** "First image at the right" and "advance with a leftward swipe" cannot both hold physically. The implemented rule is the physical mirror of English: the first page sits at inline-start (right in Arabic) and the next page is revealed by dragging content toward inline-end (rightward). The sentence in D4 is read that way.
5. **Class namespaces.** `gz-` belongs to the component system (`design/src/system/**`). The Studio uses `gzs-` / `--gzs-`; the gallery pages use their own short prefixes (`gc-`, `ng-`, `tk-`). A global class defined by one system group must not reuse another group's name (two collisions were found and fixed: `.gz-sechead` and `.gz-stack`).
6. **Shared helpers instead of per-group copies.** `Figures`, `Fig` and `useBi` live in `design/src/system/core/Figures.tsx`; `defineWords`, `definePlurals` and `p` live in `design/src/i18n/words.ts`. The domain groups re-export them. `PickerSheet` (inputs) is a thin wrapper over the overlays `Sheet` (portal into the device frame, focus trap and focus return); there is one sheet.
7. **Stop-gap copy.** Component-owned words that are not yet in a JSON namespace are `defineWords` tables next to each component (about 600 pairs in client-domain, hotel-domain, inputs and the device shell). They are written natively in both languages but are NOT covered by `pnpm i18n:check`. Moving them into `client-domain`, `hotel-domain`, `inputs` and `nav-shell` namespaces is a handoff-phase task (the call sites change from `useW()` to `useT(ns)`).
8. **Golden format cases.** `format-cases.json` stays at `packages/i18n/test/` (ADR 0010 D4 named `packages/contracts/fixtures`); the Flutter test reads it from there until the Dart workspace exists.

## Consequences

- One generator command (`pnpm tokens`) is the only way to change a token; `pnpm tokens:check` fails on drift.
- The icon stroke is now what the direction doc says; screenshots taken before 2026-10-13 show thinner icons.
- Items 7 and 8 are known gaps, listed in `docs/engineering/STATUS.md`.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Keep Light as the icon weight and change `stroke.icon` to 1.125 | The direction doc, the contrast and target maths and the 1 px knot glyphs are all drawn for 1.5 |
| Style Dictionary now | A second toolchain with no benefit for one source file; the Dart and CSS emitters are small and tested by the gates |
| Move all copy into namespaces during the design pass | 600 strings across 49 files for no visible change; the helper is the single swap point |
