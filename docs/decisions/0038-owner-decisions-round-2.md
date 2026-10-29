# ADR 0038: Owner decisions, round 2 (2026-10-29): governorates instead of areas, services independent of venues, partner application form, no guest mode

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-10-29 |
| Scope | Places and filters, what a venue page may show about other services, how service providers and private halls join, the Client app entry (no guest mode, name and sex required) |
| Confirmed by the owner | 2026-10-29, message "there are some changes need to be done to the design so as to the apps themselves", and the three answers of the same day (governorates everywhere; no venue links at all; the form lives in the Partner app only) |
| Supersedes | In ADR 0033 and 0035: the guest assumptions (signed-out visitors browse venues; the guest-gate sheet; `docs/product/owner-decisions.md` item 8 is moot). In the design: CL-ONBD-06 "Preferred areas" (retired), area pickers in the Brief, Filters and Vendors filters |
| Related ADRs | 0033, 0035 (voucher model and round 1), 0028 (auth), 0036 and 0037 (Flutter build) |
| Screens | CL-ONBD-*, CL-AUTH-*, CL-DISC-01..04, CL-VENU-*, CL-SERV-*, CL-PROF-*, HL-PROV-01, HL-ACCS-04 (change list: `docs/engineering/round2-change-brief.md`) |

## Context

After the prototype and both Flutter apps were built and verified (ADR 0037) the owner reviewed them and asked for five product changes. They touch the design, the contract, the mock and both apps, so they are recorded here once and applied everywhere from this record.

## Decision

1. **Governorates, not areas.** The client filters places by governorate only. The list of governorates is configuration (Super Admin). It starts with the six official governorates of Kuwait (Capital, Hawalli, Farwaniya, Ahmadi, Jahra, Mubarak Al-Kabeer); the owner said "about 8", so the list is an editable setting and the exact entries are an open question (OQ-R2-01). The exact-area selection is removed from the Client app everywhere: onboarding (CL-ONBD-06 is retired), the Brief sheet (CL-DISC-02), Filters (CL-DISC-04), Results (the "All areas" chip becomes "All governorates") and the Vendors filters (CL-SERV-02). Venues keep their area as a plain address line; areas stay in the data for the venue's address and for later use, not for the client's selection.
2. **Other services and facilities are independent of venues.** Hotels and halls do not provide catering add-ons, decor or other services as part of Ghazal. The venue side therefore shows none of them: no extras or add-on services inside hotel and hall packages, no service suggestions or "Find catering and decor" link on a venue or governmental facility page. The client adds services only by choosing a service provider in the Services hub (CL-SERV-*) and asking it for a quote. In the first release the Services hub lists only services that Ghazal's venues do not provide.
3. **Partner application form.** Service providers and private halls join by sending a form in the Partner app (HL-PROV-01, extended) with their business information. Ghazal staff accept or reject each application (the reason is shown on rejection) before the account can create listings. The form carries an open note for a service that is not among the pre-registered categories ("Other"); staff can add the category or reject. The Client app has no form: it shows a small note for service providers that points them to the Partner app (CA-SVC-20).
4. **No guest mode in the Client app.** After the language screen and the introduction, the person signs in with their phone (WhatsApp code, or password for returning users) before anything else is shown. A new account must give a name and sex (female or male) before the app opens; both stay editable in Profile. The guest-gate sheet and every signed-out browsing state of the Client app are removed. The Partner app keeps its signed-out state (HL-ACCS-*) because staff must sign in.
5. **Unchanged:** the voucher model (ADR 0033, 0035), the Partner app's signed-in flows, the contract's public read endpoints (a backend may keep them public; the apps never call them signed out).

## Consequences

- Design: retire CL-ONBD-06; rework the Brief, Filters, Vendors filters, CL-AUTH-01..03, the venue and package screens, CL-SERV-01 and CL-PROF-01; extend HL-PROV-01 and HL-ACCS-04. The reference frames change, so the parity references of every touched screen are regenerated.
- Contract and mock: a `sex` field on the client user and on registration (required), governorate narrowing in the Brief and the search (the engine already filters by governorate; the area narrowing is no longer driven by the client), the partner application (business information, other-category note, review decision with a reason), and the removal of venue-linked extras from what the client apps show. All changes are additive; the engine equality suites stay equal.
- Flutter: the router sends a signed-out client to sign-in; no guest gate; governorate chips replace the area pickers; the sign-up asks name and sex; the Partner form is extended; journeys J1 and J6 start from sign-up.
- Voucher copy is unaffected.

## Open questions (working assumptions)

- OQ-R2-01: the exact list of governorates ("about 8"). Working assumption: the six official governorates of Kuwait, kept in configuration so it can grow to eight or to GCC regions.
- OQ-R2-02: sex values and use. Working assumption: female and male, required at sign-up, stored on the account; it is not shown to venues and not used to filter yet (halls with men's and women's sessions keep their own labels). Confirm the purpose and whether it may be shown to partners.
- OQ-R2-03: the business-information fields of the partner form. Working assumption: account type (provider or private hall), business name in Arabic and English, categories (up to three) plus the open "Other" note, governorate, contact person, phone, email, a short description, and an optional commercial licence reference.
- OQ-R2-04: where the client note points. Working assumption: it names the Partner app and links to its store page (a URL kept in configuration); the owner can switch it to a web form later.
- OQ-R2-05: existing signed-out sessions on devices of the earlier builds. Not applicable before launch.
