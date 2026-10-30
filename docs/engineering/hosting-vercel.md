# Hosting the design prototype on Vercel

> The web prototype (`design/`: the Launcher, the Studio, every screen, the rose comparison theme) is a static Vite site. It is hosted from the repo root with `vercel.json`. The Flutter apps are not hosted here.

## What is in the repo
| File | Role |
|---|---|
| `vercel.json` (root) and `design/vercel.json` | the same settings for Root Directory = repo root and = `design`: install (`pnpm install --frozen-lockfile --filter design...`), build (`node tools/vercel-build.mjs`), output `design/dist`, cache and security headers, `X-Robots-Tag: noindex, nofollow` |
| `tools/vercel-build.mjs` | the build: design tokens (generated, gitignored), photo variants (generated, gitignored), `vite build` (typecheck first), leaves the 1800 px photo originals out when all variants exist, removes the dev-only `fonts-lab.html`, checks the output |
| `.vercelignore` | what a CLI deploy does not upload: the Flutter apps and Dart packages, `.claude/`, scratch and build folders, and archives (`*.rar`, `*.zip`: the pirated archive must never leave the machine) |
| `design/index.html` | `<meta name="robots" content="noindex, nofollow">` |
| `pnpm build:vercel` | the same build locally: result in `design/dist` (about 70 MB) |

Routes live in the URL hash (`#/play/...`, `#/frame/...`, `#/?theme=rose`), so no rewrites are needed.

## Deploy (Git integration, recommended)
1. Push the repository to GitHub, GitLab or Bitbucket (the integrator cannot push: `git push` is denied in `.claude/settings.json`).
2. Vercel: Add New Project, import the repository.
3. Settings: **Framework Preset: Other**; leave the Build, Output and Install commands empty (they come from the vercel.json of the root directory); no environment variables; Node.js 22.x. The **Root Directory** can be either of:
   - **the repository root** (leave it empty or `./`): uses `vercel.json` at the root;
   - **`design`**: uses `design/vercel.json` (it runs the build from `../tools`). Then Settings, General, must have **Include source files outside of the Root Directory in the Build Step** switched on, because the build reads `packages/`, `docs/` and `tools/`.
   Error `Cannot find module '/vercel/path0/design/tools/vercel-build.mjs'` means the Root Directory is `design` while the Build Command is still the root one (`node tools/vercel-build.mjs`): clear the Build, Output and Install command overrides in the project settings (so the file is used), or set the Root Directory to the repository root.
   If the install step cannot find pnpm, add the environment variable `ENABLE_EXPERIMENTAL_COREPACK=1` (the repo pins `pnpm@10.10.0` in `package.json`).
4. Deploy. Every push then builds a preview; the production branch builds production.

## Deploy from this machine (CLI)
```
npx vercel            # preview, answers the same questions once (root directory: ./)
npx vercel --prod
```
The CLI uploads the folder minus `.vercelignore`, including an existing `design/public/images/_v` (the photo variants), and builds on Vercel with the same `vercel.json`. To build here and upload only the result: `npx vercel build && npx vercel deploy --prebuilt`.

## Protect it before you share the link
The Studio is an internal tool: its documentation pages (`#/docs/...`: product notes, ADRs, the requirement matrix) are part of the JavaScript bundle, and the prototype shows every screen and the owner decisions. Anyone with the URL can read them. For a client review turn on Deployment Protection in the Vercel project (Settings, Deployment Protection: Vercel Authentication, or password protection depending on your plan) so only people you invite open it. The site is also served with `noindex` headers so search engines skip it.

## Photos
The prototype serves 480, 800 and 1200 px variants (`design/scripts/images.mjs`, needs ImageMagick or `sips`). The hosted build leaves the 1800 px originals out when every variant exists (set `GZ_KEEP_ORIGINALS=1` to keep them). If the Vercel build image has no ImageMagick, the build log shows `warning: no image tool`: the site then serves the originals (it works, but the upload is about 150 MB and photos load slower). Fix: build locally and `vercel deploy --prebuilt`, or commit `design/public/images/_v`.

## Checks done on 2026-10-30
- `pnpm build:vercel` builds in a few seconds when the variants exist; `design/dist` is 69 MB (1,613 files).
- Served statically, eight routes (Launcher, Launcher in Arabic with `theme=rose`, two client frames with photos, the partner sign-in, the signed-out application form, the client canvas, a docs page) load with no failed request and no console error; the discover frame shows its 15 photos; the rose theme switches through the hash.

## Links
- Open the rose theme: `<site>/#/?theme=rose` (the gold design is the default, `?theme=gold`).
- The application form: `<site>/#/play/hotel/HL-PROV-01?lang=en`, or the Launcher, Partner, "Apply to join".
