import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

import 'go_router_navigator.dart';
import 'nav_providers.dart';

/// The container of the tab branches (the `navigatorContainerBuilder` of the shell route): every visited branch stays mounted with its
/// stack and its state, only the active one is visible, and a tab switch fades the incoming branch in over the outgoing one (200 ms,
/// the `base` duration) with no re-build of the branches. Each branch gets its own [GzScrollToTopSignal] (the re-tap of its tab).
class GzTabContainer extends ConsumerStatefulWidget {
  const GzTabContainer({required this.shell, required this.branches, super.key});

  final StatefulNavigationShell shell;
  final List<Widget> branches;

  @override
  ConsumerState<GzTabContainer> createState() => _GzTabContainerState();
}

class _GzTabContainerState extends ConsumerState<GzTabContainer> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this, value: 1);
  late int _active = widget.shell.currentIndex;
  int? _leaving;
  final Set<int> _visited = <int>{};

  @override
  void initState() {
    super.initState();
    _visited.add(_active);
  }

  @override
  void didUpdateWidget(GzTabContainer old) {
    super.didUpdateWidget(old);
    final next = widget.shell.currentIndex;
    if (next == _active) return;
    _leaving = _active;
    _active = next;
    _visited.add(next);
    _fade.duration = GzReducedMotion.of(context) ? GzMotion.durationFast : GzMotion.durationBase;
    _fade.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _leaving = null);
    });
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signals = ref.read(goRouterNavigatorProvider).scrollSignals;
    final count = widget.branches.length;
    // Painting order: hidden branches, the leaving one, the active one on top (keys keep every branch's state across the reorder).
    final order = <int>[
      for (var i = 0; i < count; i++)
        if (i != _active && i != _leaving) i,
      ?_leaving,
      _active,
    ];
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final i in order)
          _Branch(
            key: ValueKey<int>(i),
            shown: i == _active || i == _leaving,
            active: i == _active,
            fade: i == _active && _leaving != null ? _fade : null,
            signal: i < signals.length ? signals[i] : null,
            child: widget.branches[i],
          ),
      ],
    );
  }
}

class _Branch extends StatelessWidget {
  const _Branch({required this.shown, required this.active, required this.fade, required this.signal, required this.child, super.key});

  final bool shown;
  final bool active;
  final Animation<double>? fade;
  final ValueNotifier<int>? signal;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    final s = signal;
    if (s != null) {
      content = ValueListenableBuilder<int>(
        valueListenable: s,
        builder: (context, value, child) => GzScrollToTopSignal(signal: value, child: child!),
        child: content,
      );
    }
    content = ExcludeSemantics(
      excluding: !active,
      child: IgnorePointer(
        ignoring: !active,
        child: TickerMode(enabled: shown, child: content),
      ),
    );
    if (fade != null) content = FadeTransition(opacity: fade!, child: content);
    return Offstage(offstage: !shown, child: content);
  }
}

/// The tab shell both apps use: the branches above a [GzTabBar] (items from [gzTabsOf], labels from the app's catalogue, badges from
/// [gzTabBadgesProvider]). Selecting a tab goes through the navigator (`switchTab`: restores the tab's stack, a re-tap pops it to its
/// root and scrolls it to top). The toast host floats above the bar while the bar is the visible bottom chrome.
class GzTabShell extends ConsumerStatefulWidget {
  const GzTabShell({required this.navigationShell, required this.kind, required this.labelOf, required this.barLabel, super.key});

  final StatefulNavigationShell navigationShell;
  final GzAppKind kind;

  /// The tab's name in the current language (`context.l10n.clientShellTabDiscover`...).
  final String Function(BuildContext context, String tabId) labelOf;

  /// The accessible name of the bar.
  final String barLabel;

  @override
  ConsumerState<GzTabShell> createState() => _GzTabShellState();
}

class _GzTabShellState extends ConsumerState<GzTabShell> {
  late final GoRouterNavigator _navigator = ref.read(goRouterNavigatorProvider);
  double _barHeight = 0;
  bool _syncQueued = false;

  @override
  void initState() {
    super.initState();
    _navigator.router.routerDelegate.addListener(_queueSync);
  }

  @override
  void dispose() {
    _navigator.router.routerDelegate.removeListener(_queueSync);
    _navigator.detachShell(widget.navigationShell);
    _navigator.toasts.bottomChrome.value = 0;
    super.dispose();
  }

  void _queueSync() {
    if (_syncQueued) return;
    _syncQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncQueued = false;
      if (!mounted) return;
      _navigator.toasts.bottomChrome.value = _navigator.tabBarCovered ? 0 : _barHeight;
    });
  }

  @override
  Widget build(BuildContext context) {
    _navigator.attachShell(widget.navigationShell);
    final tabs = _navigator.spec.tabs;
    final defs = gzTabsOf(widget.kind);
    final badges = ref.watch(gzTabBadgesProvider);
    final current = widget.navigationShell.currentIndex.clamp(0, tabs.length - 1);
    final height = GzTabBar.heightOf(MediaQuery.paddingOf(context).bottom);
    if (height != _barHeight) {
      _barHeight = height;
      _queueSync();
    }
    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: GzBottomChrome(tabBar: true, child: widget.navigationShell),
          ),
        ),
        GzTabBar(
          items: [
            for (final t in tabs)
              GzTabItem(id: t.id, icon: defs.firstWhere((d) => d.id == t.id).icon, label: widget.labelOf(context, t.id), badge: badges[t.id]),
          ],
          activeId: tabs[current].id,
          ariaLabel: widget.barLabel,
          onSelect: _navigator.switchTab,
        ),
      ],
    );
  }
}
