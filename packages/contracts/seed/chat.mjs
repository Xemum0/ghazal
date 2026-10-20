// Conversations and messages. The Aurelia thread is shared: the couple's message is visible in both apps; the hotel's reply exists
// only as drafts until the hotel sends it (CL-MSGS-02, HL-TODY-05). Typed chat may carry Khaleeji dialect; labels never do (ADR 0013).
// `text` carries both languages for the prototype's convenience; `origin` is what the author typed.
import { bil } from './lib.mjs'
import { visits, groupMembers, archiveOn } from './visits.mjs'

const at = (date, time) => `${date}T${time}:00+03:00`
let n = 0
const msg = (conversationId, from, senderName, when, kind, text, extra = {}) => {
  n += 1
  return {
    id: `msg-${String(n).padStart(3, '0')}`,
    conversationId,
    from,
    senderName,
    at: when,
    kind,
    text,
    origin: extra.origin ?? 'ar',
    status: extra.status ?? 'read',
    draft: extra.draft ?? false,
    ...(extra.voice ? { voice: extra.voice } : {}),
    ...(extra.document ? { document: extra.document } : {}),
    ...(extra.image ? { image: extra.image } : {}),
    ...(extra.card ? { card: extra.card } : {}),
  }
}
const T = (ar, en) => bil(en, ar)

// ------------------------------------------------------------------------------------------------ conversations
const venueNames = { V01: bil('Aurelia Gulf Hotel', 'فندق أوريليا الخليج'), V05: bil('Lumi Marina Hotel', 'فندق لومي مارينا') }
const visitSubtitle = {
  'visit-aurelia-reem': bil('Sat 14 Nov · 5:00 PM · confirmed', 'السبت 14 نوفمبر · 5:00 م · مؤكدة'),
  'visit-lumi-reem': bil('Wed 4 Nov · 4:30 PM · completed', 'الأربعاء 4 نوفمبر · 4:30 م · مكتملة'),
  'visit-aurelia-rashed': bil('Sat 21 Nov · 6:00 PM · requested', 'السبت 21 نوفمبر · 6:00 م · بانتظار التأكيد'),
}
const handledByName = { 'user-amal': 'Amal Al-Balushi', 'user-lumi-rep': 'Nadia Al-Failakawi' }
const visitConvState = {
  'visit-aurelia-reem': { unread: { client: 1, hotel: 0 }, lastMessageAt: at('2026-11-11', '09:55'), usuallyRepliesHours: 2 },
  'visit-lumi-reem': { unread: { client: 0, hotel: 0 }, lastMessageAt: at('2026-11-05', '16:30') },
  'visit-aurelia-rashed': { unread: { client: 0, hotel: 1 }, awaitingReplySince: at('2026-11-12', '14:36'), lastMessageAt: at('2026-11-12', '14:42') },
}

const conv = (c) => ({
  pinned: false,
  unread: { client: 0, hotel: 0 },
  handledBy: null,
  awaitingReplySince: null,
  usuallyRepliesHours: null,
  plannerId: null,
  vendorId: null,
  bookingId: null,
  venueId: null,
  ...c,
})

