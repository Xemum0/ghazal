// Client-domain components gallery: every component of design/src/system/domain-client, every variant and key state, in both
// languages, driven by the fixtures (design/src/mock). Owner: client-domain-owner. Rendered at #/gallery/client?lang=en|ar.
// Optional `&only=venue-card,thread` renders just those sections (used by the screenshot checks).
import { useLang } from '../shell/lang'
import { useRoute } from '../shell/router'
import { L } from '../system/domain-client/gallery/kit'
import { BookingCardSection, PackageCardSection, PriceBreakdownSection } from '../system/domain-client/gallery/BookingSections'
import { BriefSection, CategoryTileSection, CountdownSection, OfferSection } from '../system/domain-client/gallery/HomeSections'
import { CompareTableSection, CompareTraySection, ComparePartsSection } from '../system/domain-client/gallery/CompareSections'
import { ReviewSection, VenueInfoSection } from '../system/domain-client/gallery/VenueInfoSections'
import { PlannerSection, ServiceTileSection, VendorSection } from '../system/domain-client/gallery/ServiceSections'
import { ChatSection, ConversationSection } from '../system/domain-client/gallery/ChatSections'
import { BudgetSection, ChecklistSection, NotificationSection, PaymentSection } from '../system/domain-client/gallery/PlanSections'
import { ThreadSection } from '../system/domain-client/gallery/ThreadSections'
import { VenueCardSection, VenueCompactSection, VenueStressSection } from '../system/domain-client/gallery/VenueSections'

const SECTIONS = [
  ['brief', BriefSection],
  ['category-tile', CategoryTileSection],
  ['offer-card', OfferSection],
  ['countdown', CountdownSection],
  ['venue-card', VenueCardSection],
  ['venue-compact', VenueCompactSection],
  ['venue-stress', VenueStressSection],
  ['compare-tray', CompareTraySection],
  ['compare-table', CompareTableSection],
  ['compare-parts', ComparePartsSection],
  ['reviews', ReviewSection],
  ['venue-info', VenueInfoSection],
  ['planner-tier', PlannerSection],
  ['service-tile', ServiceTileSection],
  ['vendor-card', VendorSection],
  ['chat', ChatSection],
  ['conversation-row', ConversationSection],
  ['checklist', ChecklistSection],
  ['budget', BudgetSection],
  ['notification-row', NotificationSection],
  ['payment', PaymentSection],
  ['thread', ThreadSection],
  ['booking-card', BookingCardSection],
  ['package-card', PackageCardSection],
  ['price-breakdown', PriceBreakdownSection],
] as const

export default function ClientGallery() {
  const { lang } = useLang()
  const only = useRoute().params.get('only')?.split(',').filter(Boolean)
  return (
    <div className="gc" data-gz="ClientGallery">
      {only ? null : (
        <header className="gc-hero">
          <p className="gz-t-label">{L(lang, 'Design system', 'نظام التصميم')}</p>
          <h1 className="gz-t-d3">{L(lang, 'Client components', 'مكوّنات تطبيق العميل')}</h1>
          <p className="gz-t-body-s">
            {L(
              lang,
              'The cards, threads, tables and sheets of the couple’s app, built from the core system and fed by the fixtures. Every state in both languages; long Arabic names, three-digit prices and empty galleries are in the stress rows.',
              'البطاقات والخيوط والجداول والأوراق في تطبيق العروسين، مبنية من النظام الأساسي ومغذّاة ببيانات النماذج. كل الحالات باللغتين؛ والأسماء العربية الطويلة والأسعار من ثلاث خانات والمعارض الفارغة في صفوف الضغط.',
            )}
          </p>
          <nav className="gc-index" aria-label={L(lang, 'Sections', 'الأقسام')}>
            {SECTIONS.map(([id]) => (
              <button
                key={id}
                type="button"
                className="gz-reset gz-t-body-s gc-index__link"
                onClick={() => document.getElementById(id)?.scrollIntoView({ block: 'start' })}
              >
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
