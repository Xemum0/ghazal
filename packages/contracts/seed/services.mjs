// Additional services (ADR 0033 D8, voucher-model section 9): service providers who list post-venue needs. Five primary categories (owner
// list: hospitality and catering, buffet services, floral arrangements, event styling and decor, event planning and coordination) with 3 to 5
// providers each, then the secondary categories lightly (two providers each). Every provider package carries a standard and a voucher price.
// Price anchors from docs/research/kuwait-localization.md 8.6. Imagery: equipment, details, objects; no people (ADR 0015).
import { bil, kd, monogramOf } from './lib.mjs'
import { imageRef } from './venue-kit.mjs'
import { seeded } from '../src/engine/seeded.ts'
import { discountBps, voucherDiscountBps, voucherPrice } from '../src/engine/voucher.ts'
import { config } from './meta.mjs'
import { areas } from './areas.mjs'

export const serviceGroups = [
  { id: 'hospitality', name: bil('Hospitality and catering', 'الضيافة والتموين'), order: 1 },
  { id: 'flowers_cake', name: bil('Flowers, decor and cake', 'الزهور والديكور والكيك'), order: 2 },
  { id: 'planning', name: bil('Event planning and coordination', 'تخطيط الفعاليات وتنسيقها'), order: 3 },
  { id: 'photo_video', name: bil('Photography and video', 'التصوير والفيديو'), order: 4 },
  { id: 'music', name: bil('DJ, MC and live music', 'الدي جي والمذيع والموسيقى الحية'), order: 5 },
  { id: 'henna_makeup', name: bil('Henna and bridal makeup', 'الحناء ومكياج العروس'), order: 6 },
  { id: 'attire', name: bil('Wedding dress and suit rental', 'فستان الزفاف وتأجير البدلات'), order: 7 },
  { id: 'cars_invitations', name: bil('Luxury cars and invitations', 'السيارات الفاخرة وبطاقات الدعوة'), order: 8 },
  { id: 'travel', name: bil('Travel and honeymoon', 'السفر وشهر العسل'), order: 9 },
]

const PER_GUEST = bil('per guest', 'للضيف الواحد')
const PER_EVENT = bil('per event', 'للحفل الواحد')
const PER_SESSION = bil('per session', 'للجلسة الواحدة')
const PER_CARD = bil('per card', 'للبطاقة الواحدة')
const PER_NIGHT = bil('per night', 'لليلة الواحدة')
const PER_CAKE = bil('per cake', 'للكيكة الواحدة')
const PER_PACKAGE = bil('per package', 'للباقة الواحدة')
const PER_BOOKING = bil('per booking', 'للحجز الواحد')
const PER_DRESS = bil('per dress', 'للفستان الواحد')
const PER_SUIT = bil('per suit', 'للبدلة الواحدة')

