// Reviews: monogram authors (first name plus initial), owner replies on some, no photos (ADR 0015 D7).
// V01 reviews are hand-written (they carry the screen-quoted facts); other venues draw from a pool by a seeded function.
import { bil, monogramOf } from './lib.mjs'
import { addDays, toKuwaitInstant, instantMs, weekdayOf } from '../src/engine/dates.ts'
import { seeded, pick } from '../src/engine/seeded.ts'

const NOW_MS = Date.parse('2026-11-12T16:00:00+03:00')

const cat = (venue, food, service, value) => ({ venue, food, service, value })
const clampHalf = (n) => Math.max(1, Math.min(5, Math.round(n * 2) / 2))

// ---------------------------------------------------------------- authors
const womenAuthors = [
  ['نورة ع.', 'Noura A.'], ['مها ك.', 'Maha K.'], ['هند ش.', 'Hind S.'], ['فاطمة ر.', 'Fatima R.'],
  ['سارة ب.', 'Sara B.'], ['دانة م.', 'Dana M.'], ['لولوة ح.', 'Lulwa H.'], ['أمل ظ.', 'Amal D.'],
  ['شيخة ف.', 'Shaikha F.'], ['منيرة ص.', 'Munira S.'], ['ريما ن.', 'Reema N.'], ['جود ع.', 'Joud A.'],
  ['غدير ق.', 'Ghadeer Q.'], ['بدور ز.', 'Budoor Z.'], ['أسماء خ.', 'Asmaa K.'], ['هدى ت.', 'Huda T.'],
  ['وفاء ج.', 'Wafa J.'], ['رنا ه.', 'Rana H.'], ['ميثاء د.', 'Maitha D.'], ['علياء ص.', 'Alya S.'],
]
const menAuthors = [
  ['فهد ش.', 'Fahad S.'], ['خالد م.', 'Khalid M.'], ['يوسف ح.', 'Yousef H.'], ['سلمان ر.', 'Salman R.'],
  ['بدر ع.', 'Badr A.'], ['عبدالله ك.', 'Abdullah K.'], ['ناصر ف.', 'Nasser F.'], ['مشاري ق.', 'Mishari Q.'],
]

