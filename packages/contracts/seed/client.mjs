// The client persona (Reem Al-Dosari) and her planning tools: wedding profile, checklist, budget, saved, notifications.
// Wedding Thu 14 Jan 2027 (63 days from NOW), venue-and-catering budget KD 20,000 - 35,000, ladies about 350, men about 400.
import { bil, kd, monogramOf } from './lib.mjs'

const at = (date, time) => `${date}T${time}:00+03:00`

export const budgetBands = [
  { id: 'band-under-5k', min: kd(0), max: kd(5000) },
  { id: 'band-5k-10k', min: kd(5000), max: kd(10000) },
  { id: 'band-10k-20k', min: kd(10000), max: kd(20000) },
  { id: 'band-20k-35k', min: kd(20000), max: kd(35000) },
  { id: 'band-35k-plus', min: kd(35000), max: null },
]

export const weddingProfile = {
  id: 'wedding-reem',
  userId: 'user-reem',
  role: 'bride',
  brideName: 'ريم الدوسري',
  partnerName: 'فهد الشمري',
  weddingDate: '2027-01-14',
  dateMode: 'exact',
  guests: { women: 350, men: 400 },
  venueBudget: { min: kd(20000), max: kd(35000) },
  totalBudget: kd(60000),
  areaIds: ['salmiya', 'sharq'],
  // Salmiya is in Hawalli and Sharq in Capital (round 2: the Brief narrows by governorate, CA-FLT-08).
  governorateIds: ['hawalli', 'capital'],
  searching: ['women'],
}

// ---------------------------------------------------------------- checklist (PRD defaults plus one custom item)
const item = (id, group, ar, en, dueOn, extra = {}) => ({
  id,
  group,
  title: bil(en, ar),
  dueOn,
  done: false,
  doneAt: null,
  auto: false,
  custom: false,
  serviceCategoryId: null,
  bookingId: null,
  ...extra,
})

export const checklist = [
  // Completes automatically at `confirmed`, never at approval (ADR 0001): done is derived from the booking status.
  item('chk-venue', 'venue', 'اختيار القاعة', 'Venue', null, { auto: true, bookingId: 'bk-GZ-2611-0147' }),
  item('chk-photographer', 'photographer', 'اختيار المصوّرة', 'Photographer', '2026-11-15', { serviceCategoryId: 'photography' }),
  item('chk-dress', 'dress', 'فستان الزفاف', 'Dress', '2026-11-19', { serviceCategoryId: 'wedding_dress' }),
  item('chk-invitations', 'invitation', 'بطاقات الدعوة', 'Invitations', '2026-12-03', { serviceCategoryId: 'invitations' }),
  item('chk-cake', 'cake', 'كيكة العرض', 'Cake', '2026-12-03', { serviceCategoryId: 'cake' }),
  item('chk-music', 'music', 'الموسيقى', 'Music', '2026-12-03', { serviceCategoryId: 'dj' }),
  item('chk-flowers', 'flowers', 'الزهور', 'Flowers', '2026-12-17', { serviceCategoryId: 'flowers' }),
  item('chk-transport', 'transportation', 'السيارات والتنقل', 'Transportation', '2026-12-24', { serviceCategoryId: 'luxury_cars' }),
  item('chk-bukhoor', 'custom', 'طلب البخور', 'Order bukhoor', null, { custom: true }),
]

