// Partner-domain gallery (the app id stays `hotel`): every component of design/src/system/domain-hotel in both languages, driven by the partner fixtures
// (Aurelia Gulf Hotel, V01). Rendered at #/gallery/hotel?lang=en|ar. Optional `&only=request,timeline` renders just those sections:
//   request row timeline strip kpi month select week day block booking offer venue settings review
// The page draws the hotel app's type (AppContext = hotel): sheet titles use the UI title, not the client's serif.
import { useLang } from '../shell/lang'
import { AppContext } from '../shell/device/context'
import { L, Page } from '../system/domain-hotel/gallery/kit'
import { BookingSection } from '../system/domain-hotel/gallery/BookingSections'
import { BlockSection, DaySection, MonthSection, SelectSection, WeekSection } from '../system/domain-hotel/gallery/CalendarSections'
import { OfferSection, ReviewSection, SettingsSection, VenueSection } from '../system/domain-hotel/gallery/ManageSections'
import { AnalyticsSection, RequestRowSection, StripSection, TimelineSection } from '../system/domain-hotel/gallery/TodaySections'
import { RequestCardSection } from '../system/domain-hotel/gallery/TriageSections'

export default function HotelGallery() {
  const { lang } = useLang()
  return (
    <AppContext.Provider value="hotel">
      <Page
        eyebrow={L(lang, 'Design system', 'نظام التصميم')}
        title={L(lang, 'Partner components', 'مكوّنات تطبيق الشريك')}
        lede={L(
          lang,
          'The back office of the venue or the service provider: calmer and denser than the client app, serif only for names, figures in the figures voice, gold only on the one action that is waiting for you.',
          'الواجهة الخلفية للمكان أو لمقدّم الخدمة: أهدأ وأكثف من تطبيق العملاء، والخط ذو الزوائد للأسماء فقط، والأرقام بصوت الأرقام، والذهبي للإجراء الوحيد الذي ينتظركم.',
        )}
      >
        <RequestCardSection />
        <RequestRowSection />
        <TimelineSection />
        <StripSection />
        <AnalyticsSection />
        <MonthSection />
        <SelectSection />
        <WeekSection />
        <DaySection />
        <BlockSection />
        <BookingSection />
        <OfferSection />
        <VenueSection />
        <SettingsSection />
        <ReviewSection />
      </Page>
    </AppContext.Provider>
  )
}
