// Text-diet gallery: the icon-led components of ADR 0034 in both languages (docs/design/02-text-diet.md). FactChip and FactRow, IconStat,
// StatusIcon, IconListRow, IconProgress and the Booking Thread, IconTabs and IconSegmented (also under a scaled phone), InfoButton and
// InfoSheet, the empty, success and error states, the onboarding slide, and the trimmed voucher, price, request and KPI components.
// Rendered at #/gallery/diet?lang=en|ar. Optional `&only=facts,stats,status,rows,progress,tabs,info,states,onboarding,voucher,request`.
// Specimen annotations are design-tool text (hand-written bilingual); every figure comes from the formatter or the fixtures.
import { useState, type ReactNode } from 'react'
import { engine, heroVoucherAs, meta, PROTOTYPE_TODAY, requestsFor } from '../mock'
import { useFormat } from '../i18n'
import { useLang } from '../shell/lang'
import { useRoute } from '../shell/router'
import {
  BookingThread, Button, EmptyState, ErrorState, FactChip, FactRow, IconListRow, IconProgress, IconSegmented, IconStat, IconTabs, InfoButton,
  KpiTile, OnboardingSlide, PriceCompare, RequestCard, Sheet, StatusIcon, StatusPill, SuccessState, VoucherCard, VoucherChip, useDuration,
  type StatusKey,
} from '../system'
import './diet.css'

function Sec({ id, title, note, children }: { id: string; title: string; note?: string; children: ReactNode }) {
  const only = useRoute().params.get('only')?.split(',').filter(Boolean)
  if (only && !only.some(o => id === o || id.startsWith(`${o}-`))) return null
  return (
    <section className="dg-sec" data-gz-section={id}>
      <div className="dg-sec__head">
        <h2 className="gz-t-d2">{title}</h2>
        {note ? <p className="gz-t-body-s dg-note">{note}</p> : null}
      </div>
      <div className="dg-stack">{children}</div>
    </section>
  )
}

function Spec({ cap, children, kind = 'plain' }: { cap: string; children: ReactNode; kind?: 'plain' | 'panel' | 'ink' | 'state' }) {
  return (
    <figure className="dg-spec">
      <figcaption className="gz-t-caption dg-cap">{cap}</figcaption>
      <div className={`dg-body${kind !== 'plain' ? ` dg-body--${kind}` : ''}${kind === 'ink' ? ' gz-on-dark' : ''}`}>{children}</div>
    </figure>
  )
}

const STATUSES: StatusKey[] = [
  'pending', 'approved', 'confirmed', 'redeemed', 'declined', 'expired', 'date_proposed',
  'voucher_unpaid', 'voucher_active', 'voucher_bound', 'voucher_used', 'voucher_forfeited', 'voucher_credit',
  'visit_requested', 'visit_confirmed', 'visit_completed', 'listing_review', 'listing_active', 'available', 'held', 'booked',
]

