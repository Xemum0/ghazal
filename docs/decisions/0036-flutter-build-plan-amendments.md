# ADR 0036: Flutter build plan: amendments to ADR 0021, 0022 and 0025

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-10-20 |
| Scope | How the two Flutter apps are built from the prototype: app names, packages, API client and mock, icons and illustrations, material imports, verification channel |
| Owner confirmation still needed | None. Owner instructions applied: build both apps fully with a mock API that eases the backend; proportions, animation and flow must match the design with no errors or empty screens; no simulator until the very end |
| Amends | ADR 0021 (layout and app names), ADR 0022 (C state/codegen note, B layering and client, F icons, K guardrails), ADR 0025 (golden matrix and the visual loop) |
| Related ADRs | 0020 (NestJS), 0024 (handoff), 0027 (payment launcher), 0028 (auth), 0033 and 0035 (voucher model), 0035 (bundle ids) |
| Plan | `docs/engineering/flutter-build-plan.md` |

## Context

The prototype (134+ screens, tokens, components, fixtures, a TypeScript pricing and booking engine) is complete and reviewed. A probe on 2026-10-20 (Flutter 3.47.5, Dart 3.13.4, Xcode 26.6, iPhone 17 simulator) showed: Riverpod 3.4, go_router 18, `material_ui` 1.8, `flutter_svg` 2.3 and `qr_flutter` 4.1 build and run; **`phosphor_flutter` 2.1.0 does not compile** (Flutter made `IconData` final) and `flutter analyze` does not flag it; `flutter create` still emits framework Material imports; the iPhone 17 is 402x874 logical, so layouts must be fluid, not 390-fixed. ADR 0022 chose a generated dart-dio client behind mappers and Alchemist goldens; the owner now wants a mock that makes the real backend easy and a visual-parity loop that is cheap to run for 135 screens.

## Decision

1. **App names.** `apps/client_app` (`com.ghazal.client`) and `apps/provider_app` (`com.ghazal.provider`), not `hotel_app`: the Partner app serves hotels, halls and service providers (ADR 0035). Screen ids and the `HL-` prefix are unchanged.
2. **Packages.** `ghazal_ui`, `ghazal_core`, `ghazal_domain` (entities and repository interfaces), `ghazal_api` (REST client and repository implementations), `ghazal_mock_api`, `ghazal_testing`. The generated dart-dio `ghazal_api_client` of ADR 0021/0022 is dropped: the Dart OpenAPI generators are the weakest link, and the models are the wire models.
3. **Contract-first with hand-controlled models.** `packages/contracts/openapi/ghazal.v1.yaml` is the source of truth. Immutable Dart models in `ghazal_domain` are generated from its schemas by an in-repo script (no build_runner, freezed or json_serializable, ADR 0022 C stands), double as DTOs and entities, and are checked by contract tests. Mappers are added only where a screen needs a view model.
4. **Mock at the transport layer.** `ghazal_mock_api` is a `shelf` router over an in-memory database with the TypeScript engine ported to Dart, hosted in-process behind a dio adapter (default) or as a standalone server. Header-driven scenarios (latency, error, offline, empty, expired) and a controllable clock (default: the prototype's `2026-11-12T16:00+03:00`). Switching to the real backend changes `API_BASE_URL` and `USE_MOCK` only. ADR 0025's Prism is not used for app flows (it is stateless).
5. **Icons and illustrations.** A generated icon font from `packages/design-tokens/icons` (never `phosphor_flutter`), and the illustration set exported once to SVG assets rendered by `flutter_svg`.
6. **Material confinement.** Only `ghazal_ui` imports `material_ui` and `cupertino_ui`; apps import `ghazal_ui` and `flutter/widgets.dart`. `tools/check-dart-rules.sh` enforces it (ADR 0022 K extended). If a package conflict appears, `ghazal_ui` is the single place that switches to the framework libraries.
7. **Verification channel.** No Alchemist Ahem goldens. A headless harness in `ghazal_testing` renders any screen with the real fonts at a chosen size, locale, text scale and scenario, and a parity script composes prototype, Flutter and difference images with a score (plan section 6). Gate scores and the route sweep replace golden counts. **The iOS simulator is not used until the very end of F4** (owner instruction): it runs only the final journeys and spot screenshots.
8. **Concurrency.** Test and shot runs go through a counting semaphore (4 at a time); dependencies, the route table and the router composition are frozen at scaffold.

## Consequences

- Backend work is unblocked: the OpenAPI file is the contract, the Dart handlers are a readable executable spec of pricing, availability and the booking and voucher transitions, and the apps do not change when the real API arrives.
- One transport boundary means error, offline, empty and slow states can be produced on demand in tests and in the demo tools, which is how "no blank screens" is verified.
- A hand-run generator for models replaces an off-the-shelf one: more of our code, fewer surprises.
- No simulator feedback until the end means motion and platform behaviour are verified last; the plan therefore defines motion by tokens and widget-level tests, and reserves the final phase for the on-device check.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Keep `phosphor_flutter` | does not compile on Flutter 3.47.5 |
| Generated dart-dio client from OpenAPI | weak generators, built_value and build_runner, mappers for no benefit while we control the models |
| Prism or a static JSON mock | stateless: cannot show approval, voucher lifecycle or cross-screen state |
| Mock inside each repository | different code path from the real backend; the swap would touch every repository |
| Alchemist Ahem goldens as the gate | squares instead of text: useless for Arabic shaping and for proportion review |
| Simulator-driven development loop | slow, one device at a time, and the owner asked to hold it until the end |
| Framework `material.dart` imports in apps | spreads a deprecated import across 140 screens; one confined package is cheaper to migrate |

## Related requirement IDs

| ID | Effect |
|---|---|
| PL-ARCH-01, PL-ARCH-02, CF-01 | Four products on one backend; Flutter apps |
| NF-LOC-01..07 | Locales, mirroring, digits, formatter (shared golden cases) |
| NF-COMP-01, NF-COMP-02 | iOS 15 floor, Android minSdk 26 (ADR 0022) |
| NF-DEL-01 | Designs delivered; the apps are built from them |
