# ADR 0012: Phone, address and identifier formats, and LTR data inside RTL screens

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-10-12 |
| Scope | Client app and hotel app inputs and displays: phone, OTP, email, IBAN, coupon, names, area, address, guest count, budget, share text; seed fixtures |
| Owner confirmation still needed | OQ-L-14 (fixed +965 chip and the fallback for users without WhatsApp or with a foreign number), OQ-L-18 (clearing fictional names, patterned numbers and IBANs), OQ-L-17 (policy facts as filters) |
| Related ADRs | 0007 (identity entry), 0010 (digits), 0014 (mixed-direction text), 0015 (policy facts, avatars), 0022 (Dart phone module), 0028 (WhatsApp OTP, step-up) |
| Screens | CL-AUTH-01..03, CL-ONBD-05, CL-ONBD-06, CL-DISC-02, CL-BOOK-04, HL-ACCS-01..03, HL-BOOK-04, HL-SETT-04 |

## Context

Kuwaiti data formats break generic components, and Arabic screens must carry Latin and numeric data without scrambling.

- **Phones.** Country code +965, 8 digits; mobiles start 5, 6, 9 and 41xx; landlines start 2. libphonenumber's `isValid()` is range-allocation based and rejects legitimate-looking numbers (`+965 6123 4567` and `+965 9123 4567` return INVALID; `7xxxxxxx` and `8xxxxxxx` are invalid). Its grouping is inconsistent (`512 34567`, `4123 4567`, `9988 7766`). WhatsApp OTP delivery is the real validation. About 94% of Kuwaiti social-media users are on WhatsApp.
- **Addresses.** Area, Block (قطعة), Street (شارع), optional Avenue (جادة), House or Building (منزل / قسيمة), Floor, Flat. Block numbers repeat across areas, so the area is mandatory. PACI maintains an 8-digit automated address number (الرقم الآلي), which is not the 12-digit Civil ID (الرقم المدني); the colloquial 'الرقم الآلي' is ambiguous.
- **Areas.** Six governorates; everyday speech says 'Kuwait City' for the Capital cluster; spellings vary (Mishref, Mishrif, مشرف).
- **Names.** Arabic names often have four parts; first/last splits fail; Arabic or Latin must both be accepted.
- **Data minimisation.** Kuwait's data-privacy regulation (CITRA) is unverified; do not collect Civil ID in the MVP.
- **Inputs.** Phone, email, IBAN, coupon and OTP are LTR data on RTL screens; the value must align to the screen's start edge without hard-coding left or right.
- **Seed numbers.** Kuwait has no reserved fictional range; any seed number could belong to a real person.
- Kuwait IBAN: 30 characters (`KW` + 2 check digits + 4-letter bank code + 22 alphanumerics).

## Decision

**1. Phone storage and validation.** Store E.164 (`+96551234567`). MVP shows a fixed non-interactive `+965` chip; a country selector arrives with GCC expansion through per-country config. This is the one phone rule for every sign-in path including the password account (ADR 0028 item 2): a foreign number is not accepted in the MVP and its owner signs in with Apple or Google (OQ-L-14). Validate with a loose shape check `^(?:[2569]\d{7}|41\d{6})$` plus `isPossible`, never libphonenumber `isValid`. WhatsApp OTP delivery is the real validation.

**2. Phone display and field.** Display `+965 5123 4567` (4+4 grouping from our own formatter) inside an LTR isolate, in both languages. The input is one compound field: the +965 chip then eight digits, LTR visual order in both languages, full width, numeric keypad, Western digits. Label, helper and error follow UI direction; the typed value aligns to the start edge (right in Arabic) using a direction variable, not a left/right property.

**3. Actions.** Call is `tel:+965XXXXXXXX`; WhatsApp is `https://wa.me/965XXXXXXXX` (digits only, no plus, no spaces). The hotel app client row shows call and WhatsApp (and in-app chat) as separate 44px targets.

**4. OTP.** Six boxes in LTR order in both languages (digit 1 on the left), paste and one-time-code autofill, 60 s resend, an 'Open WhatsApp' link, Eastern digits normalised on paste.

**5. LTR-data fields.** Phone, email, OTP, IBAN, coupon code, URL, booking and invoice references render and edit with `dir="ltr"`, correct `inputmode` and `autocomplete`. Coupon codes are Latin uppercase in both languages. IBAN entry is uppercase, grouped by 4, mod-97 validated; display is masked except the last four characters; editing needs re-authentication (ADR 0028 item 6).

**6. Names.** One `الاسم الكامل / Full name` field with `dir="auto"`, Arabic or Latin accepted, no first/last split. Monogram is derived from the first letter of the name in its own script (ADR 0015 item 4).

**7. Address model.** Area (mandatory) then Block (قطعة), Street (شارع), optional Avenue (جادة), House or Building (منزل / قسيمة), Floor, Flat. Venues display `Area · Block · Street` plus a map pin; no PACI number. The directions chooser offers Google Maps, Apple Maps (iOS only) and Waze. Phase 2 home-service vendors take a full address with an optional field labelled `الرقم الآلي للعنوان (PACI)` / `PACI address number`; the bare label `الرقم الآلي` is never used. Civil ID is not collected in the MVP.

