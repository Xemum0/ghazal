# Git workflow

> Binding. Source: ADR 0026 (source control, CI), 0029 (agents, ownership), 0021 (layout, slots). Commit message format and scopes: [conventions.md](conventions.md) section 10. Who may touch which path: [agentic-workflow.md](agentic-workflow.md).

## 1. Where the repository stands

- `git init` has been run; branch is `master`; there are **no commits**. Every file is untracked.
- AGENTS.md says: do not commit unless asked. The `PreToolUse` guard turns `git commit`, `git push`, `git reset --hard` and `git clean -f` into an `ask`.
- Worktree isolation (`isolation: worktree`), diff-based gates and the ownership diff all need at least one commit (OQ-T-07). Until the owner approves the baseline commit: no worktrees, one checkout (slot 0), parallel agents write disjoint owned paths listed in their task text, and the integrator verifies afterwards (see section 3).
- The repo will live as a **private repository in the owner's GitHub organisation**, created on day one so the NF-DEL-07 transfer is a no-op.

### Baseline commit (only on the owner's explicit go-ahead)

ADR 0021 D7 schedules it at design freeze with tag `design-v1`. Ask earlier if parallel design work needs diff gates: the design phase is the busiest period for parallel agents and the one with no safety net.

Preconditions the owner confirms:

1. `BookingSaaS v2.3 Nulled.rar` is deleted or moved out of the folder by the owner. It is git-ignored but is a licence and malware risk; no agent opens it.
2. `.gitignore` carries the additions in section 8.
3. The foundation PR (pnpm workspace, `design/package-lock.json` removed, `design/node_modules` reinstalled by pnpm) is done, or the baseline is taken before it and the PR follows.
4. `gitleaks` over the working tree finds nothing; `git status` shows no `node_modules`, `.env*`, archives or key files.

Then, authored by the owner or by an agent on explicit instruction:

```
git branch -M main
git add -A && git status        # read it
git commit -m "chore: baseline of design-phase documents and prototype scaffold"
git tag design-v1               # at design freeze only
```

After the baseline, history is never rewritten. The one exception is purging a leaked secret, which is the owner's decision and happens only after the secret is rotated.

## 2. Branching (trunk-based)

- `main` is the only long-lived branch. It is protected: required checks, linear history, squash merge only, no force-push, no direct pushes.
- Short-lived branches, ideally merged within two days: `feat/<area>-<slug>`, `fix/<area>-<slug>`, `chore/...`, `docs/...`, `agent/<role>-<slug>` for autonomous work. Examples: `feat/client-booking-review`, `fix/api-hold-release`, `agent/screens-hotel-today-ab12`.
- One branch, one purpose, one owner path set. Long feature work lands behind configuration, not in a long-lived branch.
- Mobile hotfix: fix forward on `main`. If a store build must be patched, branch `release/<app>-X.Y` from the tag, cherry-pick, tag `X.Y.Z+1`.

## 3. Worktrees and slots (parallel agents, after the baseline commit)

Slot 0 is the main checkout. Slots 1 to 9 are agent worktrees. Each slot has its own ports, Docker project, database and screenshot folder so agents cannot collide (ADR 0021 D8, ADR 0029 D8).

```
git worktree add ../ghzal-slot3 -b agent/screens-client-booking-review-ab12 main
cd ../ghzal-slot3 && pnpm install            # fast: shared pnpm store
node tools/ports.mjs url design --slot 3     # prints the URL; never hand-type one (tool lands in the foundation PR)
```

| Resource | Slot N |
|---|---|
| Dev ports | `4700 + 10 x N + offset` (design 0, api 1, venue-dashboard 2, admin-dashboard 3, Prism 4, realtime 5, Flutter web 6, pdf 7) |
| Docker | `COMPOSE_PROJECT_NAME=ghazal_slot<N>`; Postgres host port `54320 + N`; Redis `63790 + N` |
| Database | `ghazal_slot<N>` |
| Screenshots | `design/.shots/<agent-id>/` |
| Locks | `flock tools/.locks/emulator`, `flock tools/.locks/build_runner` (one emulator, one build_runner at a time) |

