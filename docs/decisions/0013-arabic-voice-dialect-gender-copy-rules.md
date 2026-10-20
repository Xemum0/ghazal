# ADR 0013: Arabic voice: clear modern Arabic with Gulf warmth, gender-neutral, written not translated

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-10-12 |
| Scope | Every user-facing string in both apps, the web prototype, push, WhatsApp, email and PDFs; the i18n lint; venue-authored content rules |
| Owner confirmation still needed | OQ-L-06 (name a native Kuwaiti copy reviewer before visual freeze; approve the glossary overrides and the zero-exclamation rule), OQ-L-16 (venue content in both languages) |
| Related ADRs | 0003 (owns the states; this ADR owns the words), 0010 (numbers in copy), 0011 (date idioms), 0014 (bidi), 0016 (Arabic type rules), 0018 (card labels), 0022 (ARB pipeline) |

## Context

Copywriting is excluded from the PRD's development scope (NF-EXC-01), yet every screen needs Arabic that is written, not translated. Research found:

- About 68-70% of Kuwait's residents are non-Kuwaiti and many read Arabic as a second language; dialect orthography has no standard (ج/ي variants); screen readers and text-to-speech need standard forms; legal and payment text must be clear.
- The primary user may be the bride, her mother or the groom, so gendered imperatives (`اختر / اختاري`) would misfire. The honorific plural possessive `كم` is respectful, natural for couples and families, and gender-neutral; verbal-noun CTAs avoid the imperative problem altogether.
- Idioms bite: ليلة الجمعة means Thursday night; بالرفاء والبنين is dated and gender-biased; حيّاك الله is masculine; honorifics (سمو / الشيخ) are unsafe.
- Arabic plurals have six CLDR categories assigned by the last two digits (zero n=0, one n=1, two n=2, few n mod 100 in 3-10, many n mod 100 in 11-99, other for everything else: 100, 101, 102, 200, 300, 400); 103 is few, 111 is many, 350 and 650 are many. The dual changes to `-ين` after a preposition, which ICU cannot express.
- The research glossary used مدعو / المدعوّون for guests and wrote tanween as `مقدماً`; both are replaced here (gendered form; hand-written strings must match ICU-generated plurals).
- Competitive honesty rules apply to tone: no urgency counters, no scarcity pressure.
- Hotel staff are multinational; language is a per-user setting.

## Decision

**1. Register.** Structure, labels, buttons, legal, payment and error text are simplified Modern Standard Arabic. Light Khaleeji is allowed only in warm moments: welcome, success, push, empty states and staff-written chat. Safe set: هلا، يا هلا والله، ما قصّرتوا، تفضلوا، على راحتكم، مبروك مقدمًا، الله يبارك لكم. Dialect words never appear in labels or buttons: شنو، وين، شلون، زين، الحين، جذي، تبي (they are fine in chat messages typed by humans).

**2. Address and gender.** System strings use the honorific plural possessive `كم` (طلبكم، حجزكم، موعدكم، زفافكم، حسابكم). CTAs are verbal nouns or noun phrases (متابعة، إرسال الطلب، تأكيد الحجز، اختيار التاريخ، مقارنة، حفظ في المفضلة); no `اختر / اختاري`. Plural imperatives (جرّبوا، راجعوا، ثبّتوا) are allowed in notifications and empty states only. If onboarding records bride or groom (CA-ONB-07), gendered forms may be used only where a pronoun is unavoidable, with a neutral fallback. No `حيّاك الله`, no honorifics (سمو / الشيخ); `الأخ / الأخت` only in staff chat greetings. Greeting without pronoun: `أهلاً وسهلاً`, with first name `أهلاً وسهلاً، ريم` (EN `Hello, Reem`), once on the Home header at most; never 'welcome back'.

**3. Glossary.** The glossary in `docs/research/kuwait-localization.md` section 3.3 is canonical (الحفل النسائي، الحفل الرجالي، مختلط، جناح العروس، غرفة العريس، الكوشة، الزفّة، العربون، المبلغ المتبقي، الباقة، الإضافات، متاح / محجوز / غير متاح، حجز فوري، المفضلة، تنسيق الأعراس، الفضية / الذهبية / الملكية; hotel tabs اليوم / الحجوزات / التقويم / الرسائل / المزيد; قبول / اعتذار / تغيير الموعد; تواريخ مغلقة). Synonyms (صالة، حريمي، العرس) are search aliases only. Overrides decided here:

