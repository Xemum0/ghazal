#!/usr/bin/env node
// Route stub generator (plan phase F0, ADR 0036).
//
// Reads docs/product/screens/{client,hotel}/*.json (+ _index.json for the tabs) and writes, per app:
//   lib/features/<flow_snake>/<flow_snake>_routes.dart   one file per inventory flow (a flow agent owns it after taking it over)
//   lib/app/app_router.dart                              composes every flow (REGENERATED every run)
//   lib/app/screen_registry.dart                         inventory id -> path/kind/navigatesTo + the tab list (REGENERATED)
//
// Contract of a flow routes file (generated stub or hand-written, so app_router keeps compiling):
//   List<RouteBase> get <flowCamel>Routes        every screen of the flow that is NOT a tab root
//   Map<String, GoRoute> get <flowCamel>TabRoots inventory id -> route, only for the screens that are the root of a main tab
//                                                (emitted only when the flow has some); composed into the tab shell
//
// Chrome (which tab owns a screen, where the tab bar is hidden, which screens are sheets) is ported from design/src/system/nav/tabs.ts
// (`chromeFor`, `SHEET_SCREENS`) into the tables below and CHECKED against that file on every run (`tsCheck`), so the two cannot drift.
// The registry carries the result (`tab`, `tabBar`, `kind`); the router composition in ghazal_app_kit puts a screen that shows the tab bar
// inside its tab's StatefulShellBranch and everything else (hidden bar, no tab, sheet) on the root navigator.
//
// IDEMPOTENT: a flow file whose first line no longer starts with `// GENERATED STUB` is never touched. Deprecated screens are skipped.
//
//   node tools/gen-routes.mjs [--check] [--app client|provider]
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const MARK = '// GENERATED STUB'
const APPS = [
  { key: 'client', inv: 'client', dir: 'client_app', prefix: 'CL', start: 'CL-ONBD-01' },
  { key: 'provider', inv: 'hotel', dir: 'provider_app', prefix: 'HL', start: 'HL-ACCS-01' },
]
const args = process.argv.slice(2)
const only = args.includes('--app') ? args[args.indexOf('--app') + 1] : null
const check = args.includes('--check')

const snake = (s) => s.replace(/-/g, '_')
const camel = (s) => s.replace(/[-_](\w)/g, (_, c) => c.toUpperCase())
const dq = (s) =>
  `'${String(s ?? '')
    .replace(/\\/g, '\\\\')
    .replace(/'/g, "\\'")
    .replace(/\$/g, '\\$')
    .replace(/\r?\n/g, ' ')}'`
const oneLine = (s, n = 400) => {
  const t = String(s ?? '').replace(/\s+/g, ' ').trim()
  return t.length > n ? `${t.slice(0, n - 1)}…` : t
}


// ---------------------------------------------------------------- chrome (ported from design/src/system/nav/tabs.ts)
const CLIENT_FLOW_TAB = {
  ONBD: null, AUTH: null, DISC: 'discover', VENU: 'discover', SERV: 'discover', SAVD: 'saved', BOOK: 'discover', PAYM: 'discover',
  BKNG: 'my-wedding', WEDD: 'my-wedding', PLAN: 'my-wedding', MSGS: 'messages', RVRW: 'profile', PROF: 'profile', VCHR: 'profile', VIST: 'messages',
}
const HOTEL_FLOW_TAB = {
  ACCS: null, TODY: 'today', BOOK: 'bookings', DCSN: 'bookings', CALN: 'calendar', VENU: 'more', GROW: 'more', SETT: 'more', VIST: 'bookings', PROV: 'more',
}
const HIDDEN_FLOWS = new Set(['CL-ONBD', 'CL-AUTH', 'CL-BOOK', 'CL-PAYM', 'HL-ACCS'])
const HIDDEN_SCREENS = new Set([
  'CL-DISC-05', 'CL-VENU-01', 'CL-VENU-02', 'CL-VENU-06', 'CL-SERV-03', 'CL-SAVD-04', 'CL-MSGS-02', 'CL-PLAN-02', 'CL-RVRW-02', 'CL-PROF-06',
  'HL-TODY-05', 'HL-GROW-02', 'HL-GROW-03', 'HL-BOOK-06',
])

/** Same rules as `chromeFor` in tabs.ts: the tab that owns a screen (null: outside the tabs) and whether the tab bar shows. */
function chromeFor(id) {
  const hotel = id.startsWith('HL-')
  const parts = id.split('-')
  let owner = (hotel ? HOTEL_FLOW_TAB : CLIENT_FLOW_TAB)[parts[1] ?? ''] ?? null
  if (id === 'HL-TODY-04' || id === 'HL-TODY-05') owner = 'messages'
  const hidden = HIDDEN_FLOWS.has(parts.slice(0, 2).join('-')) || HIDDEN_SCREENS.has(id) || owner === null
  return { tab: owner, tabBar: !hidden }
}

