// Gallery: the voucher pieces (ADR 0033): VoucherCard and VoucherChip, QrCode, PriceCompare, VoucherPurchaseSummary and ConfirmWindow, driven by
// the voucher fixtures and the hero request GZ-2611-0147. Rendered at #/gallery/voucher?lang=en|ar.
import { useState } from 'react'
import { getCreditVoucher, getVoucher, heroBookingAs, heroVoucherAs, meta, requireVenue, type CreditVoucher, type Voucher } from '../../../mock'
import { Row, Section, Spec, useL } from '../../domain-client/gallery/kit'
import { PriceCompare } from '../PriceCompare'
import { QrCode } from '../QrCode'
import { VoucherCard, VoucherChip } from '../VoucherCard'
import { VoucherPurchaseSummary } from '../VoucherPurchaseSummary'
import { ConfirmWindow } from '../ConfirmWindow'
import { Button } from '../../core'

const V = (id: string): Voucher => {
  const v = getVoucher(id)
  if (!v) throw new Error(`fixture ${id}`)
  return v
}

const CREDIT = (): CreditVoucher => {
  const v = getCreditVoucher('vch-GV-2611-C4RD')
  if (!v) throw new Error('fixture credit voucher')
  return v
}

export function VoucherCardSection() {
  const l = useL()
  const [copied, setCopied] = useState(false)
  const hero = heroVoucherAs('pending')
  return (
    <Section
      id="voucher-card"
      title={l('Voucher card', 'بطاقة الكوبون')}
      note={l(
        'The KD 2 voucher as a ticket: ink hairline, a perforation, the QR drawn from the signed payload in ink tokens, the code as a left-to-right isolate in the figures voice, the venue or provider it is bound to, the bound quote (standard struck through, voucher price) and the state chip. No gold fill: a voucher is a fact.',
        'كوبون 2 د.ك كتذكرة: إطار حبري رفيع وخط تثقيب وQR مرسوم من الحمولة الموقّعة بألوان الحبر، والرمز معزول من اليسار إلى اليمين بصوت الأرقام، والمكان أو مقدّم الخدمة المرتبط به، والعرض المرتبط (السعر العادي مشطوب وسعر الكوبون) وشارة الحالة. بلا تعبئة ذهبية: الكوبون حقيقة.',
      )}
    >
      <Spec state={l('Bound to the story request · copy and full screen', 'مرتبط بطلب القصة · نسخ وملء الشاشة')}>
        <VoucherCard voucher={hero} onCopy={() => setCopied(true)} onShowFull={() => undefined} />
        <p className="gc-cap gz-t-caption">{copied ? l('Copied', 'تم النسخ') : ' '}</p>
      </Spec>
      <Spec state={l('Ready to use (released after a venue fault: reusable, or ask support for a credit voucher)', 'جاهز للاستخدام (أُفرج عنه بعد تقصير المكان: قابل لإعادة الاستخدام أو اطلبوا كوبون رصيد من الدعم)')}>
        <VoucherCard voucher={V('vch-GV-2611-QD9X')} onCopy={() => undefined} onShowFull={() => undefined} />
      </Spec>
      <Spec state={l('A service provider voucher', 'كوبون خاص بمقدّم خدمة')}>
        <VoucherCard voucher={V('vch-GV-2611-QY57')} onCopy={() => undefined} onShowFull={() => undefined} />
      </Spec>
      <Spec state={l('Used · expired · not valid (24 h lapsed): the code stays, the QR is muted', 'مستخدم · منتهٍ · غير صالح (انتهت الـ 24 ساعة): يبقى الرمز ويخفت الـQR')}>
        <VoucherCard voucher={V('vch-GV-2608-378X')} />
        <VoucherCard voucher={V('vch-GV-2608-D5QN')} />
        <VoucherCard voucher={V('vch-GV-2609-F6TM')} />
      </Spec>
      <Spec state={l('Credit voucher · granted by support, unbound: any hall, hotel or service, 60 days', 'كوبون رصيد · منحه الدعم، غير مرتبط: أي قاعة أو فندق أو خدمة، لمدة 60 يومًا')}>
        <VoucherCard voucher={CREDIT()} onCopy={() => undefined} onShowFull={() => undefined} />
        <VoucherCard voucher={CREDIT()} variant="compact" onOpen={() => undefined} />
      </Spec>
      <Spec state={l('Compact rows · the wallet list', 'صفوف مختصرة · قائمة المحفظة')}>
        {['vch-GV-2611-K7QM', 'vch-GV-2611-QD9X', 'vch-GV-2611-M2WD', 'vch-GV-2608-378X', 'vch-GV-2609-F6TM', 'vch-GV-2610-H9XB'].map(id => (
          <VoucherCard key={id} voucher={V(id)} variant="compact" onOpen={() => undefined} />
        ))}
      </Spec>
      <Spec state={l('Voucher chip · bound · ready · quiet', 'شارة الكوبون · مرتبط · جاهز · هادئ')}>
        <Row>
          <VoucherChip code={hero.code} />
          <VoucherChip code={hero.code} tone="ready" />
          <VoucherChip code={hero.code} tone="quiet" />
        </Row>
      </Spec>
    </Section>
  )
}

