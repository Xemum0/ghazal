# Flutter build status (ledger)

Plan: `docs/engineering/flutter-build-plan.md`, ADR 0036. Updated by the integrator at every gate. No simulator until the end of F4 (owner instruction 2026-10-20).

Environment verified 2026-10-20: Flutter 3.47.5, Dart 3.13.4, Xcode 26.6 + CocoaPods 1.16.2 (iOS ready), pub.dev reachable, 14 cores, 36 GB. Android: SDK 36.1 present, licences not accepted (owner action: `flutter doctor --android-licenses`). Probe: Riverpod 3.4, go_router 18, material_ui 1.8, flutter_svg, qr_flutter OK; phosphor_flutter fails (not used).

## Phases

| Phase | State | Gate result | Notes |
|---|---|---|---|
| F0 Scaffold | DONE 2026-10-20 (committed; verified by the integrator: flutter:verify green, harness PNGs read) | A: `pnpm flutter:verify` green (analyze, rules, 14 tests); harness PNGs of CL-ONBD-01, CL-DISC-01, HL-ACCS-01, HL-TODY-01 in ar and en read: 780x1688, real Almarai / El Messiri / Manrope, status bar 4:00 and home indicator drawn. B: `pnpm parity:ref` 270 PNGs (135 screens x ar/en, all 780x1688, about 6 min); `tools/parity` self-test holds | A: workspace, six packages, two apps, fonts, guardrail script, 135 route stubs, shot harness, with-slot, root scripts (guide: `docs/engineering/flutter-dev.md`); no simulator used. B: tools/parity/{ref-shots,parity,selftest}.mjs + README; thresholds recalibrated to pass < 0.075, review < 0.12. Prototype issue: HL-GROW-03 logs MissingValueError ("count" not passed to hotelGrowDatesChosen). Non-screen PNGs (diet, illustration, ill_*) sit in design/.shots/ref from earlier work |
| F1a UI foundation | not started | | |
| F1b Core + l10n | not started | | |
| F1c API + mock | not started | | |
| F2 Components | not started | | |
| F3 Screens | not started | | 0 of 135 |
| F4 Integrate (+ simulator at the very end) | not started | | |

## Flow ledger (F3)

Filled by flow agents: flow, screens done / total, parity score (max per flow), flow test, open issues.

| App | Flow | Screens | Parity max | Flow test | Open |
|---|---|---|---|---|---|
