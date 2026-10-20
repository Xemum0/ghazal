# Ghazal (غزل)

Premium wedding-venue marketplace for Kuwait (GCC later). Four products: Client Mobile App, Venue/Hotel Mobile App, Venue Admin Dashboard and Super Admin Dashboard (web). The current phase is **design** of the Client and Hotel apps as an interactive web prototype (the *Design Studio*), which Flutter then reproduces. Agents and contributors: start with [AGENTS.md](AGENTS.md).

## Run the Studio

```
pnpm install                       # pnpm 10.10, Node >=22
pnpm -F design dev                 # starts on a reserved port in 4700-4799, bound to 127.0.0.1
node tools/ports.mjs url design    # prints the URL (never type one)
node tools/ports.mjs check design  # proves the server on that port is ours
pnpm shots --route gallery:placeholder --lang both   # screenshots in design/.shots/
pnpm verify                        # typecheck + lint + tokens:check + i18n:check
```

Details, routes and gates: [design/README.md](design/README.md).

## Repo map

```
AGENTS.md / CLAUDE.md      agent instructions
docs/product/              digest, personas, journeys, scope, glossary, feature matrix, screen inventory
docs/design/               brief, binding visual direction, content guidelines, seed rulebook
docs/architecture/         stack, data model, state machine, pricing and payments, i18n/RTL, design-to-code
docs/engineering/          conventions, testing, git workflow, definition of done, STATUS, requests, ownership
docs/decisions/            ADRs (accepted ones are binding)
design/                    Design Studio (Vite + React + TypeScript), scripts, explorations
packages/                  design-tokens, i18n, contracts (@gz/*); more land with their first consumer
tools/                     ports.mjs (ports and server identity), stub.mjs
apps/                      (future) Flutter apps, API, dashboards
.claude/                   settings (permissions, hooks)
```

`BookingSaaS v2.3 Nulled.rar` is pirated software, unrelated to this project, git-ignored and never opened.
