// WhatCouplesSee (HL-PROV-03): the live preview of the listing as a registered client sees it: the title in the client's language, the category,
// the first package with its two prices (the voucher price is the headline when a voucher is offered). It reads the editor's draft, so every
// keystroke shows. A package without a valid voucher price shows the standard price only, exactly as a client would.
import { Icon, PriceCompare } from '../../../../system'
import type { IconName } from '@gz/tokens'
import { UserText, useBi, useFormat, useP } from './bits'
import { categoryName } from './model'
import { packageName, voucherOffered } from './PackageCards'
import type { ListingDraft } from './store'
import './what-couples-see.css'

export function WhatCouplesSee({ draft }: { draft: ListingDraft }) {
  const { t } = useP()
  const bi = useBi()
  const f = useFormat()
  const title = f.lang === 'ar' ? draft.titleAr || draft.titleEn : draft.titleEn || draft.titleAr
  const first = draft.packages.find(p => p.standardFils !== null && p.standardFils > 0)
  const cat = draft.categoryId ? categoryName(draft.categoryId) : undefined
  return (
    <section className="hp-wcs" data-gz="WhatCouplesSee" aria-label={t('hotelProviderPreviewTitle')}>
      <header className="hp-wcs__head">
        <Icon name={'eye' as IconName} size="sm" tone="secondary" />
        <span className="gz-t-label hp-wcs__label">{t('hotelProviderPreviewTitle')}</span>
      </header>
      {title ? <UserText role="title" className="hp-wcs__title">{title}</UserText> : <span className="gz-t-body-s hp-wcs__ph">{t('hotelProviderPreviewNoTitle')}</span>}
      {cat ? <span className="gz-t-caption hp-wcs__cat">{bi(cat)}</span> : null}
      {first && first.standardFils !== null ? (
        <div className="hp-wcs__pkg">
          <span className="gz-t-body-s hp-wcs__pkgname" dir="auto">
            {packageName(first, f.lang)}
          </span>
          <PriceCompare
            standard={first.standardFils}
            voucher={voucherOffered(first) ? first.voucherFils : null}
            structure={first.structure}
            variant="inline"
            showNet={false}
            size="strong"
          />
        </div>
      ) : (
        <span className="gz-t-body-s hp-wcs__ph">{t('hotelProviderPreviewNoPackage')}</span>
      )}
    </section>
  )
}