// ---------------------------------------------------------------- snippets
// tone: high 4.5-5, mid 3.5-4.5, low 2.5-3.5. `for`: audience and venue kind it fits. {hall} is replaced by the hall name.
const S = (tone, forWhom, ar, en, mods = {}) => ({ tone, for: forWhom, ar, en, mods })
const snippets = [
  S('high', 'women', 'الكوشة كانت أجمل مما توقعنا والإضاءة مريحة. الفريق التزم بالموعد وتجهيز {hall} كان جاهزًا قبل وصول الضيوف.', 'The kosha was better than we imagined and the lighting was soft. The team kept to the schedule and {hall} was ready before guests arrived.'),
  S('high', 'women', 'الأكل طازج والبوفيه متنوع، وكيكة العرض كانت جميلة. التنسيق مع مسؤولة الحفلات كان سهلًا من أول رسالة.', 'The food was fresh and the buffet varied, and the show cake was lovely. Coordinating with the events manager was easy from the first message.', { food: 0.5 }),
  S('high', 'women', 'الصوت واضح دون إزعاج، والمدخل المنفصل أراح الجميع. أنصح بها لمن يبحث عن حفل هادئ ومنظم.', 'The sound was clear without being loud, and the separate entrance put everyone at ease. I recommend it for a calm, well-run evening.'),
  S('high', 'women', 'غرفة العروس مرتبة وهادئة وفيها كل ما نحتاجه قبل الزفّة. شكرًا لفريق الاستقبال.', 'The bridal room was tidy and calm with everything needed before the zaffa. Thank you to the reception team.', { service: 0.5 }),
  S('high', 'women', 'كانت أمسية ممتازة والجميع مرتاح. الإدارة ردّت على كل أسئلتنا قبل الحفل وبعده.', 'It was an excellent evening and everyone was comfortable. Management answered all our questions before and after the event.', { service: 0.5 }),
  S('high', 'women', 'المكان واسع ويتسع لكل المعازيم، والتكييف ممتاز. الموظفات محترمات وسريعات في الخدمة.', 'The space is generous for all our guests and the air conditioning was excellent. The staff were courteous and quick.', { venue: 0.5 }),
  S('high', 'women', 'استقبال القهوة والتمر عند المدخل كان مرتبًا، والتصوير بمصوّرات فقط أراح الضيفات.', 'The coffee and dates welcome at the entrance was well organised, and having female photographers only put the guests at ease.', { service: 0.5 }),
  S('high', 'men', 'استقبال الرجال كان منظمًا، والقهوة والتمر عند المدخل بشكل مرتب. العشاء جاء في وقته.', 'The men’s reception was well organised, with coffee and dates at the entrance. Dinner arrived on time.'),
  S('high', 'men', 'قاعة الرجال واسعة والمواقف كافية، والفريق ساعدنا في ترتيب الطاولات حسب العدد.', 'The men’s hall is spacious with enough parking, and the team helped arrange the tables for our numbers.', { service: 0.5 }),
  S('mid', 'women', 'المكان جميل والأكل جيد، لكن الدخول كان بطيئًا قليلًا بعد العاشرة. نتمنى زيادة عدد الموظفين عند المدخل.', 'Beautiful venue and good food, though entry was a little slow after ten. More staff at the entrance would help.', { service: -0.5 }),
  S('mid', 'women', 'القاعة نظيفة والخدمة جيدة. السعر مناسب لكن التجهيز تأخر نحو نصف ساعة.', 'The hall is clean and the service good. The price is fair but setup ran about half an hour late.', { service: -0.5, value: 0.5 }),
  S('mid', 'women', 'الكوشة الأساسية جميلة والصوت واضح. بعض أطباق البوفيه نفدت مبكرًا.', 'The basic kosha is lovely and the sound was clear. A few buffet dishes ran out early.', { food: -1 }),
  S('mid', 'women', 'التنظيم جيد بشكل عام، والمواقف بعيدة قليلًا عن المدخل النسائي.', 'Organisation was good overall, though parking is a little far from the ladies’ entrance.', { venue: -0.5 }),
  S('mid', 'women', 'الموقع ممتاز لكن المكيف كان قويًا في جهة المنصة. تم تعديله بسرعة عندما أبلغنا الفريق.', 'Excellent location, but the air conditioning was strong near the stage. The team fixed it quickly once we mentioned it.'),
  S('mid', 'men', 'قاعة جيدة لكن القهوة تأخرت في البداية. بقية الخدمة كانت على ما يرام.', 'A good hall, but the coffee was slow at the start. The rest of the service was fine.', { service: -0.5 }),
  S('low', 'women', 'الأكل كان عاديًا ولم يكن بمستوى السعر. القاعة جميلة لكن الخدمة تحتاج تحسينًا.', 'The food was ordinary for the price. The hall is beautiful but service needs improvement.', { food: -1.5, value: -1, service: -1 }),
  S('low', 'women', 'تأخر بدء الحفل لأن الإضاءة لم تكن جاهزة. تعاملت الإدارة معه بلطف لكننا كنا نفضّل جاهزية أفضل.', 'The start was delayed because the lighting was not ready. Management handled it kindly, but we would have preferred better readiness.', { service: -1 }),
  S('high', 'value', 'السعر مناسب جدًا للعدد، والقاعة واسعة ونظيفة. مناسبة للعائلات الكبيرة.', 'The price is very reasonable for the numbers, and the hall is spacious and clean. A good fit for large families.', { value: 1 }),
  S('high', 'hallonly', 'استأجرنا القاعة فقط وأحضرنا المتعهد. التعاون ممتاز والقاعة جاهزة في الوقت.', 'We hired the hall only and brought our caterer. The cooperation was excellent and the hall was ready on time.', { food: -0.5 }),
  S('high', 'voucher', 'سعر الكوبون طُبّق في القاعة كما هو معروض، والفريق كان واضحًا في كل التفاصيل. القاعة كما في الصور.', 'The voucher price was applied at the venue exactly as shown, and the team was clear about every detail. The hall matches the photos.', { value: 0.5 }),
  S('high', 'outdoor', 'الإطلالة على البحر رائعة والمرج مرتب. الجو كان لطيفًا والقاعة الداخلية البديلة جاهزة.', 'The sea view is wonderful and the lawn was neatly set. The weather was kind and the indoor backup was ready.', { venue: 0.5 }),
  S('high', 'villa', 'فيلا هادئة وخصوصية تامة لعائلتنا. جهّزنا الضيافة بأنفسنا والفريق ساعدنا في الترتيب.', 'A calm villa with complete privacy for our family. We arranged our own catering and the team helped with the setup.', { venue: 0.5, food: -0.5 }),
  S('high', 'women', 'استقبال الضيوف كان راقيًا من الدخول إلى المنصة، والتنسيق مع الفريق سهّل علينا الكثير.', 'Welcoming guests felt refined from the entrance to the stage, and coordinating with the team made things much easier.', { service: 0.5 }),
  S('high', 'women', 'الإضاءة مع الكوشة جاءت متناسقة تمامًا، والقاعة بدت أجمل من الصور.', 'The lighting with the kosha was perfectly matched and the hall looked even better than the photos.', { venue: 0.5 }),
  S('high', 'women', 'الضيافة كانت مرتبة ومتجددة طوال الحفل، وما واجهنا أي تأخير في تقديم العشاء.', 'Hospitality was orderly and kept refreshed through the evening, and dinner was served without any delay.', { food: 0.5 }),
  S('high', 'women', 'مدخل منفصل ومواقف قريبة، وأهلنا ارتاحوا كثيرًا. شكرًا لفريق الأمن على التنظيم.', 'A separate entrance and nearby parking put our families at ease. Thank you to the security team for the organisation.'),
  S('high', 'women', 'الفريق ساعدنا في ترتيب الطاولات وتوزيع الضيوف، وانتهى الحفل في موعده دون أي ارتباك.', 'The team helped arrange the tables and seat the guests, and the evening ended on time without any confusion.', { service: 0.5 }),
  S('high', 'women', 'حفل هادئ ومنظم، والبوفيه كان متنوعًا مع أطباق ساخنة وباردة وحلويات متجددة.', 'A calm, organised evening, with a varied buffet of hot and cold dishes and refreshed desserts.', { food: 0.5 }),
  S('mid', 'women', 'القاعة جميلة والخدمة جيدة، لكن الصوت كان مرتفعًا قليلًا في بداية الحفل وتم تعديله بعد طلبنا.', 'A beautiful hall and good service, though the sound was a little loud at the start and was adjusted when we asked.'),
  S('mid', 'women', 'الأكل لذيذ لكن الحلويات تأخرت في الوصول. بقية التفاصيل كانت منظمة.', 'The food was delicious but desserts were late to arrive. The rest was well organised.', { food: -0.5 }),
  S('mid', 'women', 'السعر مناسب مقابل ما قُدّم، والمواقف تحتاج تنظيمًا أفضل في الذروة.', 'Fair value for what was offered, though parking needs better organisation at peak times.', { value: 0.5, venue: -0.5 }),
  S('mid', 'women', 'التجهيز جيد بشكل عام، وغرفة العروس صغيرة قليلًا لعدد المرافقات.', 'Setup was good overall, though the bridal room is a little small for the number of companions.', { venue: -0.5 }),
  S('low', 'women', 'توقعنا خدمة أسرع في الاستقبال، وتأخر وصول العشاء. القاعة نفسها جميلة.', 'We expected faster service at the welcome and dinner arrived late. The hall itself is lovely.', { service: -1, food: -0.5 }),
  S('high', 'men', 'القاعة مرتبة والخدمة سريعة، والقهوة والتمر قُدّما عند الباب بشكل لائق.', 'The hall was tidy and the service quick, with coffee and dates offered at the door in good style.'),
  S('high', 'men', 'العشاء كان جاهزًا في وقته، والفريق متعاون في ترتيب الدخول والخروج.', 'Dinner was ready on time and the team was cooperative with arrivals and departures.', { service: 0.5 }),
  S('mid', 'men', 'مكان مناسب للاستقبال الرجالي، لكن المواقف ضاقت قليلًا في الذروة.', 'A good place for the men’s reception, though parking got tight at the busiest time.', { venue: -0.5 }),
  S('high', 'value', 'قاعة واسعة وسعرها مناسب للعدد الكبير، والفريق يرد بسرعة على الاستفسارات.', 'A spacious hall priced fairly for a large group, and the team answers questions quickly.', { value: 1, service: 0.5 }),
]


