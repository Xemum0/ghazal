// Specimen copy for the nav gallery only (a design-system page, not a product screen): hand-written in both languages on purpose.
// Product strings live in packages/i18n; the demo uses real catalog keys wherever one exists (tabs, back, close, errors).
import type { Lang } from '../../../shell/lang'

export type DemoCopy = {
  pageTitle: string
  pageLede: string
  sections: { proto: string; bars: string; overlays: string; media: string; frames: string }
  // live prototype
  protoNote: string
  discover: string
  seeAll: string
  briefRow: string
  briefTitle: string
  briefDate: string
  briefGuests: string
  briefArea: string
  briefBudget: string
  briefDone: string
  guestsValue: string
  areaValue: string
  budgetValue: string
  venueFacts: string
  requestThisDate: string
  totalFor: string
  noPayment: string
  confirmTitle: string
  confirmBody: string
  confirmCta: string
  confirmCancel: string
  sentToast: string
  tabRootBody: (name: string) => string
  showToast: string
  openSheet: string
  openDialog: string
  toastDone: string
  undoToast: string
  undone: string
  // specimens
  specimens: Record<string, string>
  banner: { offline: string; info: string; warning: string; retry: string }
  emptyTitle: string
  emptyBody: string
  emptyAction: string
  faq: { title: string; body: string }[]
  dialogDestructiveTitle: string
  dialogDestructiveBody: string
  dialogDestructiveConfirm: string
  sheetTitle: string
  sheetBody: string
  searchPlaceholder: string
  largeTitle: string
  standardTitle: string
  subtitle: string
  galleryLabel: string
}

const en: DemoCopy = {
  pageTitle: 'Navigation, overlays and the device frame',
  pageLede: 'The frame every screen runs inside. Static frames are deterministic; the prototype is live. Switch language in the URL: lang=en | ar.',
  sections: { proto: 'Live prototype', bars: 'Bars', overlays: 'Overlays and states', media: 'Pager, carousel, gallery, accordion', frames: 'Device chrome' },
  protoNote: 'Tap a hall, open the date sheet, request a date. Tabs keep their own stack; re-tap a tab to return to its root.',
  discover: 'Discover',
  seeAll: 'Halls open on your date',
  briefRow: 'Thursday 14 January 2027',
  briefTitle: 'Your date',
  briefDate: 'Date',
  briefGuests: 'Guests',
  briefArea: 'Area',
  briefBudget: 'Budget',
  briefDone: 'Done',
  guestsValue: '350 guests',
  areaValue: 'Salmiya or Sharq',
  budgetValue: 'KD 20,000 to 35,000',
  venueFacts: 'Danah Ballroom seats up to 650. Ladies reception, evening session.',
  requestThisDate: 'Request this date',
  totalFor: 'Total for 350 guests',
  noPayment: 'No payment now. Nothing is charged until the hotel approves.',
  confirmTitle: 'Send this request?',
  confirmBody: 'The hotel replies within 24 hours. You pay nothing now.',
  confirmCta: 'Send request',
  confirmCancel: 'Not yet',
  sentToast: 'Request sent to the hotel',
  tabRootBody: name => `${name} is a tab root. Its stack survives a switch.`,
  showToast: 'Show a toast',
  openSheet: 'Open a sheet',
  openDialog: 'Open a dialog',
  toastDone: 'Saved to your list',
  undoToast: 'Request withdrawn',
  undone: 'Undone',
  specimens: {
    tabClient: 'TabBar, client (My Wedding dot, Messages count)',
    tabHotel: 'TabBar, hotel (Bookings count, danger tint with text)',
    tabPressed: 'TabBar, pressed',
    topStandard: 'TopBar, standard with actions',
    topLarge: 'TopBar, large title (scrolled: collapsed)',
    topTransparent: 'TopBar, transparent over a photograph',
    topSolid: 'TopBar, transparent after the hero (solid)',
    topSearch: 'TopBar, with search',
    action: 'ActionBar, price + primary + note',
    actionHotel: 'ActionBar, hotel save bar (tab bar below)',
    sheet: 'Sheet',
    dialog: 'Dialog',
    dialogDestructive: 'Dialog, destructive',
    banners: 'Banner: offline, info, warning',
    empty: 'EmptyState',
    error: 'ErrorState',
    pull: 'PullIndicator: pulling, released',
    pager: 'Pager, peek (item width = frame - 2 x gutter - peek)',
    hero: 'ImageCarousel, hero',
    tour: 'ImageCarousel, tour 16:10',
    viewer: 'FullscreenGallery (tap a hero photograph)',
    accordion: 'Accordion',
    statusDark: 'Status chrome, dark content',
    statusLight: 'Status chrome, light content over imagery',
    chromeNone: 'Chrome none',
    bezel: 'Thin bezel (player)',
    live: 'Live frame',
  },
  banner: { offline: 'You are offline. Showing what was last loaded.', info: 'Prices include service charge.', warning: 'This date is on hold for another couple.', retry: 'Try again' },
  emptyTitle: 'No saved halls yet',
  emptyBody: 'Tap the heart on a hall and it waits here for you.',
  emptyAction: 'Browse halls',
  faq: [
    { title: 'When do I pay?', body: 'After the hotel approves your request you have 24 hours to pay the deposit. Nothing is charged before.' },
    { title: 'Can I change the date?', body: 'Ask from the booking page. The hotel proposes new dates and holds your price for 72 hours.' },
    { title: 'What does the deposit cover?', body: 'The deposit is part of your total, never an extra. The balance is due 14 days before your day.' },
  ],
  dialogDestructiveTitle: 'Cancel this request?',
  dialogDestructiveBody: 'The hotel will be told. You have not paid anything, so nothing is refunded.',
  dialogDestructiveConfirm: 'Cancel request',
  sheetTitle: 'Your date',
  sheetBody: 'Date, guests, area and budget shape every price you see.',
  searchPlaceholder: 'Search halls and hotels',
  largeTitle: 'Saved',
  standardTitle: 'Aurelia Gulf Hotel',
  subtitle: 'Sharq',
  galleryLabel: 'Photos of Aurelia Gulf Hotel',
}

