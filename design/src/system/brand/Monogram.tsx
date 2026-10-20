// Monogram: the brand initial on the thread (direction section 7, "app-icon study"): one letter, G or غ, in the display serif in
// ink-900, with the gold-500 thread running along its baseline and ending in a knot. A fixed LTR mark (brand marks never mirror).
// `tile` sets it on a rose-100 square (the app-icon and splash form); `bare` is the mark alone.
import { cx } from '../core/cx'
import { useLang } from '../../shell/lang'
import './monogram.css'

export type MonogramSize = 'sm' | 'md' | 'lg'

export type MonogramProps = {
  size?: MonogramSize
  /** The letter. Default follows the language: G in English, غ in Arabic. */
  script?: 'latin' | 'arabic'
  form?: 'bare' | 'tile'
  className?: string
}

export function Monogram({ size = 'md', script, form = 'bare', className }: MonogramProps) {
  const { lang } = useLang()
  const arabic = (script ?? (lang === 'ar' ? 'arabic' : 'latin')) === 'arabic'
  return (
    <span data-gz="Monogram" data-size={size} dir="ltr" role="img" aria-label="Ghazal" className={cx('gz-monogram', `gz-monogram--${size}`, `gz-monogram--${form}`, arabic && 'gz-monogram--arabic', className)}>
      <span className="gz-monogram__thread" aria-hidden="true">
        <span className="gz-monogram__line" />
        <span className="gz-monogram__knot" />
      </span>
      <span lang={arabic ? 'ar' : 'en'} aria-hidden="true" className="gz-monogram__letter">
        {arabic ? 'غ' : 'G'}
      </span>
    </span>
  )
}