// ---------------------------------------------------------------- owner replies
const replies = [
  bil('Thank you for your kind words. We would be glad to host you again.', 'نشكركم على كلماتكم الطيبة، ويسعدنا استضافتكم مجددًا في مناسباتكم القادمة.'),
  bil('Thank you for the note about the start. We reviewed the setup schedule with the team so the lighting is ready before guests arrive.', 'شكرًا على ملاحظتكم حول بداية الحفل. راجعنا جدول التجهيز مع الفريق ليكون كل شيء جاهزًا قبل وصول الضيوف.'),
  bil('We appreciate your feedback. The buffet layout was adjusted so dishes are replenished better at peak times.', 'نقدّر ملاحظاتكم. عُدّل ترتيب البوفيه لتعويض الأطباق بشكل أفضل في أوقات الذروة.'),
  bil('Thank you. The entrance team has been informed and we will follow up on your point.', 'شكرًا لكم. تم إبلاغ فريق المدخل بملاحظتكم وسنتابع الأمر.'),
  bil('Thank you for choosing us for your evening. Your note on parking has been shared with the team.', 'شكرًا لاختياركم لنا في أمسيتكم. تمت مشاركة ملاحظتكم حول المواقف مع الفريق.'),
]

const staffByVenue = {
  V01: 'Hind Al-Enezi',
}

