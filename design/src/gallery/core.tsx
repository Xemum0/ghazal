// Core components gallery: every primitive of design/src/system/core and system/brand, every variant and every state, in both
// languages. Owner: primitives-owner. Rendered at #/gallery/core?lang=en|ar.
// Product strings (actions, statuses, availability, units, counts) come from the shared `common` messages through useT, and every
// number from the formatter. The specimen annotations (what a cell is called) are hand-written bilingual like the tokens gallery:
// they document the system, they are not product copy.
import { useState, type ReactNode } from 'react'
import { iconNames, isMirrored, type IconName } from '@gz/tokens'
import { useFormat, useT } from '../i18n'
import { useLang } from '../shell/lang'
import {
  Avatar, Badge, Button, Checkbox, Chip, CountBadge, Divider, FilterChip, Icon, IconButton, KeyFact, ListRow, Monogram, Price, Radio,
  RadioGroup, Rating, SectionHeader, Skeleton, SkeletonText, StatusPill, Switch, Tag, ThreadBead, ThreadKnot, ThreadRule, Toast,
  ToastRegion, UndoBar, Wordmark, mirroredIconNames,
  type AvailabilityState, type BookingStatus, type ListingState, type VisitState, type VoucherState,
} from '../system/core'
import './core.css'


// ---------------------------------------------------------------------------------------------------------------- layout kit
function Section({ title, note, children }: { title: string; note?: string; children: ReactNode }) {
  return (
    <section className="cg-sec" data-gz-section={title}>
      <SectionHeader title={title} draw="mount" />
      {note ? <p className="cg-note gz-t-body-s">{note}</p> : null}
      {children}
    </section>
  )
}

function Group({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="cg-group">
      <p className="cg-label gz-t-label">{label}</p>
      {children}
    </div>
  )
}

function Cell({ cap, children, fill = false, stretch = false }: { cap?: string; children: ReactNode; fill?: boolean; stretch?: boolean }) {
  return (
    <div className={`cg-cell${fill ? ' cg-cell--fill' : ''}${stretch ? ' cg-cell--stretch' : ''}`}>
      {children}
      {cap ? <span className="cg-cap gz-t-caption">{cap}</span> : null}
    </div>
  )
}

const Row = ({ children, center = false, col = false }: { children: ReactNode; center?: boolean; col?: boolean }) => (
  <div className={`cg-row${center ? ' cg-row--center' : ''}${col ? ' cg-row--col' : ''}`}>{children}</div>
)

type StageKind = 'panel' | 'ink' | 'tint'
const Stage = ({ kind = 'panel', children }: { kind?: StageKind; children: ReactNode }) => (
  <div className={`cg-stage cg-stage--${kind}${kind === 'ink' ? ' gz-on-dark' : ''}`}>{children}</div>
)

