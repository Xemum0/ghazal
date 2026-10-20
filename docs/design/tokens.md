# Design tokens (summary)

> The values are in `packages/design-tokens/src/tokens.json` (source) and `docs/design/01-direction.md` (the why). This page is the short map: what each namespace is and how to use it. Live view: `#/gallery/tokens?lang=en|ar` in the Studio. Details, naming rules and commands: `packages/design-tokens/README.md`.

## Namespaces and CSS

| Namespace | Holds | CSS example |
|---|---|---|
| `color.sys.surface` | canvas, raised (paper), quiet, tint (rose-100), tint-soft, dark, dark-raised, placeholder | `background: var(--gz-color-sys-surface-canvas)` |
| `color.sys.text` | strong (ink-900), primary (ink-700), secondary (ink-600), disabled, on-gold, gold-ink (gold-700), on-dark, on-dark-muted, on-dark-gold, success, danger | `color: var(--gz-color-sys-text-secondary)` |
| `color.sys.icon` | primary, secondary, accent (gold-700), on-dark, success, danger, disabled | `color: var(--gz-color-sys-icon-accent)` |
| `color.sys.border` | hairline, strong, control (ink-500, 3.9:1), focus, error, on-dark | `border-block-end-color: var(--gz-color-sys-border-hairline)` |
| `color.sys.mark` | khayt (gold-500), state (gold-650), decor (gold-600), pressed (gold-550), track, open | `background: var(--gz-color-sys-mark-khayt)` |
| `color.sys.action` | primary (bg, bg-pressed, label, disabled), secondary, tertiary, destructive, selected | `background: var(--gz-color-sys-action-primary-bg)` |
| `color.sys.control` `status` | input bg, segmented track, toggle parts; pending / success / danger / neutral pills; reply-bar states | `color: var(--gz-color-sys-status-danger-text)` |
| `color.sys.illus` | line (ink-800), line-soft (ink-500), ground (ink-300), tint (rose-100), tint-deep (rose-200), accent (gold-500), accent-line (gold-600), knockout (canvas): the roles of the illustration layer (ADR 0034); a drawing has no colour of its own | `fill: var(--il-tint)` (rebound from `--gz-color-sys-illus-tint` by `.gz-illus`) |
| `color.sys.scrim` `shadow` | named photo scrims and shadow colours (alpha is always a token) | `background: var(--gz-gradient-cover)` |
| `space` | 0..24 = 0..96 px (x4), gutter 20, section 32, list-gap 24, shelf-gap 32, panel-pad 16 | `padding-inline: var(--gz-space-gutter)` |
| `size` | control sm/md/cta/lg = 44/48/52/56, touch-min 44, icon 16/20/24/32, row, tab-bar, toggle, knot, avatar, thumb | `min-block-size: var(--gz-size-control-cta)` |
| `size.illustration` | sm 64, md 96, lg 144, hero 200 (square boxes of the illustration layer) | `inline-size: var(--gz-size-illustration-lg)` |
| `radius` `stroke` `z` | 4/8/12/20/pill; hair 1, icon 1.5, illustration 1.5 (non-scaling at every size), thread 2, focus 2; layers 0..70 | `border-radius: var(--gz-radius-sm)` |
| `layout` | frame 390x844, safe 47/34, breakpoints 360/390/430, aspect ratios, hero heights | `aspect-ratio: var(--gz-layout-aspect-4x5)` |
| `elevation` | 0 none, 1 ring, 2 floating, 3 sheet | `box-shadow: var(--gz-elevation-2)` |
| `motion` | durations (instant 1, fast 120, base 200, slow 320, expressive 480, success 640), eases (standard, emphasized, exit, linear), spring settle, scale, distance | `transition: transform var(--gz-motion-duration-fast) var(--gz-motion-ease-standard)` |
| `font` `type.en|ar` | four families; 39 roles per script (size, line, weight, tracking, word spacing, numeric features) | `class="gz-t-d2"` |

Never use `color.ref.*` outside the tokens package. Gold fill only for the one primary action, the selected date, count badges and knots; gold text and icons are `text-gold-ink` / `icon-accent` (gold-700).

## Type

Use a role class instead of assembling properties: `.gz-t-label`, `.gz-t-body`, `.gz-t-d1`..`d6`, `.gz-t-brief`, `.gz-t-price`, `.gz-t-kpi`, ... (generated, one per role). The language comes from the `lang` attribute: `:lang(ar)` switches every `--gz-type-*` and `--gz-font-*` variable, so one class is correct in both scripts and an Arabic run inside English UI only needs `lang="ar"`. Display serif (Newsreader / Amiri) only for names, hero price, brief sentence and countdown (never on hotel data). No italics, no Arabic tracking or uppercase.

Numbers: wrap any number inside a line in `<span class="gz-num">` (Cairo tabular Western digits, LTR island, size taken from the surrounding role: Poppins x1.08 in English, same size in Arabic). A standalone figure uses a figure/price role class. Money markup is `.gz-money > .gz-money__cur + .gz-money__num > (.gz-money__amt + .gz-money__fils)`; strings come from the shared formatter (ADR 0010), the CSS only styles them. `.gz-ltr` isolates anything else (phones, codes).

## Direction and motion helpers (`design/src/styles`)

| Need | Use |
|---|---|
| Mirror a directional icon | `.gz-mirror` (flips under `[dir=rtl]`); the registry's `mirrorInRtl` says which |
| Direction multiplier | `--gz-dir` (1 / -1), `--gz-origin-start`, `--gz-shift-end` / `--gz-shift-start` (push distance, signed) |
| Gutter, safe areas, targets | `.gz-gutter`, `.gz-safe-top` / `.gz-safe-bottom`, `.gz-target` (44) |
| Rules and the thread | `.gz-rule`, `.gz-khayt`, `.gz-thread-track` + `.gz-thread-fill`, `.gz-bead`, `.gz-knot--open|now|tied|compact` |
| Press, selection | `.gz-press` (tone step + scale .985, 120 ms), `.gz-select`, `.gz-thread-slide` |
| Entrances (once) | `.gz-thread-draw` (480 ms from inline-start), `.gz-knot-pop`, `.gz-reveal` in `.gz-reveal-frame`, `.gz-sheet-enter/-exit`, `.gz-push-*` / `.gz-pop-*`, `.gz-scrim-*`, `.gz-undo-line`, `.gz-success-draw` |
| Stagger | set `--gz-delay` from TypeScript (token ms x index); CSS has no `calc` |

Reduced motion (`prefers-reduced-motion`): draws, pops, press scale and slides are removed; movement entrances and exits become 120 ms opacity cross-fades; the undo line keeps running because it is a determinate timer (ADR 0031 addendum).

## Gates

`pnpm tokens` writes `dist/`; `pnpm tokens:check` fails on a stale dist, a contrast pair under 4.5 (text) / 3 (UI), a documented ratio that drifts from the direction doc, gold used as text, AR/EN key mismatch, off-grid spacing or line heights, an unshipped font weight, or an icon without a mirror flag.