export function QrSection() {
  const l = useL()
  const hero = heroVoucherAs('pending')
  const used = V('vch-GV-2608-378X')
  return (
    <Section
      id="qr"
      title={l('QR code', 'رمز QR')}
      note={l(
        'Generated from the voucher’s signed payload with qrcode-generator (MIT), drawn as one vector path in ink on the canvas token. Error correction M, a two-module quiet zone. The payload is never printed as text.',
        'يُولَّد من الحمولة الموقّعة للكوبون بمكتبة qrcode-generator (MIT) ويُرسم كمسار متجهي واحد بالحبر على لون الخلفية. تصحيح الخطأ M ومنطقة هادئة بعرض وحدتين. لا تُطبع الحمولة نصًّا أبدًا.',
      )}
    >
      <Spec state={l('144 · 96 · muted (a used voucher)', '144 · 96 · خافت (كوبون مستخدم)')}>
        <Row>
          <QrCode payload={hero.qr.payload} label={hero.code} size={144} />
          <QrCode payload={hero.qr.payload} label={hero.code} size={96} />
          <QrCode payload={used.qr.payload} label={used.code} size={96} muted />
        </Row>
      </Spec>
    </Section>
  )
}

export function PriceCompareSection() {
  const l = useL()
  const story = heroBookingAs('pending')
  const std = story.totals.standardTotal.fils
  const vch = story.totals.voucherTotal.fils
  return (
    <Section
      id="price-compare"
      title={l('Price compare', 'مقارنة السعر')}
      note={l(
        'The two prices of one quote on the same basis. The voucher price is the headline in the figures voice; the standard price sits under it, quiet and struck through; then the saving, the net saving after the KD 2 voucher and the basis.',
        'السعران لعرض واحد بالأساس نفسه. سعر الكوبون هو العنوان بصوت الأرقام، والسعر العادي تحته هادئًا ومشطوبًا؛ ثم التوفير والتوفير الصافي بعد كوبون 2 د.ك والأساس.',
      )}
    >
      <Spec state={l('Package · 350 guests', 'باقة · 350 ضيفًا')}>
        <PriceCompare standard={std} voucher={vch} structure="package" guests={350} />
      </Spec>
      <Spec state={l('Per person · hero size', 'للضيف · حجم العنوان')}>
        <PriceCompare standard={52000} voucher={44000} structure="per_person" guests={350} size="display" />
      </Spec>
      <Spec state={l('Inline for cards and rows', 'سطر واحد للبطاقات والصفوف')}>
        <PriceCompare standard={52000} voucher={44000} structure="per_person" guests={350} variant="inline" />
        <PriceCompare standard={std} voucher={vch} structure="package" variant="inline" />
      </Spec>
      <Spec state={l('No voucher price: the standard price alone, no strike, no voucher mention', 'لا سعر كوبون: السعر العادي وحده بلا شطب ولا إشارة للكوبون')}>
        <PriceCompare standard={std} voucher={null} structure="package" guests={350} />
      </Spec>
    </Section>
  )
}

