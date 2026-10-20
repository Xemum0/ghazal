import { useState } from 'react'
import { useT } from '../../../i18n'
import { Icon } from '../../core/Icon'
import { OtpInput } from '../OtpInput'
import { PhoneField } from '../PhoneField'
import { SearchField } from '../SearchField'
import { TextArea } from '../TextArea'
import { TextField } from '../TextField'
import { L, Section, Spec, useGalleryLang } from './kit'

export function TextFieldsSection() {
  const { lang } = useGalleryLang()
  const t = useT('common')
  const [code, setCode] = useState('')
  return (
    <Section
      id="fields"
      title={L(lang, 'Text fields', 'حقول النص')}
      note={L(
        lang,
        '56 high, radius 8, paper, ink-500 hairline. Focus turns the border ink-900 at 2 px; error adds an icon and a message; names pick their own direction, email and URL are explicit LTR islands that still start at the screen edge.',
        'الارتفاع 56 والزوايا 8 على سطح ورقي بخط رفيع. عند التركيز يصبح الإطار داكنًا بسماكة 2، وعند الخطأ تظهر أيقونة ورسالة. الأسماء تتبع اتجاه كتابتها، أما البريد والروابط فتُعرض من اليسار إلى اليمين وتبدأ من حافة الشاشة.',
      )}
    >
      <Spec state={L(lang, 'Empty', 'فارغ')}>
        <TextField label={L(lang, 'Full name', 'الاسم الكامل')} placeholder={L(lang, 'Name as on your ID', 'الاسم كما في الهوية')} helper={L(lang, 'Arabic or English, four parts are fine.', 'يمكنك الكتابة بالعربية أو الإنجليزية.')} />
      </Spec>
      <Spec state={L(lang, 'Filled', 'معبأ')}>
        <TextField label={L(lang, 'Full name', 'الاسم الكامل')} defaultValue={L(lang, 'Reem Al-Dosari', 'ريم عبدالله الدوسري')} clearable />
      </Spec>
      <Spec state={L(lang, 'Focus', 'تركيز')}>
        <TextField label={L(lang, 'Full name', 'الاسم الكامل')} defaultValue={L(lang, 'Reem Al-Dosari', 'ريم عبدالله الدوسري')} forceFocus />
      </Spec>
      <Spec state={L(lang, 'Error', 'خطأ')}>
        <TextField label={L(lang, 'Full name', 'الاسم الكامل')} defaultValue="" error={t('commonFieldRequired')} />
      </Spec>
      <Spec state={L(lang, 'Disabled with a reason', 'معطل مع السبب')}>
        <TextField
          label={L(lang, 'Wedding date', 'تاريخ الزفاف')}
          defaultValue={L(lang, 'Thu 14 Jan 2027', 'الخميس 14 يناير 2027')}
          disabled
          disabledReason={L(lang, 'The date is fixed once the hotel approves.', 'يتعذر التعديل بعد موافقة الفندق.')}
        />
      </Spec>
      <Spec state={L(lang, 'Optional, with adornments', 'اختياري مع عناصر جانبية')}>
        <TextField
          label={L(lang, 'Coupon', 'رمز الخصم')}
          optional
          dir="ltr"
          defaultValue="GZ-WELCOME"
          startAdornment={<Icon name="offer" size="sm" />}
          endAdornment={<span className="gz-t-caption">{L(lang, 'Applied', 'مطبق')}</span>}
        />
      </Spec>
      <Spec state={L(lang, 'Email: LTR island', 'البريد: اتجاه من اليسار')}>
        <TextField label={L(lang, 'Email', 'البريد الإلكتروني')} dir="ltr" type="email" inputMode="email" autoComplete="email" defaultValue="reem@example.com" helper={L(lang, 'Receipts and invoices only.', 'للإيصالات والفواتير فقط.')} />
      </Spec>
      <Spec state={L(lang, 'Loading', 'جارٍ التحقق')}>
        <TextField label={L(lang, 'Coupon', 'رمز الخصم')} dir="ltr" defaultValue="GZ-WELCOME" loading />
      </Spec>
      <Spec state={L(lang, 'Verification code (one box per digit)', 'رمز التحقق (خانة لكل رقم)')} wide>
        <OtpInput label={L(lang, 'Code sent to WhatsApp', 'الرمز المرسل عبر واتساب')} value={code} onChange={setCode} helper={L(lang, 'Enter the 6 digits.', 'أدخل الأرقام الستة.')} />
      </Spec>
    </Section>
  )
}