// id, group, primary, English, Arabic, description en/ar, icon, image, [min, max] KD, unit
const categoryRows = [
  ['catering', 'hospitality', true, 'Hospitality and catering', 'الضيافة والتموين', 'Coffee, dates, sweets and family dinners for the days around the wedding.', 'قهوة وتمر وحلويات وعشاء عائلي للأيام المحيطة بالزفاف.', 'drinks', 'details/details-39-hospitality-date-coffee-gold-tray.jpg', [6, 16], PER_GUEST],
  ['buffet', 'hospitality', true, 'Buffet services', 'خدمات البوفيه', 'Full buffets and live stations, served and cleared by the provider.', 'بوفيهات كاملة ومحطات حية تُقدَّم وتُرفع بفريق المزوّد.', 'catering', 'services/services-33-buffet-gold-vase-florals.jpg', [9, 24], PER_GUEST],
  ['flowers', 'flowers_cake', true, 'Floral arrangements', 'تنسيق الزهور', 'Kosha florals, centrepieces and entrance arrangements.', 'زهور الكوشة وتنسيقات الطاولات والمدخل.', 'flower', 'details/details-03-centerpiece-lilies-roses-table.jpg', [900, 4000], PER_EVENT],
  ['decor', 'flowers_cake', true, 'Event styling and decor', 'تنسيق وديكور المناسبات', 'Stage, entrance and table styling designed to the hall.', 'تنسيق المنصة والمدخل والطاولات بتصميم يناسب القاعة.', 'decor', 'ballrooms/ballrooms-17-floral-arch-stage-draped-ceiling.jpg', [1200, 6500], PER_EVENT],
  ['event_planning', 'planning', true, 'Event planning and coordination', 'تخطيط الفعاليات وتنسيقها', 'Planners who run the schedule and the suppliers on the day.', 'منسّقون يديرون الجدول والموردين يوم الحفل.', 'calendar-check', 'context/context-42-planner-phone-cream-surface-weekly.jpg', [500, 3500], PER_EVENT],
  ['photography', 'photo_video', false, 'Photography', 'التصوير', 'Wedding-day photographers, with female teams for ladies’ halls.', 'مصوّرون ليوم الزفاف، مع فرق نسائية للقاعات النسائية.', 'camera', 'services/services-01-studio-softbox-camera.jpg', [450, 900], PER_EVENT],
  ['videography', 'photo_video', false, 'Videography', 'الفيديو', 'Highlight films and full-event coverage.', 'أفلام مختصرة وتغطية كاملة للحفل.', 'video', 'services/services-04-gimbal-rig-brick-wall.jpg', [400, 900], PER_EVENT],
  ['cake', 'flowers_cake', false, 'Cake', 'الكيك', 'Show cakes, dessert tables and favours.', 'كيك العرض وطاولات الحلويات والتوزيعات.', 'cake', 'details/details-12-cake-painted-tiers-florals-wood-table.jpg', [150, 600], PER_CAKE],
  ['dj', 'music', false, 'DJ', 'الدي جي', 'Sound systems and playlists for the ladies’ evening.', 'أنظمة صوت وقوائم موسيقى للأمسية النسائية.', 'speaker', 'services/services-07-dj-controller-amber.jpg', [250, 600], PER_EVENT],
  ['mc', 'music', false, 'MC', 'المذيع', 'Hosts who run the programme and introduce the entrance.', 'مقدّمون يديرون البرنامج ويقدّمون المدخل.', 'mic', 'services/services-46-ballroom-crystal-chandeliers.jpg', [200, 500], PER_EVENT],
  ['live_music', 'music', false, 'Live music', 'الموسيقى الحية', 'Zaffa troupes, oud and qanun players and duff ensembles.', 'فرق الزفّة وعازفو العود والقانون وفرق الدفوف.', 'music', 'services/services-11-qanun-hands-inlay.jpg', [350, 900], PER_EVENT],
  ['henna', 'henna_makeup', false, 'Henna', 'الحناء', 'Henna artists for the bride and her family.', 'فنانات حناء للعروس وأسرتها.', 'hand', 'details/details-28-henna-hand-gold-bracelet-rings.jpg', [80, 250], PER_SESSION],
  ['bridal_makeup', 'henna_makeup', false, 'Bridal makeup', 'مكياج العروس', 'Bridal makeup and hair, with a trial session.', 'مكياج وتسريحة العروس مع جلسة تجريبية.', 'brush', 'services/services-14-brush-set-dried-flowers.jpg', [150, 450], PER_SESSION],
  ['wedding_dress', 'attire', false, 'Wedding dress', 'فستان الزفاف', 'Gowns to rent or buy, with fittings and alterations.', 'فساتين للإيجار أو الشراء مع القياس والتعديل.', 'dress', 'details/details-35-dress-lace-gown-stone-arches.jpg', [300, 1800], PER_DRESS],
  ['suit_rental', 'attire', false, 'Suit rental', 'تأجير البدلات', 'Suits and bishts for the groom and his family.', 'بدلات وبشوت للعريس وأهله.', 'suit', 'services/services-28-black-tuxedo-arched-door.jpg', [80, 250], PER_SUIT],
  ['luxury_cars', 'cars_invitations', false, 'Luxury cars', 'السيارات الفاخرة', 'Decorated wedding cars with a driver.', 'سيارات زفاف مزيّنة مع سائق.', 'car', 'services/services-17-maybach-floral-bows.jpg', [120, 400], PER_EVENT],
  ['invitations', 'cars_invitations', false, 'Invitations', 'بطاقات الدعوة', 'Printed and digital invitation suites.', 'بطاقات دعوة مطبوعة ورقمية.', 'mail', 'services/services-42-blush-envelopes-gold-seals.jpg', [0.8, 6], PER_CARD],
  ['travel', 'travel', false, 'Travel', 'السفر', 'Flights, visas and family travel arrangements.', 'تذاكر وتأشيرات وترتيبات سفر العائلة.', 'plane', 'services/services-26-leather-suitcase-linen.jpg', [20, 60], PER_BOOKING],
  ['honeymoon', 'travel', false, 'Honeymoon', 'شهر العسل', 'Honeymoon packages planned by licensed agencies.', 'باقات شهر العسل من وكالات مرخّصة.', 'palm', 'services/services-23-bali-villa-pool-lush.jpg', [750, 3500], PER_PACKAGE],
]

export const serviceCategories = categoryRows.map(([id, groupId, primary, en, ar, den, dar, icon, image, [lo, hi], unit], i) => ({
  id,
  groupId,
  primary,
  name: bil(en, ar),
  description: bil(den, dar),
  icon,
  image: imageRef(image),
  anchor: { min: kd(lo), max: kd(hi), unit },
  order: i + 1,
}))

