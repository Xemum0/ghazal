// People: the client persona, other couples, venue staff, support. Names are common Kuwaiti given names plus broad family
// names; no royal or prominent-family names (docs/design/seed-rulebook.md). Phones are +965 5000 00NN, one per party,
// display-only, never a tel: or wa.me link.
import { bil, monogramOf } from './lib.mjs'

const phone = (nn) => `+965500000${String(nn).padStart(2, '0')}`

export const REEM = 'user-reem'
export const HIND = 'user-hind'

const user = (id, role, name, nameLatin, nn, locale = 'ar', createdAt = '2026-09-01T10:00:00+03:00', email = null) => ({
  id,
  role,
  name,
  ...(nameLatin ? { nameLatin } : {}),
  monogram: monogramOf(name),
  phone: phone(nn),
  email,
  locale,
  digitStyle: 'western',
  createdAt,
})

// [id suffix, Arabic, Latin, phone NN]
const clientRows = [
  ['dana-shammari', 'دانة الشمري', 'Dana Al-Shammari', 21],
  ['abdullah-hajri', 'عبدالله الهاجري', 'Abdullah Al-Hajri', 22],
  ['maryam-kandari', 'مريم الكندري', 'Maryam Al-Kandari', 23],
  ['faisal-rasheedi', 'فيصل الرشيدي', 'Faisal Al-Rasheedi', 24],
  ['haya-mutairi', 'هيا المطيري', 'Haya Al-Mutairi', 25],
  ['salman-harbi', 'سلمان الحربي', 'Salman Al-Harbi', 26],
  ['najla-badr', 'نجلاء البدر', 'Najla Al-Badr', 27],
  ['munira-khaled', 'منيرة الخالد', 'Munira Al-Khaled', 28],
  ['lulwa-saleh', 'لولوة الصالح', 'Lulwa Al-Saleh', 29],
  ['nora-fahad', 'نورة الفهد', 'Nora Al-Fahad', 30],
  ['huda-shaya', 'هدى الشايع', 'Huda Al-Shaya', 31],
  ['fatima-azmi', 'فاطمة العازمي', 'Fatima Al-Azmi', 32],
  ['malak-hamdan', 'ملك الحمدان', 'Malak Al-Hamdan', 33],
  ['badr-otaibi', 'بدر العتيبي', 'Badr Al-Otaibi', 34],
  ['asmaa-roumi', 'أسماء الرومي', 'Asmaa Al-Roumi', 35],
  ['alya-dhafiri', 'علياء الظفيري', 'Alya Al-Dhafiri', 36],
  ['shahad-mutawa', 'شهد المطوع', 'Shahad Al-Mutawa', 37],
  ['dalal-sabti', 'دلال السبتي', 'Dalal Al-Sabti', 38],
  ['jood-ajmi', 'جود العجمي', 'Jood Al-Ajmi', 80],
  ['thamer-mutawa', 'ثامر المطوع', 'Thamer Al-Mutawa', 81],
  ['shaikha-anzi', 'شيخة العنزي', 'Shaikha Al-Anzi', 82],
  ['bashayer-dhafiri', 'بشاير الظفيري', 'Bashayer Al-Dhafiri', 83],
  ['jassim-kandari', 'جاسم الكندري', 'Jassim Al-Kandari', 84],
  ['wadha-roumi', 'وضحى الرومي', 'Wadha Al-Roumi', 85],
  ['mashael-saleh', 'مشاعل الصالح', 'Mashael Al-Saleh', 86],
  ['ahmad-hamad', 'أحمد الحمد', 'Ahmad Al-Hamad', 87],
  ['hessa-marzouq', 'حصة المرزوق', 'Hessa Al-Marzouq', 88],
  ['talal-failakawi', 'طلال الفيلكاوي', 'Talal Al-Failakawi', 89],
  ['maitha-sayegh', 'ميثاء الصايغ', 'Maitha Al-Sayegh', 90],
  ['rashed-ajmi', 'راشد العجمي', 'Rashed Al-Ajmi', 93],
  ['amna-kharafi', 'آمنة الخرافي', 'Amna Al-Kharafi', 94],
]

export const clientUsers = clientRows.map(([slug, ar, en, nn]) => user(`user-${slug}`, 'client', ar, en, nn))

