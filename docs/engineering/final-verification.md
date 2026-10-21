# Final verification (F4): what "done" means for the two Flutter apps

> The owner asked for two Flutter apps (client, hotel and service providers) with a mock API that makes the backend easy, proportions exactly suited to the design, animation and UX as designed, and "no errors or issues with flow and smoothness and empty screens". This is the checklist that proves it, in the order it is run. No simulator or emulator until step 6 (owner instruction, 2026-10-20).

## 1. The gate (every phase, and again at the end)
`pnpm flutter:verify` (analyze, rules, every test of every package and app), `pnpm verify` (web: typecheck, lint, tokens, i18n, contracts), `pnpm l10n:check`, `node tools/gen-routes.mjs --check`, `node tools/contract-test.mjs` (217 of 217 operations), the mock equality suites (engine 2,170 cases, selectors 148 cases). Nothing proceeds on red.

## 2. Screens exist and say what the prototype says
- `pnpm flutter:edges`: no stub, every `navigatesTo` edge of the inventory wired, every screen reachable from the entry screens.
- `pnpm flutter:sweep` (layout at 360 / 390 / 430, text scale 1.3, tall content, scenario states): zero framework errors, zero overflow, zero blank renders, no screen stuck on its skeleton, no error state where data was expected, content coverage of every screen and language at 97 % or more (the excused data differences are listed in `docs/architecture/mock-api.md` "Known differences from the web").
- Every state of the inventory has a frame (loading, empty, error, offline, guest) or a flow test that proves it.

## 3. Proportions
- Parity against the prototype render of all 135 screens in Arabic and English: below 0.075 clean; 0.075 to 0.12 only with a geometry diff (`pnpm parity:geo`) that shows no band drifting by 2 dp or more; above 0.12 none, except the documented ones (photo resampling, a Chrome flex quirk, a placeholder). The component galleries (`pnpm parity:board`) hold the same bar.
- At 360 and 430 the layout stays fluid (gutter 20) with no clipped text.

## 4. Flow, smoothness, no empty screen
- One flow test per flow through the real router and the in-process mock (all green), each covering the main path with real taps, the five states, the guest gate, back and sheet dismissal, one Arabic run.
- The hero story end to end in the mock: the client requests 14 Jan 2027 at Aurelia, the hotel manager sees it pending, accepts (8 s undo), the client confirms inside 24 h, the voucher is redeemed; and the lapse (forfeit by the clock), decline, counter-offer, revoke paths (`packages/ghazal_mock_api/test/lifecycle_test.dart`).
- Motion list (flutter-build-plan section 7) present: press, thread draw-on, sheets, page push / pop in both directions, shared-element gallery, favourite pop, tray insertion, skeleton to content, success draw, countdown states; reduced motion respected.

## 5. The backend hand-off
`docs/architecture/backend-handoff.md` and `mock-api.md` current: every OpenAPI tag mapped to a NestJS module, the rules the mock implements (the Dart handlers are the readable executable spec), what is faked (OTP outbox, payment gateway, push, media upload, support staffing), the contract tests and case files a backend must pass (`engine-cases.json`, `selector-cases.json`, `contract-test.mjs`).

## 6. The simulator (the only time it is used, after 1 to 5 are green)
Environment: Xcode 26.6, iPhone 17e (390 x 844) and iPhone 17 (402 x 874), both shut down until now. Build both apps for the simulator, run the standalone mock (`dart run ghazal_mock_api:serve`, node tools/ports.mjs url api) and start both apps against it (`--dart-define=USE_MOCK=false --dart-define=API_BASE_URL=<url>/v1`; Reem signs in with `+96550000012` and any six digits except 000000 / 111111 / 222222, the hotel manager with `hind@aurelia-gulf.example` and `Ghazal#2026`). Journeys as integration tests: J1 client first run (language, onboarding, home, results, venue, gate, OTP, voucher checkout, request sent), J2 partner (sign in, Today, accept, undo window), J3 client (confirm inside 24 h, the booking thread), J4 partner (redeem by code), J5 both apps in Arabic and English (every tab, every sheet type, RTL swipe-back, keyboard, scroll). Spot screenshots of each on both devices; frame timing on the heavy lists (home, results, calendar). Anything found goes back to the flow's fix pass, then steps 1 to 4 again.

## 7. Android
Compile check only (`flutter analyze` is part of the gate; a debug `flutter build apk` if the toolchain allows): the back gesture manifest flag, portrait lock, icons and launch screen exist; no emulator.

## 8. Hand-over
`docs/engineering/running-the-apps.md` (modes, accounts, demo tools, commands), `docs/engineering/flutter-status.md` (ledger complete), an ADR recording the build results and deviations, `docs/engineering/STATUS.md`, the owner-side list (delete the pirated archive, Arabic copy reader, legal wording, store accounts, real SDKs: Apple / Google sign-in, local_auth, maps, push, connectivity), cleanup of debug output, one final commit.
