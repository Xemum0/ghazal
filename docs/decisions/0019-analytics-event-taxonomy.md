# ADR 0019: Analytics event taxonomy for search, venue view, compare, booking and payment

| Field | Value |
|---|---|
| Status | proposed-needs-owner |
| Date | 2026-10-12 |
| Scope | Event registry, common properties, search, venue view, compare, booking, payment, venue-facing definitions, delivery and privacy for both apps, the prototype inspector and the API |
| Owner must confirm | OQ-L-11 (analytics stack, consent model, retention; legal review of Kuwait data-privacy rules), OQ-L-12 (definitions of Views, Clicks and Revenue; which roles see revenue), OQ-T-14 (tool and consent model) |
| Related ADRs | 0003 (status values used by `booking_status_changed`), 0001 (modes), 0008 (hotel app events), 0009 (compare events), 0018 (impression surfaces), 0020 (server events), 0022 (Analytics interface), 0027 (payment webhooks are authoritative) |

## Context

The PRD names five tracked events (NF-ANL-01..05: search, venue view, comparison, booking, payment) but no tool, schema or consent model (flagged as a gap). The hotel app's analytics (HA-ANLY-01..07: views, clicks, bookings, revenue, conversion, top packages, date filter) and the Super Admin analytics must be computed from the same data, and NF-MET-03 wants the share of bookings that used comparison to be a measurable join rather than a guess. Constraints:

- Money truth comes from the gateway webhook, not from the app's redirect (ADR 0027), so revenue and conversion must use server events.
- No IDFA or cross-app tracking: this avoids an App Tracking Transparency prompt and keeps the privacy posture simple.
- Account deletion must remove events keyed to the user (PL-CORE-10, NF-PRIV-01).
- Wedding planning spans 6-18 months, so retention must cover a full season plus a year-over-year comparison.
- The prototype should show the taxonomy firing so reviewers can verify it before any SDK exists.
- Venues will compare these numbers with their own records, so definitions must be explicit and stable.
- Event emission must not delay the 2-second home budget (ADR 0022 G).

## Decision

**1. Naming.** `object_verb_pastTense` in snake_case (`search_performed`, `venue_viewed`, `compare_changed`, `booking_submitted`, `payment_succeeded`); property names snake_case; enum values lowercase snake_case; IDs are opaque. Events live in one registry file (`packages/contracts/analytics/events.json`: name, owner, trigger, properties with types and enums, emitter client|server) validated by both apps and the API; an unregistered event fails CI. Every screen spec lists an `analytics:` array of the events it fires; the web prototype logs them to an on-page inspector with the same registry so reviewers see the taxonomy fire.

**2. Common properties on every event:** `event_id` (uuid, idempotency key), `ts_utc`, `session_id`, `anon_id` (random per install, no IDFA/GAID), `user_id` (null for guests), `app` (client|hotel), `app_version`, `platform` (ios|android|web_prototype), `lang` (ar|en), `digit_style`, `is_guest`, `screen_id`, `network` (online|offline_replay). Money is `amount_fils` plus `currency: "KWD"`; event dates are Kuwait-local `YYYY-MM-DD`.

**3. Search and discovery (NF-ANL-01).**

- `search_performed`: a results state settled for a new query, filter or sort (debounced 800 ms, one per `query_id`). Properties: `query_id`, `entry_point` (hero|quick_category|see_all|map|deeplink|wishlist), `text_query` (scrubbed, at most 60 chars, null if none), `event_date`, `date_lead_days`, `area_ids[]`, `guests`, `guests_bucket`, `budget_band_id`, `price_min_fils`, `price_max_fils`, `attendance[]` (ladies|men|mixed), `setting[]`, `amenities[]`, `instant_only`, `available_on_date`, `min_rating`, `luxury_levels[]`, `brand_ids[]`, `sort`, `result_count`, `zero_results`, `latency_ms`.
- `filter_applied`, `filter_cleared`, `sort_changed`, `hero_edited` (field date|area|guests|budget).
- `venue_impression`: card at least 50% visible for 1 s, once per `query_id` or `shelf_id` and venue, batched. Properties: `venue_id`, `surface` (results|home_shelf|wishlist|similar), `shelf_id`, `position`, `placement` (organic|featured|sponsored|offer).
- `venue_card_tapped`: `venue_id`, `surface`, `shelf_id`, `query_id`, `position`, `placement`.

**4. Venue view (NF-ANL-02).**

