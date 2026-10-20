# Ghazal Design Studio

Web prototype of the Client app and the Partner app (hotels and halls plus service providers; the app id and screen prefix stay `hotel` / `HL-`) for the voucher marketplace of ADR 0033: clients buy one KD 2 voucher in the app, everything else is settled with the venue off-app (Vite + React + TypeScript, strict). It is also the specification the Flutter apps are built from: tokens, a Flutter-translatable CSS subset, a component gallery and one file per screen. Typefaces: El Messiri (display), Manrope (English UI), Almarai (Arabic UI) (ADR 0031 addendum). Rules: `AGENTS.md`, ADR 0021 (layout, ports), 0024 (CSS subset), 0031 (design-pass amendments).

All commands run from the **repo root** unless noted. Never type a localhost URL: the port is computed.

## Run

```
pnpm install                          # once; pnpm 10.10, Node >=22
pnpm -F design dev                    # starts the Studio on its reserved port (127.0.0.1, strictPort)
node tools/ports.mjs url design       # prints the URL (4700 + 10 x slot + 0; slot from GZ_SLOT or --slot N)
node tools/ports.mjs check design     # GET /__gz: exit 0 only if it is OUR server; else prints PID + command of the owner
node tools/ports.mjs who design       # what owns the port
node tools/ports.mjs list             # every Ghazal service and its status
```

If the port is busy, Vite exits (strictPort) and `ports.mjs who design` names the culprit. Never kill a process you did not start. Never use 5173.

## Routes (hash based)

Only `#/` (the Launcher) is the product surface. The canvas, player, system and docs views below are design-work tools reached by typing their hash; the Launcher does not link to them (`shell/App.tsx`). They are also what `pnpm shots` and the Studio use.

| Route | What |
|---|---|
| `#/` | the **Launcher**, the product's front door: one phone, a Client \| Partner switch (`?app=client\|hotel`, the label says Partner, the id stays `hotel`), EN \| AR and Restart. Nothing else is linked from it |
| `#/canvas/<client\|hotel>?lang=&w=&focus=<screenId>&flow=<flowId>` | the board: every flow of the app as a row of device frames (zoom, pan, connectors, one extra frame per declared state) |
| `#/play/<app>/<screenId>?lang=&w=&story=guest\|signed-in` | the live prototype in a device (navigator, sheets, tab bar, prototype store) |
| `#/system/<galleryPage>` | a component gallery page inside the Studio ("Design system" tab) |
| `#/docs/<name>` | a design document (`direction`, `brief`, `tokens`, `content`, `seed`, `archive`) |
| `#/gallery/<name>?lang=en\|ar` | chromeless gallery page: `design/src/gallery/<name>.tsx`, default export (`tokens`, `core`, `inputs`, `nav`, `client`, `hotel`, `charts`, `i18n`, `voucher`, `illustration`, `diet`). `client` and `hotel` accept `&only=<section>,<section>` |
| `#/frame/<screenId>?lang=&state=&w=&h=` | chromeless device frame with real chrome (status bar 47, home indicator 34, tab bar per the inventory, sheet container for sheet screens); 390 x 844 by default, `w` 360/390/430, `h=auto` grows with content. An id with no file shows "Not built yet" |

Every gallery page and every screen is its own lazy module (`import.meta.glob`) wrapped in an ErrorBoundary and Suspense: one broken file never breaks the others. `GzProvider` (`src/main.tsx`) sets `<html lang dir>`, `data-lang` and the `gz-lang-en|ar` font class from `?lang=` (the URL is the source of truth); `useLang()` returns `{lang, dir, isRtl, setLang}`. Chromeless routes carry `[data-gz-route]`, a built screen frame carries `[data-gz-frame]`, a missing one `[data-gz-missing]`, a crashed one `[data-gz-error]` (the shots tool reports all of them).

## Look at your work

```
pnpm shots --route gallery:core --lang both
pnpm shots --screen CL-BOOK-05 --lang both --w 390 360        # also 430
pnpm shots --screen CL-BOOK-05 --state loading --full         # a state a screen exports; --full grows the frame
pnpm shots --url-hash "#/canvas/hotel?focus=HL-TODY-01" --lang ar --viewport 1440x900
node design/scripts/snap.mjs design/explorations/thread/board.html out.png --lang ar     # file:// pages
```

