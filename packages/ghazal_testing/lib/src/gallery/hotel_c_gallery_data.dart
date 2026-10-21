// Real objects for the hotel part C gallery (the Aurelia Gulf Hotel, V01): the hero request in four of its states with its voucher,
// the venue with its photographs, the packages with their weekend price rules, staff, office hours and reviews, all fetched through
// the partner repositories of the in-process mock, exactly the path the partner app takes.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:path/path.dart' as p;

import '../world.dart';

const String hotelVenueId = 'V01';
const String _storyBookingId = 'bk-GZ-2611-0147';

/// The persona of the partner galleries: the hotel manager of V01 (Admin and manager see every action of these components).
const String hotelPersona = 'hotel_manager';

class HotelCData {
  HotelCData._({
    required this.pending,
    required this.approved,
    required this.confirmed,
    required this.redeemed,
    required this.counter,
    required this.venue,
    required this.area,
    required this.flash,
    required this.packages,
    required this.staff,
    required this.hours,
    required this.reviews,
    required this.notifications,
    required this.images,
  });

  final PartnerRequestDetail pending;
  final PartnerRequestDetail approved;
  final PartnerRequestDetail confirmed;
  final PartnerRequestDetail redeemed;
  final PartnerRequestDetail counter;
  final Venue venue;
  final LocalizedText? area;
  final VoucherWindow flash;
  final List<PackageEditor> packages;
  final List<StaffMember> staff;
  final List<HoursRule> hours;
  final List<Review> reviews;
  final List<AppNotification> notifications;

  /// File bytes of the venue photographs by their gallery file (MemoryImage: FileImage never completes under fake async).
  final Map<String, ImageProvider> images;

  ImageProvider? imageFor(String src) => images[src];

  static Future<HotelCData> load(GzWorld world) async {
    final repos = world.repos(hotelPersona, venueId: hotelVenueId);
    Future<PartnerRequestDetail> story(String point) async {
      world.control.jumpToStory(point);
      return repos.partnerRequests.getPartnerRequest(requestId: _storyBookingId);
    }

    final pending = await story('pending');
    final approved = await story('approved');
    final confirmed = await story('confirmed');
    final redeemed = await story('redeemed');
    final counter = await story('counter_offer');
    world.control.jumpToStory('pending');
    final detail = await repos.venues.getVenue(venueId: hotelVenueId);
    final catalog = await repos.partnerVenue.listPartnerPackages();
    final staff = await repos.partnerAccount.listStaff();
    final hours = await repos.partnerVenue.getBusinessHours();
    final reviews = await repos.partnerReviews.listPartnerReviews(limit: 50);
    final notes = await repos.notifications.listNotifications(limit: 5);
    final areas = await repos.venues.listAreas();
    final images = <String, ImageProvider>{};
    final dir = p.join(Directory.current.path, '..', 'ghazal_mock_api', 'assets', 'images');
    for (final g in detail.venue.gallery.take(8)) {
      final name = p.basenameWithoutExtension(g.file);
      final file = File(p.join(dir, '${name}_480.jpg'));
      if (file.existsSync()) images[g.file] = MemoryImage(file.readAsBytesSync());
    }
    return HotelCData._(
      pending: pending,
      approved: approved,
      confirmed: confirmed,
      redeemed: redeemed,
      counter: counter,
      venue: detail.venue,
      area: areas.areas.where((a) => a.id == detail.venue.areaId).map((a) => a.name).firstOrNull,
      flash: detail.windows.firstWhere((w) => w.id == 'vw-V01-flash'),
      packages: catalog.packages.where((e) => e.package.venueId == hotelVenueId).toList(),
      staff: staff.staff.where((s) => s.venueId == hotelVenueId).toList(),
      hours: hours.rules,
      reviews: reviews.items,
      notifications: notes.items,
      images: images,
    );
  }
}