export function PurchaseSummarySection() {
  const l = useL()
  const story = heroBookingAs('pending')
  const venue = requireVenue('V01')
  const name = l(venue.name.en, venue.name.ar)
  return (
    <Section
      id="purchase-summary"
      title={l('Voucher purchase summary', 'ملخص شراء الكوبون')}
      note={l(
        'What the KD 2 buys and what it does not: the bound quote, the two prices and the saving, the one amount paid to Ghazal today, the plain sentence that the rest is settled with the venue directly, and three rules in words. Never a deposit or a balance.',
        'ما يشتريه كوبون 2 د.ك وما لا يشتريه: العرض المرتبط والسعران والتوفير، والمبلغ الوحيد المدفوع لغزل اليوم، والجملة الواضحة بأن الباقي يُسدَّد للمكان مباشرة، وثلاث قواعد بالكلمات. لا عربون ولا متبقٍّ أبدًا.',
      )}
    >
      <Spec state={l('The story quote · Aurelia Gulf Hotel', 'عرض القصة · فندق أوريليا الخليج')}>
        <VoucherPurchaseSummary
          targetName={name}
          packageName={l('Ladies’ Reception, Weekend', 'الحفل النسائي في نهاية الأسبوع')}
          eventDate={story.eventDate}
          guests={350}
          standardFils={story.totals.standardTotal.fils}
          voucherFils={story.totals.voucherTotal.fils}
          feeFils={meta.config.voucherFeeFils}
          reuseDays={meta.config.voucherReuseDays}
        />
      </Spec>
    </Section>
  )
}

const DEADLINE = '2026-11-13T16:00:00+03:00'

export function ConfirmWindowSection() {
  const l = useL()
  return (
    <Section
      id="confirm-window"
      title={l('Confirm window (24 hours)', 'مهلة التأكيد (24 ساعة)')}
      note={l(
        'The owner’s fixed rule: the client confirms within 24 hours of approval. Calm by design: an absolute deadline sentence, the time left in hours and minutes (never seconds, never a ticking digit), a thread bar that only shows how much has passed and never turns red, and one reassurance line. Under an hour it says minutes; at the end it says the window closed and what happens to the voucher.',
        'قاعدة المالك الثابتة: يؤكد العميل خلال 24 ساعة من الموافقة. هادئة بالتصميم: جملة بموعد مطلق، والوقت المتبقي بالساعات والدقائق (لا ثوانٍ ولا رقم يتغير)، وشريط خيط لا يُظهر إلا ما مضى ولا يتحول إلى الأحمر، وسطر طمأنة واحد. قبل انتهاء الساعة الأخيرة يذكر الدقائق؛ وعند النهاية يقول إن المهلة انتهت وما يحدث للكوبون.',
      )}
    >
      <Spec state={l('Open · 23 hours 40 minutes left · with the one primary action', 'مفتوحة · باقي 23 ساعة و40 دقيقة · مع الإجراء الأساسي الوحيد')}>
        <ConfirmWindow deadline={DEADLINE} now="2026-11-12T16:20:00+03:00" onConfirm={() => undefined} />
      </Spec>
      <Spec state={l('Half way · 11 hours 30 minutes left', 'في المنتصف · باقي 11 ساعة و30 دقيقة')}>
        <ConfirmWindow deadline={DEADLINE} now="2026-11-13T04:30:00+03:00" />
      </Spec>
      <Spec state={l('The last hour · 45 minutes left (minutes only, no seconds)', 'الساعة الأخيرة · باقي 45 دقيقة (دقائق فقط بلا ثوانٍ)')}>
        <ConfirmWindow deadline={DEADLINE} now="2026-11-13T15:15:00+03:00" onConfirm={() => undefined} />
      </Spec>
      <Spec state={l('Lapsed · the voucher is free to use again', 'انتهت المهلة · الكوبون متاح للاستخدام من جديد')}>
        <ConfirmWindow deadline={DEADLINE} now="2026-11-13T16:30:00+03:00" />
      </Spec>
      <Spec state={l('Confirmed', 'تم التأكيد')}>
        <ConfirmWindow deadline={DEADLINE} confirmedAt="2026-11-12T18:05:00+03:00" />
      </Spec>
      <Spec tone="ink" state={l('On an ink panel · open', 'على لوحة داكنة · مفتوحة')}>
        <ConfirmWindow deadline={DEADLINE} now="2026-11-12T16:20:00+03:00" onDark />
        <Button variant="tertiary" onDark>
          {l('Cancel request', 'إلغاء الطلب')}
        </Button>
      </Spec>
    </Section>
  )
}