export const conversations = [
  conv({
    id: 'conv-aurelia-reem',
    kind: 'venue',
    title: bil('Aurelia Gulf Hotel', 'فندق أوريليا الخليج'),
    subtitle: bil('Request · Thu 14 Jan', 'طلب · الخميس 14 يناير'),
    monogram: 'ف',
    clientId: 'user-reem',
    clientName: 'ريم الدوسري',
    venueId: 'V01',
    bookingId: 'bk-GZ-2611-0147',
    unread: { client: 0, hotel: 1 },
    handledBy: 'Hind Al-Enezi',
    awaitingReplySince: at('2026-11-12', '15:12'),
    usuallyRepliesHours: 2,
    lastMessageAt: at('2026-11-12', '15:12'),
  }),
  conv({
    id: 'conv-planner-nouf',
    kind: 'planner',
    title: bil('Nouf Al-Otaibi', 'نوف العتيبي'),
    subtitle: bil('Meeting Sun 15 Nov', 'اجتماع الأحد 15 نوفمبر'),
    monogram: 'ن',
    clientId: 'user-reem',
    clientName: 'ريم الدوسري',
    plannerId: 'planner-nouf',
    lastMessageAt: at('2026-11-12', '11:48'),
    unread: { client: 1, hotel: 0 },
  }),
  conv({
    id: 'conv-vendor-lamha',
    kind: 'vendor',
    title: bil('Lamha Photography Studio', 'استوديو لمحة للتصوير'),
    subtitle: bil('Quote request', 'طلب عرض سعر'),
    monogram: 'ل',
    clientId: 'user-reem',
    clientName: 'ريم الدوسري',
    vendorId: 'vendor-photography-lamha',
    lastMessageAt: at('2026-11-12', '13:05'),
    unread: { client: 1, hotel: 0 },
    usuallyRepliesHours: 2,
  }),
  conv({
    id: 'conv-support-reem',
    kind: 'support',
    title: bil('Ghazal Support', 'دعم غزل'),
    subtitle: bil('Help with your booking', 'مساعدة بخصوص حجزكم'),
    monogram: 'غ',
    pinned: true,
    clientId: 'user-reem',
    clientName: 'ريم الدوسري',
    lastMessageAt: at('2026-11-05', '10:01'),
  }),
  conv({
    id: 'conv-lumi-reem',
    kind: 'venue',
    title: bil('Lumi Marina Hotel', 'فندق لومي مارينا'),
    subtitle: bil('Request · Thu 14 Jan', 'طلب · الخميس 14 يناير'),
    monogram: 'ف',
    clientId: 'user-reem',
    clientName: 'ريم الدوسري',
    venueId: 'V05',
    bookingId: 'bk-GZ-2611-0098',
    lastMessageAt: at('2026-11-09', '10:05'),
  }),
  conv({
    id: 'conv-jawharat-reem',
    kind: 'enquiry',
    title: bil('Jawharat Al-Salmiya Palace', 'قصر جوهرة السالمية للأفراح'),
    subtitle: bil('Enquiry', 'استفسار'),
    monogram: 'ق',
    clientId: 'user-reem',
    clientName: 'ريم الدوسري',
    venueId: 'V07',
    lastMessageAt: at('2026-11-11', '10:42'),
    usuallyRepliesHours: 2,
  }),
  // ---- hotel-side threads
  conv({
    id: 'conv-aurelia-faisal',
    kind: 'venue',
    title: bil('Faisal Al-Rasheedi', 'فيصل الرشيدي'),
    subtitle: bil('Fri 22 Jan · Pending', 'الجمعة 22 يناير · بانتظار الرد'),
    monogram: 'ف',
    clientId: 'user-faisal-rasheedi',
    clientName: 'فيصل الرشيدي',
    venueId: 'V01',
    bookingId: 'bk-GZ-2611-7V4H',
    unread: { client: 0, hotel: 1 },
    handledBy: null,
    awaitingReplySince: at('2026-11-12', '13:05'),
    lastMessageAt: at('2026-11-12', '13:05'),
  }),
  conv({
    id: 'conv-aurelia-najla',
    kind: 'venue',
    title: bil('Najla Al-Badr', 'نجلاء البدر'),
    subtitle: bil('Today 9:00 PM · Confirmed', 'اليوم 9:00 م · مؤكد'),
    monogram: 'ن',
    clientId: 'user-najla-badr',
    clientName: 'نجلاء البدر',
    venueId: 'V01',
    bookingId: 'bk-GZ-2607-6M2J',
    handledBy: 'Amal Al-Balushi',
    lastMessageAt: at('2026-11-12', '12:25'),
  }),
  conv({
    id: 'conv-aurelia-enquiry-shahad',
    kind: 'enquiry',
    title: bil('Shahad Al-Mutawa', 'شهد المطوع'),
    subtitle: bil('Enquiry', 'استفسار'),
    monogram: 'ش',
    clientId: 'user-shahad-mutawa',
    clientName: 'شهد المطوع',
    venueId: 'V01',
    handledBy: 'Amal Al-Balushi',
    lastMessageAt: at('2026-11-11', '18:00'),
  }),
  // ---- visit group chats (one per visit; exactly three members: client, hotel representative, Ghazal support)
  ...visits.map((v) =>
    conv({
      id: v.conversationId,
      kind: 'visit_group',
      title: bil(`Site visit · ${venueNames[v.venueId].en}`, `زيارة · ${venueNames[v.venueId].ar}`),
      subtitle: visitSubtitle[v.id],
      monogram: 'ز',
      clientId: v.clientId,
      clientName: v.clientName,
      venueId: v.venueId,
      handledBy: handledByName[v.representativeId],
      visitId: v.id,
      members: groupMembers(v),
      readOnlyFrom: v.closedAt,
      archiveOn: archiveOn(v.closedAt),
      ...visitConvState[v.id],
    }),
  ),
  conv({
    id: 'conv-support-aurelia',
    kind: 'support',
    title: bil('Ghazal Support', 'دعم غزل'),
    subtitle: bil('For venue teams', 'لفرق القاعات'),
    monogram: 'غ',
    pinned: true,
    clientId: null,
    clientName: 'دعم غزل',
    venueId: 'V01',
    lastMessageAt: at('2026-10-20', '10:00'),
  }),
]

