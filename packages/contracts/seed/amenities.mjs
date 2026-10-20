import { bil } from './lib.mjs'

// Amenity taxonomy (glossary section 5). Each fact is an icon plus a plain label; the three states are
// Included / Extra / Not offered. Icon names are keys of the system icon registry (kebab-case, line icons).
const rows = [
  // space
  ['ladies-hall', 'space', "Ladies' hall", 'قاعة نسائية', 'hall'],
  ['men-hall', 'space', "Men's hall", 'قاعة رجالية', 'hall'],
  ['separate-entrance', 'space', 'Separate entrance', 'مدخل منفصل', 'door'],
  ['indoor-backup', 'space', 'Indoor backup', 'قاعة بديلة داخلية', 'roof'],
  ['garden-terrace', 'space', 'Garden or terrace', 'حديقة أو تراس', 'leaf'],
  ['bridal-suite', 'space', 'Bridal suite', 'جناح العروس', 'bed'],
  ['groom-room', 'space', "Groom's room", 'غرفة العريس', 'armchair'],
  ['abaya-cloakroom', 'space', 'Abaya cloakroom', 'غرفة العبايات', 'hanger'],
  ['prayer-room', 'space', 'Prayer room', 'مصلى', 'prayer'],
  ['suite-night', 'space', 'Suite night', 'ليلة في الجناح', 'moon'],
  // services
  ['buffet', 'service', 'Buffet', 'بوفيه مشمول', 'buffet'],
  ['welcome-drinks', 'service', 'Mocktails and juices', 'ضيافة الاستقبال', 'glass'],
  ['gahwa-tea', 'service', 'Gahwa and tea', 'قهوة وشاي', 'dallah'],
  ['valet', 'service', 'Valet', 'فاليه', 'car'],
  ['parking', 'service', 'Free parking', 'مواقف مجانية', 'parking'],
  ['female-security', 'service', 'Female security', 'حراسة نسائية', 'shield'],
  ['accessibility', 'service', 'Accessibility', 'تسهيلات لذوي الإعاقة', 'accessible'],
  ['kids-corner', 'service', "Kids' corner", 'ركن الأطفال', 'blocks'],
  ['show-cake', 'service', 'Show cake', 'كيكة العرض', 'cake'],
  ['bukhoor-service', 'service', 'Bukhoor service', 'خدمة البخور', 'incense'],
  ['coffee-station', 'service', 'Arabic coffee station', 'ركن القهوة العربية', 'dallah'],
  // production
  ['sound-lighting', 'production', 'Sound and lighting', 'صوت وإضاءة', 'speaker'],
  ['led-screens', 'production', 'LED screens', 'شاشات LED', 'screen'],
  ['basic-decor', 'production', 'Basic decor', 'ديكور أساسي مشمول', 'flower'],
  ['kosha', 'production', 'Kosha (bridal stage)', 'الكوشة', 'stage'],
  ['florals', 'production', 'Fresh florals', 'الزهور الطبيعية', 'flower'],
  ['female-photographer', 'production', 'Female photographer', 'مصوّرة', 'camera'],
  ['zaffa', 'production', 'Zaffa (bridal procession)', 'الزفّة', 'drum'],
  // policy
  ['outside-catering', 'policy', 'Outside catering', 'ضيافة خارجية', 'utensils'],
  ['outside-decor', 'policy', 'Outside decor', 'ديكور خارجي', 'palette'],
  ['extra-hour', 'policy', 'Extra hour', 'ساعة إضافية', 'clock'],
]

export const amenityDefs = rows.map(([id, group, en, ar, icon]) => ({ id, group, label: bil(en, ar), icon }))