// ---------------------------------------------------------------- portfolio pools (empty rooms, objects, equipment)
const pools = {
  catering: ['details/details-39-hospitality-date-coffee-gold-tray.jpg', 'details/details-38-hospitality-dallah-dates-woven-tray.jpg', 'details/details-40-hospitality-dates-gold-tray-lantern.jpg', 'details/details-41-hospitality-dates-gold-pattern-cup.jpg', 'details/details-42-hospitality-chocolate-dates-calligraphy.jpg', 'services/services-34-gold-dallah-dates.jpg'],
  buffet: ['services/services-33-buffet-gold-vase-florals.jpg', 'services/services-37-dessert-gold-stands-orchids.jpg', 'services/services-38-dessert-glass-stand-candlelight.jpg', 'details/details-16-dessert-table-white-glass-trays.jpg', 'details/details-17-dessert-table-cake-hanging-greenery.jpg', 'details/details-01-table-gold-charger-menu-card.jpg'],
  decor: ['ballrooms/ballrooms-17-floral-arch-stage-draped-ceiling.jpg', 'ballrooms/ballrooms-16-ivory-sofas-floral-stage-detail.jpg', 'ballrooms/ballrooms-21-floral-aisle-arch-glass-roof.jpg', 'ballrooms/ballrooms-18-hotel-ballroom-gold-arch-stage-wide.jpg', 'context/context-54-hero-gold-candelabras-white-floral-tables.jpg', 'details/details-09-candles-gold-geometric-lantern-roses.jpg', 'details/details-11-lanterns-gold-moroccan-candlelight.jpg'],
  event_planning: ['context/context-42-planner-phone-cream-surface-weekly.jpg', 'context/context-41-planner-phone-open-calendar-blush-marble.jpg', 'ballrooms/ballrooms-14-skylight-vault-long-tables.jpg', 'context/context-55-hero-candlelit-long-table-chandelier.jpg'],
  photography: ['services/services-01-studio-softbox-camera.jpg', 'services/services-02-lens-leather-bag-vintage-cine.jpg', 'services/services-03-two-lenses-wood-table.jpg', 'details/details-02-table-gold-cutlery-linen.jpg', 'ballrooms/ballrooms-20-blush-gold-banquet-lattice-walls.jpg', 'details/details-22-rings-gold-bands-dark-marble.jpg'],
  videography: ['services/services-04-gimbal-rig-brick-wall.jpg', 'services/services-05-cinema-camera-rig.jpg', 'services/services-03-two-lenses-wood-table.jpg', 'ballrooms/ballrooms-14-skylight-vault-long-tables.jpg', 'context/context-55-hero-candlelit-long-table-chandelier.jpg'],
  flowers: ['details/details-03-centerpiece-lilies-roses-table.jpg', 'details/details-04-centerpiece-roses-pillar-candles.jpg', 'details/details-05-centerpiece-gold-vase-white-roses.jpg', 'details/details-06-centerpiece-ivory-roses-ivy-runner.jpg', 'details/details-07-arch-corner-florals-window-light.jpg', 'details/details-08-arch-climbing-roses-garden.jpg', 'details/details-29-bouquet-blush-roses-toile-cushion.jpg'],
  cake: ['details/details-12-cake-painted-tiers-florals-wood-table.jpg', 'details/details-13-cake-three-tier-roses-eucalyptus.jpg', 'details/details-14-cake-five-tier-sugar-flowers-blooms.jpg', 'details/details-15-cakes-orchids-crystal-stands.jpg', 'details/details-16-dessert-table-white-glass-trays.jpg', 'details/details-17-dessert-table-cake-hanging-greenery.jpg', 'details/details-18-dessert-gold-tray-truffles.jpg'],
  dj: ['services/services-07-dj-controller-amber.jpg', 'ballrooms/ballrooms-11-chandelier-hall-polished-floor.jpg', 'ballrooms/ballrooms-18-hotel-ballroom-gold-arch-stage-wide.jpg'],
  mc: ['services/services-46-ballroom-crystal-chandeliers.jpg', 'services/services-45-string-lights-chandeliers-lawn.jpg', 'ballrooms/ballrooms-18-hotel-ballroom-gold-arch-stage-wide.jpg'],
  live_music: ['services/services-11-qanun-hands-inlay.jpg', 'services/services-08-oud-lace-curtain.jpg', 'services/services-09-oud-ney-lavender-linen.jpg', 'services/services-10-oud-wall-light.jpg', 'services/services-12-violin-scroll.jpg', 'services/services-13-darbuka-gold-floral.jpg'],
  henna: ['details/details-28-henna-hand-gold-bracelet-rings.jpg', 'details/details-27-henna-bridal-hands-lace-sleeves.jpg', 'details/details-45-attar-oud-oil-bottles-stone.jpg', 'details/details-43-incense-silver-burner-smoke.jpg'],
  bridal_makeup: ['services/services-14-brush-set-dried-flowers.jpg', 'services/services-15-blush-tubes-brush.jpg', 'halls/halls-29-bridal-dressing-room-vanity.jpg', 'details/details-32-bouquet-pearls-glitter-heels-blush-satin.jpg'],
  wedding_dress: ['details/details-35-dress-lace-gown-stone-arches.jpg', 'details/details-36-dress-satin-gown-warm-wall-light.jpg', 'details/details-37-dress-lace-bodice-garden.jpg', 'halls/halls-30-bridal-gown-lace-window.jpg', 'halls/halls-34-bridal-gown-sheer-curtains.jpg', 'details/details-33-shoes-satin-bow-heels.jpg'],
  suit_rental: ['services/services-28-black-tuxedo-arched-door.jpg', 'services/services-29-embellished-tuxedo-arch.jpg', 'services/services-30-cream-blazer-bridge.jpg'],
  luxury_cars: ['services/services-17-maybach-floral-bows.jpg', 'services/services-18-white-ghost-alley.jpg', 'services/services-20-car-interior-blush-flowers.jpg'],
  invitations: ['services/services-42-blush-envelopes-gold-seals.jpg', 'services/services-43-rose-envelope-gold-seal.jpg', 'services/services-44-black-envelopes-gold-seals.jpg', 'details/details-19-stationery-gold-foil-invitations-pearls.jpg', 'details/details-20-stationery-blush-calligraphy-suite.jpg'],
  travel: ['services/services-26-leather-suitcase-linen.jpg', 'services/services-24-swiss-lake-dusk.jpg', 'services/services-23-bali-villa-pool-lush.jpg'],
  honeymoon: ['services/services-23-bali-villa-pool-lush.jpg', 'services/services-24-swiss-lake-dusk.jpg', 'services/services-26-leather-suitcase-linen.jpg', 'details/details-24-rings-blush-roses-bouquet.jpg'],
}