// ---------------------------------------------------------------- V01 hand-written
const V01_HAND = [
  {
    id: 'rv-V01-01', author: ['نورة ع.', 'Noura A.'], rating: 4.8, categories: cat(5, 4.5, 5, 4.5), audience: 'women', hall: 'danah',
    event: '2026-09-17', posted: '2026-09-20T10:15:00+03:00', origin: 'ar',
    text: bil('Refined hall, excellent organisation; the ladies’ hall team were helpful from arrival to the very end and the buffet was varied and well kept.', 'قاعة راقية والتنظيم ممتاز. فريق القاعة النسائية كان متعاونًا جدًا من لحظة الدخول حتى نهاية الحفل، والبوفيه مرتب ومتنوع.'),
    reply: [bil('Thank you for your kind words. We would be glad to host you again.', 'نشكركم على كلماتكم الطيبة، ويسعدنا استضافتكم مجددًا في مناسباتكم القادمة.'), '2026-09-21T11:00:00+03:00'],
  },
  {
    id: 'rv-V01-02', author: ['منى س.', 'Mona S.'], rating: 3.5, categories: cat(4.0, 3.5, 3.0, 3.5), audience: 'women', hall: 'danah',
    event: '2026-10-30', posted: '2026-11-01T11:00:00+03:00', origin: 'ar',
    text: bil('The location is excellent, but getting into the car park was crowded after ten, and more valet staff would help.', 'الموقع ممتاز لكن الدخول للمواقف كان مزدحمًا بعد العاشرة، ونتمنى زيادة عدد الموظفين في الفاليه.'),
    reply: null,
    draftReply: bil('Thank you for your valuable feedback. The valet team has been increased on busy nights, and we would be glad to host you again.', 'شكرًا لكم على ملاحظاتكم القيّمة. تمت زيادة فريق الفاليه في الليالي المزدحمة، ويسعدنا استضافتكم مجددًا.'),
  },
  {
    id: 'rv-V01-03', author: ['مها ك.', 'Maha K.'], rating: 5, categories: cat(5, 5, 5, 4.5), audience: 'women', hall: 'danah',
    event: '2026-10-09', posted: '2026-10-12T09:40:00+03:00', origin: 'ar',
    text: bil('The kosha was better than we imagined and the lighting was soft. The team kept to the schedule and Danah Ballroom was ready before guests arrived.', 'الكوشة كانت أجمل مما توقعنا والإضاءة مريحة. الفريق التزم بالموعد وكانت قاعة الدانة جاهزة قبل وصول الضيوف.'),
    reply: [bil('Thank you for your kind words. We would be glad to host you again.', 'نشكركم على كلماتكم الطيبة، ويسعدنا استضافتكم مجددًا في مناسباتكم القادمة.'), '2026-10-13T10:00:00+03:00'],
  },
  {
    id: 'rv-V01-04', author: ['فهد ش.', 'Fahad S.'], rating: 4.5, categories: cat(5, 4.5, 5, 4.5), audience: 'men', hall: 'majlis',
    event: '2026-09-24', posted: '2026-09-26T13:20:00+03:00', origin: 'ar',
    text: bil('The men’s reception was well organised, with coffee and dates at the entrance. Dinner arrived on time.', 'استقبال الرجال كان منظمًا، والقهوة والتمر عند المدخل بشكل مرتب. العشاء جاء في وقته.'),
    reply: null,
  },
  {
    id: 'rv-V01-05', author: ['سارة ب.', 'Sara B.'], rating: 4.5, categories: cat(5, 5, 5, 4.5), audience: 'women', hall: 'danah',
    event: '2026-08-20', posted: '2026-08-23T12:05:00+03:00', origin: 'ar',
    text: bil('The food was fresh and the buffet varied, and the show cake was lovely. Coordinating with the events manager was easy from the first message.', 'الأكل طازج والبوفيه متنوع، وكيكة العرض كانت جميلة. التنسيق مع مسؤولة الحفلات كان سهلًا من أول رسالة.'),
    reply: null,
  },
  {
    id: 'rv-V01-06', author: ['لولوة ح.', 'Lulwa H.'], rating: 5, categories: cat(5, 5, 5, 4.5), audience: 'women', hall: 'danah',
    event: '2026-07-16', posted: '2026-07-19T16:30:00+03:00', origin: 'ar',
    text: bil('The sound was clear without being loud, and the separate entrance put everyone at ease. I recommend it for a calm, well-run evening.', 'الصوت واضح دون إزعاج، والمدخل المنفصل أراح الجميع. أنصح بها لمن يبحث عن حفل هادئ ومنظم.'),
    reply: [bil('Thank you for choosing us for your evening. Your note has been shared with the team.', 'شكرًا لاختياركم لنا في أمسيتكم. تمت مشاركة ملاحظتكم مع الفريق.'), '2026-07-20T09:30:00+03:00'],
  },
  {
    id: 'rv-V01-07', author: ['هند ش.', 'Hind S.'], rating: 4, categories: cat(4.5, 4.5, 4.5, 4), audience: 'women', hall: 'danah',
    event: '2026-06-12', posted: '2026-06-14T11:10:00+03:00', origin: 'ar',
    text: bil('A beautiful hall and good service. The price is on the higher side, but you can see where it goes.', 'قاعة جميلة وخدمة جيدة. السعر في الجهة الأعلى لكن يمكن رؤية ما يقابله.'),
    reply: null,
  },
  {
    id: 'rv-V01-08', author: ['يوسف ح.', 'Yousef H.'], rating: 4.5, categories: cat(5, 4.5, 5, 4.5), audience: 'men', hall: 'majlis',
    event: '2026-05-08', posted: '2026-05-11T14:00:00+03:00', origin: 'ar',
    text: bil('The men’s hall is spacious with enough parking, and the team helped arrange the tables for our numbers.', 'قاعة الرجال واسعة والمواقف كافية، والفريق ساعدنا في ترتيب الطاولات حسب العدد.'),
    reply: null,
  },
  {
    id: 'rv-V01-09', author: ['أمل ظ.', 'Amal D.'], rating: 5, categories: cat(5, 4.5, 5, 4.5), audience: 'women', hall: 'danah',
    event: '2026-03-27', posted: '2026-03-30T10:45:00+03:00', origin: 'ar',
    text: bil('The bridal room was tidy and calm with everything needed before the zaffa. Thank you to the reception team.', 'غرفة العروس مرتبة وهادئة وفيها كل ما نحتاجه قبل الزفّة. شكرًا لفريق الاستقبال.'),
    reply: [bil('Thank you for your kind words. We would be glad to host you again.', 'نشكركم على كلماتكم الطيبة، ويسعدنا استضافتكم مجددًا في مناسباتكم القادمة.'), '2026-03-31T09:15:00+03:00'],
  },
  {
    id: 'rv-V01-10', author: ['شيخة ف.', 'Shaikha F.'], rating: 4, categories: cat(5, 4.5, 4.5, 4), audience: 'women', hall: 'danah',
    event: '2026-02-05', posted: '2026-02-08T12:00:00+03:00', origin: 'ar',
    text: bil('Beautiful venue and good food, though entry was a little slow after ten. More staff at the entrance would help.', 'المكان جميل والأكل جيد، لكن الدخول كان بطيئًا قليلًا بعد العاشرة. نتمنى زيادة عدد الموظفين عند المدخل.'),
    reply: [bil('Thank you. The entrance team has been informed and we will follow up on your point.', 'شكرًا لكم. تم إبلاغ فريق المدخل بملاحظتكم وسنتابع الأمر.'), '2026-02-09T10:30:00+03:00'],
  },
  {
    id: 'rv-V01-11', author: ['دانة م.', 'Dana M.'], rating: 5, categories: cat(5, 5, 5, 4.5), audience: 'women', hall: 'danah',
    event: '2026-01-15', posted: '2026-01-18T15:20:00+03:00', origin: 'ar',
    text: bil('It was an excellent evening and everyone was comfortable. Management answered all our questions before and after the event.', 'كانت أمسية ممتازة والجميع مرتاح. الإدارة ردّت على كل أسئلتنا قبل الحفل وبعده.'),
    reply: null,
  },
  {
    id: 'rv-V01-12', author: ['ريما ن.', 'Reema N.'], rating: 4.5, categories: cat(5, 4.5, 5, 4.5), audience: 'women', hall: 'majlis',
    event: '2025-12-12', posted: '2025-12-15T13:35:00+03:00', origin: 'ar',
    text: bil('The coffee and dates welcome at the entrance was well organised, and having female photographers only put the guests at ease.', 'استقبال القهوة والتمر عند المدخل كان مرتبًا، والتصوير بمصوّرات فقط أراح الضيفات.'),
    reply: null,
  },
]

