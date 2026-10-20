# Exploration archive: three directions, three judges, one hybrid

> One page of record. The decision is ADR 0030 and the binding rules are `docs/design/01-direction.md`. The static pages in `design/explorations/` are an ARCHIVE (read-only reference); do not edit them, do not build screens from their CSS (copy values from `01-direction.md`).

## 1. The three directions

| Key | Concept | Memorable device | Own stated risk |
|---|---|---|---|
| `maison` | Editorial hospitality: ivory canvas, full-bleed photography, serif signage (Newsreader, Amiri); one gold hairline, the khayt, carries facts | The search as a typeset sentence whose underlined words are the controls | Serif in a data-dense hotel app; sentence discoverability; reliance on empty-room photography; Amiri for younger readers; Google Fonts |
| `majlis` | Architectural warmth: Ink bars, an arch crown on hero photos and sheets, a lattice in empty states, gold as line work | The sheet whose arch crown flattens to a lintel as you drag it | Arch read as "mosque" or gimmick; Ink chrome takes 11 to 14% of the screen; Markazi reads small; hotel app plain; Google Fonts |
| `thread` | Poppins and Cairo only; one 2 px gold line that appears only when something progresses, is selected, connects or waits | The Booking Thread: Request, Approval, Deposit, Balance, Day, identical for couple and hotel | Static screens undersell the motion; Light type needs strong photography; Arabic Light below 26 px is thin; per-span numerals formatter |

## 2. Judging (13 criteria, 1 to 10; judges: CD = creative director of a five-star hotel brand, UX = head of UX, accessibility and Arabic/RTL, SK = design-systems engineer and AI-template skeptic)

| Direction | CD | UX | SK | Mean | Ranked first by |
|---|---|---|---|---|---|
| majlis | 99 | 104 | 103 | 102.0 | UX, SK |
| maison | 101 | 99 | 101.5 | 100.5 | CD |
| thread | 93 | 96 | 90 | 93.0 | nobody |

Per criterion (CD / UX / SK):

| Criterion | maison | majlis | thread |
|---|---|---|---|
| premium feel | 9 / 9 / 8 | 7 / 7 / 8 | 6 / 6 / 6 |
| distinctiveness vs AI template | 8 / 9 / 6.5 | 7 / 7 / 8 | 6 / 8 / 6 |
| hierarchy clarity | 8 / 7 / 8 | 8 / 9 / 8 | 7 / 7 / 7 |
| imagery treatment | 9 / 8 / 9 | 7 / 7 / 7 | 6 / 6 / 6 |
| typography craft | 9 / 8 / 8 | 7 / 7 / 7 | 6 / 6 / 6 |
| Arabic native quality | 8 / 7 / 8 | 7 / 9 / 8 | 6 / 6 / 7 |
| palette discipline | 9 / 8 / 8 | 7 / 8 / 7 | 8 / 8 / 8 |
| measurement rigor | 7 / 8 / 8 | 9 / 9 / 8 | 8 / 7 / 6 |
| hotel app fit | 6 / 6 / 7 | 8 / 9 / 8 | 9 / 8 / 8 |
| compare screen solution | 7 / 7 / 8 | 9 / 8 / 9 | 8 / 9 / 7 |
| system scalability | 6 / 7 / 8 | 8 / 8 / 9 | 8 / 9 / 8 |
| Flutter feasibility | 6 / 6 / 7 | 8 / 9 / 8 | 8 / 8 / 8 |
| memorability | 9 / 9 / 8 | 7 / 7 / 8 | 7 / 8 / 7 |

All three judges recommended the same hybrid (Maison look and photography, Majlis structure, Thread's booking thread and day timeline). Defects they asked to fix, all carried into `01-direction.md`: Maison italic accent word, eyebrow plus dash on every card, greeting banner, 40 px tappable words, six-line sentence at 360, serif in hotel triage; Majlis lattice on Home, Ink bars (94 and 120 px), single-letter Arabic weekdays, `+12%` bidi glitch, default gold on one compare column; Thread sub-12 px decimals, text on busy photos, thin Arabic Light, gold-500 hairline as the only signal.

## 3. What was adopted from each

| From | Adopted | Dropped |
|---|---|---|
| maison | identity, ramps and contrast table, type tables (EN and AR), serif display, full-bleed heroes, wall-label plates, brief sentence (as echo), ruled YOUR DATE strip, deposit split, countdown card, hotel check line and conflict note, motion tokens, khayt, wordmark fonts | italic accent word, pink greeting card, serif in hotel data, Ink primary button, eyebrow and dash everywhere |
| majlis | gutter 20, section 32, control heights, real status bar and safe areas, structured brief card, compare layout and labelled action bar, hotel Ink band and triage, hall segmented, package checks, calendar toggle, arch geometry (Home and onboarding hero only) | lattice, Ink tab and CTA bars, arch on sheets, thumbs and tray, Markazi, doorway mark (app-icon study only) |
| thread | Booking Thread (5 knots), vertical day timeline, reply-window bar, 7-day strip, range bars and `How you book` row, Cairo figures x1.08 and fils rule, gold-is-a-verb lint, gold-650 ring and gold-550 pressed fill, wordmark baseline geometry | Light 300 display in Poppins/Cairo, looping thread loader, 2 px chip rings, sub-12 px decimals |

## 4. Re-opening the static pages

- File URLs only (AGENTS.md: no dev server, no default port). Open from the repo root, for example `file:///Users/youcefs/Desktop/Desktop/ghzal/design/explorations/maison/board.html`.
- Per direction: `board.html` (concept, tokens, components, in-situ screens) and four screens `client-home.html`, `client-venue.html`, `client-compare.html`, `hotel-today.html`; `direction.css` holds every token; `README.md` the concept.
- Arabic and RTL: append `?lang=ar` (all three). Full-page capture: `?full=1` (majlis, thread) or `?static` (maison).
- The pages load Newsreader, Amiri, Cairo and Poppins from Google Fonts, so type renders correctly only online; the production system self-hosts fonts (ADR 0016, `01-direction.md` rule 1).
- Screenshots, both languages, fold and full: `design/.review/directions/<key>/` (for example `client-home-ar-fold.png`); boards `board.png` there are 15 to 18k px tall. Regenerate with `node design/scripts/snap.mjs design/explorations/<key>/<page>.html <out.png> --lang ar|en [--full]` (needs `playwright-core` in `design/node_modules`).
- Judge reports: the workflow journal under `~/.claude/projects/-Users-youcefs-Desktop-Desktop-ghzal/<session>/subagents/workflows/wf_bf58b5c9-324/journal.jsonl` (lines with `verdict`); the scores above are copied from it.
