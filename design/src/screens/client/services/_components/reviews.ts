// Prototype fixtures: three recent reviews for a reviewed vendor (CA-SVC-10). Service-neutral wording so they read true for any
// category; first name plus initial only, monogram avatars, dates before the prototype's today.
import type { Bilingual } from '../../../../mock'

export type VendorReview = { id: string; author: Bilingual; date: string; rating: number; text: Bilingual }

export const VENDOR_REVIEWS: readonly VendorReview[] = [
  {
    id: 'vr-1',
    author: { ar: 'نورة ع.', en: 'Noura A.' },
    date: '2026-09-18',
    rating: 5,
    text: {
      ar: 'وصلوا قبل الموعد وكان الفريق مرتبًا ومحترمًا. النتيجة فاقت ما توقعناه.',
      en: 'The team arrived early, tidy and respectful. The result was better than we hoped.',
    },
  },
  {
    id: 'vr-2',
    author: { ar: 'فاطمة ك.', en: 'Fatima K.' },
    date: '2026-08-30',
    rating: 4.5,
    text: {
      ar: 'تواصل واضح من أول رسالة، والتسليم كان في الوقت المتفق عليه.',
      en: 'Clear from the first message, and everything was delivered when agreed.',
    },
  },
  {
    id: 'vr-3',
    author: { ar: 'مريم ش.', en: 'Maryam S.' },
    date: '2026-07-22',
    rating: 5,
    text: {
      ar: 'استمعوا لكل تفصيل طلبناه وعدّلوا الخطة معنا بصبر. أنصح بهم.',
      en: 'They listened to every detail we asked for and adjusted the plan patiently. Recommended.',
    },
  },
]