export const users = [
  user(REEM, 'client', 'ريم الدوسري', 'Reem Al-Dosari', 12, 'ar', '2026-10-25T20:10:00+03:00'),
  user('user-support', 'support', 'دعم غزل', 'Ghazal Support', 1, 'ar', '2026-01-01T00:00:00+03:00'),
  user(HIND, 'hotel_staff', 'هند العنزي', 'Hind Al-Enezi', 40, 'ar', '2026-06-02T09:00:00+03:00'),
  user('user-khalid', 'hotel_staff', 'خالد العتيبي', 'Khalid Al-Otaibi', 41, 'ar', '2026-06-01T09:00:00+03:00'),
  user('user-amal', 'hotel_staff', 'أمل البلوشي', 'Amal Al-Balushi', 42, 'ar', '2026-06-10T09:00:00+03:00'),
  user('user-mahmoud', 'hotel_staff', 'محمود صالح', 'Mahmoud Saleh', 43, 'en', '2026-06-10T09:00:00+03:00'),
  user('user-sara', 'hotel_staff', 'سارة القطان', 'Sara Al-Qattan', 44, 'ar', '2026-11-11T11:00:00+03:00'),
  // Partner personas beyond Aurelia (ADR 0033 D7): a non-major hotel manager, the hotel representative of Lumi Marina Hotel (member of
  // Reem's visit group chat), a service-provider owner, and the Ghazal support representative of every visit group chat.
  user('user-lumi-rep', 'hotel_staff', 'نادية الفيلكاوي', 'Nadia Al-Failakawi', 45, 'ar', '2026-07-01T09:00:00+03:00'),
  user('user-lumi-manager', 'hotel_staff', 'بدرية الكندري', 'Badriya Al-Kandari', 46, 'ar', '2026-07-01T09:00:00+03:00'),
  user('user-zahra', 'provider_staff', 'زهرة المطيري', 'Zahra Al-Mutairi', 47, 'ar', '2026-10-05T10:00:00+03:00'),
  user('user-support-lama', 'support', 'لمى الخالدي', 'Lama Al-Khalidi', 4, 'ar', '2026-01-01T00:00:00+03:00'),
  ...clientUsers,
]

const roleSummary = {
  admin: bil('Admin: everything, including staff and billing', 'المالك: كل الصلاحيات بما فيها الموظفون والفواتير'),
  manager: bil('Manager: everything except staff and billing', 'المدير: كل الصلاحيات عدا الموظفين والفواتير'),
  reception: bil('Reception: requests, calendar, messages, visits and voucher redemption', 'الاستقبال: الطلبات والتقويم والرسائل والزيارات واستخدام الكوبونات'),
  accountant: bil('Accountant: billing and receipts', 'المحاسب: الفواتير والإيصالات'),
  marketing: bil('Marketing: voucher prices, analytics and photos', 'التسويق: أسعار الكوبون والتحليلات والصور'),
}
const roleLabel = {
  admin: bil('Admin (owner)', 'المالك'),
  manager: bil('Manager', 'المدير'),
  reception: bil('Reception', 'الاستقبال'),
  accountant: bil('Accountant', 'المحاسب'),
  marketing: bil('Marketing', 'التسويق'),
}

const staff = (id, userId, name, nameLatin, role, nn, uiLang, extra = {}) => ({
  id,
  userId,
  venueId: 'V01',
  name,
  nameLatin,
  monogram: monogramOf(name),
  role,
  roleLabel: roleLabel[role],
  roleSummary: roleSummary[role],
  phone: phone(nn),
  status: 'active',
  uiLang,
  lastSeenAt: null,
  invitedAt: null,
  inviteExpiresAt: null,
  invitedBy: null,
  isYou: false,
  ...extra,
})

// Staff of Aurelia Gulf Hotel (HL-SETT-03): the demo user is Hind Al-Enezi, Manager.
export const hotelStaff = [
  staff('staff-khalid', 'user-khalid', 'خالد العتيبي', 'Khalid Al-Otaibi', 'admin', 41, 'ar', { lastSeenAt: '2026-11-12T15:55:00+03:00' }),
  staff('staff-hind', HIND, 'هند العنزي', 'Hind Al-Enezi', 'manager', 40, 'ar', { isYou: true, lastSeenAt: '2026-11-12T16:00:00+03:00' }),
  staff('staff-amal', 'user-amal', 'أمل البلوشي', 'Amal Al-Balushi', 'reception', 42, 'ar', { lastSeenAt: '2026-11-12T14:30:00+03:00' }),
  staff('staff-mahmoud', 'user-mahmoud', 'محمود صالح', 'Mahmoud Saleh', 'accountant', 43, 'en', { lastSeenAt: '2026-11-12T11:20:00+03:00' }),
  staff('staff-sara', 'user-sara', 'سارة القطان', 'Sara Al-Qattan', 'marketing', 44, 'ar', {
    status: 'invited',
    invitedAt: '2026-11-11T11:00:00+03:00',
    inviteExpiresAt: '2026-11-14T23:59:00+03:00',
    invitedBy: 'Khalid Al-Otaibi',
  }),
]

// The sister venue of the venue switcher (state only, not part of the seeded roster).
export const sisterVenue = { id: 'V-sister-marina', name: bil('Aurelia Marina Hall', 'قاعة أوريليا المارينا'), role: 'reception', pending: 2 }

// Staff invitations of Aurelia Gulf Hotel (ADR 0035 D8): sent by email through Resend, never by WhatsApp.
export const staffInvitations = [
  { id: 'inv-sara', venueId: 'V01', email: 'sara.alqattan@aurelia-gulf.example', role: 'marketing', status: 'invited', sentAt: '2026-11-11T11:00:00+03:00', expiresAt: '2026-11-14T23:59:00+03:00', invitedBy: 'Khalid Al-Otaibi', staffId: 'staff-sara' },
  { id: 'inv-amal', venueId: 'V01', email: 'amal.albalushi@aurelia-gulf.example', role: 'reception', status: 'accepted', sentAt: '2026-06-10T09:00:00+03:00', expiresAt: null, invitedBy: 'Khalid Al-Otaibi', staffId: 'staff-amal' },
]
