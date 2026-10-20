---
paths:
  - "design/src/screens/**"
---
# Screens (design/src/screens/<app>/<flow-id>/<INVENTORY-ID>.tsx)

- The file name IS the inventory id (`CL-BOOK-05`). The entry lives in `docs/product/screens/<app>/NN-<flow>.json`; read it first (requirement IDs, states, interactions). App `hotel` is the Partner app.
- Procedure: `design/README.md` "Add a screen", or the `add-screen` skill. Rules for agents: `docs/engineering/screen-agent-brief.md`.
- Build from `design/src/system` only (`Screen`, `TopBar`, `ActionBar`, `Button` ...) and `design/src/mock` fixtures. Do not edit `system/`, `shell/` or tokens; request them with one `>>` line in `docs/engineering/requests.md`.
- CSS: sibling file, `var(--gz-...)` tokens only, logical properties, flex + gap, no grid / `%` / `rem` / `calc` / backdrop-filter. Gate: `pnpm lint:css`.
- Strings: namespace `<app>-<flow>` in `packages/i18n/messages/{en,ar}/`; read with `useT` / `<T>`. Never type a price, date or number into a message; money is `{fils, currency}` through `useFormat()`.
- Voucher model (ADR 0033): no deposit, balance, payout or refund-tier UI; every package shows standard and voucher price; ad rates show "Rates announced soon".
- Monogram avatars, no faces, no emoji. One primary action per screen, targets at least 44 px.
- Done = `pnpm typecheck`, `pnpm lint:css`, `pnpm i18n:check` and `pnpm shots --screen <ID> --lang both --w 390 360` with the Arabic PNG actually read.
