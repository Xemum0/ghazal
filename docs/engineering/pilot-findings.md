# F3 pilot findings (2026-10-21)

> Four agents built 37 screens (client onboarding + auth, discover, booking; partner access + today) through the real router and the in-process mock. 90 flow tests pass, parity at 390 is 0.03 to 0.11 for most screens and content coverage 80 to 100 %. What they found wrong in the process is below, with the owner and where it is fixed. The main wave (the other 98 screens) starts when the rows marked "before the main wave" are done.

## Process and tools (integrator, done 2026-10-21)
| Finding | Fix |
|---|---|
| fshot printed only the last 80 lines; the first exception was cut | prints the first exception block, keeps `<out>/fshot.log` |
| `--state error` / `--offline` stayed on the skeleton and failed with "A Timer is still pending" (dio retry timers outlive the 1.8 s pump) | `gzRetryPolicyProvider`, shots run with `RetryPolicy.none`: the state shows at once, no timer |
| the hero story points (approved, confirmed, lapsed ...) and route params could not be opened by fshot | `--story <point>` (MockControl.jumpToStory) and `--params '{json}'` (route extra); the label carries `.story-<point>` |
| a hung test held a semaphore slot forever; agents cannot kill | `tools/with-slot.mjs` kills the process group after 6 min without output or 45 min of run (exit 124) |
| composite shows THAT something moved, not by how much; a 1 dp shift of everything below was invisible | `pnpm parity:geo`: every web word matched with its Flutter word, dy / dx per 60 dp band, the first band that drifts |
| content tool counted GzChip's hidden width copy, placeholders and "38 s" vs "38s" as differences | hidden subtrees skipped, placeholders in the web dump, digit and letter tokens |
| `dart format` reflowed files at 80 columns | `formatter: page_width: 150` in `analysis_options.yaml` |
| parity score carries about 0.02 to 0.03 of noise on any card with a photo (JPEG downscale) and any tab screen (the shell bar) | known: photo cards sit at 0.09 to 0.11 with exact geometry; read the geometry diff instead of chasing the score |

## Kit, state and test infrastructure (before the main wave: agent KIT-S)
| Finding | Owner |
|---|---|
| `SessionNotifier.completeGate` throws a CircularDependencyError with the real router (the session provider reads the navigator that watches the router); auth flow works around it in `finishSignIn` | kit |
| a session change makes the router redirect away from `/access/*` at once, dropping the route params and disposing the screen: no way to land on a route with params after sign-in | kit: a sign-in landing hook |
| `weddingProfileProvider` never seeds the Brief after its GET: every Brief-aware screen as Reem starts with placeholders | app state |
| the shell tab bar is about 3.5 dp shorter than the web's and the Messages badge is missing in shots | kit tab shell / ghazal_ui |
| every flow wrote its own widget-test world (`flow_world`, `discover_kit`, `booking_world`): fonts, one scenario per test, `finish()`, drag-scroll helper, retry-free client | one shared `test/support/flow_world.dart` per app |
| badges refresh only on a revision bump: nothing refreshes them when the app resumes | `GzAppRoot(onResume:)` |
| the demo tools exist only for the in-process mock; the two-app story needs the standalone server | demo tools over the HTTP control surface |

Test facts every flow test needs (learned the hard way): call `loadAppFonts()` first (without it every text is Ahem and overflows), open a base page that is not `CL-ONBD-01` (the redirect throws a signed-in user off the first-start path), ONE scenario per test (`GzHarness.pump` creates a fresh container), never flush the mock between Accept and Undo (flush ends the 8 s undo window), end every test with `finish()` (unmount and pump a second), no real IO in fake async (it hangs at 0 % CPU), `tester.ensureVisible` aligns the target to the TOP of the scroll view and parks it under a top bar (drag instead).

## Components (before the main wave: agents FIX and KIT-U)
Core deviations measured by the phase C groups are being fixed by the parity fix agent (FactChip, Price, Rating, IconProgress, SegmentTrack, Accordion, Button compact and spill, figures strut, RoleBadge, UserText, price line baseline, group chat bubble). The pilots added, each built flow-locally as a stand-in until the shared one exists:

| Gap | Seen in |
|---|---|
| `GzIconTabs` overflows by 4 dp (60 high item in a 56 box) and puts the Arabic badge on the wrong side | discover, today (HL-TODY-02..04 score 0.12 to 0.14 because of it) |
| `GzChip` cannot fill a cell (`expand`) and keeps a hidden duplicate label that breaks `find.text` and taps; `GzPressable` shrink-wraps | onboarding, filters |
| `GzChipGroup` options and `GzCheckbox` / `GzStepper` take plain strings: want icon, semantic label, widget label; glyph chips with a muted count | filters, booking, onboarding |
| `GzStepper`: hero variant, `labelWidget`, compact mode | onboarding, booking |
| `GzActionBar.note`, `GzTopBar.title`, `GzTimelineEvent.meta` are String only; `GzTopBar` text action slot and search focus callback | auth, today, discover |
| `GzTextField.textAlign`; `GzPhoneField` value alignment against the +965 chip in Arabic | auth |
| `GzListRow` / `GzIconListRow` `flush` keeps a control radius where the web sets 0 | booking |
| `GzStruckMoney` is internal; flow-local copies for the exact mode and the Arabic figure-then-currency order | booking |
| `GzSheet`: no pinned header and no fill-90 % mode for "a screen as a sheet"; two exported `gzImageSrc` with different signatures | auth, discover |
| no `GzInfoButton` / `GzInfoSheet` / aside: three flow-local copies | onboarding, booking |
| `GzPressable` has no `expanded` semantics; range slider value labels sit above the rail (web: below) | discover |

## Mock data (agent MOCK, running)
Home feed rules (no "This week" shelf, free shelf not bound to the area, counts), `availableOnDate` drops held halls, `searchRegions` finds nothing for Arabic "مشرف", missing search filters (setting, facility, brand, price, distance), `limit` above 50 answers 422 where the docs say it is clamped (also `listMessages`), partner Needs-you 18 rows vs 10 and 6 pending vs 5, `today.events` is 30 days not the day, notification tie order, no sister venue for "Switch venue", `invitedBy` Latin only, no OTP_INVALID path and no OTP outbox, package prices without per-guest rate / flat / billed guests, no way to move a bound voucher to another date, request drafts carry extras without quantity. Reem has no approved, confirmed or lapsed request by default (use `fshot --story`), and her only unbound voucher is for V05.

## Not fixable by flows (documented, not chased)
Wrong-code and five-attempts paths of the OTP before the MOCK fix; Apple, Google and biometric sign-in have no SDK in the build (placeholders); a platform map SDK for CL-DISC-05 is an F4 item (a token-drawn schematic stands in); `connectivity` has no source package (offline frames come from `ApiProblem.offline`); Today role frames for accountant and marketing need endpoints the API does not have; the brand photograph of onboarding is served from the mock package assets (a bundled app asset is an F4 item).
