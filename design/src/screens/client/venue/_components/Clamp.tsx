// Clamp (ADR 0034, docs/design/02-text-diet.md section 1): authored text (a hall description, a review, the venue's own terms) is exempt from
// the word budget but never runs long on the page: two or three lines, then the chevron. "Show more" is the chevron, not a sentence.
// The cut is made on the text itself (not by CSS), so the page carries only what is shown; the full text is one tap away in place.
import { useState } from 'react'
import { useT } from '../../../../i18n'
import { IconButton } from '../../../../system'
import './clamp.css'

/** The text up to `limit` characters, cut at the last space so no word is split, closed with an ellipsis. */
export function cutAt(text: string, limit: number): string {
  if (text.length <= limit) return text
  const head = text.slice(0, limit)
  const space = head.lastIndexOf(' ')
  return `${(space > limit * 0.6 ? head.slice(0, space) : head).replace(/[\s,.;:،؛]+$/, '')}…`
}

export type ClampProps = {
  text: string
  /** Characters shown before the chevron (about two lines at 15 px on a phone). */
  limit?: number
  /** Language of the text when it is not the interface language (a review as typed). */
  lang?: string
  className?: string
  dataId?: string
}

export function Clamp({ text, limit = 96, lang, className, dataId }: ClampProps) {
  const t = useT('client-venue')
  const [open, setOpen] = useState(false)
  const long = text.length > limit
  return (
    <div className={`gzv-clamp ${className ?? ''}`} data-gz-id={dataId}>
      <p className="gzv-clamp__text gz-t-body-s" lang={lang} dir="auto">
        {long && !open ? cutAt(text, limit) : text}
      </p>
      {long ? (
        <IconButton
          icon={open ? 'chevron-up' : 'chevron-down'}
          iconSize="sm"
          label={open ? t('clientVenueLess') : t('clientVenueMore')}
          aria-expanded={open}
          onClick={() => setOpen(v => !v)}
          className="gzv-clamp__btn"
        />
      ) : null}
    </div>
  )
}