// ---------------------------------------------------------------- budget (venue and catering merged: Kuwaiti packages price them per guest together)
const cat = (id, ar, en, allocated, icon, autoLinked = false) => ({
  id,
  name: bil(en, ar),
  allocated: kd(allocated),
  paid: kd(0),
  committed: kd(0),
  autoLinked,
  icon,
})
export const budget = {
  total: kd(60000),
  categories: [
    cat('venue_catering', 'القاعة والضيافة', 'Venue and catering', 32000, 'hall', true),
    cat('photo_video', 'التصوير والفيديو', 'Photography and video', 4000, 'camera'),
    cat('flowers_decor', 'الزهور والديكور', 'Flowers and decoration', 6000, 'flower'),
    cat('attire', 'الملابس (الفستان والبدلة)', 'Attire (dress and suit)', 7000, 'dress'),
    cat('makeup_henna', 'المكياج والحناء', 'Makeup and henna', 2500, 'brush'),
    cat('cars', 'السيارات', 'Cars', 1500, 'car'),
    cat('invitations', 'بطاقات الدعوة', 'Invitations', 1000, 'mail'),
    cat('music', 'الموسيقى', 'Music', 3000, 'music'),
    cat('honeymoon', 'شهر العسل', 'Honeymoon', 3000, 'palm'),
  ],
  expenses: [],
}
// States of the budget that depend on the story booking (the prototype walks the booking; paid and committed follow it). The only money
// that moves through Ghazal is the KD 2 voucher; the event itself is settled with the hotel off-app, so it counts as committed, not paid.
export const budgetVariants = {
  /** Request sent: the hero voucher (KD 2) is paid, nothing is committed yet. */
  pending: { paid: kd(2), committed: kd(0) },
  /** Booking confirmed: the voucher price (350 x 44 = KD 15,400) is committed, remaining KD 44,598. */
  confirmed: { paid: kd(2), committed: kd(15400) },
  /** CL-WEDD-04 example entry, not part of the base budget. */
  sampleExpense: { id: 'exp-henna', categoryId: 'makeup_henna', label: 'فنانة حناء', amount: kd(80), status: 'paid', date: '2026-11-08', bookingId: null, vendorId: 'vendor-henna-naqsh' },
  /** Alert example: Flowers and decoration at 82%. */
  flowersAt82: { categoryId: 'flowers_decor', paid: kd(4920) },
}

export const notificationPrefs = {
  userId: 'user-reem',
  marketing: true,
  quietHours: { start: '22:00', end: '09:00' },
  maxMarketingPerWeek: 2,
}

// ---------------------------------------------------------------- saved, compare, recents
export const clientState = {
  userId: 'user-reem',
  saved: [
    { type: 'venue', id: 'V01', savedAt: at('2026-10-26', '19:40'), lastSeenPrice: kd(18200) },
    { type: 'venue', id: 'V05', savedAt: at('2026-10-26', '19:55'), lastSeenPrice: kd(13300) },
    { type: 'venue', id: 'V07', savedAt: at('2026-10-27', '21:10'), lastSeenPrice: kd(11550) },
    { type: 'venue', id: 'V09', savedAt: at('2026-10-30', '20:05'), lastSeenPrice: kd(11900) },
    { type: 'venue', id: 'V08', savedAt: at('2026-11-02', '18:30'), lastSeenPrice: kd(10850) },
    { type: 'vendor', id: 'vendor-photography-lamha', savedAt: at('2026-11-05', '17:20'), lastSeenPrice: kd(450) },
    { type: 'vendor', id: 'vendor-flowers-nakheel-blooms', savedAt: at('2026-11-06', '21:00'), lastSeenPrice: kd(900) },
    { type: 'package', id: 'V01-ladies-weekend', savedAt: at('2026-10-26', '19:42'), lastSeenPrice: kd(18200) },
    { type: 'package', id: 'planner-gold', savedAt: at('2026-11-08', '16:15'), lastSeenPrice: kd(1900) },
  ],
  compareVenueIds: ['V01', 'V05', 'V07'],
  recentlyViewedVenueIds: ['V01', 'V09', 'V08', 'V05', 'V07', 'V03'],
}

