// Wedding planners: tier packages (platform-level, configured in Super Admin) and the planners who deliver them.
// Silver, Gold and Royal belong to planners only, never to venues (glossary). Tier is signalled by one, two or three
// thread marks, not metallic colour. Planner fees are settled with the planner off-app (ADR 0033: no deposit in the app).
import { bil, kd } from './lib.mjs'
import { imageRef } from './venue-kit.mjs'

export const plannerPackages = [
  {
    id: 'planner-silver',
    tier: 'silver',
    name: bil('Silver', 'الفضية'),
    tagline: bil('Day-of coordination', 'تنسيق يوم الحفل'),
    marks: 1,
    from: kd(650),
    inclusions: [
      bil('Coordinator on the day', 'منسّقة يوم الحفل'),
      bil('Run-of-show timeline', 'جدول زمني لسير الحفل'),
      bil('Vendor arrival checks', 'متابعة وصول الموردين'),
      bil('Venue walkthrough', 'جولة تفقد في القاعة'),
    ],
    suits: bil('Couples who have planned everything and want a calm day', 'لأزواج أنهوا كل التحضيرات ويريدون يومًا هادئًا'),
    image: imageRef('context/context-42-planner-phone-cream-surface-weekly.jpg'),
  },
  {
    id: 'planner-gold',
    tier: 'gold',
    name: bil('Gold', 'الذهبية'),
    tagline: bil('Planning and styling', 'تخطيط وتنسيق'),
    marks: 2,
    from: kd(1900),
    inclusions: [
      bil('Everything in Silver', 'كل ما في الفضية'),
      bil('Planning from the booking date', 'التخطيط من تاريخ الحجز'),
      bil('Vendor shortlist and quotes', 'قائمة موردين وعروض أسعار'),
      bil('Styling concept and moodboard', 'فكرة التنسيق ولوحة الإلهام'),
      bil('Two planning meetings', 'اجتماعا تخطيط'),
    ],
    suits: bil('Couples who want help choosing and styling, with a plan to follow', 'لأزواج يريدون مساعدة في الاختيار والتنسيق مع خطة واضحة'),
    image: imageRef('context/context-41-planner-phone-open-calendar-blush-marble.jpg'),
  },
  {
    id: 'planner-royal',
    tier: 'royal',
    name: bil('Royal', 'الملكية'),
    tagline: bil('Full design and production', 'تصميم وإنتاج متكامل'),
    marks: 3,
    from: kd(5500),
    inclusions: [
      bil('Everything in Gold', 'كل ما في الذهبية'),
      bil('Bespoke kosha and decor design', 'تصميم مخصص للكوشة والديكور'),
      bil('Production management', 'إدارة الإنتاج'),
      bil('Vendor contracting', 'التعاقد مع الموردين'),
      bil('A dedicated planner team', 'فريق تخطيط مخصص'),
    ],
    suits: bil('Couples who want the whole wedding designed and produced for them', 'لأزواج يريدون تصميم الزفاف وإنتاجه بالكامل'),
    image: imageRef('context/context-53-hero-staircase-blush-roses-copper-lanterns.jpg'),
  },
]

export const plannerUsers = [
  { id: 'user-planner-nouf', role: 'planner', name: 'نوف العتيبي', nameLatin: 'Nouf Al-Otaibi', monogram: 'ن', phone: '+96550000050', email: null, locale: 'ar', digitStyle: 'western', createdAt: '2026-01-10T09:00:00+03:00' },
  { id: 'user-planner-shahd', role: 'planner', name: 'شهد المطيري', nameLatin: 'Shahd Al-Mutairi', monogram: 'ش', phone: '+96550000051', email: null, locale: 'ar', digitStyle: 'western', createdAt: '2026-01-10T09:00:00+03:00' },
  { id: 'user-planner-mariam', role: 'planner', name: 'مريم الصباغ', nameLatin: 'Mariam Al-Sabbagh', monogram: 'م', phone: '+96550000052', email: null, locale: 'en', digitStyle: 'western', createdAt: '2026-02-01T09:00:00+03:00' },
]

export const planners = [
  {
    id: 'planner-nouf',
    userId: 'user-planner-nouf',
    name: bil('Nouf Al-Otaibi', 'نوف العتيبي'),
    role: bil('Wedding planner', 'منسّقة أعراس'),
    monogram: 'ن',
    tiers: ['silver', 'gold', 'royal'],
    languages: ['ar', 'en'],
    about: bil('Plans ladies’ receptions in five-star hotels, with a focus on kosha design and run-of-show.', 'تخطط للحفلات النسائية في الفنادق الكبرى مع تركيز على تصميم الكوشة وسير البرنامج.'),
    yearsExperience: 9,
  },
  {
    id: 'planner-shahd',
    userId: 'user-planner-shahd',
    name: bil('Shahd Al-Mutairi', 'شهد المطيري'),
    role: bil('Wedding planner', 'منسّقة أعراس'),
    monogram: 'ش',
    tiers: ['silver', 'gold'],
    languages: ['ar'],
    about: bil('Day-of coordination and vendor management for family weddings.', 'تنسيق يوم الحفل وإدارة الموردين لأفراح العائلات.'),
    yearsExperience: 6,
  },
  {
    id: 'planner-mariam',
    userId: 'user-planner-mariam',
    name: bil('Mariam Al-Sabbagh', 'مريم الصباغ'),
    role: bil('Production planner', 'منسّقة إنتاج'),
    monogram: 'م',
    tiers: ['gold', 'royal'],
    languages: ['ar', 'en'],
    about: bil('Leads full design and production for large weddings.', 'تقود التصميم والإنتاج الكامل للأفراح الكبيرة.'),
    yearsExperience: 12,
  },
]
