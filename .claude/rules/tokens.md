---
paths:
  - "packages/design-tokens/**"
---
# Design tokens (single writer: tokens owner / integrator)

- The only hand-edited source is `src/tokens.json` (plus `a11y-pairs.json` for allowed contrast pairs). Everything in `dist/` and `design/src/styles/typography.roles.css` is generated: run `pnpm tokens`, never edit by hand.
- Gate: `pnpm tokens:check` (type allow-list, 4-pt grid, control heights 44/48/52/56, AR/EN type parity, contrast pairs, icons, dist freshness). Never write to `dist/` to make it pass.
- Colour: raw values only in `color.ref`; semantic tokens reference them. Palette = Ink, Matte Gold, Soft Rose plus warm neutrals and a tiny success/danger set (ADR 0030). Add a token with a `reason` instead of inlining a value anywhere else.
- Typefaces: El Messiri (display), Manrope (EN UI), Almarai (AR UI) (ADR 0031 addendum). Token names: ADR 0023 D3 (`--gz-color-sys-text-primary`).
- Others request a token with one `>>` line in `docs/engineering/requests.md`.
