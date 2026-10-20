// PackageCards and PackageSheet (HL-PROV-03): the packages of a listing, each with a standard price and a voucher price on the same basis
// (per person or per package), and the sheet that edits one. A voucher is offered only when the saving beats the KD 2 fee (voucher-model 4.1);
// otherwise the package says so, in words, before the client could ever see it.
import { useState } from 'react'
import { Button, Icon, PricingStructureToggle, Price, TextField } from '../../../../system'
import { FieldError, PriceField, BilingualField } from './fields'
import { SheetFrame, useFormat, useP } from './bits'
import { FEE_FILS } from './model'
import { scriptOf, type PackageDraft } from './store'
import './package-cards.css'

export const savingOf = (p: Pick<PackageDraft, 'standardFils' | 'voucherFils'>): number | null =>
  p.standardFils !== null && p.voucherFils !== null ? p.standardFils - p.voucherFils : null

/** A voucher is offered only when the saving is more than the fee. */
export const voucherOffered = (p: Pick<PackageDraft, 'standardFils' | 'voucherFils'>): boolean => {
  const s = savingOf(p)
  return s !== null && s > FEE_FILS
}

export const packageName = (p: PackageDraft, lang: 'ar' | 'en'): string => (lang === 'ar' ? p.nameAr || p.nameEn : p.nameEn || p.nameAr)

// ---------------------------------------------------------------- cards

export type PackageCardsProps = {
  packages: PackageDraft[]
  onEdit: (p: PackageDraft) => void
  onAdd: () => void
  error?: boolean
}

export function PackageCards({ packages, onEdit, onAdd, error = false }: PackageCardsProps) {
  const { t, c } = useP()
  const f = useFormat()
  const lang = f.lang
  return (
    <div className="hp-pk" data-gz="PackageCards">
      {null}
      <ul className="hp-pk__list">
        {packages.map(p => {
          const offered = voucherOffered(p)
          const saving = savingOf(p)
          return (
            <li key={p.id}>
              <button type="button" className="gz-reset hp-pk__card gz-press" onClick={() => onEdit(p)} data-incomplete={p.standardFils === null || undefined}>
                <span className="hp-pk__head">
                  <span className="gz-t-title hp-pk__name" dir="auto">
                    {packageName(p, lang) || t('hotelProviderPkgUnnamed')}
                  </span>
                  <span className="gz-t-caption hp-pk__basis">{c(p.structure === 'per_person' ? 'commonPricingPerPerson' : 'commonPricingPackage')}</span>
                  <Icon name="chevron-right" size="sm" tone="secondary" />
                </span>
                <span className="hp-pk__prices">
                  <span className="hp-pk__price">
                    <span className="gz-t-caption hp-pk__label">{c('commonStandardPrice')}</span>
                    {p.standardFils !== null ? <Price fils={p.standardFils} size="strong" /> : <span className="gz-t-body-s">{c('commonLabelNotDecided')}</span>}
                  </span>
                  <span className="hp-pk__price">
                    <span className="gz-t-caption hp-pk__label">{c('commonVoucherPrice')}</span>
                    {p.voucherFils !== null ? <Price fils={p.voucherFils} size="strong" /> : <span className="gz-t-body-s">{c('commonLabelNotDecided')}</span>}
                  </span>
                </span>
                {offered && saving !== null ? (
                  <span className="hp-pk__line gz-t-caption hp-pk__line--ok">
                    <Icon name="check" size="xs" tone="success" />
                    {c('commonYouSave', { amount: f.money(saving, { mode: 'browse' }) })}
                  </span>
                ) : saving !== null ? (
                  <span className="hp-pk__line gz-t-caption">
                    <Icon name="info" size="xs" tone="secondary" />
                    {t('hotelProviderPkgNoVoucher')}
                  </span>
                ) : null}
              </button>
            </li>
          )
        })}
      </ul>
      {error ? <FieldError>{t('hotelProviderPkgNeeded')}</FieldError> : null}
      <Button variant="secondary" iconStart="plus" onClick={onAdd}>
        {t('hotelProviderPkgAdd')}
      </Button>
    </div>
  )
}

// ---------------------------------------------------------------- sheet

export const newPackage = (): PackageDraft => ({ id: `pk-${Math.random().toString(36).slice(2, 8)}`, nameAr: '', nameEn: '', structure: 'package', standardFils: null, voucherFils: null, includes: [] })

export type PackageSheetProps = {
  initial: PackageDraft
  isNew: boolean
  onSave: (p: PackageDraft) => void
  onDelete?: () => void
  onClose?: () => void
  /** The frame that draws this sheet to show validation (a static state). */
  forceErrors?: boolean
}