// ---------------------------------------------------------------- planner and vendor requests
export const plannerRequest = {
  id: 'plannerreq-reem',
  clientId: 'user-reem',
  tier: 'gold',
  venueId: 'V01',
  eventDate: '2027-01-14',
  windows: [
    { date: '2026-11-15', part: 'evening' },
    { date: '2026-11-16', part: 'afternoon' },
  ],
  note: 'نحتاج مساعدة في تصميم الكوشة والتنسيق مع الفندق',
  requestedAt: at('2026-11-11', '18:00'),
  status: 'meeting_scheduled',
  plannerId: 'planner-nouf',
  assignedAt: at('2026-11-12', '11:00'),
  meeting: { at: at('2026-11-15', '19:30'), durationMin: 60, channel: 'video_call' },
  slots: [{ date: '2026-11-15', times: ['17:00', '17:30', '19:30', '20:00'] }],
}

export const vendorQuoteRequest = {
  id: 'vquote-reem-lamha',
  clientId: 'user-reem',
  vendorId: 'vendor-photography-lamha',
  vendorPackageId: 'vp-photography-lamha-1',
  eventDate: '2027-01-14',
  venueId: 'V01',
  guests: 350,
  note: 'نحتاج مصوّرة فقط للحفل النسائي',
  requestedAt: at('2026-11-11', '21:30'),
  status: 'replied',
}

// ---------------------------------------------------------------- notifications (client, newest first)
const nt = (id, kind, when, title, body, params, extra = {}) => ({
  id,
  audience: 'client',
  userId: 'user-reem',
  kind,
  title,
  body,
  params,
  at: when,
  read: extra.read ?? false,
  tone: extra.tone ?? 'neutral',
  tag: extra.tag ?? null,
  bookingId: extra.bookingId ?? null,
  venueId: extra.venueId ?? null,
  conversationId: extra.conversationId ?? null,
  channel: extra.channel ?? 'transactional',
  voucherId: extra.voucherId ?? null,
  visitId: extra.visitId ?? null,
})

