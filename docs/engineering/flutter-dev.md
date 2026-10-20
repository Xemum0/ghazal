# Flutter development guide (workspace, harness, rules)

Plan: `docs/engineering/flutter-build-plan.md`; decisions: ADR 0022 as amended by ADR 0036. No simulator or emulator until the very end of F4 (owner instruction): verify with `flutter analyze`, `flutter test` and the headless shot harness only. Never run `flutter run` or `flutter build ios`.

## Commands (repo root)

| Command | What it does |
|---|---|
| `pnpm flutter:get` | `flutter pub get` for the whole workspace (also regenerates the l10n Dart files) |
| `pnpm flutter:analyze` | `flutter analyze` over every member (one `analysis_options.yaml` at the root) |
| `pnpm flutter:rules` | `tools/check-dart-rules.sh` (add `--fix-hints` for the remedy of each rule, or pass paths) |
| `pnpm flutter:routes` | `node tools/gen-routes.mjs` (route stubs, router composition, screen registry; `--check` fails when stale) |
| `pnpm flutter:test` | `flutter test` in every member with a `test/` folder, concurrently, through `tools/with-slot.mjs` (4 slots) |
| `pnpm flutter:verify` | analyze + rules + test |
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
packages/ghazal_core         locale provider now; Money, GzFormat, env, errors, retry in F1b (Flutter package: Riverpod, shared_preferences)
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
4. Strings: add the keys to your flow's ARB inputs under `packages/i18n/messages/**` (merged into the app ARB by the l10n script, F1b) and read them through `AppL10n.of(context)`; never a literal in `Text(`, never a hand-typed price or date (`useFormat` equivalent: `GzFormat`, F1b).
5. `pnpm fshot --app <client|provider> --screen <ID> --lang both`, Read the Arabic PNG, compare with the prototype shot, then `pnpm flutter:verify`.
6. Need a token, component or dependency: append one line to `docs/engineering/requests.md` with `>>`. Nobody runs `pub add`.

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

## Known F0 limits (handed to later phases)

The theme and tokens in `ghazal_ui` are placeholders (`lib/src/tokens/placeholder_tokens.dart`, `buildPlaceholderTheme`) until F1a; `packages/design-tokens/dist/dart/gz_tokens.dart` imports `flutter/material.dart` (`ThemeExtension`) and uses family names with spaces, so the F1a generator change must switch it to `material_ui` / `ElMessiri` before it moves into `ghazal_ui`. The tab bar is `GzStubTabBar`. `localeProvider` has no persistence yet. The l10n ARB files hold one stub key each (F1b merges the real strings).
