# Seed rulebook (fixtures for both apps)

> The one place the definition of done, the glossary and the persona docs mean when they say "the seed rulebook". It is extracted from `docs/research/kuwait-localization.md` sections 7 and 8 (raw input, which loses to ADRs) and reconciled with the ADRs and the screen JSON on 2026-10-12. Where a value here differs from the research file, this page is right. Everything is fictional. Destination later: `packages/contracts/fixtures/` (one file feeds the prototype and the Flutter tests).

## 1. Clock and shared story

| Fact | Value |
|---|---|
| NOW | Thu 12 Nov 2026, 4:00 PM, Asia/Kuwait, fixed |
| Client persona | `ريم الدوسري` Reem Al-Dosari (monogram `ر`), wedding Thu 14 Jan 2027 (63 days), venue-and-catering budget KD 20,000 - 35,000 (the Brief budget, ADR 0007 D3), ladies about 350, men about 400, areas Salmiya and Sharq |
| Booking | Aurelia Gulf Hotel (V01), Danah Ballroom, ladies' reception, Evening, 350 guests, weekend rate KD 52 per guest |
| Reference | `GZ-2611-0147` everywhere (client, hotel, API fixtures) |
| Money | 350 x 52 = 18,200.000; deposit 30% = 5,460.000 (already a multiple of KD 5, so the round-up leaves it unchanged); balance 12,740.000 due Thu 31 Dec 2026 |
| Approval at NOW | the venue accepts at 4:00 PM, so the client sees `Pay by Fri 13 Nov, 4:00 PM` (24 h pay window); Haya Al-Mutairi's hold expires 7:30 PM (a different booking) |
| Venue reply | Reem's message was sent 3:12 PM and is unanswered at NOW (48 min); the venue's reply exists only as the hotel's draft and appears in the client thread after the hotel sends it |
| Venue hours | Sun - Thu 9:00 AM - 10:00 PM; Fri and Sat 4:00 PM - 1:00 AM |
| Danah Ballroom Evening | 9:00 PM - 2:00 AM, cut-off 2:00 AM; Majlis Hall Evening 8:30 PM - 1:00 AM |
| Hall capacities | Danah Ballroom 650, Majlis Hall 450 (both fit every fixture request) |
| Phones | `+965 5000 00NN`: `0001` Ghazal Support, `0002` Aurelia Gulf Hotel, `0012` Reem Al-Dosari; one number per party |
| Pending requests at the hotel (nearest deadline first) | Dana Al-Shammari (Sun 17 Jan, Majlis, 250, 11,500.000), Abdullah Al-Hajri (Fri 5 Feb, full night, 34,160.000), Maryam Al-Kandari (Thu 28 Jan, 300, 15,600.000), Faisal Al-Rasheedi (Fri 22 Jan, men, 400, 12,800.000), Reem (Thu 14 Jan, 18,200.000). No second request exists for any date, so there is no competing-request row in the base seed |
| Offer demo | flash sale on the open soft dates Thu 3 Dec and Sat 5 Dec; the block-dates demo uses Thu 24 Dec - Sat 26 Dec |

## 2. Naming

Hotels: brand-style name plus descriptor (`فندق أوريليا الخليج` / Aurelia Gulf Hotel). Ballrooms: Kuwaiti heritage nouns (`قاعة الدانة` Danah Ballroom, `قاعة المجلس` Majlis Hall). Independent halls: `قصر X للأفراح`, `قاعة X الكبرى`, `مركز X للمؤتمرات والأفراح`. Government: `قاعة الأفراح الحكومية، {area}`. English uses `Al-` and capitals; about 24 characters on a card (two lines, then truncate); no real brands, royal names, mosque names or religious words. Luxury levels: `فاخر` Prestige, `راقٍ` Signature, `كلاسيكي` Classic, `قاعة حكومية` Government. Silver, Gold and Royal belong to planner tiers.

## 3. Tier price ranges (KD)

| Tier | Ladies per guest | Men per guest | Min guests | Hall capacity |
|---|---|---|---|---|
| Prestige | 44 - 55 (resort setup flat 1,500; villa flat 4,200 - 4,800 per night) | 30 - 38 | 150 - 300 | 300 - 800 (villa 220) |
| Signature | 27 - 38 | 20 - 28 | 200 - 300 | 400 - 1,200 |
| Classic | 20 - 27, or hall-only flat 1,400 - 2,800 (weekday lower) | 15 - 22 | 250 - 300 | 450 - 900 |
| Government | flat 100 | same | n/a | 400 - 500, venue only |

Default deposit 30%, balance 14 days before the event; outdoor and beach venues are winter only (Nov - Mar).

## 4. Venue roster (21; Hawalli heaviest)

