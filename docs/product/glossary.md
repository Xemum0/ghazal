# Ghazal — Glossary (Arabic and English, including Kuwait wedding vocabulary)

> One term, one meaning, one Arabic word. Canonical sources: ADR 0013 (Arabic voice), ADR 0003 (statuses), ADR 0002 (booking vocabulary), `docs/research/kuwait-localization.md` §3.3, and the Arabic strings already used in `docs/product/screens/**`.
> **Arabic in the UI is the canonical term; "aliases" are search-only and never shown.** A dagger (†) marks a provisional Arabic term that no source fixes yet: it needs the native Kuwaiti reviewer before visual freeze (OQ-L-06).
> Overrides of the older research glossary (ADR 0013 D3): guests are **ضيف / ضيوف** (never مدعو / مدعوات); tanween is written in the ICU form with the fathatan before the alef (يومًا, ضيفًا, مقدمًا); client-facing "Rejected" is **لم يُقبل الطلب**; the hotel button is **اعتذار**.

## 1. Booking and money

| English | Arabic (UI) | Meaning and usage | Notes |
|---|---|---|---|
| Brief | تفاصيل زفافكم | Date, guests, area and budget as global context; drives price and availability on every card (ADR 0007 D3). "Not decided" and "Flexible month" are valid values | Onboarding and Brief budget = venue and catering budget (ميزانية القاعة والضيافة); the total wedding budget is asked in the Budget Manager; search budget filter = venue price (ADR 0007 D3, amended) |
| Booking / Request | الحجز / الطلب | A **request** is a booking in status `requested`: no money, no calendar claim. Never say "Book now" | CTA: "Request to book" / طلب الحجز; "Send request" / إرسال الطلب |
| Request mode / Instant booking | طلب حجز / حجز فوري | Per-hall mode. Instant needs verified payout, an instant-verified flag or track record, event 30 days or more away, fixed price (ADR 0001 D3) | Settings label: وضع الحجز |
| Approval / Hold | تمت الموافقة / محجوز لكم حتى {الوقت}† | Approval creates a **hold** and a pay window; the date is "held for you", not secured, until the deposit lands | Never "secured" before `confirmed` (ADR 0001 consequences) |
| Deposit | العربون | Default 30% of the total, rounded up to the next KD 5, never below 20% (ADR 0005 D1) | Never cash; always online (CF-27) |
| Balance | المبلغ المتبقي | Remainder, due 14 days before the event | Venue-configurable 7-30 days |
| Pay window / Response window | مهلة الدفع / مهلة الرد | Time the client has to pay after approval (default 24 h) / time the venue has to reply (default 24 h, max 48 h) | See section 11 |
| Package | الباقة | A priced bundle bound to one or more halls; never named Silver, Gold or Royal (reserved for planners) | Plural الباقات |
| Extras | الإضافات | Optional add-ons priced separately (kosha, florals, female photographer) | Items already in the package show "Included" |
| Special requests | طلبات خاصة | Free text from the couple to the venue | |
| Review (the step) | المراجعة | Last screen before commitment; shows the full price and schedule; no fee may appear after it | Distinct from a venue review (التقييم) |
| Cancellation policy | سياسة الإلغاء | Template of days-before-event tiers (Flexible, Standard, Strict); consented to on Review | Free-cancellation date is always absolute |
| Free cancellation until {date} | إلغاء مجاني حتى {التاريخ} | Last date with 0% forfeit under the policy | "No free cancellation (event within 60 days)" when applicable |
| Cooling-off | فترة التراجع (48 ساعة)† | Platform-wide: 100% refund within 48 h of paying when the event is 30 days or more away (ADR 0006 D2) | Owner and lawyer pending (OQ-B-05) |
| Refund | الاسترداد | Exists only after money was paid; to the original method; arrival copy is soft (KNET 1-3 working days, cards up to 10) | Rejection, expiry and a lost slot never refund anything |
| Counter-offer / Propose another date | اقتراح موعد آخر | Venue offers 1-3 other dates for the same hall and session; client has 48 h (72 h for a reschedule of a confirmed booking) | Client card: اقتراح موعد آخر من المكان / "Venue proposed another date" |
| Reschedule | تغيير الموعد | Child object, never a status; a confirmed booking shows a "Reschedule pending" chip | |
| Receipt / Invoice | الإيصال / الفاتورة | A receipt per payment at once; the invoice updates as payments land; documents say KWD | Issuer wording pending (OQ-B-06) |
| Payment schedule | جدول الدفعات† | Four nodes: Today, On approval, Balance due {date}, Wedding day | |
| Coupon / Platform credit | كوبون / رصيد غزل† | A venue coupon is an offer that needs entry; platform credit is platform-funded and never lowers the venue payout | Rules pending (OQ-B-14) |
| Service charge | رسوم الخدمة† | Appears only when the venue declares one; included in the headline price | No VAT lines in Kuwait |
| Commission / Payout | العمولة / المستحقات† | Ghazal's cut, collected from the deposit via the gateway split; the venue's payout | Hotel app shows "You receive KD X" only when a rule exists, never to Reception |
| Booking reference | رقم الحجز† | Format `GZ-2611-0147`, an LTR isolate | See inconsistency note in `screen-inventory.md` |