export function PackageSheet({ initial, isNew, onSave, onDelete, onClose, forceErrors = false }: PackageSheetProps) {
  const { t, c } = useP()
  const f = useFormat()
  const [d, setD] = useState<PackageDraft>(initial)
  const [typed, setTyped] = useState('')
  const [tried, setTried] = useState(forceErrors)
  const patch = (p: Partial<PackageDraft>) => setD(s => ({ ...s, ...p }))
  const saving = savingOf(d)
  const over = d.standardFils !== null && d.voucherFils !== null && d.voucherFils > d.standardFils
  const err = {
    nameAr: tried && d.nameAr.trim() === '',
    nameEn: tried && d.nameEn.trim() === '',
    standard: tried && (d.standardFils === null || d.standardFils <= 0),
    voucher: tried && d.voucherFils === null,
  }
  const ok = d.nameAr.trim() !== '' && d.nameEn.trim() !== '' && d.standardFils !== null && d.standardFils > 0 && d.voucherFils !== null && !over
  const required = t('hotelProviderRequired')
  const addInclusion = () => {
    const v = typed.trim()
    if (!v || d.includes.includes(v) || d.includes.length >= 8) return
    patch({ includes: [...d.includes, v] })
    setTyped('')
  }
  const basis = d.structure === 'per_person' ? c('commonUnitPerGuest') : t('hotelProviderPkgPerPackage')
  return (
    <SheetFrame
      title={t(isNew ? 'hotelProviderPkgSheetNew' : 'hotelProviderPkgSheetEdit')}
      onClose={onClose}
      footer={
        <>
          <Button
            variant="primary"
            fullWidth
            onClick={() => {
              if (!ok) return setTried(true)
              onSave(d)
            }}
          >
            {t('hotelProviderPkgSave')}
          </Button>
          {onDelete && !isNew ? (
            <Button variant="tertiary" fullWidth onClick={onDelete}>
              {t('hotelProviderPkgDelete')}
            </Button>
          ) : null}
        </>
      }
    >
      <BilingualField
        label={t('hotelProviderPkgName')}
        ar={d.nameAr}
        en={d.nameEn}
        onAr={nameAr => patch({ nameAr })}
        onEn={nameEn => patch({ nameEn })}
        errorAr={err.nameAr ? required : undefined}
        errorEn={err.nameEn ? required : undefined}
        maxLength={48}
      />
      <div className="hp-pks__group">
        <span className="gz-t-label hp-pks__label">{c('commonPricingStructure')}</span>
        <PricingStructureToggle value={d.structure} onChange={v => v !== 'all' && patch({ structure: v })} />
      </div>
      <PriceField label={`${c('commonStandardPrice')} · ${basis}`} fils={d.standardFils} onChange={standardFils => patch({ standardFils })} error={err.standard ? required : undefined} />
      <PriceField
        label={`${c('commonVoucherPrice')} · ${basis}`}
        fils={d.voucherFils}
        onChange={voucherFils => patch({ voucherFils })}
        error={over ? t('hotelProviderPkgVoucherOver') : err.voucher ? required : undefined}
      />
      {saving !== null && !over ? (
        <div className="hp-pks__saving" data-offered={voucherOffered(d) || undefined} role="status">
          <Icon name={voucherOffered(d) ? 'check-circle' : 'info'} size="sm" tone={voucherOffered(d) ? 'success' : 'secondary'} />
          <span className="gz-t-body-s">
            {voucherOffered(d) ? t('hotelProviderPkgSaving', { amount: f.money(saving, { mode: 'browse' }) }) : t('hotelProviderPkgNoVoucherFull', { fee: f.money(FEE_FILS, { mode: 'browse' }) })}
          </span>
        </div>
      ) : null}
      <div className="hp-pks__group">
        <span className="gz-t-label hp-pks__label">{t('hotelProviderPkgIncludes')}</span>
        {d.includes.length ? (
          <ul className="hp-pks__inc">
            {d.includes.map(i => (
              <li key={i} className="hp-pks__chip gz-t-body-s">
                <span lang={scriptOf(i)} className="hp-pks__chiptext">
                  <bdi dir="auto">{i}</bdi>
                </span>
                <button type="button" className="gz-reset hp-pks__x gz-press" aria-label={t('hotelProviderPkgRemoveIncl', { name: i })} onClick={() => patch({ includes: d.includes.filter(x => x !== i) })}>
                  <Icon name="close" size="xs" />
                </button>
              </li>
            ))}
          </ul>
        ) : null}
        <TextField
          label={t('hotelProviderPkgInclPlaceholder')}
          value={typed}
          onValueChange={setTyped}
          maxLength={60}
          onKeyDown={e => {
            if (e.key === 'Enter') {
              e.preventDefault()
              addInclusion()
            }
          }}
          endAdornment={
            <Button variant="tertiary" onClick={addInclusion} disabled={!typed.trim()}>
              {c('commonActionAdd')}
            </Button>
          }
        />
      </div>
    </SheetFrame>
  )
}