| ID | Name (EN / AR) | Tier, type | Area (governorate) | Halls (capacity) | Rating (n) |
|---|---|---|---|---|---|
| V01 | Aurelia Gulf Hotel / فندق أوريليا الخليج | Prestige, 5-star hotel | Sharq (Capital) | Danah Ballroom 650; Majlis Hall 450 | 4.8 (212) |
| V02 | Madar Grand Hotel / فندق مدار جراند | Prestige, 5-star hotel | Bneid Al-Qar (Capital) | Qamar 800; Nujoum 400 | 4.7 (167) |
| V03 | Nawar Beach Resort / منتجع نوّار الشاطئي | Prestige, resort | Messila (Mubarak Al-Kabeer) | Seaview 300; Lawn Terrace 450 outdoor | 4.9 (96) |
| V04 | Bayan Villa Estate / فيلا بيان الخاصة | Prestige, villa | Bayan (Hawalli) | Garden 160 + Majlis 60 | 4.9 (41) |
| V05 | Lumi Marina Hotel / فندق لومي مارينا | Signature, 4-star hotel | Salmiya (Hawalli) | Marina Hall 500; Terrace Room 180 | 4.5 (138) |
| V06 | Rawnaq Events Hotel / فندق رونق للمناسبات | Signature, 4-star hotel | Shuwaikh (Capital) | Hall 600; Hall 300 | 4.4 (89) |
| V07 | Jawharat Al-Salmiya Palace / قصر جوهرة السالمية للأفراح | Signature, hall | Salmiya (Hawalli) | Ladies 700; Men 500 | 4.6 (224) |
| V08 | Wasl Convention and Wedding Centre / مركز وصل للمؤتمرات والأفراح | Signature, convention | Mishref (Hawalli) | Grand 1,200; A 600; B 450; Men's Majlis 500 | 4.3 (158) |
| V09 | Qasr Al-Nakheel / قصر النخيل للأفراح | Signature, hall | Jabriya (Hawalli) | Ladies 550; Men 400 | 4.6 (131) |
| V10 | Qurain Grand Hall / قاعة القرين الكبرى للأفراح | Classic, hall | Qurain (Mubarak Al-Kabeer) | Ladies 800; Men 600 | 4.2 (73) |
| V11 | Mahboula Crown Hall / قاعة التاج للأفراح | Classic, hall | Mahboula (Ahmadi) | Ladies 650; Men 450 | 4.3 (64) |
| V12 | Khiran Lagoon Estate / عزبة اللاجون | Signature, outdoor | Khiran (Ahmadi) | Outdoor 300; indoor majlis 120 | 4.7 (38) |
| V13 | Fintas Sea Pavilion / جناح البحر للمناسبات | Signature, outdoor-mixed | Fintas (Ahmadi) | Pavilion 350 | 4.4 (52) |
| V14 | Khaitan Orchard Hall / قاعة بستان خيطان | Classic, hall | Khaitan (Farwaniya) | Ladies 700; Men 700 | 4.1 (117) |
| V15 | Rai Grand Ballroom / قاعة الري الكبرى | Classic, hall | Al-Rai (Farwaniya) | Hall 900 | 4.0 (45) |
| V16 | Jleeb Family Hall / قاعة العائلة، جليب الشيوخ | Classic, hall | Jleeb Al-Shuyoukh (Farwaniya) | Hall 450 | 3.9 (29) |
| V17 | Taima Grand Palace / قصر تيماء الكبير | Classic, hall | Taima (Jahra) | Ladies 750; Men 500 | 4.2 (86) |
| V18 | Oyoun Garden Hall / قاعة حدائق العيون | Classic, garden | Oyoun (Jahra) | Garden 400 | 4.0 (22) |
| V19 | Government Wedding Hall, Hateen / قاعة الأفراح الحكومية، حطين | Government | Hateen (Hawalli) | 400, venue only | no reviews |
| V20 | Government Wedding Hall, Sabah Al-Salem / قاعة الأفراح الحكومية، صباح السالم | Government | Sabah Al-Salem (Mubarak Al-Kabeer) | 500, venue only | no reviews |
| V21 | Salwa Pearl Hall / قاعة لؤلؤة سلوى | Classic, hall | Salwa (Hawalli) | Hall 500 | 4.1 (57) |

Prices per venue (ladies weekday / weekend, men, minimums, flat fees) are in `docs/research/kuwait-localization.md` section 8.3; V01 is: ladies weekday 46, weekend 52, minimum 300 (Danah) and 200 (Majlis); men 32, minimum 300. Demo stage totals: V01 ladies weekday 350 x 46 = 16,100.000; V01 men 400 x 32 = 12,800.000; V05 ladies weekend 300 x 38 = 11,400.000; V08 ladies weekday 400 x 27 = 10,800.000; V14 ladies weekend 400 x 23 = 9,200.000.

## 5. Areas

Six governorates (Capital, Hawalli, Farwaniya, Ahmadi, Jahra, Mubarak Al-Kabeer); the picker groups by governorate and is searchable; the full area list with Arabic and English is `docs/research/kuwait-localization.md` section 7 (verified there; Salmiya, Mishref, Jabriya, Bayan and Salwa are in Hawalli, Fintas and Khiran in Ahmadi, Messila and Funaitees in Mubarak Al-Kabeer). Use only areas from that list.

## 6. Package archetypes

`الحفل النسائي · أيام الأسبوع` Ladies' Reception, Weekday (Sun - Wed); `الحفل النسائي · نهاية الأسبوع` Ladies' Reception, Weekend (Thu - Sat); `الحفل النسائي المتكامل` Ladies' Signature Evening; `الحفل الرجالي` Men's Reception; `غداء الرجال` Men's Lunch; `ليلة الزفاف المتكاملة` Full-Night Package; `إيجار القاعة فقط` Hall Only; `ليلة الفيلا` Villa Night; `رسوم الإيجار الحكومية` Government Rental Fee. Extras ranges, vendor price anchors and planner tiers (Silver 650, Gold 1,900, Royal 5,500 KD from-prices; the 25% deposit is a proposal, OQ-P-19) are in the research file sections 8.4 to 8.6.

## 7. Rules for any new fixture

One value per fact, written once here or in the fixtures file and quoted everywhere; money reconciles (guests x unit price = total; deposit per ADR 0005 D1; balance = total - deposit); dates carry a correct weekday; Arabic plurals follow the CLDR rule; phones are patterned and unique per party; no real people, brands or numbers. Content rules: [content-guidelines.md](content-guidelines.md).