function monoOf(ar) {
  return monogramOf(ar)
}

const meanRating = (c) => Math.round(((c.venue + c.food + c.service + c.value) / 4) * 10) / 10

function handReview(venueId, h) {
  return {
    id: h.id,
    venueId,
    author: bil(h.author[1], h.author[0]),
    monogram: monoOf(h.author[0]),
    anonymous: false,
    rating: meanRating(h.categories),
    categories: h.categories,
    text: h.text,
    origin: h.origin,
    audience: h.audience,
    hallId: `${venueId}-${h.hall}`,
    eventDate: h.event,
    postedAt: h.posted,
    ownerReply: h.reply ? { text: h.reply[0], repliedAt: h.reply[1], by: staffByVenue[venueId] ?? 'Venue team' } : null,
    supportRequest: null,
    replyDraft: h.draftReply ?? null,
    verifiedBooking: true,
    photos: [],
  }
}

// ---------------------------------------------------------------- generated reviews for the other venues
function fitsVenue(sn, venue, audience) {
  const kind =
    venue.style === 'villa' ? 'villa' : venue.style === 'outdoor' || venue.style === 'resort' ? 'outdoor' : null
  if (sn.for === 'women' || sn.for === 'men') return sn.for === audience
  if (sn.for === 'villa') return kind === 'villa'
  if (sn.for === 'outdoor') return kind === 'outdoor'
  if (sn.for === 'hallonly') return venue.tier !== 'prestige'
  if (sn.for === 'voucher') return venue.voucherEnabled && venue.tier === 'signature'
  if (sn.for === 'value') return venue.tier === 'classic' || venue.tier === 'signature'
  return false
}