// ---------------------------------------------------------------------------------------------------------------- copy
const C = {
  en: {
    eyebrow: 'Design system',
    title: 'Core components',
    lede: 'The primitives every screen is built from. Each one is shown in every variant and every state, in this language; switch language to check the mirror.',
    switchTo: 'العربية',
    icons: 'Icon',
    iconsNote: 'One registry, four sizes (16, 20, 24, 32), one weight setting. Glyphs with an outline flip in Arabic; nothing else ever does.',
    sizes: 'Sizes', weights: 'Light and regular', registry: 'Registry', mirrors: 'Mirrors in Arabic (ADR 0014)', tones: 'Tones',
    buttons: 'Button',
    buttonsNote: 'One primary per screen. Press is a tone step and a 0.985 scale; the tertiary underline shortens instead. Loading keeps the label and draws the thread once.',
    variants: 'Variants', states: 'States', withIcons: 'With icons', pair: 'Equal pair', fullWidth: 'Full width', heights: 'Heights',
    primary: 'Primary 52', secondary: 'Secondary 48', tertiary: 'Tertiary 44', destructive: 'Destructive 48',
    def: 'Default', pressed: 'Pressed', focus: 'Focus', disabled: 'Disabled', loading: 'Loading', selected: 'Selected',
    reason: 'Pick a date to continue', iconStart: 'Icon start', iconEnd: 'Icon end',
    iconButtons: 'Icon button',
    iconButtonsNote: 'Always a 44 target. Over a photograph it is a canvas disk with the fab ring; a toggle keeps its ink and pops once.',
    plain: 'Plain', outline: 'Outline', overImage: 'Over image 32', overImageLg: 'Over image 44', onScrim: 'On scrim', toggle: 'Toggle off / on',
    chips: 'Chip and filter chip',
    chipsNote: 'Choice is ink and a bead, never a gold fill. The label keeps its width when selected.',
    badges: 'Badge and count badge',
    badgesNote: 'Badges are objective labels. The gold count is the only gold fill besides the one primary action.',
    outlineB: 'Outline + bead', photoB: 'On photo', quietB: 'Quiet', counts: 'Counts', ring: 'Ring on a tab icon', danger: 'SLA danger',
    pills: 'Status pill',
    pillsNote: 'Every request status of ADR 0033, every voucher, visit and listing state and every availability state: icon and label, never colour alone.',
    client: 'Client wording', hotel: 'Partner wording', availability: 'Availability', also: 'Beside a status', vouchers: 'Voucher', visits: 'Site visit', listings: 'Listing',
    avatars: 'Avatar',
    avatarsNote: 'A monogram on rose-100, never a face. The hotel app uses the sans letter; the serif is for venue names and the greeting.',
    serif: 'Serif (client)', sans: 'Sans (hotel)',
    ratings: 'Rating',
    ratingsNote: 'Star, figure and count are separate items. The row fills from inline-start, so it mirrors.',
    prices: 'Price',
    pricesNote: 'Integer fils through the shared formatter. Browse shows dinars; exact shows three decimals with a quiet .000. The currency sits left of the number in both languages.',
    browse: 'Browse', exact: 'Exact', sizesP: 'Sizes', unitsP: 'Units and old price',
    threads: 'Divider and thread rule',
    threadsNote: 'The khayt marks a place, never decoration. It draws on once from inline-start; reduced motion keeps the finished line.',
    hairline: 'Hairline', strong: 'Strong', khayt: 'Khayt 24', full: 'Full', knotV: 'With knot', replay: 'Replay', onInk: 'On ink',
    controls: 'Switch, checkbox, radio',
    controlsNote: 'Choice is ink-700, never gold. Every row is at least 44 high and tappable across its width.',
    off: 'Off', on: 'On', indeterminate: 'Mixed', error: 'Error',
    skeleton: 'Skeleton',
    skeletonNote: 'A static ink-100 shape. No shimmer, nothing loops; the image reveal is the only motion.',
    toasts: 'Toast and undo bar',
    toastsNote: 'Ink bar, canvas text, gold-400 action. The undo line depletes over eight seconds and also runs under reduced motion.',
    toast: 'Toast', undo: 'Undo bar', region: 'Over a bar, 16 above',
    rows: 'List row',
    rowsNote: 'Minimum 64, queue 80. The chevron mirrors; names align by their own first letter.',
    plainR: 'Title and sub-line', withTrail: 'Leading, trailing, chevron', queue: 'Queue row 80', toggleRow: 'With a switch', dangerRow: 'Danger',
    sectionHeaders: 'Section header',
    sectionHeadersNote: 'Khayt, optional eyebrow, title, See all. Client titles are serif; hotel titles are UI weight.',
    facts: 'Key fact and tag', stack: 'Stacked', inline: 'Inline',
    brand: 'Brand',
    brandNote: 'The lockup never mirrors. The thread is always gold-500 and never above the letters.',
    lockup: 'Master lockup', single: 'Single script', monograms: 'Monogram', knots: 'Thread knots', beads: 'Beads', booking: 'Booking 20', compactK: 'Compact 12', ended: 'Ended',
    open: 'Open', now: 'Now', tied: 'Tied', pop: 'Pop',
    guestsLbl: 'Guests', sessionLbl: 'Session', evening: 'Evening', hallLbl: 'Hall', vipLbl: 'VIP lounge',
    nameSample: 'Noura Al-Sabah', venueSample: 'Aurelia Gulf Hotel',
    undoMsg: 'Request withdrawn', toastMsg: 'Saved to your list',
    fav: 'Save to favourites', unfav: 'Remove from favourites', compare: 'Add to compare',
    areaSample: 'Salmiya',
  },
  ar: {
    eyebrow: 'نظام التصميم',
    title: 'المكوّنات الأساسية',
    lede: 'الوحدات التي تُبنى منها كل شاشة. يُعرض كل مكوّن بكل أشكاله وحالاته بهذه اللغة؛ بدّلوا اللغة للتأكد من الانعكاس.',
    switchTo: 'English',
    icons: 'الأيقونة',
    iconsNote: 'سجلّ واحد وأربعة أحجام (16 و20 و24 و32) وإعداد واحد للسُّمك. الرموز ذات الإطار تنعكس بالعربية، ولا شيء غيرها.',
    sizes: 'الأحجام', weights: 'خفيف وعادي', registry: 'السجلّ', mirrors: 'ما ينعكس بالعربية (ADR 0014)', tones: 'الألوان',
    buttons: 'الزر',
    buttonsNote: 'زر أساسي واحد في كل شاشة. الضغط تدرّج لوني وتصغير إلى 0.985؛ ويقصر خط الزر النصي بدلاً من ذلك. التحميل يُبقي النص ويرسم الخيط مرة واحدة.',
    variants: 'الأشكال', states: 'الحالات', withIcons: 'مع أيقونات', pair: 'زوجان متساويان', fullWidth: 'بعرض كامل', heights: 'الارتفاعات',
    primary: 'أساسي 52', secondary: 'ثانوي 48', tertiary: 'نصي 44', destructive: 'حذف 48',
    def: 'افتراضي', pressed: 'مضغوط', focus: 'تركيز', disabled: 'معطّل', loading: 'تحميل', selected: 'محدد',
    reason: 'اختاروا تاريخاً للمتابعة', iconStart: 'أيقونة في البداية', iconEnd: 'أيقونة في النهاية',
    iconButtons: 'زر الأيقونة',
    iconButtonsNote: 'هدف لمس بحجم 44 دائماً. فوق الصورة هو قرص بلون الخلفية مع حلقة خفيفة؛ والمفتاح يبقى بالحبر ويقفز مرة واحدة.',
    plain: 'عادي', outline: 'بإطار', overImage: 'فوق الصورة 32', overImageLg: 'فوق الصورة 44', onScrim: 'فوق التعتيم', toggle: 'مفتاح: إيقاف / تشغيل',
    chips: 'الشريحة وشريحة التصفية',
    chipsNote: 'الاختيار بالحبر وخرزة، وليس بتعبئة ذهبية. يحافظ النص على عرضه عند الاختيار.',
    badges: 'الشارة وشارة العدد',
    badgesNote: 'الشارات تسميات موضوعية. العدد الذهبي هو التعبئة الذهبية الوحيدة إلى جانب الزر الأساسي.',
    outlineB: 'إطار وخرزة', photoB: 'فوق الصورة', quietB: 'هادئة', counts: 'الأعداد', ring: 'حلقة فوق أيقونة تبويب', danger: 'خطر المهلة',
    pills: 'شارة الحالة',
    pillsNote: 'كل حالات الطلب في ADR 0033 وحالات الكوبون والزيارة والإعلان وحالات التوفر: أيقونة ونص، وليس اللون وحده.',
    client: 'صياغة العميل', hotel: 'صياغة الشريك', availability: 'التوفر', also: 'بجانب الحالة', vouchers: 'الكوبون', visits: 'زيارة القاعة', listings: 'الإعلان',
    avatars: 'الصورة الرمزية',
    avatarsNote: 'حرف أول على الوردي، وليس وجهاً. يستخدم تطبيق الفندق الحرف بالخط العادي؛ فالسيريف لأسماء القاعات والتحية.',
    serif: 'سيريف (العميل)', sans: 'عادي (الفندق)',
    ratings: 'التقييم',
    ratingsNote: 'النجمة والرقم والعدد عناصر منفصلة. يمتلئ الصف من بداية الاتجاه، لذلك ينعكس.',
    prices: 'السعر',
    pricesNote: 'فلوس صحيحة عبر المنسّق المشترك. التصفح يعرض الدنانير؛ والدقيق يعرض ثلاث خانات مع .000 هادئة. العملة على يسار الرقم باللغتين.',
    browse: 'تصفح', exact: 'دقيق', sizesP: 'الأحجام', unitsP: 'الوحدات والسعر القديم',
    threads: 'الفاصل وخط الخيط',
    threadsNote: 'الخيط الدقيق يحدّد مكاناً وليس زينة. يُرسم مرة واحدة من بداية الاتجاه؛ وتقليل الحركة يُبقي الخط مكتملاً.',
    hairline: 'دقيق', strong: 'قوي', khayt: 'خيط 24', full: 'كامل', knotV: 'مع عقدة', replay: 'أعد التشغيل', onInk: 'على الحبر',
    controls: 'المفتاح ومربع الاختيار والزر الدائري',
    controlsNote: 'الاختيار بالحبر 700 وليس بالذهبي. كل صف بارتفاع 44 على الأقل وقابل للضغط بعرضه كاملاً.',
    off: 'إيقاف', on: 'تشغيل', indeterminate: 'مختلط', error: 'خطأ',
    skeleton: 'هيكل التحميل',
    skeletonNote: 'شكل ثابت بالحبر 100. لا لمعان ولا تكرار؛ وكشف الصورة هو الحركة الوحيدة.',
    toasts: 'التنبيه وشريط التراجع',
    toastsNote: 'شريط حبري ونص بلون الخلفية وإجراء بالذهبي 400. يتناقص خط التراجع خلال ثماني ثوانٍ ويعمل أيضاً مع تقليل الحركة.',
    toast: 'تنبيه', undo: 'شريط التراجع', region: 'فوق شريط، بفارق 16',
    rows: 'صف القائمة',
    rowsNote: 'الحد الأدنى 64 وصف الطابور 80. السهم ينعكس؛ والأسماء تصطف بحرفها الأول.',
    plainR: 'عنوان وسطر فرعي', withTrail: 'بداية ونهاية وسهم', queue: 'صف الطابور 80', toggleRow: 'مع مفتاح', dangerRow: 'خطر',
    sectionHeaders: 'رأس القسم',
    sectionHeadersNote: 'خيط ثم عنوان فرعي اختياري ثم العنوان ثم عرض الكل. عناوين العميل بالسيريف وعناوين الفندق بخط الواجهة.',
    facts: 'الحقيقة السريعة والوسم', stack: 'متراص', inline: 'في سطر',
    brand: 'الهوية',
    brandNote: 'الشعار لا ينعكس أبداً. الخيط ذهبي 500 دائماً ولا يعلو الحروف.',
    lockup: 'الشعار الكامل', single: 'كتابة واحدة', monograms: 'الحرف المميّز', knots: 'عقد الخيط', beads: 'الخرز', booking: 'حجز 20', compactK: 'مضغوط 12', ended: 'منتهٍ',
    open: 'مفتوح', now: 'الآن', tied: 'معقود', pop: 'قفزة',
    guestsLbl: 'المدعوون', sessionLbl: 'الفترة', evening: 'مسائية', hallLbl: 'القاعة', vipLbl: 'صالة كبار الضيوف',
    nameSample: 'نورة الصباح', venueSample: 'فندق أوريليا الخليج',
    undoMsg: 'تم سحب الطلب', toastMsg: 'تم الحفظ في قائمتكم',
    fav: 'إضافة إلى المفضلة', unfav: 'إزالة من المفضلة', compare: 'إضافة إلى المقارنة',
    areaSample: 'السالمية',
  },
} as const

