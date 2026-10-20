// Gallery: checklist, budget, notifications, payment methods and the voucher receipt layout, from the client fixtures.
import { useState } from 'react'
import {
  budgetFor, checklistFor, clientNotifications, heroVoucherAs, serviceCategories, vouchers,
  type Budget, type ChecklistItem as Item,
} from '../../../mock'
import { useBi } from '../bits'
import { BudgetSummary, ChecklistItem, ChecklistProgress } from '../Planning'
import { NotificationRow } from '../NotificationRow'
import { PaymentMethodRow, ReceiptSheet, type PaymentMethodKey } from '../Payments'
import { Section, Spec, useL } from './kit'

export function ChecklistSection() {
  const l = useL()
  const bi = useBi()
  const base = checklistFor('pending')
  const confirmed = checklistFor('confirmed')
  const [items, setItems] = useState<Item[]>(base.items)
  const done = items.filter(i => i.done).length
  const cat = (id: string | null) => serviceCategories.find(c => c.id === id)
  return (
    <Section
      id="checklist"
      title={l('Checklist', 'قائمة المهام')}
      note={l(
        'A 64 row with a 24 box in a 44 target. Done is quiet ink, never struck through; overdue is said in words with a glyph; the Venue task completes itself at confirmation and shows a lock. The progress line is gold because it is state.',
        'صف بارتفاع 64 ومربع 24 داخل هدف لمس 44. المنجز بحبر هادئ دون شطب؛ والمتأخر يُقال بالكلمات مع رمز؛ ومهمة القاعة تكتمل تلقائيًا عند التأكيد وتعرض قفلًا. خط التقدم ذهبي لأنه حالة.',
      )}
    >
      <Spec state={l('Interactive · tick a task, open its category', 'تفاعلي · علّموا مهمة وافتحوا فئتها')}>
        <ChecklistProgress done={done} total={items.length} />
        <div className="gc-list">
          {items.map((it, i) => (
            <ChecklistItem
              key={it.id}
              item={it}
              today="2026-11-16"
              last={i === items.length - 1}
              onToggle={d => setItems(items.map(x => (x.id === it.id ? { ...x, done: d, doneAt: d ? '2026-11-12T16:00:00+03:00' : null } : x)))}
              onChoose={() => undefined}
              actionLabel={cat(it.serviceCategoryId) ? bi(cat(it.serviceCategoryId)!.name) : undefined}
            />
          ))}
        </div>
      </Spec>
      <Spec state={l('After confirmation: the Venue task is done by the system (11%)', 'بعد التأكيد: أنجز النظام مهمة القاعة (11%)')}>
        <ChecklistProgress done={confirmed.items.filter(i => i.done).length} total={confirmed.items.length} />
        <div className="gc-list">
          {confirmed.items.slice(0, 2).map((it, i) => (
            <ChecklistItem key={it.id} item={it} last={i === 1} />
          ))}
        </div>
      </Spec>
    </Section>
  )
}

export function BudgetSection() {
  const l = useL()
  const normal = budgetFor('pending').budget
  const conf = budgetFor('confirmed').budget
  const over: Budget = {
    ...conf,
    categories: conf.categories.map(c => (c.id === 'flowers_decor' ? { ...c, paid: { fils: 4920000, currency: 'KWD' }, committed: { fils: 1600000, currency: 'KWD' } } : c)),
  }
  const empty: Budget = { ...normal, categories: normal.categories.slice(0, 2) }
  return (
    <Section
      id="budget"
      title={l('Budget summary', 'ملخص الميزانية')}
      note={l(
        'The total, a stacked bar (paid in ink, committed in gold, the rest on the track), the three meanings in words, and category rows with their own bars. An alert appears only when a category or the whole budget goes over, and says so in words.',
        'الإجمالي وشريط مكدّس (المدفوع بالحبر والملتزم به بالذهبي والباقي على المسار) والمعاني الثلاثة بالكلمات وصفوف الفئات بأشرطتها. لا يظهر التنبيه إلا عند تجاوز فئة أو الميزانية كلها ويُذكر بالكلمات.',
      )}
    >
      <Spec state={l('Confirmed booking: voucher paid, the venue price committed', 'حجز مؤكد: الكوبون مدفوع وسعر المكان ملتزم به')}>
        <BudgetSummary budget={conf} />
      </Spec>
      <Spec state={l('Nothing spent yet', 'لم يُصرف شيء بعد')}>
        <BudgetSummary budget={empty} />
      </Spec>
      <Spec state={l('A category over its share: the alert, in words', 'فئة تجاوزت حصتها: التنبيه بالكلمات')}>
        <BudgetSummary budget={over} />
      </Spec>
      <Spec state={l('Stress: a very large committed amount', 'ضغط: مبلغ ملتزم به كبير جدًا')}>
        <BudgetSummary budget={{ ...conf, total: { fils: 6000000, currency: 'KWD' } }} />
      </Spec>
    </Section>
  )
}

