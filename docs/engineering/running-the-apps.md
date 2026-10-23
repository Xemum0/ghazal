# Running the two apps

> Client app `com.ghazal.client` ("Ghazal") and Partner app `com.ghazal.provider` ("Ghazal Partner", hotels, halls and service providers). Both are Flutter 3.47.5 apps over a mock API that implements the whole REST contract, so everything works without a backend. Commands marked "verified at the end" are run for the first time at the final simulator verification (docs/engineering/final-verification.md, step 6); the headless checks (analyze, tests, screenshots) are verified now.

## Prerequisites
Flutter 3.47.5 (Dart 3.13.4), Xcode 26.6 for iOS, Node 22+ and pnpm 10 for the tooling (`pnpm install` once at the repo root), then `pnpm flutter:get`.

## Two ways to run
**1. One app, mock inside the app (default).** Nothing else to start. The app carries the mock backend in-process, with the story clock at 12 Nov 2026 16:00 (Kuwait) so the countdowns match the design.
```
cd apps/client_app      # or apps/provider_app
flutter run -d <simulator id>          # verified at the end
```
**2. Both apps in one world (the story travels between them).** The mock runs as a server on the Mac and both apps talk to it, so a request sent in the Client app shows up pending in the Partner app.
```
cd packages/ghazal_mock_api && dart run ghazal_mock_api:serve --port 4701     # node tools/ports.mjs url api prints the reserved URL
cd apps/client_app   && flutter run -d <iPhone 17e id> --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://127.0.0.1:4701/v1
cd apps/provider_app && flutter run -d <iPhone 17 id>  --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://127.0.0.1:4701/v1
```
(verified at the end; the iOS simulator reaches the Mac at 127.0.0.1, an Android emulator at 10.0.2.2.)

## Accounts of the demo world
| Who | App | Sign in |
|---|---|---|
| Reem Al-Dosari, the hero client (a request for 14 Jan 2027 at Aurelia Gulf Hotel, a wedding profile, favourites) | Client | phone `+96550000012`, code: any six digits |
| Nora Al-Mutairi, a new client with no history | Client | phone `+96550000099`, any six digits |
| Hind Al-Enezi, manager of Aurelia Gulf Hotel (V01) | Partner | `hind@aurelia-gulf.example`, password `Ghazal#2026` or the email code (any six digits) |
Special codes: `000000` is locked, `111111` has expired, `222222` is the wrong code (five wrong codes lock the challenge). More personas (hotel admin, reception, a service provider) are in `docs/architecture/mock-api.md`.

## Demo tools (development builds only)
Five quick taps on the top corner of the screen (the status bar area, at the start edge) open the demo tools: reset the story, switch persona, force a scenario for the next requests (slow, error, offline, empty, expired), move the clock (+1 hour, +24 hours: the 24-hour confirmation window and the forfeit happen on this clock), jump to a story point (pending, approved, confirmed, redeemed, declined, lapsed ...), language and digit style. They work with the in-process mock; with the server, use the control surface (`POST /__mock/...`, documented in `docs/architecture/mock-api.md`).

## Language, direction, text size
Arabic is the default on first run; the language tile of the first screen and Profile switch it live (the whole app mirrors). The Eastern digits switch is in Profile. Text size follows the system setting up to 1.3.

## Checks without a device
```
pnpm flutter:verify          # analyze, rules, every test of every package and both apps
pnpm fshot --app client --screen CL-DISC-01 --lang ar     # a headless screenshot of any screen through the real app (the Partner app: --app provider --screen HL-TODY-01)
pnpm parity -- --app client --screen CL-DISC-01 --lang ar # the screen against the prototype, side by side with the difference (the Partner app: --app hotel)
pnpm flutter:sweep           # every screen, both languages, three widths, text scale 1.3, states
```

## Where things are
`apps/client_app`, `apps/provider_app` (features per flow under `lib/features`), `packages/ghazal_ui` (the design system), `packages/ghazal_app_kit` (router, session, state shell), `packages/ghazal_mock_api` (the mock, the executable spec of the backend), `docs/engineering/flutter-dev.md` (the developer guide), `docs/architecture/backend-handoff.md` (what the NestJS backend must implement).