- `venue_viewed`: `venue_id`, `view_id`, `source` (results|home_shelf|compare|wishlist|similar|notification|deeplink|share|chat), `query_id`, `position`, `date_set`, `availability_state` (available|held|booked|unknown), `est_total_fils`, `guests`.
- `venue_view_ended`: `view_id`, `dwell_ms`, `max_scroll_pct`, `zones_viewed[]`, `gallery_images_viewed`.
- `gallery_opened` (zone), `video_played` (media_id, completed_pct), `availability_date_selected` (date, state, mode availability|prices), `estimate_changed` (guests), `wishlist_changed` (item_type, item_id, action, surface), `share_initiated` (object venue|compare|booking, channel whatsapp|system_sheet|copy_link).
- `venue_cta_clicked`: `venue_id`, `cta` (book|chat|call|whatsapp|directions|share|notify_date|ministry_handoff|instagram), `surface`.

**5. Compare (NF-ANL-03).**

- `compare_changed`: `venue_id`, `action` (added|removed|replaced), `set_size_after`, `surface`, `replaced_venue_id`.
- `compare_viewed`: `compare_id`, `venue_ids[]`, `diff_only`, `hidden_rows`.
- `compare_book_clicked`: `compare_id`, `venue_id`, `position_in_set`. `compare_shared`: `compare_id`, `format` (image|link).
- `compare_id` carries into `booking_started.from_compare_id` and is copied to the booking record, so the share of bookings that used comparison (NF-MET-03) is a join, not a guess.

**6. Booking (NF-ANL-04).**

- *Client:* `booking_started` (`booking_draft_id`, `venue_id`, `hall_ids[]`, `entry` card|details|compare|calendar, `mode` instant|request, `sections[]`, `event_date`, `lead_days`, `from_compare_id`); `booking_step_viewed` and `booking_step_completed` (`step` 1-5, `step_key` date_session|package_extras|guests_details|review_send|deposit, `duration_ms`); `auth_prompted` and `auth_completed` (`context` booking|chat|wishlist_sync, `method` whatsapp_otp|apple|google|email); `booking_conflict_shown` (`reason` date_taken|session_taken|hold_expired); `booking_review_viewed` (`total_fils`, `deposit_fils`, `guests`, `sections_count`, `extras_count`); `booking_submitted` (`booking_id`, `booking_draft_id`, `mode`, `total_fils`, `deposit_fils`, `event_date`, `sections[]`, `package_ids[]`); `booking_abandoned` (draft left or app backgrounded over 30 min; `last_step_key`).
- *Server (authoritative):* `booking_status_changed` (`booking_id`, `from_status`, `to_status`, `reason_code` none|expired|declined_by_venue|cancelled_by_client|cancelled_by_venue|authority_order|date_hold_lapsed|completed_auto|completed_manual, `actor` client|venue|system, `elapsed_ms_since_submit`). Status values come from the booking state-machine ADR (0003); analytics never invents a status.
- *Hotel app:* `request_viewed`, `request_accepted`, `request_declined` (`reason_code`), `request_counter_offered` (`dates_count`), each with `response_time_ms`; `today_viewed`, `calendar_viewed` (`mode`), `dates_blocked` (`count`, `reason`), `offer_published` (`type`, `discount_pct`, `dates_count`), `analytics_viewed` (`range`).

**7. Payment (NF-ANL-05).**

- *Client (advisory):* `payment_started` (`payment_id`, `booking_id`, `kind` deposit|balance|full, `method` knet|visa|mastercard|apple_pay|google_pay|cash, `amount_fils`, `methods_shown[]`), `payment_redirected`, `payment_returned` (`return_state` success|cancel|timeout|unknown).
- *Server (authoritative, from the gateway webhook, PL-PAY-02):* `payment_succeeded` (`payment_id`, `amount_fils`, `method`), `payment_failed` (`failure_class` user_cancelled|declined|limit_exceeded|timeout|three_ds_failed|gateway_error), `payment_pending_shown`, `refund_initiated` and `refund_completed` (`payment_id`, `amount_fils`, `reason_code`). Revenue and conversion use server events only; if client and server disagree, server wins.

**8. Supporting events (MVP minimum):** `app_opened`, `onboarding_step_completed`, `language_changed`, `digit_style_changed`, `notification_opened`, `review_submitted`, `chat_started`, `planner_consultation_requested`.

**9. Venue-facing definitions** (what the hotel app shows).

| Metric | Definition |
|---|---|
| Views | distinct identity (`user_id` or `anon_id`) and venue per 30 minutes of `venue_viewed` |
| Clicks | count of `venue_cta_clicked` (intent clicks after a view) |
| Requests | `booking_submitted` |
| Confirmed | `booking_status_changed` to `confirmed` |
| Conversion | Confirmed divided by Views over the same period, attributed to the last venue view in a 30-day window |
| Funnel | Views, Clicks, Requests, Confirmed |
| Impressions | captured, not shown in the MVP |
| Revenue | booked value (sum of totals of confirmed bookings by event month) with received amount (by payment date) as the sub-line, pending the owner's definition (OQ-L-12) |

Admin: most searched areas from `search_performed.area_ids`; peak booking months from the `event_date` month of `booking_submitted`; cancellation rate from `booking_status_changed`.

