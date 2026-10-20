import 'package:flutter/widgets.dart';

import '../../l10n/generated/gz_localizations.dart';
import '../theme/gz_fonts.dart';
import '../tokens/placeholder_tokens.dart';

/// A clearly labelled "Not built yet" screen for an inventory screen with no Flutter implementation.
/// Unbuilt screens stay visible on purpose: the final sweep fails on any route that still renders this widget.
/// `tools/gen-routes.mjs` emits one per inventory screen; a flow agent replaces it with the real screen.
class GzStubScreen extends StatelessWidget {
  const GzStubScreen({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.kind,
    this.purpose = '',
    super.key,
  });

  /// Inventory id, for example `CL-DISC-01`.
  final String id;
  final String titleEn;
  final String titleAr;

  /// Inventory kind: `screen`, `sheet` or `tab-root`.
  final String kind;

  /// Inventory purpose text (English, developer-facing, shown on stubs only).
  final String purpose;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isAr = locale.languageCode == 'ar';
    final title = isAr ? titleAr : titleEn;
    final ui = GzFonts.uiFor(locale);
    final fallback = GzFonts.fallbackFor(locale);
    TextStyle style(double size, FontWeight weight, Color color, {String? family}) => TextStyle(
          fontFamily: family ?? ui,
          fontFamilyFallback: fallback,
          package: GzFonts.package,
          fontSize: size,
          fontWeight: weight,
          height: 1.45,
          letterSpacing: 0,
          color: color,
          leadingDistribution: TextLeadingDistribution.even,
        );
    return ColoredBox(
      color: GzPlaceholderColors.canvas,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: GzPlaceholderColors.gold100,
                  border: Border.all(color: GzPlaceholderColors.gold500),
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    GzL10n.of(context).stubNotBuilt,
                    style: style(13, FontWeight.w700, GzPlaceholderColors.ink900),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(id, style: style(15, FontWeight.w600, GzPlaceholderColors.ink700)),
              ),
              const SizedBox(height: 8),
              Text(title, style: style(32, FontWeight.w600, GzPlaceholderColors.ink900, family: GzFonts.display)),
              const SizedBox(height: 4),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(kind, style: style(13, FontWeight.w400, GzPlaceholderColors.ink700)),
              ),
              if (purpose.isNotEmpty) ...[
                const SizedBox(height: 16),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    purpose,
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: style(14, FontWeight.w400, GzPlaceholderColors.ink700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One entry of the stub tab bar.
class GzStubTab {
  const GzStubTab({required this.titleEn, required this.titleAr});

  final String titleEn;
  final String titleAr;
}

/// PLACEHOLDER tab bar for the tab shell (labels always visible; order mirrors in RTL because it is a Row).
/// Replaced by `GzTabBar` in phase F2.
class GzStubTabBar extends StatelessWidget {
  const GzStubTabBar({required this.tabs, required this.currentIndex, required this.onTap, super.key});

  final List<GzStubTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isAr = locale.languageCode == 'ar';
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: GzPlaceholderColors.paper,
        border: Border(top: BorderSide(color: GzPlaceholderColors.ink300)),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(bottom: bottom),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Center(
                      child: Text(
                        isAr ? tabs[i].titleAr : tabs[i].titleEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: GzFonts.uiFor(locale),
                          fontFamilyFallback: GzFonts.fallbackFor(locale),
                          package: GzFonts.package,
                          fontSize: 12,
                          fontWeight: i == currentIndex ? FontWeight.w700 : FontWeight.w400,
                          letterSpacing: 0,
                          color: i == currentIndex ? GzPlaceholderColors.ink900 : GzPlaceholderColors.ink700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
