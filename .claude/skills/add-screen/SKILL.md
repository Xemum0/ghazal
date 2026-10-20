---
name: add-screen
description: Build or change one prototype screen in design/src/screens from its inventory entry (file, strings, mock data, CSS, shots, gates). Use when asked to build, rebuild or fix a Client or Partner screen by inventory id such as CL-BOOK-05 or HL-TODY-01.
---
# Add a screen

Full text: `design/README.md` section "Add a screen" and `docs/engineering/screen-agent-brief.md`. Read both first; this is the short procedure.

1. **Inventory.** Find the id in `docs/product/screens/<client|hotel>/NN-<flow>.json` (requirement IDs, states, interactions). `hotel` is the Partner app. Check the requirement IDs exist in `docs/product/feature-matrix.json` (filter, never open whole). Check ADR 0033 and `docs/product/voucher-model-changes.json` if the screen touches money, vouchers, visits or listings.
2. **File.** `design/src/screens/<app>/<flow-id>/<INVENTORY-ID>.tsx`, default export, no props. Flow-local pieces go in `_components/`. Sibling CSS file, tokens only (`var(--gz-...)`), logical properties, flex + gap.
3. **Compose from the system.** `import { Screen, TopBar, ActionBar, Button, ... } from '../../../system'`; hooks `useFrame()` and `useNav()`. Export a `states` list for declared states (loading, empty, error ...).
4. **Data.** `import ... from '../../../mock'` (fixtures). Money is `{fils, currency}` through `useFormat()`; never type a price, date or number in a string.
5. **Strings.** One namespace pair per flow: `node packages/i18n/scripts/new-namespace.mjs <app>-<flow>` if missing; flat camelCase keys prefixed by the namespace; read with `useT('<ns>')` or `<T>`. Write Arabic natively (ADR 0013), not translated.
6. **Missing token or component?** Do not edit shared files. Append one line: `echo '- [<role>] <what and why>' >> docs/engineering/requests.md`.
7. **Look.** Use the `shots-review` skill: `pnpm shots --screen <ID> --lang both --w 390 360` plus every state (`--state`); Read the Arabic PNG.
8. **Gates.** `pnpm typecheck && pnpm lint:css && pnpm i18n:check`. Report any gate that fails; do not hide warnings you introduced.

Ownership: edit only `design/src/screens/<app>/<flow-id>/**` and your two i18n namespace files.