## 2. Statuses (ADR 0003; chips always carry an icon and a label)

The PRD's six statuses are the vocabulary of filters and reports; the nine internal statuses are the canonical enum.

| Internal enum | PRD family | Client chip (EN / AR) | Hotel chip (EN / AR) | Chip style |
|---|---|---|---|---|
| `requested` | Pending | Pending / بانتظار الرد | Pending / بانتظار الرد | gold tint, clock |
| `awaiting_deposit` | Approved | Approved - deposit due / تمت الموافقة · بانتظار العربون | same | gold outline, hourglass |
| `confirmed` | Approved | Confirmed / مؤكد | Confirmed / مؤكد | success, check |
| `rejected` | Rejected | Not accepted / لم يُقبل الطلب | Declined / تم الاعتذار | danger, x |
| `expired` | Cancelled | Expired / انتهت المهلة | Missed / انتهت مهلة الرد (venue silence); Expired / انتهت المهلة † (client did not pay) | neutral, clock-off |
| `cancelled` | Cancelled | Cancelled / ملغي (by me, by venue, by Ghazal) | Cancelled / ملغي | neutral ink, x |
| `refunded` | Refunded | Refunded / تم الاسترداد | Refunded / تم الاسترداد | rose tint, return arrow |
| `completed` | Completed | Completed / مكتمل | Completed / مكتمل | ink tint, double check |
| `no_show` (P2) | Completed | No-show / عدم حضور | No-show / عدم حضور | danger outline, user-minus |

Supporting fields: `cancelled_by` (client, venue, system, admin); `expired_reason` (venue_no_response, client_no_payment, slot_taken, client_no_response); overlays that are never statuses: counter-offer, reschedule request, amendment, blocked-by-hold, payout hold, dispute, deposit-verifying. The client-side Arabic label for Rejected is لم يُقبل الطلب (ADR 0013 D4, quoted by ADR 0003 D2).

## 3. Venue, hall, session, audience