/** Fails (exit 1) when the tables above differ from tabs.ts, or when SHEET_SCREENS differs from the inventory's `kind: sheet`. */
function tsCheck(inventorySheets) {
  const src = fs.readFileSync(path.join(ROOT, 'design/src/system/nav/tabs.ts'), 'utf8')
  const body = (name) => {
    const m = src.match(new RegExp(`(?:const|export const) ${name}\\b[^=]*=\\s*(?:new Set\\()?([\\[{][\\s\\S]*?[\\]}])\\)?\\n`))
    if (!m) throw new Error(`tabs.ts: ${name} not found (gen-routes.mjs tsCheck needs updating)`)
    return m[1]
  }
  const strings = (name) => [...body(name).matchAll(/'([^']+)'/g)].map((x) => x[1])
  const record = (name) => Object.fromEntries([...body(name).matchAll(/(\w+):\s*(?:'([^']+)'|null)/g)].map((x) => [x[1], x[2] ?? null]))
  const problems = []
  const same = (label, a, b) => {
    const A = JSON.stringify(a), B = JSON.stringify(b)
    if (A !== B) problems.push(`${label}\n    gen-routes.mjs: ${A}\n    tabs.ts:        ${B}`)
  }
  same('CLIENT_FLOW_TAB', CLIENT_FLOW_TAB, record('CLIENT_FLOW_TAB'))
  same('HOTEL_FLOW_TAB', HOTEL_FLOW_TAB, record('HOTEL_FLOW_TAB'))
  same('HIDDEN_FLOWS', [...HIDDEN_FLOWS].sort(), strings('HIDDEN_FLOWS').sort())
  same('HIDDEN_SCREENS', [...HIDDEN_SCREENS].sort(), strings('HIDDEN_SCREENS').sort())
  same('SHEET_SCREENS (inventory kind: sheet vs tabs.ts)', [...inventorySheets].sort(), strings('SHEET_SCREENS').sort())
  if (!/id === 'HL-TODY-04' \|\| id === 'HL-TODY-05'\) owner = 'messages'/.test(src)) problems.push("the HL-TODY-04 / HL-TODY-05 messages special case of chromeFor changed in tabs.ts")
  if (problems.length) {
    console.error(`gen-routes: chrome tables drifted from design/src/system/nav/tabs.ts:\n  ${problems.join('\n  ')}`)
    process.exit(1)
  }
}

const written = []
const skipped = []
function write(file, content) {
  if (check) {
    const cur = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : null
    if (cur !== content) throw new Error(`stale: ${path.relative(ROOT, file)} (run node tools/gen-routes.mjs)`)
    return
  }
  fs.mkdirSync(path.dirname(file), { recursive: true })
  fs.writeFileSync(file, content)
  written.push(path.relative(ROOT, file))
}

{
  const sheets = []
  for (const app of APPS) {
    const dir = path.join(ROOT, 'docs/product/screens', app.inv)
    for (const f of fs.readdirSync(dir).filter((x) => x.endsWith('.json') && x !== '_index.json')) {
      for (const sc of JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')).screens) if (!sc.deprecated && sc.kind === 'sheet') sheets.push(sc.id)
    }
  }
  tsCheck(sheets)
}

for (const app of APPS) {
  if (only && only !== app.key) continue
  const invDir = path.join(ROOT, 'docs/product/screens', app.inv)
  const index = JSON.parse(fs.readFileSync(path.join(invDir, '_index.json'), 'utf8'))
  const tabs = index.navigation.tabs
  const tabRootIds = new Set(tabs.map((t) => t.rootScreen))
  const flowOrder = index.flowOrder
  const flows = []
  for (const file of fs.readdirSync(invDir).filter((f) => f.endsWith('.json') && f !== '_index.json')) {
    const j = JSON.parse(fs.readFileSync(path.join(invDir, file), 'utf8'))
    flows.push(j)
  }
  flows.sort((a, b) => flowOrder.indexOf(a.id) - flowOrder.indexOf(b.id))

  const appDir = path.join(ROOT, 'apps', app.dir)
  const registry = []
  const seenPaths = new Set()
  const seenIds = new Set()

  for (const flow of flows) {
    const fsnake = snake(flow.id)
    const fcamel = camel(flow.id)
    const live = flow.screens.filter((s) => !s.deprecated)
    const routes = []
    const tabRoots = []
    for (const s of live) {
      if (seenIds.has(s.id)) throw new Error(`duplicate screen id ${s.id}`)
      seenIds.add(s.id)
      const p = `/${flow.id}/${s.slug}`
      if (seenPaths.has(p)) throw new Error(`duplicate path ${p} (${s.id})`)
      seenPaths.add(p)
      const chrome = chromeFor(s.id)
      registry.push({ id: s.id, path: p, kind: s.kind, flow: flow.id, tab: chrome.tab, tabBar: chrome.tabBar, navigatesTo: (s.navigatesTo ?? []).filter((x) => typeof x === 'string') })
      const route = `  GoRoute(
    path: ${dq(p)},
    name: ${dq(s.id)},
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: ${dq(s.id)},
      titleEn: ${dq(s.title?.en)},
      titleAr: ${dq(s.title?.ar)},
      kind: ${dq(s.kind)},
      purpose: ${dq(oneLine(s.purpose))},
    ),
  )`
      if (tabRootIds.has(s.id)) tabRoots.push({ id: s.id, route })
      else routes.push(route)
    }
    const featureDir = path.join(appDir, 'lib/features', fsnake)
    const file = path.join(featureDir, `${fsnake}_routes.dart`)
    for (const sub of ['presentation', 'application']) {
      const keep = path.join(featureDir, sub, '.gitkeep')
      if (!check && !fs.existsSync(keep)) {
        fs.mkdirSync(path.dirname(keep), { recursive: true })
        fs.writeFileSync(keep, '')
      }
    }
    if (fs.existsSync(file) && !fs.readFileSync(file, 'utf8').startsWith(MARK)) {
      skipped.push(path.relative(ROOT, file))
      continue
    }
    const header = `${MARK}: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: \`${fcamel}Routes\` (non-tab screens)${tabRoots.length ? ` and \`${fcamel}TabRoots\` (tab roots by inventory id)` : ''}.
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow \`${flow.id}\` (${app.prefix}): ${live.length} screens. ${oneLine(flow.title?.en ?? '')}
List<RouteBase> get ${fcamel}Routes => <RouteBase>[
${routes.join(',\n')}${routes.length ? ',' : ''}
];
`
    const tabPart = tabRoots.length
      ? `
/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get ${fcamel}TabRoots => <String, GoRoute>{
${tabRoots.map((t) => `  ${dq(t.id)}:\n${t.route.replace(/^/gm, '  ')}`).join(',\n')},
};
`
      : ''
    write(file, header + tabPart)
  }

  // ---- app_router.dart
  const flowsWithRoutes = flows.map((f) => ({ id: f.id, snake: snake(f.id), camel: camel(f.id) }))
  const tabByRoot = new Map()
  for (const f of flows) for (const s of f.screens) if (!s.deprecated && tabRootIds.has(s.id)) tabByRoot.set(s.id, f)
  for (const t of tabs) if (!tabByRoot.get(t.rootScreen)) throw new Error(`tab ${t.id}: root screen ${t.rootScreen} not found or deprecated`)
  const flowsWithTabRoots = [...new Set(tabs.map((t) => tabByRoot.get(t.rootScreen).id))]
  const imports = flowsWithRoutes.map((f) => `import '../features/${f.snake}/${f.snake}_routes.dart';`).join('\n')
  const spreads = flowsWithRoutes.map((f) => `        ...${f.camel}Routes,`).join('\n')
  const tabSpreads = flowsWithTabRoots.map((id) => `        ...${camel(id)}TabRoots,`).join('\n')
  const startFlow = registry.find((r) => r.id === app.start).flow
  const guard =
    app.key === 'provider'
      ? `    requireSession: true,\n    publicPrefixes: <String>['/${startFlow}'],\n`
      : ''
  const router = `// GENERATED by tools/gen-routes.mjs (node tools/gen-routes.mjs). Regenerated on every run: do not edit by hand.
// Composition only: one line per flow. Flow code lives in lib/features/<flow>/ and is never touched here. Which screens sit inside
// a tab (and keep the bar) and which go above it is decided by ghazal_app_kit \`buildGzRouter\` from the chrome of the registry.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_ui/ghazal_ui.dart' show GzAppKind;
import 'package:go_router/go_router.dart';

${imports}
import 'app_tab_shell.dart';
import 'screen_registry.dart';

/// Navigation facts of the app, derived from the screen registry (tabs, chrome per screen, first start, guard).
final GzRouterSpec kRouterSpec = GzRouterSpec(
  app: GzAppKind.${app.key === 'client' ? 'client' : 'partner'},
  tabs: <GzTabSpec>[for (final t in kAppTabs) GzTabSpec(t.id, t.rootScreen)],
  chrome: <String, GzScreenChrome>{
    for (final e in kScreenRegistry.entries)
      e.key: GzScreenChrome(tab: e.value.tab, tabBar: e.value.tabBar, sheet: e.value.kind == ScreenKind.sheet),
  },
  paths: <String, String>{for (final e in kScreenRegistry.entries) e.key: e.value.path},
  startPath: kInitialLocation,
  homePath: kScreenRegistry[kAppTabs.first.rootScreen]!.path,
${guard});

/// The app router. [initialLocation] defaults to the first screen of a first start (${app.start}). [ref] connects the redirect and the
/// refresh listenable to \`sessionProvider\` (the app root override passes it; tests may omit it).
GoRouter buildAppRouter({Ref? ref, String? initialLocation, Object? initialExtra, List<NavigatorObserver> observers = const <NavigatorObserver>[]}) {
  return buildGzRouter(
    spec: kRouterSpec,
    routes: <RouteBase>[
${spreads}
    ],
    tabRoots: <String, GoRoute>{
${tabSpreads}
    },
    tabShellBuilder: (BuildContext context, StatefulNavigationShell navigationShell) => AppTabShell(navigationShell: navigationShell),
    ref: ref,
    initialLocation: initialLocation,
    initialExtra: initialExtra,
    observers: observers,
  );
}
`
  write(path.join(appDir, 'lib/app/app_router.dart'), router)

  // ---- screen_registry.dart
  const startEntry = registry.find((r) => r.id === app.start)
  if (!startEntry) throw new Error(`start screen ${app.start} missing`)
  const kindEnum = { screen: 'screen', sheet: 'sheet', 'tab-root': 'tabRoot' }
  const reg = registry
    .map(
      (r) =>
        `  ${dq(r.id)}: ScreenEntry(path: ${dq(r.path)}, kind: ScreenKind.${kindEnum[r.kind] ?? 'screen'}, flow: ${dq(r.flow)}, tab: ${
          r.tab ? dq(r.tab) : 'null'
        }, tabBar: ${r.tabBar}${r.navigatesTo.length ? `, navigatesTo: <String>[${r.navigatesTo.map(dq).join(', ')}]` : ''})`,
    )
    .join(',\n')
  const tabList = tabs
    .map((t) => `  AppTab(id: ${dq(t.id)}, titleEn: ${dq(t.title.en)}, titleAr: ${dq(t.title.ar)}, rootScreen: ${dq(t.rootScreen)}),`)
    .join('\n')
  const registrySrc = `// GENERATED by tools/gen-routes.mjs from docs/product/screens/${app.inv}/. Regenerated on every run: do not edit by hand.
// Used by the router composition, tests, the shot harness (inventory id -> path) and the final sweep. ${registry.length} live screens (deprecated ones are skipped).
// \`tab\` and \`tabBar\` are the chrome of design/src/system/nav/tabs.ts (\`chromeFor\`): the tab that owns the screen and whether the bar shows.

enum ScreenKind { screen, sheet, tabRoot }

class ScreenEntry {
  const ScreenEntry({
    required this.path,
    required this.kind,
    required this.flow,
    this.tab,
    this.tabBar = false,
    this.navigatesTo = const <String>[],
  });

  final String path;
  final ScreenKind kind;
  final String flow;

  /// The tab that owns the screen (null: it lives outside the tabs: onboarding, auth, access).
  final String? tab;

  /// The tab bar shows under this screen (false for sheets, the booking flow, detail pages with their own CTA bar, ...).
  final bool tabBar;

  /// Inventory ids this screen can navigate to (the BFS graph of the reachability check).
  final List<String> navigatesTo;
}

class AppTab {
  const AppTab({required this.id, required this.titleEn, required this.titleAr, required this.rootScreen});

  final String id;
  final String titleEn;
  final String titleAr;
  final String rootScreen;
}

/// Location of a first start (${app.start}).
const String kInitialLocation = ${dq(startEntry.path)};

/// Main tabs in inventory order (the bar mirrors in RTL; the order never changes).${
    app.key === 'provider' ? '\n/// A service-provider account swaps the Calendar slot for Listings (HL-PROV-02) later; the hotel tabs are the default.' : ''
  }
const List<AppTab> kAppTabs = <AppTab>[
${tabList}
];

const Map<String, ScreenEntry> kScreenRegistry = <String, ScreenEntry>{
${reg},
};
`
  write(path.join(appDir, 'lib/app/screen_registry.dart'), registrySrc)
  console.log(`${app.dir}: ${registry.length} screens, ${flows.length} flows, ${tabs.length} tabs`)
}

if (written.length) console.log(`wrote ${written.length} files`)
if (skipped.length) console.log(`kept (flow-owned, marker removed):\n  ${skipped.join('\n  ')}`)
if (check) console.log('routes up to date')
