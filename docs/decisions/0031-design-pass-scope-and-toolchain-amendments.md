# ADR 0031: Design-pass scope and toolchain amendments (integrator overrides of ADR 0021 and 0024)

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-10-12 |
| Scope | What of ADR 0021 (toolchain pins, birth criteria) and ADR 0024 (spec/redline overhead) is built now, deferred, or relaxed during the design pass of the Client and Hotel apps |
| Owner confirmation still needed | None. Revisit at design freeze (before the Dart workspace is created) |
| Amends | ADR 0021 decisions 7 and 9; ADR 0024 decisions 2, 5, 6 and 10 |
| Related ADRs | 0021, 0023, 0024, 0025, 0029, 0030 |

## Context

ADR 0021 pins Node 24, pnpm 12, TypeScript ~6.0 and tells agents not to install anything until the owner upgrades Node; the machine has Node 23.7 and pnpm 10.10. Following that literally blocks the prototype, which is the current deliverable. ADR 0024 asks for a spec JSON per component and per screen, redline export and parity tests. That is the right shape for the *handoff packet* that precedes the Flutter build, but front-loading it onto about 90 screens would slow the design pass without improving the design.

## Decision

1. **Toolchain.** Pin what runs here: `engines.node >=22`, `packageManager: pnpm@10.10.0`, current stable React, Vite and TypeScript that install cleanly (exact versions come from the lockfile). Moving to Node 24 LTS / a newer pnpm is a later chore (own PR); nothing may *require* the newer versions yet. Agents may run `pnpm install` inside the workspace.
2. **Birth criteria (ADR 0021 d7), narrowed.** Created now: root `package.json`, `pnpm-workspace.yaml`, `design/`, `packages/design-tokens`, `packages/i18n` (message JSON, formatters), `packages/contracts` (types and fixtures), `tools/ports.mjs`, `.claude/*`, `docs/engineering/{STATUS,requests,ownership}.md`. Deferred: Biome, lefthook, commitlint, GitHub workflows, `packages/config-tsconfig` (a shared `tsconfig.base.json` at the root instead).
3. **CSS subset (ADR 0024 d2) stays, as lint warnings.** `design/src/**` follows the Flutter-translatable subset (flex + gap, integer px on the 4-pt grid, tokens only, logical properties, no grid / backdrop-filter / blend / filter / clip-path-except-the-named-arch / calc / rem). Stylelint reports violations as warnings in the design pass; they become errors at design freeze. `position: sticky` is permitted for pinned bars and headers only, and each use is annotated `/* flutter-ok: pinned sliver */`. The scroll-driven CSS animation used in the compare exploration is not carried over.
4. **Specs deferred.** Per-component and per-screen spec JSON, `redlines.mjs`, and parity tests (ADR 0024 d5, d6, d10) are produced in the handoff-packet phase after design freeze. In the design pass the spec is: `docs/design/01-direction.md` + `packages/design-tokens` + the live component gallery in the Studio + the screen inventory JSON. `data-gz="<Component>"` markers on component roots stay (cheap and useful for QA).
5. **Screen identity.** The inventory id (`CL-BOOK-05`, `HL-TODY-01`) is canonical in the prototype registry. The ADR 0024 spec id is derived: `<app>.<flow-id>.<slug>` from the same inventory entry (for example `client.booking.review`). One mapping, no second source.
6. **Fixtures.** The prototype reads mock content from `packages/contracts/fixtures` (venues, packages, bookings, requests, conversations), money in integer fils, as ADR 0021 d4 says. The fixtures are authored once, bilingual, and are the single seed for both apps.

## Consequences

- The prototype can be built and run on this machine today; no OS-level upgrades are a prerequisite.
- The handoff rigour of ADR 0024 is postponed, not dropped; a checklist item in `docs/engineering/definition-of-done.md` (design-screen list) must be completed before a screen counts as "handed off".
- Warnings-level CSS lint means the design pass can use sticky headers and the arch clip without an ADR per use, at the cost of a clean-up pass at freeze.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Follow ADR 0021 literally (Node 24, pnpm 12, no installs) | Blocks the current deliverable; the pins were chosen without regard for the machine in hand |
| Full ADR 0024 specs and redlines during the design pass | Front-loads about a day of tooling plus a spec per screen before any design is approved; design may still change |
| No CSS subset at all | Reopens the blur/grid/blend problem the brief and ADR 0024 exist to prevent |

## Addendum: resolutions of conflicts raised while writing ADR 0030 (2026-10-12)

| Topic | Resolution |
|---|---|
| Reduced motion (ADR 0017 D9 vs direction doc) | `prefers-reduced-motion` removes transforms, draws, pops and parallax; opacity cross-fades are KEPT at the 120 ms token so push, sheet and tab changes never read as a jump cut. The "1 ms" wording in `docs/design/01-direction.md` means transform/draw durations only. |
| Eyebrow tracking (ADR 0016) | +0.14em as in ADR 0030, at most two eyebrows per screen. |
| Display face validation (ADR 0016 D7) | Cannot be run by agents. Newsreader + Amiri ship in the prototype; the reviewer test with Kuwaiti readers is an owner action before visual freeze, with Poppins/Cairo as the fallback (tokens make the swap one line). Tracked in open questions. |
| Remaining ADR 0030 refinements (0003 D6, 0007 D6, 0008 D4/D5, 0009 D6/D8, 0018 D3/D9, 0024 aspect tokens, gold-650/550, size.control.cta, no italics) | Accepted as written in ADR 0030; the tokens agent adds the missing tokens (52 px CTA control, 4:5 and 16:10 aspects, 640 ms success, gold-550/650). |

## Addendum: typeface change (owner decision, 2026-10-13)

The owner reviewed six pairings in `design/public/fonts-lab.html` and chose **C**: **El Messiri** (display, both scripts), **Manrope** (English UI and figures), **Almarai** (Arabic UI). This supersedes the Newsreader / Amiri / Poppins / Cairo set of ADR 0016 and ADR 0030 (the 0030 visual direction, colour, shape and motion decisions are unchanged). Almarai ships 300/400/700 and El Messiri 400-700, so the former 500/600 Arabic UI roles map to 400/700 and 300-weight display roles to 400. Italics stay banned. Files are self-hosted under `design/public/fonts/woff2`; tokens are in `packages/design-tokens/src/tokens.json` (`font.*`), with the shipped-weight gate in `packages/design-tokens/scripts/lib/tokens.mjs`. The old font files and `LICENSES.md` entries remain on disk until cleanup.