| English | Arabic (UI) | Meaning and usage | Notes |
|---|---|---|---|
| Venue | المكان (generic: the venue as a business); فندق for hotels, قصر / مركز for halls by their own name | The container: brand, policies, payout account | Venue names show Arabic in the Arabic UI, English in the English UI |
| Hall | قاعة (e.g. قاعة الدانة) | The bookable unit: capacity bounds, allowed audiences, setting, sessions | Distinct from the venue: قاعة means only the bookable room, never the business (headers say فندق أوريليا الخليج · قاعة الدانة). Aliases: صالة (search only) |
| Session | الفترة† (e.g. الفترة المسائية†) | A time template per hall: Afternoon 12:00-16:00, Evening 19:00-01:00 (default), Full day | Not الجلسة, which means a sign-in session. Hidden when only one is free (ADR 0002 D5) |
| Exclusive day | قاعة لحفل واحد في اليوم† | One wedding per hall per day; removes the session picker | Default for ballrooms with kosha setup |
| Event section | القسم† | Hall × session × audience × guests × package; a booking has 1 or 2 | UI shows a Ladies and Men tab pair, not the word section |
| Audience: ladies / men / mixed | الحفل النسائي / الحفل الرجالي / حفل مختلط (chips: نسائي / رجالي / مختلط) | Text chips only, never male or female pictograms; **Mixed is last in every list and never the default** | Banned: حريمي (search alias only) |
| Both | الاثنان | Adds a second section with its own hall, guests and package; atomic approval, payment and cancellation | UI may ship in v1.1 |
| Setting: indoor / outdoor / mixed | داخلي / في الهواء الطلق / مختلط (داخلي وخارجي) | Not the same "mixed" as audience; the filter label is "Mixed setting" | CF-21 |
| Government hall | قاعة حكومية | Ministry of Social Affairs hall: listing plus hand-off, no Ghazal checkout | "Book via official channel" / الحجز عبر وزارة الشؤون الاجتماعية |
| Official channel | القناة الرسمية† | Compare footer label for a government hall | |
| Luxury level | فاخر · راقٍ · كلاسيكي · قاعة حكومية | Prestige, Signature, Classic, Government | Never Silver, Gold or Royal for venues |
| Featured / Sponsored / New | مميز / إعلان / جديد | Paid placement is always labelled إعلان; a venue with no reviews shows جديد, never 0.0 | MK-SUB-04 |
| Guests | ضيف / ضيوف | Per hall ("Guests in this hall"); stepper steps by the package guest step | Aliases: المدعوون, المعازيم |
| Capacity / Minimum guests | السعة / الحد الأدنى 200 ضيف | Hall bounds / package floor, below which the price is the minimum price | |

## 4. Kuwait wedding vocabulary

| English | Arabic | Notes for product and copy |
|---|---|---|
| Ladies' reception | الحفل النسائي | The headline event: bride, kosha, zaffa, dinner buffet, evening start. Banned: حريمي |
| Men's reception | الحفل الرجالي | Shorter; Friday lunch after the Jumu'ah prayer is common [K]; often in a diwaniya or Majlis Hall |
| Men's lunch | غداء الرجال | Package archetype |
| Kosha | الكوشة | Bridal stage; first use in English: "Kosha (bridal stage)" |
| Zaffa | الزفّة | Bridal procession; first use: "Zaffa (bridal procession)" |
| Bridal suite / Groom's room | جناح العروس / غرفة العريس | Facilities |
| Milka (marriage contract) | ملكة† | Alias: عقد القران, الملجة. Optional Occasion chip, flagged (OQ-B-11) |
| Henna night | ليلة الحناء | A proper event name, allowed; the banned pattern is "ليلة" plus a weekday |
| Diwaniya / Majlis | ديوانية / مجلس | Men's gathering room; "Majlis Hall" is قاعة المجلس |
| Gahwa and dates | القهوة والتمر | Welcome service; welcome drinks are mocktails and juices, never alcohol |
| Bukhoor | بخور | May be restricted by hotel fire systems; shown as "Bukhoor allowed" |
| Duff and nasheed | دفوف وأناشيد | Music policy value: "Music: duff only" / «الموسيقى: دفوف وأناشيد فقط»; stated neutrally, no judgement words |
| Abaya cloakroom / Prayer room | غرفة العبايات / مصلى | Per-section policy facts (ADR 0015 D6) |
| Female photographer | مصوّرة | Photography policy: female photographers only / none / allowed |
| Guest favours | توزيعات | Checklist and budget preset, pending (OQ-P-07) |
| Ramadan events | غبقة · قرقيعان | Venues use inventory for these in Ramadan [K]; hence blocks need a reason |
| Mahr and gold | المهر والذهب | Optional budget category, pending (OQ-P-07) |
| Civil ID / PACI address number | البطاقة المدنية / الرقم الآلي للعنوان (PACI) | Civil ID is not collected in the MVP; the bare label «الرقم الآلي» is never used (ADR 0012 D7) |

**Governorates and seed areas** (use only these in seed content; canonical English transliteration with Al- and capitals):