// ---------------------------------------------------------------- package templates by category: [name en, name ar, includes[]]
const T = (en, ar, inc) => ({ en, ar, inc })
const templates = {
  photography: [
    T('Wedding-day coverage · 6 hours', 'تغطية يوم الزفاف · 6 ساعات', [['Photographer for 6 hours', 'مصوّرة لمدة 6 ساعات'], ['Edited gallery within 3 weeks', 'معرض صور معدّل خلال 3 أسابيع']]),
    T('8 hours + album', '8 ساعات مع ألبوم', [['Photographer for 8 hours', 'مصوّرة لمدة 8 ساعات'], ['Printed album', 'ألبوم مطبوع'], ['Edited gallery within 3 weeks', 'معرض صور معدّل خلال 3 أسابيع']]),
    T('Full day + album + highlight video', 'يوم كامل مع ألبوم وفيديو مختصر', [['Photographer for the full day', 'مصوّرة ليوم كامل'], ['Printed album', 'ألبوم مطبوع'], ['Highlight video', 'فيديو مختصر']]),
  ],
  videography: [
    T('Highlight film', 'فيلم مختصر', [['Highlight film of 3 to 4 minutes', 'فيلم مختصر من 3 إلى 4 دقائق'], ['One videographer', 'مصوّر فيديو واحد']]),
    T('Event film', 'فيلم الحفل', [['Full-event coverage', 'تغطية كاملة للحفل'], ['Highlight film', 'فيلم مختصر'], ['Two cameras', 'كاميرتان']]),
    T('Cinematic film + teaser', 'فيلم سينمائي مع مقطع تشويقي', [['Two videographers', 'مصوّرا فيديو'], ['Cinematic edit', 'مونتاج سينمائي'], ['Social teaser', 'مقطع تشويقي']]),
  ],
  flowers: [
    T('Entrance and tables', 'المدخل والطاولات', [['Entrance arrangement', 'تنسيق المدخل'], ['Table centrepieces', 'تنسيقات الطاولات']]),
    T('Kosha florals', 'زهور الكوشة', [['Kosha floral styling', 'تنسيق زهور الكوشة'], ['Aisle arrangement', 'تنسيق الممر']]),
    T('Full hall florals', 'زهور القاعة كاملة', [['Kosha, aisle and entrance', 'الكوشة والممر والمدخل'], ['Table centrepieces', 'تنسيقات الطاولات'], ['Setup and removal', 'التركيب والإزالة']]),
  ],
  cake: [
    T('Show cake', 'كيكة العرض', [['One tiered show cake', 'كيكة عرض متعددة الطبقات'], ['Delivery to the venue', 'التوصيل إلى المكان']]),
    T('Cake and dessert table', 'الكيك وطاولة الحلويات', [['Show cake', 'كيكة العرض'], ['Dessert table', 'طاولة حلويات']]),
    T('Cake, desserts and favours', 'الكيك والحلويات والتوزيعات', [['Show cake', 'كيكة العرض'], ['Dessert table', 'طاولة حلويات'], ['Guest favours', 'توزيعات للضيوف']]),
  ],
  dj: [
    T('Evening sound', 'صوت الأمسية', [['DJ for 4 hours', 'دي جي لمدة 4 ساعات'], ['Sound system for the hall', 'نظام صوت للقاعة']]),
    T('Sound and lighting', 'صوت وإضاءة', [['DJ for 5 hours', 'دي جي لمدة 5 ساعات'], ['Sound and stage lighting', 'صوت وإضاءة للمنصة']]),
  ],
  mc: [
    T('Evening host', 'مقدّمة الأمسية', [['Host for the programme', 'مقدّمة للبرنامج'], ['Entrance introduction', 'تقديم المدخل']]),
    T('Host and programme planning', 'تقديم وتخطيط البرنامج', [['Host for the evening', 'مقدّمة للأمسية'], ['Programme planning meeting', 'اجتماع لتخطيط البرنامج']]),
  ],
  live_music: [
    T('Zaffa entrance', 'مدخل الزفّة', [['Troupe for the entrance', 'فرقة لمدخل الزفّة'], ['Rehearsal with the venue', 'بروفة مع القاعة']]),
    T('Zaffa and live set', 'الزفّة وفقرة حية', [['Zaffa entrance', 'مدخل الزفّة'], ['One-hour live set', 'فقرة حية لمدة ساعة']]),
    T('Full evening ensemble', 'فرقة الأمسية كاملة', [['Zaffa entrance', 'مدخل الزفّة'], ['Two live sets', 'فقرتان حيتان'], ['Sound check', 'فحص الصوت']]),
  ],
  henna: [
    T('Bride henna', 'حناء العروس', [['Bridal henna design', 'نقش حناء للعروس'], ['Session of 2 hours', 'جلسة مدتها ساعتان']]),
    T('Bride and family', 'العروس والأسرة', [['Bridal henna design', 'نقش حناء للعروس'], ['Henna for up to 6 guests', 'حناء لـ 6 ضيوف كحد أقصى']]),
  ],
  bridal_makeup: [
    T('Bridal makeup', 'مكياج العروس', [['Bridal makeup', 'مكياج العروس'], ['Lashes and finishing', 'رموش ولمسات أخيرة']]),
    T('Makeup and hair', 'مكياج وتسريحة', [['Bridal makeup', 'مكياج العروس'], ['Bridal hair', 'تسريحة العروس']]),
    T('Trial and wedding day', 'تجربة ويوم الزفاف', [['Trial session', 'جلسة تجريبية'], ['Makeup and hair on the day', 'مكياج وتسريحة يوم الزفاف']]),
  ],
  wedding_dress: [
    T('Gown rental', 'إيجار فستان', [['Gown for 3 days', 'فستان لمدة 3 أيام'], ['One fitting', 'قياس واحد']]),
    T('Gown rental with alterations', 'إيجار فستان مع التعديل', [['Gown for 3 days', 'فستان لمدة 3 أيام'], ['Two fittings and alterations', 'قياسان وتعديل']]),
    T('Made-to-order gown', 'فستان بالطلب', [['Designed gown', 'فستان مصمم'], ['Three fittings', 'ثلاثة قياسات']]),
  ],
  suit_rental: [
    T('Suit rental', 'تأجير بدلة', [['Suit for 2 days', 'بدلة لمدة يومين'], ['Fitting', 'قياس']]),
    T('Suit and bisht', 'بدلة وبشت', [['Suit and bisht', 'بدلة وبشت'], ['Fitting and pressing', 'قياس وكوي']]),
  ],
  luxury_cars: [
    T('Bridal car', 'سيارة العروس', [['Decorated car with driver for 3 hours', 'سيارة مزيّنة مع سائق لمدة 3 ساعات']]),
    T('Bridal car and escort', 'سيارة العروس ومرافقة', [['Decorated car with driver', 'سيارة مزيّنة مع سائق'], ['Escort car', 'سيارة مرافقة']]),
  ],
  invitations: [
    T('Printed cards', 'بطاقات مطبوعة', [['Minimum 100 cards', 'الحد الأدنى 100 بطاقة'], ['Envelopes included', 'المظاريف مشمولة']]),
    T('Printed cards with foil', 'بطاقات مطبوعة بالرقائق الذهبية', [['Minimum 100 cards', 'الحد الأدنى 100 بطاقة'], ['Gold foil', 'رقائق ذهبية']]),
  ],
  catering: [
    T('Coffee and dates', 'القهوة والتمر', [['Arabic coffee and dates service', 'خدمة القهوة العربية والتمر'], ['Serving team and cups', 'فريق خدمة وفناجين']]),
    T('Hospitality and sweets', 'ضيافة وحلويات', [['Coffee, tea and dates', 'قهوة وشاي وتمر'], ['Sweets and chocolates', 'حلويات وشوكولاتة'], ['Serving team', 'فريق خدمة']]),
    T('Family dinner hospitality', 'ضيافة العشاء العائلي', [['Welcome hospitality', 'ضيافة الاستقبال'], ['Hot dinner for the family', 'عشاء ساخن للعائلة'], ['Serving team and cleanup', 'فريق خدمة وتنظيف']]),
  ],
  buffet: [
    T('Classic buffet', 'بوفيه كلاسيكي', [['Hot and cold stations', 'محطات ساخنة وباردة'], ['Service team', 'فريق تقديم']]),
    T('Buffet with live stations', 'بوفيه مع محطات حية', [['Classic buffet', 'بوفيه كلاسيكي'], ['Two live stations', 'محطتان حيتان'], ['Dessert table', 'طاولة حلويات']]),
    T('Grand buffet', 'البوفيه الكبير', [['Extended buffet with carving station', 'بوفيه موسّع مع محطة تقطيع'], ['Live stations', 'محطات حية'], ['Dessert and coffee corner', 'ركن حلويات وقهوة']]),
  ],
  decor: [
    T('Entrance and tables', 'المدخل والطاولات', [['Entrance styling', 'تنسيق المدخل'], ['Table styling', 'تنسيق الطاولات']]),
    T('Stage styling', 'تنسيق المنصة', [['Stage and backdrop design', 'تصميم المنصة والخلفية'], ['Lighting accents', 'لمسات إضاءة']]),
    T('Full hall styling', 'تنسيق القاعة كاملة', [['Stage, entrance and tables', 'المنصة والمدخل والطاولات'], ['Design meeting and mood board', 'اجتماع تصميم ولوحة إلهام'], ['Setup and removal', 'التركيب والإزالة']]),
  ],
  event_planning: [
    T('Day-of coordination', 'تنسيق يوم الحفل', [['Coordinator on the day', 'منسّقة يوم الحفل'], ['Run-of-show timeline', 'جدول زمني لسير الحفل']]),
    T('Planning and coordination', 'التخطيط والتنسيق', [['Planning from booking', 'التخطيط من تاريخ الحجز'], ['Supplier follow-up', 'متابعة الموردين'], ['Coordinator on the day', 'منسّقة يوم الحفل']]),
    T('Full event management', 'إدارة الفعالية كاملة', [['Planning and supplier booking', 'التخطيط وحجز الموردين'], ['Design concept', 'فكرة التصميم'], ['Team on the day', 'فريق يوم الحفل']]),
  ],
  travel: [
    T('Ticket and visa service', 'خدمة التذاكر والتأشيرات', [['Booking support', 'مساعدة في الحجز']]),
    T('Family travel plan', 'خطة سفر للعائلة', [['Flights and transfers for a family', 'رحلات وتنقلات لعائلة']]),
  ],
  honeymoon: [
    T('Week by the sea', 'أسبوع على البحر', [['Seven nights', 'سبع ليالٍ'], ['Flights and transfers', 'رحلات وتنقلات']]),
    T('Two-city honeymoon', 'شهر عسل بمدينتين', [['Ten nights', 'عشر ليالٍ'], ['Flights and transfers', 'رحلات وتنقلات'], ['Private guide', 'مرشد خاص']]),
  ],
}