**8. Area picker.** Grouped under the six governorates (العاصمة، حولي، الفروانية، الأحمدي، الجهراء، مبارك الكبير), searchable, multi-select for onboarding (CA-ONB-06) and filters (CA-SRCH-03), canonical names from the Super Admin area data (SA-AREA-01), displayed in the UI language, with a search-only alias table (examples: Mishref = مشرف / Mishrif / Meshref; Bneid Al-Qar = بنيد القار / Bnaid Al-Gar; Salmiya = السالمية / Salmiyah; the colloquial 'Kuwait City' maps to the Capital areas). Arabic search normalisation: strip tashkeel and tatweel; unify أ إ آ to ا; ى to ي; optional ة to ه; optional ال; Eastern to Western digits; Latin case-fold.

**9. Guest count and budget inputs.** Guest count is a stepper plus preset chips (100, 150, 200, 300, 400, 500, 650, 800, 1,000+; hard cap 1,500 per the brief). Budget uses bands (under 5,000 | 5,000-10,000 | 10,000-20,000 | 20,000-35,000 | 35,000+) with a custom range, labelled `ميزانية القاعة والضيافة` / `Venue and catering budget` so it is not confused with total wedding spend.

**10. Share text.** Share-to-WhatsApp (venue, compare, booking summary) carries image, Arabic or English name per UI language, area, the 'From' price with its basis, and a link; no emoji.

**11. Fixtures.** Prototype phones use obviously patterned `+965 5000 00NN` values, display-only and never rendered as tappable `tel:` or `wa.me` links. Each number belongs to one party: `0001` Ghazal Support, `0002` Aurelia Gulf Hotel, `0012` Reem Al-Dosari, `0040` the next free fixture; never reuse a number for a second party.

Layout rule for the phone field on an Arabic screen: the label, helper and error text follow the UI direction (right-aligned), while the field itself reads left to right: the `+965` chip first, then the eight digits, with the typed value starting at the screen's start edge (the right edge in Arabic) through a direction variable.

## Consequences

- Numbers read left to right with no scrambling; loose validation avoids rejecting real customers; one address model serves venues and Phase 2 vendors.
- A fixed +965 chip excludes users whose WhatsApp number is foreign; fallback paths (Apple and Google sign-in, email OTP) are an owner decision on the CA-AUTH-06 gap (OQ-L-14, OQ-T-08).
- Our own phone grouping and the alias table are small pieces of code and data that must be maintained (`PhoneKw` and the digit normaliser live in `ghazal_core`, ADR 0022 B).
- Seed numbers in the 5000 range could belong to a real person, hence never clickable.
- The server normalises Arabic-Indic (U+0660-0669) and Persian (U+06F0-06F9) digits on every numeric, phone, OTP and amount input (ADR 0020), and keeps `name_norm` columns and area aliases for search.
- The hotel Contact sheet shows Call, in-app Chat and a WhatsApp row (OQ-B-12); the number is visible only once shared (OQ-B-19, ADR 0008 D5).
- `PACI` and Civil ID are out of the MVP; if a venue contract requires them, collect off-app.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| libphonenumber `isValid()` | Rejects real Kuwaiti numbers; WhatsApp delivery is the validation |
| A country selector in the MVP | Only +965 for now; per-country config arrives with GCC expansion |
| libphonenumber national grouping | Inconsistent; our 4+4 grouping |
| First name and last name fields | Four-part names; one full-name field |
| Places Autocomplete for areas | Costlier and worse UX than a curated list with aliases (ADR 0022 G) |
| A PACI address-number field for venues | Not needed; map pin plus Area, Block, Street |
| Collecting Civil ID | Data minimisation; privacy rules unverified |
| Budget labelled 'wedding budget' | Confused with total spend; label it venue and catering |
| Right-to-left phone input (reversed digit groups) | Scrambles groups; one LTR compound field |
| Real-looking seed phone numbers | Could be real people; patterned and never clickable |

## Related requirement IDs

| ID | Effect |
|---|---|
| CA-AUTH-05, CA-AUTH-06 | WhatsApp OTP entry, resend, expiry; phone field and OTP boxes |
| CA-ONB-04, CA-ONB-05, CA-ONB-06 | Budget bands, guest presets, multi-select areas |
| CA-SRCH-03, CA-SRCH-05 | Area filter and capacity filter inputs |
| CA-BOOK-07 | Personal information with a verified phone and a contact person |
| CA-VDET-09, CA-VDET-10 | Map and directions chooser |
| HA-BOOK-06 | Call and WhatsApp targets on the client row |
| HA-SET-03 | IBAN entry, masking and re-authentication |
| SA-AREA-01 | Canonical area data and alias table |
| PL-AUTH-02 | OTP policy (ADR 0028) |
| NF-LOC-01 | Both scripts first-class in inputs |