Never stop a process you did not start. When the task ends: stop your own servers, `git worktree remove ../ghzal-slot3`, delete the merged branch.

Before the baseline commit exists, the interim ownership check is a marker file: the orchestrator touches a marker before the run and the integrator lists changes with `find <paths> -newer <marker> -type f` and compares them with the task's owned paths. Anything outside them is reverted or reviewed.

## 4. Commits and hooks

- Format, types and scopes: [conventions.md](conventions.md) section 10. One scope per commit; small, reviewable, buildable.
- Agents commit only when asked. When they do, the commit ends with the attribution trailer supplied by the session.
- lefthook runs on every commit (installed by `pnpm install`):

| Hook | Runs |
|---|---|
| pre-commit | `biome check --staged`; Stylelint on staged CSS; `dart format --set-exit-if-changed` on staged Dart; `gitleaks protect --staged` (`gitleaks git --staged` on versions that deprecate `protect`) |
| commit-msg | commitlint (Conventional Commits with the scope list) |

- Nobody, human or agent, uses `--no-verify`. If a hook is wrong, fix the hook in its own `chore(tools)` commit.
- CI repeats every hook check; a bypassed hook still fails the PR.

## 5. Pull requests

- The title is a Conventional Commit and becomes the squash commit.
- Size: one screen, one component, one endpoint or one ADR. As a guide, under about 400 changed lines excluding generated files and fixtures; split anything larger.
- `.github/pull_request_template.md` (integrator) asks for:

```
## What and why
## Requirement IDs and ADRs            (CA-BOOK-11, ADR 0001; a UI PR without IDs fails review)
## UI evidence                          (PNG paths under design/.shots/<run>/; state that the Arabic PNGs were Read at full size)
## Verify output                        (tail of `pnpm verify <area>`)
## Open questions touched               (OQ-B-xx, OQ-L-xx, OQ-T-xx; placeholders called out)
## Generated files regenerated          (which generator ran)
## Risk and rollback
```

- Required checks: one always-reporting aggregate job per workflow (`ci-ok`). Do the path filtering inside the workflow with job-level conditions and a `changes` job, not with `on.paths`: a required check that is skipped by a path filter never reports and blocks the PR forever.
- Review: the read-only reviewer subagents (`design-qa`, `rtl-reviewer`, `a11y-auditor`, `prd-tracer`, `handoff-checker`) attach findings tables; the owner merges. Production deploys and mobile `prod` builds additionally need a protected-environment approval.
- Squash merge, delete the branch, linear history.
- `CODEOWNERS` assigns integrator-owned paths (`.claude/**`, `.github/**`, `tools/**`, root configs, `docs/engineering/**`, `infra/**`, `AGENTS.md`) and `packages/design-tokens/src/**` to the owner for review.

## 6. Conflicts and single-writer files

Prevent conflicts with ownership; resolve the rest with these rules.

| File kind | Resolution |
|---|---|
| `pnpm-lock.yaml`, `pubspec.lock` | never merge by hand: take main's file, rerun `pnpm install` or `flutter pub get`; integrator only |
| Generated outputs (tokens, ARB merges, `openapi.json`, API clients) | take either side, regenerate, commit; CI fails on diff |
| Token JSON, `design/src/system/**`, `.claude/**`, `.github/**`, `AGENTS.md` | single writer; a conflict means an ownership breach: stop and tell the integrator |
| ARB parts, route modules, specs | per feature; a conflict means two agents shared a feature: stop |
| Append-only logs (`docs/product/open-questions.md`, `docs/engineering/requests.md`) | `merge=union` in `.gitattributes`; append with shell `>>`, never Write |
| ADRs | numbers come from `node tools/new-adr.mjs` under a lock; a duplicate number is renamed in the later PR |
| Migrations | timestamp names; on rebase, re-sort, re-run the integration suite; only one agent runs `drizzle-kit generate` |

