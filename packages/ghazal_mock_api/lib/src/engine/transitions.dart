/// The request state machine of docs/architecture/booking-state-machine.md section 4 as a pure table (ADR 0033 D3). The handlers, the
/// contract tests and the TypeScript engine read the same rows. Port of engine/transitions.ts.
library;

class Transition {
  const Transition(this.id, this.from, this.to, this.command, this.actor, this.voucher, this.guard);
  final String id;
  final String? from;
  final String to;
  final String command;

  /// `client`, `venue`, `system` or `admin`.
  final String actor;

  /// Where the voucher goes: bind, release, release_credit_eligible, keep, use, consume, forfeit, none.
  final String voucher;
  final String guard;

  Map<String, dynamic> toJson() => {'id': id, 'from': from, 'to': to, 'command': command, 'actor': actor, 'voucher': voucher, 'guard': guard};
}

const transitions = <Transition>[
  Transition('R01', null, 'pending', 'SendRequest', 'client', 'bind', 'signed in, verified phone, active voucher bound to this target and quote, fewer than 3 open requests, slot not booked or blocked'),
  Transition('R03', 'pending', 'approved', 'Approve', 'venue', 'keep', 'hold insertable; optional lower voucher price, never higher; starts the 24 h confirm window'),
  Transition('R03u', 'approved', 'pending', 'UndoApprove', 'venue', 'keep', 'before undo_until (8 s) only'),
  Transition('R04', 'pending', 'declined', 'Decline', 'venue', 'release_credit_eligible', 'reason required'),
  Transition('R05', 'pending', 'approved', 'AcceptProposal', 'client', 'keep', 'counter-offer open, 1-3 dates, voucher price held, valid 48 h; the 24 h confirm window starts'),
  Transition('R06', 'pending', 'expired', 'ExpireRequest', 'system', 'release_credit_eligible', 'respond_by passed (venue_no_response)'),
  Transition('R07', 'pending', 'cancelled', 'Withdraw', 'client', 'release', 'none (free)'),
  Transition('R08', 'approved', 'confirmed', 'Confirm', 'client', 'keep', 'before confirm_by (24 h after approval); claim still active'),
  Transition('R09', 'approved', 'expired', 'ExpireApproval', 'system', 'forfeit', 'confirm_by passed (client_no_confirmation): the voucher is not valid, never comes back'),
  Transition('R10a', 'approved', 'cancelled', 'CancelApproved', 'client', 'release', 'none for the client'),
  Transition('R10b', 'approved', 'cancelled', 'Revoke', 'venue', 'release_credit_eligible', 'Admin or Manager, reason required, reliability strike'),
  Transition('R11', 'confirmed', 'redeemed', 'RedeemVoucher', 'venue', 'use', 'code belongs to this partner; request confirmed; voucher bound and not used'),
  Transition('R12a', 'confirmed', 'completed', 'Complete', 'system', 'use', 'event end plus 12 h'),
  Transition('R12b', 'redeemed', 'completed', 'Complete', 'system', 'keep', 'event end plus 12 h'),
  Transition('R13a', 'confirmed', 'cancelled', 'ClientCancel', 'client', 'consume', 'voucher consumed (cancelled_after_confirm), no money back'),
  Transition('R13b', 'confirmed', 'cancelled', 'VenueCancel', 'venue', 'release_credit_eligible', 'Admin or Manager, reason required, reliability strike'),
];

/// Statuses that never change again (R14 admin override aside).
const terminalStatuses = ['declined', 'expired', 'cancelled', 'completed'];

/// Statuses that count against the open-request limit of a wedding file.
const openStatuses = ['pending', 'approved'];

List<Transition> transitionsFrom(String? status) => transitions.where((t) => t.from == status).toList();

bool canTransition(String? from, String to) => transitions.any((t) => t.from == from && t.to == to);

Transition? transitionById(String id) {
  for (final t in transitions) {
    if (t.id == id) return t;
  }
  return null;
}

/// The voucher status that goes with each booking status while the voucher is attached (booking-state-machine section 3).
String voucherStatusFor(String status) {
  switch (status) {
    case 'pending':
    case 'approved':
    case 'confirmed':
      return 'bound';
    case 'redeemed':
    case 'completed':
      return 'used';
    default:
      return 'active';
  }
}
