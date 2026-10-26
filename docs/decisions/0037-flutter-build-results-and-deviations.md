# ADR 0037: Flutter build results and deviations from the plan

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-10-26 |
| Scope | What the two Flutter apps are at the end of F3 and F4 (headless phase), what deviated from ADR 0036 and `docs/engineering/flutter-build-plan.md`, which differences from the prototype are accepted and why, and the open items |
| Owner confirmation still needed | None for the deviations below. Owner-side items stay as listed in `docs/engineering/running-the-apps.md` and the hand-over note (pirated archive, Arabic copy reader, legal and tax wording, support staffing, store accounts and SDK keys) |
| Amends | ADR 0036 (adds the parity exceptions, the standalone-mock demo path and the shot persona rule) |
| Related ADRs | 0033, 0035 (voucher model and owner decisions), 0036 (build plan) |

## Context

ADR 0036 fixed how the apps are built: contract-first mock, hand-controlled models, material confined to `ghazal_ui`, a headless parity loop against the prototype, and no simulator until everything else is verified. This record states what was reached and where reality differed.

## Results (2026-10-26)

1. **Screens.** All 134 live screens are built: Client app 83, Partner app 51 (five inventory entries are deprecated by ADR 0033; HL-CALN-05 is built). Each flow has a flow test through the real router and the in-process mock.
2. **Tests.** Every package suite passes when run on its own: client 2,038, provider 1,835, `ghazal_ui` 1,439, `ghazal_testing` 231, `ghazal_app_kit` 89, `ghazal_mock_api` 78, `ghazal_core` 1,986, `ghazal_domain` 86, `ghazal_api` 23 (7,805 tests). The contract checks pass: 16,612 checks, 217 of 217 operations, engine cases 2,170, selector cases 148. Run all suites at once on a loaded machine and the runner may time out; run them one at a time (`docs/engineering/flutter-dev.md`).
3. **Proportions.** Parity against the prototype at 390 wide, bar 0.075: client 67 of 83 screens are under the bar in both languages, 15 are in the 0.075 to 0.12 review band (each with a geometry check showing no band drifting 2 dp or more) and 1 is above (CL-RVRW-01, 0.126 / 0.130: the web decorates reviews with synthetic photos and a stand-in stay date). The partner screens were scored in both languages three times; the remaining scores above the bar are classified below. The component board (95 sections) shows no regression against the end of phase C.
4. **Layout under stress.** The sweep (360, 390 and 430 wide, text scale 1.3) reports no overflow, blank render, stub or framework error on the client app; the partner sweep lists 94 flags, none an overflow (expected empty states, persona and tool limits, state scenarios that do not apply to forms).
5. **Backend hand-off.** `docs/architecture/backend-handoff.md` and `mock-api.md` describe the module map, the rules the mock implements and what it fakes. The contract proposals found during the build are listed in the hand-off (section 10).

## Deviations from ADR 0036 and the plan

1. **Demo tools and the story clock follow the standalone mock.** The plan had the demo tools only in-process. For the two-app story (a request sent in the Client app appears in the Partner app) the apps probe `API_BASE_URL` for `/__mock/state` in development builds (`RemoteMock`, `packages/ghazal_app_kit/lib/src/data/remote_mock.dart`); the clock, persona switch, scenario, story jump and reset then drive the server. A real backend fails the probe and nothing changes; production builds never probe.
2. **Shot persona rule.** A shot or parity run uses the persona of the web frame: Reem for client screens except onboarding and auth, the hotel manager for partner screens except access, the service provider for `HL-PROV-*`, the hotel admin for `HL-SETT-03` and `HL-SETT-05` (`gzShotPersona`).
3. **Names as authored.** The mock answers people's names as authored (Arabic for guests) in both languages, as the web fixtures do; only staff names carry a Latin spelling in English. Latin guest names would need an additive field in the partner request contract (proposed, not made).
4. **Shot settle.** The headless capture waits for skeleton-to-content fades (bounded) so a screen is not scored mid-fade; a screen that never leaves its skeleton is still reported by the sweep.
5. **Plan rates.** Partner plan rates are not decided: the apps show "Rates announced soon" and no number, and payment stays disabled until Super Admin sets rates (ADR 0035). The web frames of HL-PROV-05 and HL-GROW-02/03 hard-code demo prices and drafts; the apps do not copy them.
6. **Parity exceptions are explicit.** A score above the bar is accepted only with a stated cause: the web frame hard-codes data the product must not show, the frame depends on a different persona or story, text anti-aliasing and baseline noise (about 0.02 on text-heavy screens, Chrome snaps baselines to whole pixels), a kit widget with a filed request, or the tool cannot see the difference (text field values). The list is in `docs/engineering/requests.md` and the per-flow rows of `docs/engineering/flutter-status.md`.
7. **Simulator pass done (2026-10-26).** After everything above was proven headless, the single simulator pass ran on the iPhone 17e (client) and iPhone 17 (partner): journeys J1 to J5 in English, Arabic and with the semantics tree on, then the cross-app journeys J6 to J8 against one standalone mock (a request sent in the Client app appears in the Partner app, is accepted, and the client sees Approved, then forfeited after +24 h on the server clock). It found five app bugs no headless run could show, all fixed with regression tests: the keyboard rebuilt the whole screen as it rose and wiped typed text (`GzScreen`, `GzSheetRoute`), two stacked first-run sheets covered the partner tab bar, the chat did not follow a sent message, and two calendar-sheet bugs on the voucher path. An Arabic screen reader crash was traced to a Flutter 3.47.5 semantics bug and avoided by keeping decorative animated transforms out of semantics. Both apps also build a debug APK for Android (no emulator run).

## Open items

- Real SDKs are not in the build: Apple and Google sign-in, biometrics, the map view, push, connectivity. Their screens show the designed states over placeholders.
- Proposed contract additions (additive): send-test-email for calendar sync, `CalendarClaim.batchId`, a gallery video flag for the client, cancelling a planner consultation, a Latin client name on partner requests, a saves tile and deltas on the partner performance tiles. None is implemented in the contract yet.
- The kit widgets named in the open KIT lines of `docs/engineering/requests.md` (voucher card stub gap on CL-PAYM-05, chip group and stepper on CL-WEDD-05, bell badge on CL-MSGS-01, text field label and Arabic value inset on HL-VENU-03) stay for a later pass.
- Three client files exceed the 500-line limit from before this pass (`cl_msgs_02.dart`, `cl_venu_01.dart`, `saved_rows.dart`).
- Brand photographs are bundled from the mock package; the apps need their own asset set before store submission.

## Consequences

The apps can be demonstrated end to end against the mock today and handed to a backend team with the mock as the executable specification. Anything above the parity bar is visible and justified, not hidden. The simulator pass can find device-only issues (keyboard, safe areas, gestures, frame timing); those go back through the flows' fix passes and the gates are re-run.