| Governorate | Areas |
|---|---|
| Capital / العاصمة | شرق Sharq · بنيد القار Bneid Al-Qar · الشويخ Shuwaikh · الدسمة Dasma |
| Hawalli / حولي (densest) | السالمية Salmiya · الجابرية Jabriya · مشرف Mishref · سلوى Salwa · بيان Bayan · حطين Hateen |
| Farwaniya / الفروانية | خيطان Khaitan · جليب الشيوخ Jleeb Al-Shuyoukh · الري Al-Rai |
| Ahmadi / الأحمدي | الفنطاس Fintas · المهبولة Mahboula · الخيران Khiran |
| Mubarak Al-Kabeer / مبارك الكبير | المسيلة Messila · القرين Qurain · صباح السالم Sabah Al-Salem |
| Jahra / الجهراء | تيماء Taima · العيون Oyoun |

Address pattern: area, block (قطعة), street (شارع); optional avenue (جادة), house or building (منزل / قسيمة), floor, flat. "Kuwait City" in speech maps to the Capital areas.

## 5. Amenities and policy facts (icon plus plain label)

Space: Ladies' hall قاعة نسائية · Men's hall قاعة رجالية · Separate entrance مدخل منفصل · Indoor backup قاعة بديلة داخلية · Garden or terrace حديقة أو تراس. Services: Buffet included بوفيه مشمول · Welcome drinks ضيافة الاستقبال · Gahwa and tea قهوة وشاي · Valet فاليه · Free parking مواقف مجانية · Female security حراسة نسائية · Accessibility تسهيلات لذوي الإعاقة · Kids' corner ركن الأطفال. Production: Sound and lighting صوت وإضاءة · LED screens شاشات LED · Basic decor included ديكور أساسي مشمول · Music policy سياسة الموسيقى · Photography policy سياسة التصوير. Policies: Outside catering allowed ضيافة خارجية مسموحة · Outside decor allowed ديكور خارجي مسموح · Dress code زي الحضور (example «لباس رسمي محتشم») · Children الأطفال · Cut-off time and overtime ساعة الانتهاء · Cancellation الإلغاء.

Facility rows use three states: **Included / Extra / Not offered** (icon plus text).

## 6. Navigation and action labels

| Client tab (EN / AR) | Hotel tab (EN / AR) |
|---|---|
| Discover / استكشاف | Today / اليوم |
| Saved / المفضلة | Bookings / الحجوزات |
| My Wedding / زفافكم | Calendar / التقويم |
| Messages / الرسائل | Messages / الرسائل |
| Profile / حسابكم | More / المزيد |

| Action | Arabic | Notes |
|---|---|---|
| Continue | متابعة | Verbal noun, not a gendered imperative |
| Send request | إرسال الطلب | Review CTA in request mode |
| Pay deposit | دفع العربون | Instant mode CTA: "Pay deposit KD {amount}" |
| Confirm booking | تأكيد الحجز | |
| Accept / Decline / Propose another date | قبول / اعتذار / اقتراح موعد آخر | Hotel; "اعتذار" is softer than "رفض" |
| Block dates / Open dates | إغلاق التواريخ / فتح | Blocked dates: تواريخ مغلقة; reasons: حجز خارج غزل, صيانة, مناسبة خاصة, أخرى |
| Record cash received | تسجيل مبلغ نقدي مستلم | Balance only |
| Cancel booking | إلغاء الحجز | |
| Compare / Replace which one? | مقارنة / أي قاعة تستبدلون؟ | Max 3 |
| Needs you | بانتظاركم | Hotel Needs-you queue |
| Request consultation | طلب استشارة | Planner |
| Sign in | تسجيل الدخول | One entry; "Continue with WhatsApp" / المتابعة عبر واتساب |
| Verification code | رمز التحقق | Six boxes, LTR order in both languages |

