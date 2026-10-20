# Flutter build status (ledger)

Plan: `docs/engineering/flutter-build-plan.md`, ADR 0036. Updated by the integrator at every gate. No simulator until the end of F4 (owner instruction 2026-10-20).

Environment verified 2026-10-20: Flutter 3.47.5, Dart 3.13.4, Xcode 26.6 + CocoaPods 1.16.2 (iOS ready), pub.dev reachable, 14 cores, 36 GB. Android: SDK 36.1 present, licences not accepted (owner action: `flutter doctor --android-licenses`). Probe: Riverpod 3.4, go_router 18, material_ui 1.8, flutter_svg, qr_flutter OK; phosphor_flutter fails (not used).

## Phases

| Phase | State | Gate result | Notes |
|---|---|---|---|
| F0 Scaffold | DONE 2026-10-20 (committed; verified by the integrator: flutter:verify green, harness PNGs read) | A: `pnpm flutter:verify` green (analyze, rules, 14 tests); harness PNGs of CL-ONBD-01, CL-DISC-01, HL-ACCS-01, HL-TODY-01 in ar and en read: 780x1688, real Almarai / El Messiri / Manrope, status bar 4:00 and home indicator drawn. B: `pnpm parity:ref` 270 PNGs (135 screens x ar/en, all 780x1688, about 6 min); `tools/parity` self-test holds | A: workspace, six packages, two apps, fonts, guardrail script, 135 route stubs, shot harness, with-slot, root scripts (guide: `docs/engineering/flutter-dev.md`); no simulator used. B: tools/parity/{ref-shots,parity,selftest}.mjs + README; thresholds recalibrated to pass < 0.075, review < 0.12. Prototype issue: HL-GROW-03 logs MissingValueError ("count" not passed to hotelGrowDatesChosen). Non-screen PNGs (diet, illustration, ill_*) sit in design/.shots/ref from earlier work |
| F1a UI foundation | DONE 2026-10-21 (integrator gate passed) | ghazal_ui `flutter analyze` clean; `bash tools/check-dart-rules.sh` ok; ghazal_ui tests green (tokens vs JSON incl. both type sets, theme, GzText/GzNum, GzPressable press + reduced motion + focus + semantics, icons, illustrations); `pnpm tokens:check`, `gen-icons --check`, `export-illustrations --check` ok; foundation gallery (ghazal_testing) rendered in ar and en and read; parity of the colour ramps vs `#/gallery/tokens`: 0.071 ar / 0.062 en (pass), sys roles and type roles aligned crops 0.07-0.10 (text anti-aliasing), illustration sheets 0.01-0.03 against the web gallery | Dart tokens generated into `packages/ghazal_ui/lib/src/tokens/generated/` (old `dist/dart/gz_tokens.dart` removed); `buildGhazalTheme`, `GzTheme` / `context.gz`, `GzText`, `GzNum` / `GzFigures`, `GzLtr`, `GzMotion`, `GzReducedMotion`, `GzPressable`, `GzHaptics`, `GzFadeReveal`; icon font (179 glyphs, no tofu) and `GzIcon`; 60 illustrations x 4 sizes exported and `GzIllustration`; `GzFoundationGallery`. Open: `GzHarness` should set `debugDisableShadows = false` (shadows are hard shapes in tests); page transitions and `GzTabBar` come from the navigation and F2 owners; the web full-page tool stitches wrongly beyond 16384 px |
| F1b Core + l10n | DONE 2026-10-21 (integrator gate passed) | `ghazal_core` (Money, GzFormat 1,963 golden cases, PhoneKw, providers, AppEnv, ApiProblem, RetryPolicy, GzLogger, Analytics, ScreenState), `tools/gen-l10n.mjs`, ARB + `AppL10n`/`GzL10n` (client 2,326 keys, provider 2,036, ui 218), message parity tests (1,734, 1,684, 334) | apps bootstrap must add `initGzIntl()` and `loadPreferencesOverride()` (see requests.md) |
| F1c API + mock | part i DONE 2026-10-20 (API architect; part ii mock server pending) | contract + generated Dart: `node tools/bundle-openapi.mjs --check`, Redocly lint clean, `fixtures-to-wire.mjs --check` (1,513 fixture objects and examples valid), `gen-dart-models.mjs --check`, `gen-coverage.mjs --check` (75 selectors, 47 store actions, 217 operations mapped); `ghazal_domain` 86 tests, `ghazal_api` 23 tests green; analyze clean | `packages/contracts/openapi/ghazal.v1.yaml` (OpenAPI 3.1, 217 operations in 23 tags, 463 schemas, 54 error codes), 322 generated models + 122 enums + 7 sealed variants, 23 repository interfaces and REST implementations, dio client (bearer single-flight refresh, Idempotency-Key, locale and partner headers, GET retry via core `RetryPolicy`, problem+json to core `ApiProblem`); docs `api-coverage.md`, `backend-handoff.md`. Handed to part ii: seeds via `fixtures-to-wire.mjs`, mock control surface in backend-handoff section 8, `ghazal_core` `ApiProblemCode` needs the new contract codes (requests.md) |
| F2 Components | not started | | |
| F3 Screens | not started | | 0 of 135 |
| F4 Integrate (+ simulator at the very end) | not started | | |

## Flow ledger (F3)

Filled by flow agents: flow, screens done / total, parity score (max per flow), flow test, open issues.

| App | Flow | Screens | Parity max | Flow test | Open |
|---|---|---|---|---|---|