// ------------------------------------------------------------------------------------------------ messages
export const messages = [
  // Aurelia x Reem (shared). The hotel's reply is a draft until it is sent.
  msg('conv-aurelia-reem', 'client', 'ريم الدوسري', at('2026-11-12', '15:12'), 'text', T('السلام عليكم، هل يوم الخميس 14 يناير متاح للحفل النسائي؟ عدد الضيوف تقريبًا 350.', 'Peace be upon you. Is Thursday 14 January available for the ladies’ reception? About 350 guests.'), { status: 'delivered' }),
  msg('conv-aurelia-reem', 'venue', 'Hind Al-Enezi', at('2026-11-12', '16:05'), 'text', T('وعليكم السلام ورحمة الله، هلا فيكم. نعم التاريخ متاح، ولما نوافق على طلبكم تقدرون تأكدون الحجز خلال 24 ساعة.', 'And peace be upon you, welcome. Yes, the date is available, and once we approve your request you can confirm the booking within 24 hours.'), { draft: true, status: 'sent' }),
  msg('conv-aurelia-reem', 'venue', 'Hind Al-Enezi', at('2026-11-12', '16:06'), 'voice', null, { draft: true, status: 'sent', voice: { seconds: 14 } }),
  msg('conv-aurelia-reem', 'venue', 'Hind Al-Enezi', at('2026-11-12', '16:07'), 'document', null, { draft: true, status: 'sent', document: { name: 'Quotation.pdf', sizeKb: 13, mime: 'application/pdf' } }),

  // Planner thread
  msg('conv-planner-nouf', 'planner', 'Nouf Al-Otaibi', at('2026-11-12', '11:10'), 'text', T('أهلًا ريم، أنا نوف من فريق التخطيط في غزل. سأكون معكم في تجهيزات الزفاف.', 'Hello Reem, I am Nouf from Ghazal’s planning team. I will be with you through the wedding preparations.')),
  msg('conv-planner-nouf', 'client', 'ريم الدوسري', at('2026-11-12', '11:25'), 'text', T('أهلًا نوف، نحتاج مساعدة في تصميم الكوشة والتنسيق مع الفندق.', 'Hello Nouf, we need help with the kosha design and coordinating with the hotel.')),
  msg('conv-planner-nouf', 'planner', 'Nouf Al-Otaibi', at('2026-11-12', '11:40'), 'meeting_card', null, {
    card: { kind: 'meeting', title: bil('Video call', 'مكالمة فيديو'), lines: [bil('Sun 15 Nov, 7:30 PM · Kuwait time', 'الأحد 15 نوفمبر، 7:30 م بتوقيت الكويت')], at: at('2026-11-15', '19:30'), refId: 'plannerreq-reem' },
  }),
  msg('conv-planner-nouf', 'planner', 'Nouf Al-Otaibi', at('2026-11-12', '11:48'), 'text', T('يسعدني التواصل. أرسلوا لي أي صور تعجبكم للكوشة قبل الاجتماع.', 'Glad to be in touch. Send me any kosha pictures you like before the meeting.'), { status: 'delivered' }),

  // Vendor thread
  msg('conv-vendor-lamha', 'client', 'ريم الدوسري', at('2026-11-11', '21:30'), 'quote_request_card', null, {
    card: {
      kind: 'quote_request',
      title: bil('Quote request', 'طلب عرض سعر'),
      lines: [bil('Wedding-day coverage · 6 hours', 'تغطية يوم الزفاف · 6 ساعات'), bil('Thu 14 Jan 2027 · Aurelia Gulf Hotel · 350 guests (ladies’ hall)', 'الخميس 14 يناير 2027 · فندق أوريليا الخليج · 350 ضيفًا (القاعة النسائية)'), bil('We only need a female photographer for the ladies’ hall', 'نحتاج مصوّرة فقط للحفل النسائي')],
      refId: 'vquote-reem-lamha',
    },
  }),
  msg('conv-vendor-lamha', 'vendor', 'Lamha Photography Studio', at('2026-11-12', '10:10'), 'text', T('شكرًا لتواصلكم. يتوفر لدينا فريق نسائي لهذا التاريخ، وسنرسل عرض السعر خلال اليوم.', 'Thank you for getting in touch. We have a female team available for that date and will send the quote today.')),
  msg('conv-vendor-lamha', 'vendor', 'Lamha Photography Studio', at('2026-11-12', '13:05'), 'document', null, { document: { name: 'Quotation-Lamha.pdf', sizeKb: 38, mime: 'application/pdf' }, status: 'delivered' }),

  // Support thread (human replies, no bot)
  msg('conv-support-reem', 'support', 'Ghazal Support', at('2026-10-25', '20:15'), 'text', T('أهلاً وسهلاً، ريم. نحن هنا لأي سؤال عن الحجز أو الدفع.', 'Hello, Reem. We are here for any question about booking or payment.')),
  msg('conv-support-reem', 'client', 'ريم الدوسري', at('2026-11-03', '19:40'), 'text', T('هل يمكن إضافة الحفل الرجالي إلى الطلب نفسه؟', 'Can the men’s reception be added to the same request?')),
  msg('conv-support-reem', 'support', 'Ghazal Support', at('2026-11-03', '20:10'), 'text', T('نعم، يمكن إضافة الحفل الرجالي في خطوة الإضافات إذا كانت القاعة تقدّمه في اليوم نفسه.', 'Yes, the men’s reception can be added in the Extras step if the venue offers it on the same day.')),

  // Lumi thread: the question that never got an answer
  msg('conv-lumi-reem', 'client', 'ريم الدوسري', at('2026-11-09', '10:05'), 'text', T('السلام عليكم، هل القاعة متاحة يوم الخميس 14 يناير؟', 'Peace be upon you. Is the hall available on Thursday 14 January?')),

  // Jawharat enquiry, with a layout photo and a voice note from the venue
  msg('conv-jawharat-reem', 'client', 'ريم الدوسري', at('2026-11-10', '20:00'), 'text', T('السلام عليكم، ما هو أقرب تاريخ متاح بعد 14 يناير؟', 'Peace be upon you. What is the nearest available date after 14 January?')),
  msg('conv-jawharat-reem', 'venue', 'Jawharat Al-Salmiya Palace', at('2026-11-11', '10:30'), 'text', T('هلا والله. متاح الخميس 21 يناير والجمعة 22 يناير، ونرسل لكم العرض بالتفصيل.', 'Welcome. Thursday 21 January and Friday 22 January are available, and we will send you the offer in detail.')),
  msg('conv-jawharat-reem', 'venue', 'Jawharat Al-Salmiya Palace', at('2026-11-11', '10:41'), 'image', null, { image: { file: 'ballrooms/ballrooms-27-olive-columns-long-table-candlelight.jpg', alt: bil('Seating layout for 350 guests', 'ترتيب الجلسات لـ 350 ضيفًا') } }),
  msg('conv-jawharat-reem', 'venue', 'Jawharat Al-Salmiya Palace', at('2026-11-11', '10:42'), 'voice', null, { voice: { seconds: 21 } }),

  // Hotel inbox: Faisal, Najla, an enquiry and support
  msg('conv-aurelia-faisal', 'client', 'فيصل الرشيدي', at('2026-11-12', '13:05'), 'text', T('هل تتوفر خدمة الفاليه لقاعة الرجال؟', 'Is valet service available for the men’s hall?'), { status: 'delivered' }),
  msg('conv-aurelia-najla', 'client', 'نجلاء البدر', at('2026-11-12', '12:10'), 'text', T('هل يمكن إدخال الزهور من الساعة 5:00 م؟', 'Can the flowers be brought in from 5:00 PM?')),
  msg('conv-aurelia-najla', 'venue', 'Amal Al-Balushi', at('2026-11-12', '12:25'), 'text', T('أكيد، فريق الفعاليات بيكون جاهز من الساعة 4:30 م.', 'Of course, the events team will be ready from 4:30 PM.')),
  msg('conv-aurelia-enquiry-shahad', 'client', 'شهد المطوع', at('2026-11-11', '17:20'), 'text', T('السلام عليكم، ممكن أعرف الباقات المتوفرة للحفل النسائي في شهر مارس؟', 'Peace be upon you. Could I know the packages available for a ladies’ reception in March?')),
  msg('conv-aurelia-enquiry-shahad', 'venue', 'Amal Al-Balushi', at('2026-11-11', '18:00'), 'text', T('وعليكم السلام ورحمة الله. الباقات موجودة في صفحة القاعة، ونقدر نرسل لكم التفاصيل إذا حددتم التاريخ وعدد الضيوف.', 'And peace be upon you. The packages are on the venue page, and we can send details once you choose the date and guest count.')),
  msg('conv-support-aurelia', 'support', 'Ghazal Support', at('2026-10-20', '10:00'), 'text', T('أهلاً بكم في غزل لفرق القاعات. نحن هنا لأي استفسار عن الحجوزات أو الدفعات.', 'Welcome to Ghazal for venue teams. We are here for any question about bookings or payments.')),
]


