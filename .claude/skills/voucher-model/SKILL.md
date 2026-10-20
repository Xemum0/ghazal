---
name: voucher-model
description: Quick facts of Ghazal's voucher marketplace model (ADR 0033) and where the source of truth lives. Use before writing or reviewing any screen, copy, fixture or doc that touches payment, price, voucher, request status, visits, partner fees or listings.
---
# Voucher model: quick facts

Sources of truth: `docs/decisions/0033-voucher-marketplace-model.md` (binding D1-D9; assumptions A-01..A-15 are proposed-needs-owner), `docs/product/voucher-model.md` (full flows), `docs/product/voucher-model-changes.json` (per-screen impact), `docs/architecture/pricing-and-payments.md`, `docs/product/open-questions.md` section 2b (OQ-V), `docs/product/owner-decisions.md`. If this file and the ADR disagree, the ADR wins.

- **Money:** the only in-app payment for clients is the voucher, KD 2.000 (`voucher_fee_fils`, configuration), online by KNET, cards, Apple Pay, Google Pay. Partners and providers pay listing or advertising fees (plans weekly, monthly, annual; rates NOT decided: UI says "Rates announced soon", no number anywhere; major hotels exempt via `fee_exempt`). All venue money (price, deposit, contract) is off-app: no deposits, balances, commission, payouts, venue bank details, refund tiers.
- **Voucher:** single-use code and QR, one per request, bound at purchase to one venue or provider and its quote (A-01); states `unpaid, active, bound, used, expired, refunded`; valid 60 days (A-02); offered only when the saving exceeds the fee; guests see prices but must register to buy. Arabic UI word: «كوبون».
- **Prices:** every package and priced extra has a standard and a voucher price on the same basis; struck-through "was" is always the standard price; the venue may approve lower, never higher.
- **Request statuses:** `pending, approved, declined, expired, confirmed, redeemed, completed, cancelled` (+ client `draft`). Approval opens a 24 h hold; the client must confirm within 24 h (countdown in hours and minutes, no seconds); the partner redeems by code or QR. No instant booking, no in-app reschedule after confirmation (A-05).
- **Apps:** Client app; Partner app = Hotel or hall (`venue`) and Service provider (`service_provider`) account types, one login may hold both (A-06). Tabs Today, Bookings, Calendar, Messages, More; providers get Listings in place of hall calendar.
- **Listings:** draft, payment, pending review, approved or rejected, active or expired; never auto-published on payment; every ad is moderated, major hotels included.
- **Visits:** free, independent of the voucher, hotels and halls only (A-10); each creates a group chat of client, hotel representative, Ghazal support (read-only 24 h after the slot).
- **Governmental facilities:** browse-only, official hand-off, no voucher (A-13).
- **Removed:** loyalty and rewards, venue offers and coupon codes, platform credit, commission, payout and revenue screens.
