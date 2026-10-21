# Parity tooling (flutter-build-plan section 6)

Instruments, not gates: both scripts exit 0 unless `--strict`. Needs system Chrome (playwright-core from `design/`), ImageMagick (`magick`) and the design dev server (started detached if down, identity-checked via `tools/ports.mjs`).

## Reference renders: `pnpm parity:ref`
`node tools/parity/ref-shots.mjs [--only ID,ID] [--flow <flow-id>] [--lang ar|en|both] [--w 390] [--states] [--force]`

- Renders every live (non-deprecated) screen of `docs/product/screens/{client,hotel}/*.json` from `#/frame/<id>?lang=..&w=..` at 390x844, scale 2 (780x1688), reduced motion, fonts awaited, 250 ms settle. One browser and one page; each screen starts from `about:blank` (a hash-only navigation left screens half-rendered).
- Output: `design/.shots/ref/<id>.<lang>.png` and `manifest.json` (id, flow, app, kind, lang, state, size, time, hash, errors; for state frames `distinctFromDefault` says whether the image differs from the default frame, i.e. the state produced a real frame).
- `--states` also renders the non-default states listed in the inventory (`?state=`) as `<id>.<state>.<lang>.png`.
- A PNG is skipped when it is newer than every file in `design/src` and `packages/i18n/messages` (unless `--force`).
- Full run: 135 screens x 2 languages = 270 PNGs, about 6 minutes.

## Compare: `pnpm parity`
```
node tools/parity/parity.mjs --app client --screen CL-DISC-01 --lang ar [--w 390] [--flutter <png>] [--out <png>]
node tools/parity/parity.mjs --app client --flow discover [--lang ar|en|both] [--strict]
```
Defaults: reference `design/.shots/ref/<id>.<lang>.png`; Flutter shot `apps/<client_app|provider_app>/build/shots/<id>.<lang>.<w>.png`; composite `apps/<app>/build/parity/<id>.<lang>.png`. `--flow` takes the flow id from the manifest (the inventory file `id`, e.g. `discover`), runs all its screens and prints a table sorted worst first; missing files are listed as "missing". A Flutter PNG of another size is resized to the reference size (noted in the output).

Score: normalised RMSE (0 = identical, 1 = black vs white) over the area between the safe areas (top 94 px status bar and bottom 68 px home indicator at DPR 2 are cut). "diff%" is the share of pixels whose luminance differs by more than 8%.

## Reading the composite
Three panels, labelled, with the score in the header: `reference | flutter | difference`. In the difference panel red marks pixels that differ by more than the tolerance on a faded copy of the reference; grey bars are the masked safe areas. Thin red outlines along text and edges mean sub-pixel shifts or anti-aliasing; solid red blocks mean wrong size, colour, position or missing content. A low score can still hide a small but real change (an icon, one line of text): always look at the composite in Arabic and English.

## Thresholds and calibration (`node tools/parity/selftest.mjs`)
Verdict: **pass < 0.075**, **review < 0.12**, fail otherwise. Measured on three reference screens (CL-DISC-01 ar, HL-TODY-01 ar, CL-BOOK-02 en):

| case | score |
|---|---|
| identical | 0.0000 |
| anti-aliasing noise / contrast -3% | 0.006 / 0.013-0.015 |
| blur 0.5 px / 1.0 px | 0.018-0.021 / 0.040-0.046 |
| shift 1 px (0.5 dp) | 0.064-0.069 |
| shift 2 px (1 dp) | 0.101-0.107 |
| shift 4 px (2 dp) | 0.133-0.141 |
| different screen | 0.33-0.41 |

So 1 px shifts and text anti-aliasing pass, a 1 dp shift needs a look, a 2 dp shift or another screen fails. The build plan's original 0.06 sat below a 1 px shift and was relaxed to 0.075. If thresholds change, rerun the self-test and update this table. Real Flutter-vs-browser text rendering differences are expected to land around 0.02-0.05 and will be re-checked on the first real shots.

## Gallery and screen tools added in phases C and F3

| Tool | What it proves |
|---|---|
| `pnpm parity:board` (`board.mjs`) | one table of every component gallery against the web references; `--save` / `--baseline` mark regressions (`!!`) and improvements (`+`) |
| `pnpm probe` (`probe.mjs`) | the computed boxes and styles of any web element (screen or gallery), with a box tree: the number to build to |
| `pnpm parity:text` + `pnpm parity:content` | content parity: the words of a Flutter shot against the web frame as bags of words; catches a missing subtitle, a missing section below the fold, a wrong name (render tall: `pnpm fshot ... --h 4000 --health`) |
| `pnpm flutter:edges` (`tools/check-nav-edges.mjs`) | every `navigatesTo` edge of the inventory has a route name in the flow's source; every screen reachable; no stub |
| `pnpm flutter:sweep` (`tools/flutter-sweep.mjs`) | the route sweep: layout at 360 / 390 / 430, text scale 1.3, content, scenario states; framework errors, overflow, stubs, blank renders, stuck skeletons, error states, missing words |

The shot harness writes `<label>.health.json` (errors, overflow, stub, skeletons, error / offline / empty state) and `<label>.texts.json` next to every PNG; `--health` makes framework errors non-fatal so a sweep reads them instead of stopping.
