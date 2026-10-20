// Gallery sections: the partner's management pieces (voucher-price window editor, packages with two prices, photos, staff, business hours,
// reviews and the partner notifications), driven by the Aurelia Gulf Hotel fixtures (voucher windows, packages and price rules, gallery,
// staff, settings, reviews). ADR 0033: no offers, no coupon codes, no bank information.
import { useState } from 'react'
import { getPackage, getVenue, hotelNotifications, hotelSettings, hotelStaff, meta, packagesFor, reviewsFor, rulesFor, voucherWindows, PROTOTYPE_TODAY } from '../../../mock'
import { useLang } from '../../../shell/lang'
import { NotificationRow } from '../../domain-client'
import { VoucherWindowPreview } from '../offers/VoucherWindowPreview'
import { ValidityRange } from '../offers/ValidityRange'
import { BusinessHoursRow } from '../settings/BusinessHoursRow'
import { ReviewReplyCard } from '../settings/ReviewReplyCard'
import { StaffRow } from '../settings/StaffRow'
import { PackageEditorRow } from '../venue/PackageEditorRow'
import { PhotoManagerGrid, type PhotoTile } from '../venue/PhotoManagerGrid'
import { L, Section, Spec, Stage } from './kit'

const venue = () => getVenue(meta.hotelVenueId)

export function OfferSection() {
  const { lang } = useLang()
  const v = venue()
  const [range, setRange] = useState({ start: '2026-12-03', end: '2026-12-05' })
  const [hours, setHours] = useState<6 | 12 | 24 | 48>(24)
  const flash = voucherWindows.find(o => o.id === 'vw-V01-flash')
  const pkg = getPackage('V01-ladies-weekend')
  if (!v || !flash || !pkg) return null
  return (
    <Section
      id="offer"
      title={L(lang, 'Voucher price window editor', 'محرر نافذة سعر الكوبون')}
      note={L(lang, 'Step 1: when the lower voucher price applies and runs. The preview is the client app’s own card, with the real standard price struck through and the saving in exact money.', 'الخطوة 1: متى ينطبق سعر الكوبون الأقل ومتى يعمل. المعاينة هي بطاقة تطبيق العملاء نفسها مع شطب السعر العادي الفعلي والتوفير بالمبلغ الدقيق.')}
    >
      <Spec cap={L(lang, 'When: event dates, a time-boxed window, scheduled', 'المدة: تواريخ المناسبة ونافذة محددة المدة، مجدول')}>
        <ValidityRange value={range} onChange={r => setRange({ start: r.start ?? range.start, end: r.end ?? range.end })} windowHours={hours} onWindowChange={setHours} endsAt="2026-11-13T16:00:00+03:00" startsAt="2026-11-13T16:00:00+03:00" status="scheduled" today={PROTOTYPE_TODAY} />
      </Spec>
      <Spec cap={L(lang, 'Live preview: a lower voucher price on Ladies’ Reception, Weekend', 'معاينة حية: سعر كوبون أقل على الحفل النسائي في نهاية الأسبوع')}>
        <VoucherWindowPreview venue={v} title={flash.title[lang]} standard={18200000} voucher={15400000} guests={350} packageId={pkg.id} date="2026-12-03" />
      </Spec>
    </Section>
  )
}

export function VenueSection() {
  const { lang } = useLang()
  const v = venue()
  const pkgs = packagesFor(meta.hotelVenueId).slice(0, 3)
  const weekend = (id: string) => rulesFor(id).find(r => r.tier === 'weekend' && (r.perGuest || r.flat)) ?? rulesFor(id).find(r => r.perGuest || r.flat)
  const gallery = v?.gallery ?? []
  const tiles: PhotoTile[] = gallery.slice(0, 8).map((g, i) => ({ id: g.file, image: g, status: i === 3 ? 'review' : i === 6 ? 'rejected' : 'live' }))
  const [order, setOrder] = useState(tiles)
  const move = (id: string, by: -1 | 1) =>
    setOrder(list => {
      const i = list.findIndex(t => t.id === id)
      const j = i + by
      if (i < 0 || j < 0 || j >= list.length) return list
      const next = [...list]
      ;[next[i], next[j]] = [next[j] as PhotoTile, next[i] as PhotoTile]
      return next
    })
  return (
    <Section
      id="venue"
      title={L(lang, 'Packages and photos', 'الباقات والصور')}
      note={L(lang, 'Edit the standard and voucher price, minimum guests and inclusions in place; manage the photo grid with a cover marker, zone tags, status chips and a reorder mode with plain Move buttons.', 'عدّلوا السعر العادي وسعر الكوبون والحد الأدنى للضيوف وما تشمله الباقة في مكانه؛ وأدِيروا شبكة الصور بعلامة الغلاف ووسوم المناطق وشارات الحالة ووضع إعادة ترتيب بأزرار نقل واضحة.')}
    >
      <Stage kind="panel">
        <div>
          {pkgs.map((pk, i) => (
            <PackageEditorRow key={pk.id} pkg={pk} priceFils={weekend(pk.id)?.perGuest?.fils ?? weekend(pk.id)?.flat?.fils ?? 0} voucherFils={weekend(pk.id)?.voucherPerGuest?.fils ?? weekend(pk.id)?.voucherFlat?.fils ?? null} defaultExpanded={i === 0} last={i === pkgs.length - 1} />
          ))}
        </div>
      </Stage>
      <Spec cap={L(lang, 'Photos: cover, zone tags, under review, rejected, Add tile', 'الصور: الغلاف ووسوم المناطق وقيد المراجعة والمرفوضة وبلاطة الإضافة')}>
        <PhotoManagerGrid items={order} />
      </Spec>
      <Spec cap={L(lang, 'Reorder mode: handle and Move earlier / Move later', 'وضع إعادة الترتيب: المقبض وزرا التقديم والتأخير')}>
        <PhotoManagerGrid items={order.slice(0, 5)} reorder onMove={move} />
      </Spec>
    </Section>
  )
}