const cat = (id) => serviceCategories.find((c) => c.id === id)
const roundTo = (n, step) => Math.round(n / step) * step
const areaById = new Map(areas.map((a) => [a.id, a]))

/** Categories priced per guest (a per-person structure) and their minimum quantities. */
const PER_PERSON = new Set(['catering', 'buffet'])
const MIN_QTY = { catering: 50, buffet: 100, invitations: 100 }
/** Voucher rounding step in fils by category: per guest KD 0.5, per card KD 0.05, everything else KD 5. */
const stepOf = (categoryId) => (PER_PERSON.has(categoryId) ? 500 : categoryId === 'invitations' ? 50 : 5000)

// [categoryId, key, English, Arabic, area, average|null, count, fromKD, femaleTeam, repliesHours, also[], tags[[en, ar]]]
const providerRows = [
  // ---- primary: hospitality and catering (5)
  ['catering', 'qahwat-diwan', 'Qahwat Al-Diwan Hospitality', 'ضيافة قهوة الديوان', 'salmiya', 4.7, 61, 7.5, true, 2, [], [['Female serving team for ladies’ halls', 'فريق خدمة نسائي للقاعات النسائية']]],
  ['catering', 'mouna', 'Mouna Catering', 'مؤونة للتموين', 'jabriya', 4.6, 44, 9, true, 3, [], []],
  ['catering', 'sufra-bayt', 'Sufrat Al-Bayt Kitchen', 'مطبخ سفرة البيت', 'farwaniya', 4.4, 27, 6.5, false, 4, [], []],
  ['catering', 'najma', 'Najma Hospitality', 'نجمة للضيافة', 'hawalli', 4.5, 35, 8, true, 3, [], []],
  ['catering', 'bayt-karam', 'Bayt Al-Karam Catering', 'بيت الكرم للتموين', 'sharq', null, 0, 11, true, 5, [], []],
  // ---- primary: buffet services (4)
  ['buffet', 'masaya', 'Masaya Buffets', 'بوفيهات مساء', 'mishref', 4.7, 52, 12, false, 3, [], []],
  ['buffet', 'mazaj', 'Mazaj Live Stations', 'محطات مزاج الحية', 'salmiya', 4.5, 38, 14, false, 4, [], []],
  ['buffet', 'sinia', 'Sinia Buffet House', 'بيت صينية للبوفيه', 'jahra', 4.4, 22, 9.5, false, 5, [], []],
  ['buffet', 'mawaid', 'Mawaid Buffets', 'موائد للبوفيهات', 'hawalli', null, 0, 10, false, 6, [], []],
  // ---- primary: floral arrangements (5)
  ['flowers', 'nakheel-blooms', 'Nakheel Blooms', 'زهور النخيل', 'jabriya', 4.6, 51, 900, false, 3, [], []],
  ['flowers', 'warda', 'Warda Atelier', 'مشغل وردة', 'sharq', 4.8, 36, 1400, false, 4, [], []],
  ['flowers', 'hadiqa', 'Hadiqa Flowers', 'حديقة الزهور', 'khaitan', 4.3, 40, 950, false, 5, [], []],
  ['flowers', 'bustan-roses', 'Bustan Roses', 'ورود البستان', 'salmiya', null, 0, 900, false, 6, [], []],
  ['flowers', 'zahra', 'Zahra Floral Studio', 'استوديو زهرة للزهور', 'zahra', 4.6, 24, 950, false, 2, [], [['Kosha and entrance florals', 'زهور الكوشة والمدخل']]],
  // ---- primary: event styling and decor (4)
  ['decor', 'lamset', 'Lamset Decor', 'لمسة للديكور', 'sharq', 4.8, 57, 1800, false, 3, [], []],
  ['decor', 'masrah', 'Masrah Events Styling', 'مسرح لتنسيق المناسبات', 'salmiya', 4.6, 41, 2500, false, 4, [], []],
  ['decor', 'zakhrafa', 'Zakhrafa Studio', 'استوديو زخرفة', 'jabriya', 4.4, 19, 1500, false, 4, [], []],
  ['decor', 'rawaa', 'Rawaa Decor', 'روعة للديكور', 'khaitan', null, 0, 1300, false, 6, [], []],
  // ---- primary: event planning and coordination (4)
  ['event_planning', 'tanseeq', 'Tanseeq Events', 'تنسيق للفعاليات', 'sharq', 4.7, 33, 900, true, 2, [], [['Female coordinators for ladies’ halls', 'منسّقات للقاعات النسائية']]],
  ['event_planning', 'khutwa', 'Khutwa Wedding Coordination', 'خطوة لتنسيق الأفراح', 'hawalli', 4.6, 28, 650, true, 3, [], []],
  ['event_planning', 'ihtifal', 'Ihtifal Planning House', 'بيت احتفال للتخطيط', 'salmiya', 4.5, 21, 1200, true, 4, [], []],
  ['event_planning', 'silsila', 'Silsila Events', 'سلسلة للمناسبات', 'farwaniya', null, 0, 700, true, 5, [], []],
  // ---- secondary (two each)
  ['photography', 'lamha', 'Lamha Photography Studio', 'استوديو لمحة للتصوير', 'salmiya', 4.7, 58, 450, true, 2, ['videography'], [['Female team for ladies’ halls', 'فريق نسائي للقاعات النسائية']]],
  ['photography', 'gulf-lens', 'Gulf Lens Studio', 'عدسة الخليج للتصوير', 'jabriya', 4.5, 31, 600, true, 3, [], []],
  ['videography', 'daw', 'Daw Video Production', 'ضوء للإنتاج المرئي', 'shuwaikh', 4.6, 44, 700, false, 3, [], []],
  ['videography', 'rawi', 'Rawi Films', 'روي للأفلام', 'rumaithiya', 4.4, 19, 600, false, 4, [], []],
  ['cake', 'kaak', 'Kaak Atelier', 'مشغل الكيك', 'salmiya', 4.7, 64, 250, false, 2, [], []],
  ['cake', 'layali', 'Layali Sweets', 'حلويات ليالي', 'hawalli', 4.5, 48, 150, false, 3, [], []],
  ['dj', 'sawt', 'Sawt Events', 'صوت للمناسبات', 'salmiya', 4.5, 33, 250, true, 3, [], []],
  ['dj', 'nabdh', 'Nabdh DJ', 'نبض دي جي', 'hawalli', 4.6, 29, 350, true, 2, [], []],
  ['mc', 'kalima', 'Kalima Hosting', 'كلمة للتقديم', 'sharq', 4.6, 21, 200, true, 3, [], []],
  ['mc', 'majlis-voices', 'Majlis Voices', 'أصوات المجلس', 'jabriya', 4.4, 16, 250, false, 4, [], []],
  ['live_music', 'zaffa-khaleej', 'Zaffa Al-Khaleej Troupe', 'فرقة زفّة الخليج', 'salmiya', 4.7, 39, 350, true, 3, [], []],
  ['live_music', 'oud-evenings', 'Oud Evenings', 'أمسيات العود', 'sharq', 4.8, 18, 500, true, 4, [], []],
  ['henna', 'naqsh', 'Naqsh Henna', 'نقش للحناء', 'salmiya', 4.8, 72, 80, true, 2, [], []],
  ['henna', 'hinnaa', 'Hinnaa Studio', 'استوديو حنّاء', 'jabriya', 4.6, 41, 100, true, 3, [], []],
  ['bridal_makeup', 'glow', 'Glow Atelier', 'غلو للمكياج', 'salmiya', 4.7, 88, 250, true, 2, [], []],
  ['bridal_makeup', 'lamsat', 'Lamsat Beauty', 'لمسات للجمال', 'hawalli', 4.5, 57, 150, true, 3, [], []],
  ['wedding_dress', 'dar-farah', 'Dar Al-Farah Gowns', 'دار الفرح للفساتين', 'sharq', 4.6, 37, 400, true, 4, [], []],
  ['wedding_dress', 'lace-pearl', 'Lace and Pearl', 'دانتيل ولؤلؤ', 'salmiya', 4.7, 29, 600, true, 3, [], []],
  ['suit_rental', 'sharaf', 'Sharaf Suits', 'بدلات الشرف', 'hawalli', 4.5, 26, 80, false, 3, [], []],
  ['suit_rental', 'bisht-diwan', 'Bisht Al-Diwan', 'بشت الديوان', 'farwaniya', 4.6, 32, 120, false, 4, [], []],
  ['luxury_cars', 'raqi', 'Raqi Limousines', 'راقي للسيارات الفاخرة', 'hawalli', 4.6, 35, 150, false, 2, [], []],
  ['luxury_cars', 'zaffa-cars', 'Zaffa Cars', 'سيارات الزفّة', 'salmiya', 4.4, 21, 120, false, 3, [], []],
  ['invitations', 'dawat', 'Dawat Atelier', 'مشغل دعوة', 'sharq', 4.7, 46, 0.8, false, 3, [], []],
  ['invitations', 'waraq', 'Waraq Studio', 'استوديو ورق', 'salmiya', 4.5, 30, 1.2, false, 4, [], []],
  ['travel', 'rihla', 'Rihla Travel', 'رحلة للسفر', 'hawalli', 4.6, 52, 25, false, 3, [], []],
  ['travel', 'ufuq', 'Ufuq Tours', 'أفق للسياحة', 'salmiya', 4.4, 33, 30, false, 4, [], []],
  ['honeymoon', 'qamar', 'Qamar Honeymoons', 'قمر لشهر العسل', 'sharq', 4.8, 41, 900, false, 3, [], []],
  ['honeymoon', 'jazira', 'Jazira Escapes', 'جزيرة للرحلات', 'salmiya', 4.6, 28, 750, false, 4, [], []],
]

