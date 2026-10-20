// Composer: the message bar of the conversation (HA-MSG-02, HA-MSG-03). Quick-reply chips above (defaults only, bilingual), then
// Attach (+), a text field that sets its own direction (`dir=auto`, ADR 0014 D8) and either Send (text typed) or a hold-to-record
// voice button (field empty). Voice: hold to record; slide toward inline-start to cancel; slide up to lock; releasing sends. The
// slide direction follows the language (inline-start is the right in Arabic). The play triangle of a voice bubble never mirrors.
// Gold is not used here: the one gold action of the thread is Accept in the context bar. Text diet: the recording hints are glyphs
// (a chevron and a bin to cancel, a chevron and a lock to lock), the sentences are read.
import { useEffect, useRef, useState, type PointerEvent } from 'react'
import { Chip, Icon, IconButton } from '../../../../system'
import { useLang } from '../../../../shell/lang'
import { useFormat } from '../../../../i18n'
import { Figures, useWords } from './bits'
import './composer.css'

export type QuickReply = { id: string; label: string; text: string }

export type ComposerProps = {
  quick: QuickReply[]
  onSend: (text: string) => void
  onAttach: () => void
  onVoice: (seconds: number) => void
  /** A tap that was too short to record: the hint says to hold. */
  onTooShort?: () => void
  /** Static frames: draw the recording row as if the thumb were down (seven seconds). */
  previewRecording?: 'holding' | 'locked'
}

const CANCEL_DISTANCE = 96
const LOCK_DISTANCE = 64

type Rec = { mode: 'holding' | 'locked'; seconds: number; cancel: boolean }

