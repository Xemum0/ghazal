---
name: shots-review
description: Shoot a screen or gallery page in English and Arabic with the shots tool, view the PNGs and critique them against the Ghazal direction. Use after building or changing any UI, or when asked to review how a screen looks.
---
# Shots review

1. **Shoot** (repo root; the tool verifies the dev server identity and starts it if down; never type a URL):
   - `pnpm shots --screen CL-BOOK-05 --lang both --w 390 360` (add `430` when width matters)
   - states: `pnpm shots --screen <ID> --state loading --lang both` (also `empty`, `error`, `offline`); long content: add `--full`
   - gallery: `pnpm shots --route gallery:core --lang both`; any view: `pnpm shots --url-hash "#/canvas/hotel?focus=HL-TODY-01" --lang ar --viewport 1440x900`
   Output goes to `design/.shots/<name>.<lang>.<w>.png`; the tool prints each path and any page error (use `--strict` to fail on errors).
2. **Look.** Read every PNG with the Read tool, the Arabic one first. A type-check is not design QA.
3. **Critique checklist** (binding sources: `docs/design/01-direction.md`, AGENTS.md hard rules):
   - Hierarchy readable at arm's length; one primary action (gold fill, ink label); gold only as a verb.
   - 4-pt grid, 20 px gutter, targets at least 44 px, nothing clipped at 360 px.
   - Colour only from the palette (Ink, Matte Gold, Soft Rose, warm neutrals, restrained success/danger); no gradients, glass, neon, emoji icons.
   - No faces (monograms, empty rooms); photography crops are sensible.
   - Voucher model correct: two prices where a package shows, "KD 2" voucher wording, no deposit/balance/payout/commission, ad rates "Rates announced soon".
   - Typefaces: El Messiri display, Manrope English, Almarai Arabic; no fallback glyphs.
   - Copy: no placeholder text, no raw keys, no exclamation marks, numbers formatted by the formatter.
   - Every declared state renders and looks designed (not a stub).
4. Run the `rtl-check` skill for the Arabic image. Report findings as a short list (screen, issue, severity), not prose.
