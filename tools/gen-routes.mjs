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
      registry.push({ id: s.id, path: p, kind: s.kind, flow: flow.id, navigatesTo: (s.navigatesTo ?? []).filter((x) => typeof x === 'string') })
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
  const imports = flowsWithRoutes.map((f) => `import '../features/${f.snake}/${f.snake}_routes.dart';`).join('\n')
  const spreads = flowsWithRoutes.map((f) => `    ...${f.camel}Routes,`).join('\n')
  const branches = tabs
    .map((t) => {
      const f = tabByRoot.get(t.rootScreen)
      if (!f) throw new Error(`tab ${t.id}: root screen ${t.rootScreen} not found or deprecated`)
      return `        StatefulShellBranch(routes: <RouteBase>[${camel(f.id)}TabRoots[${dq(t.rootScreen)}]!]),`
    })
    .join('\n')
  const router = `// GENERATED by tools/gen-routes.mjs (node tools/gen-routes.mjs). Regenerated on every run: do not edit by hand.
// Composition only: one line per flow, then the tab shell. Flow code lives in lib/features/<flow>/ and is never touched here.
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

${imports}
import 'app_tab_shell.dart';
import 'screen_registry.dart';

/// The app router. [initialLocation] defaults to the first screen of a first start (${app.start}).
GoRouter buildAppRouter({String? initialLocation, List<NavigatorObserver> observers = const <NavigatorObserver>[]}) {
  return GoRouter(
    initialLocation: initialLocation ?? kInitialLocation,
    observers: observers,
    routes: <RouteBase>[
${spreads}
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) =>
            AppTabShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
${branches}
        ],
      ),
    ],
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
        `  ${dq(r.id)}: ScreenEntry(path: ${dq(r.path)}, kind: ScreenKind.${kindEnum[r.kind] ?? 'screen'}, flow: ${dq(r.flow)}${
          r.navigatesTo.length ? `, navigatesTo: <String>[${r.navigatesTo.map(dq).join(', ')}]` : ''
        })`,
    )
    .join(',\n')
  const tabList = tabs
    .map((t) => `  AppTab(id: ${dq(t.id)}, titleEn: ${dq(t.title.en)}, titleAr: ${dq(t.title.ar)}, rootScreen: ${dq(t.rootScreen)}),`)
    .join('\n')
  const registrySrc = `// GENERATED by tools/gen-routes.mjs from docs/product/screens/${app.inv}/. Regenerated on every run: do not edit by hand.
// Used by tests, the shot harness (inventory id -> path) and the final sweep. ${registry.length} live screens (deprecated ones are skipped).

enum ScreenKind { screen, sheet, tabRoot }

class ScreenEntry {
  const ScreenEntry({required this.path, required this.kind, required this.flow, this.navigatesTo = const <String>[]});

  final String path;
  final ScreenKind kind;
  final String flow;

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
