import { bil } from './lib.mjs'

// Areas by governorate (docs/research/kuwait-localization.md section 7; Salmiya, Mishref, Jabriya, Bayan, Salwa and Hateen
// are Hawalli, Fintas and Khiran are Ahmadi, Messila and Funaitees are Mubarak Al-Kabeer). Centroids are approximate and only
// feed the drive-time estimates.
export const governorates = [
  { id: 'capital', name: bil('Capital', 'العاصمة') },
  { id: 'hawalli', name: bil('Hawalli', 'حولي') },
  { id: 'farwaniya', name: bil('Farwaniya', 'الفروانية') },
  { id: 'ahmadi', name: bil('Ahmadi', 'الأحمدي') },
  { id: 'jahra', name: bil('Jahra', 'الجهراء') },
  { id: 'mubarak-al-kabeer', name: bil('Mubarak Al-Kabeer', 'مبارك الكبير') },
]

// [id, governorate, English, Arabic, lat, lng, aliases]
const rows = [
  ['sharq', 'capital', 'Sharq', 'شرق', 29.383, 47.993],
  ['bneid-al-qar', 'capital', 'Bneid Al-Qar', 'بنيد القار', 29.3975, 48.001],
  ['shuwaikh', 'capital', 'Shuwaikh', 'الشويخ', 29.35, 47.938],
  ['dasma', 'capital', 'Dasma', 'الدسمة', 29.369, 47.998],
  ['kaifan', 'capital', 'Kaifan', 'كيفان', 29.355, 47.963],
  ['shamiya', 'capital', 'Shamiya', 'الشامية', 29.3648, 47.9665],
  ['rawda', 'capital', 'Rawda', 'الروضة', 29.334, 47.9945],
  ['adailiya', 'capital', 'Adailiya', 'العديلية', 29.34, 47.968],
  ['qadsiya', 'capital', 'Qadsiya', 'القادسية', 29.35, 47.9715],
  ['mansouriya', 'capital', 'Mansouriya', 'المنصورية', 29.359, 47.989],
  ['surra', 'capital', 'Surra', 'السرة', 29.317, 47.995],
  ['yarmouk', 'capital', 'Yarmouk', 'اليرموك', 29.306, 47.965],
  ['sulaibikhat', 'capital', 'Sulaibikhat', 'الصليبيخات', 29.349, 47.9],
  ['abdullah-al-salem', 'capital', 'Abdullah Al-Salem', 'عبدالله السالم', 29.352, 47.99],
  ['doha', 'capital', 'Doha', 'الدوحة', 29.3645, 47.818],
  ['nuzha', 'capital', 'Nuzha', 'النزهة', 29.349, 47.978],
  ['daiya', 'capital', 'Daiya', 'الدعية', 29.364, 47.994],

  ['hawalli', 'hawalli', 'Hawalli', 'حولي', 29.332, 48.029],
  ['salmiya', 'hawalli', 'Salmiya', 'السالمية', 29.334, 48.076],
  ['jabriya', 'hawalli', 'Jabriya', 'الجابرية', 29.317, 48.031],
  ['bayan', 'hawalli', 'Bayan', 'بيان', 29.3065, 48.0435],
  ['mishref', 'hawalli', 'Mishref', 'مشرف', 29.279, 48.0525],
  ['rumaithiya', 'hawalli', 'Rumaithiya', 'الرميثية', 29.325, 48.06],
  ['salwa', 'hawalli', 'Salwa', 'سلوى', 29.29, 48.078],
  ['shaab', 'hawalli', 'Shaab', 'الشعب', 29.351, 48.039],
  ['salam', 'hawalli', 'Salam', 'السلام', 29.334, 48.0],
  ['hateen', 'hawalli', 'Hateen', 'حطين', 29.305, 48.005],
  ['zahra', 'hawalli', 'Zahra', 'الزهراء', 29.32, 48.025],
  ['siddeeq', 'hawalli', 'Siddeeq', 'الصديق', 29.315, 48.018],
  ['shuhada', 'hawalli', 'Shuhada', 'الشهداء', 29.327, 48.033],
  ['bidaa', 'hawalli', "Bida'a", 'البدع', 29.348, 48.063],
  ['mubarak-al-abdullah', 'hawalli', 'Mubarak Al-Abdullah', 'مبارك العبدالله (غرب مشرف)', 29.268, 48.06],

  ['farwaniya', 'farwaniya', 'Farwaniya', 'الفروانية', 29.278, 47.958],
  ['khaitan', 'farwaniya', 'Khaitan', 'خيطان', 29.283, 47.982],
  ['jleeb-al-shuyoukh', 'farwaniya', 'Jleeb Al-Shuyoukh', 'جليب الشيوخ', 29.262, 47.934],
  ['ardiya', 'farwaniya', 'Ardiya', 'العارضية', 29.34, 47.88],
  ['andalus', 'farwaniya', 'Andalus', 'الأندلس', 29.3, 47.885],
  ['rabiya', 'farwaniya', 'Rabiya', 'الرابية', 29.308, 47.912],
  ['omariya', 'farwaniya', 'Omariya', 'العمرية', 29.304, 47.942],
  ['rehab', 'farwaniya', 'Rehab', 'الرحاب', 29.264, 47.983],
  ['sabah-al-nasser', 'farwaniya', 'Sabah Al-Nasser', 'صباح الناصر', 29.248, 47.953],
  ['ishbiliya', 'farwaniya', 'Ishbiliya', 'إشبيلية', 29.244, 47.945],
  ['ferdous', 'farwaniya', 'Ferdous', 'الفردوس', 29.26, 47.925],
  ['dajeej', 'farwaniya', 'Dajeej', 'الضجيج', 29.28, 47.92],
  ['abdullah-al-mubarak', 'farwaniya', 'Abdullah Al-Mubarak', 'عبدالله المبارك', 29.247, 47.899],
  ['al-rai', 'farwaniya', 'Al-Rai', 'الري', 29.301, 47.939],

  ['ahmadi', 'ahmadi', 'Ahmadi', 'الأحمدي', 29.077, 48.083],
  ['fahaheel', 'ahmadi', 'Fahaheel', 'الفحيحيل', 29.083, 48.13],
  ['mangaf', 'ahmadi', 'Mangaf', 'المنقف', 29.093, 48.129],
  ['mahboula', 'ahmadi', 'Mahboula', 'المهبولة', 29.14, 48.129],
  ['abu-halifa', 'ahmadi', 'Abu Halifa', 'أبو حليفة', 29.144, 48.133],
  ['sabahiya', 'ahmadi', 'Sabahiya', 'الصباحية', 29.121, 48.103],
  ['riqqa', 'ahmadi', 'Riqqa', 'الرقة', 29.133, 48.095],
  ['fintas', 'ahmadi', 'Fintas', 'الفنطاس', 29.193, 48.128],
  ['egaila', 'ahmadi', 'Egaila', 'العقيلة', 29.166, 48.134],
  ['hadiya', 'ahmadi', 'Hadiya', 'هدية', 29.057, 48.07],
  ['dhaher', 'ahmadi', 'Dhaher', 'الظهر', 29.099, 48.075],
  ['wafra', 'ahmadi', 'Wafra', 'الوفرة', 28.635, 47.933],
  ['zour', 'ahmadi', 'Zour', 'الزور', 28.715, 48.29],
  ['khiran', 'ahmadi', 'Khiran', 'الخيران', 28.67, 48.34],
  ['sabah-al-ahmad-sea-city', 'ahmadi', 'Sabah Al-Ahmad Sea City', 'مدينة صباح الأحمد البحرية', 28.716, 48.256],
  ['ali-sabah-al-salem', 'ahmadi', 'Ali Sabah Al-Salem', 'علي صباح السالم', 28.901, 48.011],

  ['jahra', 'jahra', 'Jahra', 'الجهراء', 29.338, 47.674],
  ['qasr', 'jahra', 'Qasr', 'القصر', 29.356, 47.755],
  ['naeem', 'jahra', 'Naeem', 'النعيم', 29.352, 47.705],
  ['oyoun', 'jahra', 'Oyoun', 'العيون', 29.345, 47.685],
  ['waha', 'jahra', 'Waha', 'الواحة', 29.361, 47.7],
  ['taima', 'jahra', 'Taima', 'تيماء', 29.376, 47.726],
  ['saad-al-abdullah', 'jahra', 'Saad Al-Abdullah', 'سعد العبدالله', 29.405, 47.7],
  ['nasseem', 'jahra', 'Nasseem', 'النسيم', 29.415, 47.685],
  ['sulaibiya', 'jahra', 'Sulaibiya', 'الصليبية', 29.243, 47.8],
  ['kazma', 'jahra', 'Kazma', 'كاظمة', 29.5, 47.76],
  ['abdali', 'jahra', 'Abdali', 'العبدلي', 30.02, 47.75],

  ['mubarak-al-kabeer', 'mubarak-al-kabeer', 'Mubarak Al-Kabeer', 'مبارك الكبير', 29.206, 48.06],
  ['qurain', 'mubarak-al-kabeer', 'Qurain', 'القرين', 29.241, 48.064],
  ['adan', 'mubarak-al-kabeer', 'Adan', 'العدان', 29.225, 48.062],
  ['qusour', 'mubarak-al-kabeer', 'Qusour', 'القصور', 29.229, 48.072],
  ['messila', 'mubarak-al-kabeer', 'Messila', 'المسيلة', 29.262, 48.083],
  ['sabah-al-salem', 'mubarak-al-kabeer', 'Sabah Al-Salem', 'صباح السالم', 29.249, 48.06],
  ['abu-fatira', 'mubarak-al-kabeer', 'Abu Fatira', 'أبو فطيرة', 29.22, 48.07],
  ['abu-al-hasaniya', 'mubarak-al-kabeer', 'Abu Al-Hasaniya', 'أبو الحصانية', 29.199, 48.065],
  ['funaitees', 'mubarak-al-kabeer', 'Funaitees', 'الفنيطيس', 29.185, 48.1],
  ['masayel', 'mubarak-al-kabeer', 'Masayel', 'المسايل', 29.254, 48.07],
]