function toneFor(avg, r) {
  if (avg >= 4.6) return r < 0.9 ? 'high' : r < 0.99 ? 'mid' : 'low'
  if (avg >= 4.3) return r < 0.78 ? 'high' : r < 0.97 ? 'mid' : 'low'
  return r < 0.64 ? 'high' : r < 0.93 ? 'mid' : 'low'
}

function ratingFor(tone, venueId, i) {
  const base = tone === 'high' ? [4.5, 5, 5, 4.5] : tone === 'mid' ? [4, 4, 4, 4.5] : [3, 3, 3.5, 3.5]
  return pick(base, 'rating', venueId, i)
}

function eventDateFor(venueId, i, seasonMonths) {
  // A Thursday, Friday or Saturday between 1 Oct 2025 and 31 Oct 2026 (inside the hall's season), deterministic per venue and index.
  const start = '2025-10-02'
  const span = 395
  for (let attempt = 0; attempt < 40; attempt += 1) {
    let d = addDays(start, Math.floor(seeded('evt', venueId, i, attempt) * span))
    for (let k = 0; k < 7; k += 1) {
      const wd = weekdayOf(d)
      if (wd === 4 || wd === 5 || wd === 6) break
      d = addDays(d, 1)
    }
    const month = Number(d.slice(5, 7))
    if (!seasonMonths || seasonMonths.includes(month)) return d
  }
  throw new Error(`No in-season event date for ${venueId}`)
}