const bookingHero = 'bk-GZ-2611-0147'
const voucherHero = 'vch-GV-2611-K7QM'
export const clientNotifications = [
  nt('ntf-c-01', 'request_sent', at('2026-11-12', '12:41'),
    bil('Request sent', 'تم إرسال الطلب'),
    bil('Request sent to Aurelia Gulf Hotel at the voucher price for Thu 14 Jan. Expected reply by Fri 13 Nov, 12:40 PM.', 'تم إرسال طلبكم إلى فندق أوريليا الخليج بسعر الكوبون ليوم الخميس 14 يناير. الرد المتوقع قبل الجمعة 13 نوفمبر، 12:40 م.'),
    { venue: 'V01', eventDate: '2027-01-14', replyBy: '2026-11-13T12:40:00+03:00' }, { bookingId: bookingHero, venueId: 'V01', voucherId: voucherHero }),
  nt('ntf-c-02', 'voucher_ready', at('2026-11-12', '12:31'),
    bil('Your voucher is ready', 'كوبونكم جاهز'),
    bil('Voucher GV-2611-K7QM is bound to Aurelia Gulf Hotel. Send your request at the voucher price.', 'الكوبون GV-2611-K7QM مرتبط بفندق أوريليا الخليج. أرسلوا طلبكم بسعر الكوبون.'),
    { venue: 'V01', code: 'GV-2611-K7QM' }, { tone: 'success', venueId: 'V01', voucherId: voucherHero }),
  nt('ntf-c-03', 'planner_assigned', at('2026-11-12', '11:05'),
    bil('Planner assigned', 'تعيين منسّقة'),
    bil('Nouf Al-Otaibi is your wedding planner. Video call on Sun 15 Nov at 7:30 PM, Kuwait time.', 'نوف العتيبي هي منسّقة زفافكم. مكالمة الفيديو الأحد 15 نوفمبر الساعة 7:30 م بتوقيت الكويت.'),
    { planner: 'planner-nouf', meetingAt: '2026-11-15T19:30:00+03:00' }, { conversationId: 'conv-planner-nouf' }),
  nt('ntf-c-04', 'checklist_due', at('2026-11-12', '08:00'),
    bil('Checklist', 'قائمة المهام'),
    bil('Photographer is due Sun 15 Nov. Review your checklist.', 'موعد اختيار المصوّرة الأحد 15 نوفمبر. راجعوا قائمة المهام.'),
    { item: 'chk-photographer', dueOn: '2026-11-15' }, { read: true }),
  nt('ntf-c-05', 'visit_confirmed', at('2026-11-11', '09:41'),
    bil('Visit confirmed', 'تم تأكيد الزيارة'),
    bil('Your visit to Aurelia Gulf Hotel is confirmed for Sat 14 Nov at 5:00 PM. Ghazal support is in the group chat.', 'تم تأكيد زيارتكم لفندق أوريليا الخليج يوم السبت 14 نوفمبر الساعة 5:00 م. دعم غزل في المحادثة الجماعية.'),
    { venue: 'V01', visit: 'visit-aurelia-reem' }, { tone: 'success', venueId: 'V01', visitId: 'visit-aurelia-reem', conversationId: 'conv-visit-aurelia-reem' }),
  nt('ntf-c-06', 'voucher_released', at('2026-11-10', '10:06'),
    bil('Your voucher is still yours', 'كوبونكم ما زال لكم'),
    bil('Voucher GV-2611-R4TF is back in your wallet. Use it again at Lumi Marina Hotel until 9 Jan, or ask for the KD 2 back.', 'عاد الكوبون GV-2611-R4TF إلى محفظتكم. استخدموه مجددًا في فندق لومي مارينا حتى 9 يناير، أو اطلبوا استرداد الـ 2 د.ك.'),
    { venue: 'V05', code: 'GV-2611-R4TF', reuseUntil: '2027-01-09' }, { venueId: 'V05', voucherId: 'vch-GV-2611-R4TF', read: true }),
  nt('ntf-c-07', 'request_expired', at('2026-11-10', '10:05'),
    bil('Request expired', 'انتهت مهلة الطلب'),
    bil('Lumi Marina Hotel did not reply to your request for Thu 14 Jan in time. Nothing was lost: your voucher is still yours.', 'لم يردّ فندق لومي مارينا على طلبكم ليوم الخميس 14 يناير في الوقت المحدد. لم تخسروا شيئًا: كوبونكم ما زال لكم.'),
    { venue: 'V05', eventDate: '2027-01-14' }, { bookingId: 'bk-GZ-2611-0098', venueId: 'V05', voucherId: 'vch-GV-2611-R4TF', read: true }),
  nt('ntf-c-08', 'request_sent', at('2026-11-09', '10:01'),
    bil('Request sent', 'تم إرسال الطلب'),
    bil('Request sent to Lumi Marina Hotel for Thu 14 Jan. Expected reply by Tue 10 Nov, 10:00 AM.', 'تم إرسال طلبكم إلى فندق لومي مارينا ليوم الخميس 14 يناير. الرد المتوقع قبل الثلاثاء 10 نوفمبر، 10:00 ص.'),
    { venue: 'V05', eventDate: '2027-01-14' }, { bookingId: 'bk-GZ-2611-0098', venueId: 'V05', voucherId: 'vch-GV-2611-R4TF', read: true }),
  nt('ntf-c-09', 'new_venue', at('2026-11-08', '10:00'),
    bil('New near you', 'جديد قرب منطقتكم'),
    bil('Bayan Villa Estate has joined Ghazal, close to Salmiya.', 'انضمت فيلا بيان الخاصة إلى غزل، قريبًا من السالمية.'),
    { venue: 'V04' }, { venueId: 'V04', channel: 'marketing', read: true }),
  nt('ntf-c-10', 'credit_voucher_issued', at('2026-11-05', '10:00'),
    bil('Credit voucher issued', 'تم إصدار كوبون رصيد'),
    bil('Support added a credit voucher for you. Use it at any hall, hotel or service within 60 days.', 'أضاف الدعم كوبون رصيد لكم. استخدموه في أي قاعة أو فندق أو خدمة خلال 60 يومًا.'),
    { code: 'GV-2611-C4RD', from: 'GV-2610-H9XB' }, { tone: 'success', voucherId: 'vch-GV-2611-C4RD', read: true }),
  nt('ntf-c-11', 'checklist_due', at('2026-11-05', '09:00'),
    bil('Checklist', 'قائمة المهام'),
    bil('Dress is due Thu 19 Nov. Review your checklist.', 'موعد اختيار الفستان الخميس 19 نوفمبر. راجعوا قائمة المهام.'),
    { item: 'chk-dress', dueOn: '2026-11-19' }, { read: true }),
  nt('ntf-c-12', 'message', at('2026-11-03', '20:10'),
    bil('Ghazal Support', 'دعم غزل'),
    bil('Ghazal Support replied to your message.', 'ردّ دعم غزل على رسالتكم.'),
    { conversation: 'conv-support-reem' }, { conversationId: 'conv-support-reem', read: true }),
  nt('ntf-c-13', 'visit_reminder', at('2026-11-03', '16:30'),
    bil('Visit tomorrow', 'زيارة غدًا'),
    bil('Your visit to Lumi Marina Hotel is tomorrow, Wed 4 Nov, at 4:30 PM.', 'زيارتكم لفندق لومي مارينا غدًا الأربعاء 4 نوفمبر الساعة 4:30 م.'),
    { venue: 'V05', visit: 'visit-lumi-reem' }, { venueId: 'V05', visitId: 'visit-lumi-reem', conversationId: 'conv-visit-lumi-reem', read: true }),
  nt('ntf-c-14', 'request_declined', at('2026-10-31', '10:16'),
    bil('Not accepted', 'لم يُقبل الطلب'),
    bil('Qasr Al-Nakheel could not accept Fri 15 Jan. Your voucher is still yours: use it again or ask for the KD 2 back.', 'لم تتمكن قاعة قصر النخيل من قبول الجمعة 15 يناير. كوبونكم ما زال لكم: استخدموه مجددًا أو اطلبوا استرداد الـ 2 د.ك.'),
    { venue: 'V09', eventDate: '2027-01-15' }, { bookingId: 'bk-GZ-2610-5C8Y', venueId: 'V09', voucherId: 'vch-GV-2610-H9XB', read: true }),
  nt('ntf-c-15', 'checklist_due', at('2026-10-28', '09:00'),
    bil('Checklist', 'قائمة المهام'),
    bil('Your checklist is ready. Venue comes first.', 'قائمة مهامكم جاهزة. اختيار القاعة أولًا.'),
    { item: 'chk-venue' }, { read: true }),
  nt('ntf-c-16', 'countdown', at('2026-10-26', '09:00'),
    bil('Countdown', 'العد التنازلي'),
    bil('Your countdown has started. Thursday 14 January 2027.', 'بدأ العد التنازلي لزفافكم. الخميس 14 يناير 2027.'),
    { weddingDate: '2027-01-14' }, { read: true }),
  nt('ntf-c-17', 'message', at('2026-10-25', '20:15'),
    bil('Ghazal Support', 'دعم غزل'),
    bil('Hello, Reem. We are here for any question about requests or vouchers.', 'أهلاً وسهلاً، ريم. نحن هنا لأي سؤال عن الطلبات أو الكوبونات.'),
    { conversation: 'conv-support-reem' }, { conversationId: 'conv-support-reem', read: true }),
]