Staff roles (paired forms like the planner role, so labels stay gender-neutral; the person's stored form is shown, the pair is the default in settings lists): Admin (owner) المالك / المالكة† · Manager المدير / المديرة · Reception الاستقبال · Accountant المحاسب / المحاسبة · Marketing التسويق. Planner tiers: Silver الفضية (650, "Day-of coordination" / تنسيق يوم الحفل) · Gold الذهبية (1,900, "Planning and styling" / تخطيط وتنسيق) · Royal الملكية (5,500, "Full design and production" / تصميم وإنتاج متكامل); shown by one, two or three thread marks, never metal colours. The planner service is **تنسيق الأعراس**; the person is منسّق / منسّقة الأعراس (not "ويدنج بلانر").

Planning and settings: Checklist قائمة المهام · Budget الميزانية · Countdown العدّ التنازلي · Notifications الإشعارات · Reviews التقييمات · Rewards المكافآت · Offers العروض · Flash sale عرض سريع · Analytics التحليلات · Bank information بيانات الحساب البنكي · Business hours ساعات العمل · Digits الأرقام · Biometric lock القفل الحيوي.

## 7. Dates, time and occasions (ADR 0011)

| Term | Rule |
|---|---|
| Full date | AR `الخميس 14 يناير 2027`, EN `Thursday 14 January 2027`; short `Thu 14 Jan`; never numeric-only; never "ليلة" plus a weekday (in Arabic, ليلة الجمعة means Thursday night). Use `مساء الخميس 14 يناير`. |
| Gulf month names | يناير فبراير مارس أبريل مايو يونيو يوليو أغسطس سبتمبر أكتوبر نوفمبر ديسمبر |
| Weekday header (AR) | أحد اثنين ثلاثاء أربعاء خميس جمعة سبت (article-less, 13 px) |
| Time | AR `9:00 م` / `9:00 ص`, EN `9:00 PM`; always Asia/Kuwait; "بتوقيت الكويت" / "Kuwait time" only when the device zone differs |
| Weekend and peak | Weeks start Sunday. Pricing weekday = Sun-Wed; weekend tier = Thu, Fri, Sat; the visual Thu-Sat peak band sits at the inline-end edge |
| Business day | 06:00 to 06:00 next day; a 19:30-01:00 wedding belongs to its start date |
| Hijri | A muted line in Arabic summaries only (`6 شعبان 1448 هـ`) and approximate occasion markers `تقريبي` / "approx." until announced |
| Occasions (seed) | Isra and Miraj الإسراء والمعراج Tue 5 Jan 2027 · Ramadan 1448 رمضان from Mon 8 Feb 2027 · National Day اليوم الوطني Thu 25 Feb · Liberation Day يوم التحرير Fri 26 Feb · Eid al-Fitr عيد الفطر about Tue 9-Thu 11 Mar · Eid al-Adha عيد الأضحى about Sun 16-Wed 19 May · Islamic New Year about Sun 6 Jun · Ashura عاشوراء about Tue 15 Jun (quiet marker, no commentary) |
| Relative words | Only اليوم / Today and غدًا / Tomorrow; countdown in whole days (`باقي 63 يومًا`) |

## 8. Numbers, money and plurals (ADR 0010)

| Term | Rule |
|---|---|
| Digits | Western 0-9 in both languages; comma thousands, dot decimals; Eastern digits only through the Arabic-only Settings row الأرقام |
| Currency | AR `18,200 د.ك`, EN `KD 18,200`; the currency sits visually left of the number; `KWD` only on invoices, receipts, bank and payout settings, the gateway and the API |
| Precision | Browse: whole dinars when fils are zero, else exactly three decimals. Booking, deposit, balance, payment, refund, invoice, hotel booking detail and revenue: always three decimals (`18,200.000`) |
| Units | A price always states its unit: `46 د.ك للضيف` / `KD 46 per guest`; `2,800 د.ك لليلة`; `رسوم الإيجار 100 د.ك`; estimate `من 16,100 د.ك لعدد 350 ضيفًا`. A bare "From KD X" is forbidden |
| Fils | 1,000 fils = KD 1; integer `amount_fils` everywhere; never shown in the UI |
| Phone | `+965 5000 0012` (4+4, LTR isolate); fixtures are display-only and never tappable |

**Arabic plural categories (CLDR; ADR 0013 D7).** They follow CLDR on the last two digits, not on magnitude: `zero` n = 0; `one` n = 1; `two` n = 2; `few` n mod 100 in 3-10; `many` n mod 100 in 11-99; `other` everything else (100, 101, 102, 200, 300, 400, 1,000). So 103 is few and 111 is many, **350 and 650 are many** (`350 ضيفًا`) while **300 and 400 are other** (`300 ضيف`). The hero booking's 350 guests therefore reads `350 ضيفًا`. Zero is written `لا {plural}`. After a preposition the dual becomes -ين (`خلال يومين`, `لمدة ساعتين`) and is written as an explicit variant.

| Noun | one | two | few | many | other |
|---|---|---|---|---|---|
| ضيف guest | ضيف واحد | ضيفان | {n} ضيوف | {n} ضيفًا | {n} ضيف |
| يوم day | يوم واحد | يومان | {n} أيام | {n} يومًا | {n} يوم |
| قاعة hall | قاعة واحدة | قاعتان | {n} قاعات | {n} قاعة | {n} قاعة |
| طلب request | طلب واحد | طلبان | {n} طلبات | {n} طلبًا | {n} طلب |
| حجز booking | حجز واحد | حجزان | {n} حجوزات | {n} حجزًا | {n} حجز |
| ساعة hour | ساعة واحدة | ساعتان | {n} ساعات | {n} ساعة | {n} ساعة |

## 9. Do not use

| Banned | Use instead | Why |
|---|---|---|
| ليلة الخميس / ليلة الجمعة (and "ليلة" before any weekday) | `مساء الخميس 14 يناير` | Idiom trap: ليلة الجمعة means Thursday night |
| بالرفاء والبنين | الله يبارك لكم · مبروك مقدمًا | Dated and gender-biased |
| حيّاك الله; honorifics (سمو, الشيخ) | أهلاً وسهلاً | Masculine; no honorifics anywhere |
| حريمي | الحفل النسائي | Register; search alias only |
| اختر / اختاري | verbal nouns (اختيار التاريخ) | Gendered imperatives |
| مدعو / مدعوات | ضيف / ضيوف | Gendered; search alias only |
| عزيزي العميل | possessive كم (طلبكم) | Impersonal and gendered |
| شنو, وين, شلون, زين, الحين, جذي, تبي in labels | modern Arabic | Dialect only in staff-typed chat |
| Religious phrases in payment, error, legal or discount copy | plain outcome-first sentence | ADR 0013 D5 |
| "Book now" | "Request to book" (or "Pay deposit KD {amount}" for instant halls) | Nothing is booked on send |
| "Rejected" in client UI | "Not accepted" / لم يُقبل الطلب | Gentle and subject-neutral (a feminine verb tied to "the hall" misfires for a hotel), ADR 0013 D4 |
| "Welcome back", "Oops", "Hurry", "Only N left", "Don't miss out", "dream wedding" | calm, precise sentences | Brief anti-patterns |
| "No booking fee", "Installments (soon)", "Couples' choice", "Most booked" | omit | Not true or not decided (OQ-B-15; CA-PAY-09; ADR 0018 D2) |
| Silver / Gold / Royal for venue packages | any other name | Reserved for planner tiers; the editor rejects it |
| Exclamation marks, emoji, urgency or scarcity words, lorem ipsum, real brands or phone numbers | n/a | `docs/design/content-guidelines.md` |

Also: one celebratory line per flow, at confirmation (`مبروك مقدمًا، تم تأكيد حجزكم.`). Arabic punctuation (، ؛ ؟ and « »); no tatweel, no tashkeel except the fathatan and shadda inside glossary words; Latin brand names are transliterated in the Arabic UI.

## 10. Search aliases (never shown)

قاعة = صالة = قصر = ديوانية (men's) · فندق = هوتيل · نسائي = حريمي = ladies = women · رجالي = رجال = men · كوشة = كوشه = منصة · عروس = bride · ضيوف = مدعوين = معازيم. Areas: Mishref = مشرف / Mishrif / Meshref · Bneid Al-Qar = بنيد القار / Bnaid Al-Gar · Salmiya = السالمية / Salmiyah · Messila = المسيلة / Mesilah. Normalisation for matching only: strip tashkeel and tatweel; unify أ إ آ to ا, ى to ي, optional ة to ه; optional ال; Eastern to Western digits; fold Latin case.

## 11. Timers and thresholds (single source: ADR 0001 D6, ADR 0005, ADR 0006)

| Term | Value |
|---|---|
| Venue response window (SLA) | 24 h default; venue picks 12, 24 or 48 h; hard maximum 48 h; forced 4 h and flagged Urgent when the event is 14 days away or less |
| Pay window after approval | 24 h default; 12, 24, 48 or 72 h; forced 6 h when the event is 14 days away or less |
| Instant hold | 10 minutes (+5 minutes grace only while a gateway session is open) |
| Counter-offer / venue-proposed reschedule | 48 h / 72 h |
| Late-payment rescue | 60 minutes |
| SLA escalation | push at 50%, WhatsApp to manager and reception at 80%, expire at 100% |
| Client pay-window reminders | -12 h and -3 h (WhatsApp), -1 h |
| Open unpaid bookings per wedding file | 3 (`requested` plus `awaiting_deposit`) |
| Accept Undo | 8 seconds; the client is told only after it |
| Cooling-off | 48 h after paying, event 30 days or more away |
| Balance due / guest-count lock | T-14 (venue 7-30) / T-7 (venue 3-14) |
| Completed / no-show flag / issue report | event end + 12 h / within 24 h / 72 h after completion |

## 11b. Voucher model terms (ADR 0033)

| English | Arabic | Meaning | Notes |
|---|---|---|---|
| Voucher | كوبون | The KD 2 voucher (coupon) Ghazal sells; makes the client eligible to request at the voucher price; one code and QR, single-use, bound to one venue or provider and quote | Never «قسيمة» in Arabic UI copy: in Kuwait it also means a land plot (OQ-V-15). The older glossary row "Coupon / Platform credit" is superseded |
| Voucher price / Standard price | سعر الكوبون / السعر العادي | The two prices of every package: what the client pays the venue with a voucher, and without | Both with the same unit and guest basis |
| You save | وفّروا | Standard total minus voucher total, shown on cards, details and the request summary; the headline chip nets the KD 2 | Offered only when the saving beats the voucher fee |
| Request | طلب | A booking request at the voucher price (table `bookings`); product copy says request until it is confirmed | Eight statuses: Pending, Approved, Confirmed, Voucher redeemed, Not accepted, Expired, Cancelled, Completed |
| Confirm booking | تأكيد الحجز | The client's official confirmation, required within 24 hours of the venue's approval | The 24 hour window is fixed |
| Redeem / Redeemed | استخدام الكوبون / تم استخدام الكوبون | The partner scans the QR or types the code and marks the voucher used | Admin, Manager, Reception |
| Reusable until | قابل للاستخدام حتى | The 60-day reuse window of a released voucher at the same venue | Configuration (OQ-V-02) |
| Visit / Book a visit | زيارة / احجزوا زيارة | A free site visit to a hotel or hall with a three-way group chat | Not for governmental facilities |
| Hotel representative / Ghazal support | ممثل الفندق / دعم غزل | Two of the three roles of a visit chat (the third is the client) | Role chips, monogram avatars |
| Partner app | تطبيق الشركاء | The former hotel app; account types Hotel or wedding hall, and Service provider | |
| Hotel or wedding hall / Service provider | فندق أو قاعة أفراح / مقدّم خدمة | The two partner account types | |
| Listing | إعلان | A service provider's (or hotel's) advertised offer, reviewed before it goes live | Lifecycle in voucher-model section 9.2 |
| Plan (Weekly, Monthly, Annual) | باقة (أسبوعية، شهرية، سنوية) | The paid advertising plan of a listing | Rates undecided: "Rates announced soon" / «الأسعار تُعلن قريبًا» |
| Major hotel | فندق رئيسي | A partner flagged `fee_exempt` by Ghazal: no listing fees, still reviewed | Never shown to clients |
| Governmental facility | منشأة حكومية | Venue type with official fees; browse-only | Replaces "Government hall" in filters |
| Additional services | الخدمات الإضافية | The client section for post-venue needs: five primary categories then secondary ones | |

## 12. Project shorthand

**ADR** architecture decision record (`docs/decisions/`) · **OQ-x-nn** open question (B booking, L localisation, T technical, P product) · **CF-nn** conflicts-register entry · **MVP-P1 / MVP-P2** phase labels in the matrix · **core / supporting** screen priority; **P0 spine** the wired prototype path · **Needs you** hotel queue ranked by nearest deadline · **Booking Thread** the shared timeline component (Request, Approval, Deposit, Balance, Day), an internal design term with no Arabic label · **fils** thousandth of a dinar · **LTR isolate** bidi-safe wrapper for numbers and codes · **KYC** payout verification of a venue with the gateway · **ARB** Flutter localisation file · **ICU** message format and plural rules.