export function NotificationSection() {
  const l = useL()
  const rows = clientNotifications.slice(0, 7)
  return (
    <Section
      id="notification-row"
      title={l('Notification row', 'صف الإشعار')}
      note={l(
        'A glyph in a tone disk (a reinforcement, never the only signal), the title, two lines of body, the time, and a gold bead while unread. Marketing is tagged.',
        'رمز داخل قرص بنبرة (تعزيز لا إشارة وحيدة) والعنوان وسطران من النص والوقت وخرزة ذهبية ما دام غير مقروء. الإشعارات التسويقية موسومة.',
      )}
    >
      <Spec state={l('The client inbox · unread first', 'صندوق إشعارات العميل · غير المقروء أولًا')}>
        <div className="gc-list">
          {rows.map((n, i) => (
            <NotificationRow key={n.id} notification={n} last={i === rows.length - 1} onOpen={() => undefined} />
          ))}
        </div>
      </Spec>
    </Section>
  )
}

export function PaymentSection() {
  const l = useL()
  const [pick, setPick] = useState<PaymentMethodKey>('knet')
  const order: PaymentMethodKey[] = ['apple_pay', 'knet', 'visa', 'mastercard']
  const android: PaymentMethodKey[] = ['knet', 'google_pay', 'visa', 'mastercard']
  const paid = heroVoucherAs('pending')
  const refunded = vouchers.find(v => v.status === 'refunded' && v.refund?.creditNoteNo)
  return (
    <Section
      id="payment"
      title={l('Payment methods and receipt', 'طرق الدفع والإيصال')}
      note={l(
        'Marks are monochrome placeholders set in ink; no brand artwork is copied. iOS orders Apple Pay first, Android KNET first (ADR 0027). The only payment in the product is the KD 2 voucher: there is no cash row. Documents say KWD, with Western digits and three decimals.',
        'العلامات بدائل أحادية اللون بالحبر؛ ولا تُنسخ أي صور لعلامات تجارية. يبدأ iOS بـ Apple Pay، ويبدأ Android بكي نت (القرار 0027). الدفعة الوحيدة في المنتج هي كوبون بقيمة 2 د.ك: لا يوجد صف للدفع النقدي. تقول المستندات KWD بأرقام غربية وثلاث خانات عشرية.',
      )}
    >
      <Spec state={l('iOS order · radio rows · KNET selected', 'ترتيب iOS · صفوف اختيار · كي نت محددة')}>
        {order.map(m => (
          <PaymentMethodRow key={m} method={m} selected={pick === m} onSelect={() => setPick(m)} />
        ))}
      </Spec>
      <Spec state={l('Android order · unavailable · pressed', 'ترتيب Android · غير متاح · الضغط')}>
        {android.map(m => (
          <PaymentMethodRow key={m} method={m} selected={pick === m} onSelect={() => setPick(m)} />
        ))}
        <PaymentMethodRow method="apple_pay" unavailable />
        <PaymentMethodRow method="visa" note={l('Recommended after a KNET limit', 'موصى بها عند بلوغ حد كي نت')} previewState="pressed" />
      </Spec>
      <Spec state={l('Receipt · the KD 2 voucher, issued by Ghazal', 'إيصال · كوبون بقيمة 2 د.ك صادر عن غزل')}>
        <ReceiptSheet voucher={paid} />
      </Spec>
      {refunded ? (
        <Spec state={l('Credit note · for a refunded voucher', 'إشعار دائن · لكوبون مسترد')}>
          <ReceiptSheet voucher={refunded} kind="credit_note" />
        </Spec>
      ) : null}
    </Section>
  )
}