## 7. Generated files in git

Generated files are committed so a fresh clone works and drift is a visible diff. They are never hand-edited. CI regenerates and fails on any diff. The authoritative list with each generator is `docs/engineering/generated-files.md`. In summary:

- `packages/design-tokens/dist/**`, `packages/ghazal_ui/lib/src/tokens/generated/**`
- `apps/*/lib/l10n/app_*.arb`, `apps/*/lib/l10n/generated/**`
- `packages/contracts/openapi.json`, `packages/api-client-ts/src/generated/**`, `packages/ghazal_api_client/**`
- the icon font and `GzIcons`, lockfiles

`.gitattributes` marks them `linguist-generated` so GitHub collapses them in diffs.

## 8. Repository hygiene

- `.gitattributes` (integrator):

```
* text=auto eol=lf
*.ttf binary
*.png binary
*.webp binary
packages/design-tokens/dist/** linguist-generated
**/generated/** linguist-generated
*.g.dart linguist-generated
packages/contracts/openapi.json linguist-generated
pnpm-lock.yaml linguist-generated
docs/product/open-questions.md merge=union
docs/engineering/requests.md merge=union
```

- `.gitignore` already covers `node_modules/`, `dist/`, `build/`, `.env*` (except `.env.example`), `*.pem`, `*.p12`, `*.keystore`, `service-account*.json`, `design/.shots/`, `design/.review/`, `*.rar`, `*.zip`, `*.7z`. Add: `design/.redlines/`, `tools/.locks/`, `.dart_tool/`, `.flutter-plugins*`, `.gradle/`, `**/Pods/`, `local.properties`, `key.properties`, `*.jks`, `*.p8`, `*.mobileprovision`, `.pnpm-store/`, `*.log`. Firebase client config from `flutterfire configure` is committed on purpose (not a secret).
- No binary above about 1 MB without a reason. Allowed exceptions: the static fonts (about 300 KB in total), the licensed or generated prototype images (credited in `design/public/images/CREDITS.md`), and golden PNGs within the budget (at most 1,200 files and 40 MB). No Git LFS.
- No secrets, ever; if one lands in a commit, follow the leak procedure in [environments-and-secrets.md](environments-and-secrets.md).
- Never commit the `.rar`, anything extracted from it, or a file named like it.

## 9. Releases and tags

| Artefact | Trigger | Rules |
|---|---|---|
| Design freeze | tag `design-v1` on `main` | after it, a token change needs an ADR and a STATUS broadcast |
| Client app | tag `client-app/vX.Y.Z+N` | `pubspec.yaml` version must equal the tag (CI check); `N` only increases; builds `stg` to TestFlight and the Play internal track; `prod` only from a tag through a protected environment with required reviewers |
| Hotel app | tag `hotel-app/vX.Y.Z+N` | same |
| API | merge to `main` deploys staging; production needs a manual approval | image tagged with the git SHA; migrations run as a Cloud Run Job before traffic shifts 10% then 100%; forward-only expand/contract; rollback means the previous revision, never a down migration |
| Release notes | GitHub Release per tag | generated from Conventional Commits filtered by scope |

`release-mobile` is manual-only for agents; they never tag or deploy to production (ADR 0026 D5).

## 10. What agents may and may not do with git

May: read-only commands (`git status`, `git diff`, `git log`), create a branch or worktree when the task says so, stage and commit when asked.

Must not, without an explicit instruction from the owner in the current session: `git commit`, `git push`, `git reset --hard`, `git clean -f`, `git checkout -- <file>`, force-push, amend or rebase shared history, `--no-verify`, edit `.git/hooks`, delete branches they did not create, or run any git command on the pirated archive. When in doubt, stop and ask (see the stop-and-ask table in [agentic-workflow.md](agentic-workflow.md)).