// ---- visit group chats: system messages carry the three roles and the slot; the client never creates a group chat on their own
const sys = (cid, when, kind, en, ar, card) => msg(cid, 'system', null, when, kind, bil(en, ar), { origin: 'en', ...(card ? { card } : {}) })
messages.push(
  // Aurelia x Reem, Sat 14 Nov, 5:00 PM (confirmed)
  sys('conv-visit-aurelia-reem', at('2026-11-10', '20:15'), 'system', 'A group chat opened for your visit on Sat 14 Nov: you, Aurelia Gulf Hotel and Ghazal support.', 'فُتحت محادثة جماعية لزيارتكم يوم السبت 14 نوفمبر: أنتم وفندق أوريليا الخليج ودعم غزل.'),
  msg('conv-visit-aurelia-reem', 'support', 'Lama Al-Khalidi', at('2026-11-10', '20:16'), 'text', T('أهلاً ريم، أنا لمى من دعم غزل. أنا هنا معكم ومع الفندق لتأكيد موعد وصولكم.', 'Hello Reem, I am Lama from Ghazal support. I am here with you and the hotel to confirm your arrival.')),
  msg('conv-visit-aurelia-reem', 'client', 'ريم الدوسري', at('2026-11-10', '20:20'), 'text', T('السلام عليكم، نبي نأكد موعد زيارتنا السبت الساعة 5 مساءً، ونكون 3 أشخاص.', 'Peace be upon you. We would like to confirm our visit on Saturday at 5 PM, three of us.')),
  msg('conv-visit-aurelia-reem', 'venue', 'Amal Al-Balushi', at('2026-11-11', '09:40'), 'text', T('وعليكم السلام ورحمة الله، أهلاً ريم. موعدكم مؤكد السبت 14 نوفمبر الساعة 5:00 م، وبنستقبلكم عند المدخل الرئيسي.', 'And peace be upon you, Reem. Your visit is confirmed for Saturday 14 November at 5:00 PM, and we will meet you at the main entrance.')),
  sys('conv-visit-aurelia-reem', at('2026-11-11', '09:41'), 'visit_card', 'Visit confirmed', 'تم تأكيد الزيارة', {
    kind: 'visit',
    title: bil('Site visit confirmed', 'تم تأكيد زيارة القاعة'),
    lines: [bil('Sat 14 Nov · 5:00 PM', 'السبت 14 نوفمبر · 5:00 م'), bil('Aurelia Gulf Hotel · main entrance', 'فندق أوريليا الخليج · المدخل الرئيسي'), bil('3 visitors', '3 زائرين')],
    at: at('2026-11-14', '17:00'),
    refId: 'visit-aurelia-reem',
  }),
  msg('conv-visit-aurelia-reem', 'venue', 'Amal Al-Balushi', at('2026-11-11', '09:55'), 'text', T('نذكّركم بإحضار أي صور للكوشة تعجبكم لنناقشها خلال الزيارة.', 'A reminder to bring any kosha pictures you like so we can discuss them during the visit.'), { status: 'delivered' }),

  // Lumi x Reem, Wed 4 Nov, 4:30 PM (completed, now read-only)
  sys('conv-visit-lumi-reem', at('2026-11-02', '11:00'), 'system', 'A group chat opened for your visit on Wed 4 Nov: you, Lumi Marina Hotel and Ghazal support.', 'فُتحت محادثة جماعية لزيارتكم يوم الأربعاء 4 نوفمبر: أنتم وفندق لومي مارينا ودعم غزل.'),
  msg('conv-visit-lumi-reem', 'client', 'ريم الدوسري', at('2026-11-02', '11:05'), 'text', T('السلام عليكم، نرغب بزيارة القاعة الأربعاء 4 نوفمبر الساعة 4:30 مساءً.', 'Peace be upon you. We would like to visit the hall on Wednesday 4 November at 4:30 PM.')),
  msg('conv-visit-lumi-reem', 'venue', 'Nadia Al-Failakawi', at('2026-11-02', '14:10'), 'text', T('وعليكم السلام ورحمة الله. موعدكم مؤكد الأربعاء 4 نوفمبر الساعة 4:30 م عند الاستقبال.', 'And peace be upon you. Your visit is confirmed for Wednesday 4 November at 4:30 PM at reception.')),
  msg('conv-visit-lumi-reem', 'support', 'Lama Al-Khalidi', at('2026-11-02', '14:12'), 'text', T('أهلاً ريم، أنا لمى من دعم غزل. أنا معكم لأي استفسار قبل الزيارة.', 'Hello Reem, I am Lama from Ghazal support. I am with you for any question before the visit.')),
  msg('conv-visit-lumi-reem', 'client', 'ريم الدوسري', at('2026-11-04', '16:32'), 'text', T('وصلنا، نحن عند الاستقبال.', 'We have arrived, we are at reception.')),
  sys('conv-visit-lumi-reem', at('2026-11-04', '16:35'), 'system', 'Arrival confirmed by the hotel representative.', 'أكّد ممثل الفندق وصولكم.'),
  sys('conv-visit-lumi-reem', at('2026-11-04', '17:20'), 'system', 'The visit is complete.', 'اكتملت الزيارة.'),
  sys('conv-visit-lumi-reem', at('2026-11-04', '17:21'), 'booking_card', 'Voucher', 'الكوبون', {
    kind: 'voucher_offer',
    title: bil('Get your voucher', 'احصلوا على الكوبون'),
    lines: [bil('Request this hall at the voucher price', 'اطلبوا هذه القاعة بسعر الكوبون'), bil('One voucher per request', 'كوبون واحد لكل طلب')],
    refId: 'V05',
  }),
  sys('conv-visit-lumi-reem', at('2026-11-05', '16:30'), 'system', 'This chat is now read-only.', 'أصبحت هذه المحادثة للقراءة فقط.'),

  // Aurelia x Rashed, Sat 21 Nov, 6:00 PM (requested: waiting for the hotel representative)
  sys('conv-visit-aurelia-rashed', at('2026-11-12', '14:35'), 'system', 'A group chat opened for your visit on Sat 21 Nov: you, Aurelia Gulf Hotel and Ghazal support.', 'فُتحت محادثة جماعية لزيارتكم يوم السبت 21 نوفمبر: أنتم وفندق أوريليا الخليج ودعم غزل.'),
  msg('conv-visit-aurelia-rashed', 'client', 'راشد العجمي', at('2026-11-12', '14:36'), 'text', T('السلام عليكم، نبي نزور القاعة يوم السبت 21 الساعة 6 مساءً مع الوالدة وأخواتي.', 'Peace be upon you. We would like to visit the hall on Saturday the 21st at 6 PM with my mother and sisters.'), { status: 'delivered' }),
  msg('conv-visit-aurelia-rashed', 'support', 'Lama Al-Khalidi', at('2026-11-12', '14:42'), 'text', T('أهلاً راشد، أنا لمى من دعم غزل. وصل طلب الزيارة للفندق وننتظر تأكيد ممثل الفندق.', 'Hello Rashed, I am Lama from Ghazal support. The visit request reached the hotel and we are waiting for the hotel representative to confirm.'), { status: 'delivered' }),
)

