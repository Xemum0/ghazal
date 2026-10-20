# ADR 0022: Flutter architecture: SDK pins and floors, Riverpod, go_router, ARB localisation, token theming, images

| Field | Value |
|---|---|
| Status | accepted; partially superseded: D tabs by 0007 D1, E money string by 0010 D7; item A (iOS 15.0) is proposed-needs-owner until OQ-T-02 and CF-35 are signed |
| Date | 2026-10-12 |
| Scope | `apps/client_app`, `apps/hotel_app`, `packages/ghazal_*`: platform floors, layering, state, routing, localisation, theming, images and performance, platform services, accessibility, flavors, guardrails |
| Owner confirmation still needed | OQ-T-02 (iOS 15.0 and Android minSdk 26, registered as CF-35 and signed off by the owner), OQ-T-06 (bundle ID prefix and domain), OQ-T-03 (store accounts) |
| Deviation from the PRD | NF-COMP-01 says iOS 14+; this ADR sets iOS 15.0 (CF-35). NF-COMP-02 (Android 8, API 26) is unchanged but made explicit |
| Related ADRs | 0007 (tabs and guest gating), 0010 and 0011 (formatter and calendar config), 0012 (phone), 0014 (directional widgets), 0016 (fonts), 0017 (motion), 0021 (workspace), 0023 (tokens), 0024 (handoff), 0025 (tests), 0027 (payment launcher), 0028 (auth) |

## Context

The PRD fixes Flutter for both mobile apps (CF-01) and a 2-second home load (NF-PERF-01), iOS 14+ and Android 8+. Verified on 2026-10-10 by running the toolchain:

- **Flutter 3.47.5 / Dart 3.13** is current stable; `flutter create` emits `IPHONEOS_DEPLOYMENT_TARGET = 15.0` and `minSdk 24`. iOS 14 and iOS 15 support exactly the same hardware (iPhone 6s and later), so raising the floor excludes no device. Pinning Flutter 3.44 to keep iOS 14 buys a stale SDK and Xcode 27 UIScene problems for no user benefit.
- Flutter 3.47 split Material and Cupertino into standalone packages (`material_ui` 1.6.0, `cupertino_ui` 1.1.2); the in-framework libraries are deprecated in the November 2026 stable. The analyzer does not yet flag the old imports, so a grep gate is needed. The packages release weekly.
- Riverpod 3 retries any error by default (200 ms doubling to 6.4 s), which is dangerous for non-idempotent calls; offline persistence and mutations are still experimental. Codegen (freezed, build_runner) is the main source of merge conflicts for parallel agents.
- The Dart OpenAPI generator ecosystem is weak (dart-dio is stable but built_value-based; native-Dart generators are immature), so generated code must be walled behind mappers.
- Web and Flutter disagree on defaults: Dart `ar` gives Western digits; Chrome `ar-KW` gives Eastern digits; both treat the Arabic week as Saturday-first (ADR 0010, ADR 0011).
- Poppins has no tabular figures (ADR 0016); Material's `ColorScheme.fromSeed` would drift off-brand.
- The 2-second budget needs one composed home endpoint, stale-while-revalidate, pre-generated WebP variants with blurhash, a native HTTP stack (`dart:io` is HTTP/1.1 only) and lazy Firebase initialisation.

## Decision

