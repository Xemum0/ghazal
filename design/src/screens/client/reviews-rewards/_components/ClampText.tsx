// ClampText (ADR 0034, docs/design/02-text-diet.md section 1): authored text (a review, the venue's reply) is exempt from the word budget
// but never runs long on the page: two lines, then the chevron. "Show more" is the chevron, not a sentence. The cut is made on the text
// itself, so the page carries only what is shown; the full text is one tap away in place. Flow-local twin of the venue flow's Clamp
// (docs/engineering/requests.md asks the system to promote one).
import { useState } from 'react'
import { IconButton } from '../../../../system'
import { useRr } from './useRr'
import './clamp-text.css'

/** The text up to `limit` characters, cut at the last space so no word is split, closed with an ellipsis. */
export function cutAt(text: string, limit: number): string {
  if (text.length <= limit) return text
  const head = text.slice(0, limit)
  const space = head.lastIndexOf(' ')
  return `${(space > limit * 0.6 ? head.slice(0, space) : head).replace(/[\s,.;:،؛]+$/, '')}…`
}

export type ClampTextProps = {
  text: string
  /** Characters shown before the chevron (about two lines at 15 px on a phone). */
  limit?: number
  /** Language of the text when it is not the interface language (a review as typed). */
  lang?: string
  dataId?: string
}

export function ClampText({ text, limit = 96, lang, dataId }: ClampTextProps) {
  const { t, tc } = useRr()
  const [open, setOpen] = useState(false)
  const long = text.length > limit
  return (
    <div className="rvc" data-gz-id={dataId}>
      <p className="rvc__text gz-t-body-s" lang={lang} dir="auto">
        {long && !open ? cutAt(text, limit) : text}
      </p>
      {long ? (
        <IconButton
          icon={open ? 'chevron-up' : 'chevron-down'}
          iconSize="sm"
          label={open ? tc('commonActionShowLess') : t('clientReviewsRewardsShowMore')}
          aria-expanded={open}
          onClick={() => setOpen(v => !v)}
          className="rvc__btn"
        />
      ) : null}
    </div>
  )
}
