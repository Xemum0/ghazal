// PackageEditorRow: one package in "Packages" with its edit controls in place (HL-VENU-02 / 03, HA-VMGT-03, HA-VMGT-04). Closed it
// is a 64+ row: the name, "voucher KD 44 per guest . 200 to 650 guests", the active switch and the disclosure. Open it carries the things
// the phone edits: the TWO prices of the package on the same basis (standard and voucher, ADR 0033 D4: numeric fields in KD, up to three
// decimals, Eastern digits normalised, stored as integer fils; the voucher price must be lower and the client's saving must beat the
// KD 2 voucher fee, the row says so in words),
// the minimum and maximum guests (steppers that move by the package's guest step, the maximum never below the minimum), and the inclusions
// (removable chips plus an Add chip). Seasonal, holiday and special-date prices stay on the dashboard and the row says so. Draft state lives
// here; the screen gets every change through `onChange` and owns Save.
import { useMemo, useState } from 'react'
import type { Bilingual, Package } from '@gz/contracts'
import { useFormat, useT } from '../../../i18n'
import { Icon, Price, Switch } from '../../core'
import { Stepper, TextField } from '../../inputs'
import { cx } from '../../core/cx'
import { Figures, parseKdToFils, useBi } from '../internal/bits'
import { defineWords, p } from '../internal/copy'
import './venue-tools.css'

const useW = defineWords({
  from: p('From', 'من'),
  guests: p('{from} to {to} guests', 'من {from} إلى {to} ضيف'),
  price: p('Standard price per guest', 'السعر العادي للضيف'),
  priceFlat: p('Standard price', 'السعر العادي'),
  voucherPrice: p('Voucher price per guest', 'سعر الكوبون للضيف'),
  voucherPriceFlat: p('Voucher price', 'سعر الكوبون'),
  priceHelper: p('In KD, up to three decimals. What a client pays you without a voucher.', 'بالدينار الكويتي حتى ثلاث خانات عشرية. ما يدفعه العميل لكم دون كوبون.'),
  voucherHelper: p('Lower than the standard price. What a client pays you with a Ghazal voucher.', 'أقل من السعر العادي. ما يدفعه العميل لكم بكوبون غزل.'),
  priceError: p('Enter an amount such as 52 or 52.500.', 'أدخلوا مبلغًا مثل 52 أو 52.500.'),
  voucherError: p('The voucher price must be lower than the standard price.', 'يجب أن يكون سعر الكوبون أقل من السعر العادي.'),
  voucherSmall: p('Clients save {amount}, which is not more than the voucher fee, so no voucher is offered.', 'يوفّر العميل {amount} وهو لا يزيد على ثمن الكوبون، لذلك لا يُعرض الكوبون.'),
  saving: p('Clients save {amount}{unit} with the voucher', 'يوفّر العميل {amount}{unit} بالكوبون'),
  structure: p('Pricing: {structure}', 'التسعير: {structure}'),
  perPerson: p('per person', 'للضيف'),
  package: p('package', 'باقة'),
  min: p('Minimum guests', 'الحد الأدنى للضيوف'),
  max: p('Maximum guests', 'الحد الأقصى للضيوف'),
  rule: p('Moves by {step}', 'يتغير بمقدار {step}'),
  inclusions: p('Inclusions', 'ما تشمله الباقة'),
  remove: p('Remove {name}', 'إزالة {name}'),
  add: p('Add inclusion', 'إضافة'),
  active: p('Active', 'مفعّلة'),
  activeOf: p('{name} is active', 'الباقة {name} مفعّلة'),
  dashboard: p('Seasonal, holiday and special-date prices are edited on the dashboard.', 'تُعدَّل أسعار المواسم والعطل والتواريخ الخاصة من لوحة التحكم.'),
  edit: p('Edit {name}', 'تعديل {name}'),
  kd: p('KD', 'د.ك'),
})

export type PackageDraft = { priceFils: number | null; voucherFils: number | null; minGuests: number; maxGuests: number; inclusions: Bilingual[]; active: boolean }

export type PackageEditorRowProps = {
  pkg: Package
  /** Weekend standard price in fils on the package's basis (from the package's price rules). */
  priceFils: number
  /** Weekend voucher price in fils on the same basis; null = the package has no voucher price. */
  voucherFils?: number | null
  defaultExpanded?: boolean
  onChange?: (draft: PackageDraft) => void
  onAddInclusion?: () => void
  last?: boolean
  className?: string
}