| Override | Rule |
|---|---|
| (a) Guests | `ضيف / ضيوف` everywhere (`عدد الضيوف`, `للضيف`); `مدعو / مدعوات` are banned in UI (gendered) and kept as search aliases |
| (b) Tanween | Written in the ICU form with the fathatan before the alef (يومًا، مقدمًا، ضيفًا) so hand-written strings match generated plurals |
| (c) Rejected | Client-facing 'Rejected' is `لم يُقبل الطلب` (subject-neutral: the earlier `اعتذرت القاعة` was a feminine verb tied to the noun 'hall' and misfired for hotels); the hotel button is `اعتذار` |

**4. Status chips (the one place the EN and AR chip words are settled; ADR 0003 D2 quotes this list)** (icon plus label, never colour alone): `بانتظار الرد` / Pending; `تمت الموافقة · بانتظار العربون` / Approved, deposit due; `مؤكد` / Confirmed; `لم يُقبل الطلب` / Not accepted; `انتهت المهلة` / Expired (hotel side, venue silence: `انتهت مهلة الرد` / Missed); `ملغي` / Cancelled; `مكتمل` / Completed; `تم الاسترداد` / Refunded. The booking state-machine ADR owns the states; this ADR owns only the words.

**5. Message anatomy.** Outcome first, money status second, next step third, passive and calm: `تعذّر إتمام الدفع. لم يُخصم أي مبلغ.` / The payment could not be completed. No amount was charged. No exclamation marks in either language, no emoji, no urgency words (Hurry, Only N left, Don't miss out), no blaming the user. Religious phrases never appear in payment, error, legal or discount copy; `إن شاء الله` only in warm, non-contractual moments; `بالرفاء والبنين` is banned (dated, gender-biased) in favour of `الله يبارك لكم` or `مبروك مقدمًا`. One celebratory line per flow, at confirmation: `مبروك مقدمًا، تم تأكيد حجزكم.`

**6. Punctuation and script.** Arabic punctuation (، ؛ ؟ and « »); the Latin comma only inside numbers; NBSP between a number and its unit; no tatweel; no tashkeel except the fathatan above and the shadda inside glossary words (الزفّة، مصوّرة، منسّقة). Latin brand names are replaced by their Arabic transliteration in the Arabic UI (`فندق أوريليا الخليج`); any remaining Latin run is isolated and never ends a sentence. Brand: wordmark `غزل` in the Arabic UI, `Ghazal` in the English UI. Venue names show the Arabic name in the Arabic UI and the English name in the English UI.

**7. Plurals (amended 2026-10-12 to the CLDR rule; the earlier 'other = 100+' wording contradicted its own 103/111 examples).** ICU categories by the last two digits: zero n = 0, one n = 1, two n = 2, few n mod 100 in 3-10, many n mod 100 in 11-99, other = everything else (100, 101, 102, 200, 300, 400). So 350 and 650 render `ضيفًا` (many) while 300 and 400 render `ضيف` (other). The native reviewer confirms (OQ-L-06). Every plural message supplies one, two, few, many and other, zero as `لا {plural}`. The dual after a preposition changes to `-ين` (`خلال يومين`), so those strings are explicit variants. Prefer the `label: value` pattern (`عدد الضيوف: 350`) wherever a count is not the headline.

Example (the same string runs in Flutter gen-l10n and in the prototype via intl-messageformat 12):

```json
"guestsCount": "{count, plural, =0{لا ضيوف} =1{ضيف واحد} =2{ضيفان} few{{count} ضيوف} many{{count} ضيفًا} other{{count} ضيف}}"
```

which renders as:

| count | output |
|---|---|
| 0 | لا ضيوف |
| 1 | ضيف واحد |
| 2 | ضيفان |
| 3 | 3 ضيوف |
| 11 | 11 ضيفًا |
| 100 | 100 ضيف |
| 350 | 350 ضيفًا |
| 400 | 400 ضيف |
| 103 | 103 ضيوف |

**8. English voice.** British spelling, second person, sentence case, warm, precise, calm: `Your request is with the venue. Venues usually reply within 24 hours.` Currency `KD`, dates per ADR 0011.

**9. Authoring and checks.** Copy is authored natively in each language, never machine-translated, never mirrored word for word. Keys are camelCase `<feature><Screen><Element>`. CI i18n lint: identical key and placeholder sets, all Arabic plural categories present, no Latin letters in Arabic strings outside an allow-list (KD, KWD, brand names, codes), no literal digits in prose, warn when the Arabic string is more than 1.6 times the English length. Compare-table cells budget 14 characters in English and 12 in Arabic (ADR 0009 D7). Every Arabic string gets a native Kuwaiti reader before visual freeze (OQ-L-06).

**10. Venue-authored content** (PL-CORE-08, HA-VMGT-09). Both languages are required before a venue publishes; the hotel app shows per-language completeness; the product never silently machine-translates. If a language is missing the client sees the available language with a quiet language chip.

**11. Sponsored placements** are labelled `إعلان` / `Sponsored` (MK-SUB-04); the Arabic word goes through the same native review.

## Consequences

- One voice across both apps; gendered-verb and idiom errors are removed at the source; strings survive TTS and screen readers because they are standard Arabic. The lint turns most of this into CI failures instead of review comments.
- Two documented departures from the research glossary (ضيف, tanween form) and one from competitive copy (no exclamation marks) must be applied by every copy author. The research microcopy bank in `kuwait-localization.md` section 3.4 still shows the old forms (`مقدماً`, `مدعواً`, `ألف مبروك`); apply this ADR when reusing it.
- Native review is a scheduling dependency before design freeze; the owner must name the reviewer (OQ-L-06).
- Server-originated channels (push, WhatsApp, email, PDF) are rendered server-side in the user's saved locale from `packages/i18n/messages/server` (NF-LOC-07, ADR 0020).
- Arabic strings routinely run longer than English; layouts are fluid (ADR 0016 item 8) and the lint only warns above 1.6 times the English length.
- The ARB pipeline (per-feature parts merged into app ARBs, ADR 0022 E) carries the plural and parity checks.
- Chat messages typed by staff may use dialect; system strings never do.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Khaleeji dialect throughout | No standard spelling; excludes second-language readers; breaks TTS and legal clarity |
| Plain MSA with no warmth | Cold for a wedding product; light Khaleeji is allowed in welcome, success, push, empty states and staff chat |
| Gendered imperatives (`اختر / اختاري`) after asking gender | Extra onboarding friction; the user may be the mother or a planner; `كم` plus verbal nouns solve it |
| `مدعو / مدعوات` for guests | Gendered; `ضيف / ضيوف` is neutral |
| `مقدماً` spelling (alef then tanween) | Hand-written strings must match ICU-generated plurals; fathatan before the alef |
| 'Rejected' as `مرفوض` or `غير مقبول` on the client; `اعتذرت القاعة` | Harsh, or gendered to 'hall'; `لم يُقبل الطلب` is neutral and calm (OQ-B-21, OQ-L-06 confirm) |
| Exclamation marks and a 'مبروك' on every success | One celebratory line per flow, at confirmation |
| Machine translation of venue content | Quality and cultural risk; both languages required before publish |
| Urgency copy ('Hurry', 'Only N left') | Honesty rules; CMA-style enforcement risk |
| Latin brand names inside Arabic UI | Bidi breakage and tone; Arabic transliteration with an isolated Latin run when unavoidable |

## Related requirement IDs

| ID | Effect |
|---|---|
| NF-LOC-01, NF-LOC-06, NF-LOC-07 | Both languages first-class; runtime switch; server-originated content in both languages |
| CA-ONB-02, CA-PROF-07 | Language choice and switch |
| CA-ONB-07 | Bride or groom role; neutral fallback |
| CA-STAT-01..10, CA-NOTI-02, CA-NOTI-07 | Status chips and notification wording |
| PL-CORE-08, HA-VMGT-09 | Venue-authored content in both languages |
| MK-SUB-04 | 'Sponsored' label |
| NF-EXC-01 | Copywriting excluded from dev scope; owner names a reviewer |
