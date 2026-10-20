// Voucher-model gallery (ADR 0033): every new component of the voucher marketplace in both languages, driven by the fixtures: the voucher ticket
// and chip, QR, the two-price block, the purchase summary, the 24 hour confirm window, the visit and group-chat pieces, the service-provider module
// (listings, review timeline, ad plans, major-hotel badge) and the search filters. The Booking Thread (five knots) lives in #/gallery/client and the
// status pills in #/gallery/core. Rendered at #/gallery/voucher?lang=en|ar. Optional `&only=voucher-card,qr` renders just those sections.
import { useLang } from '../shell/lang'
import { useRoute } from '../shell/router'
import { L } from '../system/domain-client/gallery/kit'
import { ConfirmWindowSection, PriceCompareSection, PurchaseSummarySection, QrSection, VoucherCardSection } from '../system/domain-voucher/gallery/VoucherSections'
import { GroupChatSection, RoleBadgeSection, VisitCardSection } from '../system/domain-voucher/gallery/GroupSections'
import { AdPlanSection, ListingSection, ReviewTimelineSection } from '../system/domain-voucher/gallery/ProviderSections'
import { FilterSection } from '../system/domain-voucher/gallery/FilterSections'

const SECTIONS = [
  ['voucher-card', VoucherCardSection],
  ['qr', QrSection],
  ['price-compare', PriceCompareSection],
  ['purchase-summary', PurchaseSummarySection],
  ['confirm-window', ConfirmWindowSection],
  ['role-badge', RoleBadgeSection],
  ['group-chat', GroupChatSection],
  ['visit-card', VisitCardSection],
  ['listing', ListingSection],
  ['review-timeline', ReviewTimelineSection],
  ['ad-plan', AdPlanSection],
  ['filters', FilterSection],
] as const

export default function VoucherGallery() {
  const { lang } = useLang()
  const only = useRoute().params.get('only')?.split(',').filter(Boolean)
  return (
    <div className="gc" data-gz="VoucherGallery">
      {only ? null : (
        <header className="gc-hero">
          <p className="gz-t-label">{L(lang, 'Design system', 'نظام التصميم')}</p>
          <h1 className="gz-t-d3">{L(lang, 'Voucher marketplace components', 'مكوّنات سوق الكوبون')}</h1>
          <p className="gz-t-body-s">
            {L(
              lang,
              'Ghazal sells one thing: a KD 2 voucher that unlocks the lower price at the venue or provider. These are the pieces of that model: the voucher ticket, the two prices, the 24 hour confirm window, site visits with their three-way chat, the service-provider module with manual review, and the search filters.',
              'تبيع غزل شيئًا واحدًا: كوبونًا بقيمة 2 د.ك يفتح السعر الأقل لدى المكان أو مقدّم الخدمة. هذه هي قطع هذا النموذج: تذكرة الكوبون والسعران ومهلة التأكيد (24 ساعة) وزيارات القاعة مع محادثتها الثلاثية ووحدة مقدّمي الخدمة بالمراجعة اليدوية ومرشحات البحث.',
            )}
          </p>
          <nav className="gc-index" aria-label={L(lang, 'Sections', 'الأقسام')}>
            {SECTIONS.map(([id]) => (
              <button key={id} type="button" className="gz-reset gz-t-body-s gc-index__link" onClick={() => document.getElementById(id)?.scrollIntoView({ block: 'start' })}>
                {id}
              </button>
            ))}
          </nav>
        </header>
      )}
      {SECTIONS.filter(([id]) => !only || only.includes(id)).map(([id, Section]) => (
        <Section key={id} />
      ))}
    </div>
  )
}
