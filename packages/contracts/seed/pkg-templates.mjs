// Package templates for the common archetypes (docs/design/seed-rulebook.md section 6).
import { bil } from './lib.mjs'
import { inclusionsFor, NOTE_IN_HOUSE } from './venue-kit.mjs'

export const FEATURES = {
  hotelPlus: { valet: true, bridalSuite: true, suiteNight: false, showCake: true, kosha: 'basic' },
  hotel: { valet: true, bridalSuite: true, showCake: false, kosha: 'basic' },
  hall: { valet: false, bridalSuite: true, showCake: false, kosha: 'basic' },
  hallPlus: { valet: true, bridalSuite: true, showCake: true, kosha: 'basic' },
  men: { valet: false },
  menHotel: { valet: true },
}

export function ladiesWeekday({ halls, min, max, price, feats = FEATURES.hotel, inhouse = true, extra = {} }) {
  return {
    key: 'ladies-weekday',
    halls,
    name: bil("Ladies' Reception, Weekday", 'الحفل النسائي · أيام الأسبوع'),
    archetype: 'ladies_weekday',
    audiences: ['women'],
    min,
    max,
    description: bil('Evening reception for Sunday to Wednesday with buffet dinner.', 'حفل مسائي من الأحد إلى الأربعاء مع عشاء بوفيه.'),
    inclusions: inclusionsFor(feats),
    notes: inhouse ? [NOTE_IN_HOUSE] : [],
    rules: [['weekday', { perGuest: price }]],
    ...extra,
  }
}

export function ladiesWeekend({ halls, min, max, price, feats = FEATURES.hotel, inhouse = true, extraRules = [], extra = {} }) {
  return {
    key: 'ladies-weekend',
    halls,
    name: bil("Ladies' Reception, Weekend", 'الحفل النسائي · نهاية الأسبوع'),
    archetype: 'ladies_weekend',
    audiences: ['women'],
    min,
    max,
    description: bil('Evening reception for Thursday to Saturday with buffet dinner.', 'حفل مسائي من الخميس إلى السبت مع عشاء بوفيه.'),
    inclusions: inclusionsFor(feats),
    notes: inhouse ? [NOTE_IN_HOUSE] : [],
    rules: [['weekend', { perGuest: price }], ...extraRules],
    ...extra,
  }
}

export function menReception({ halls, min, max, price, feats = FEATURES.men, extra = {} }) {
  return {
    key: 'men-reception',
    halls,
    name: bil("Men's Reception", 'الحفل الرجالي'),
    archetype: 'men_reception',
    audiences: ['men'],
    min,
    max,
    description: bil('Evening reception for men with buffet dinner and coffee service.', 'استقبال مسائي للرجال مع عشاء بوفيه وخدمة القهوة.'),
    inclusions: inclusionsFor(feats),
    notes: [NOTE_IN_HOUSE],
    rules: [
      ['weekday', { perGuest: price }],
      ['weekend', { perGuest: price }],
    ],
    ...extra,
  }
}

export function hallOnly({ key = 'hall-only', halls, audiences = ['women', 'men'], weekday, weekend, min = 0, max, extra = {} }) {
  return {
    key,
    halls,
    name: bil('Hall Only', 'إيجار القاعة فقط'),
    archetype: 'hall_only',
    audiences,
    basis: 'flat',
    min,
    max,
    step: 10,
    description: bil(
      'The hall for the evening session with tables, chairs and basic lighting. Catering and decor are arranged by the hirer.',
      'القاعة للفترة المسائية مع الطاولات والكراسي وإضاءة أساسية. الضيافة والديكور على المستأجر.',
    ),
    inclusions: [
      bil('Hall for the evening session', 'القاعة للفترة المسائية'),
      bil('Tables, chairs and basic lighting', 'طاولات وكراسي وإضاءة أساسية'),
      bil('Bridal room', 'غرفة العروس'),
      bil('Parking for guests', 'مواقف للضيوف'),
    ],
    notes: [bil('Outside caterer and decorator are welcome', 'يُسمح بالضيافة والديكور من الخارج')],
    rules: [
      ['weekday', { flat: weekday }],
      ['weekend', { flat: weekend }],
    ],
    ...extra,
  }
}