// States that arrive after NOW in the prototype walk (approval, confirmation, lapse, redemption): used by the hero variants.
export const heroVariantNotifications = {
  approved: nt('ntf-c-v-approved', 'request_approved', at('2026-11-12', '16:00'),
    bil('Approved: confirm within 24 hours', 'تمت الموافقة · أكدوا خلال 24 ساعة'),
    bil('Aurelia Gulf Hotel approved your request at the voucher price. Confirm your booking by Fri 13 Nov, 4:00 PM to keep the date.', 'وافق فندق أوريليا الخليج على طلبكم بسعر الكوبون. أكدوا حجزكم قبل الجمعة 13 نوفمبر، 4:00 م للحفاظ على التاريخ.'),
    { venue: 'V01', confirmBy: '2026-11-13T16:00:00+03:00' }, { tone: 'gold', bookingId: bookingHero, venueId: 'V01', voucherId: voucherHero }),
  confirmReminder: nt('ntf-c-v-reminder', 'confirm_reminder', at('2026-11-13', '13:00'),
    bil('Confirm within 3 hours', 'أكدوا خلال 3 ساعات'),
    bil('Your approval from Aurelia Gulf Hotel ends today at 4:00 PM. Confirm your booking to keep Thu 14 Jan.', 'تنتهي موافقة فندق أوريليا الخليج اليوم الساعة 4:00 م. أكدوا حجزكم للحفاظ على الخميس 14 يناير.'),
    { venue: 'V01', confirmBy: '2026-11-13T16:00:00+03:00' }, { tone: 'gold', bookingId: bookingHero, venueId: 'V01', voucherId: voucherHero }),
  confirmed: nt('ntf-c-v-confirmed', 'request_confirmed', at('2026-11-12', '16:12'),
    bil('Booking confirmed', 'تم تأكيد الحجز'),
    bil('Your booking at Aurelia Gulf Hotel on Thu 14 Jan is confirmed at the voucher price. Pay the hotel directly and show your voucher code.', 'تم تأكيد حجزكم في فندق أوريليا الخليج ليوم الخميس 14 يناير بسعر الكوبون. سدّدوا للفندق مباشرة وأظهروا رمز الكوبون.'),
    { venue: 'V01', code: 'GV-2611-K7QM' }, { tone: 'success', bookingId: bookingHero, venueId: 'V01', voucherId: voucherHero }),
  lapsed: nt('ntf-c-v-lapsed', 'request_expired', at('2026-11-13', '16:00'),
    bil('The confirmation window ended', 'انتهت مهلة التأكيد'),
    bil('The booking was not confirmed at the hotel within 24 hours, so the voucher is not valid and the date was released.', 'لم يُؤكَّد الحجز لدى الفندق خلال 24 ساعة، لذلك الكوبون غير صالح وتم تحرير التاريخ.'),
    { venue: 'V01', eventDate: '2027-01-14' }, { bookingId: bookingHero, venueId: 'V01', voucherId: voucherHero }),
  declined: nt('ntf-c-v-declined', 'request_declined', at('2026-11-12', '17:30'),
    bil('Not accepted', 'لم يُقبل الطلب'),
    bil('Aurelia Gulf Hotel could not accept Thu 14 Jan. Your voucher is still yours: use it again or ask support for a credit voucher.', 'لم يتمكن فندق أوريليا الخليج من قبول الخميس 14 يناير. كوبونكم ما زال لكم: استخدموه مجددًا أو اطلبوا كوبون رصيد من الدعم.'),
    { venue: 'V01', eventDate: '2027-01-14' }, { bookingId: bookingHero, venueId: 'V01', voucherId: voucherHero }),
  redeemed: nt('ntf-c-v-redeemed', 'voucher_redeemed', at('2027-01-03', '12:20'),
    bil('Voucher redeemed', 'تم استخدام الكوبون'),
    bil('Aurelia Gulf Hotel redeemed voucher GV-2611-K7QM at the voucher price.', 'استخدم فندق أوريليا الخليج الكوبون GV-2611-K7QM بسعر الكوبون.'),
    { venue: 'V01', code: 'GV-2611-K7QM' }, { tone: 'success', bookingId: bookingHero, venueId: 'V01', voucherId: voucherHero }),
  thirtyDays: nt('ntf-c-v-30', 'countdown', at('2026-12-15', '09:00'),
    bil('Countdown', 'العد التنازلي'),
    bil('30 days to your wedding. Review your checklist.', 'باقي 30 يومًا على زفافكم. راجعوا قائمة المهام.'),
    { days: 30 }),
}
clientNotifications.sort((a, b) => (a.at < b.at ? 1 : a.at > b.at ? -1 : 0))
void monogramOf
