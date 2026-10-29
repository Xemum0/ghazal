// Category sheet (web `CategorySheet.tsx`): the categories of an account, the five primary first, then "More". Up to [max] can be chosen; the
// unchosen chips disable once the limit is reached.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

class CategorySheet extends StatefulWidget {
  const CategorySheet({required this.categories, required this.value, required this.max, required this.onApply, super.key});

  final List<ServiceCategory> categories;
  final List<ServiceCategoryId> value;
  final int max;
  final ValueChanged<List<ServiceCategoryId>> onApply;

  @override
  State<CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<CategorySheet> {
  late List<ServiceCategoryId> _pick = widget.value;

  Widget _group(BuildContext context, bool primary, String label) {
    final lang = context.gz.locale.languageCode;
    final full = _pick.length >= widget.max;
    final items = widget.categories.where((c) => c.primary == primary).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GzText(label, role: GzTextRole.label, color: context.gz.colors.textSecondary),
          const SizedBox(height: GzSpace.s3),
          GzChipGroup<ServiceCategoryId>.multiple(
            label: label,
            values: _pick,
            onChanged: (v) => setState(() => _pick = v.length > widget.max ? v.sublist(0, widget.max) : v),
            options: [
              for (final c in items)
                GzChipOption<ServiceCategoryId>(
                  value: c.id,
                  label: c.name.of(lang),
                  icon: GzIcons.byName[c.icon],
                  disabled: full && !_pick.contains(c.id),
                  figures: false,
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // the web sheet frame spaces its head and its body by space-4 (`.hp-sheet { gap }`); the kit sheet's title row has no gap below it and is
        // about 3 dp taller than the web head, so the measured gap that lands the counter on the web's line is space-3
        const SizedBox(height: GzSpace.s3),
        GzText(l.hotelProviderCatsLimit(_pick.length, widget.max), role: GzTextRole.bodyS, color: c.textSecondary, figures: true),
        _group(context, true, l.hotelProviderCatsPrimary),
        _group(context, false, l.hotelProviderCatsMore),
        const SizedBox(height: GzSpace.s4),
        GzSheetFooter(child: GzButton(label: l.commonActionDone, fullWidth: true, onPressed: () => widget.onApply(_pick))),
      ],
    );
  }
}