export const heroReplyDraftIds = messages.filter((m) => m.draft).map((m) => m.id)

// Support thread (ADR 0035 D5): the client asked for a credit voucher after a declined request; support granted it. No money goes back.
messages.push(
  msg('conv-support-reem', 'client', 'ريم الدوسري', at('2026-11-02', '20:30'), 'text', T('القاعة رفضت طلبنا. نبي كوبون بديل نستخدمه في قاعة ثانية.', 'The hall declined our request. We would like another voucher to use at a different hall.')),
  msg('conv-support-reem', 'support', 'Lama Al-Khalidi', at('2026-11-02', '21:05'), 'text', T('وصلنا طلبكم ونراجعه. نرد عليكم خلال يومين.', 'We received your request and are reviewing it. We will reply within two days.')),
  msg('conv-support-reem', 'support', 'Lama Al-Khalidi', at('2026-11-05', '10:00'), 'text', T('تمت الموافقة. أضفنا كوبون رصيد إلى حسابكم، صالح 60 يومًا في أي قاعة أو فندق أو خدمة.', 'Approved. We added a credit voucher to your account, valid for 60 days at any hall, hotel or service.')),
  msg('conv-support-reem', 'support', 'Lama Al-Khalidi', at('2026-11-05', '10:01'), 'credit_card', null, {
    card: {
      kind: 'credit_voucher',
      title: bil('Credit voucher added', 'تمت إضافة كوبون رصيد'),
      lines: [bil('Any hall, hotel or service', 'أي قاعة أو فندق أو خدمة'), bil('Valid for 60 days', 'صالح لمدة 60 يومًا')],
      refId: 'vch-GV-2611-C4RD',
    },
  }),
)