**A. Platform floors and SDK policy.** Pin Flutter 3.47.5 / Dart 3.13 (`flutter: '>=3.47.5 <3.48.0'` in pubspec and CI); upgrade quarterly, never in a build week. iOS deployment target 15.0: a deviation from NF-COMP-01 registered as CF-35 and needing owner sign-off (OQ-T-02); pinning Flutter 3.44 to keep iOS 14 buys a stale SDK and zero extra devices and is rejected. Android minSdk 26 set explicitly (matches NF-COMP-02; Flutter's default is 24), compile/target per Flutter (36), Java 17+. Use the template's UIScene lifecycle and SwiftPM-capable plugins. Use `material_ui` and `cupertino_ui` from the first commit, run `dart fix --apply --code=migrate_design_widgets` after every `flutter create`, and ban `package:flutter/material.dart` and `package:flutter/cupertino.dart` in `tools/check-dart-rules.sh` (the analyzer does not flag them yet). Pin both packages (weekly releases); avoid third-party widgets that expose Material types.

**B. Layering.** Each app: `lib/{main,bootstrap}.dart`, `lib/app/{app.dart,router/app_router.dart,theme/}`, `lib/features/<feature>/{presentation,application,domain,data,<feature>_routes.dart}`, `lib/l10n/`, `test/`, `integration_test/`, `goldens/`, `config/env.{dev,staging,prod}.json`. Shared packages: `ghazal_ui` (theme, tokens, `Gz*` components, icon font, fonts, transitions, haptics, `@Preview`s), `ghazal_core` (Money, GzFormat, PhoneKw, digit normaliser, AppEnv, logger, analytics interface, ApiProblem, retry policy), `ghazal_auth` (ADR 0028), `ghazal_chat`, `ghazal_api_client` (generated dart-dio, never hand-edited), `ghazal_testing`, `ghazal_lints`. Data flow: Widget -> Notifier/AsyncNotifier -> repository interface (domain) -> repository impl (data) -> generated DTO -> mapper -> hand-written immutable entity with `equatable`. Mappers are the anti-corruption layer; generated types never reach UI. Features are also the ownership partition: client = auth, onboarding, home, search, venue, compare, booking, payment, bookings, planner, services, planning, chat, notifications, reviews, profile; hotel = today, bookings, calendar, venue_management, offers, analytics, notifications, settings, chat.

**C. State.** Riverpod 3.4 with hand-written `Notifier`/`AsyncNotifier`, `riverpod_lint` through the analyzer plugin system. No riverpod_generator, freezed, json_serializable or build_runner in the apps (build_runner exists only to regenerate `ghazal_api_client`, outside the apps). Global retry policy in `ghazal_core`: only idempotent GETs, only on network errors and 5xx, max 3 with backoff; POST/PATCH/DELETE, OTP, booking creation and payments never auto-retry (a user-initiated retry reuses the same Idempotency-Key). Riverpod offline persistence and mutations are experimental and unused. No local database in the MVP: `dio_cache_interceptor` file store for GET caching, `shared_preferences` for compare tray, onboarding, locale and digit style. Drift only through a new ADR if offline chat or calendar becomes a requirement.

**D. Routing.** go_router 18; one `<feature>_routes.dart` per feature exporting `List<RouteBase>`; `app_router.dart` only composes them (one line per feature, all lines created at scaffold, so effectively frozen). Tabs use `StatefulShellRoute.indexedStack` (client: Discover, Saved, My Wedding, Messages, Profile per ADR 0007 D1; hotel: Today, Bookings, Calendar, Messages, More). Typed route helpers are hand-written (`Routes.venue(id)`), not go_router_builder. Guest gating (CA-AUTH-09/10): a `redirect` stores a `GuestIntent` (route, step, params) and resumes it after login/OTP; the server codes `AUTH_REQUIRED` and `PHONE_VERIFICATION_REQUIRED` trigger the same path. One `GhazalPageTransitionsBuilder` reads `Directionality` (24% travel + fade, `motion.duration.slow`, emphasised curve); iOS keeps the Cupertino interactive back swipe (it flips in RTL by itself); Android enables predictive back. Deep links: one host `link.<domain>` with `/c/*` (client) and `/v/*` (hotel), AASA and assetlinks from `infra/well-known/`; push taps and payment returns use the same HTTPS links.

**E. Localisation, RTL, numerals (NF-LOC-01..07).**

- `supportedLocales`: `ar`, `en` (ar_KW has no distinct intl data). Runtime switch without restart through a persisted `localeProvider`; the theme is rebuilt on change. First launch: device language if ar or en, otherwise Arabic; asked again in onboarding.
- gen-l10n: template `app_en.arb`, output `lib/l10n/generated`, class `AppL10n`, no synthetic-package. ARB is authored as per-feature parts in `packages/i18n/messages/{common,client,hotel,server}/<feature>.<locale>.json`, merged by script into `apps/*/lib/l10n/app_{en,ar}.arb` (committed). Keys are camelCase `<feature><Screen><Element>`; the English part carries descriptions and placeholder metadata, the Arabic part only strings. CI parity: identical keys and placeholders; every Arabic plural has one/two/few/many/other (=0 optional); no Latin letters in Arabic strings except an allow-list (KWD, brand names); no hardcoded digits in prose; warn when len(ar)/len(en) > 1.6. The same strings render identically in the prototype through intl-messageformat 12.
- Numerals: Western digits by default in both languages (CF-11). `DigitStyle { western, easternArabic }` is a persisted setting applied only by `GzFormat` after formatting (dates and times too). Inputs normalise Arabic-Indic and Persian digits to ASCII through one `TextInputFormatter`. The prototype uses `ar` with `-u-nu-latn`, never an ar-KW tag; `snap.mjs` currently launches Playwright with locale ar-KW and must change to `ar`.
- Money: `Money(fils:int, currency)` in `ghazal_core`; `GzFormat.money` returns bidi-safe text (whole amount isolated with U+2066/U+2069), 'KD' in consumer English ('KWD' only on invoices, receipts, payout settings and the API; ADR 0010 D7) and 'د.ك' in Arabic, three decimals on booking/payment/invoice/balance surfaces and whole dinars on browse surfaces when fils are 000. Shared cases in `packages/contracts/fixtures/format-cases.json` are asserted by both TS and Dart tests.
- Calendar: the week starts Sunday as explicit config (`GzCalendar` and the prototype), never read from the locale (intl says Saturday). Weekend and peak days come from the venue/API. Hijri is never computed on the client: the API sends holiday labels and Hijri pairs where pricing depends on them (moon sighting moves Ramadan and Eid).
- Phones: Kuwait shape check `[2569]xxxxxxx` or `41xxxxxx` after +965, display grouping 4+4 (+965 5123 4567), always LTR inside RTL layouts. No libphonenumber isValid (it rejects real Kuwaiti numbers); WhatsApp delivery is the real validation.
- Native strings: `ar.lproj`/`en.lproj` InfoPlist.strings (Face ID, location, camera, photos, microphone), `CFBundleLocalizations`, Android `locales_config.xml`.

**F. Theming from tokens (ADR 0023).** `buildGhazalTheme(Locale)` builds an explicit `ColorScheme` from sys tokens (never `fromSeed`), M3 with overrides, `NoSplash` plus token-driven press feedback (scale 0.98, 120 ms), standard density, padded tap targets, the transitions builder, a `textTheme` from the locale's typography tokens, and `ThemeExtension`s (`GzColors` with copyWith/lerp). Widgets read semantic tokens only. Light theme only for MVP. Every generated TextStyle sets `leadingDistribution: even` and an explicit height; Arabic sets letterSpacing 0 and is never italic. Hairline = 1 dp. Focus ring: 2 px gold-ink outside the bounds. Fonts are bundled static subsets (Cairo 400/500/600/700, Arabic + Latin, about 65 KB each; Poppins Latin about 14 KB each): Arabic UI = Cairo only, English UI = Poppins with Cairo fallback, and a `numeric` role in Cairo digits for aligned figures (prices, calendar, counters, tables). No google_fonts runtime fetch.

**G. Images, performance, maps (NF-PERF-01/02).** Budget: cold start to first meaningful home content <= 2.0 s p75 on a mid-range Android at 10 Mbps / 100 ms RTT (the matrix working call), warm start <= 800 ms, one extra check at 1.6 Mbps / 150 ms. A skeleton does not count as loaded; a blurhash-tinted card with real title and price does. Instrument with `reportFullyDrawn()`, a `home_ttfmc` event and a nightly profile-mode drive.

- One composed `GET /v1/home` <= 30 KB gzip; stale-while-revalidate (paint the last cached payload, refresh behind it).
- Variants generated at upload by a job: WebP at 320/640/960/1440, content-hash file names, immutable cache headers, GCS + Cloud CDN; AVIF is not used (decode support is uneven). Blurhash 4x3 plus aspect ratio stored per image and delivered as descriptors `{id, blurhash, aspect, baseUrl}`. Card thumbnails <= 40 KB at 2x.
- Flutter: `cached_network_image` with `memCacheWidth` = 2x display width, `precacheImage` for the first two rows only, fixed `AspectRatio` boxes (no layout shift), 200 ms reveal from the blurhash, builder slivers.
- Maps: never a live map in a list. Details shows a pre-rendered, brand-styled static tile plus 'Open in Maps'; interactive google_maps_flutter only on a dedicated full-screen route. Area selection uses a curated Kuwait areas list with aliases, not Places Autocomplete. Location is requested when-in-use, in context.
- Video: short muted H.264 MP4 loops (<= 15 s, 720p) on cards and hero, derived server-side from uploads of up to 60 s and 100 MB (OQ-T-15); the full video plays only on details or after scroll settles.
- HTTP and startup: dio 5 with `native_dio_adapter` (HTTP/2, HTTP/3 through system stacks); minimal `main()`, native splash until first frame, Firebase/FCM/analytics initialised after first frame, SharedPreferences preloaded, release builds with `--obfuscate --split-debug-info`.

**H. Platform services.** FCM + flutter_local_notifications; Android channels `bookings`, `messages`, `offers`, `reminders`; the notification permission is requested after the first booking request (moment of value), not at launch. The hotel app's new-request push is iOS time-sensitive with badge = pending count (Critical Alerts are not planned). The server localises push from the saved locale and sends `data.link`. A thin `Analytics` interface in `ghazal_core` (sink: Firebase Analytics, event schema in `packages/contracts`) covers NF-ANL-01..05; Crashlytics receives symbols from CI.

**I. Accessibility.** Semantics with ARB labels on every interactive widget, `ExcludeSemantics` for decorative imagery, `SemanticsService.announce` on booking-status changes, targets >= 44 dp (48 for primary), layouts that survive 200% text scale, `MediaQuery.disableAnimationsOf` mapped to reduced motion.

**J. Flavors.** dev/stg/prod for each app. Bundle IDs `<prefix>.client[.dev|.stg]` and `<prefix>.venue[.dev|.stg]` (prefix from OQ-T-06). Public config through `--dart-define-from-file=config/env.<env>.json`; `GZ_LOCALE=ar|en` is honoured in non-prod flavors only; `flutterfire configure` per flavor (outputs committed, they are not secrets).

**K. Guardrail script** `tools/check-dart-rules.sh` fails on: the two banned imports; `Color(0x` or `Colors.` outside `lib/src/tokens/generated/`; `EdgeInsets.only(left|right`, `Alignment.centerLeft|centerRight`, `Positioned(left|right`, `TextAlign.left|right`; string literals passed to `Text(` outside tests and l10n; `letterSpacing` in Arabic-capable styles; cross-feature imports.

## Consequences

- No build_runner in the apps keeps parallel agents from colliding and keeps loops fast.
- The prototype and the apps share ARB strings, fonts, fixtures and format cases, which removes a whole class of AR/EN drift.
- Material/Cupertino migration risk is paid once, at the start.
- iOS 14 is dropped (CF-35): owner sign-off required, and the digest and NF-COMP-01 note must say so.
- Hand-written entities, mappers and routes cost typing time; accepted for merge safety.
- Riverpod 3 and material_ui/cupertino_ui are young: pin exact versions and upgrade deliberately.
- A numeric role in Cairo digits next to Poppins text must be checked visually in English by the design-system owner (ADR 0016 test).
- Hijri and weekend rules stay server-driven, so the API must ship holiday labels with pricing calendars.
- Firebase Auth is not used: sessions are backend JWTs (ADR 0028), so `firebase_core` is only for FCM, Analytics and Crashlytics.
- The payment screen uses a `PaymentLauncher` interface (default `flutter_web_auth_2`) and never a card form (ADR 0027).

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Pin Flutter 3.44 to keep iOS 14 | Stale SDK, Xcode 27 UIScene problems, zero extra devices |
| In-framework Material and Cupertino | Deprecated in the November 2026 stable; migration paid once now |
| Riverpod with riverpod_generator, freezed, json_serializable | build_runner conflicts and slow loops for parallel agents |
| `go_router_builder` typed routes | Needs build_runner; hand-written `Routes.venue(id)` |
| A local database (Drift) in the MVP | No offline requirement yet; HTTP cache plus `shared_preferences`; Drift only via a new ADR |
| Generated DTOs used directly in UI | The generator is the weakest link; mappers are the anti-corruption layer |
| `ColorScheme.fromSeed` | M3 tonal palettes drift off-brand; explicit scheme from tokens |
| `google_fonts` at runtime | Offline, cost, flash of fallback text against the 2-second target |
| AVIF images | Decode support is uneven on Flutter devices; WebP |
| `myfatoorah_flutter` SDK in the app | The SDK needs the API key in the app; server-created sessions instead (ADR 0027) |
| Material and Cupertino date pickers | Digits, week start and Hijri line must stay under the formatter (ADR 0011) |
| Auto-retry of every error | Dangerous for payments, OTP and booking creation; global policy limits retries to idempotent GETs |

## Related requirement IDs

| ID | Effect |
|---|---|
| PL-ARCH-02, CF-01 | Flutter from a single codebase per app |
| NF-COMP-01, NF-COMP-02, CF-35 | iOS floor 15.0 (deviation) and Android minSdk 26 |
| NF-LOC-01..07 | Locales, mirroring, calendar config, digits, formatter, runtime switch, bilingual content |
| NF-PERF-01, NF-PERF-02 | 2-second budget and image and cache strategy |
| PL-ARCH-09 | Push through FCM |
| NF-ANL-01..05 | `Analytics` interface (ADR 0019) |
| CA-AUTH-08, CA-AUTH-09, CA-AUTH-10 | Biometric unlock, guest browsing, guest intent resume (ADR 0028) |
| NF-DSN-08, NF-DSN-09 | Contrast through tokens; one component library |

## Notes on conflicting inputs

- **Tabs.** Item D lists the client tabs as 'Discover, Compare/Planner, Plan, Messages, Profile' (the brief's hypothesis, copied from the research). ADR 0007 D1 replaced it: Discover, Saved, My Wedding, Messages, Profile. ADR 0007 owns navigation; the router follows it.
- **Currency in English.** Item E says `GzFormat.money` returns 'KWD' in English. ADR 0010 item 7 writes `KD` on consumer English surfaces and `KWD` only on invoices, receipts, payout settings, the gateway hand-off and the API. ADR 0010 owns number and currency strings.
- **Poppins weights.** Item F bundles Cairo 400/500/600/700 and Poppins 'about 14 KB each' without listing weights; ADR 0016 item 1 bundles Poppins 400/500/600. Use ADR 0016 for the font list.
