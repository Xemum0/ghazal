import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show VenueResult, VenueSummary;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/state/state.dart' show compareProvider;
import '../../application/saved_data.dart';

/// Interaction timing, not animation: three idle seconds (ADR 0009 D3).
const Duration kSavedTrayIdle = Duration(seconds: 3);

/// The Compare tray docked under the Saved list (ADR 0009 D3): the list is shorter by the tray, so its last row is never covered. Collapses
/// to the 44 pill after three idle seconds and when the list scrolls down, returns on scroll-up or a tap on the pill. [collapsed] forces the
/// pill (a static frame shows the state it is told to).
class SavedTrayLayer extends ConsumerStatefulWidget {
  const SavedTrayLayer({this.collapsed = false, super.key});

  final bool collapsed;

  @override
  ConsumerState<SavedTrayLayer> createState() => _SavedTrayLayerState();
}

class _SavedTrayLayerState extends ConsumerState<SavedTrayLayer> {
  bool _idle = false;
  Timer? _timer;
  double _lastTop = 0;
  String _key = '';

  void _arm() {
    _timer?.cancel();
    _timer = Timer(kSavedTrayIdle, () {
      if (mounted) setState(() => _idle = true);
    });
  }

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ids = ref.watch(compareProvider.select((s) => s.venueIds));
    final key = ids.join('|');
    if (key != _key) {
      // any change of the set wakes the tray, then three idle seconds put it to sleep
      if (_key.isNotEmpty || ids.length > 1) _idle = false;
      _key = key;
      _arm();
    }
    final top = GzScreenScroll.of(context);
    final delta = top - _lastTop;
    if (delta.abs() >= GzSpace.s2) {
      _lastTop = top;
      if (delta > 0 && !_idle) {
        _timer?.cancel();
        _idle = true;
      } else if (delta < 0 && _idle) {
        _idle = false;
        _arm();
      }
    }
    final byId = ref.watch(briefRosterProvider).value ?? const <String, VenueResult>{};
    final venues = <VenueSummary>[
      for (final id in ids)
        if (byId[id] != null) byId[id]!.venue,
    ];
    if (venues.isEmpty) return const SizedBox.shrink();
    final collapsed = widget.collapsed || _idle;
    final nav = context.gzNav;
    return ColoredBox(
      color: context.gz.colors.surfaceCanvas,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          top: GzSpace.s2,
          bottom: GzSpace.s4,
          start: collapsed ? 0 : GzSpace.gutter,
          end: collapsed ? 0 : GzSpace.gutter,
        ),
        child: Align(
          alignment: AlignmentDirectional.center,
          child: GzCompareTray(
            key: const ValueKey<String>('saved.tray.dock'),
            venues: venues,
            collapsed: collapsed,
            onOpen: () => nav.push('CL-SAVD-04', params: const <String, Object?>{'from': 'saved'}),
            onRemove: (id) => ref.read(compareProvider.notifier).remove(id),
            onClear: () => ref.read(compareProvider.notifier).clear(),
            onExpand: () {
              setState(() => _idle = false);
              _arm();
            },
          ),
        ),
      ),
    );
  }
}