`shots.mjs` checks `/__gz` first (identity), starts `pnpm -F design dev` detached if the server is down (log in the out dir), tolerates a concurrent starter, uses the system Chrome (`playwright-core`, channel chrome), waits for fonts, and prints saved paths plus every console error, failed request, error-boundary hit and "not built" placeholder (`--strict` exits 3 on any). Files land in `design/.shots/` as `<name>.<lang>.<width>.png` (git-ignored; `--out` overrides). Open the Arabic PNG with Read, always. Never type a localhost URL: `node tools/ports.mjs url design`.

## Add a screen

1. Find the inventory entry in `docs/product/screens/<app>/NN-<flow>.json` (id `CL-BOOK-05`, flow id `booking`, requirement IDs, states, interactions). The Studio shows the same data in the inspector.
2. Create `design/src/screens/<app>/<flow-id>/<INVENTORY-ID>.tsx` (`client` or `hotel`; flow id as in the JSON file name: `onboarding`, `saved-compare`, `my-wedding`, `reviews-rewards`, `today`, `grow` ...). The file name IS the screen id: the registry, the canvas, the player and `pnpm shots --screen` find it by that name, nothing to register.
3. Default-export a component. Props: none (read `useFrame()` for `{screenId, state, width}` and `useNav()` for `params`, `push`, `pop`, `replace`, `reset`, `switchTab`, `openSheet`, `openDialog`, `toast`; both work in a static frame, where navigation is inert). Optionally `export const states = ['loading', 'empty', 'error']` (strings, never `'default'`): the canvas draws one extra frame per state and the inspector lists them; the `?state=` of the frame is what `useFrame().state` returns.
4. Build from the system only: `import { Screen, TopBar, ActionBar, Button, ... } from '../../../system'`. A screen is `<Screen top={<TopBar .../>} bottom={<ActionBar action={{label}} />}>` plus content; the body is the one scroll container and has no side padding (add `padding-inline: var(--gz-space-gutter)` in the screen's own CSS file next to it; full-bleed heroes need that). Screen CSS follows the same subset and lint as the system (tokens only, logical properties). Declare the requirement IDs the screen covers in a comment at the top of the file.
5. Mock data: `import { ... } from '../../../mock'` (re-exports `@gz/contracts`: venues, packages, bookings, requests, chat, `engine` pricing and availability). Money is `{fils, currency}`, formatted only by `useFormat()` (`f.money`, `f.moneyParts`). Prototype state (auth gate, brief, compare list, bookings) is `usePrototype` from `'../../../shell/state'` (read with selectors, act with `usePrototype.getState().addToCompare(id)`).
6. Strings: one i18n namespace pair per flow, `<app>-<flow>`:
   ```
   node packages/i18n/scripts/new-namespace.mjs client-booking     # creates packages/i18n/messages/{en,ar}/client-booking.json, regenerates the key types
   ```
   Keys are flat camelCase starting with the namespace (`clientBookingReviewTitle`); read them with `const t = useT('client-booking')` or `<T ns="client-booking" k="..." components={{...}} />`. Words that already exist are in `common` (actions, statuses, availability, a11y labels). Never type a digit, a price or a date in a message: pass the finished string from `useFormat()`. Run `pnpm i18n:check` before handing back. Component-owned words (inside `system/`) are the stop-gap `defineWords` tables, not namespaces yet (STATUS.md).
7. Look: `pnpm shots --screen <ID> --lang both --w 390 360` and every exported state; Read the Arabic PNG; also open `#/canvas/<app>?focus=<ID>` once to see it in its flow. Run `pnpm typecheck`, `pnpm lint:css`, `pnpm i18n:check`.

Gallery pages (a component, not a screen): `design/src/gallery/<name>.tsx`, default export; it appears under "Design system" in the Studio and at `#/gallery/<name>`. Group galleries compose per-component sections from `design/src/system/<group>/gallery/`.

## Text diet (ADR 0034, `docs/design/02-text-diet.md`)

The apps speak through illustration, icon, number, image and one-word labels; a sentence is the exception and lives behind an info glyph. Read `docs/design/02-text-diet.md` before touching copy. In short:

| Element | Budget (EN / AR) |
|---|---|
| Screen title | 3 words |
| Section title | 2 (3 max) |
| Button | 2, verb first |
| Caption or helper | 6 / 5, only if it prevents an error |
| Status | icon + 1 word (AR 2) |
| Empty, success, error, offline | illustration + title of 4 words + one action |
| Onboarding | illustration + 5 words |
| Body paragraph | none, except consent, cancellation terms, error recovery (behind `InfoButton`) |

Facts are icon + value with no label (`FactChip`, `FactRow`); lists use leading icons, not subtitles (`IconListRow`); icon-only controls only for universal glyphs (heart, share, phone, chat, close, search, filter, calendar, pin, camera, back, more, compare) and never for money, accept/decline, delete, pay or confirm. Every icon keeps its word as an accessible name (`gz-sr-only` or `aria-label`).

New system pieces (gallery pages `#/gallery/illustration` and `#/gallery/diet`, both languages):

| Piece | Use |
|---|---|
| `Illustration` (`system/illustration/`) | 39 spot drawings and 21 compositions in one hand (1.5 px ink line, rose tint, one gold accent, no people); sizes `sm 64`, `md 96`, `lg 144`, `hero 200`; tones `default quiet danger success on-dark`; decorative unless `label` is given; directional drawings flip in Arabic through `illustrationMirrors` |
| `EmptyState`, `SuccessState`, `ErrorState` | illustration + <= 4-word title + one action; `detail` (and a legacy long `body`) opens from an info glyph; an `icon` is mapped to its illustration |
| `OnboardingSlide` | illustration + <= 5 words |
| `FactChip`, `FactRow`, `IconStat`, `StatusIcon`, `IconListRow`, `IconProgress` | icon + value facts, big-number stat, status glyph, leading-icon row, thread with icon knots (`BookingThread` is built on it) |
| `InfoButton`, `InfoSheet` | the three allowed paragraphs |
| `IconTabs`, `IconSegmented` | glyph controls with a fixed-size container; one word under or beside the selected item; measured scale-safe |
| `useDuration` | `23 h` for time-left facts |

Measure with `node design/scripts/wordcount.mjs --lang both --only <ID-prefixes> [--out f.json]` against `docs/engineering/text-diet-baseline.json`. Targets: at least 45% fewer visible words per screen, EN and AR, at least 55% on the hero screens (CL-DISC-01, CL-VENU-01, CL-SAVD-04, CL-VCHR-03, CL-BOOK-05, CL-BOOK-08/09, HL-TODY-01/02, HL-BOOK-01); requirement coverage must not drop.

Scale safety: the Launcher scales the phone and the Studio zooms frames, so anything that measures (`getBoundingClientRect`) and then writes px back, or turns pointer deltas into a transform, divides by `layoutScale(el)` (`system/core/layoutScale.ts`). Thread and thumb positions, sheet and pager drags, pull-to-refresh, the range slider and FLIP all do.

## Gates

```
pnpm typecheck       # tsc --noEmit (strict) in every package that has the script
pnpm lint            # design typecheck + stylelint
pnpm lint:css        # Flutter subset, logical properties, token-only values (see below); currently 0 warnings
pnpm tokens          # regenerate packages/design-tokens/dist and design/src/styles/typography.roles.css
pnpm tokens:check    # tokens gates (grid, control heights, type parity, 127 contrast pairs, icons) and dist freshness
pnpm i18n:check      # messages lint; add --write after adding or removing a namespace file
pnpm contracts:check # fixtures freshness (pnpm -F @gz/contracts build regenerates) + 10k validation checks
pnpm verify          # all of the above
node design/scripts/images.mjs         # photo variants (480/800/1200) under public/images/_v; Photo builds its srcset from them
node design/scripts/probe.mjs [--soft]  # gallery probe at 360/390, en+ar: visible overflow, targets under 44 (>= 390), unnamed controls/dialogs
pnpm -F design check:cycles            # fails on an import cycle (part of `pnpm lint`)
pnpm -F design build # typecheck + vite build
pnpm -F @gz/i18n test
```

## CSS lint (ADR 0024 D2, warnings per ADR 0031 D3)

`design/stylelint.config.mjs` + `design/stylelint/gz-flutter-subset.mjs`: logical properties only (`stylelint-use-logical`); colours, spacing, radius, type and motion values must be `var(--gz-...)` tokens (`stylelint-declaration-strict-value`); denied: `grid`, `backdrop-filter`, `mix-blend-mode`, `filter`, `clip-path`, `mask*`, `calc()`, `em/rem/vh/vw/ch`, `%` (except flex), `:hover`, italics, `text-transform`, container `opacity`, inset or multi-layer shadows, negative margins, raw hex/`rgb()`, raw `ms`/`cubic-bezier`; px on spacing and size properties must be a multiple of 4 (plus 0, 1, 2, 6, 10 and 9999 for the pill radius). Waive one declaration with `/* flutter-ok: <reason> */` above it (sticky: `/* flutter-ok: pinned sliver */`). `src/shell/**`, `src/gallery/**` and `src/system/*/gallery/**` skip the token-only rule (harness and gallery chrome, not product CSS); logical properties and the subset deny-list still apply there. At design freeze flip `defaultSeverity` to `error`.

## Layout

```
src/main.tsx            entry: tokens CSS (packages/design-tokens/dist/tokens.css), styles/, shell CSS, GzProvider + App
src/styles/             reset, base (.gz-mirror, bidi), typography (+ generated roles), motion, thread, fonts
src/shell/              router, lang (GzProvider), frame context, registries, ErrorBoundary
src/shell/device/       Device, StaticFrame, PrototypePlayer (status bar, safe areas, home indicator)
src/shell/studio/       the Studio: canvas, chrome, player page, docs, data (inventory, requirements); classes use gzs-
src/shell/state/        prototype store (zustand): auth gate, brief, wedding profile, compare list, bookings
src/system/<group>/     core (+ brand), inputs, nav, overlays, illustration, charts, domain-client, domain-hotel; one barrel each, re-exported by system/index.ts
src/system/<group>/gallery/   the group's gallery sections
src/gallery/<name>.tsx  one component-gallery page per file
src/i18n/               React binding of @gz/i18n: useT, useFormat, <T>, Ltr / Auto / Num / Phone, defineWords (words.ts)
src/screens/{client,hotel}/<flow>/<ID>.tsx   one screen per file, named by inventory id (134 built; flow-local pieces in _components/, which the registry ignores)
src/mock/               re-exports packages/contracts fixtures and engine
public/fonts            self-hosted woff2 (El Messiri, Manrope, Almarai are the product faces; older Cairo, Poppins, Newsreader, Amiri files remain for the explorations); public/images photography (manifest.json, CREDITS.md)
vite/gz-identity.ts     /__gz plugin + <meta name="gz-app">
scripts/                shots.mjs, snap.mjs
.review/                audit scripts (contrast, font metrics, segments); explorations/ static design explorations (not part of the app)
```

Conventions: classes `gz-<component>` (system), `gzs-` (Studio); a class is defined by exactly one group; component roots carry `data-gz="<Component>"`; directional icons mirror through the registry flag (`<Icon>` adds `gz-mirror`), nothing else flips; motion values are `var(--gz-motion-*)` and every animation has a `prefers-reduced-motion` branch; `Figures`, `Fig` and `useBi` come from `system/core`, `defineWords` from `i18n/words.ts`.

Aliases (vite + tsconfig): `@gz/tokens` -> `packages/design-tokens`, `@gz/i18n` -> `packages/i18n`, `@gz/contracts` -> `packages/contracts` (workspace packages `@gz/design-tokens`, `@gz/i18n`, `@gz/contracts`), `@docs/*` -> repo `docs/` (JSON and markdown imports; the dev server may read the repo root).