export function SettingsSection() {
  const { lang } = useLang()
  const staff = hotelStaff.filter(s => s.venueId === meta.hotelVenueId)
  const rules = hotelSettings.hours.rules
  const hoursOf = (wd: number) => rules.find(r => (r.days as number[]).includes(wd))
  const [open, setOpen] = useState<Record<number, boolean>>({ 0: true, 1: true, 2: true, 3: true, 4: true, 5: true, 6: false })
  return (
    <Section
      id="settings"
      title={L(lang, 'Staff and hours', 'الموظفون والساعات')}
      note={L(lang, 'Roles explained in one line and as a check list; hours with custom time buttons and the past-midnight label', 'الأدوار موضّحة بسطر واحد وبقائمة صلاحيات؛ والساعات بأزرار وقت مخصصة وعلامة تجاوز منتصف الليل')}
    >
      <Stage kind="panel">
        <div>
          {staff.map((s, i) => (
            <StaffRow key={s.id} staff={s} defaultExpanded={s.role === 'reception'} last={i === staff.length - 1} />
          ))}
        </div>
      </Stage>
      <Stage kind="panel">
        <div>
          {[0, 1, 2, 3, 4, 5, 6].map(wd => {
            const r = hoursOf(wd)
            return (
              <BusinessHoursRow
                key={wd}
                weekday={wd as 0}
                open={open[wd] ?? false}
                from={r?.open ?? '09:00'}
                to={r?.close ?? '22:00'}
                onOpenChange={v => setOpen(o => ({ ...o, [wd]: v }))}
                onCopy={wd === 0 ? () => undefined : undefined}
                last={wd === 6}
              />
            )
          })}
        </div>
      </Stage>
      <Spec cap={L(lang, 'Invalid: opening and closing at the same time', 'غير صالح: الفتح والإغلاق في الوقت نفسه')}>
        <Stage kind="panel">
          <BusinessHoursRow weekday={4} open from="09:00" to="09:00" invalid last />
        </Stage>
      </Spec>
    </Section>
  )
}

export function ReviewSection() {
  const { lang } = useLang()
  const reviews = reviewsFor(meta.hotelVenueId)
  const needs = reviews.find(r => r.ownerReply === null && r.replyDraft)
  const replied = reviews.find(r => r.ownerReply)
  const plain = reviews.find(r => r.ownerReply === null && !r.replyDraft && r.id !== needs?.id)
  return (
    <Section id="review" title={L(lang, 'Reviews and notifications', 'التقييمات والإشعارات')} note={L(lang, 'Reply once, report abuse; the hotel never edits or hides a review. Notifications reuse the system row with the hotel kinds.', 'رد واحد وإبلاغ عن الإساءة؛ ولا يعدّل الفندق التقييم ولا يخفيه. تستخدم الإشعارات الصف نفسه مع أنواع الفندق.')}>
      <Stage kind="panel">
        <div>
          {needs ? <ReviewReplyCard review={needs} state="needs_reply" /> : null}
          {replied ? <ReviewReplyCard review={replied} state="replied" /> : null}
          {plain ? <ReviewReplyCard review={plain} state="reported" last /> : null}
        </div>
      </Stage>
      <Spec cap={L(lang, 'Hotel notifications (new request, message, cancellation, payment, review)', 'إشعارات الفندق (طلب جديد، رسالة، إلغاء، دفعة، تقييم)')}>
        <Stage kind="panel">
          <div>
            {hotelNotifications.slice(0, 5).map((n, i, a) => (
              <NotificationRow key={n.id} notification={n} last={i === a.length - 1} />
            ))}
          </div>
        </Stage>
      </Spec>
    </Section>
  )
}