/** Two prices per package: the standard price and the provider's voucher price (15% to 35% lower, deterministic per provider). */
function priced(providerId, categoryId, priceKd) {
  const std = Math.round(priceKd * 1000)
  const bps = voucherDiscountBps(providerId, config.seedVoucherDiscountBps)
  const vch = voucherPrice(std, bps, stepOf(categoryId), config.seedVoucherDiscountBps)
  return { price: kd(std / 1000), voucherPrice: kd(vch / 1000) }
}

function providerPackages(providerId, categoryId, key, fromKd) {
  const list = templates[categoryId]
  const perGuest = PER_PERSON.has(categoryId)
  const factors = perGuest ? [1, 1.35, 1.8] : list.length === 3 ? [1, 1.45, 2] : [1, 1.6]
  return list.map((t, i) => {
    const step = categoryId === 'invitations' ? 0.1 : perGuest ? 0.5 : 5
    const raw = fromKd * factors[i]
    const price = categoryId === 'invitations' ? Math.round(raw * 10) / 10 : roundTo(raw, step)
    return {
      id: `vp-${categoryId}-${key}-${i + 1}`,
      name: bil(t.en, t.ar),
      ...priced(providerId, categoryId, price),
      unit: cat(categoryId).anchor.unit,
      priceStructure: perGuest ? 'per_person' : 'package',
      minQuantity: MIN_QTY[categoryId] ?? null,
      includes: t.inc.map(([en, ar]) => bil(en, ar)),
    }
  })
}