export function PackageEditorRow({ pkg, priceFils, voucherFils = null, defaultExpanded = false, onChange, onAddInclusion, last = false, className }: PackageEditorRowProps) {
  const f = useFormat()
  const t = useT('common')
  const w = useW()
  const bi = useBi()
  const [open, setOpen] = useState(defaultExpanded)
  const [text, setText] = useState(() => (priceFils % 1000 === 0 ? String(priceFils / 1000) : (priceFils / 1000).toFixed(3)))
  const [vtext, setVtext] = useState(() => (voucherFils === null ? '' : voucherFils % 1000 === 0 ? String(voucherFils / 1000) : (voucherFils / 1000).toFixed(3)))
  const [min, setMin] = useState(pkg.minGuests)
  const [max, setMax] = useState(pkg.maxGuests)
  const [inc, setInc] = useState<Bilingual[]>(pkg.inclusions)
  const [active, setActive] = useState(pkg.active)
  const parsed = useMemo(() => parseKdToFils(f, text), [f, text])
  const vparsed = useMemo(() => (vtext.trim() === '' ? null : parseKdToFils(f, vtext)), [f, vtext])
  const draft = (patch: Partial<PackageDraft>): PackageDraft => ({ priceFils: parsed, voucherFils: vparsed, minGuests: min, maxGuests: max, inclusions: inc, active, ...patch })
  const name = bi(pkg.name)
  const shownPrice = parsed ?? priceFils
  const flatBasis = pkg.priceUnit === 'flat'
  const shownVoucher = vparsed ?? voucherFils
  const saving = parsed !== null && vparsed !== null ? parsed - vparsed : null
  const voucherInvalid = vtext.trim() !== '' && (vparsed === null || (parsed !== null && vparsed >= parsed))
  const feeFils = 2000

  return (
    <section data-gz="PackageEditorRow" data-open={open || undefined} className={cx('gz-per', open && 'is-open', last && 'is-last', className)}>
      <div className="gz-per__head">
        <button type="button" className="gz-reset gz-per__summary gz-press" aria-expanded={open} aria-label={w('edit', { name })} onClick={() => setOpen(!open)}>
          <span className="gz-per__text">
            <span className="gz-t-title gz-per__name">
              <bdi dir="auto">{name}</bdi>
            </span>
            <span className="gz-per__meta gz-t-caption">
              <span className="gz-per__price">
                {shownVoucher ? <Price fils={shownVoucher} mode="browse" size="card" unit={flatBasis ? 'perNight' : 'perGuest'} /> : <Price fils={shownPrice} mode="browse" size="card" unit={flatBasis ? 'perNight' : 'perGuest'} />}
              </span>
              <span>
                <Figures text={w('guests', { from: f.integer(min), to: f.integer(max) })} />
              </span>
            </span>
          </span>
          <Icon name={open ? 'chevron-up' : 'chevron-down'} size="sm" tone="secondary" />
        </button>
        <Switch
          checked={active}
          onChange={v => {
            setActive(v)
            onChange?.(draft({ active: v }))
          }}
          label={w('activeOf', { name })}
        />
      </div>

      {open ? (
        <div className="gz-per__body">
          <p className="gz-per__structure gz-t-caption">{w('structure', { structure: pkg.priceStructure === 'package' ? w('package') : w('perPerson') })}</p>
          <TextField
            label={flatBasis ? w('priceFlat') : w('price')}
            helper={w('priceHelper')}
            error={parsed === null ? w('priceError') : undefined}
            inputMode="decimal"
            dir="ltr"
            value={text}
            onValueChange={v => {
              setText(v)
              onChange?.(draft({ priceFils: parseKdToFils(f, v) }))
            }}
            startAdornment={<span className="gz-t-label gz-per__cur">{w('kd')}</span>}
          />
          <TextField
            label={flatBasis ? w('voucherPriceFlat') : w('voucherPrice')}
            helper={saving !== null && saving > 0 ? undefined : w('voucherHelper')}
            error={voucherInvalid ? (vparsed === null ? w('priceError') : w('voucherError')) : undefined}
            inputMode="decimal"
            dir="ltr"
            value={vtext}
            onValueChange={v => {
              setVtext(v)
              onChange?.(draft({ voucherFils: v.trim() === '' ? null : parseKdToFils(f, v) }))
            }}
            startAdornment={<span className="gz-t-label gz-per__cur">{w('kd')}</span>}
          />
          {saving !== null && saving > 0 ? (
            <p className={cx('gz-per__save gz-t-caption', saving <= feeFils && 'is-weak')}>
              <Figures text={saving > feeFils ? w('saving', { amount: f.money(saving, { mode: 'browse' }), unit: flatBasis ? '' : ` ${t('commonUnitPerGuest')}` }) : w('voucherSmall', { amount: f.money(saving, { mode: 'browse' }) })} />
            </p>
          ) : null}
          <div className="gz-per__steppers">
            <Stepper
              label={w('min')}
              caption={w('rule', { step: f.integer(pkg.guestStep) })}
              value={min}
              min={pkg.guestStep}
              max={max}
              step={pkg.guestStep}
              onChange={v => {
                setMin(v)
                onChange?.(draft({ minGuests: v }))
              }}
            />
            <Stepper
              label={w('max')}
              value={max}
              min={min}
              max={1500}
              step={pkg.guestStep}
              onChange={v => {
                setMax(v)
                onChange?.(draft({ maxGuests: v }))
              }}
            />
          </div>
          <div className="gz-per__inc">
            <p className="gz-t-label gz-per__label">{w('inclusions')}</p>
            <ul className="gz-per__chips">
              {inc.map((i, k) => (
                <li key={`${i.en}-${k}`} className="gz-per__chip gz-t-body-s">
                  <bdi dir="auto" className="gz-per__chip-label">
                    {bi(i)}
                  </bdi>
                  <button
                    type="button"
                    className="gz-reset gz-per__x gz-press"
                    aria-label={w('remove', { name: bi(i) })}
                    onClick={() => {
                      const next = inc.filter((_, j) => j !== k)
                      setInc(next)
                      onChange?.(draft({ inclusions: next }))
                    }}
                  >
                    <Icon name="close" size="xs" />
                  </button>
                </li>
              ))}
              <li>
                <button type="button" className="gz-reset gz-per__chip gz-per__chip--add gz-t-body-s gz-press" onClick={onAddInclusion}>
                  <Icon name="plus" size="xs" />
                  {w('add')}
                </button>
              </li>
            </ul>
          </div>
          <p className="gz-t-caption gz-per__note">{w('dashboard')}</p>
        </div>
      ) : null}
    </section>
  )
}
