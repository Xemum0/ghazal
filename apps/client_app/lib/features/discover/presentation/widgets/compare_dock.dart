import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show VenueSummary;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/state/state.dart' show compareProvider;
import '../../application/discover_regions.dart';

/// Interaction timing, not animation: three idle seconds (ADR 0009 D3).
const Duration kTrayIdle = Duration(seconds: 3);

/// The Compare tray where Discover mounts it (Home and Results, ADR 0009 D3). The anti-nag rules live here: it appears only when the set
/// holds something, and only an add made in this session opens it (a set that was already there when the screen opened starts as the 44
/// pill); with one hall nothing is actionable, with two or three it is "Compare (n)"; it collapses to the pill after three idle seconds and
/// when the list scrolls down, and returns when the list scrolls up; "Clear" empties the set. [extra] sits above the tray (the Map pill).
class CompareDock extends ConsumerStatefulWidget {
  const CompareDock({this.extra, this.initiallyOpen = false, super.key});

  final Widget? extra;
  final bool initiallyOpen;

  @override
  ConsumerState<CompareDock> createState() => _CompareDockState();
}

class _CompareDockState extends ConsumerState<CompareDock> {
  late bool _open = widget.initiallyOpen;
  Timer? _idle;
  double _lastTop = 0;
  int? _lastCount;

  void _arm() {
    _idle?.cancel();
    _idle = Timer(kTrayIdle, () {
      if (mounted) setState(() => _open = false);
    });
  }

  @override
  void dispose() {
    _idle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ids = ref.watch(compareProvider.select((c) => c.venueIds));
    final top = GzScreenScroll.of(context);
    final last = _lastCount;
    if (last != null && ids.length > last) {
      _open = true;
      _arm();
    }
    _lastCount = ids.length;
    final delta = top - _lastTop;
    if (delta.abs() >= GzSpace.s4) {
      _lastTop = top;
      if (ids.isNotEmpty) {
        if (delta > 0 && _open) {
          _idle?.cancel();
          _open = false;
        } else if (delta < 0 && !_open) {
          _open = true;
          _arm();
        }
      }
    }
    final roster = ref.watch(venueRosterProvider).value ?? const [];
    final venues = <VenueSummary>[
      for (final id in ids) ...[for (final r in roster) if (r.venue.id == id) r.venue],
    ];
    final extra = widget.extra;
    if (venues.isEmpty && extra == null) return const SizedBox.shrink();
    final nav = context.gzNav;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ?extra,
        if (extra != null && venues.isNotEmpty) const SizedBox(height: GzSpace.s3),
        if (venues.isNotEmpty)
          Padding(
            padding: _open ? const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter) : EdgeInsets.zero,
            child: GzCompareTray(
              key: const ValueKey<String>('discover.tray'),
              venues: venues,
              collapsed: !_open,
              onOpen: () => nav.push('CL-SAVD-04', params: const <String, Object?>{'from': 'discover'}),
              onRemove: (id) => ref.read(compareProvider.notifier).remove(id),
              onClear: () => ref.read(compareProvider.notifier).clear(),
              onExpand: () {
                setState(() => _open = true);
                _arm();
              },
            ),
          ),
      ],
    );
  }
}
