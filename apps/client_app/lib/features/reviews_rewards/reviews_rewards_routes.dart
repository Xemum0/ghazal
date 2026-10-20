// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `reviewsRewardsRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `reviews-rewards` (CL): 2 screens. Reviews and rewards
List<RouteBase> get reviewsRewardsRoutes => <RouteBase>[
  GoRoute(
    path: '/reviews-rewards/reviews-list',
    name: 'CL-RVRW-01',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-RVRW-01',
      titleEn: 'Reviews',
      titleAr: 'التقييمات',
      kind: 'screen',
      purpose: 'All reviews for one venue: rating summary with the four categories, filters, review cards with owner replies and a report control on every review. Reached from the Venue detail reviews block.',
    ),
  ),
  GoRoute(
    path: '/reviews-rewards/write-review',
    name: 'CL-RVRW-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-RVRW-02',
      titleEn: 'Write a review',
      titleAr: 'كتابة تقييم',
      kind: 'screen',
      purpose: 'Rate a completed booking: overall stars, four category scores, a comment, and optional photos or videos that follow the no-people rule. Reached from the morning-after prompt, the Completed Booking detail and the My Wedding post-event card.',
    ),
  ),
];
