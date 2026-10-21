import 'package:flutter/foundation.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show LocalizedText, PartnerAccountType, StaffRole;

/// The commit moments that open the guest gate sheet (web `GateReason`, ADR 0007 D8, ADR 0033).
enum GateReason {
  sendRequest,
  voucher,
  visit,
  chat,
  review,
  planner,
  quote,
  save;

  /// The web spelling (`send-request`), used in route params and analytics.
  String get wire => switch (this) {
        GateReason.sendRequest => 'send-request',
        _ => name,
      };

  static GateReason parse(Object? wire) => GateReason.values.firstWhere((r) => r.wire == wire, orElse: () => GateReason.save);
}

/// The signed-in person as the shell needs them: id, name, phone (E.164 for a client, display value for staff), monogram.
@immutable
final class AuthUser {
  const AuthUser({required this.id, required this.name, required this.phone, required this.monogram, this.email});

  final String id;
  final String name;
  final String phone;
  final String monogram;
  final String? email;

  @override
  bool operator ==(Object other) =>
      other is AuthUser && other.id == id && other.name == name && other.phone == phone && other.monogram == monogram && other.email == email;

  @override
  int get hashCode => Object.hash(id, name, phone, monogram, email);

  @override
  String toString() => 'AuthUser($id)';
}

/// Who is using the app: a guest (browsing, no token), a signed-in client or signed-in partner staff.
@immutable
sealed class AppSession {
  const AppSession();

  bool get isSignedIn;
}

/// Browsing without a token.
final class GuestSession extends AppSession {
  const GuestSession();

  @override
  bool get isSignedIn => false;

  @override
  bool operator ==(Object other) => other is GuestSession;

  @override
  int get hashCode => 0;
}

/// A signed-in client.
final class ClientSession extends AppSession {
  const ClientSession({required this.user, this.isNewUser = false, this.phoneVerified = true});

  final AuthUser user;

  /// The sign-in created the account (the name-and-terms step follows).
  final bool isNewUser;
  final bool phoneVerified;

  @override
  bool get isSignedIn => true;

  @override
  bool operator ==(Object other) =>
      other is ClientSession && other.user == user && other.isNewUser == isNewUser && other.phoneVerified == phoneVerified;

  @override
  int get hashCode => Object.hash(user, isNewUser, phoneVerified);
}

/// Signed-in partner staff, in one account context: a venue (hotel or hall) or a service provider.
final class PartnerSession extends AppSession {
  const PartnerSession({
    required this.user,
    required this.accountType,
    required this.role,
    this.accountId,
    this.venueId,
    this.providerId,
    this.accountName,
    this.feeExempt = false,
    this.permissions = const <String>[],
  });

  final AuthUser user;

  /// `venue` (hotels and halls, app prefix `hotel`) or `serviceProvider`.
  final PartnerAccountType accountType;
  final StaffRole role;
  final String? accountId;

  /// `X-Venue-Id` of every call (hotel or hall accounts).
  final String? venueId;

  /// `X-Provider-Id` of every call (service provider accounts).
  final String? providerId;

  /// The venue or business name in both languages (`accountName.of(languageCode)`).
  final LocalizedText? accountName;
  final bool feeExempt;
  final List<String> permissions;

  bool get isProvider => accountType == PartnerAccountType.serviceProvider;

  @override
  bool get isSignedIn => true;

  @override
  bool operator ==(Object other) =>
      other is PartnerSession &&
      other.user == user &&
      other.accountType == accountType &&
      other.role == role &&
      other.accountId == accountId &&
      other.venueId == venueId &&
      other.providerId == providerId &&
      other.accountName == accountName &&
      other.feeExempt == feeExempt &&
      listEquals(other.permissions, permissions);

  @override
  int get hashCode => Object.hash(user, accountType, role, accountId, venueId, providerId, accountName, feeExempt, Object.hashAll(permissions));
}