const ar: DemoCopy = {
  pageTitle: 'التنقل والطبقات وإطار الجهاز',
  pageLede: 'الإطار الذي تعمل داخله كل شاشة. الإطارات الثابتة حتمية، والنموذج التجريبي حي. تبديل اللغة من الرابط: lang=en | ar.',
  sections: { proto: 'النموذج الحي', bars: 'الأشرطة', overlays: 'الطبقات والحالات', media: 'المنزلق والصور والأكورديون', frames: 'واجهة الجهاز' },
  protoNote: 'اختاروا قاعة، افتحوا ورقة التاريخ، ثم أرسلوا الطلب. لكل تبويب مساره الخاص، والضغط على التبويب الحالي يعيدكم إلى جذره.',
  discover: 'استكشف',
  seeAll: 'قاعات متاحة في تاريخكم',
  briefRow: 'الخميس 14 يناير 2027',
  briefTitle: 'تاريخكم',
  briefDate: 'التاريخ',
  briefGuests: 'عدد الضيوف',
  briefArea: 'المنطقة',
  briefBudget: 'الميزانية',
  briefDone: 'تم',
  guestsValue: '350 ضيفًا',
  areaValue: 'السالمية أو شرق',
  budgetValue: '20,000 إلى 35,000 د.ك',
  venueFacts: 'قاعة دانة تتسع حتى 650. حفل نسائي، الفترة المسائية.',
  requestThisDate: 'اطلبوا هذا التاريخ',
  totalFor: 'الإجمالي لعدد 350 مدعوًا',
  noPayment: 'لا دفع الآن. لن يُخصم شيء حتى يوافق الفندق.',
  confirmTitle: 'إرسال هذا الطلب؟',
  confirmBody: 'يرد الفندق خلال 24 ساعة. لا شيء يُدفع الآن.',
  confirmCta: 'إرسال الطلب',
  confirmCancel: 'ليس بعد',
  sentToast: 'تم إرسال الطلب إلى الفندق',
  tabRootBody: name => `${name} هو جذر تبويب. يبقى مساره عند التبديل.`,
  showToast: 'عرض إشعار',
  openSheet: 'فتح ورقة',
  openDialog: 'فتح نافذة',
  toastDone: 'تمت الإضافة إلى قائمتكم',
  undoToast: 'تم سحب الطلب',
  undone: 'تم التراجع',
  specimens: {
    tabClient: 'شريط التبويب، العميل (نقطة زفافكم وعدد الرسائل)',
    tabHotel: 'شريط التبويب، الفندق (عدد الحجوزات بلون التنبيه مع نص)',
    tabPressed: 'شريط التبويب، حالة الضغط',
    topStandard: 'الشريط العلوي، عادي مع إجراءات',
    topLarge: 'الشريط العلوي، عنوان كبير (بعد التمرير: مطوي)',
    topTransparent: 'الشريط العلوي، شفاف فوق صورة',
    topSolid: 'الشريط العلوي، شفاف بعد الصورة (مصمت)',
    topSearch: 'الشريط العلوي، مع بحث',
    action: 'شريط الإجراء، السعر والزر الرئيسي وملاحظة',
    actionHotel: 'شريط الإجراء، حفظ للفندق (فوق شريط التبويب)',
    sheet: 'الورقة',
    dialog: 'النافذة',
    dialogDestructive: 'النافذة، إجراء لا رجعة فيه',
    banners: 'اللافتة: غير متصل، معلومة، تنبيه',
    empty: 'حالة فارغة',
    error: 'حالة خطأ',
    pull: 'مؤشر السحب: أثناء السحب وبعد الإفلات',
    pager: 'المنزلق مع إطلالة (عرض العنصر = الإطار - 2 × الهامش - الإطلالة)',
    hero: 'عرض الصور، رئيسي',
    tour: 'عرض الصور، جولة 16:10',
    viewer: 'عارض الصور بملء الشاشة (اضغطوا على صورة رئيسية)',
    accordion: 'الأكورديون',
    statusDark: 'واجهة النظام، محتوى داكن',
    statusLight: 'واجهة النظام، محتوى فاتح فوق صورة',
    chromeNone: 'بلا واجهة',
    bezel: 'إطار رفيع (للمشغّل)',
    live: 'إطار حي',
  },
  banner: { offline: 'لا يوجد اتصال. نعرض آخر ما تم تحميله.', info: 'الأسعار تشمل رسوم الخدمة.', warning: 'هذا التاريخ محجوز مؤقتًا لحجز آخر.', retry: 'إعادة المحاولة' },
  emptyTitle: 'لا قاعات محفوظة بعد',
  emptyBody: 'اضغطوا على القلب في أي قاعة لتنتظركم هنا.',
  emptyAction: 'تصفح القاعات',
  faq: [
    { title: 'متى أدفع؟', body: 'بعد موافقة الفندق على طلبكم أمامكم 24 ساعة لدفع العربون. لا يُخصم شيء قبل ذلك.' },
    { title: 'هل أستطيع تغيير التاريخ؟', body: 'اطلبوا من صفحة الحجز. يقترح الفندق تواريخ جديدة ويحفظ سعركم 72 ساعة.' },
    { title: 'ماذا يغطي العربون؟', body: 'العربون جزء من إجماليكم وليس رسمًا إضافيًا. المتبقي يستحق قبل يومكم بـ 14 يومًا.' },
  ],
  dialogDestructiveTitle: 'إلغاء هذا الطلب؟',
  dialogDestructiveBody: 'سيُبلَّغ الفندق. لم تدفعوا شيئًا، فلا مبلغ يُسترد.',
  dialogDestructiveConfirm: 'إلغاء الطلب',
  sheetTitle: 'تاريخكم',
  sheetBody: 'التاريخ وعدد الضيوف والمنطقة والميزانية تحدد كل سعر تشاهدونه.',
  searchPlaceholder: 'ابحثوا عن قاعة أو فندق',
  largeTitle: 'المفضلة',
  standardTitle: 'فندق أوريليا الخليج',
  subtitle: 'شرق',
  galleryLabel: 'صور فندق أوريليا الخليج',
}

export const DEMO_COPY: Record<Lang, DemoCopy> = { en, ar }