export function PhoneSection() {
  const { lang } = useGalleryLang()
  return (
    <Section
      id="phone"
      title={L(lang, 'Phone', 'رقم الجوال')}
      note={L(
        lang,
        'One LTR compound field in both languages: the fixed +965 chip, then 8 digits grouped 4 + 4. Eastern digits and +965 prefixes are normalised on entry. Label, hint and error follow the screen.',
        'حقل واحد من اليسار إلى اليمين في اللغتين: رمز +965 ثابت ثم 8 أرقام بمجموعتين. تُحوَّل الأرقام الهندية وتُحذف مقدمة +965 عند الإدخال. العنوان والتلميح والخطأ تتبع اتجاه الشاشة.',
      )}
    >
      <Spec state={L(lang, 'Empty', 'فارغ')}>
        <PhoneField helper={L(lang, 'We send a code on WhatsApp.', 'سنرسل لك رمزًا عبر واتساب.')} />
      </Spec>
      <Spec state={L(lang, 'Filled', 'معبأ')}>
        <PhoneField defaultValue="50000012" />
      </Spec>
      <Spec state={L(lang, 'Focus', 'تركيز')}>
        <PhoneField defaultValue="5000" forceFocus />
      </Spec>
      <Spec state={L(lang, 'Error', 'خطأ')}>
        <PhoneField defaultValue="70001234" error={L(lang, 'Numbers starting with 7 are not used in Kuwait.', 'الأرقام التي تبدأ بالرقم 7 غير مستخدمة في الكويت.')} />
      </Spec>
      <Spec state={L(lang, 'Disabled', 'معطل')}>
        <PhoneField defaultValue="50000012" disabled disabledReason={L(lang, 'Change it from account security.', 'يتم التغيير من إعدادات الأمان.')} />
      </Spec>
    </Section>
  )
}

export function OtpSection() {
  const { lang } = useGalleryLang()
  return (
    <Section
      id="otp"
      title={L(lang, 'One-time code', 'رمز التحقق')}
      note={L(
        lang,
        'Six boxes, digit 1 on the left even on an Arabic screen. Auto-advance, paste and autofill spread across the boxes. Errors shake once (not under reduced motion).',
        'ست خانات والرقم الأول عن اليسار حتى في الشاشة العربية. ينتقل المؤشر تلقائيًا ويُوزَّع اللصق والتعبئة التلقائية على الخانات. يهتز الصف مرة واحدة عند الخطأ ولا يهتز مع تقليل الحركة.',
      )}
    >
      <Spec state={L(lang, 'Empty', 'فارغ')}>
        <OtpInput label={L(lang, 'Code', 'الرمز')} />
      </Spec>
      <Spec state={L(lang, 'Partly filled', 'معبأ جزئيًا')}>
        <OtpInput label={L(lang, 'Code', 'الرمز')} defaultValue="482" />
      </Spec>
      <Spec state={L(lang, 'Focus', 'تركيز')}>
        <OtpInput label={L(lang, 'Code', 'الرمز')} forceFocus />
      </Spec>
      <Spec state={L(lang, 'Error', 'خطأ')}>
        <OtpInput label={L(lang, 'Code', 'الرمز')} defaultValue="482915" error={L(lang, 'That code is not right. Try again.', 'الرمز غير صحيح. حاول مرة أخرى.')} />
      </Spec>
      <Spec state={L(lang, 'Verifying', 'جارٍ التحقق')}>
        <OtpInput label={L(lang, 'Code', 'الرمز')} defaultValue="482915" loading />
      </Spec>
      <Spec state={L(lang, 'Disabled', 'معطل')}>
        <OtpInput label={L(lang, 'Code', 'الرمز')} disabled disabledReason={L(lang, 'Too many attempts. Try again later.', 'محاولات كثيرة. حاول لاحقًا.')} />
      </Spec>
    </Section>
  )
}

