import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/discover_filters.dart';
import 'discover_labels.dart';

/// The small Sort sheet (never mixed with filtering): one radio list of the orders; choosing one applies it and closes. The group's name
/// is the sheet title, so the list is announced as "Sort by".
class SortSheet extends ConsumerWidget {
  const SortSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final value = ref.watch(discoverStateProvider.select((s) => s.sort));
    final labels = DiscoverLabels(context);
    final nav = context.gzNav;
    return Column(
      key: const ValueKey<String>('discover.sort'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSheetHeader(title: l.clientDiscoverSortTitle, onClose: nav.closeSheet),
        const SizedBox(height: GzSpace.s2),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
          child: GzRadioGroup<DiscoverSort>(
            label: l.clientDiscoverSortTitle,
            value: value,
            onChanged: (v) {
              ref.read(discoverStateProvider.notifier).setSort(v);
              nav.closeSheet();
            },
            children: [
              for (var i = 0; i < kSorts.length; i++)
                Container(
                  constraints: const BoxConstraints(minHeight: GzSize.controlLg),
                  decoration: BoxDecoration(border: i == kSorts.length - 1 ? null : Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
                  child: GzRadio<DiscoverSort>(key: ValueKey<String>('discover.sort.${kSorts[i].name}'), value: kSorts[i], label: labels.sort(kSorts[i])),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