function generate(venue) {
  const n = 6 + Math.floor(seeded('rv-count', venue.id) * 5) // 6..10
  const out = []
  const usedSnips = new Set()
  const usedAuthors = new Set()
  for (let i = 0; i < n; i += 1) {
    const women = venue.halls.some((h) => h.sections.some((s) => s.audience === 'women'))
    const men = venue.halls.some((h) => h.sections.some((s) => s.audience === 'men'))
    const audience = women && (!men || seeded('aud', venue.id, i) < 0.78) ? 'women' : 'men'
    const tone = toneFor(venue.rating.average, seeded('tone', venue.id, i))
    let pool = snippets.filter((s) => s.tone === tone && fitsVenue(s, venue, audience))
    if (pool.length === 0) pool = snippets.filter((s) => fitsVenue(s, venue, audience) && s.tone !== 'low')
    pool = pool.filter((s) => !usedSnips.has(s))
    if (pool.length === 0) pool = snippets.filter((s) => fitsVenue(s, venue, audience))
    const sn = pick(pool, 'snip', venue.id, i)
    usedSnips.add(sn)
    const names = audience === 'women' ? womenAuthors : menAuthors
    let author = pick(names, 'author', venue.id, i)
    for (let k = 1; usedAuthors.has(author[0]) && k < 20; k += 1) author = pick(names, 'author', venue.id, i, k)
    usedAuthors.add(author[0])
    const rating = ratingFor(sn.tone, venue.id, i)
    const m = sn.mods
    const j = (key) => clampHalf(rating + (m[key] ?? 0) + (seeded('cat', venue.id, i, key) < 0.5 ? 0 : -0.5))
    const hall = pick(
      venue.halls.filter((h) => h.sections.some((s) => s.audience === audience)),
      'hall', venue.id, i,
    )
    const eventDate = eventDateFor(venue.id, i, hall.seasonMonths)
    const posted = toKuwaitInstant(instantMs(`${addDays(eventDate, 1 + Math.floor(seeded('lag', venue.id, i) * 3))}T10:30:00+03:00`))
    const cats = { venue: j('venue'), food: j('food'), service: j('service'), value: j('value') }
    const finalRating = meanRating(cats)
    const needsReply = finalRating <= 3.5
    const replied = needsReply ? true : finalRating < 5 && seeded('reply', venue.id, i) < 0.3
    const replyText = needsReply ? pick(replies.slice(1), 'rt', venue.id, i) : replies[0]
    const repliedAt = toKuwaitInstant(instantMs(posted) + (1 + Math.floor(seeded('rl', venue.id, i) * 2)) * 86_400_000)
    const hallName = hall.name
    out.push({
      id: `rv-${venue.id}-${String(i + 1).padStart(2, '0')}`,
      venueId: venue.id,
      author: bil(author[1], author[0]),
      monogram: monoOf(author[0]),
      anonymous: false,
      rating: finalRating,
      categories: cats,
      text: bil(sn.en.replaceAll('{hall}', hallName.en), sn.ar.replaceAll('{hall}', hallName.ar)),
      origin: 'ar',
      audience,
      hallId: hall.id,
      eventDate,
      postedAt: posted,
      ownerReply: replied && instantMs(repliedAt) < NOW_MS ? { text: replyText, repliedAt, by: 'Venue team' } : null,
      supportRequest: null,
      replyDraft: null,
      verifiedBooking: true,
      photos: [],
    })
  }
  return out.sort((a, b) => (a.postedAt < b.postedAt ? 1 : -1))
}

export function buildReviews(venues) {
  const all = []
  for (const v of venues) {
    if (v.id === 'V01') {
      all.push(...V01_HAND.map((h) => handReview('V01', h)).sort((a, b) => (a.postedAt < b.postedAt ? 1 : -1)))
    } else if (v.rating.count > 0) {
      all.push(...generate(v))
    }
  }
  return all
}
