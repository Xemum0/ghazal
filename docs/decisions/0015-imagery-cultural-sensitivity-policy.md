# ADR 0015: Imagery and cultural-sensitivity policy: empty rooms, monogram avatars, per-section policy facts

| Field | Value |
|---|---|
| Status | proposed-needs-owner |
| Date | 2026-10-12 |
| Scope | All imagery (venue galleries, reviews, ads, onboarding, empty states, seed content), avatars, section badges, per-section policy fields, user and venue media moderation, content timing |
| Owner must confirm | OQ-L-07 (empty-room-only galleries even though most venues' photos include people), OQ-L-08 (review media policy and who staffs the moderation queue), OQ-L-15 (push timing rules), OQ-L-17 (policy facts as filters or detail-page facts only), OQ-L-18 (clearing fictional names and fixtures), OQ-B-25 (review governance) |
| Domain assumptions to validate | Music axis, abaya cloakroom, boys' age rule, bukhoor limits: validate with 5-8 venue managers |
| Related ADRs | 0002 (per-hall policies per section), 0012 (names, monogram source), 0013 (neutral wording), 0016 (type), 0018 (card and section tags), 0019 (privacy), 0022 (push) |
| Screens | CL-VENU-01, CL-VENU-02, CL-VENU-05, CL-RVRW-01, CL-RVRW-02, CL-MSGS-02, HL-VENU-01, HL-VENU-04, HL-VENU-05, HL-GROW-06 |

## Context

A Kuwaiti wedding is gender-segregated in most cases, and the product will be forwarded through family WhatsApp groups. Research (localization section 2.8 and competitive-ux) found:

- Ladies' hall interiors with people must never be published. Review photos and videos (PRD 6.16) would otherwise leak images of unveiled women from ladies' halls; a Gulf privacy risk that matches the brief's no-faces rule.
- Alcohol is illegal in Kuwait (welcome drinks are mocktails, juices, gahwa, dates). No mixed-gender dancing or touching imagery, no bare shoulders, no embracing or heart-with-couple clichés, no royal portraits or state emblems, no mosque imagery or Quranic verses as decoration.
- Policy fields are per section: photography in the ladies' hall (female photographers only or none), music policy including a 'no instruments' option, abaya cloakroom, prayer room, separate entrances, female security, children and boys' age rule, outside catering and decor, bukhoor, indoor backup for outdoor. These are the questions Kuwaiti families actually ask and common reasons a venue is excluded; the PRD offers only a venue-wide photography filter (CA-SRCH-12).
- Venues' existing Instagram and wedding photography usually include people, so most existing venue imagery becomes unusable.
- Luxury restraint (competitive-ux 7): photography carries all colour, one grade, consistent crop ratios, no blurred backdrops, no autoplay video, no gold-calligraphy or arabesque wallpaper.
- Avatars: a single Arabic letter stands alone; a connected two-letter pair misrenders.
- Push timing: weddings happen at night and families are on their phones then; Friday congregational prayer and Ramadan change attention windows.
- Mixed events are a minority and a sensitive label.

## Decision

**1. What imagery shows.** Empty rooms and details only: halls, tables, florals, kosha (bridal stage), lighting, buffet, exteriors, gardens and beaches, entrance and valet, seating-layout plans, rings, henna patterns on hands, objects. Never an identifiable face, hair or body, silhouettes of people, guests, staff, performers or couples, in any gallery, review, ad, onboarding, empty state or illustration, whether photographed, stock or generated. Seed photography is generic: no legible signage, no recognisable real landmarks or real hotel identity next to a fictional venue name. Every image has bilingual alt text naming the zone and venue; credits are recorded in `design/public/images/CREDITS.md`; generated imagery must pass the same rules.

**2. What imagery never shows.** Alcohol, bars, champagne towers, cocktails (welcome drinks are mocktails, juices, gahwa, dates); mixed-gender dancing or touching; bare shoulders or revealing dress; embracing, kissing or heart-with-couple clichés; royal portraits, state emblems, flag misuse; mosque imagery or Quranic verses as decoration; other-faith wedding iconography unless a venue explicitly serves that community; arabesque wallpaper or gold-calligraphy ornament that carries no information. Service categories (Phase 2): dress on a hanger or headless mannequin, makeup as tools and palettes, henna as hand patterns only, photography as equipment, entertainment as instruments and lighting.

**3. One grade.** Photography carries all colour: one warm natural grade, consistent crop ratios (ADR 0018), no heavy pink wedding filters, no blurred backdrops, no autoplay video anywhere; video starts only on a tap, with a static poster.

**4. Avatars.** A single-letter monogram: the first letter of the name in its own script, ignoring `ال`; an Arabic letter stands alone in its isolated form, never a connected pair (if two letters are ever required they are separate spans or joined by ZWNJ); Latin names use the first Latin capital. Style: Rose-tint disk with Ink letter (6.90:1) or Ink disk with Off-White letter, sizes 24/32/40/56. Venues and vendors without a logo use the same monogram. There is no avatar upload and no photo field anywhere; onboarding asks names and role only.

**5. Section badges and neutrality.** Ladies, men and mixed are text-only chips (`نسائي` / `رجالي` / `مختلط`; Ladies / Men / Mixed), never male or female pictograms or silhouettes. Mixed is last in every list, never the default, and never suggested to someone who chose ladies-only. Women-only and men-only are neutral facts, not marketing claims.

**6. Per-section policy facts** (replacing any venue-wide toggle, per CA-SRCH-12/13 and CA-VDET-26). For each section the venue states:

| Fact | Values |
|---|---|
| Photography | female photographers only / none / allowed |
| Music | DJ or band / live / duff and nasheed only, no instruments / none, shown as a plain fact such as `الموسيقى: دفوف فقط` / `Music: duff only`, with no judgement words |
| Dress code | bilingual free text (CA-VDET-18) |
| Facilities | abaya cloakroom; prayer room; separate entrance; female security |
| Rules | children and boys' age rule; outside catering allowed; outside decor allowed; bukhoor allowed |
| Operations | indoor backup for outdoor; cut-off time and overtime |

Each fact is an icon plus a plain label from the amenity taxonomy; negative or moralising wording is forbidden.

**7. User and venue media.**

- *Reviews:* text publishes after an automated check; photos and videos enter an 'under review' state visible only to their author and publish only after moderation (people detection plus a human queue) passes; allowed subjects are venue, decor, food and details; the composer states the rule up front (`لا يمكن نشر الصور أو المقاطع التي يظهر فيها أشخاص.` / Photos and videos showing people can't be published.). Reviewer names show first name plus initial (`نورة ع.`) with an anonymous option; rating categories are venue, food, service, value; a report control exists for every review (CA-REV-06).
- *Chat media* (CA-CHAT-07) is private between participants and carries a report action.
- *Hotel uploads* (HA-VMGT-01): the upload sheet says 'empty-room photos only', requires a zone tag (Hall, Stage and Kosha, Bridal suite, Buffet, Outdoors, Entrance and valet, Layouts), warns when a face is detected, and moderation rejects with a stated reason.

**8. Content timing.** Client push observes quiet hours 23:00-08:00 Asia/Kuwait (transactional pushes in that window are silent and still land in the notification centre); no marketing push 11:30-13:00 on Fridays; in Ramadan marketing moves to after Maghrib. The hotel app's new-request push follows the venue's business-hours setting. Ashura is a quiet calendar marker with no commentary.

**9. Copy and imagery review.** Every screen is checked against this list in design QA, next to the RTL checklist of ADR 0014.

## Consequences

- The product is safe to show in any Kuwaiti family's WhatsApp group; the policy fields answer the questions families actually ask and make the venue profile honest.
- Venues' existing Instagram and wedding photography (which usually includes people) becomes unusable; venues must shoot empty-room galleries or crop. The owner must accept this (OQ-L-07).
- Moderation needs tooling and a human queue (OQ-L-08); face detection has false positives and negatives. If capacity is missing at launch, fall back to text-only reviews plus venue media.
- Prototype photography must be licensed stock or generated without people, which narrows the pool.
- Per-section policy fields add venue-side data entry in the hotel app (one short form per section, HL-VENU-04 and HL-VENU-05).
- Domain-knowledge assumptions (music axis, abaya cloakroom, boys' age rule, bukhoor limits) need validation with 5-8 venue managers.
- The i18n lint and design QA both include the banned-phrase and banned-imagery lists (ADR 0013, `docs/design/content-guidelines.md`).
- Reviews: venues reply once and report abuse; they do not approve or hide (OQ-B-25); eligibility is booking owner, status `completed`, one per booking.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Allow people in galleries with face blur | Detection is imperfect; hair and body remain identifiable; ladies' halls must never show people |
| Venue-only media for reviews (no user media) | Kept as the fallback if moderation capacity is missing (OQ-L-08) |
| Automatic face-blur on review media | Same imperfections; an 'under review' state plus human queue is safer |
| Photo avatars or an avatar upload | Privacy; the brief says avatars are monograms |
| Male and female pictograms for sections | Text-only chips; neutral facts, never silhouettes |
| A venue-wide 'photography allowed' toggle | Wrong for dual-section venues; per-section facts replace it |
| Mixed prominent or default | Sensitive label for the core audience; present, neutral, last, never default |
| Metal tier badges, arabesque wallpaper, calligraphy ornaments | Carry no information; template tropes |
| Autoplay video | Performance and calm; tap-to-play with a poster |
| Photographic couples in onboarding or empty states | Violates the no-faces rule |
| Marketing push at any hour | Quiet hours and prayer and Ramadan windows apply |

## Related requirement IDs

| ID | Effect |
|---|---|
| NF-DSN-02, NF-DSN-05 | Imagery carries the screens; restrained accent |
| CA-SRCH-12, CA-SRCH-13, CA-VDET-26 | Photography and attendance policy as per-section facts |
| CA-VDET-01, CA-VDET-02, CA-VDET-15, CA-VDET-18 | Gallery, video, music facility, dress code |
| CA-REV-01..06 | Review text, media moderation, venue replies, report |
| CA-CHAT-07, CA-CHAT-11 | Chat media privacy and report |
| CA-ONB-07 | Names and role only |
| HA-VMGT-01, HA-VMGT-07, HA-VMGT-08 | Upload rules, amenities, policies |
| CA-NOTI-03..05 | Marketing notification timing |
| CF-24 | Reviews and user-generated content: report and block, venues reply and report only |
| NF-EXC-01 | Photography excluded from dev scope; owner supplies compliant content |

## Notes on conflicting inputs

- **Quiet hours.** Item 8 sets client push quiet hours at 23:00-08:00 (transactional pushes in that window are silent, still in the notification centre). ADR 0007 D11 sets marketing quiet hours at 22:00-09:00 with a cap of 2 per week and says 'transactional always delivered'. These can be read as two layers (marketing is held back longer than everything else; transactional is delivered silently at night), but the ADRs do not say so. Treat the layered reading as the working assumption and confirm with OQ-L-15.