const PHOTO = '/images/halls/halls-02-ivory-draped-ballroom.jpg'

export default function CoreGallery() {
  const { lang, setLang } = useLang()
  const c = C[lang]
  const t = useT('common')
  const f = useFormat()

  return (
    <div className="cg" data-gz="CoreGallery">
      <header className="cg-head">
        <Wordmark size="md" draw />
        <p className="gz-t-label">{c.eyebrow}</p>
        <h1 className="gz-t-d4">{c.title}</h1>
        <p className="cg-lede gz-t-body">{c.lede}</p>
        <div className="cg-lang">
          <Button variant="secondary" size="sm" iconStart="translate" onClick={() => setLang(lang === 'ar' ? 'en' : 'ar')}>
            {c.switchTo}
          </Button>
        </div>
      </header>

      <IconSection c={c} />
      <ButtonSection c={c} t={t} />
      <IconButtonSection c={c} />
      <ChipSection c={c} t={t} />
      <BadgeSection c={c} t={t} />
      <PillSection c={c} />
      <AvatarSection c={c} />
      <RatingSection c={c} />
      <PriceSection c={c} />
      <ThreadSection c={c} />
      <ControlSection c={c} t={t} />
      <SkeletonSection c={c} />
      <ToastSection c={c} t={t} />
      <RowSection c={c} t={t} f={f} />
      <HeaderSection c={c} t={t} f={f} />
      <FactSection c={c} t={t} f={f} />
      <BrandSection c={c} />
    </div>
  )
}

type Copy = { [K in keyof typeof C.en]: string }
type T = ReturnType<typeof useT<'common'>>
type F = ReturnType<typeof useFormat>

