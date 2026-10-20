# Research: Competitive & best-in-class UX patterns

> Produced by an independent analyst agent during the Understand phase (Oct 2026). Inputs to ADRs in `docs/decisions/`; where this file and an ADR disagree, **the ADR wins**.

## Key insights

- KNET is the constraint that reshapes the booking flow: via MyFatoorah, KNET transactions are always AuthorizeAndCapture (no hold-then-capture; Broadleaf's MyFatoorah KNET docs). The Airbnb/Peerspace 'hold the card, release on decline' model therefore cannot be the default in Kuwait. Recommended request-mode flow: send request with no charge -> venue approves -> date is held for the couple for ~24h -> couple pays the deposit to confirm. Instant-book venues charge the deposit immediately. This needs an 'Approved - awaiting deposit' sub-state (PRD gap #8 and the status list).
- Venue price is meaningless without a guest count. Wedding Spot's 'Starting at $X for N guests' plus a saved estimate, and Zola's guest-count-driven recalculation, are the right price model. Ghazal's onboarding already captures date, guests, budget and area, so the hero search should be a prefilled summary of the couple's brief, not an empty form, and every card price should read 'From KD X for N guests' (date-specific when a date is set).
- Three-up comparison at 390px works only if the table is full-bleed fluid thirds (130px each, 106px usable), with the label above each row, a sticky header, and 'differences only' by default. A pinned-label-column table hides the third venue and collides with iOS edge-swipe back (which flips in RTL). Baymard's four proven comparison details (hide identical rows, group by category, sticky headers, horizontal row styling) all fit this layout.
- Honesty is the luxury differentiator. The UK CMA forced Booking.com, Expedia, Hotels.com, Agoda and Trivago to fix pressure-selling, misleading discounts and 'rooms left' claims, and Which? found Booking.com still non-compliant. Ghazal should show all-in prices, only verifiable scarcity (calmly worded), reviews only from completed bookings, and 'was' prices only against a real prior price.
- The best luxury hotel apps are quiet by doing less, and the ones that did more failed on reliability: Four Seasons built its app around check-in/out/room service, human chat in 100+ languages and no chatbots; Jumeirah's app sits at 3.1 stars ('booking function freezes when you try to select dates') and Mandarin Oriental's reviews note you cannot cancel in the app. Reliability and complete empty/error/offline states are part of the luxury feel.
- Host-side apps win on triage, not on dashboards. Airbnb's Today tab leads with time-sensitive alerts, and its request card is earnings + guest rating + Accept/Decline + 24-hour countdown. Peerspace's 48-hour expiry, 'decline rather than ignore' and custom-offer counter map directly onto Accept / Reject / Reschedule. Booking.com Pulse reviews show the failure modes to avoid: bugs, missing desktop functions, repeated 2FA, no payout predictability.
- Resy Notify (auto-notify when a slot opens) is the single best-fit borrowed mechanic for sold-out peak wedding dates: 'Notify me if this date opens', which pairs with 24-48h request expiry freeing held dates.
- The brand colours need a contrast fix before any component work: ink #5A4B4F on matte gold #D8B26E is 4.12:1 (fails AA 4.5 for normal text); #8F7479-style muted ink on off-white is 4.07:1; white on gold is 2.0:1. Gold buttons need a deeper ink label (e.g. #3A2F33 gives 6.43:1) and muted text needs a darker step. All ratios were computed in this session.
- Two Kuwait-specific content risks competitors do not solve: (a) gender-segregated halls make 'women-only / men-only / mixed / separate halls' a gating filter that belongs first in the filter sheet and as a card facility; (b) reviews with photos/videos (PRD 6.16) will otherwise leak images of unveiled women from women's halls, so review media needs a venue-only or face-blur policy.
- Quiet-luxury techniques are consistent across Aman and Four Seasons: hierarchy by size and tracking rather than weight, unframed image-led cards, photography carries all colour, motion 120-240ms with only opacity/crop reveals, 'hint of next band' under hero. Tracking/uppercase must be Latin-only: letter-spacing breaks Arabic joins, so Arabic eyebrows must use size/colour instead.
- The Kuwait competitor field is immature: Mokanik (new venue marketplace, no ratings yet, 'group booking flow' in v2.0) and Farah (event-services marketplace, under 1,000 downloads, 1 rating). Zafaf (Dugun-owned, 11 countries) and Arabia Weddings (Amman, directory) are the regional incumbents. The bar to clear is reliability, price clarity and taste, not feature count.

## Recommendations

### Deposit and booking-mode flow (PRD gap #8)  _(confidence: medium)_

Adopt a two-mode booking model. Request mode: no charge on submit; venue has a 48h hard expiry (24h target, nudges at 12h/4h/1h); on approval the date is held for the couple for 24h and they pay the deposit (KNET/card/Apple Pay) to confirm. Instant-book mode: deposit charged at the end of the stepper, allowed only when the date is at least N days away. Add an 'Approved - awaiting deposit' sub-state. Record as an ADR.

*Why:* KNET via MyFatoorah is AuthorizeAndCapture only, so holds are not portable across payment methods; Airbnb India's charge-then-refund model carries up to 15-day refund waits. Airbnb (non-India) and Peerspace both use 'no charge unless accepted'. Pay-after-approval avoids refunds entirely and keeps one flow for every payment method.

### Price display model  _(confidence: high)_

Show 'From KD X for N guests' on every card (N from the couple's brief), date-specific price once a date is chosen, all-in (no later fees), 3 decimals only in booking summary/invoice and none in discovery. Venue page has a guest stepper that live-updates the estimate. If Ghazal charges no guest fee, say 'No booking fee' as a trust line.

*Why:* Wedding Spot ('Starting at $X for N guests', saved estimate), Airbnb's all-in total-price default across search/map/filter/listing/checkout, and CMA's 'final price in the headline price' remedy. Kuwait pricing is hall rental plus per-guest buffet, so a bare 'from' price misleads.

### Hero search  _(confidence: medium)_

Make the hero a 'brief card' prefilled from onboarding (date, area, guests, budget): three 64px rows (Date full width; Area and Guests side by side; Budget range), solid off-white surface, hairline border, 12px radius, one gold 52px CTA. Single date (not a range). Overlap the hero image by about 88px and leave a hint of the next shelf visible at 844px.

*Why:* Airbnb's pill (64px, three segments) and Four Seasons' 52px booking fields show compact search works; a wedding is one date and the app already knows the brief, so the form should be a summary the user can edit.

### Filter sheet  _(confidence: high)_

Bottom sheet at ~90% detent with sticky footer 'Show N venues' (live count) and 'Clear all'. Order: Hall arrangement (women-only / men-only / mixed / separate halls) first, then Area, Venue type, Budget (dual-thumb with price histogram, mirrored in RTL), Capacity, Facilities toggles, Booking (instant, available on my date default on), Rating, Luxury level, Hotel brand. Show match counts per option and an applied-filter chip row; never reset scroll position on apply. Add 4-5 thematic quick filters above results.

*Why:* Live result-count buttons are standard best practice; Baymard's luxury benchmark flagged missing thematic filters, missing match counts and missing applied-filter overview; a Booking.com guerilla test found filters that reload and jump to top frustrating. Gender arrangement is gating in the Gulf.

### Venue card anatomy  _(confidence: medium)_

Unframed card: 4:5 image (12px radius, no shadow), heart top-end, compare control top-start, max one badge, rating+count, 'Name', 'Area - Hall arrangement', 'From KD X for N guests' with date-specific availability line. No 'Book' button on list cards; the card is the target. Optional trailing 'Book' text button only when a date is set and the hall is available.

*Why:* Airbnb card (1:1 photo, floating badge, heart, four-line meta, photography over chrome) and Four Seasons unframed cards; Booking.com's badge density is what to avoid. PRD lists a Book button on the card; this honours it contextually without competing with the image.

### Availability calendar with price per day  _(confidence: medium)_

Single-date month calendar, Sunday-start, mirrored in RTL, fluid 7 columns (about 48.9px at 24px gutters), 56px rows. Segmented control Availability | Prices. States encoded by more than colour: available, selected (gold fill, deep-ink text), held by another request (corner mark; tap offers 'Notify me if this date opens'), booked/blocked (struck-through number). Price view shows prices in thousands of KD with a unit legend; mark the 3 best-value dates with a gold-ink dot, no green/red. Bottom summary card gives exact price, sessions, deposit for the focused date. Month paging by swipe plus a 12-month jump sheet.

*Why:* Airbnb's struck-through unavailable dates, Google Flights' per-day price graph and cheapest-date highlighting (mobile swipe through dates), Resy Notify for sold-out slots. PRD web pricing engine has weekday/weekend/holiday/season prices so the calendar must carry price tiers.

### 3-up comparison at 390px  _(confidence: high)_

Pick Layout A: full-bleed three equal columns (130px at 390, 120 at 360, 143 at 430; 12px inner padding), label above each row, hairline dividers, sticky header (expanded 106x132 thumbnails with remove control; collapses to 56px with 40px thumbs), first group 'Your date' (availability + price on that date), 'Differences only' default on with 'N matching rows hidden', best-in-row gold-ink dot, three outline 'Book' buttons in a bottom bar aligned to the columns. Replace-one sheet when adding a 4th venue; compare tray appears only after the first add, above the tab bar, collapses to a pill.

*Why:* Baymard (hide identical attributes, group by category, persistent column headings, horizontal row styling), Contentsquare mobile guidance (sticky headers, short phrases, differences-only toggle), Hotels.com swap-when-full pattern. Pinned-label-column tables hide the third column and clash with iOS edge-swipe.

### Booking stepper and status timeline  _(confidence: medium)_

Compress the 11 PRD steps into 4 pre-send phases (Date & session; Package & extras; Guests & details with inline WhatsApp OTP; Review & send) plus Deposit as phase 5 in instant mode or post-approval in request mode. Progress is a 2px hairline 'thread' that fills in gold with 'Step 2 of 5'. Status is a vertical timeline: past nodes with timestamps, current node, 1-2 faint 'what happens next' nodes, and for Pending 'Expected reply by Sun 3 Nov, 18:00' (a timestamp, not a ticking countdown). Rejected states offer 3 similar venues free on the date.

*Why:* Baymard: keep checkout linear; progress trackers set expectations and reduce abandonment; carrier-style vertical timelines are the de-facto order-tracking pattern; Airbnb request flow (24h, withdraw before accept, dates held while pending).

### Price breakdown and deposit card  _(confidence: medium)_

Breakdown rows: package x guests, date rate (explained), extras, then bold Total. Below it a Deposit card answering three questions in 12 words or fewer each: how much, when charged, what if plans change; plus a mini payment schedule (today - on approval - balance due date - wedding day). Balance due date tied to the venue cancellation policy. Show 'Free cancellation until <date>' when true.

*Why:* Airbnb shows full breakdown before confirming and its Reserve Now, Pay Later ties payment due date to the free-cancellation window; deposit/balance 'due today / due later' is the established e-commerce pattern; Four Seasons requires total cost, taxes, fees, cancellation exposed as text.

### Planner packages (Silver / Gold / Royal)  _(confidence: medium)_

Sticky segmented control [Silver | Gold | Royal] above one full-width package card (price or 'from', who it suits by guest count, at most 6 included items), with a 'Compare packages' link opening the same fluid-thirds table. Default to Gold only if a stated criterion supports it ('Suits 300-500 guests'). Differentiate tiers by typographic weight and a 1/2/3 thread mark, not metallic colours. CTA is 'Request consultation', never 'Buy'. Offer the planner as one quiet card after booking confirmation and under Plan.

*Why:* Fiverr-style three-tier presentation with a highlighted middle tier, and Airbnb's post-booking add-on suggestions. Metal-gradient tier badges are the classic template trope.

### Budget manager, checklist, countdown  _(confidence: high)_

Budget: one hero figure (Remaining, 48px+ sans), one three-segment bar (Paid ink / Committed gold / Remaining rose-tint track, 2px gaps), a legend with values, then category rows with 6px meters; bookings and deposits flow in automatically; guest-count changes re-estimate venue/buffet; over-budget uses functional danger plus icon plus text; no donut. Checklist: grouped by the PRD countdown bands (365/180/30/7), 56px rows, 44px checkbox targets, venue task auto-completes on booking, completion is a 160ms check draw with undo. Countdown: large day count with six equal-spaced milestone ticks on the thread, no seconds.

*Why:* Zola (set total, divide by category, paid vs owed, guest-count recalculation, link payments to vendors), The Knot (timeline-grouped checklist; budget advisor), Zafaf (countdown on every login), dataviz rules (no donut for 8+ categories, hero figure, thin marks).

### Hotel request-triage card  _(confidence: high)_

Expanded card for pending only: time-left line with 2px depleting hairline (gold under 6h, danger under 1h with icon), headline date (Thu 14 Nov 2026) with hall and session, three facts (guests, package, total with expected payout), client line (monogram, name, verified/first-booking marker, 44px call and chat buttons), conditional conflict row ('Another request for this date'), then one primary Accept (gold, 48px) with 5-second undo, below it two secondary text buttons: Propose another date (sheet with open dates, sends a counter-offer) and Decline (reason chips, offers alternatives by default). No swipe gestures. Sort by expiry. Compact 96px rows for everything else.

*Why:* Airbnb request card (earnings, guest rating, Accept/Decline, 24h timer), Peerspace (48h expiry, decline-rather-than-ignore, custom offer, message templates), Pulse reviews (payout predictability gap).

### Hotel calendar on a phone  _(confidence: medium)_

Segmented Month | Week | Day. Month grid on top with the selected day's agenda strip underneath. Week is a vertical list of 7 day rows (not 7 columns). Day is a prep-event-teardown timeline per hall, not a 24-hour grid. Hall filter chips. Cell marks: solid ink bar confirmed, gold bar pending, struck-through blocked. Range select by long-press-drag (Airbnb) with an accessible 'Select dates' tap mode; bottom action bar 'Block / Open' with count.

*Why:* Airbnb host calendar (tap-hold-swipe multi-select, struck-through blocked nights, new daily view), Hostaway mobile calendar documentation; 7 columns cannot hold event titles at 390px.

### Hotel dashboard hierarchy and analytics  _(confidence: high)_

Today tab order: one-sentence status ('3 requests need your reply - first expires in 5h 20m'), Needs-reply cards, This-week strip, then a maximum of three KPIs (one 48px+ hero figure plus two tiles, delta vs previous period with arrow and sign), Messages preview. No charts on Today. Analytics (under More): sticky 7D/30D/90D/12M row; 2x2 stat tiles with sparklines; funnel as horizontal bars (views, clicks, requests, confirmed); single-series revenue line with end-point label; top packages as horizontal bar list; table-view twin for each; scrub-and-hold readout above the finger.

*Why:* Airbnb Today (alerts first), Square (metrics with tap-to-compare), Shopify metrics card (label, number, trend; stacks at 400px or less); dataviz rules (stat tile over one-bar chart, no dual-axis, thin marks, no donut).

### Flash-offer creation  _(confidence: medium)_

Start from the calendar (select open dates then Offer) as well as More > Offers. One scroll screen: type (Flash sale | Discount | Coupon), dates (open dates only), discount chips 10/15/20/25 plus custom, duration (24/48/72h or until date), applies-to, live preview using the real client card with struck-through price, and a sticky summary bar with Publish. Guardrails: one offer per date (highest wins), 'was' price must equal the real prior price, show guest price and venue payout.

*Why:* Booking.com promotion flow (template, discount, booking window, stay dates, preview, set up), Airbnb last-minute discounts (0-28 days; callout at 10% or more; one discount per night), CMA enforcement on misleading discount claims.

### Luxury restraint and anti-cliche rules  _(confidence: medium)_

One display face at light/regular for at most three moments per screen; hierarchy by size and tracking, not weight; Latin-only uppercase tracking (Arabic uses size/colour); unframed image cards; images must reveal the place (no blur backdrops, no autoplay video); photography carries colour; motion 120-240ms with opacity/crop reveals (<=500ms), reduced-motion respected; max one badge per card; no urgency counters, no 3D icons, no metallic tier badges, no confetti, no gold calligraphy/arabesque wallpaper, no auto-advancing carousels.

*Why:* Aman and Four Seasons design analyses (third-party), Nucleus on digital luxury, CMA action against pressure selling, Airbnb 2025's 3D animated icon language being a mass-market house style.

### RTL decisions for charts and numerals  _(confidence: low)_

Mirror calendars, week strips, progress, sliders, timelines and time-series charts in Arabic so earlier-to-later follows reading direction; keep digits Western 0-9 and LTR inside RTL text; mirror directional icons only; never mirror media controls or circular/clockwise symbols. Provide the numeral switch in the formatter. Verify with 5 Kuwaiti users.

*Why:* Material guidance says charts and graphs are not mirrored while time depicts right-to-left in RTL, and sources disagree; consistency with the mirrored calendar and week strip is the deciding factor. Western digits are increasingly the Gulf default in banking/productivity apps.

## Risks & gaps

- Evidence limits: Baymard's Booking.com/Airbnb page analyses and Apple HIG / Material 3 pages were paywalled or JS-rendered and returned no body text, so Booking.com's mobile filter/search internals are not first-hand-verified; Airbnb card anatomy and Aman/Four Seasons token numbers come from third-party design-system extractions (getdesign.md, shadcn.io, webdesignhot), so treat exact px values as indicative and re-check on the live products. Rosewood and Aman have no findable app UI documentation.
- KNET finding rests on one integration doc (Broadleaf's MyFatoorah KNET page: 'always result in an AuthorizeAndCapture'). Confirm with MyFatoorah/KNET directly before the ADR is final; the fallback (approve-then-pay) is robust either way.
- Brand contrast: ink #5A4B4F on gold #D8B26E = 4.12:1 (fails 4.5 for normal text), gold on off-white = 1.91, white on gold = 2.00, #8F7479 on off-white = 4.07. The design system needs a deep-ink label token for gold fills and a darker muted-text step.
- Three-up compare relies on terse values; Arabic strings run longer and Eastern digits are visually heavier, so row copy needs a strict length budget (about 14 characters) and the layout must be QA'd at 360px in Arabic.
- Calendar price compaction ('2.45' in thousands of KD) is unfamiliar and untested; if comprehension is poor in testing, fall back to showing only tier marks plus the exact price in the bottom summary.
- Chart mirroring in RTL has conflicting guidance (Material: do not mirror charts; Arabic reading direction suggests mirroring time axes). Decide once, document in an ADR, and test.
- PRD 'Book' button on venue cards conflicts with image-led restraint; PRD 'AI recommendations' (project.md) conflicts with the PDF (Phase 3); both need explicit owner confirmation.
- Instant-book and session logic are underspecified (PRD gaps #8-#10): per-date vs per-session booking, multiple halls, men/women sections, government halls. Calendar, card and stepper designs must carry optional session and hall dimensions until decided.
- UGC privacy: review photos/videos from women's halls can expose unveiled women; moderation/face-blur or venue-only media policy is needed before reviews ship.
- Competitor research did not surface Kuwait-specific booking norms (deposit size, lead time, Thursday/Friday demand, Hijri/Eid avoidance); those assumptions need validation with 3-5 venue managers before pricing-tier and calendar-mark designs are locked.
- Kuwait cost anchors come from search-result snippets of Kuwait Times (5-star hall about KD 1,350 without services; KD 33 per person at some 5-star venues; 4-star KD 13 to 17 per person); the article pages themselves were not retrievable, so use them for plausibility only, not as copy or data.

## Open questions for the owner

- Booking mode: should each venue (or hall) choose Instant vs Request, and is an 'Approved - awaiting deposit' state with a 24h date hold acceptable? What is the minimum lead time for instant-book?
- Deposit: fixed percentage or venue-set amount? Is it refundable on cancellation per venue policy, and does Ghazal hold funds (escrow) until the event or release to the venue on approval?
- Does Ghazal add any guest-side fee? If not, can we state 'No booking fee' on checkout? What commission does the venue see, and should the venue app show net payout per booking?
- Is a venue booked per date, per session (afternoon/evening), or per hall? Are women's and men's halls separate inventory with separate prices?
- Planner packages (Silver/Gold/Royal): fixed price, percentage of budget, or 'from' pricing? Who delivers them: Ghazal staff or partner planners?
- Reviews with photos/videos: may the product restrict media to venue/decor shots and auto-blur faces?
- Calendar content: should the client calendar mark Ramadan, Eid and public holidays (Hijri source needed) to explain price tiers?
- Venue response SLA: 24h target with 48h hard expiry, and should response time influence ranking or earn a visible 'Replies within X' badge?
- Revenue definition on the venue dashboard: booked value, received, or net of commission? Which staff roles (reception/accountant/manager) see revenue on mobile?
- Numerals: confirm Western 0-9 default in Arabic UI with a user-level switch, and decide chart/time-axis mirroring in Arabic.
- Are venue tours/viewings (a real step before booking a hall) in scope? The PRD has chat but no tour request; competitors such as Bridebook centre on 'request a brochure'.
- Should the venue app support an event-day mode (live event card, offline cache of today's bookings, one-tap call to coordinator) in MVP? Eventbrite's organizer app shows the value, but it is not in PRD 7.x.

---

## Full findings

# Competitive and best-in-class UX patterns for Ghazal

Scope: Client Mobile App and Venue/Hotel Mobile App, 390 x 844 frame, Arabic RTL and English LTR, KWD, three core colours (Ink #5A4B4F, Matte Gold #D8B26E, Soft Rose #F8E7EC) on Warm Off White #FFF9F5.

Conventions in this document:
- "(src)" marks a fact taken from a source I consulted. Sources are listed in section 9.
- "Proposal" marks my recommendation, not a competitor fact. All pixel values in proposals are on the 4-pt grid unless stated.
- PRD references use the digest numbering (6.x client, 7.x venue).
- Confidence levels in the structured recommendations reflect evidence quality, not design taste.

---

## 0. The decisions in one screen

1. **Deposit flow (the KNET finding).** KNET through MyFatoorah is always AuthorizeAndCapture (src: Broadleaf MyFatoorah KNET docs), so "hold the card and release on decline" (Peerspace, Airbnb) is not portable. Request mode becomes: send request with no charge, venue approves within 48h, date is held for the couple 24h, couple pays the deposit to confirm. Instant-book venues take the deposit at the end of the stepper. Add an "Approved - awaiting deposit" sub-state.
2. **Price model.** "From KD X for N guests" on every card, driven by the couple's brief, all-in, date-specific once a date is set (Wedding Spot; Airbnb all-in default; CMA remedies).
3. **Hero search = a prefilled brief card**, not an empty form. Onboarding already collected date, guests, budget, area.
4. **Filter sheet** with live "Show N venues" button, per-option match counts, gender arrangement first.
5. **Venue card** is unframed and image-led: 4:5 photo, three text lines, one badge maximum, no Book button on list cards.
6. **Availability calendar** is single-date, with an Availability | Prices switch, non-colour state encoding and "Notify me if this date opens" (Resy Notify).
7. **3-up comparison**: Layout A, full-bleed fluid thirds, label-above rows, sticky header, "differences only" default, three Book buttons aligned to the columns.
8. **Booking stepper**: 4 pre-send phases plus a deposit phase, with a hairline "thread" progress line; status timeline in the carrier-tracking style with timestamps, never ticking countdowns on the guest side.
9. **Planner packages**: segmented Silver | Gold | Royal over one card; tiers differ by type and thread count, not metallic colour; "Request consultation".
10. **Budget**: hero Remaining plus one three-segment bar plus category meters; no donut.
11. **Hotel triage card**: time-left hairline, date headline, three facts, client line with call/chat, one primary Accept with 5-second undo, Propose another date, Decline with reasons.
12. **Hotel calendar**: Month grid with day agenda below; Week as a vertical list; Day as a prep-event-teardown timeline.
13. **Hotel dashboard**: status sentence first, needs-reply cards second, three KPIs maximum, no charts on Today.
14. **Brand token fix**: ink on gold is 4.12:1 (fails). Gold buttons need a deep-ink label token.

---

## 1. Evidence base and its limits

What I actually read (not recalled): Airbnb Help (request to book, calendar), Airbnb host resources (redesigned reservations), Airbnb newsroom and trade coverage (total price default, 2025 Summer Release, Reserve Now Pay Later, Guest favorite criteria, photo tour), Rental Scale-Up on the Today tab, Booking.com Pulse App Store listing and reviews, UK CMA coverage (CMS, CNN, TTG), Peerspace help and host guidance, Wedding Spot, Bridebook, The Knot and Zola feature coverage, Zafaf and Arabia Weddings background (Wamda and company pages), Mokanik and Farah App Store listings, Four Seasons (Skift, trade press), Four Seasons/Aman/Hyatt design-system analyses, Nucleus on digital luxury, Baymard (luxury benchmark, comparison-tool research), Contentsquare comparison UX, Square/Shopify metrics docs, Eventbrite, Resy OS and OpenTable listings, Material/JetRuby RTL guidance, and the bundled dataviz skill rules.

Known limits (be careful quoting pixel values):
- Baymard's per-site Booking.com and Airbnb analyses, Apple HIG and Material 3 token pages returned no body text. Booking.com's mobile filter/search mechanics are therefore known from general practice plus a guerilla-test summary, not from first-hand teardown.
- Airbnb card measurements (14px clip, 1:1, 64px search pill, 8px buttons), Aman tokens (zero radius, #313131/#f3eee7, 0.3-2px tracking) and Four Seasons tokens (Saol Display 300, 39/52px controls, 24px mobile gutter, 120-240ms/700ms motion) come from third-party design-system extractions. Indicative, not authoritative.
- No documentation found for Rosewood or Aman app UIs; Jumeirah and Mandarin Oriental are known only from store listings (ratings of 3.1 on 8 ratings and 4.1 on 10 reviews: tiny samples, directional only).
- Zola's and The Knot's in-app UI came through feature summaries, not screens.
- Kuwait price anchors came from search snippets of Kuwait Times (article pages not retrievable).

---

## 2. Market read: Kuwait and the region

| Player | What it is (src) | Lesson for Ghazal |
|---|---|---|
| Mokanik | Kuwait venue platform for weddings, engagements, conferences; v2.0 "new venue group booking flow"; no ratings yet on the App Store | Group booking exists in the market; no trust layer (reviews) yet. Our reviews-after-completed-booking is an opening. |
| Farah | Kuwait events marketplace: venues plus photography, buffets, hospitality, flowers, Arabic coffee, incense, music, rentals; smart planner, e-invites, "real-time availability"; under 1,000 downloads, 1 rating | The service sprawl is what PRD Phase 2 would add. Launch lean; do not copy the 10+ category menu into MVP navigation. |
| Zafaf (Dugun) | Arabic-language, 11 countries; budget, guest website, vendors; countdown and reminders on every login (src: Wamda) | Countdown as a persistent hook works; do it as a card, not a login interstitial. |
| Arabia Weddings | Amman-based directory/planning marketplace, 12+ years | Directory model: lists and "top halls" content, not transactional. |
| Four Seasons / Ritz-Carlton / Jumeirah / Mandarin Oriental apps | Luxury hospitality apps | Quiet imagery, human service, but reliability complaints at Jumeirah and Mandarin Oriental. |

Kuwait cost anchors (src: Kuwait Times snippets via search): a 5-star hotel hall about KD 1,350 without services; some 5-star venues about KD 33 per person; 4-star prices rose from KD 13 to KD 17 per person; many Gulf couples prefer separate halls for women and men. Implication: price = hall plus per-guest buffet, so a bare "from" price is misleading and the gender arrangement is a gating attribute.

---

## 3. Per-pattern verdicts

### 3.1 Client app: discovery and trust

| Pattern (source) | Verdict | Why for Ghazal |
|---|---|---|
| Airbnb three-segment search pill, Where/When/Who (src) | ADAPT | Wedding = one date, plus budget; the app already knows the brief, so show a prefilled card, not a pill. |
| Airbnb total price shown by default across search, map, filter, listing, checkout; breakdown before confirm (src) | ADOPT | Directly answers "price clarity" and mirrors CMA's remedy. |
| Wedding Spot "Starting at $X for N guests", saved estimates to compare (src) | ADOPT | The only honest venue price. Guest count is the multiplier in Kuwait (per-person buffet). |
| Zola budget recalculating catering and venue from guest count (src) | ADOPT | Same mechanic in the venue estimator and the budget manager. |
| Booking.com pressure selling ("only 1 room left", pressure to book), misleading discounts (src: CMA) | AVOID | Regulatory and trust risk; contradicts "certainty before beauty". |
| Booking.com Genius badges and loyalty-discount labelling (src) | AVOID on cards | Badge noise. Loyalty (PRD 6.16) lives in profile and checkout. |
| Airbnb Guest favorite (4.9+, at least 5 reviews, about 1% or lower reliability issues, re-evaluated daily) (src) | ADAPT | Criteria-based "Couples' choice" (proposal: 4.8+, 10+ verified completed weddings, low cancellation); never editorial or paid. |
| Booking.com Genius entry bar (3 reviews, 7.5+) (src) | AVOID | Too low a bar for a premium badge. |
| The Knot / WeddingWire annual awards and "Quick Responder" badge (src) | ADAPT | Use a live "Replies within 2 h" fact instead of annual trophies. |
| Booking.com reviews only from guests with a booking (src) | ADOPT | "Verified wedding" tag; owner replies (PRD 6.16). |
| Bridebook "Request a brochure" lead-gen (src) | AVOID | We transact; lead capture is not our job. Venue tours are an open question. |
| Airbnb 1:1 card, floating badge top-start, heart top-end, four-line meta (src, third-party analysis) | ADAPT | Use 4:5, three lines, unframed, one badge. |
| Four Seasons unframed property cards (src, third-party analysis) | ADOPT | Fits the "image is the hero" principle. |
| Filter bottom sheet with live "Show N results" button and Clear all (src: design-pattern guides) | ADOPT | Standard and expected. |
| Baymard luxury benchmark: add thematic filters, match counts per option, applied-filter overview (src) | ADOPT | Luxury sites underserve filtering; we need it for 20 PRD filters. |
| Booking.com filters that reload the page and jump to top (src: guerilla test) | AVOID | Apply from the sheet; never reset scroll. |
| Airbnb photo tour grouped by room (80% mapped rule, 19 room types) (src) | ADAPT | Group by zone: Hall, Stage/Kosha, Bridal suite, Buffet, Outdoors, Entrance and valet, Layouts. Venue tags zone at upload. |
| Four Seasons video only on user action, static fallback (src, third-party) | ADOPT | No autoplay video, performance (PRD NFR: 2 s on 4G) and calm. |
| Ritz-Carlton "Journey pages" (src: Deloitte Digital) | ADAPT | Short editorial collection pages for Beach, Luxury Hotels, etc., not long-form content. |
| Airbnb 2025 redesign with animated 3D icons (src: newsroom, "dimensional, beautifully animated interface") | AVOID | A mass-market house style; wrong register for quiet luxury. |
| Hotels.com compare up to 5, swap one when full (src) | ADAPT | Cap 3, same swap behaviour. |

### 3.2 Client app: booking, payment, status

| Pattern (source) | Verdict | Why for Ghazal |
|---|---|---|
| Airbnb request to book: ~24h, no charge until accept, can withdraw, dates reserved while pending (src) | ADAPT | Pair with KNET constraint: pay after approval. |
| Airbnb India: charged at request, refund on decline taking up to 15 days (src) | AVOID | Refund waits destroy trust. |
| Peerspace authorization hold, charged on accept, hold released on decline (src) | AVOID as default | KNET cannot hold. Possible only as an optional card-only optimisation later. |
| Peerspace Instant Book when the event is at least 24h away; manual approval otherwise (src) | ADAPT | Venue chooses mode; instant-book only if date is at least N days away. Gives the PRD "Instant booking" filter a precise meaning. |
| Airbnb Reserve Now, Pay Later: payment due before end of free-cancellation window; not a loan (src) | ADAPT | Balance due date derived from cancellation policy; no financing (installments are future). |
| Baymard: checkout must be linear (src) | ADOPT | Stepper never branches visually. |
| Progress trackers state step count and position (src: UXPin) | ADOPT | "Step 2 of 5" plus hairline thread. |
| Carrier-style vertical timeline with timestamps (src: UX guides) | ADOPT | Booking-status screen. |
| Google Flights price graph with cheapest highlighted (green) and expensive (red) (src) | ADAPT | Highlight best-value dates with a gold-ink dot only; no traffic lights. |
| Airbnb struck-through unavailable dates (src: Help) | ADOPT | Non-colour encoding. |
| Resy Notify, auto-notify on opened slot (src) | ADOPT | "Notify me if this date opens." Pairs with request expiry. |
| Fiverr Basic/Standard/Premium with the middle highlighted and clear differentiation (src) | ADAPT | Silver/Gold/Royal presentation; highlight only with a stated criterion. |
| Airbnb 2025 post-booking add-on suggestions slotted into the itinerary (src) | ADAPT | Planner and services suggestions after confirmation, adding tasks to the checklist. |
| Four Seasons itinerary builder (src) | ADAPT | Plan tab top card = booking plus next task. |

### 3.3 Client app: planning tools

| Pattern (source) | Verdict | Why |
|---|---|---|
| Zola: total, categories, paid vs owed, link payments to vendors (src) | ADOPT | Bookings and deposits auto-populate Paid and Committed. |
| The Knot Budget Advisor from real-couple averages (src) | ADAPT later | Needs data. MVP is rules-based (PRD digest gap #7). |
| The Knot / Zola checklist grouped by time bands, customisable (src) | ADOPT | Bands = PRD countdown milestones (365/180/30/7). |
| Joy: minimal clutter, countdown, checklist, budget (src) | ADOPT (principle) | Quietness. Joy's guest list/RSVP/website: AVOID, not in PRD. |
| Zafaf countdown on every login (src: Wamda) | ADAPT | Persistent card, not interstitial. |

### 3.4 Hotel app

| Pattern (source) | Verdict | Why |
|---|---|---|
| Airbnb Today tab order: time-sensitive alerts, current/upcoming, next steps, tips (src) | ADAPT | Keep alerts and upcoming; drop tips and "next steps" marketing. |
| Airbnb request card: earnings, guest rating, Accept/Decline, 24h timer (src) | ADOPT | The model for triage. |
| Peerspace 48h expiry, "decline rather than ignore", custom offer, message templates (src) | ADAPT | Reschedule = counter-offer; reply templates in chat. |
| Booking.com Pulse: push for new bookings, cancellations, modifications; calendar; availability/rate edits; pre-translated templates (src) | ADAPT | Keep scope tight. |
| Pulse failures: bugs, notifications vanishing, no multi-property, limited vs extranet, repeated 2FA, no payout prediction (src: App Store, review summaries) | AVOID (all of it) | Reliability is the feature; show expected payout per booking. |
| Airbnb host calendar: tap-hold-swipe multi-select, struck-through blocked nights, daily view (src) | ADAPT | Add a tap-select mode for accessibility. |
| Airbnb price tips (src) | AVOID (MVP) | Dynamic-pricing suggestions are explicitly deferred in the PRD. |
| Square: metrics with tap "vs" to compare periods; Dashboard widget (src) | ADAPT | Delta vs previous period; widget post-MVP. |
| Shopify metrics card: label, primary number, trend badge; stacks at 400px or less (src) | ADOPT | KPI tile anatomy. |
| Shopify customisable home metrics, 4 to 18, long-press (src) | AVOID (MVP) | Fixed three KPIs. |
| Booking.com promotion creation: template, discount, booking window, stay dates, preview, set up (src) | ADOPT (shape) | Flash-offer flow. |
| Airbnb discounts: last-minute 0-28 days; callout at 10% or more; only the highest-priority discount applies per night (src) | ADAPT | Guardrails in the flash-offer form. |
| Eventbrite Organizer: real-time sales and check-in, offline sync, multiple staff (src) | ADAPT | Offline cache of today's events; event-day mode is an open question. |
| OpenTable/Resy floor plans, pacing, table turns (src) | AVOID | Wrong domain. Resy OS at 2.8 stars with lock-timeout errors and crashes (src) is a reliability warning. |

---

## 4. Client app: specific UI patterns

### 4.1 Discover and hero search (PRD 6.3, 6.2)

Why: onboarding collects wedding date, budget, guests, area (PRD 6.2). Asking again on Home is friction; showing the brief as an editable summary is the quiet-luxury version of search.

Proposal:
- Hero: image zone about 300px with the brief card overlapping by about 88px. Solid Warm Off White surface, 1px hairline, 12px radius, no blur, no shadow.
- Card rows (64px each, label 12px muted above value 16px): Date (full width, single date) / Area and Guests (two columns, hairline divider) / Budget (range text, tap opens slider sheet). CTA 52px gold fill with deep-ink label; label "Show 38 halls" (live count) not "Search".
- At 844px the first shelf must show a hint below the card (Four Seasons "preserve a hint of the next content band").
- Shelf order (PRD lists 8; collapse to 5): Available on your date; Collections (6 image tiles: Luxury Hotels, Wedding Halls, Government Halls, Beach, Outdoor, VIP; 4:5 tiles, text overlay with subtle scrim, no coloured chips); Offers and last-minute (merged, honest); Near your area (merges Nearby and Recommended); Newly added. "Trending" becomes a sort option because social-pressure framing is a CMA-sensitive pattern.
- Active booking: a single status card pinned at the top (Airbnb Trips-tab logic): "Al Qasr Ballroom, Thu 14 Nov. Awaiting reply" with the timeline one tap away.
- Arabic: field labels 13px, values 17px, line-height at least 1.6; icons mirrored only if directional.

### 4.2 Filter sheet and sort (PRD 6.4)

- Sheet detent about 90%; grabber; drag to dismiss; sticky footer: "Clear all" (text) and "Show 14 venues" (primary). The count updates within 200ms of each change.
- Group order: 1 Hall arrangement (Women-only, Men-only, Mixed, Separate halls); 2 Area (multi-select with counts); 3 Venue type; 4 Budget (dual-thumb with price histogram; thumb direction mirrors in RTL; numerals stay LTR); 5 Capacity; 6 Facilities (parking, valet, bridal room, buffet included, decoration included, photography allowed); 7 Booking (instant booking; available on my date, default on); 8 Rating; 9 Luxury level; 10 Hotel brand (collapsed).
- Collapsed groups show their selected values as a summary line; applied filters appear as a single scrolling chip row under the app bar; scroll position is preserved on apply.
- Sort is a separate small sheet: Recommended, Price low to high, Rating, Newest, Nearest. (Do not mix sort into filters.)
- Quick filters above results: four to five thematic chips (e.g. Women's hall, Beachfront, Under KD 3,000, Available this Thursday). Hairline chips, not coloured.

### 4.3 Venue card anatomy (PRD 6.5)

```
[ 4:5 image, 12px radius              ]   compare control top-start (44px target)
[ carousel dots, max 5            ♡   ]   heart top-end (44px target)
[ one badge, bottom-start             ]   only: Couples' choice | Instant booking | Offer -15%
Al Qasr Ballroom             4.8 (126)    name 16/22 medium; rating+count 14, tabular
Salmiya  -  Separate halls                14 muted
From KD 2,450 for 300 guests              16 medium; price tabular
Available Thu 14 Nov                      12-14 with icon+label (not colour alone)
```

- One badge maximum. If two apply, priority: Offer, then Instant booking, then Couples' choice.
- Price line uses guest count from the brief; if no date set, it says "From"; with a date it states the date price.
- Availability states: Available / On hold / Booked on your date, always icon plus text.
- PRD "Book" button: honour it contextually. Show a trailing "Book" text button (44px target) only when a date is set and the hall is available; otherwise the card is the only target. Optional video shows as a small play affordance on the image, never autoplay.
- Unframed: no card border or shadow. Cards are separated by space (24px vertical rhythm, 32px between shelves).

### 4.4 Venue details and gallery (PRD 6.6)

Order (single scroll, sticky bottom bar with price and CTA; anchor chips appear after the gallery scrolls away):
1. Gallery hero 390 x 480 with counter "3 / 24" and zone label.
2. Title block: name, area, rating, one badge.
3. Your date card (prefilled): availability, price on that date, sessions, deposit amount.
4. Packages.
5. Estimator with a guest stepper (live "From" total).
6. Hall arrangement and capacity (diagram if available).
7. Facilities (grouped, "Show all 32").
8. Policies in plain language: cancellation, children, dress code, working hours.
9. Reviews (verified wedding tag, owner replies).
10. Location (Google Maps), FAQ, similar venues.

Gallery specifics:
- Zone chips (Hall, Stage/Kosha, Bridal suite, Buffet, Outdoors, Entrance and valet, Layouts, Video) act as the "photo tour".
- Shared-element expansion from card or hero to a full-screen viewer, container-transform style at about 480-500ms; swipe-down dismiss shrinks the image back; pinch zoom; viewer background uses the deepest ink token, not pure black.
- No people: venue photographs are empty, staged halls; seating-layout plans are first-class photos for 300/500/800 guest set-ups.
- 360 tour is a future placeholder (PRD), so reserve a disabled "360" slot only if it will not read as broken.

### 4.5 Availability calendar with price per day (PRD 6.6, 6.8)

Anatomy (390 frame, 24px gutters, 342px content):
- Header: month name (Gregorian), prev/next chevrons (mirror in RTL), 12-month jump sheet (a 3 x 4 month grid with availability density).
- Segmented control: Availability | Prices.
- Grid: 7 fluid columns (about 48.9px), 56px rows, Sunday-start; the week mirrors in RTL (Sunday on the right). Fri and Sat are the weekend (brief).
- Day cell states (never colour alone):
  - Available: ink number on canvas.
  - Selected: gold fill, 8px radius, deep-ink number, price below.
  - On hold (another couple's pending request): number at 60% ink plus corner mark; tap opens a sheet with "Notify me if this date opens".
  - Booked/blocked: number struck through, 40% ink. Do not reveal why.
  - Past: 32% ink, no strike.
  - Session split (only if sessions are confirmed in the ADR): two half-dots under the number (mirror in RTL).
- Prices view: compact price under the date in thousands of KD (e.g. 2.45), 12px tabular; legend says "Prices in KD thousands" (Arabic: "الأسعار بآلاف الدنانير"). Mark the three best-value dates in view with a gold-ink dot (not green).
- Focus summary card pinned below the grid: exact price, sessions, deposit, "Continue".
- Month paging: horizontal swipe; wedding dates are chosen 6-18 months out, so the jump sheet matters.
- Honesty rules (CMA): no "only N dates left" counters; any scarcity phrase is computed from real data and worded calmly ("3 Thursdays left in November").
- Holiday price tier exists in the PRD web pricing engine (weekend/weekday/holiday/season), so the calendar must be able to show holiday marks; Hijri/Eid data source is an open question.

### 4.6 Three-up comparison on a 390px screen (PRD 6.7)

Three concrete layouts considered:

**Layout A: Fluid thirds, label above values (PICK).**
Full-bleed table, three equal columns (130px at 390, 120 at 360, 143 at 430), 1px hairline dividers, 12px inner padding (106px usable at 390). Each attribute is a block: a 12px muted label spanning the row, then three values aligned in the thirds. No horizontal scroll, no label column. Sticky header with three thumbnails.

**Layout B: Pinned label column plus swiping venue columns (REJECT).**
NN/g-style priority column pattern: label column about 88px, then two and a half venue columns. Rejected because the third venue is always off-screen (defeats "3-up"), and horizontal edge swipes collide with iOS back-navigation (which also flips in RTL).

**Layout C: Anchor-and-delta pager (REJECT as primary).**
One venue full width, the other two as deltas ("+KD 300", "-50 guests"), swipe to change anchor. Good for "which one is better than my favourite" but asymmetrical and harder to learn. Keep as a small "At a glance" row (lowest price, largest hall, highest rated) at the top of Layout A.

Layout A specification (proposal):
- Header (expanded): remove control (24px icon in a 44px target) on each image corner; image 106 x 132 (4:5); name 14/20 medium, 2 lines max (Arabic 15/24); area 12 muted. Collapses on scroll to 56px: 40 x 40 thumbnail plus one-line name.
- Groups (Baymard: group by category): Your date (availability and price on that date, first because certainty of the date decides); Price (From, Deposit, Buffet per guest); Capacity and layout (Max guests, Hall arrangement, Indoor/Outdoor/Mixed); Facilities (Parking, Valet, Bridal room, Decoration, Buffet, Photography allowed: Yes/No with icons and text equivalents); Rating (score plus count); Distance (from the couple's area); Packages (expandable); Photos (three 106 x 80 strips, tap to open the gallery).
- "Differences only" segmented control at the top, default on, with a summary "7 matching rows hidden" (Baymard users prefer hiding identical attributes over merely highlighting them).
- Best-in-row mark: a small gold-ink dot before the winning value on objective rows (price, capacity, distance, rating). Never on subjective rows. Never green/red.
- Value copy budget: at most 14 characters per cell in English and 12 in Arabic; longer text lives behind an expandable row.
- Row styling: horizontal hairlines between rows (Baymard: horizontal styling helps scanning).
- Footer: three 48px outline "Book" buttons aligned exactly to the columns, so each button belongs visibly to its venue; tapping carries date and guests into the stepper. (Three equal outline buttons are a choice group, so the one-primary-action rule is not broken.)
- Tray (on lists and details): appears only after the first add, sits above the tab bar, shows three 40 x 40 slots plus "Compare (2)"; after 3 seconds of no interaction it collapses to a 44px pill; hides on scroll-down and returns on scroll-up; never appears inside booking or checkout. Adding a fourth opens a "Replace one" sheet (Hotels.com swap behaviour).
- Entry also from Wishlist ("Select 2-3, Compare"), like Bridebook's favourites-to-compare.
- States: fewer than two venues ("Add one more to compare" with empty slots drawn as hairline boxes), venue became unavailable (row shows "Booked", header stays), offline (last data with timestamp).

### 4.7 Booking stepper (PRD 6.8)

PRD has 11 steps. One decision per screen is a binding principle, but 11 dots is hostile. Group:

| Phase | PRD steps | Notes |
|---|---|---|
| 1 Date and session | Choose date, choose time | Prefilled from search; shows the date price |
| 2 Package and extras | Choose package, add extras | Sticky running total |
| 3 Guests and details | Guest count, personal info, special requests | Inline WhatsApp OTP here if not signed in (guest browsing ends at this point) |
| 4 Review and send | Review booking, confirm | Breakdown, deposit card, policy acknowledgement |
| 5 Deposit | Deposit payment | Instant mode: immediately. Request mode: after approval, from a push |

- Progress: text "Step 2 of 5" plus a 2px hairline "thread" under the app bar that fills in gold (RTL fills from the right). The same thread appears later in the checklist, countdown and status timeline, so the "غزل thread" motif is always a progress indicator, never decoration.
- Back is always safe: state persists; leaving shows a quiet "Save draft" snackbar.
- Sticky footer on steps 2-4: "Total KD 4,650.000" with an expandable breakdown, plus the primary CTA.
- Step 5 in request mode is a standalone "Pay deposit to lock Thu 14 Nov" screen with a plain hold timestamp ("Held for you until Fri 15 Nov, 18:00"), not a ticking timer.

### 4.8 Price breakdown and deposit explanation (PRD 6.8, 6.9)

Breakdown (390 frame, rows 24-32px, tabular numerals):
```
Gold package - 300 guests            4,200.000
Thursday peak rate                     + 300.000   (i) explains rate tiers
Extras (2)                             + 150.000
------------------------------------------------
Total                           KD 4,650.000
```
- Never add a fee later. If Ghazal charges the couple no fee, say "No booking fee."
- Deposit card (three answers, 12 words or fewer each):
  - How much: "Deposit KD 930.000 (20% of total)."
  - When: "Nothing is charged until the venue approves."
  - If plans change: "Free cancellation until 1 Oct. After that, the venue policy applies."
- Mini payment schedule (four nodes on the thread): Today (no charge) - On approval (deposit) - 14 days before (balance, date derived from the policy) - Wedding day.
- Payment methods list in PRD order: KNET, Visa, Mastercard, Apple Pay, Google Pay, cash only where the venue allows. Never ask for card data in-app (gateway-hosted, NFR).
- Copy tone: plain and exact; no "Don't miss out".

### 4.9 Booking-status timeline (PRD 6.10)

- Vertical timeline, chronological, nodes: Request sent - Venue reviewing - Approved, awaiting deposit - Confirmed - Wedding day - Completed. Faint future nodes show "what happens next" (maximum two).
- Each node: label 16, timestamp 12 muted, one sentence.
- Pending shows "Expected reply by Sun 3 Nov, 18:00" (timestamp, not countdown, to avoid guest anxiety; Airbnb phrases this as "typically within 24 hours").
- Status chip (icon plus text plus shape): Pending (gold-ink, clock), Approved (ink, check), Rejected (functional danger, cross), Cancelled (muted, cross), Completed (ink outline, check), Refunded (ink outline, return arrow).
- Rejected or expired: offer three similar venues free on the date and a clear refund line ("Nothing was charged").
- Refunded: amount, method, expected date.
- Notifications mirror each transition (PRD 6.15).

### 4.10 Planner packages (PRD 6.11)

- Entry: one quiet card after booking confirmation ("Need a wedding planner?") and permanently under Plan. Never a blocking interstitial.
- Layout: sticky segmented control Silver | Gold | Royal; one full-width card below with price (or "from"), who it suits ("300-500 guests"), up to 6 included items, and a "Compare packages" link to a fluid-thirds table (same component as 4.6).
- Differentiation: type weight and a 1/2/3 hairline thread mark. No silver/gold/purple gradients.
- Highlighting: only with a stated criterion ("Suits 300-500 guests"); no "Most popular" unless it is true and measurable.
- CTA: "Request consultation". Next: chat then "Schedule meeting" slot picker.
- Pricing model unknown (open question).

### 4.11 Budget manager (PRD 6.13)

Form choices (dataviz rules): single current value gets a hero figure, part-to-whole of three states gets a stacked bar, many categories get a ranked list with meters. Not a donut: eight or more categories and close values are the donut anti-pattern.

- Hero: "Remaining KD 6,420" (48px+ in the UI sans, proportional digits). If over: "Over by KD 420" with a danger icon.
- One horizontal segmented bar (about 12px thick, 4px rounded data end, 2px surface gaps): Paid (ink), Committed/booked but unpaid (gold), Remaining (rose-tint track). A legend row below always shows values.
- Category rows: name, "1,200 / 1,500" tabular, 6px meter; at 80% a calm alert, at 100% functional danger plus icon plus text ("KD 120 over").
- Auto entries: bookings and deposits appear as linked rows with a link icon; guest-count change re-estimates venue and buffet (Zola behaviour).
- Categories map from the PRD services list; Kuwait copy (such as Kosha, zaffa, bisht) must be validated with a local copywriter before use.
- No AI: rules-based suggestions only (digest gap #7).

### 4.12 Checklist and countdown (PRD 6.13)

- Checklist bands = countdown milestones: 12+ months (365), 6 months (180), final month (30), final week (7). Customisable like Zola/The Knot.
- Row: 56px, 44px checkbox target (24px visual), label 16, due chip 12, deep link ("Browse photographers"). The Venue task auto-completes when the booking is confirmed.
- Header progress: "7 of 24 - 29%" with the thread filling.
- Completion motion: 160ms check draw, row slides into a "Completed" group after about 600ms with an undo snackbar; no confetti.
- Countdown: large day count (display face allowed, it is a brand moment) plus six equal-spaced ticks on the thread: 365, 180, 30, 7, 1, 0. Current tick marked; passed ticks filled; the line fills right to left in Arabic. No seconds. Milestone pushes include one suggested next step.

### 4.13 Messages, notifications, profile (PRD 6.14-6.16)

- Chat: human-first. Four Seasons Chat runs in 100+ languages with no chatbots (src). MVP has no bot (AI is Phase 3). Show the venue coordinator as monogram plus name plus reply time ("Replies within 2 h") instead of a face.
- Notification types as in PRD; booking transitions and "date opened" are high priority; offers and new venues are quiet and batched.
- Account deletion in Profile settings is mandatory; place it in a dedicated section with a plain explanation.

---

## 5. Payments and booking mode: the KNET finding in detail

Facts:
- Airbnb (non-India): request to book, host typically responds within 24h; no charge unless accepted; guest can withdraw; dates held while pending (src: Airbnb Help).
- Airbnb India: charged at request, full refund on decline or expiry, "can take up to 15 days" (src).
- Peerspace: hosts have 48h; accepting charges the guest in full; declining releases the authorization hold; invite-to-book handles price changes; expired requests hurt response rate (src).
- KNET through MyFatoorah: "always result in an AuthorizeAndCapture transaction" (src: Broadleaf MyFatoorah docs). No separate hold.

Therefore (proposal, needs ADR):
1. **Request mode**: guest sends request, nothing charged. Venue has 48h hard expiry (24h target; venue nudges at 12h, 4h, 1h). On approval the date is held for the couple 24h. Couple pays the deposit with any PRD method (KNET, card, Apple Pay, Google Pay) to confirm. If unpaid, the hold lapses and the date reopens (Notify-me list is alerted).
2. **Instant mode**: venue opts in per hall; allowed only when the date is at least N days out (Peerspace uses 24h; for weddings N should be larger); deposit charged at the end of the stepper.
3. **Conflicts**: if two requests target the same date, the venue triage card shows the conflict; approving one holds the date and tells the other couple immediately with alternatives.
4. **Status model**: Pending -> Approved (awaiting deposit) -> Approved (confirmed) is the same PRD "Approved", with a sub-label. Rejected, Cancelled, Completed, Refunded unchanged.
5. **Trade-off**: a drop-off between approval and payment is possible. Mitigate with a push, a WhatsApp reminder (channel in PRD), and a clear hold timestamp.

---

## 6. Hotel app: specific UI patterns

### 6.1 Information architecture

Tabs: Today, Bookings, Calendar, Messages, More (matches the brief and echoes Airbnb's host tabs: Today, Calendar, Listings, Messages, Menu; and its later Today, Inbox, Calendar, Insights, Menu). Insights stays in More because managers act, not analyse, in a corridor. Pending requests reachable in one tap from anywhere: a badge on Bookings plus an app-bar pill ("3 to reply") on non-Today screens.

Roles (PRD 7.8 staff; web roles Reception, Manager, Accountant, Marketing): compose Today by role. Reception: requests, calendar, messages. Accountant: payments received, revenue. Manager: all. Design the manager view fully and the others as subsets.

### 6.2 Request-triage card (PRD 7.2)

Expanded card (pending only), 342px wide, 16px padding, hairline border, 12px radius:

```
Needs reply                         Reply within 5 h 20 m     <- 12px; 2px hairline along card top depletes
Thu 14 Nov 2026                                               <- 20/24, weekday + date
Evening  -  Grand Ballroom                                    <- 14 muted
Guests 300      Package Gold      Total KD 4,650.000          <- three facts: label 12 over value 16
You receive KD 4,278.000                                      <- expected payout (Pulse gap)
(AB)  Abdullah A.     Verified phone - First booking     [call] [chat]   <- monogram 40, buttons 44
! Another request for this date, received 2 h ago  Compare   <- conditional
"Special requests ... (2 lines)"  More                         <- conditional
[            Accept            ]   <- primary gold, 48px, deep-ink label
 Propose another date   |   Decline                          <- two 44px secondary text buttons
```

Behaviour:
- Time-left hairline: ink tint by default; gold below 6h; functional danger plus icon below 1h.
- Accept: single tap, 5-second undo snackbar, then commit (deposit request goes out). No confirmation modal.
- Decline: reason sheet (Date unavailable / Capacity does not fit / Package not offered / Other plus optional note), with "Offer other dates" on by default so a rejection becomes a counter-offer. Copy encourages "Decline rather than ignore" (src: Peerspace).
- Propose another date: sheet with a mini month calendar of that hall's open dates, pick 1-3, optional price note; sends as a counter-offer card in the client's timeline (Peerspace custom-offer analogue).
- No swipe actions: hidden and ambiguous under RTL mirroring.
- Sorting: by expiry ascending. Bookings tab segments: Needs reply (n), Upcoming, Past. Compact rows (96px) for everything else: 48 x 56 date block, client and package, time-left or status, chevron.
- Notifications: new request is the only time-sensitive one; deep-links to the card.

### 6.3 Calendar on a phone (PRD 7.3)

- Segmented control: Month | Week | Day. Default Month with the selected day's agenda strip beneath (split view like iOS Calendar).
- Month cell (about 48.9 x 56): number, plus up to three 4px bars along the bottom (one per hall; +n beyond three): solid ink = confirmed, gold = pending, struck-through number = blocked. Today has a ring. Legend collapsible to one line.
- Week: a vertical list of 7 day rows (72-96px each) with event chips; seven columns cannot hold names at 390px.
- Day: a prep - event - teardown timeline per hall with staff notes; not a 24-hour grid.
- Hall filter chips (All, Grand Ballroom, Women's Hall, ...).
- Selection: long-press then drag across dates (Airbnb), haptic tick per day, plus a "Select dates" mode for tap-select (accessibility). Selection reveals a bottom action bar: "5 dates - Block / Open / Offer".
- RTL: Sunday on the right; drag direction mirrors; numerals stay LTR.
- Offline: cache the current and next month; show "Updated 10:42".

### 6.4 Dashboard hierarchy (PRD 7.1)

Top to bottom on Today (390 frame):
1. App bar: venue name plus hall switcher (if more than one), bell with count.
2. **Status sentence** (20/28): "3 requests need your reply" with sub-line "First expires in 5 h 20 m." If none: "You are all caught up" with "Next event: Thu 14 Nov, Al Rashid wedding, 300 guests." (No emoji, no "welcome back".)
3. **Needs reply**: up to two expanded cards, then "See all 5".
4. **This week**: a 7-day strip (Sunday start, mirrored) with bars; tap goes to the day.
5. **KPIs, maximum three**: one hero figure (48px+, UI sans) plus two tiles (24px values). Proposal: Booked value this month (hero, with "KD x received" sub-line), Confirmed this month, Open dates next 30 days. Each tile: 12px label, value, delta vs previous period with arrow and sign (not colour alone). Square's tap-to-compare "vs" becomes tap-to-expand on the hero.
6. **Messages**: two unread previews.

Rule for glanceability: the screen answers "Do I have anything to do, and when?" within 3 seconds, before any number. No charts on Today.

### 6.5 Analytics at 390px (PRD 7.6)

Applying dataviz rules (stat tile over one-bar chart; no dual axis; thin marks; no donut; legend for 2+ series; table-view twin):
- One sticky filter row: segmented 7D / 30D / 90D / 12M above everything.
- Stat tiles (2 x 2): Views, Clicks, Bookings, Revenue; each with delta and a 12-point sparkline (muted, current period in ink).
- Funnel card: horizontal bars (<= 24px thick, 4px rounded end, 2px gaps) for Views, Clicks, Requests, Confirmed; value at the bar tip; conversion between steps as muted text; headline conversion as a tile.
- Revenue over time: single series, 2px ink line, 10% area wash, end-dot of at least 8px with a 2px surface ring and the last value labelled; four x-axis ticks; no legend (single series). Previous period as a ghost line brings a legend; label the two ends directly.
- Top packages: ranked horizontal bar list (3-5 rows), name above bar, value at tip.
- Optional seasonality: 12-cell strip by wedding month (single-hue sequential) to inform pricing.
- Interaction: press-and-hold scrub shows the readout in a fixed header above the plot (the finger hides floating tooltips); hit targets at least 24px; every chart has a table view.
- RTL (decision): mirror the time axis so earlier-to-later follows reading direction, consistent with the mirrored calendar and week strip; digits stay Western and LTR. Material guidance says charts are not mirrored, so this is a recorded exception to test.

### 6.6 Flash-offer creation (PRD 7.5)

Entry points: More > Offers > "+", and calendar select-dates > "Offer". (Unsold dates live in the calendar, so creating from it is the shortest path.)

One scrolling form, all inputs visible, sticky bottom summary:
1. Type: Flash sale | Discount | Coupon (segmented; Flash default).
2. Dates: chips of the next open dates plus "Pick dates" (sheet; only open dates selectable).
3. Discount: chips 10 / 15 / 20 / 25 / Custom. Under it: "Couples see KD 3,100 -> KD 2,635 (-15%)" and "You receive KD x" (commission placeholder).
4. Duration: Ends in 24h / 48h / 72h / when the date passes (default 48h).
5. Applies to: All packages or pick.
6. Preview: the real client venue card with the struck-through price and "Ends Fri 18:00".
7. Sticky bar: "12 dates - 15% off - ends Fri 18:00" with Publish.

Guardrails (src: Airbnb and CMA context): one offer per date, the highest priority wins; minimum 10% (below it a callout is not meaningful); "was" price must be the real price within the prior 28 days; warn above 40% ("Check price?").

After publishing: a status card on Today ("Flash sale - 12 dates - 2 requests so far - ends in 31 h", End now).

### 6.7 Venue management, notifications, settings (PRD 7.4, 7.7, 7.8)

- Photos and videos: require a zone tag at upload (Hall, Stage, Bridal suite, Buffet, Outdoors, Entrance, Layouts), which powers the client photo tour.
- Packages, prices, capacity, amenities, policies: edit as short forms, each with a "Preview as couple" link.
- Notification list grouped by day; each item deep-links; types: new booking (priority), cancelled booking, payment received, new review.
- Settings: staff roles, bank info, business hours, languages.

---

## 7. Luxury-restraint techniques and the clichés to avoid

### 7.1 What the best do (specific, transferable)

Typography
- One editorial display face at light or regular weight for a few moments (Four Seasons: Saol Display 300 for heroes; Aman: Lyon Text 400 for h2/h3 only), with a plain grotesque for everything functional. Proposal: use the display face at most three times per screen; the PRD pair (Poppins, Cairo) is the functional pair.
- Hierarchy through size and tracking, not weight (Aman keeps weight 400 throughout; size runs 10 to 31px; tracking 0.3 to 2px). Proposal: Latin-only uppercase micro-labels at 12px with about 0.08em tracking. **Arabic must never be letter-spaced** (joins break); Arabic eyebrows use size and ink value instead.
- Uppercase tracking never applies to sentences (Four Seasons note).
- Arabic gets +1-2px optical size and about 10-15% more line-height than Latin (src: type-pairing guidance); pair Arabic and Latin by weight and x-height.
- Tabular figures in columns (prices, calendars, tables), proportional for hero numbers (dataviz).

Imagery
- Photography carries all colour; the interface is neutral (Aman: "no primary brand color"; palette runs charcoal to linen). Ghazal keeps gold but spends it on one action per screen, the way Airbnb spends one coral.
- Images reveal the place; no blurred "atmosphere" backdrops (Four Seasons direction).
- Alternate full-bleed image bands with flat fields; leave a hint of the next band under the hero.
- Consistent crop ratios (4:5 cards, 3:2 or 4:5 gallery), one colour grade, warm natural light, no stock couples, empty halls.
- Video only on user action with a static fallback.

Spacing and structure
- Space is the material: 24px gutter (Four Seasons mobile gutter), 48-64px between sections, few modules per screen (Aman: small number of impeccably spaced modules).
- Unframed cards, hairlines instead of shadows (Airbnb relies on photo and corner clipping, not elevation).
- Radius: Aman and Four Seasons use zero; the PRD asks for rounded. Proposal: 0 for editorial dividers, 8 for controls, 12 for image cards, 20 for sheets, pill only for chips.

Motion
- Fast responses 120-240ms; image reveals up to about 700ms using opacity or crop (Four Seasons); keep Ghazal's at or under 500ms except deliberate success moments; container transform for card to gallery (Material container transform; 500ms "long2" for complex choreography); reduced-motion = instant visibility; no decorative loops; transitions never delay booking or hide price and cancellation terms.

Behavioural restraint
- Do less, reliably. Four Seasons' app chose check-in, check-out and room service and left everything else to people (src: Skift). The Jumeirah app at 3.1 stars ("booking function freezes when you try to select dates") and Mandarin Oriental's "can make a reservation but cannot cancel" show that beauty without reliability reads as cheap. Every key surface needs empty, loading, error and offline states.
- Expose total cost, fees, currency, cancellation and accessibility information as plain text (Four Seasons accessibility notes).
- Human presence without faces: a named coordinator with a monogram and a reply-time fact.
- Luxury sites tend to be great at homepages and weak at search/filters (Baymard luxury benchmark). The differentiator is taste plus findability.

### 7.2 Clichés and template tropes to avoid

| Trope | Why |
|---|---|
| Urgency counters ("Only 2 left", "12 people viewing", flashing timers) | CMA enforcement against Booking.com, Expedia, Hotels.com, Agoda, Trivago; Which? found "only one room left" claims still inaccurate. Trust killer. |
| Animated 3D icons, "dimensional" UI | Airbnb's mass-market house style; wrong register for quiet luxury. |
| Metal-gradient Silver/Gold/Royal badges | Generic wedding-template look; tier by type and thread count. |
| Glass panels, blur backdrops, glow, gradient CTAs | Brief anti-patterns; also hide the photograph. |
| Gold-foil calligraphy, arabesque wallpaper, mosque-silhouette stock | Decoration that carries no information. |
| Rainbow category chips, emoji icons, confetti | Childish, off-brand. |
| Star walls and "#1" trophy badges | Rating is a number plus count; one criteria-based badge maximum. |
| Autoplay hero video, auto-advancing carousels, parallax everywhere | Perf and calm. |
| Ticking countdown with seconds | Anxiety, not luxury. |
| "Welcome back" greetings | Brief anti-pattern. |
| Fake social proof ("Most booked") without data | Trust and legal risk. |
| Dense badge stacks (Genius, Popular, Free cancellation, Deal) on cards | Booking.com density is for a different product. |

---

## 8. Cross-cutting decisions

### 8.1 Brand tokens: contrast (computed in this session)

| Pair | Ratio | Verdict |
|---|---|---|
| Ink #5A4B4F on Off White #FFF9F5 | 7.88 | Pass |
| Ink #5A4B4F on Rose #F8E7EC | 6.90 | Pass |
| Gold #D8B26E on Off White #FFF9F5 | 1.91 | Fail: fills and hairlines only |
| Ink #5A4B4F on Gold #D8B26E | 4.12 | **Fail AA for normal text**; passes only large text |
| White on Gold | 2.00 | Fail |
| Deep ink #3A2F33 on Gold | 6.43 | Pass: use for gold button labels |
| Deep ink #2E2528 on Gold | 7.45 | Pass |
| Gold-ink #7A5C1E on Off White | 5.96 | Pass: candidate gold-ink text/icon token |
| Gold-ink #7A5C1E on Rose | 5.22 | Pass |
| #8F7479 on Off White | 4.07 | Fail: muted text needs a darker step |

Action: add a deep-ink token for gold-fill labels, a gold-ink text token (about #7A5C1E, tunable) and a darker muted-ink step.

### 8.2 RTL and numerals
- Mirror: layout, navigation, directional chevrons/arrows, progress, sliders, calendars, week strip, timelines, time-series charts (recorded exception, see 6.5).
- Do not mirror: media controls, clockwise/circular symbols, non-directional icons, logos, phone numbers, digits.
- Digits: default Western 0-9 (Gulf banking/productivity apps increasingly default to it) with a formatter-level user switch; pick one numeral system per screen, never mix.
- Arabic comma and separators from the formatter; currency "د.ك" after the number in Arabic, "KD" before in English.

### 8.3 Money display
- Discovery: "KD 2,450" (hide trailing .000). Booking summary, payment, invoice, budget rows: "KD 2,450.000". Tabular figures in columns; proportional in hero numbers.

### 8.4 Accessibility
- 44px touch targets everywhere (Baymard luxury benchmark flagged hit-area problems on luxury mobile sites; its guidance is at least 7mm x 7mm).
- Booleans and states: icon plus text, never colour alone.
- Calendar and charts need non-drag alternatives and table views.

### 8.5 Motion tokens to propose
- 120 (tap/press), 200 (state change), 320 (sheet, push), 480 (shared-element, success).
- One standard-out curve and one emphasised curve; sheets rise on emphasised-decelerate; push/pop direction flips in RTL.
- Reduced motion: cross-fade 120ms or instant.

---

## 9. Sources consulted

Primary or near-primary:
- Airbnb Help: Request to book vs Instant Book (airbnb.com/help/article/85); host calendar help (airbnb.ca/help/article/2060, /447); redesigned reservations (airbnb.ca/resources/hosting-homes/a/redesigned-reservations-765)
- Airbnb newsroom: 2025 Summer Release (news.airbnb.com); coverage of total price display (TechCrunch 2025-04-21; Design Compass; TechRadar; Rental Scale-Up)
- Rental Scale-Up: Airbnb's new Today host tab (rentalscaleup.com)
- Skift and Bloomberg/TravelPulse coverage: Airbnb Reserve Now, Pay Later (skift.com/2025/08/14/...)
- Airbnb Guest favorite criteria (hospitable.com, hostex.io, rentalscaleup.com) and discounts (hospitable.com, hostex.io, igms.com, Rentals United)
- Airbnb photo tour coverage (Guesty, Hostaway, Travel Extra)
- Booking.com Pulse: App Store listing (apps.apple.com/us/app/pulse-for-booking-com-partners/id992795726), Mara Solutions guide, unstar.app review analysis
- Booking.com promotions: Mara Solutions extranet guide, SiteMinder, Streamline VRS, Recranet, Avantio
- UK CMA action: CMS Law, CNN, TTG Media (Which? spot checks)
- Peerspace help and resources (intercom.help/peerspace..., peerspace.com/resources/accepting-booking-requests)
- Wedding Spot: How it works, listing page, press (wedding-spot.com)
- Bridebook: search page and favourites copy (bridebook.com)
- The Knot: App Store, checklist (theknot.com/content/12-month-wedding-planning-countdown), vendor trust signals (WeddingPro, The Knot help)
- Zola: feature coverage via third-party reviews (budget, guest-count recalculation, vendor payment link)
- Joy: withjoy.com blog and App Store coverage
- Zafaf and Arabia Weddings: Wamda articles, arabiaweddings.com
- Mokanik (App Store id6745263194) and Farah (mwm.ai, App Store data)
- Four Seasons: Skift (2015), Hospitality Net, Hotel Technology News, Journal des Palaces; Ritz-Carlton: Deloitte Digital case study, Journal des Palaces; Jumeirah and Mandarin Oriental App Store listings
- Square Help (Dashboard app), Shopify Dev (metrics card), Shopify changelog (customizable home metrics), PulseKit listing
- Eventbrite: onsite operations tools, check-in app pages; ResyOS App Store listing and Capterra; OpenTable for Restaurants mobile listing
- Broadleaf Commerce docs: MyFatoorah KNET transaction type (developer.broadleafcommerce.com/services/myfatoorah/knet)
- Material Design: bidirectionality (m2.material.io/go/design-bidirectionality, via search summary), container transform and motion (via search summary)

Secondary or third-party (indicative values):
- getdesign.md Airbnb design-system analysis; webdesignhot.com Four Seasons and Hyatt design.md; shadcn.io Aman design.md; Nucleus (Aman website, "The Architecture of Digital Luxury")
- Baymard: luxury e-commerce benchmark; user-friendly comparison tools; Contentsquare on product comparison UI; Foolproof (blocked: 429)
- JetRuby RTL guide; type-pairing guidance on Arabic and Latin; numeral-system discussions (appscreenshotstudio.com, Wikipedia)
- Ninja Tables on mobile table patterns (pinned column, iOS edge-swipe issue)
- Google/travel coverage on Google Flights price graph (Google blog, Travolution)
- Kuwait Times article snippets via search (price per guest and hall anchors)

Could not retrieve (do not rely): Baymard per-site Booking.com/Airbnb pages (paywalled), Apple HIG pages (JS), Material 3 token pages (JS), Medium and uxdesign.cc Booking.com case studies (403), The Knot protection-program press release (403), Arabia Weddings Kuwait halls page (410).

Excluded by rule: the "BookingSaaS v2.3 Nulled.rar" file was not opened or referenced.