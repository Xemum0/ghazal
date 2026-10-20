// The extra editor sheet (HL-VENU-02, state extra-editor): bilingual name and short description, price, how it is charged, active.
// The same content runs in the navigator's sheet host and, in a static frame, inside an inline Sheet.
import { Button, ChipGroup, ToggleRow, useNav } from '../../../../system'
import { BilingualField, FieldError, PriceField, SheetFrame } from './fields'
import { useV } from './bits'
import { useDraft, useIsStatic } from './editor'
import { useUnitLabel } from './labels'
import { blankExtra, seedExtra, useVenueStore, type ExtraModel, type ExtraUnit } from './store'
import { isReservedName } from './venue'

const UNITS: readonly ExtraUnit[] = ['event', 'hour', 'guest', 'unit']

export type ExtraSheetProps = {
  /** An extra id to edit; omitted for a new one. */
  extraId?: string
  offline?: boolean
}

export function ExtraSheet({ extraId, offline = false }: ExtraSheetProps) {
  const { t, c, f } = useV()
  const nav = useNav()
  const isStatic = useIsStatic()
  const unit = useUnitLabel()
  const stored = useVenueStore(s => (extraId ? s.extras[extraId] : undefined))
  const { draft, patch, dirty } = useDraft<ExtraModel>(() => stored ?? (extraId ? seedExtra(extraId) : null) ?? blankExtra())

  const reservedAr = isReservedName(draft.nameAr)
  const reservedEn = isReservedName(draft.nameEn)
  const namesMissing = draft.nameAr.trim() === '' || draft.nameEn.trim() === ''
  const priceMissing = draft.priceFils <= 0
  const problem = reservedAr || reservedEn ? t('hotelVenueReservedName') : namesMissing ? t('hotelVenueNameRequired') : priceMissing ? t('hotelVenueNeedPrice') : undefined
  const reason = offline ? t('hotelVenueNeedsConnection') : problem ?? undefined

  const save = () => {
    if (reason || isStatic) return
    useVenueStore.getState().saveExtra({ ...draft, nameAr: draft.nameAr.trim(), nameEn: draft.nameEn.trim(), descAr: draft.descAr.trim(), descEn: draft.descEn.trim() })
    nav.closeSheet()
    nav.toast({ message: t(draft.isNew ? 'hotelVenueToastExtraCreated' : 'hotelVenueToastExtraSaved'), icon: 'check-circle' })
  }

  return (
    <SheetFrame
      footer={
        <Button variant="primary" fullWidth disabled={Boolean(reason)} reason={reason} onClick={save}>
          {c('commonActionSave')}
        </Button>
      }
    >
      <BilingualField
        label={t('hotelVenueFieldName')}
        ar={draft.nameAr}
        en={draft.nameEn}
        onAr={v => patch({ nameAr: v })}
        onEn={v => patch({ nameEn: v })}
        errorAr={reservedAr ? t('hotelVenueReservedName') : undefined}
        errorEn={reservedEn ? t('hotelVenueReservedName') : undefined}
        maxLength={60}
      />
      <PriceField
        label={t('hotelVenueFieldPrice')}
        fils={draft.priceFils > 0 ? draft.priceFils : null}
        onChange={v => patch({ priceFils: v ?? 0 })}
        helper={draft.fromFils !== null && draft.upToFils !== null ? t('hotelVenueExtraRange', { from: f.money(draft.fromFils), to: f.money(draft.upToFils) }) : undefined}
      />
      <div className="hv-zone">
        <span className="gz-t-label">{t('hotelVenueFieldUnit')}</span>
        <ChipGroup<ExtraUnit>
          label={t('hotelVenueFieldUnit')}
          value={draft.unit}
          onChange={v => {
            if (v) patch({ unit: v })
          }}
          options={UNITS.map(u => ({ value: u, label: unit(u) }))}
        />
      </div>
      <BilingualField label={t('hotelVenueFieldDescription')} ar={draft.descAr} en={draft.descEn} onAr={v => patch({ descAr: v })} onEn={v => patch({ descEn: v })} multiline maxLength={140} />
      <ToggleRow
        title={t('hotelVenueFieldShow')}
        description={draft.active ? t('hotelVenueExtraActiveOn') : t('hotelVenueExtraActiveOff')}
        checked={draft.active}
        onChange={v => patch({ active: v })}
        divider={false}
      />
      {problem && dirty ? <FieldError>{problem}</FieldError> : null}
    </SheetFrame>
  )
}
