# Flutter development guide (workspace, harness, rules)

Plan: `docs/engineering/flutter-build-plan.md`; decisions: ADR 0022 as amended by ADR 0036. No simulator or emulator until the very end of F4 (owner instruction): verify with `flutter analyze`, `flutter test` and the headless shot harness only. Never run `flutter run` or `flutter build ios`.

## Commands (repo root)

| Command | What it does |
|---|---|
| `pnpm flutter:get` | `flutter pub get` for the whole workspace (also regenerates the l10n Dart files) |
| `pnpm flutter:analyze` | `flutter analyze` over every member (one `analysis_options.yaml` at the root) |
| `pnpm flutter:rules` | `tools/check-dart-rules.sh` (add `--fix-hints` for the remedy of each rule, or pass paths) |
| `pnpm tokens` / `pnpm tokens:check` | build (or verify freshness of) the web outputs AND the Dart tokens in `packages/ghazal_ui/lib/src/tokens/generated/` |
| `pnpm flutter:icons` | `node tools/gen-icons.mjs`: icon font `GzIcons.ttf` + `gz_icons.g.dart` from `packages/design-tokens/icons` (`--check` verifies the registry and the codepoint map) |
| `pnpm flutter:illustrations` | `node tools/export-illustrations.mjs`: the 60 drawings to `packages/ghazal_ui/assets/illustrations/<name>.<sm|md|lg|hero>.svg` + `gz_illustrations.g.dart` (`--check` verifies all 240 files) |
| `pnpm flutter:routes` | `node tools/gen-routes.mjs` (route stubs, router composition, screen registry; `--check` fails when stale) |
| `pnpm flutter:test` | `flutter test` in every member with a `test/` folder, concurrently, through `tools/with-slot.mjs` (4 slots) |
| `pnpm flutter:verify` | analyze + rules + test |
| `pnpm l10n` | merge `packages/i18n/messages` into the ARB files, `flutter gen-l10n` for client_app, provider_app and ghazal_ui, then regenerate the message-parity table |
| `pnpm l10n:check` | ARB parity (keys, placeholders, plural categories), freshness of ARB and fixtures, `dart analyze` of the generated code |
| `pnpm format-cases` | regenerate `packages/contracts/fixtures/format-cases.json` and the Hijri table from the TypeScript formatters |
| `pnpm fshot --app client --screen CL-DISC-01 --lang ar [--w 360 390] [--state loading]` | headless PNG of one or more screens; `--flow <flow-id>` expands to every screen of a flow, `--all` to every screen |

Heavy runs always go through `node tools/with-slot.mjs <name> -- <command>` (counting semaphore, default 4, lock directories under `tools/.locks`, stale locks removed by pid). Never run several `flutter test` processes by hand in parallel.

## Folder layout

```
pubspec.yaml                 Dart pub workspace root (members, SDK pins); one pubspec.lock; analysis_options.yaml
apps/client_app              com.ghazal.client   (CL-* screens)     apps/provider_app   com.ghazal.provider (HL-* screens)
  lib/main.dart, bootstrap.dart
  lib/app/app.dart           ConsumerStatefulWidget: router + locale into GzApp
  lib/app/app_router.dart    GENERATED composition (one line per flow + the tab shell)
  lib/app/screen_registry.dart  GENERATED: inventory id -> path / kind / flow / navigatesTo, plus the tab list
  lib/app/app_tab_shell.dart placeholder tab bar until GzTabBar (F2)
  lib/features/<flow>/{presentation,application}/, <flow>_routes.dart   one folder per inventory flow
  lib/l10n/{app_en,app_ar}.arb + generated/   AppL10n (gen_l10n, committed)
  test/shots/shots_test.dart the shot entry; test/registry_test.dart checks the route table against the inventory
packages/ghazal_ui           theme, tokens, GzApp (the ONLY MaterialApp host), GzStubScreen, fonts, GzL10n; only package importing material_ui / cupertino_ui
packages/ghazal_core         Money, GzFormat, PhoneKw, providers (locale, digit style, clock, format), AppEnv, ApiProblem, RetryPolicy, GzLogger, Analytics, ScreenState (Flutter package: Riverpod, shared_preferences)
packages/ghazal_domain       entities and repository interfaces (pure Dart)
packages/ghazal_api          dio client and repositories (depends on ghazal_core)
packages/ghazal_mock_api     shelf mock (pure Dart): in-process dio adapter or standalone server
packages/ghazal_testing      shot harness (loadAppFonts, GzHarness, runShotSuite), fixtures, fake clock
tools/                       gen-routes.mjs, with-slot.mjs, fshot.mjs, flutter-test-all.mjs, check-dart-rules.sh
```

Fonts live in `packages/ghazal_ui/assets/fonts` (families `ElMessiri`, `Manrope`, `Almarai`; licences and the web-name mapping in `LICENSES.md`). Always give a `TextStyle` that names them `package: 'ghazal_ui'`; use `GzFonts`.

## The shot harness

`GzHarness.pump(tester, ...)` models the prototype device: 390x844 logical at DPR 2 (780x1688 PNG), safe area 47 top and 34 bottom, a drawn status bar (4:00) and home indicator above the app (parity ignores both bands), the real fonts (`loadAppFonts()` registers every font of `FontManifest.json`, never Ahem), a bounded settle (at most 4 s of fake time, looping animations tolerated, images pre-cached inside `tester.runAsync`). `GzHarness.shoot(tester, path)` writes the root repaint boundary. Parameters: `app` or `router`, `locale`, `width`, `height`, `dpr`, `safeTop`, `safeBottom`, `textScale`, `overrides`, `fixedClock` (default `2026-11-12T16:00+03:00`).