export const areas = rows.map(([id, governorateId, en, ar, lat, lng]) => ({
  id,
  governorateId,
  name: bil(en, ar),
  geo: { lat, lng },
}))

// Origins for "distance from ..." (Compare, Nearby, map chips). The airport is a neutral landmark; the real towers and
// other landmarks never appear next to a fictional venue (ADR 0015).
export const referencePoints = [
  { id: 'ref-salmiya', name: bil('Salmiya', 'السالمية'), areaId: 'salmiya', geo: { lat: 29.334, lng: 48.076 } },
  { id: 'ref-sharq', name: bil('Sharq', 'شرق'), areaId: 'sharq', geo: { lat: 29.383, lng: 47.993 } },
  { id: 'ref-hawalli', name: bil('Hawalli', 'حولي'), areaId: 'hawalli', geo: { lat: 29.332, lng: 48.029 } },
  { id: 'ref-farwaniya', name: bil('Farwaniya', 'الفروانية'), areaId: 'farwaniya', geo: { lat: 29.278, lng: 47.958 } },
  { id: 'ref-jahra', name: bil('Jahra', 'الجهراء'), areaId: 'jahra', geo: { lat: 29.338, lng: 47.674 } },
  { id: 'ref-fahaheel', name: bil('Fahaheel', 'الفحيحيل'), areaId: 'fahaheel', geo: { lat: 29.083, lng: 48.13 } },
  { id: 'ref-airport', name: bil('Kuwait International Airport', 'مطار الكويت الدولي'), areaId: null, geo: { lat: 29.2266, lng: 47.9689 } },
]
