import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, venuesRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/venue_providers.dart';
import 'venue_glyphs.dart';
import 'widgets/venue_hero.dart';

/// CL-VENU-02 Photos and videos. Covers CA-VDET-01, CA-VDET-02, CA-CARD-02.
///
/// The full-screen photo tour as a route: zone chips as a photo tour, pinch and double-tap zoom, a counter that stays
/// left to right, video starting only on tap from its poster. The venue page hero opens this same viewer in place from
/// the photograph itself; this screen is the viewer as a route (from the compare photo strips, a deep link). No tab bar.
class ClVenu02Screen extends ConsumerStatefulWidget {
  const ClVenu02Screen({super.key});

  @override
  ConsumerState<ClVenu02Screen> createState() => _ClVenu02State();
}

class _ClVenu02State extends ConsumerState<ClVenu02Screen> {
  @override
  Widget build(BuildContext context) {
    final params = VenueParams.of(context.gzNav.params);
    final detail = ref.watch(_venueDetailProvider(params.venueId));
    return GzAsyncView<VenueDetail>(
      value: detail,
      onRetry: () => ref.invalidate(_venueDetailProvider(params.venueId)),
      loading: const _ViewerSkeleton(),
      data: (d) => _Viewer(venueId: d.venue.id, venue: d.venue, start: params),
    );
  }
}

/// The venue of the viewer: the route param, else the hero hotel (a dead link still tours the hero gallery).
final _venueDetailProvider = FutureProvider.autoDispose.family<VenueDetail, String>((ref, venueId) async {
  final venues = ref.watch(venuesRepositoryProvider);
  try {
    return await venues.getVenue(venueId: venueId);
  } on Object {
    return venues.getVenue(venueId: kHeroVenueId);
  }
});

class _Viewer extends ConsumerStatefulWidget {
  const _Viewer({required this.venueId, required this.venue, required this.start});

  final String venueId;
  final Venue venue;
  final VenueParams start;

  @override
  ConsumerState<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends ConsumerState<_Viewer> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = 0;
  }

  @override
  Widget build(BuildContext context) {
    final gallery = VenueGallery(context, widget.venue);
    final images = gallery.images;
    if (images.isEmpty) {
      return GzScreen(
        top: GzTopBar(title: context.l10n.clientVenueGalleryZones, back: GzTopBarBack.auto),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.section),
          child: Center(
            child: GzIllustration(GzIllustrationName.camera, size: GzIllustrationSize.lg, semanticLabel: context.l10n.clientVenueNoPhotos),
          ),
        ),
      );
    }
    final start = context.gzNav.params['index'];
    final initial = (start is int ? start : 0).clamp(0, images.length - 1);
    if (_index >= images.length) _index = initial;
    final zones = gallery.zones;
    final zoneOf = gallery.zoneOf;
    final current = _index.clamp(0, images.length - 1);
    final selected = zoneOf[current];
    final caption = gallery.captions[current];
    final l = context.l10n;
    final mq = MediaQuery.of(context);

    void selectZone(MediaZone z) {
      final first = zoneOf.indexOf(z);
      if (first >= 0) setState(() => _index = first);
    }

    // The viewer's own stage collapses to zero under the Stack's loose constraints (a ColoredBox with no child):
    // this backing is the dark stage it would draw itself in its route.
    return ColoredBox(
      color: context.gz.colors.surfaceDark,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The stage is the dark backing; the photograph hugs its own frame (the web `.gzv-gal__photo` is transparent), so the
          // kit's placeholder tone must not paint the whole page.
          GzTheme(
            locale: context.gz.locale,
            colors: context.gz.colors.copyWith(surfacePlaceholder: context.gz.colors.surfacePlaceholder.withAlpha(0)),
            child: GzGalleryViewer(
              images: images,
              label: l.clientVenueGalleryLabel(context.bi(widget.venue.name)),
              initialIndex: initial,
              index: _index,
              onIndexChanged: (i) => setState(() => _index = i),
              onClose: () => context.gzNav.pop(),
              heroGroup: 'venue-hero-${widget.venue.id}',
            ),
          ),
          PositionedDirectional(
            top: mq.padding.top + GzSize.controlLg + GzSpace.s2,
            start: 0,
            end: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
              child: Semantics(
                container: true,
                label: l.clientVenueGalleryZones,
                child: Row(
                  children: [
                    for (final z in zones) ...[
                      _ZoneChip(selected: z == selected, zone: z, onPressed: () => selectZone(z)),
                      const SizedBox(width: GzSpace.s2),
                    ],
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: mq.padding.bottom + GzSpace.s4 + GzSize.knotBead + GzSpace.s2,
            start: GzSpace.gutter,
            end: GzSpace.gutter,
            child: GzText(caption, role: GzTextRole.caption, color: context.gz.colors.textOnDark),
          ),
        ],
      ),
    );
  }
}

/// The photo tour chip of the dark stage (web `.gzv-gal__chip`): the zone glyph alone, the gold bead under the chosen one.
class _ZoneChip extends StatelessWidget {
  const _ZoneChip({required this.selected, required this.zone, required this.onPressed});

  final bool selected;
  final MediaZone zone;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final fg = selected ? c.textOnDark : c.textOnDarkMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: zoneName(context.l10n, zone),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minWidth: GzSize.controlMd, minHeight: GzSize.controlSm),
          padding: const EdgeInsets.symmetric(horizontal: GzSpace.s2),
          decoration: BoxDecoration(
            color: c.surfaceDarkRaised,
            borderRadius: GzRadius.smAll,
            border: Border.all(color: selected ? c.textOnDark : c.borderOnDark, width: GzStroke.hair),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GzIcon(zoneGlyph(zone), size: GzIconSize.md, color: fg),
              const SizedBox(height: GzSpace.s1),
              Transform.rotate(
                angle: 0.7853981633974483,
                child: SizedBox(
                  width: GzSize.knotBead,
                  height: GzSize.knotBead,
                  child: ColoredBox(color: selected ? c.markKhayt : c.markKhayt.withAlpha(0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewerSkeleton extends StatelessWidget {
  const _ViewerSkeleton();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.gz.colors.surfaceDark,
    child: const Center(child: ExcludeSemantics(child: GzSkeleton(inlineSize: 200, blockSize: 200))),
  );
}

// Edges (inventory navigatesTo): 'CL-VENU-01' (close and swipe-back return to the detail).
