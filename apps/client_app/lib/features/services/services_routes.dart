// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `servicesRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `services` (CL): 4 screens. Wedding services
List<RouteBase> get servicesRoutes => <RouteBase>[
  GoRoute(
    path: '/services/services-hub',
    name: 'CL-SERV-01',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-SERV-01',
      titleEn: 'Additional services',
      titleAr: 'الخدمات الإضافية',
      kind: 'screen',
      purpose: 'The Additional services hub for post-venue needs: five primary categories (Hospitality and catering, Buffet services, Floral arrangements, Event styling and decor, Event planning and coordination) as large tiles, then "More services" (the secondary categories) as a compact list, a planner entry card and a way back to venues. Also where the governmental-facility "Find catering and decor" link land…',
    ),
  ),
  GoRoute(
    path: '/services/category-list',
    name: 'CL-SERV-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-SERV-02',
      titleEn: 'Vendors',
      titleAr: 'مقدّمو الخدمة',
      kind: 'screen',
      purpose: 'Vendors in one category with name, rating, starting price and photos, plus area, price and rating filters and sort.',
    ),
  ),
  GoRoute(
    path: '/services/vendor-profile',
    name: 'CL-SERV-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-SERV-03',
      titleEn: 'Vendor profile',
      titleAr: 'ملف مقدّم الخدمة',
      kind: 'screen',
      purpose: 'Description, portfolio, packages with prices, reviews and an honest availability line for one vendor. Actions: Request quote, Save, Add to budget.',
    ),
  ),
  GoRoute(
    path: '/services/request-quote',
    name: 'CL-SERV-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-SERV-04',
      titleEn: 'Request a quote',
      titleAr: 'طلب عرض سعر',
      kind: 'sheet',
      purpose: 'A short structured enquiry that becomes a card in a new vendor chat thread. Hard-gated, with everything typed preserved through sign-in.',
    ),
  ),
];
