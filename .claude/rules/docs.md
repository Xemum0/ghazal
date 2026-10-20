---
paths:
  - "docs/**"
---
# Docs

- ADRs are append-only history: change meaning only with a new ADR (`docs/decisions/README.md` "Adding", next free number is 0034). Typos and links may be edited in place. Update the index row in the same change.
- `docs/engineering/requests.md` and `docs/product/open-questions.md` are append-only: add a line with `>>`; the integrator appends status blocks. Section 6 of the open questions is for answered or superseded rows (keep the ID).
- Requirement IDs are append-only in `docs/product/feature-matrix.json`; the `.md` twin must match. Filter the matrix, never open it whole.
- `docs/product/screen-inventory.md` is stale (generated before ADR 0033); the screen JSON under `docs/product/screens/` is authoritative.
- Never invent scope: a new idea goes to `docs/product/open-questions.md` with a working assumption. Owner-only questions are collected in `docs/product/owner-decisions.md`.
- `docs/engineering/STATUS.md` is integrator-owned; do not edit it from a screen task.
- Plain, bilingual-aware wording; no emoji. Respect the voucher model (ADR 0033) in anything written about money.