// ---------------------------------------------------------------------------------------------------------------- icons
const SPECIMEN_ICONS: IconName[] = ['search', 'heart', 'calendar', 'guests', 'pin', 'wallet', 'bell', 'compare']

function IconSection({ c }: { c: Copy }) {
  return (
    <Section title={c.icons} note={c.iconsNote}>
      <Group label={c.sizes}>
        <div className="cg-sizes">
          {(['xs', 'sm', 'md', 'lg'] as const).map(size => (
            <Cell key={size} cap={size}>
              <Icon name="calendar-check" size={size} />
            </Cell>
          ))}
        </div>
      </Group>
      <Group label={c.weights}>
        <Row center>
          {(['light', 'regular'] as const).map(w => (
            <Stage key={w}>
              <Row center>
                {SPECIMEN_ICONS.map(n => <Icon key={n} name={n} weight={w} />)}
              </Row>
              <span className="cg-cap gz-t-caption">{w}</span>
            </Stage>
          ))}
        </Row>
      </Group>
      <Group label={c.tones}>
        <Row center>
          {(['primary', 'secondary', 'accent', 'success', 'danger', 'disabled'] as const).map(tone => (
            <Cell key={tone} cap={tone}>
              <Icon name="check-circle" tone={tone} />
            </Cell>
          ))}
        </Row>
      </Group>
      <Group label={c.mirrors}>
        <div className="cg-icons">
          {mirroredIconNames.map(n => (
            <span key={n} className="cg-icon cg-icon--mirror" title={n}><Icon name={n} /></span>
          ))}
        </div>
      </Group>
      <Group label={c.registry}>
        <div className="cg-icons">
          {iconNames.map(n => (
            <span key={n} className={`cg-icon${isMirrored(n) ? ' cg-icon--mirror' : ''}`} title={n}><Icon name={n} /></span>
          ))}
        </div>
      </Group>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- button
function ButtonSection({ c, t }: { c: Copy; t: T }) {
  const [busy, setBusy] = useState(false)
  const go = () => {
    setBusy(true)
    window.setTimeout(() => setBusy(false), 2400)
  }
  const accept = t('commonActionAccept')
  const variants = [
    { v: 'primary', cap: c.primary, label: accept },
    { v: 'secondary', cap: c.secondary, label: t('commonActionReschedule') },
    { v: 'tertiary', cap: c.tertiary, label: t('commonActionSeeAll') },
    { v: 'destructive', cap: c.destructive, label: t('commonActionDecline') },
  ] as const
  return (
    <Section title={c.buttons} note={c.buttonsNote}>
      <Group label={c.variants}>
        <Row center>
          {variants.map(x => (
            <Cell key={x.v} cap={x.cap}>
              <Button variant={x.v} iconStart={x.v === 'destructive' ? 'close' : undefined}>{x.label}</Button>
            </Cell>
          ))}
        </Row>
      </Group>
      {variants.map(x => (
        <Group key={x.v} label={`${x.cap} · ${c.states}`}>
          <Row center>
            <Cell cap={c.def}><Button variant={x.v}>{x.label}</Button></Cell>
            <Cell cap={c.pressed}><Button variant={x.v} previewState="pressed">{x.label}</Button></Cell>
            <Cell cap={c.focus}><Button variant={x.v} previewState="focus">{x.label}</Button></Cell>
            <Cell cap={c.disabled}><Button variant={x.v} disabled>{x.label}</Button></Cell>
            <Cell cap={c.loading}><Button variant={x.v} loading>{x.label}</Button></Cell>
          </Row>
        </Group>
      ))}
      <Group label={c.disabled}>
        <Button variant="primary" fullWidth disabled reason={c.reason}>{t('commonActionContinue')}</Button>
      </Group>
      <Group label={c.withIcons}>
        <Row center>
          <Cell cap={c.iconStart}><Button variant="secondary" iconStart="calendar">{t('commonCalendarAvailability')}</Button></Cell>
          <Cell cap={c.iconEnd}><Button variant="primary" iconEnd="arrow-right">{t('commonActionNext')}</Button></Cell>
          <Cell cap={c.iconEnd}><Button variant="tertiary" iconEnd="chevron-right">{t('commonActionSeeAll')}</Button></Cell>
        </Row>
      </Group>
      <Group label={c.heights}>
        <Row center>
          {(['sm', 'md', 'cta', 'lg'] as const).map(s => (
            <Cell key={s} cap={s}><Button variant="secondary" size={s}>{t('commonActionSave')}</Button></Cell>
          ))}
        </Row>
      </Group>
      <Group label={c.pair}>
        <div className="cg-pair">
          <Button variant="secondary">{t('commonActionReschedule')}</Button>
          <Button variant="secondary">{t('commonActionDecline')}</Button>
        </div>
        <Button variant="primary" fullWidth>{accept}</Button>
      </Group>
      <Group label={c.loading}>
        <Button variant="primary" fullWidth loading={busy} onClick={go}>{t('commonActionConfirm')}</Button>
      </Group>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- icon button
function IconButtonSection({ c }: { c: Copy }) {
  const t = useT('common')
  const [fav, setFav] = useState(false)
  const [cmp, setCmp] = useState(true)
  return (
    <Section title={c.iconButtons} note={c.iconButtonsNote}>
      <Group label={c.variants}>
        <Row center>
          <Cell cap={c.plain}><IconButton icon="share" label={t('commonActionShare')} /></Cell>
          <Cell cap={c.outline}><IconButton icon="back" label={t('commonActionBack')} variant="outline" /></Cell>
          <Cell cap={c.pressed}><IconButton icon="share" label={t('commonActionShare')} previewState="pressed" /></Cell>
          <Cell cap={c.focus}><IconButton icon="share" label={t('commonActionShare')} previewState="focus" /></Cell>
        </Row>
      </Group>
      <Group label={`${c.overImage} / ${c.overImageLg} / ${c.onScrim}`}>
        <div className="cg-photo">
          <img className="cg-photo__img" src={PHOTO} alt="" />
          <div className="cg-photo__scrim" />
          <IconButton icon="compare" label={cmp ? t('commonA11yCompareRemove') : t('commonA11yCompareAdd')} variant="over-image" active={cmp} onClick={() => setCmp(v => !v)} />
          <span className="cg-photo__end">
            <IconButton icon="share" label={t('commonActionShare')} variant="on-scrim" />
            <IconButton icon="heart" iconActive="heart-fill" label={fav ? t('commonA11yFavouriteRemove') : t('commonA11yFavouriteAdd')} variant="over-image" disk="lg" active={fav} onClick={() => setFav(v => !v)} />
          </span>
        </div>
      </Group>
      <Group label={`${c.toggle} · ${c.pressed} · ${c.focus}`}>
        <div className="cg-photo">
          <img className="cg-photo__img" src={PHOTO} alt="" />
          <div className="cg-photo__scrim" />
          <IconButton icon="heart" iconActive="heart-fill" label={t('commonA11yFavouriteAdd')} variant="over-image" active={false} />
          <span className="cg-photo__end">
            <IconButton icon="heart" iconActive="heart-fill" label={t('commonA11yFavouriteRemove')} variant="over-image" active previewState="pressed" />
            <IconButton icon="heart" iconActive="heart-fill" label={t('commonA11yFavouriteRemove')} variant="over-image" active previewState="focus" />
          </span>
        </div>
      </Group>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- chips
function ChipSection({ c, t }: { c: Copy; t: T }) {
  const [tier, setTier] = useState<string>('weekend')
  const [filters, setFilters] = useState(2)
  const tiers = [
    ['weekday', t('commonTierWeekday')],
    ['weekend', t('commonTierWeekend')],
    ['holiday', t('commonTierHoliday')],
  ] as const
  return (
    <Section title={c.chips} note={c.chipsNote}>
      <Group label={c.states}>
        <Row center>
          <Cell cap={c.def}><Chip onClick={() => undefined}>{t('commonTierWeekday')}</Chip></Cell>
          <Cell cap={c.selected}><Chip selected>{t('commonTierWeekend')}</Chip></Cell>
          <Cell cap={c.pressed}><Chip onClick={() => undefined} previewState="pressed">{t('commonTierHoliday')}</Chip></Cell>
          <Cell cap={c.focus}><Chip onClick={() => undefined} previewState="focus">{t('commonTierSeason')}</Chip></Cell>
          <Cell cap={c.disabled}><Chip disabled onClick={() => undefined}>{t('commonTierSpecialDate')}</Chip></Cell>
        </Row>
      </Group>
      <Group label={c.variants}>
        <Row center>
          {tiers.map(([k, label]) => (
            <FilterChip key={k} selected={tier === k} onToggle={() => setTier(k)}>{label}</FilterChip>
          ))}
        </Row>
        <Row center>
          <FilterChip selected={false} menu onToggle={() => undefined}>{t('commonCalendarAvailability')}</FilterChip>
          <FilterChip selected menu count={filters} onToggle={() => setFilters(n => (n + 1) % 5)}>{t('commonLabelSettings')}</FilterChip>
          <Chip iconStart="pin">{c.areaSample}</Chip>
        </Row>
      </Group>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- badges
function BadgeSection({ c, t }: { c: Copy; t: T }) {
  return (
    <Section title={c.badges} note={c.badgesNote}>
      <Group label={c.variants}>
        <Row center>
          <Cell cap={c.outlineB}><Badge>{t('commonLabelNew')}</Badge></Cell>
          <Cell cap={c.quietB}><Badge variant="quiet">{t('commonLabelSponsored')}</Badge></Cell>
        </Row>
      </Group>
      <Group label={c.photoB}>
        <div className="cg-photo">
          <img className="cg-photo__img" src={PHOTO} alt="" />
          <div className="cg-photo__scrim" />
          <Badge variant="photo">{t('commonLabelNew')}</Badge>
        </div>
      </Group>
      <Group label={c.counts}>
        <Row center>
          <Cell cap="1"><CountBadge count={1} /></Cell>
          <Cell cap="12"><CountBadge count={12} /></Cell>
          <Cell cap="99+"><CountBadge count={140} /></Cell>
          <Cell cap={c.danger}><CountBadge count={3} tone="danger" /></Cell>
          <Cell cap={c.ring}>
            <span className="cg-tab"><Icon name="chat" /><CountBadge count={2} ring /></span>
          </Cell>
        </Row>
      </Group>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- status pills
const BOOKING: BookingStatus[] = ['pending', 'approved', 'confirmed', 'redeemed', 'completed', 'declined', 'expired', 'cancelled']
const PARTNER: BookingStatus[] = ['pending', 'approved', 'redeemed', 'declined', 'expired']
const AVAIL: AvailabilityState[] = ['available', 'held', 'booked', 'blocked', 'unavailable', 'past']
const BESIDE: BookingStatus[] = ['date_proposed', 'missed', 'lapsed', 'urgent']
const VOUCHER: VoucherState[] = ['voucher_unpaid', 'voucher_active', 'voucher_bound', 'voucher_used', 'voucher_expired', 'voucher_refunded']
const VISIT: VisitState[] = ['visit_requested', 'visit_confirmed', 'visit_reschedule', 'visit_arrived', 'visit_completed', 'visit_declined', 'visit_cancelled', 'visit_missed']
const LISTING: ListingState[] = ['listing_draft', 'listing_payment', 'listing_review', 'listing_approved', 'listing_rejected', 'listing_active', 'listing_expired', 'listing_paused']

function PillSection({ c }: { c: Copy }) {
  return (
    <Section title={c.pills} note={c.pillsNote}>
      <Group label={c.client}>
        <Row>{BOOKING.map(s => <Cell key={s} cap={s}><StatusPill status={s} /></Cell>)}</Row>
      </Group>
      <Group label={c.hotel}>
        <Row>{PARTNER.map(s => <Cell key={s} cap={s}><StatusPill status={s} audience="hotel" /></Cell>)}</Row>
      </Group>
      <Group label={c.also}>
        <Row>{BESIDE.map(s => <Cell key={s} cap={s}><StatusPill status={s} audience="hotel" /></Cell>)}</Row>
      </Group>
      <Group label={c.vouchers}>
        <Row>{VOUCHER.map(s => <Cell key={s} cap={s}><StatusPill status={s} /></Cell>)}</Row>
      </Group>
      <Group label={c.visits}>
        <Row>{VISIT.map(s => <Cell key={s} cap={s}><StatusPill status={s} /></Cell>)}</Row>
      </Group>
      <Group label={c.listings}>
        <Row>{LISTING.map(s => <Cell key={s} cap={s}><StatusPill status={s} audience="hotel" /></Cell>)}</Row>
      </Group>
      <Group label={c.availability}>
        <Row>{AVAIL.map(s => <Cell key={s} cap={s}><StatusPill status={s} /></Cell>)}</Row>
      </Group>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- avatar
function AvatarSection({ c }: { c: Copy }) {
  return (
    <Section title={c.avatars} note={c.avatarsNote}>
      <Group label={c.serif}>
        <Row center>
          {(['xs', 'sm', 'md', 'lg'] as const).map(s => (
            <Cell key={s} cap={s}><Avatar name={c.nameSample} size={s} /></Cell>
          ))}
          <Cell cap="غ"><Avatar name="غادة" size="md" /></Cell>
        </Row>
      </Group>
      <Group label={c.sans}>
        <Row center>
          {(['xs', 'sm', 'md', 'lg'] as const).map(s => (
            <Cell key={s} cap={s}><Avatar name={c.venueSample} size={s} voice="sans" /></Cell>
          ))}
        </Row>
      </Group>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- rating
function RatingSection({ c }: { c: Copy }) {
  return (
    <Section title={c.ratings} note={c.ratingsNote}>
      <Row center>
        <Cell cap="compact"><Rating value={4.8} /></Cell>
        <Cell cap="+ count"><Rating value={4.8} count={212} /></Cell>
        <Cell cap="stars"><Rating variant="stars" value={4.3} count={86} /></Cell>
        <Cell cap="stars"><Rating variant="stars" value={3.5} /></Cell>
      </Row>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- price
function PriceSection({ c }: { c: Copy }) {
  const t = useT('common')
  return (
    <Section title={c.prices} note={c.pricesNote}>
      <Group label={`${c.browse} · ${c.exact}`}>
        <Stage>
          <Row center>
            <Cell cap={c.browse}><Price fils={18_200_000} /></Cell>
            <Cell cap={`${c.browse} · fils`}><Price fils={18_500} /></Cell>
            <Cell cap={c.exact}><Price fils={5_460_000} mode="exact" /></Cell>
            <Cell cap={c.exact}><Price fils={5_460_500} mode="exact" /></Cell>
          </Row>
        </Stage>
      </Group>
      <Group label={c.sizesP}>
        <Stage>
          <Cell cap="card 17 / 500"><Price fils={18_200_000} size="card" /></Cell>
          <Cell cap="strong 17 / 600"><Price fils={18_200_000} size="strong" /></Cell>
          <Cell cap="total 22 / 600 · exact"><Price fils={5_460_000} size="total" mode="exact" /></Cell>
          <Cell cap="kpi 32 / 600"><Price fils={18_200_000} size="kpi" /></Cell>
          <Cell cap="display d1"><Price fils={46_000} size="display" /></Cell>
          <Cell cap="hero d3"><Price fils={16_100_000} size="hero" /></Cell>
        </Stage>
      </Group>
      <Group label={c.unitsP}>
        <Stage>
          <Cell cap={t('commonUnitPerGuest')}><Price fils={46_000} unit="perGuest" /></Cell>
          <Cell cap={t('commonUnitPerNight')}><Price fils={2_800_000} unit="perNight" size="strong" /></Cell>
          <Cell cap="was"><Price fils={42_000} was={46_000} unit="perGuest" /></Cell>
        </Stage>
      </Group>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- dividers and thread rules
function ThreadSection({ c }: { c: Copy }) {
  const [run, setRun] = useState(0)
  return (
    <Section title={c.threads} note={c.threadsNote}>
      <Group label={`${c.hairline} / ${c.strong}`}>
        <Stage>
          <Divider />
          <Divider tone="strong" />
        </Stage>
      </Group>
      <Group label={`${c.khayt} / ${c.full} / ${c.knotV}`}>
        <Stage>
          <ThreadRule key={`a${run}`} variant="khayt" draw="mount" />
          <ThreadRule key={`b${run}`} variant="full" draw="mount" />
          <ThreadRule key={`c${run}`} variant="knot" draw="mount" />
        </Stage>
        <Row>
          <Button variant="tertiary" iconStart="refresh" onClick={() => setRun(n => n + 1)}>{c.replay}</Button>
        </Row>
      </Group>
      <Group label={c.onInk}>
        <Stage kind="ink">
          <Divider tone="on-dark" />
          <ThreadRule key={`d${run}`} variant="knot" draw="mount" />
        </Stage>
      </Group>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- switch, checkbox, radio
function ControlSection({ c, t }: { c: Copy; t: T }) {
  const [plan, setPlan] = useState('deposit')
  return (
    <Section title={c.controls} note={c.controlsNote}>
      <Group label={`Switch · ${c.off} / ${c.on} / ${c.pressed} / ${c.focus} / ${c.disabled}`}>
        <Row center>
          <Cell cap={c.off}><Switch label={t('commonA11yFavouriteAdd')} defaultChecked={false} /></Cell>
          <Cell cap={c.on}><Switch label={t('commonA11yFavouriteAdd')} defaultChecked /></Cell>
          <Cell cap={c.pressed}><Switch label={t('commonA11yFavouriteAdd')} previewState="pressed" /></Cell>
          <Cell cap={c.focus}><Switch label={t('commonA11yFavouriteAdd')} defaultChecked previewState="focus" /></Cell>
          <Cell cap={c.disabled}><Switch label={t('commonA11yFavouriteAdd')} disabled /></Cell>
          <Cell cap={`${c.disabled} · ${c.on}`}><Switch label={t('commonA11yFavouriteAdd')} disabled defaultChecked /></Cell>
        </Row>
      </Group>
      <Group label="Checkbox">
        <Stage>
          <Checkbox>{t('commonAvailabilityFree')}</Checkbox>
          <Checkbox defaultChecked>{t('commonAvailabilityHeld')}</Checkbox>
          <Checkbox indeterminate>{c.indeterminate}</Checkbox>
          <Checkbox previewState="pressed">{c.pressed}</Checkbox>
          <Checkbox defaultChecked previewState="focus">{c.focus}</Checkbox>
          <Checkbox disabled>{t('commonAvailabilityUnavailable')}</Checkbox>
          <Checkbox disabled defaultChecked>{t('commonAvailabilityBooked')}</Checkbox>
          <Checkbox error={t('commonFieldRequired')}>{t('commonLabelRequired')}</Checkbox>
        </Stage>
      </Group>
      <Group label="Radio">
        <Stage>
          <RadioGroup label={t('commonMoneyDeposit')} value={plan} onChange={setPlan}>
            <Radio value="deposit">{t('commonMoneyDeposit')}</Radio>
            <Radio value="balance">{t('commonMoneyBalance')}</Radio>
            <Radio value="total">{t('commonMoneyTotal')}</Radio>
            <Radio value="never" disabled>{t('commonAvailabilityUnavailable')}</Radio>
          </RadioGroup>
          <Radio value="x" checked previewState="focus">{c.focus}</Radio>
          <Radio value="y" previewState="pressed">{c.pressed}</Radio>
        </Stage>
      </Group>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- skeleton
function SkeletonSection({ c }: { c: Copy }) {
  return (
    <Section title={c.skeleton} note={c.skeletonNote}>
      <Stage>
        <div className="cg-card" aria-busy="true">
          <Skeleton variant="block" blockSize={160} />
          <div className="cg-card__top">
            <Skeleton variant="circle" inlineSize={40} />
            <Skeleton variant="line" blockSize={20} grow />
          </div>
          <SkeletonText lines={3} lastLine={160} />
        </div>
      </Stage>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- toast and undo
function ToastSection({ c, t }: { c: Copy; t: T }) {
  const [run, setRun] = useState(0)
  return (
    <Section title={c.toasts} note={c.toastsNote}>
      <Group label={c.toast}>
        <Toast message={c.toastMsg} icon="check-circle" actionLabel={t('commonActionUndo')} />
        <Toast message={t('commonStateOffline')} icon="offline" />
        <Toast message={c.toastMsg} actionLabel={t('commonActionUndo')} previewState="pressed" />
      </Group>
      <Group label={c.undo}>
        <UndoBar key={run} message={c.undoMsg} runKey={run} />
        <UndoBar message={c.undoMsg} previewState="focus" />
        <Row>
          <Button variant="tertiary" iconStart="refresh" onClick={() => setRun(n => n + 1)}>{c.replay}</Button>
        </Row>
      </Group>
      <Group label={c.region}>
        <div className="cg-bar">
          <ToastRegion barHeight={0}>
            <UndoBar message={c.undoMsg} runKey={`r${run}`} />
          </ToastRegion>
        </div>
      </Group>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- list row
function RowSection({ c, t, f }: { c: Copy; t: T; f: F }) {
  const [push, setPush] = useState(true)
  const sub = `${c.areaSample} · ${t('commonCountGuests', { count: 350 })}`
  return (
    <Section title={c.rows} note={c.rowsNote}>
      <Stage>
        <Group label={c.plainR}>
          <ListRow flush title={t('commonLabelLanguage')} subtitle={t('commonLabelKuwaitTime')} />
        </Group>
        <Group label={c.withTrail}>
          <ListRow flush chevron onClick={() => undefined} leading={<Icon name="globe" tone="secondary" />} title={t('commonLabelLanguage')} trailing={t('commonLanguageEnglish')} />
          <ListRow flush chevron onClick={() => undefined} leading={<Icon name="wallet" tone="secondary" />} title={t('commonMoneyDeposit')} subtitle={t('commonStatusAwaitingDeposit')} trailing={<Price fils={5_460_000} mode="exact" size="strong" />} />
        </Group>
        <Group label={c.queue}>
          <ListRow flush size="queue" chevron onClick={() => undefined} autoDir leading={<Avatar name={c.nameSample} size="sm" voice="sans" />} title={c.nameSample} subtitle={sub} trailing={<Price fils={16_100_000} size="strong" />} />
        </Group>
        <Group label={`${c.pressed} / ${c.selected} / ${c.focus}`}>
          <ListRow flush chevron onClick={() => undefined} previewState="pressed" title={t('commonActionEdit')} />
          <ListRow flush chevron onClick={() => undefined} selected title={t('commonActionShare')} />
          <ListRow flush chevron onClick={() => undefined} previewState="focus" title={t('commonActionMessage')} />
        </Group>
        <Group label={c.toggleRow}>
          <ListRow flush title={t('commonCalendarPeak')} subtitle={f.number(3)} trailing={<Switch label={t('commonCalendarPeak')} checked={push} onChange={setPush} />} />
        </Group>
        <Group label={c.dangerRow}>
          <ListRow flush last tone="danger" onClick={() => undefined} leading={<Icon name="trash" tone="danger" />} title={t('commonActionRemove')} />
        </Group>
      </Stage>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- section header
function HeaderSection({ c, t, f }: { c: Copy; t: T; f: F }) {
  const [run, setRun] = useState(0)
  return (
    <Section title={c.sectionHeaders} note={c.sectionHeadersNote}>
      <Group label={c.variants}>
        <SectionHeader key={`a${run}`} title={t('commonCountHalls', { count: 38 })} draw="mount" onSeeAll={() => undefined} />
        <SectionHeader key={`b${run}`} title={c.venueSample} eyebrow={c.areaSample} draw="mount" />
        <SectionHeader key={`c${run}`} voice="hotel" title={t('commonCountRequests', { count: 3 })} draw="mount" onSeeAll={() => undefined} seeAllLabel={`${t('commonActionSeeAll')} ${f.integer(3)}`} />
      </Group>
      <Row>
        <Button variant="tertiary" iconStart="refresh" onClick={() => setRun(n => n + 1)}>{c.replay}</Button>
      </Row>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- key fact and tag
function FactSection({ c, t, f }: { c: Copy; t: T; f: F }) {
  return (
    <Section title={c.facts}>
      <Group label={c.stack}>
        <Stage>
          <Row>
            <KeyFact icon="guests" label={c.guestsLbl} value={f.integer(350)} />
            <KeyFact icon="clock" label={c.sessionLbl} value={c.evening} />
            <KeyFact icon="hall" label={c.hallLbl} value={c.venueSample} />
          </Row>
        </Stage>
      </Group>
      <Group label={c.inline}>
        <Stage>
          <KeyFact layout="inline" icon="wallet" label={t('commonMoneyDeposit')} value={<Price fils={5_460_000} mode="exact" size="strong" />} />
        </Stage>
      </Group>
      <Group label="Tag">
        <Row>
          <Tag icon="valet">{t('commonLabelOptional')}</Tag>
          <Tag icon="sound">{c.vipLbl}</Tag>
          <Tag icon="staff">{t('commonLabelNew')}</Tag>
          <Tag>{c.areaSample}</Tag>
        </Row>
      </Group>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- brand
function BrandSection({ c }: { c: Copy }) {
  const [run, setRun] = useState(0)
  return (
    <Section title={c.brand} note={c.brandNote}>
      <Group label={c.lockup}>
        <div className="cg-lock">
          {(['sm', 'md', 'lg', 'xl'] as const).map(s => (
            <Cell key={`${s}${run}`} cap={s}><Wordmark size={s} draw={run > 0} /></Cell>
          ))}
        </div>
        <Row>
          <Button variant="tertiary" iconStart="refresh" onClick={() => setRun(n => n + 1)}>{c.replay}</Button>
        </Row>
      </Group>
      <Group label={c.single}>
        <Row center>
          <Cell cap="latin"><Wordmark size="lg" script="latin" /></Cell>
          <Cell cap="arabic"><Wordmark size="lg" script="arabic" /></Cell>
        </Row>
      </Group>
      <Group label={c.onInk}>
        <Stage kind="ink">
          <Wordmark size="lg" onDark />
        </Stage>
      </Group>
      <Group label={c.monograms}>
        <Row center>
          {(['sm', 'md', 'lg'] as const).map(s => (
            <Cell key={s} cap={s}><Monogram size={s} /></Cell>
          ))}
          <Cell cap="tile"><Monogram size="lg" form="tile" /></Cell>
          <Cell cap="arabic"><Monogram size="lg" form="tile" script="arabic" /></Cell>
          <Cell cap="latin"><Monogram size="lg" form="tile" script="latin" /></Cell>
        </Row>
      </Group>
      <Group label={`${c.knots} · ${c.booking}`}>
        <Stage>
          <div className="cg-knots">
            <Cell cap={c.open}><ThreadKnot state="open" /></Cell>
            <Cell cap={c.now}><ThreadKnot state="now" /></Cell>
            <Cell cap={c.tied}><ThreadKnot state="tied" /></Cell>
            <Cell cap="x"><ThreadKnot state="ended" endedIcon="close" endedTone="danger" /></Cell>
            <Cell cap="clock"><ThreadKnot state="ended" endedIcon="clock" endedTone="neutral" /></Cell>
            <Cell cap="undo"><ThreadKnot state="ended" endedIcon="undo" endedTone="rose" /></Cell>
            <Cell cap="user"><ThreadKnot state="ended" endedIcon="user-minus" endedTone="danger-outline" /></Cell>
          </div>
        </Stage>
      </Group>
      <Group label={`${c.knots} · ${c.compactK}`}>
        <Stage>
          <div className="cg-knots">
            <Cell cap={c.open}><ThreadKnot size="compact" state="open" /></Cell>
            <Cell cap={c.now}><ThreadKnot size="compact" state="now" /></Cell>
            <Cell cap={c.tied}><ThreadKnot size="compact" state="tied" /></Cell>
            <Cell cap={c.pop}><ThreadKnot size="booking" state="tied" pop key={run} /></Cell>
          </div>
        </Stage>
      </Group>
      <Group label={`${c.knots} · ${c.onInk}`}>
        <Stage kind="ink">
          <div className="cg-knots">
            <Cell cap={c.open}><ThreadKnot onDark state="open" /></Cell>
            <Cell cap={c.now}><ThreadKnot onDark state="now" /></Cell>
            <Cell cap={c.tied}><ThreadKnot onDark state="tied" /></Cell>
            <Cell cap="x"><ThreadKnot onDark state="ended" endedTone="danger" /></Cell>
          </div>
        </Stage>
      </Group>
      <Group label={c.beads}>
        <Row center>
          <Cell cap="gold"><ThreadBead /></Cell>
          <Cell cap="ink"><ThreadBead tone="ink" /></Cell>
          <Cell cap="hollow"><ThreadBead tone="hollow" /></Cell>
        </Row>
      </Group>
    </Section>
  )
}