`runShotSuite` (called by each app's `test/shots/shots_test.dart`) is driven by `--dart-define`: `SHOT_IDS` (comma list or `all`), `SHOT_LANGS` (`ar,en`), `SHOT_W` (comma list; 390), `SHOT_H` (844), `SHOT_SCALE` (2), `SHOT_TEXT_SCALE` (1), `SHOT_STATE` (none), `SHOT_OUT` (default `apps/<app>/build/shots`). Files: `<id>.<lang>.<w>.png`, `.<state>` before the extension when a state is set. A shot at width 390, scale 2 and no state is also written as `<id>.<lang>.png` (the name the parity tool reads). Shots of the stub screens show "Not built yet": that label is how unbuilt screens are found (the final sweep fails on any route still rendering `GzStubScreen`).

## Route stubs and who owns what

`tools/gen-routes.mjs` writes one `lib/features/<flow>/<flow>_routes.dart` per inventory flow, first line `// GENERATED STUB`. Contract (kept by hand-written files too): `List<RouteBase> get <flowCamel>Routes` for every screen that is not a tab root, and `Map<String, GoRoute> get <flowCamel>TabRoots` (inventory id to route) for the screens that are the root of a main tab. Paths are `/<flow-id>/<slug>`, route names are the inventory ids (`context.goNamed('CL-DISC-02')`). A flow agent takes a file over by deleting the first line; the generator then never rewrites it. `app_router.dart` and `screen_registry.dart` are regenerated on every run and are never edited by hand. Sheets are plain routes until the sheet page builder lands in F2.

## How to add (or implement) a feature screen

1. Read the inventory entry (`docs/product/screens/<app>/<nn>-<flow>.json`) and the prototype screen in `design/src/screens/`.
2. In `lib/features/<flow>/presentation/` write the screen as a widget from `ghazal_ui` components; state in `application/` (hand-written Riverpod `Notifier` / `AsyncNotifier`, no codegen).
3. Delete the `// GENERATED STUB` line of `<flow>_routes.dart` and replace the `GzStubScreen` builder of that screen with yours (keep the path, the name and the two getters).
4. Strings: add the keys to your flow's namespace under `packages/i18n/messages/**`, run `pnpm l10n`, and read them as `context.l10n.someKey` (see "Localisation" below); never a literal in `Text(`, never a hand-typed price or date (`ref.watch(gzFormatProvider)`).
5. `pnpm fshot --app <client|provider> --screen <ID> --lang both`, Read the Arabic PNG, compare with the prototype shot, then `pnpm flutter:verify`.
6. Need a token, component or dependency: append one line to `docs/engineering/requests.md` with `>>`. Nobody runs `pub add`.

## UI foundation (`ghazal_ui`, F1a)

Everything below is exported from `package:ghazal_ui/ghazal_ui.dart` (apps never import `material_ui`; the reference ramps `GzRefColors` are only in `package:ghazal_ui/ghazal_ui_dev.dart` for galleries and tests).

### Tokens: build, use, add

`pnpm tokens` writes the web outputs and four Dart files into `packages/ghazal_ui/lib/src/tokens/generated/` (committed, `// GENERATED`, never edited): `gz_colors.g.dart` (`GzColors` ThemeExtension with every sys role, `copyWith`, `lerp`, `named`), `gz_dimensions.g.dart` (`GzSpace`, `GzRadius`, `GzSize`, `GzStroke`, `GzZ`, `GzLayout`, `GzElevation` BoxShadow lists, `GzGradient`, `GzShape`), `gz_motion.g.dart` (`GzMotion`), `gz_type.g.dart` (`GzFont`, `GzTextRole`, `GzType`, `GzTypeSet`). Names are the token path in camelCase (`color.sys.text.primary` -> `GzColors.textPrimary`, `space.4` -> `GzSpace.s4`, `size.control.cta` -> `GzSize.controlCta`, `type.ar.body` -> `GzType.ar.body`). Font families are exactly `ElMessiri`, `Manrope`, `Almarai` and every style carries `package: 'ghazal_ui'` (so `TextStyle.fontFamily` reads `packages/ghazal_ui/Manrope`). Arabic styles have `letterSpacing: 0` (the generator throws otherwise); numeric roles carry tabular and lining `FontFeature`s.

To add a token: edit `packages/design-tokens/src/tokens.json` (single writer: the tokens owner; others append a line to `docs/engineering/requests.md`), run `pnpm tokens`, commit the generated files. A new type role needs an entry in both `type.en` and `type.ar`; a new colour role is a new `color.sys.*` token (it appears as a `GzColors` field automatically). `packages/ghazal_ui/test/tokens_test.dart` compares sample tokens with `dist/tokens.flat.json`.

### Theme and `context.gz`

```dart
GzApp(routerConfig: router, locale: locale)            // the only MaterialApp host; installs buildGhazalTheme(locale) and GzTheme
final gz = context.gz;                                  // GzThemeData
gz.colors.textPrimary   gz.text(GzTextRole.body)   gz.isRtl   gz.isAr   gz.locale   gz.textDirection
GzSpace.s4  GzSize.controlCta  GzRadius.mdAll  GzStroke.hair  GzElevation.e2  GzMotion.durationFast   // static token classes
```

`buildGhazalTheme(Locale)` builds an explicit `ColorScheme` (never `fromSeed`), no ink splash, and a text theme from the locale roles; components read `context.gz`, not `Theme.of`. In a widget test wrap the subject in `GzTheme(locale: ..., child: ...)` (without one `context.gz` falls back to the light colours and the ambient locale).

Text: `GzText('x', role: GzTextRole.body, color: ..., maxLines: 2)` (colour defaults to `textPrimary`; tracked English eyebrows are uppercased by the widget; `figures: true` wraps digit runs as figures islands; `GzText.rich` for spans). Numbers: `GzNum(formatted, role: GzTextRole.price)` for a number that is the whole element, `GzFigures.span(context, '12', role: ...)` / `GzFigures.spans` inline (Manrope tabular digits, U+2066 .. U+2069 isolate, the size of the role's figure role, line height 0 like the web `.gz-num`), `GzLtr(child:)` and `GzBidi.isolateLtr` for other LTR islands. Never type a number or price into a string.

### Motion and `GzPressable`

`GzMotion` (durations 120 / 200 / 320 / 480 / success 640, curves `easeStandard` / `easeEmphasized` / `easeExit` as `Cubic`, `scalePress` .985, `scaleRevealFrom` 1.035, push distances). `GzReducedMotion.of(context)` is `MediaQuery.disableAnimations`; `movement(context, d)` returns 1 ms when reduced, `fade(context, d)` caps a fade at 120 ms. `GzPressable` is the single press behaviour: scale .985 + tone step (`color` -> `pressedColor`, `disabledColor`) in 120 ms on the standard curve, a minimum 44 x 44 target, a 2 dp focus ring 2 dp outside (colour `focusRing`, `onDark: true` for ink surfaces; keyboard focus only), Enter / Space activation, Semantics button (`semanticLabel`, `selected`), a disabled state when `onPressed` is null, and `GzHaptics.fire` (the app installs `GzHaptics.handler` once; the default does nothing). Use `GzPressable.builder` when the content changes with `GzPressState` (pressed, focused, enabled). `GzFadeReveal(child:, revealed:)` is the image reveal (opacity + 3.5% settle, 480 ms; reduced motion keeps only a 120 ms fade). Tests: `test/gz_pressable_test.dart`.

### Icons

`pnpm flutter:icons` builds `assets/fonts/GzIcons.ttf` with fantasticon (`npx`, pinned 4.1.0, the SVGs are filled outline paths so `normalize` is off and every glyph shares the 256-unit em) from the Phosphor Regular set the web uses (`icons/regular`, 177 glyphs) plus `brand-knot` (use at size 8) and `brand-divider` (size 56). Codepoints are stable (`assets/fonts/GzIcons.codepoints.json`, committed; new names take the next free one) and `lib/src/icons/gz_icons.g.dart` has `GzIcons.<camelName>` `IconData` constants, `GzIcons.byName`, `GzIcons.mirrorInRtl` (the manifest mirror flags, ADR 0014; mirrored glyphs also carry `matchTextDirection`). `GzIcon(GzIcons.back, size: GzIconSize.md, tone: GzIconTone.accent, semanticLabel: ...)` or `GzIcon.named('chevron-left')`; sizes 16 / 20 / 24 / 32; decorative unless a label is given; flips in RTL for the mirror set (`mirror:` overrides).

### Illustrations

`pnpm flutter:illustrations` loads the real registry with Vite SSR (no browser), renders each drawing with react-dom/server and resolves the CSS classes (`il-l`, `il-s`, `il-t`, `il-td`, `il-k`, `il-a`, `il-al`, `il-g`, `il-f`, `il-fs`, `il-kl`, `il-dash`) into presentation attributes with the token hex values. flutter_svg has no `vector-effect: non-scaling-stroke`, so each size variant pre-compensates the stroke and dash lengths by 120 / size (1.5 dp at sm 64, md 96, lg 144, hero 200): `assets/illustrations/<name>.<size>.svg`. `GzIllustration(GzIllustrationName.doorway, size: GzIllustrationSize.lg, tone: GzIllustrationTone.standard, semanticLabel: ...)`; tones are applied with a flutter_svg `ColorMapper` over the exact token hex values; drawings with `mirror: true` in the registry flip in RTL. Do not hand-edit the SVGs.

### Foundation gallery and parity

`GzFoundationGallery` (`ghazal_testing`) is the Flutter twin of the web `#/gallery/tokens` and `#/gallery/illustration` pages: colour ramps with contrast, sys roles, every type role in both scripts, space / radius / elevation / control heights, motion, the icon sheet (name under each glyph) and the illustration contact sheet. `packages/ghazal_testing/test/foundation_gallery_test.dart` writes `packages/ghazal_testing/build/foundation/<chunk>.<lang>.png` (390 wide, DPR 2, no device chrome). Compare with the web render (the reference shots are `pnpm shots --route gallery:tokens --lang both --w 390 --full --out design/.shots/ref/gallery`; Chrome stitches full-page shots wrongly beyond 16384 px, so compare the first 16000 px, or screenshot single `.tk-sec` elements) using `node tools/parity/parity.mjs --app client --screen <name> --lang ar --ref <png> --flutter <png> --out <png>` on aligned crops.

## Rules (`pnpm flutter:rules`)

- No `package:flutter/material.dart` or `cupertino.dart` anywhere; `material_ui` and `cupertino_ui` only inside `packages/ghazal_ui`. Apps import `package:ghazal_ui/ghazal_ui.dart` and `package:flutter/widgets.dart`.
- `Color(0x` and `Colors.` only in `packages/ghazal_ui/lib/src/tokens/`. Semantic tokens everywhere else.
- Directional layout only: `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`, `TextAlign.start/end`, `BorderRadiusDirectional`. No `EdgeInsets.only(left|right`, `Alignment.centerLeft|Right|top/bottomLeft|Right`, `Positioned(left|right`, `TextAlign.left|right`.
- No string literal directly in `Text(` (tests and `ghazal_testing` excepted); no `letterSpacing` other than 0 outside tokens.
- No `BackdropFilter`, `ImageFiltered` or `Opacity(` outside `packages/ghazal_ui/lib/src/effects/` (alpha colours instead).
- No import from one `lib/features/<a>/` into `lib/features/<b>/` (share through a package or a provider in `lib/app`, navigate by route name).
- A trailing `// gz-rules-ok` on a line silences one deliberate exception; use it rarely and say why.
- Riverpod 3: use `Notifier` / `AsyncNotifier`; `StateProvider` lives in `package:flutter_riverpod/legacy.dart` and is not used. `phosphor_flutter` does not compile on this Flutter and is never added. `Override` is imported from `package:flutter_riverpod/misc.dart` (re-exported by `ghazal_testing`).
- Do not use `rm -rf` (project settings deny it); use `rm -r` on exact paths.

## Core and brand components (`ghazal_ui`, F2 group G1)

Source of truth: `design/src/system/core/**` and `brand/**`; `Foo` is `GzFoo`, props keep the TypeScript names and defaults (a web `children` string is `label`, `onClick` is `onPressed`, a null `onPressed` is `disabled`). Barrels: `package:ghazal_ui/src/core/core.dart`, `.../brand/brand.dart` (both exported by `ghazal_ui.dart`).

| Group | Widgets |
|---|---|
| Actions | `GzButton` (`GzButtonVariant` primary / secondary / tertiary / destructive, `GzButtonSize` 44 / 48 / 52 / 56, `iconStart`, `iconEnd`, `loading` draws the thread once, `fullWidth`, `reason`, `onDark`), `GzIconButton` (plain / outline / overImage / onScrim, `active` toggle with the favourite pop), `GzChip`, `GzFilterChip` (`selected`, `menu`, `count`) |
| Marks | `GzBadge`, `GzCountBadge`, `GzStatusPill` / `GzStatusIcon` (`GzStatus` has every request, voucher, visit, listing and availability state; labels come from the shared `common` words via `status.label(context.gzL10n, audience)`), `GzAvatar`, `GzRating`, `GzMoney`, `GzPrice` (`GzPriceSize`, `GzPriceUnit`, `was`, `prefix`) |
| Structure | `GzDivider`, `GzThreadRule` (`GzDraw` mount / inview / off), `GzListRow`, `GzIconListRow`, `GzSectionHeader`, `GzKeyFact`, `GzTag`, `GzFactChip`, `GzFactRow`, `GzIconStat`, `GzIconProgress`, `GzSkeleton` / `GzSkeletonText`, `GzToast`, `GzUndoBar`, `GzToastRegion` (a child of a `Stack`) |
| Controls | `GzSwitch`, `GzCheckbox`, `GzRadioGroup<T>` + `GzRadio<T>`: controlled with `checked` / `value` + `onChanged`, or uncontrolled from `defaultChecked` / `defaultValue`; one Semantics node each (toggled, checked / mixed, mutually exclusive) |
| Brand | `GzWordmark`, `GzMonogram`, `GzThreadKnot` (`GzKnotState` open / now / tied / ended, `pop`), `GzThreadBead` |
| Helpers | `GzDrawOnce` (the 480 ms draw-on from inline-start, reduced motion = finished), `GzFadeInOnce`, `GzScalePop`, `GzBead` / `GzBeadBox`, `GzFocusOutline`, `GzPreviewState` (gallery only: pressed / focus without a pointer), `gzFigText` |

Rules of this group. Numbers and money go through the shared formatter: `GzPrice(fils: 18200000)`, `GzCountBadge(count: 3)`, `GzRating(value: 4.8, count: 212)`. `ghazal_ui` therefore depends on `ghazal_core`; the app installs `GzFormatScope(format: ref.watch(gzFormatProvider), child: ...)` once above the router (without it the components use a default Western-digits formatter for the ambient locale). Colour, space, radius, stroke and motion are tokens only. Skeleton is static (direction 5: nothing loops); `shimmer: true` is opt-in and respects reduced motion. Money is one LTR island, the currency drawn before the figure in both languages, a zero `.000` set quiet in `exact` mode.

Parity notes (gallery `core`, `node tools/parity/parity.mjs --gallery core`; `ghazal_testing/test/gallery/core_gallery_test.dart` renders it and also writes each Arabic render under the Arabic section name the web reference files use):
- The prototype's `.gz-reset { font: inherit }` is declared after the type role classes, so a web `<button class="gz-reset gz-t-button">` renders its label in the page type (`body`: 16/24 regular), not the 15/500 `button` role. Button, Chip and the toast action reproduce what the reference renders (`gzResetLabelStyle`, one function to change if the web CSS is fixed). The tertiary rule hangs under that 24 dp line box.
- A web chip is exactly padding 16 + 1 hairline per side (12 before the bead), measured in Chrome (a 3-digit chip is 63.77 dp); `GzChip` and the chip group use the tokens as they are. Flutter text sits about 0.5 to 1 dp lower than Chrome's inside the same line box (all sections show a 1 to 2 px height difference from this): Chrome rounds each font's ascent and descent to whole pixels.
- Web `weights` row of the Icon section shows light and regular glyphs; the Flutter font has regular only.
- `FileImage` never completes under `flutter_test` fake async: galleries load photographs with `MemoryImage`.

## Charts (`ghazal_ui`, F2 group G4)

Source of truth: `design/src/system/charts/**`; `Foo` is `GzFoo`. Barrel `package:ghazal_ui/src/charts/charts.dart` (add to `ghazal_ui.dart` when the integrator wires the groups). No chart library: `CustomPainter`, tokens only.

| Widget | Notes |
|---|---|
| `GzSparkline(values, label, description, height: 32, area, endMark, tone: GzSparkTone)` | one bead on the last value, mirrors in RTL |
| `GzBarChart(bars: [GzBar(id, label, value, highlight, hatch)], formatAxis, title, seriesLabel, formatValue, hatchLabel, xLabel, height, showTable)` | every bar labelled when 8 or fewer, else first / middle / last |
| `GzLineChart(series: [GzLineSeries(id, label, values, tone: GzLineTone, dashed, area)], xLabel, formatAxis, title, formatValue, xLabels, height, showTable)` | one to three series |
| `GzBreakdownChart(segments: [GzSegment(id, label, value, pattern: GzFillPattern, tone: GzSegmentTone)], formatValue, formatShare, title, variant: GzBreakdownVariant, center: GzDonutCenter)` | stacked bar or donut |
| `GzFunnelBars(stages: [GzFunnelStage], formatValue, formatStep, title, valueLabel)`, `GzRankedBars(items: [GzRankedItem], formatValue, title, valueLabel)` | horizontal bars growing from inline-start |
| `GzHeatStrip(days: [GzHeatDay(iso, lanes: [GzLaneState], peak)], laneLabels, dayLabel, legend: GzHeatLegend, counts: GzHeatCounts, title, laneHeight)` | one lane per hall |
| Kit | `GzChartGeometry` (pure: `niceTicks`, `labelIndexes`, `pointX`, `valueY`, `sparkPoints`, `linePoints`, `barRects`, `segmentWidths`, `donutArcs`, `stepPercent`, `barShare`), `GzChartReveal` / `GzChartProgress`, `GzChartLegend` / `GzLegendEntry`, `GzChartTwin`, `GzPatternPainter` |

Rules of this group. Every chart takes `title`, optional `description`, `animate`, and (except the sparkline) `showTable`. Accessibility: ONE Semantics node per chart (label = title, value = description + every row of the table twin); marks, axes and legend are excluded; colour is never the only carrier (patterns hatch / dots / cross plus legend labels and printed shares). Direction (ADR 0014 D5): time and ordinal axes follow reading direction (earliest at the right edge in Arabic), the value axis never flips and sits at the inline-start, a donut is circular and never mirrors, numbers are figures islands (`gzFigText`). Animation: `GzChartReveal` plays the grow (480 ms) then the fade (320 ms) once when first built (not on scroll: there is no viewport trigger yet); reduced motion and `animate: false` show the final frame. The draw-on of a line reveals by a clip from the first point's side (no per-frame path extraction); patterns are drawn as lines and circles (no shader asset). Dashed comparison lines are pre-split into one path at build time. Painters repaint on the animation only and are each inside a `RepaintBoundary`. No words live in the group (all text arrives as parameters), so there is no `charts.*` l10n part.

Parity notes (gallery `charts`, `node tools/parity/parity.mjs --gallery charts`): the web reference was captured before the 480 ms delayed fade layer played (`gz-chart-fade`: area tint, beads, dashed series, lanes of a strip below the fold, the donut ring), so those layers are drawn only by Flutter; the table twin column widths are a proportional proxy for CSS auto layout.

## Inputs and calendar (`ghazal_ui`, F2 group G2)

Source of truth: `design/src/system/inputs/**`; `Foo` is `GzFoo`, props keep the TypeScript names. Barrel `package:ghazal_ui/src/inputs/inputs.dart` (exported by `ghazal_ui.dart`). Words live in `l10n_src/inputs.{en,ar}.json` (keys `uiInputs<Component><Element>`), shared words (Optional, Clear, Search, Calendar, Availability ...) come from `common`.

| Group | Widgets |
|---|---|
| Fields | `GzTextField` (`GzFieldDir.auto` / `.ltr`, `clearable`, `loading`, start / end adornments, `forceFocus`), `GzPhoneField` (+965 chip, 4 + 4 mask `GzPhoneMaskFormatter`, `GzPhoneChange`), `GzOtpInput` (`length`, `onCompleted`), `GzSearchField` (`GzSearchSize.sm` 44 / `.md` 48, `gzSearchKey`, `gzMatchesSearch`), `GzTextArea` (`rows`, `maxRows`, `maxLength`) |
| Building blocks | `GzFieldShell` (label, 56 box, hint / error / reason, counter), `GzFieldInput` (the material_ui text field with no decoration, styled by tokens), `GzInAction` (44 dp clear / step action), `GzActivity` (the only looping element), `GzTextController`, `gzTextFieldHost` |
| Choice | `GzStepper` (press and hold), `GzRangeSlider` (`GzRange` record, `onChangeEnd`, `GzRangeEdge`), `GzSegmentedControl<V>` + `GzIconSegmented<V>`, `GzTabs<V>` (`fill` / `hug`) + `GzIconTabs<V>`, `GzChipGroup<V>` (single) and `GzChipGroup<V>.multiple`, `GzToggle`, `GzToggleRow` |
| Pickers | `GzSelectRow<V>` (closed trigger, `values`, `onTap`, `open`; `field` / `row`), `GzPickerList<V>` (the sheet body: search, rows, marks), `GzTimeSlotPicker` (`GzTimeSession`, `GzSessionStatus`), `GzCalendar` and `GzCalendar.range` (`GzCalendarDayInfo`, `GzDayStatus`, `GzDateRange`, `GzYm`, `GzCalendarView`), `GzDateField` / `GzDateField.range` (closed field, `onTap`, `open`) and `GzDateFieldSheetContent` (calendar on a draft + Confirm / Clear) with `gzDateFieldSheetTitle` |

Rules of this group. No sheet is imported: `GzSelectRow` and `GzDateField` only draw the closed state and call `onTap`; the navigation group's sheet host shows `GzPickerList` / `GzDateFieldSheetContent` and passes `open` back. Every text input is the material_ui text field (it needs a Material ancestor: `gzTextFieldHost` supplies a transparent one) with tokens for caret, selection and placeholder, `DigitNormalizingFormatter` on numeric keyboards, autofill hints and IME actions; `dir="auto"` is the first strong letter (an empty field reads left to right, like the browser, so an Arabic placeholder sits at the left), `GzFieldDir.ltr` is an LTR island that starts at the screen start edge (`TextAlign.end` of an LTR line in Arabic). OTP and phone read left to right in both languages; an empty OTP cell holds U+200B so a soft keyboard's Backspace on an empty cell still reaches `onChanged` (walks back). Segmented, icon segmented and icon tabs slide an `AnimatedPositionedDirectional` from the START edge (equal options need no measuring); `GzTabs` measures the active tab after layout (one frame) so `hug` tabs work. The calendar paints the Thu to Sat band as its own layer under the day buttons, so a selected day's 2 dp canvas ring and 1 dp gold ring are never cut by the next row. Implicit animations need a frame to start: in tests `pump()` once, then `pump(duration)` (`test/inputs/inputs_harness.dart` `settle`). The chip group draws its own chip body (`_FigChip`, the `GzChip` anatomy with the label in the figures voice) because `GzChip` takes a plain string.

Parity notes (gallery `inputs`, `node tools/parity/parity.mjs --gallery inputs`; `ghazal_testing/test/gallery/inputs_gallery_test.dart`, file slugs are the web section ids):
- The web hint icon (`gz-field__msg`) hangs from the line top: the margin rule targets a class the icon does not carry.
- A disabled segmented control keeps its selected label (web rule order: the `[data-selected]` colour wins over `:disabled`).
- Text rendered by Flutter sits about 0.5 to 1 dp lower than Chrome inside the same line box; every section shows it.
- Chips (0.083 ar / 0.062 en): the label is the body face (the web `.gz-reset { font: inherit }`, see `gzResetLabelStyle`) with the digit islands at the `body-s` figure size (16 in both languages, `--gz-num-size` survives the reset), padding exactly 16 + 1 per side, so a 3-digit chip is 63.77 dp and four fit a 350 dp row like the web (the earlier version used 17 px digits and a padding tweak to hide it, which put five in a row once the digits were right).

## Navigation, overlays and motion (`ghazal_ui`, F2 group G3)

Source: `design/src/system/nav/**`, `design/src/system/overlays/**`, the device framework `design/src/shell/device/**`, direction section 10, ADR 0017 (motion), 0022 D (routing), 0014 (RTL gestures). Barrels `package:ghazal_ui/src/nav/nav.dart`, `.../overlays/overlays.dart` (exported by `ghazal_ui.dart`). No new words (everything uses `common*`), so there is no `l10n_src/nav.*` or `overlays.*`.

| Group | Widgets and functions |
|---|---|
| Scaffold and bars | `GzScreen` (`child` or `GzScreen.slivers`; `top`, `topOverlay`, `bottom`, `fixed`; one scroller, bars are column children, keyboard shrinks it and spends the bottom inset), `GzTopBar` (`GzTopBarVariant` standard / largeTitle / transparent / search, `GzTopBarBack` auto / show / hide / close, `GzTopBarAction`, `GzTopBarSearch`), `GzBarButton`, `GzTabBar` (`GzTabItem`, `GzTabBadge.count` / `.dot`, `gzClientTabs`, `gzPartnerTabs`, `gzTabsOf`), `GzActionBar` (`GzActionBarAction`) |
| Scopes | `GzAppScope` / `GzAppKind` (client or partner: title faces), `GzScreenScroll`, `GzBottomChrome`, `GzBarInsets` + `GzBarInsetRegistry`, `GzScrollToTopSignal`, `GzScrollBehavior` |
| Navigator contract | `GzNavigator` (push, pop, replace, reset, switchTab, openSheet, openSheetBuilder, closeSheet, openDialog, toast, dismissToast; `canGoBack`, `params`, `currentId`, `activeTab`), `GzNavigatorScope.of` (inert outside a scope), `GzInertNavigator`, `GzNavigatorBase` (the overlay half done on a root `navigatorKey` + `GzToastController`; the go_router adapter implements the stack half and `buildScreen`), `GzSheetOptions`, `GzDialogSpec`, `GzToastSpec` |
| Page transitions | `GzPageTransition`, `GzPageTransitionsBuilder`, `gzPageTransitionsTheme`, `GzPageRoute<T>`, `GzPage<T>` (a Navigator `Page`: `pageBuilder: (c, s) => GzPage(key: s.pageKey, child: ...)`) |
| Overlays | `GzSheet` (container + drag), `showGzSheet<T>`, `GzSheetPage<T>`, `GzSheetRoute<T>`, `GzSheetFooter` (a screen opened as a sheet pins its action row), `GzSheetHeader`, `GzScrim`; `GzDialog`, `showGzDialog`, `GzDialogRoute`; `GzToastHost`, `GzToastController`, `GzToasts.show(context, ...)` / `.dismiss`; `GzBanner`; `GzEmptyState`, `GzErrorState` (`GzErrorKind`), `GzSuccessState`, `GzOfflineState`, `GzStateAction`; `GzPullIndicator`, `GzPullToRefresh`; `GzAccordion` |
| Media | `GzPhoto` (+ `GzPhoto.provider`, `gzResolveImage`, `gzPhotoVariantFor`, `GzPhoto.networkUrl`), `GzPager` (`GzPagerMode`, `gzPagerItemWidth`), `GzPagerProgress`, `GzImageCarousel` (`GzCarouselImage`, `GzCarouselVariant`, `gzGalleryHeroTag`), `GzGalleryViewer`, `showGzGalleryViewer` |

Wiring (integrator): `GzApp.builder` wraps the router in `GzToastHost(controller: toasts, child: ...)` and a `GzNavigatorScope`; `buildGhazalTheme` takes `pageTransitionsTheme: gzPageTransitionsTheme` (replacing `gzPageTransitionsPlaceholder`); router pages are `GzPage`, sheet routes `GzSheetPage`; the tab shell puts `GzTabBar` below a `GzBottomChrome(tabBar: true)` body, sets `toasts.bottomChrome.value` to the bar height while it is visible and `GzScrollToTopSignal` on a re-tap; Android needs `android:enableOnBackInvokedCallback="true"` for predictive back.

Behaviour worth knowing:
- Push is the Ghazal fade + 24 dp travel (the `distancePush` token, not a percentage) over 320 ms on the emphasised curve; the end edge flips in RTL; pop plays it backwards; the covered page travels 24 dp toward inline-start and fades out over an opaque canvas box. Reduced motion: no travel, a 120 ms cross-fade. iOS keeps the Cupertino back swipe (the `cupertino_ui` detector, which mirrors in RTL) and Android keeps predictive back: the platform transition is the carrier and sees the real animations only while a gesture is in progress, so a programmatic push is always the Ghazal one.
- Sheet: rise 320 ms emphasised, leave 200 ms exit curve, drag on the handle or title row, leaves past 30% of its height or 700 dp/s (the settle spring continues the finger velocity), rubber band upward x 0.15, scrim dims with the drag, max 90% of the room above the keyboard, `PopScope` blocks back when not dismissible, Escape and system back close it.
- Toasts: one at a time (a new one replaces it), 200 ms in, 120 ms out, 4 s plain, 8 s undo (the depleting line of `GzUndoBar`); they float 16 dp above the action bar, else the tab bar, else the home-indicator inset. `GzToast.show` of the plan is `GzToasts.show` (an extension cannot add a static to the finished core class).
- `GzPhoto`: `asset://<package>/<path>` becomes `AssetImage('assets/<path>_<480|960>.jpg', package:)` (the mock package declares `assets/images/`), http(s) becomes `NetworkImage('<url>_<480|960>.jpg')` (`GzPhoto.networkUrl` is the one place to change when the CDN differs; the OpenAPI note says `/{width}.webp`), both wrapped in a `ResizeImage` of 2 x the box width; the picture reveals once (480 ms) over the placeholder colour; the hero carousel anchors the picture at inline-start (the prototype's hero box is as wide as the natural ratio at 440 high and clipped at inline-end).
- The gallery viewer expands from the carousel photo with a `Hero` (the flight uses the framework curve, the duration is the 480 ms token); pinch and double tap zoom, the pager and the dismiss gesture step aside while zoomed.

Parity notes (gallery `nav`, `node tools/parity/parity.mjs --gallery nav`; the web crops the 390 frames at its 310 column from the physical left in both languages, the Flutter gallery reproduces that):
- The prototype measures the tab bar item at 60 (glyph box 32 + 4 + a 20 high label line box + 4), not 56; `GzTabBar` follows the measure.
- `proto` (the web prototype player renders the product screens in a bezel; the Flutter twin `NavDemoApp` is a mechanism demo: push and pop, tab bar, sheet, dialog, toast, undo bar, carousel and viewer) and the four `StaticFrame` specimens of `frames` (they render product screens from the inventory) cannot be compared pixel for pixel; the other frames specimens match.
- Icons are one weight: the web tab bar draws the inactive glyph light and the active one regular, the Flutter font has regular only.

## Reading parity scores (measured 2026-10-21, applies to every screen and gallery)

- **Text baseline.** Chrome snaps the baseline inside a line box to a whole pixel: `floor((line - (round(ascent) + round(descent))) / 2) + round(ascent)`. Flutter keeps the fractional value of the same font metrics. Measured with the real fonts and the same roles: Flutter's baseline is 0.1 to 0.9 dp lower than Chrome's (EN: label +0.60, caption -0.02, body-s +0.74, body +0.13, ui-title +0.66, d4 +0.50; AR: label +0.51, body-s +0.55, body +0.90, ui-title +0.63, d4 +0.45), about 0.45 dp on average. Line boxes have the same height. It is below one device pixel at DPR 2 and is not corrected (a global paint shift in `GzText` was judged riskier than the noise it removes); it is why text-dense sections sit at 0.07 to 0.10 with every box in the right place.
- **Mixed font sizes in one baseline-aligned row** (a 15 px name next to a 17 px price) are up to 1 dp taller on the web for the same reason.
- **What the score means.** From `tools/parity/README.md`: a 1 px (0.5 dp) shift scores 0.065, a 1 dp shift 0.10, a 2 dp shift 0.13. So below 0.075 is clean; 0.075 to 0.12 is acceptable when the composite shows only thin outlines along text and no box, icon, colour or size difference; above 0.12, or any visible geometry difference, is a defect to trace.
- **Trace with numbers, not with the eye.** `pnpm probe -- --screen CL-DISC-01 --selector '[data-gz="VenueCard"]' --depth 3` prints the web's computed boxes and styles (x, y, w, h in dp, `r` = distance from the right edge, the number to compare in Arabic); the Flutter side is `tester.getRect(find...)` in a widget test. This found two real bugs at the phase B gate (chip digits at the wrong figure size, a padding tweak hiding it) after the composites alone had been read as noise.

## Known limits (handed to later phases)

Navigation shell (F1d, K1; `packages/ghazal_app_kit/lib/src/nav/`). The apps run on `GzAppRoot` (theme, localisation, `GzAppScope`, `GzFormatScope`, `GzNavigatorScope`, `GzToastHost`) over `routerProvider`, which each app root overrides: `clientRouterOverride({initialLocation})` / `partnerRouterOverride(...)` of `lib/app/app.dart` (pass them to `runGhazalApp(overrides:)`; `ClientApp(router: r)` is a test convenience that installs a prebuilt router for its subtree only). `gzNavigatorProvider` is the `GoRouterNavigator`; a screen reads its own `GzNavigatorScope.of(context)` (params, `currentId`, `canGoBack` of THAT screen), providers read the provider. Routes are the flows' `GoRoute(name: <inventory id>, builder: ...)`: `buildGzRouter` turns a plain `builder:` into `gzScreenPage` / `gzSheetPage` and decides the placement from `kScreenRegistry` (`tab`, `tabBar`, `kind`, the port of `chromeFor` that `tools/gen-routes.mjs` checks against `design/src/system/nav/tabs.ts` on every run): a screen that belongs to a tab and shows the bar lives in that tab's `StatefulShellBranch`; a hidden-bar screen, a screen outside the tabs and every sheet sit on the root navigator above the bar. A flow that writes its own `pageBuilder:` keeps it (call `gzScreenPage(state, child)` or `gzSheetPage(state, child)`). Always navigate through `GzNavigator` (`push`, `pop`, `replace`, `reset`, `switchTab`, `openSheet`...), not `context.pushNamed`: a branch screen pushed with go_router from a screen above the bar would mount the tab shell twice, so the navigator pushes its root twin `<id>@root` then. Rules worth knowing: `push` lands on the ACTIVE tab (a screen of another tab pushed from here keeps this tab highlighted, as in the prototype); `push` of a tab root enters that tab; `reset` drops every other tab stack (each shows its root when next selected); `switchTab` restores the stack, a re-tap pops to the root and bumps that tab's `GzScrollToTopSignal` only; system back on a later tab's root goes to the first tab, on the first tab's root it leaves the app; a screen that is the FIRST route (the shot harness) still reports `canGoBack: true` unless it is a tab root or a sheet, because the web StaticFrame does (the button is inert, pop never leaves a root); a sheet opened by id goes through the router (`GzSheetExtra` carries title, dismissible and scrim), so the Android back and the drag close it; tab badges come from `gzTabBadgesProvider` (`Map<String, GzTabBadge>`, the flows fill it). Not done: `replace` uses the push transition (the prototype cross-fades), a sheet that is not on top cannot be closed by key, and the `refreshListenable` re-evaluates only the redirect rules of `gzRedirect` (first-start screen, partner access), not the gate resume (K2). Stale lines above that still describe the placeholder tab bar, the plain-route sheets and `app_tab_shell.dart` as a placeholder (Folder layout, "Route stubs") are the integrator's to refresh. `flutter_test` draws every shadow as a hard solid shape: a test that must show soft elevation sets `debugDisableShadows = false` BEFORE pumping the frame and back to `true` before the test ends (see `packages/ghazal_testing/test/foundation_gallery_test.dart`); `GzHarness` does not do this yet.

## App state (`apps/*/lib/app/state/`, agent S)

Port of the prototype store (`design/src/shell/state/*`) to hand-written Riverpod 3 `Notifier` / `AsyncNotifier`, one folder per app, no codegen, no import from `lib/features`. Import `package:client_app/app/state/state.dart` or `package:provider_app/app/state/state.dart`. What the prototype kept in browser memory but the real system keeps on the server (wishlist, wedding profile, vouchers, requests, notification read state) goes through the repositories of `ghazal_app_kit`; a draft or UI memory stays in the app. Write actions never throw an `ApiProblem`: they return `ActionResult<T>` (`ActionSuccess(value)`, `ActionFailure(problem)`, `ActionGated()` for a guest at a gate; `.valueOrNull`, `.problem`, `.when(...)`), keep one idempotency key per intent (`IntentKeys`: the key survives a retry, a definite answer starts a new intent), show their key in `state.busy` while they run (`confirm:<id>`), and bump a revision counter afterwards (also on a 409): list providers of the flows start with `ref.watch(clientDataRevisionProvider);` (partner: `partnerDataRevisionProvider`) so they refetch. Money is `MoneyAmount` (fils); never format here. Loading providers are `AsyncNotifier`s, so every screen can use `GzAsyncView`.

**Wiring (integrator).** Pass `clientStateOverrides` (client) / `partnerStateOverrides` (partner) to `runGhazalApp(overrides: [...])`: they make `gzTabBadgesProvider` read the tab badges from this folder. Persisted device state (Brief, wedding draft, guest hearts) lives under `gz.state.*` in shared_preferences and only when the bootstrap passes `loadPreferencesOverride()`.

### Client app

| Provider (state type) | What and one usage line |
|---|---|
| `favouritesProvider` (`AsyncValue<FavouritesState>`: `venue`, `vendor`, `package` id sets, `signupNudge`) | Signed in: the server wishlist; a guest: hearts on the device, merged with `mergeWishlist` at the next sign-in. Optimistic, rolled back on a refusal (`notifier.lastProblem`). `final saved = await ref.read(favouritesProvider.notifier).toggle(SavedType.venue, id);` the third heart of a guest raises `signupNudge` once per device, then `clearSignupNudge()`. `ref.watch(isFavouriteProvider((SavedType.venue, id)))` for the heart. `await notifier.settled` waits for the writes in flight |
| `compareProvider` (`CompareState`: `venueIds`, `isFull`, `canCompare`) | Max `kCompareMax` = 3, local. `notifier.add(id)` returns `CompareResult.added / exists / full`; `replace(old, new)`, `remove`, `clear`, `toggle`, `setAll` |
| `searchBriefProvider` (`SearchBrief`: `date`, `guests`, `audience`, `areaIds`, `budget`, `dateMode`) | The Brief draft, persisted per device. `notifier.update((b) => b.copyWith(guests: 350))`, `set`, `clear`, `fillBlanks(seed)`; `brief.hasQuoteInputs` says a Brief price is possible |
| `weddingProfileProvider` (`AsyncValue<WeddingProfile?>`, null = none yet) and `weddingDraftProvider` (`WeddingProfileInput`) | A guest's onboarding answers go to the draft (device); the first sign-in with no server profile sends it (`putWeddingProfile`) and clears it; either way the blanks of the Brief are filled. `await ref.read(weddingProfileProvider.notifier).save(input)` (create or replace), `.patch(input)` |
| `bookingDraftProvider` (`BookingDraft`: target, venue or provider, hall, session, package, extras, date, audience, guests, `personal`, `requests`, `voucherId`, `quoteId`, `requestId`, `step`) | The request being built (not persisted, cleared at sign-out). `notifier.start(venueId: 'V01', packageId: p)` seeds date, audience, guests from the Brief and name, phone from the session; `patch((d) => d.copyWith(hallId: h))` (`clearVoucher: true` when a quote input changes), `toggleExtra`, `setStep`, `setPersonal`, `reset`. `draft.missing`, `draft.isComplete`, `draft.toCheckoutInput()`, `draft.toCreateRequestInput(voucherId:)` (throws `StateError` when incomplete) |
| `paymentProvider` (`PaymentFlowState`: `outcome` idle / processing / success / failed / cancelled / verifying, `voucherId`, `amount`, `methods`, `paymentId`, `redirectUrl`, `problem`) | The hosted-gateway outcome machine of the KD 2 voucher. The checkout prepares it; `await notifier.begin(GatewayMethod.knet, returnUrl: ...)` opens the session (open `state.redirectUrl`), back from the gateway `await notifier.verify()` polls `getPaymentState` every 2 s (success is never taken from the redirect), `refresh()` is one read, `reset()` stops everything |
| `voucherActionsProvider` (`ActionsState`: `busy`, `lastProblem`) | `checkout()` (the KD 2 voucher for the draft; gate `GateReason.voucher`), `sendRequest()` (R01, draft to `sent`; gate `sendRequest`), `cancelRequest(id)` (R07 withdraw, R10a, R13a by status), `confirm(id)` (R08), `acceptProposal` / `declineProposal` (R05), `askSupportCredit(voucherId)` (no money back), `refresh()` (R09 is a server job: only refetch). `final r = await ref.read(voucherActionsProvider.notifier).confirm(id);` |
| `notificationsProvider` (`AsyncValue<NotificationsState>`: `items`, `unread`, `nextCursor`) and `unreadNotificationsProvider` (`int`) | Empty for a guest without a call. `loadMore()`, `markRead(id)`, `markAllRead()` (optimistic), `refresh()`. `ref.watch(unreadNotificationsProvider)` for the bell |
| `clientTabBadgesProvider` (`Map<String, GzTabBadge>`), `clientActionDueProvider`, `clientUnreadMessagesProvider` | `my-wedding` dot while an approved request waits for the client; `messages` unread count. Installed on `gzTabBadgesProvider` by `clientStateOverrides` |
| `clientDataRevisionProvider` (`int`), `clientUserIdProvider` (`String?`) | The refetch counter and the signed-in client id |

### Partner app

| Provider (state type) | What and one usage line |
|---|---|
| `partnerContextProvider` (`PartnerContextState?`: `accountType`, `role`, `venueId`, `providerId`, `accountName`, `feeExempt`, `permissions`; null when no partner is signed in) | Derived from the session. `ctx.isProvider`, `ctx.targetId`, `ctx.can(PartnerPermission.voucherRedeem)`; show a button from the request's `allowedActions` first. `await notifier.switchTo(accountId, venueId: v)` changes account. `partnerMembershipsProvider` (`AsyncValue<List<PartnerMembership>>`) feeds the switcher |
| `requestActionsProvider` (`RequestActionsState`: `busy`, `lastProblem`, `last`, `canUndo`) | R03 `accept(id, lowerVoucherTotal:)` starts the 8 s undo (`state.last`, `canUndo`; `undoWindowProvider` is the length; the timer commits by itself), `undo()` (R03u, `UNDO_WINDOW_ENDED` after the server window), `commit()`, `decline(id, RejectReason.dateUnavailable)` (R04, not undoable), `proposeDates(id, options)` and `rescheduleTo(id, date)` (R05, 48 h, price held), `cancelByPartner(id)` (R10b revoke for an approved request, R13b for a confirmed one, chosen by status), `checkVoucher(code)` then `redeem(code)` (R11). `final r = await ref.read(requestActionsProvider.notifier).accept(id);` |
| `partnerBadgeCountsProvider` (`AsyncValue<PartnerBadgeCounts>`: `pending`, `awaitingClient`, `unreadMessages`, `danger`), `partnerTabBadgesProvider` (`Map<String, GzTabBadge>`) | From `getPartnerToday`: `bookings` pending count (danger-toned when a waiting request is in SLA danger), `messages` unread. Installed by `partnerStateOverrides` |
| `partnerDataRevisionProvider` (`int`) | The refetch counter (also bumped on a context switch) |

Behaviour worth knowing: an accept or a decline of a request that moved under the screen answers `BOOKING_STATE_CONFLICT` (the lists refetch); only an accept is undoable (api-coverage: decline and propose are not); a stale `version` is read again from the server when the screen does not pass the version of the detail it shows. The mock lists its own permission keys (`request:respond` ...), not the contract's (`booking:approve` ...), so `ctx.can(...)` on contract keys is false against the mock (requests.md): use `allowedActions`. Tests (`apps/*/test/state/`): `StateWorld` (the in-process mock, `fresh()` per test, `FakeNavigator`) and the hero story: Reem requests 14 Jan 2027, the hotel manager sees it pending, accept, undo, forfeit by the clock, decline then credit voucher, redeem.

## Formatting (`ghazal_core`, F1b)

Dart twin of `packages/i18n` (`createFormat`). One object per locale, digit style and clock; same method names as the web `useFormat()`; the same golden cases (`packages/contracts/fixtures/format-cases.json`, 1,963 cases generated by `tools/export-format-cases.mjs` from the TypeScript implementation, run by `packages/ghazal_core/test/gz_format_golden_test.dart`).

```dart
final f = ref.watch(gzFormatProvider);          // GzFormat; rebuilds on locale, digit style or clock change
f.money(18200000)                                // KD 18,200 | ⁦18,200⁩ د.ك   (input is integer fils)
f.moneyOf(const Money.kwd(2000), mode: MoneyMode.exact)
f.moneyParts(5460000, const MoneyOptions(mode: MoneyMode.exact)) // integer, fraction ('.000'), fractionIsZero, currency, amount, text
```

| Group | Methods (all on `GzFormat`) |
|---|---|
| Numbers | `number`, `integer`, `percent`, `numberRange`, `counter`, `pluralCategory`, `plural`, `list`, `digits(String)` (digit style on translated prose) |
| Money (fils) | `money`, `moneyOf`, `moneyParts`, `moneyPartsOf`, `moneySet`, `moneyRange`, `moneyAxis`, `priceUnit`, `flatFee`, `guests`, `minGuests`, `priceForGuests`, `fromPriceMin`; options `MoneyOptions(mode: browse/exact/axis, currency, legal, fullPrecision)` |
| Dates (Asia/Kuwait, fixed +03:00) | `date(d, DateStyle)`, `dateTime`, `time`, `timeRange`, `relativeDay`, `countdownDays`, `daysUntil`, `duration(ms)`, `ago`, `weekdayName`, `monthName`, `weekdayHeaders`, `weekdayLabels`, `monthGrid`, `civil`, `instant`, `kuwaitDate`, `isoDay`, `addDays`; `hijri`, `hijriShort`, `hijriDate`, `dateWithHijri` (Umm al-Qura month table 2025-2037, null outside it) and `hijriShortFromLabel(serverLabel)` |
| Phone | `phone`, `phoneNational`, `normalizePhone`, `isValidPhone`, `e164`, `telHref`, `whatsappHref`; static `PhoneKw.*` |
| Text | `normalizeDigits`, `plain`; top level `isolateLtr`, `plainText`, `kLri/kPdi/kNbsp/kMinus`, `toEasternDigits`, `DigitNormalizingFormatter` (put first in `inputFormatters`) |

`Money(fils, currency)` is exact integer arithmetic (`+ - * compare sum`, `toJson`/`fromJson` with `{fils, currency}`); a non-integer is rejected. Date inputs are an ISO string (a bare `YYYY-MM-DD` is Kuwait noon, a local `YYYY-MM-DDTHH:mm` is Kuwait wall time, `Z` or an offset is absolute), a `DateTime` or epoch milliseconds. `DigitStyle.easternArabic` is honoured in Arabic only and applied last. Western digits are the default in both languages. Call `await initGzIntl()` once in `bootstrap()` (date symbols for `ar` and `en`).

## Core services (`ghazal_core`)

| Name | What |
|---|---|
| `localeProvider` / `LocaleNotifier([forced])` | UI locale: forced arg (tests, harness) > `GZ_LOCALE` (non-prod) > persisted (`gz.locale`) > device language if ar/en > Arabic. `setLocale` persists and emits `language_changed` |
| `digitStyleProvider` / `DigitStyleNotifier` | Eastern-digits switch, persisted (`gz.digit_style`), off by default |
| `clockProvider` | `DateTime Function()`; override with a fixed time in tests and shots |
| `gzFormatProvider` | the `GzFormat` for the three above |
| `sharedPreferencesProvider`, `loadPreferencesOverride()` | persistence is on only when the app bootstrap passes `await loadPreferencesOverride()` to `ProviderScope` (null in tests and shots) |
| `AppEnv` / `appEnvProvider` | `--dart-define` values: `API_BASE_URL` (or `GZ_API_BASE_URL`), `USE_MOCK` (default true), `ENV` (dev/staging/prod), `GZ_LOCALE`, `MOCK_LATENCY_MS` (default 0) |
| `ApiProblem`, `ApiProblemCode`, `ApiFieldError` | RFC 9457 parsing with the stable codes of api-conventions section 5; `messageKey` is the ARB key (`apiErrorSlotUnavailable`) of the user-safe text, `params` fill it; `ApiProblem.offline()` for connectivity |
| `RetryPolicy` | idempotent GET/HEAD/OPTIONS only, network errors and 5xx, max 3, 300 ms doubling with jitter, cap 4 s; `shouldRetry`, `delayFor`, `run` |
| `GzLogger('tag')` | levels, replaceable `GzLogger.sink`; never log personal data |
| `Analytics`, `AnalyticsEvent`, `GzEvents`, `NoopAnalytics`, `RecordingAnalytics`, `analyticsProvider` | ADR 0019 names (snake_case registry); no-op sink until the first-party sink exists |
| `ScreenState<T>` (`ScreenLoading/Data/Empty/Error/Offline`) | `ScreenState.from(asyncValue, isEmpty:)` then `.when(loading:, data:, empty:, error:, offline:)`: every screen handles the five states the same way |
| `parseRichTags(String) -> List<RichPart>` | splits `<f>..</f>`, `<n>..</n>`, `<terms>..</terms>`, `<privacy>..</privacy>` for `GzRich` |

## Localisation

`tools/gen-l10n.mjs` merges `packages/i18n/messages/{en,ar}/<namespace>.json` into ARB files: client_app = `common` + every `client-*` (2,326 keys), provider_app = `common` + every `hotel-*` (2,036 keys), ghazal_ui `GzL10n` = `common` + the parts in `packages/ghazal_ui/l10n_src/*.{en,ar}.json` (218 keys; README there). Placeholder metadata is derived from the ICU AST: plural becomes `int` (decimalPattern), `{x, number}` becomes `num` (decimalPattern), select and plain become `String`. Because gen_l10n has no `#`, a plural count is written `{count}`; Arabic numbers get the same LTR isolate the web formatter adds. Rich-text tags stay literal in the string.

- Read strings: `context.l10n.clientBookingReviewTitle` or `context.l10n.clientBookingReviewGuests(350)` (import `lib/l10n/l10n.dart` of the app); `context.gzL10n.commonActionBack` inside ghazal_ui.
- Prices, dates, times and phones are never formatted in a message: pass `ref.watch(gzFormatProvider).dateTime(...)` as a String argument.
- Known limits of gen_l10n: counts print with intl's decimal pattern (Western digits, comma grouping, ASCII minus), so the Eastern-digits switch does not reach them: wrap the result in `f.digits(text)`. `{x, number, percent}`, selectordinal, plural offset, literal `'`, `{`, `}`, `#` in prose and exact plural values other than `=0 =1 =2` are rejected by the generator.
- Parity with the web: `tools/export-message-cases.mjs` formats a (key, args) table through intl-messageformat (1,734 client, 1,684 provider, 334 ui cases, both languages) into `packages/contracts/fixtures/message-cases.json` and writes `test/l10n_calls.g.dart` per package; `test/l10n_parity_test.dart` asserts the generated classes print the same strings.
- Edit only the JSON in `packages/i18n/messages` (or `l10n_src`); never the `.arb` or `generated/` files. Run `pnpm l10n` after editing, `pnpm l10n:check` before handing back.