const LAMHA_PACKAGES = [
  { id: 'vp-photography-lamha-1', name: bil('Wedding-day coverage · 6 hours', 'تغطية يوم الزفاف · 6 ساعات'), kdPrice: 450, includes: [bil('Female photographer for 6 hours', 'مصوّرة لمدة 6 ساعات'), bil('Edited gallery within 3 weeks', 'معرض صور معدّل خلال 3 أسابيع')] },
  { id: 'vp-photography-lamha-2', name: bil('8 hours + album', '8 ساعات مع ألبوم'), kdPrice: 650, includes: [bil('Female photographer for 8 hours', 'مصوّرة لمدة 8 ساعات'), bil('Printed album', 'ألبوم مطبوع'), bil('Edited gallery within 3 weeks', 'معرض صور معدّل خلال 3 أسابيع')] },
  { id: 'vp-photography-lamha-3', name: bil('Full day + album + highlight video', 'يوم كامل مع ألبوم وفيديو مختصر'), kdPrice: 900, includes: [bil('Photographer for the full day', 'مصوّرة ليوم كامل'), bil('Printed album', 'ألبوم مطبوع'), bil('Highlight video', 'فيديو مختصر')] },
]

const aboutByCategory = {
  catering: bil('Hospitality teams for the family gatherings around the wedding: coffee, dates, sweets and dinner.', 'فرق ضيافة لتجمعات العائلة حول الزفاف: قهوة وتمر وحلويات وعشاء.'),
  buffet: bil('Buffets and live stations served and cleared by the provider’s own team.', 'بوفيهات ومحطات حية يقدّمها ويرفعها فريق المزوّد نفسه.'),
  flowers: bil('Florists who design to the hall and the kosha.', 'منسقو زهور يصممون بحسب القاعة والكوشة.'),
  decor: bil('Stylists who design the stage, entrance and tables to the hall.', 'منسّقون يصممون المنصة والمدخل والطاولات بحسب القاعة.'),
  event_planning: bil('Coordinators who run the schedule and the suppliers so the family can enjoy the evening.', 'منسّقون يديرون الجدول والموردين لتستمتع العائلة بالأمسية.'),
  photography: bil('Photographers who work in empty halls and details first, then guests only where the family agrees.', 'مصوّرون يبدأون بالقاعة والتفاصيل، ثم الضيوف فقط حيث توافق العائلة.'),
  videography: bil('Film teams with quiet equipment and a short edit turnaround.', 'فرق تصوير بمعدات هادئة وتسليم سريع للمونتاج.'),
  cake: bil('Show cakes and dessert tables made to order.', 'كيك عرض وطاولات حلويات بالطلب.'),
  dj: bil('Sound and playlists that suit a ladies’ evening.', 'صوت وقوائم موسيقى تناسب الأمسية النسائية.'),
  mc: bil('Hosts who keep the programme calm and on time.', 'مقدّمون يحافظون على هدوء البرنامج والتزامه بالوقت.'),
  live_music: bil('Troupes and players for the entrance and live sets.', 'فرق وعازفون للمدخل والفقرات الحية.'),
  henna: bil('Henna artists with fine, traditional and modern designs.', 'فنانات حناء بنقوش دقيقة تقليدية وحديثة.'),
  bridal_makeup: bil('Bridal makeup and hair, with a trial before the day.', 'مكياج وتسريحة للعروس مع تجربة قبل الحفل.'),
  wedding_dress: bil('Gowns to rent or order, with fittings.', 'فساتين للإيجار أو الطلب مع القياس.'),
  suit_rental: bil('Suits and bishts for the groom and family.', 'بدلات وبشوت للعريس والأسرة.'),
  luxury_cars: bil('Decorated cars with experienced drivers.', 'سيارات مزيّنة مع سائقين ذوي خبرة.'),
  invitations: bil('Invitation suites printed with fine papers.', 'بطاقات دعوة مطبوعة على ورق فاخر.'),
  travel: bil('Flights, visas and travel plans for families.', 'رحلات وتأشيرات وخطط سفر للعائلات.'),
  honeymoon: bil('Honeymoon packages from licensed agencies.', 'باقات شهر العسل من وكالات مرخّصة.'),
}