export default function DietGallery() {
  const { lang } = useLang()
  const f = useFormat()
  const L = (en: string, ar: string) => (lang === 'ar' ? ar : en)
  const only = useRoute().params.get('only')
  const [tab, setTab] = useState('days')
  const [seg, setSeg] = useState('prices')
  const hero = heroVoucherAs('pending')
  const reqs = requestsFor(meta.hotelVenueId)
  const request = reqs.find(r => r.booking.id === 'bk-GZ-2611-0147') ?? reqs[0]!
  const duration = useDuration()
  const hours = (n: number) => duration(n * 3_600_000)

  return (
    <div className="dg" data-gz="DietGallery">
      {only ? null : (
        <header className="dg-head">
          <p className="gz-t-label">{L('Design system', 'نظام التصميم')}</p>
          <h1 className="gz-t-d3">{L('Text diet', 'أقل نصًّا')}</h1>
          <p className="gz-t-body-s">
            {L(
              'Icons, figures and drawings carry the screens; a sentence is the exception and lives behind an info glyph. Every glyph keeps its word as an accessible name.',
              'الأيقونات والأرقام والرسوم تحمل الشاشات، والجملة استثناء تقيم خلف أيقونة المعلومات. كل أيقونة تحتفظ بكلمتها اسمًا لقارئ الشاشة.',
            )}
          </p>
        </header>
      )}

      <Sec id="facts" title={L('Facts', 'الحقائق')} note={L('An icon and a value, no label. The label is the accessible name.', 'أيقونة وقيمة بلا عنوان. العنوان هو الاسم الصوتي.')}>
        <Spec cap={L('FactRow · guests, area, session, rating, price', 'صف حقائق · الضيوف والمساحة والفترة والتقييم والسعر')}>
          <FactRow>
            <FactChip icon="users-three" label={L('Guests', 'الضيوف')} value={f.integer(350)} />
            <FactChip icon="ruler" label={L('Area', 'المساحة')} value={f.integer(1200)} unit="m²" />
            <FactChip icon="moon" label={L('Evening', 'مساءً')} />
            <FactChip icon="star" label={L('Rating', 'التقييم')} value={f.number(4.8, { maxFraction: 1 })} tone="accent" />
            <FactChip icon="coins" label={L('From', 'من')} value={f.money(4_200_000, { mode: 'browse' })} />
          </FactRow>
        </Spec>
        <Spec cap={L('Sections, time, distance, per guest', 'الأقسام والوقت والمسافة والسعر للضيف')}>
          <FactRow>
            <FactChip icon="section-women" label={L('Ladies', 'نسائي')} />
            <FactChip icon="section-men" label={L('Men', 'رجالي')} />
            <FactChip icon="section-mixed" label={L('Mixed', 'مختلط')} />
            <FactChip icon="sun" label={L('Day', 'نهارًا')} />
            <FactChip icon="timer" label={L('Time left', 'الوقت المتبقي')} value={hours(23)} />
            <FactChip icon="navigate" label={L('Distance', 'المسافة')} value={f.integer(3)} unit="km" />
            <FactChip icon="per-guest" label={L('Per guest', 'للضيف')} value={f.money(12_000, { mode: 'browse' })} />
          </FactRow>
        </Spec>
        <Spec cap={L('Small and muted · parking, valet, stage, buffet, music, camera', 'صغير وخافت · مواقف وفاليه ومسرح وبوفيه وموسيقى وتصوير')}>
          <FactRow>
            {(['parking', 'valet', 'stage', 'buffet', 'music', 'camera', 'lighting', 'makeup'] as const).map(i => (
              <FactChip key={i} icon={i} label={i} size="sm" tone="muted" />
            ))}
          </FactRow>
        </Spec>
      </Sec>

      <Sec id="stats" title={L('Icon stat', 'إحصاءة')} note={L('A big number with its icon. Delta is a trend glyph and a signed figure.', 'رقم كبير مع أيقونته. التغيّر سهم واتجاه ونسبة.')}>
        <Spec cap={L('Stack · tiles', 'عمودي · بلاطات')} kind="panel">
          <div className="dg-row dg-row--top">
            <IconStat icon="eye" label={L('Views', 'المشاهدات')} value={f.integer(1280)} delta={12} />
            <IconStat icon="ticket" label={L('Vouchers', 'الكوبونات')} value={f.integer(38)} delta={-3.5} />
            <IconStat icon="calendar-check" label={L('Booked', 'محجوز')} value={f.integer(14)} tone="accent" />
          </div>
        </Spec>
        <Spec cap={L('Inline · headers and rows', 'أفقي · رؤوس وصفوف')} kind="panel">
          <div className="dg-row">
            <IconStat layout="inline" icon="users-three" label={L('Guests', 'الضيوف')} value={f.integer(350)} />
            <IconStat layout="inline" icon="timer" label={L('Time left', 'الوقت المتبقي')} value={hours(23)} tone="accent" />
          </div>
        </Spec>
      </Sec>

      <Sec id="status" title={L('Status', 'الحالة')} note={L('Icon and one word; the icon alone only inside a row that names its subject.', 'أيقونة وكلمة واحدة؛ الأيقونة وحدها داخل صف يسمّي موضوعها.')}>
        <Spec cap={L('StatusPill · icon + one word', 'شارة الحالة · أيقونة وكلمة')}>
          <div className="dg-row">
            {STATUSES.map(s => (
              <StatusPill key={s} status={s} />
            ))}
            <StatusPill status="approved" hours={23} />
          </div>
        </Spec>
        <Spec cap={L('StatusIcon · 24 and 32, the word is the accessible name', 'أيقونة الحالة · 24 و32، الكلمة هي الاسم الصوتي')}>
          <div className="dg-grid">
            {STATUSES.map(s => (
              <span className="dg-cell" key={s}>
                <StatusIcon status={s} size="md" />
                <StatusIcon status={s} />
              </span>
            ))}
          </div>
        </Spec>
      </Sec>

      <Sec id="rows" title={L('List rows', 'صفوف القوائم')} note={L('A leading glyph or drawing, one line, a fact at the end. No subtitle.', 'أيقونة أو رسم في البداية وسطر واحد وحقيقة في النهاية. بلا عنوان فرعي.')}>
        <Spec cap={L('IconListRow · glyph, trailing fact, chevron', 'صف بأيقونة · حقيقة في النهاية وسهم')} kind="panel">
          <IconListRow icon="ticket" title={L('Vouchers', 'الكوبونات')} trailing={<FactChip icon="check" label={L('Ready', 'جاهز')} value={f.integer(2)} size="sm" />} chevron onClick={() => undefined} />
          <IconListRow icon="calendar" title={L('Visits', 'الزيارات')} trailing={<StatusIcon status="visit_confirmed" />} chevron onClick={() => undefined} />
          <IconListRow icon="chat" title={L('Messages', 'الرسائل')} trailing={<FactChip icon="bell" label={L('Unread', 'غير مقروءة')} value={f.integer(3)} size="sm" tone="accent" />} chevron onClick={() => undefined} />
          <IconListRow icon="settings" title={L('Settings', 'الإعدادات')} chevron onClick={() => undefined} last />
        </Spec>
        <Spec cap={L('With a drawing · partner tasks', 'مع رسم · مهام الشريك')} kind="panel">
          <IconListRow illustration="partner-scanner" title={L('Redeem', 'استخدام كوبون')} chevron onClick={() => undefined} />
          <IconListRow illustration="partner-calendar" title={L('Dates', 'التواريخ')} chevron onClick={() => undefined} />
          <IconListRow
            illustration="partner-review"
            title={L('Listing', 'الإعلان')}
            facts={
              <FactRow>
                <FactChip icon="clock" label={L('In review', 'قيد المراجعة')} value={hours(48)} size="sm" tone="muted" />
              </FactRow>
            }
            chevron
            onClick={() => undefined}
            last
          />
        </Spec>
      </Sec>

      <Sec id="progress" title={L('Thread', 'الخيط')} note={L('A glyph per knot; the word only under the active knot; the deadline is a timer and a time.', 'أيقونة لكل عقدة؛ الكلمة تحت العقدة النشطة فقط؛ والمهلة مؤقت ووقت.')}>
        <Spec cap={L('BookingThread · requested · approved (confirm window) · confirmed · redeemed', 'خيط الحجز · طلب · موافقة · تأكيد · استخدام')} kind="panel">
          <div className="dg-row dg-row--col">
            <BookingThread status="pending" draw={false} />
            <BookingThread status="approved" draw={false} />
            <BookingThread status="confirmed" draw={false} />
            <BookingThread status="redeemed" draw={false} />
          </div>
        </Spec>
        <Spec cap={L('Ended · declined · expired · cancelled', 'منتهية · لم تُقبل · انتهت المهلة · ملغاة')} kind="panel">
          <div className="dg-row dg-row--col">
            <BookingThread status="declined" draw={false} />
            <BookingThread status="expired" draw={false} />
            <BookingThread status="cancelled" draw={false} />
          </div>
        </Spec>
        <Spec cap={L('Compact · glyph, word and time on one line', 'مصغّر · أيقونة وكلمة ووقت في سطر')} kind="panel">
          <div className="dg-row dg-row--col">
            <BookingThread status="pending" variant="compact" draw={false} />
            <BookingThread status="approved" variant="compact" draw={false} />
          </div>
        </Spec>
        <Spec cap={L('Vertical · booking detail', 'عمودي · تفاصيل الحجز')} kind="panel">
          <BookingThread status="confirmed" variant="vertical" draw={false} />
        </Spec>
        <Spec cap={L('On ink · the confirmation hero', 'على الحبر · بطل التأكيد')} kind="ink">
          <BookingThread status="approved" onDark draw={false} />
        </Spec>
        <Spec cap={L('IconProgress · any short process', 'تقدّم بأيقونات · أي عملية قصيرة')} kind="panel">
          <IconProgress
            label={L('Listing', 'الإعلان')}
            describe={L('Review, step 3 of 4', 'المراجعة، المرحلة 3 من 4')}
            draw={false}
            steps={[
              { key: 'draft', icon: 'edit', label: L('Draft', 'مسودة'), state: 'tied' },
              { key: 'pay', icon: 'card', label: L('Payment', 'الدفع'), state: 'tied' },
              { key: 'review', icon: 'clock', label: L('Review', 'مراجعة'), state: 'now' },
              { key: 'live', icon: 'megaphone', label: L('Live', 'منشور'), state: 'open' },
            ]}
            note={
              <>
                <FactChip icon="timer" label={L('Time left', 'الوقت المتبقي')} value={hours(46)} size="sm" tone="muted" />
              </>
            }
            noteTone="now"
          />
        </Spec>
      </Sec>

      <Sec id="tabs" title={L('Tabs and switches', 'التبويبات والمفاتيح')} note={L('Fixed-size containers: choosing never moves or resizes anything, only the thread slides. Measured scale-safe: the last specimen is a phone at 75%.', 'حاويات ثابتة الحجم: الاختيار لا يحرّك شيئًا، الخيط وحده ينزلق. القياس يراعي التصغير: العيّنة الأخيرة هاتف بنسبة 75%.')}>
        <Spec cap={L('IconTabs · the word under the selected tab only', 'تبويبات بأيقونات · الكلمة تحت التبويب المحدد فقط')}>
          <IconTabs
            label={L('Sections', 'الأقسام')}
            value={tab}
            onChange={setTab}
            items={[
              { value: 'days', icon: 'calendar', label: L('Dates', 'التواريخ') },
              { value: 'prices', icon: 'coins', label: L('Prices', 'الأسعار') },
              { value: 'photos', icon: 'camera', label: L('Photos', 'الصور'), count: 3 },
              { value: 'map', icon: 'pin', label: L('Map', 'الخريطة') },
            ]}
          />
        </Spec>
        <Spec cap={L('IconTabs · all words (an ambiguous glyph)', 'تبويبات بأيقونات · كل الكلمات')}>
          <IconTabs
            labels="all"
            label={L('Sections', 'الأقسام')}
            defaultValue="prices"
            items={[
              { value: 'days', icon: 'calendar', label: L('Dates', 'التواريخ') },
              { value: 'prices', icon: 'coins', label: L('Prices', 'الأسعار') },
              { value: 'rules', icon: 'document', label: L('Rules', 'الشروط') },
            ]}
          />
        </Spec>
        <Spec cap={L('IconSegmented · the word beside the selected glyph', 'مفتاح بأيقونات · الكلمة بجانب الأيقونة المحددة')}>
          <IconSegmented
            label={L('View', 'العرض')}
            value={seg}
            onChange={setSeg}
            options={[
              { value: 'dates', icon: 'calendar', label: L('Dates', 'التواريخ') },
              { value: 'prices', icon: 'coins', label: L('Prices', 'الأسعار') },
            ]}
          />
        </Spec>
        <Spec cap={L('IconSegmented · three sessions, glyphs only (names remain for screen readers)', 'مفتاح بأيقونات · ثلاث فترات بلا كلمات')}>
          <IconSegmented
            labels="none"
            label={L('Session', 'الفترة')}
            defaultValue="evening"
            options={[
              { value: 'day', icon: 'sun', label: L('Day', 'نهارًا') },
              { value: 'sunset', icon: 'sunset', label: L('Sunset', 'عصرًا') },
              { value: 'evening', icon: 'moon', label: L('Evening', 'مساءً') },
            ]}
          />
        </Spec>
        <Spec cap={L('Under a scaled phone (75%): the pill and the thread sit exactly under the option', 'داخل هاتف مصغّر (75%): الشريط والخيط تحت الخيار تمامًا')}>
          <div className="dg-scaled-box">
            <div className="dg-scaled">
              <div className="dg-row dg-row--col">
                <IconSegmented
                  label={L('View', 'العرض')}
                  defaultValue="prices"
                  options={[
                    { value: 'dates', icon: 'calendar', label: L('Dates', 'التواريخ') },
                    { value: 'prices', icon: 'coins', label: L('Prices', 'الأسعار') },
                    { value: 'map', icon: 'pin', label: L('Map', 'الخريطة') },
                  ]}
                />
                <IconTabs
                  label={L('Sections', 'الأقسام')}
                  defaultValue="photos"
                  items={[
                    { value: 'days', icon: 'calendar', label: L('Dates', 'التواريخ') },
                    { value: 'photos', icon: 'camera', label: L('Photos', 'الصور') },
                    { value: 'map', icon: 'pin', label: L('Map', 'الخريطة') },
                  ]}
                />
              </div>
            </div>
          </div>
        </Spec>
      </Sec>

      <Sec id="info" title={L('Info', 'المعلومات')} note={L('Where the three allowed paragraphs live: consent, cancellation and voucher terms, error recovery.', 'مكان الفقرات الثلاث المسموحة: الموافقة وشروط الإلغاء والكوبون وتعافي الأخطاء.')}>
        <Spec cap={L('InfoButton · a 44 target; tap opens the sheet', 'زر المعلومات · هدف 44؛ يفتح الورقة')} kind="panel">
          <div className="dg-row">
            <span className="gz-t-title">{L('Terms', 'الشروط')}</span>
            <InfoButton title={L('Cancellation', 'الإلغاء')}>
              <p>{L('The voucher goes back to you if the venue declines or does not reply in time. If you withdraw before approval it stays yours for 60 days at the same venue.', 'يعود الكوبون إليكم إذا اعتذر المكان أو لم يرد في الوقت. وإذا سحبتم الطلب قبل الموافقة يبقى لكم 60 يومًا لدى المكان نفسه.')}</p>
            </InfoButton>
          </div>
        </Spec>
        <Spec cap={L('InfoSheet · title of three words at most, the paragraph, Done', 'ورقة المعلومات · عنوان من ثلاث كلمات والفقرة وزر تم')}>
          <Sheet
            placement="inline"
            title={L('Cancellation', 'الإلغاء')}
            footer={<Button variant="secondary" fullWidth>{L('Done', 'تم')}</Button>}
          >
            <div className="gz-info__body gz-t-body">
              <p>{L('The voucher goes back to you if the venue declines or does not reply in time.', 'يعود الكوبون إليكم إذا اعتذر المكان أو لم يرد في الوقت.')}</p>
            </div>
          </Sheet>
        </Spec>
      </Sec>

      <Sec id="states-empty" title={L('States', 'الحالات')} note={L('An illustration, a title of four words at most, one action. The recovery text is one tap further.', 'رسم وعنوان من أربع كلمات وإجراء واحد. نص التعافي على بعد نقرة.')}>
        <Spec cap={L('EmptyState · saved', 'حالة فارغة · المحفوظات')} kind="state">
          <EmptyState illustration="empty-saved" title={L('Nothing saved', 'لا شيء محفوظ')} action={{ label: L('Browse halls', 'تصفح القاعات'), iconStart: 'search' }} />
        </Spec>
        <Spec cap={L('EmptyState · from a legacy icon and a long body (the body moves behind the info glyph)', 'حالة فارغة · من أيقونة قديمة ونص طويل (النص يذهب خلف أيقونة المعلومات)')} kind="state">
          <EmptyState icon="ticket" title={L('No vouchers', 'لا كوبونات')} body={L('Vouchers you buy appear here with their code and QR so you can show them at the venue.', 'تظهر هنا الكوبونات التي تشترونها مع رمزها وQR لعرضها لدى المكان.')} />
        </Spec>
      </Sec>

      <Sec id="states-success" title={L('Success', 'النجاح')}>
        <Spec cap={L('SuccessState · request sent', 'حالة نجاح · أُرسل الطلب')} kind="state">
          <SuccessState illustration="success-request" title={L('Request sent', 'أُرسل الطلب')} action={{ label: L('Done', 'تم') }} />
        </Spec>
        <Spec cap={L('SuccessState · voucher ready', 'حالة نجاح · الكوبون جاهز')} kind="state">
          <SuccessState illustration="success-voucher" title={L('Voucher ready', 'الكوبون جاهز')} action={{ label: L('View voucher', 'عرض الكوبون') }} />
        </Spec>
      </Sec>

      <Sec id="states-error" title={L('Errors', 'الأخطاء')}>
        <Spec cap={L('ErrorState · load', 'حالة خطأ · التحميل')} kind="state">
          <ErrorState kind="load" />
        </Spec>
        <Spec cap={L('ErrorState · offline · payment · no access', 'حالة خطأ · بلا اتصال · الدفع · بلا صلاحية')} kind="state">
          <ErrorState kind="network" />
        </Spec>
        <Spec cap={L('Payment', 'الدفع')} kind="state">
          <ErrorState kind="payment" />
        </Spec>
        <Spec cap={L('No access', 'بلا صلاحية')} kind="state">
          <ErrorState kind="no-access" />
        </Spec>
      </Sec>

      <Sec id="onboarding" title={L('Onboarding', 'التعريف')} note={L('A drawing and five words.', 'رسم وخمس كلمات.')}>
        <Spec cap={L('OnboardingSlide', 'شريحة تعريف')} kind="state">
          <OnboardingSlide illustration="onboard-compare" title={L('Compare three halls', 'قارنوا بين ثلاث قاعات')} />
        </Spec>
        <Spec cap={L('OnboardingSlide · dates and voucher', 'شريحة تعريف · التواريخ والكوبون')} kind="state">
          <OnboardingSlide illustration="onboard-dates" title={L('See free dates', 'التواريخ المتاحة')} />
        </Spec>
        <Spec cap={L('Voucher', 'الكوبون')} kind="state">
          <OnboardingSlide illustration="onboard-voucher" title={L('One voucher, lower price', 'كوبون واحد بسعر أقل')} />
        </Spec>
      </Sec>

      <Sec id="voucher" title={L('Voucher and price', 'الكوبون والسعر')} note={L('Glyphs and figures: the words stay as accessible names.', 'أيقونات وأرقام: الكلمات تبقى أسماءً صوتية.')}>
        <Spec cap={L('VoucherCard · full', 'بطاقة الكوبون · كاملة')}>
          <VoucherCard voucher={hero} onCopy={() => undefined} onShowFull={() => undefined} />
        </Spec>
        <Spec cap={L('VoucherCard · compact · VoucherChip', 'بطاقة الكوبون · مختصرة · شارة الكوبون')}>
          <div className="dg-row dg-row--col">
            <VoucherCard voucher={hero} variant="compact" onOpen={() => undefined} />
            <VoucherChip code={hero.code} />
          </div>
        </Spec>
        <Spec cap={L('PriceCompare · stack · inline', 'مقارنة السعر · عمودي · سطر')} kind="panel">
          <div className="dg-row dg-row--col">
            <PriceCompare standard={4_200_000} voucher={3_400_000} structure="package" guests={350} />
            <PriceCompare standard={12_000} voucher={9_000} structure="per_person" guests={350} variant="inline" />
          </div>
        </Spec>
      </Sec>

      <Sec id="request" title={L('Partner request and KPI', 'طلب الشريك والمؤشرات')} note={L('The triage card in glyphs and figures; KPI tiles as a glyph over the number.', 'بطاقة الفرز بأيقونات وأرقام؛ بلاطات المؤشرات أيقونة فوق الرقم.')}>
        <Spec cap={L('RequestCard', 'بطاقة الطلب')}>
          <RequestCard request={request} state="new" />
        </Spec>
        <Spec cap={L('KpiTile · with an icon', 'بلاطة مؤشر · مع أيقونة')}>
          <div className="dg-row dg-row--stretch">
            <KpiTile icon="eye" label={L('Views', 'المشاهدات')} value={{ kind: 'count', value: 1280 }} delta={12} deltaLabel={L('vs previous 30 days', 'مقارنة بآخر 30 يومًا')} />
            <KpiTile icon="ticket" label={L('Vouchers redeemed', 'كوبونات مستخدمة')} value={{ kind: 'count', value: 38 }} />
          </div>
        </Spec>
      </Sec>
    </div>
  )
}

void engine
void PROTOTYPE_TODAY