export function SearchSection() {
  const { lang } = useGalleryLang()
  const [q, setQ] = useState(L(lang, 'Salmiya', 'السالمية'))
  return (
    <Section
      id="search"
      title={L(lang, 'Search', 'البحث')}
      note={L(lang, '48 by default, 44 in compact bars and sheets. The query takes its own direction.', 'الارتفاع 48 افتراضيًا و44 في الأشرطة المدمجة. اتجاه النص يتبع لغة الكتابة.')}
    >
      <Spec state={L(lang, 'Empty, 48', 'فارغ، 48')}>
        <SearchField placeholder={L(lang, 'Search halls, areas or hotels', 'ابحث عن قاعة أو منطقة أو فندق')} />
      </Spec>
      <Spec state={L(lang, 'Filled, 44', 'معبأ، 44')}>
        <SearchField size="sm" value={q} onValueChange={setQ} />
      </Spec>
      <Spec state={L(lang, 'Focus', 'تركيز')}>
        <SearchField placeholder={L(lang, 'Search halls, areas or hotels', 'ابحث عن قاعة أو منطقة أو فندق')} forceFocus />
      </Spec>
      <Spec state={L(lang, 'Loading', 'جارٍ البحث')}>
        <SearchField defaultValue={L(lang, 'Mishref', 'مشرف')} loading />
      </Spec>
      <Spec state={L(lang, 'Disabled', 'معطل')}>
        <SearchField placeholder={L(lang, 'Search is unavailable offline', 'البحث غير متاح بدون اتصال')} disabled />
      </Spec>
    </Section>
  )
}

export function TextAreaSection() {
  const { lang } = useGalleryLang()
  const t = useT('common')
  return (
    <Section
      id="textarea"
      title={L(lang, 'Text area', 'نص متعدد الأسطر')}
      note={L(lang, 'Grows with the text up to eight lines; the counter sits at the end of the hint line.', 'يكبر مع النص حتى ثمانية أسطر، ويظهر العداد في نهاية سطر التلميح.')}
    >
      <Spec state={L(lang, 'Empty', 'فارغ')}>
        <TextArea label={L(lang, 'Notes for the hotel', 'ملاحظات للفندق')} optional placeholder={L(lang, 'Anything the hotel should know', 'أي شيء تودّ إبلاغ الفندق به')} maxLength={300} />
      </Spec>
      <Spec state={L(lang, 'Filled', 'معبأ')}>
        <TextArea
          label={L(lang, 'Notes for the hotel', 'ملاحظات للفندق')}
          optional
          maxLength={300}
          defaultValue={L(lang, 'We would like a separate entrance for the ladies reception and a quiet room for the bride before the entrance.', 'نرغب بمدخل مستقل للحفل النسائي وغرفة هادئة للعروس قبل الدخول.')}
        />
      </Spec>
      <Spec state={L(lang, 'Error', 'خطأ')}>
        <TextArea label={L(lang, 'Notes for the hotel', 'ملاحظات للفندق')} defaultValue="" error={t('commonFieldRequired')} maxLength={300} />
      </Spec>
      <Spec state={L(lang, 'Disabled', 'معطل')}>
        <TextArea label={L(lang, 'Notes for the hotel', 'ملاحظات للفندق')} defaultValue={L(lang, 'Sent with your request.', 'أُرسلت مع طلبك.')} disabled />
      </Spec>
    </Section>
  )
}