export const providers = providerRows.map(([categoryId, key, en, ar, area, avg, count, from, female, replies, also, tags], idx) => {
  const id = `vendor-${categoryId}-${key}`
  const pool = pools[categoryId]
  const start = Math.floor(seeded('pf', categoryId, key) * pool.length)
  const take = Math.min(pool.length, 4)
  const portfolio = Array.from({ length: take }, (_, i) => imageRef(pool[(start + i) % pool.length]))
  const packages =
    key === 'lamha'
      ? LAMHA_PACKAGES.map((p) => ({ id: p.id, name: p.name, ...priced(id, categoryId, p.kdPrice), unit: PER_EVENT, priceStructure: 'package', minQuantity: null, includes: p.includes }))
      : providerPackages(id, categoryId, key, from)
  const lowest = packages.reduce((m, p) => (p.price.fils < m.price.fils ? p : m))
  const lowestV = packages.reduce((m, p) => (p.voucherPrice && (!m || p.voucherPrice.fils < m.fils) ? p.voucherPrice : m), null)
  return {
    id,
    categoryId,
    alsoCategoryIds: also,
    name: bil(en, ar),
    monogram: monogramOf(ar),
    areaId: area,
    governorateId: areaById.get(area).governorateId,
    partnerAccountId: `partner-${id}`,
    about:
      key === 'lamha'
        ? bil('A Salmiya studio that photographs empty halls, decor and details first. Female photographers are available for ladies’ halls.', 'استوديو في السالمية يبدأ بتصوير القاعات الفارغة والديكور والتفاصيل. تتوفر مصوّرات للقاعات النسائية.')
        : key === 'zahra'
          ? bil('A Hawalli floral studio for kosha, entrance and table florals, designed to the hall and the colours of the family.', 'استوديو زهور في حولي لزهور الكوشة والمدخل والطاولات، بتصميم يناسب القاعة وألوان العائلة.')
          : aboutByCategory[categoryId],
    rating: avg === null ? null : { average: avg, count },
    from: lowest.price,
    fromVoucher: lowestV,
    fromUnit: cat(categoryId).anchor.unit,
    packages,
    portfolio,
    tags: tags.map(([e, a]) => bil(e, a)),
    femaleTeamForLadies: female,
    usuallyRepliesHours: replies,
    verified: avg !== null,
    phone: key === 'zahra' ? '+96550000147' : `+9655000${String(200 + idx).padStart(4, '0')}`,
  }
})

/** Realised discount of a provider headline, for the validator. */
export const providerDiscountBps = (p) => (p.fromVoucher ? discountBps(p.from.fils, p.fromVoucher.fils) : null)