export function Composer({ quick, onSend, onAttach, onVoice, onTooShort, previewRecording }: ComposerProps) {
  const { t, c } = useWords()
  const f = useFormat()
  const { isRtl } = useLang()
  const [text, setText] = useState('')
  const [rec, setRecState] = useState<Rec | null>(previewRecording ? { mode: previewRecording, seconds: 7, cancel: false } : null)
  const recRef = useRef<Rec | null>(rec)
  const setRec = (next: Rec | null) => {
    recRef.current = next
    setRecState(next)
  }
  const start = useRef<{ x: number; y: number } | null>(null)
  const ticker = useRef<number | null>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  const stopTicker = () => {
    if (ticker.current !== null) window.clearInterval(ticker.current)
    ticker.current = null
  }
  useEffect(() => stopTicker, [])

  const clock = (s: number) => `${f.integer(Math.floor(s / 60))}:${String(s % 60).padStart(2, '0')}`

  const begin = (e: PointerEvent<HTMLButtonElement>) => {
    if (previewRecording) return
    e.currentTarget.setPointerCapture(e.pointerId)
    start.current = { x: e.clientX, y: e.clientY }
    setRec({ mode: 'holding', seconds: 0, cancel: false })
    stopTicker()
    ticker.current = window.setInterval(() => {
      const r = recRef.current
      if (r) setRec({ ...r, seconds: r.seconds + 1 })
    }, 1000)
  }
  const move = (e: PointerEvent<HTMLButtonElement>) => {
    const s = start.current
    const r = recRef.current
    if (!s || !r || r.mode === 'locked' || previewRecording) return
    // Inline-start is left in LTR and right in RTL: the cancel slide is measured along it.
    const along = (isRtl ? 1 : -1) * (e.clientX - s.x)
    const up = s.y - e.clientY
    if (up > LOCK_DISTANCE) setRec({ ...r, mode: 'locked', cancel: false })
    else if (r.cancel !== along > CANCEL_DISTANCE) setRec({ ...r, cancel: along > CANCEL_DISTANCE })
  }
  const end = () => {
    const r = recRef.current
    if (!start.current || !r || previewRecording) return
    start.current = null
    if (r.mode === 'locked') return
    stopTicker()
    setRec(null)
    if (r.cancel) return
    if (r.seconds > 0) onVoice(r.seconds)
    else onTooShort?.()
  }

  const discard = () => {
    stopTicker()
    setRec(null)
  }
  const sendLocked = () => {
    const seconds = Math.max(1, recRef.current?.seconds ?? 1)
    stopTicker()
    setRec(null)
    onVoice(seconds)
  }

  const submit = () => {
    const value = text.trim()
    if (!value) return
    onSend(value)
    setText('')
  }

  return (
    <div className="ht-cmp" data-gz="Composer">
     <div className="ht-cmp__inner">
      {rec ? null : (
        <div className="ht-cmp__quick" role="group" aria-label={t('hotelTodayQuickLabel')}>
          {quick.map(q => (
            <Chip
              key={q.id}
              onClick={() => {
                setText(q.text)
                inputRef.current?.focus()
              }}
            >
              {q.label}
            </Chip>
          ))}
        </div>
      )}
      <div className={`ht-cmp__row${rec ? ' ht-cmp__row--rec' : ''}`}>
        {rec ? (
          rec.mode === 'locked' ? (
            <IconButton icon="trash" label={t('hotelTodayRecordDelete')} onClick={discard} />
          ) : (
            <span className="ht-cmp__spacer" aria-hidden="true" />
          )
        ) : (
          <IconButton icon="plus" label={t('hotelTodayAttach')} variant="outline" onClick={onAttach} />
        )}
        {rec ? (
          <span className="ht-cmp__rec" role="status" aria-label={t('hotelTodayRecording')}>
            <span className="ht-cmp__recdot" aria-hidden="true" />
            <span className="ht-cmp__time gz-t-title">
              <Figures text={clock(rec.seconds)} />
            </span>
            <span className={`ht-cmp__recnote${rec.cancel ? ' is-cancel' : ''}`}>
              {rec.mode === 'locked' ? (
                <>
                  <Icon name="lock" size="sm" tone="secondary" />
                  <span className="gz-sr-only">{t('hotelTodayRecordingLocked')}</span>
                </>
              ) : rec.cancel ? (
                <>
                  <Icon name="trash" size="sm" tone="danger" />
                  <span className="gz-sr-only">{c('commonActionCancel')}</span>
                </>
              ) : (
                <>
                  <span className="ht-cmp__hint" aria-hidden="true">
                    <Icon name="chevron-left" size="xs" tone="secondary" />
                    <Icon name="trash" size="xs" tone="secondary" />
                  </span>
                  <span className="ht-cmp__hint" aria-hidden="true">
                    <Icon name="chevron-up" size="xs" tone="secondary" />
                    <Icon name="lock" size="xs" tone="secondary" />
                  </span>
                  <span className="gz-sr-only">
                    {t('hotelTodaySlideCancel')}. {t('hotelTodaySlideLock')}
                  </span>
                </>
              )}
            </span>
          </span>
        ) : (
          <label className="ht-cmp__field">
            <span className="gz-sr-only">{t('hotelTodayComposerLabel')}</span>
            <input
              ref={inputRef}
              className="ht-cmp__input gz-t-body gz-auto"
              dir="auto"
              value={text}
              placeholder={t('hotelTodayComposerPlaceholder')}
              onChange={e => setText(e.target.value)}
              onKeyDown={e => {
                if (e.key === 'Enter') {
                  e.preventDefault()
                  submit()
                }
              }}
            />
          </label>
        )}
        {rec?.mode === 'locked' ? (
          <button type="button" className="gz-reset ht-cmp__send gz-press" onClick={sendLocked} aria-label={t('hotelTodayRecordSend')}>
            <Icon name="send" size="sm" tone="on-dark" />
          </button>
        ) : text.trim() && !rec ? (
          <button type="button" className="gz-reset ht-cmp__send gz-press" onClick={submit} aria-label={c('commonActionSend')}>
            <Icon name="send" size="sm" tone="on-dark" />
          </button>
        ) : (
          <button
            type="button"
            className={`gz-reset ht-cmp__mic gz-press${rec ? ' is-live' : ''}`}
            aria-label={t('hotelTodayRecordHold')}
            onPointerDown={begin}
            onPointerMove={move}
            onPointerUp={end}
            onPointerCancel={end}
            onKeyDown={e => {
              if (e.key === 'Enter' || e.key === ' ') onVoice(1)
            }}
          >
            <Icon name="mic" size="md" />
          </button>
        )}
      </div>
     </div>
    </div>
  )
}
