@AGENTS.md

## Claude Code notes
- Subagents inherit this file. Re-state only the rules a task depends on; don't paste this file into prompts.
- Look at UI work before calling it done: `pnpm shots --screen <ID> --lang both --w 390 360`, then Read the Arabic PNG (output in `design/.shots/`). The tool checks the dev server identity and starts it if down. Never hand-type a localhost URL; use `node tools/ports.mjs url design`. `snap.mjs` is for `file://` explorations only.
- Parallel agents: touch only the files you own (paths are given in the task); shared files (`packages/design-tokens/src/`, `design/src/system/`, `design/src/shell/`) are changed only by the agent assigned to them.
- Project skills (`/add-screen`, `/shots-review`, `/rtl-check`, `/voucher-model`), path rules and subagents live in `.claude/`; AGENTS.md lists them.