**10. Delivery and integrity.** The client batches up to 20 events or 30 s, persists up to 500 events for 7 days offline, and sends at-least-once; the server deduplicates on `event_id`. Server timestamps are recorded on receipt next to client timestamps; reports bucket by Asia/Kuwait day. Analytics SDKs initialise after first frame (2 s budget).

**11. Privacy.** Never in an event: name, phone, email, Civil ID, IBAN, card data, chat or review text, special-request text. `text_query` is scrubbed of emails and phone-like digit runs and kept 90 days. First-party events are the source of truth for venue and admin analytics; a third-party SDK is optional for marketing attribution only. No IDFA or cross-app tracking, so no ATT prompt. Settings has a `Share usage data` toggle (default on; off leaves only server-side transactional events). Account deletion deletes events keyed to the user and unlinks `anon_id`. Raw events are kept 13 months, then aggregated (one full season plus a year-over-year comparison). Legal confirmation under Kuwait's data-privacy rules is required before launch (OQ-L-11).

## Consequences

- One registry means both Flutter apps, the prototype and the API cannot drift; NF-MET-03 and every HA-ANLY tile become straightforward queries; funnels are computed from server truth for money.
- The registry is a new artifact to maintain, and `analytics:` lines in every screen spec add authoring work (ADR 0024 item 6).
- Definitions of Views, Clicks and Revenue are product decisions that venues will compare to their own records; getting them wrong erodes trust.
- Long retention and a user-keyed store create privacy obligations (deletion, export) that engineering must honour.
- Implementation hooks: a thin `Analytics` interface in `ghazal_core` with a first-party sink (ADR 0022 H); an API ingestion endpoint that deduplicates on `event_id`; server events emitted from the booking state machine (ADR 0003) and the payment webhook handler (ADR 0027).
- Hotel analytics charts follow ADR 0014 item 5 (mirrored time axes, table twin).
- Firebase Analytics and Crashlytics behind the interface remain acceptable as an optional mirror (OQ-T-14 working assumption).

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Third-party SDK as the source of truth (Firebase Analytics, Mixpanel, Amplitude) | Venue and admin analytics, money and deletion obligations need first-party, server-authoritative data; SDK optional for marketing attribution only |
| Client-reported revenue and conversion | App redirects are untrusted (ADR 0027); server webhook events only |
| Free-form event names per team | Drift; one registry and CI rejection of unregistered events |
| camelCase or mixed-case names | One convention (`object_verb_pastTense`, snake_case) |
| Session-based Views | Distinct identity per 30 minutes is simpler to explain to venues |
| IDFA or cross-app attribution | Requires an ATT prompt and weakens the privacy posture |
| Indefinite raw retention | 13 months then aggregate; deletion on account removal |
| Logging PII or free text in events | Names, phones, emails, chat, review and request text are never logged |
| Impressions shown to venues in the MVP | Captured but not shown until definitions settle |

## Related requirement IDs

| ID | Effect |
|---|---|
| NF-ANL-01..05 | Search, venue view, comparison, booking and payment events |
| NF-MET-01, NF-MET-03 | Time to complete a request; share of bookings that used comparison |
| HA-ANLY-01..07 | Views, clicks, bookings, revenue, conversion, top packages, date range |
| SA-ANLY-01..08 | Super Admin analytics from the same events |
| PL-CORE-09 | Analytics store aggregates events |
| NF-PRIV-01, PL-CORE-10 | Deletion removes events keyed to the user |
| CA-PROF-08 | Settings holds the `Share usage data` toggle |

## Notes on conflicting inputs

- **Step keys.** `step_key` in item 6 lists five keys (date_session, package_extras, guests_details, review_send, deposit), which follow the competitive-ux grouping of 4 pre-send phases plus a deposit phase. ADR 0001 D12 fixes the booking flow as five steps: Your event, Package, Extras, Your details, Review (then outcome). The registry needs the 0001 step keys (for example `your_event`, `package`, `extras`, `your_details`, `review`) before it is frozen; the deposit is a separate session in request mode, not step 5.
- **Reason codes.** `booking_status_changed.reason_code` above overlaps but does not match ADR 0003 D1 (`reason_code` includes `authority_order`; `expired_reason` is `venue_no_response | client_no_payment | slot_taken | client_no_response`; `cancelled_by` is a separate field). The registry should adopt ADR 0003's fields; analytics must not invent values.
- `payment_started.method` includes `cash`, but cash is recorded by the venue for the balance only (ADR 0005 D6) and never goes through the gateway; treat it as a venue-recorded event, not a client payment method.
- **Amendment 2026-10-12 (architecture README #18).** `reason_code` values here differ from ADR 0003's reason codes; the mapping is in booking-state-machine section 11 and ADR 0003 owns the values.
