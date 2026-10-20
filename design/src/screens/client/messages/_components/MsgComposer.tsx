// Composer: the message bar of the conversation (CA-CHAT-06, CA-CHAT-07). Suggestion chips above on a new enquiry, then Attach (+), a text
// field that sets its own direction (`dir=auto`, ADR 0014 D8) and either Send (text typed) or the hold-to-record microphone (field empty).
// Voice: hold to record with a live waveform; slide toward inline-start to cancel (left in English, right in Arabic); slide up to lock;
// releasing sends. Haptics at start, cancel and lock (the web prototype asks the device to vibrate; Flutter uses HapticFeedback).
// Gold is not used: a chat is not a verb, and the one gold action of a conversation is the booking's own.
import { useEffect, useRef, useState, type PointerEvent } from 'react'
import type { IconName } from '@gz/tokens'
import { Chip, Figures, Icon, IconButton } from '../../../../system'
import { MsgMicIcon as MicIcon } from './MsgMicIcon'
import { useMsg } from './useMsg'
import './composer.css'

/** A suggestion: `text` goes into the field; `onPress` instead takes the couple somewhere (Book a visit opens the visit sheet). */
export type QuickReply = { id: string; label: string; icon?: IconName; text?: string; onPress?: () => void }

export type ComposerProps = {
  value: string
  onChange: (value: string) => void
  onSend: (text: string) => void
  onAttach: () => void
  onVoice: (seconds: number) => void
  /** A press too short to record: the hint says to hold. */
  onTooShort?: () => void
  /** Suggestion chips (a new enquiry): tapping one puts its sentence in the field, never sends it. */
  quick?: QuickReply[]
  /** Static frames: draw the recording row as if the thumb were down (seven seconds). */
  previewRecording?: 'holding' | 'locked'
  disabled?: boolean
}

const CANCEL_DISTANCE = 96
const LOCK_DISTANCE = 64
const BARS = 28
const TICK_MS = 100
const STEPS = [4, 8, 12, 16, 20, 24]

type Rec = { mode: 'holding' | 'locked'; ticks: number; cancel: boolean }

/** A deterministic level for tick `n` (a recorded level meter, repeatable in a screenshot). */
const level = (n: number): number => {
  const h = (Math.imul(n + 7, 2654435761) >>> 0) % 997
  return STEPS[(h % 4) + (n % 3 === 0 ? 2 : 0)] ?? 8
}

const buzz = () => {
  try {
    navigator.vibrate?.(10)
  } catch {
    /* no haptics on this device */
  }
}

export function MsgComposer({ value, onChange, onSend, onAttach, onVoice, onTooShort, quick = [], previewRecording, disabled = false }: ComposerProps) {
  const { t, tc, isRtl, clock } = useMsg()
  const [rec, setRecState] = useState<Rec | null>(previewRecording ? { mode: previewRecording, ticks: 70, cancel: false } : null)
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

  const run = () => {
    stopTicker()
    ticker.current = window.setInterval(() => {
      const r = recRef.current
      if (r) setRec({ ...r, ticks: r.ticks + 1 })
    }, TICK_MS)
  }

  const begin = (e: PointerEvent<HTMLButtonElement>) => {
    if (previewRecording || disabled) return
    e.currentTarget.setPointerCapture(e.pointerId)
    start.current = { x: e.clientX, y: e.clientY }
    setRec({ mode: 'holding', ticks: 0, cancel: false })
    buzz()
    run()
  }
  const move = (e: PointerEvent<HTMLButtonElement>) => {
    const s = start.current
    const r = recRef.current
    if (!s || !r || r.mode === 'locked' || previewRecording) return
    // Inline-start is left in LTR and right in RTL: the cancel slide is measured along it.
    const along = (isRtl ? 1 : -1) * (e.clientX - s.x)
    const up = s.y - e.clientY
    if (up > LOCK_DISTANCE) {
      setRec({ ...r, mode: 'locked', cancel: false })
      buzz()
    } else if (r.cancel !== along > CANCEL_DISTANCE) {
      setRec({ ...r, cancel: along > CANCEL_DISTANCE })
      if (along > CANCEL_DISTANCE) buzz()
    }
  }
  const end = () => {
    const r = recRef.current
    if (!start.current || !r || previewRecording) return
    start.current = null
    if (r.mode === 'locked') return
    stopTicker()
    setRec(null)
    if (r.cancel) return
    const seconds = Math.floor(r.ticks / (1000 / TICK_MS))
    if (seconds > 0) onVoice(seconds)
    else onTooShort?.()
  }

  const discard = () => {
    stopTicker()
    setRec(null)
  }
  const sendLocked = () => {
    const seconds = Math.max(1, Math.floor((recRef.current?.ticks ?? 0) / (1000 / TICK_MS)))
    stopTicker()
    setRec(null)
    onVoice(seconds)
  }

  const submit = () => {
    const text = value.trim()
    if (!text) return
    onSend(text)
  }

  const seconds = rec ? Math.floor(rec.ticks / (1000 / TICK_MS)) : 0
  const bars = rec ? Array.from({ length: Math.min(BARS, rec.ticks + 1) }, (_, i) => level(Math.max(0, rec.ticks - Math.min(BARS, rec.ticks + 1) + 1) + i)) : []

  return (
    <div className="gzm-cmp" data-gz="Composer">
      <div className="gzm-cmp__inner">
        {rec || quick.length === 0 ? null : (
          <div className="gzm-cmp__quick" role="group" aria-label={t('clientMessagesComposerLabel')}>
            {quick.map(q => (
              <Chip
                key={q.id}
                iconStart={q.icon}
                onClick={() => {
                  if (q.onPress) return q.onPress()
                  onChange(q.text ?? '')
                  inputRef.current?.focus()
                }}
              >
                {q.label}
              </Chip>
            ))}
          </div>
        )}
        <div className={`gzm-cmp__row${rec ? ' gzm-cmp__row--rec' : ''}`} role={rec ? 'group' : undefined} aria-label={rec ? t('clientMessagesRecording') : undefined}>
          {rec?.mode === 'locked' ? (
            <IconButton icon="trash" label={t('clientMessagesRecordDelete')} onClick={discard} />
          ) : rec ? (
            <span className="gzm-cmp__slot" aria-hidden="true">
              <Icon name="chevron-up" size="sm" tone="secondary" />
            </span>
          ) : (
            <IconButton icon="plus" label={t('clientMessagesAttach')} variant="outline" onClick={onAttach} disabled={disabled} />
          )}
          {rec ? (
            <span className="gzm-cmp__rec">
              <span className="gzm-cmp__recdot" aria-hidden="true" />
              <span className="gzm-cmp__time gz-t-title">
                <Figures text={clock(seconds)} />
              </span>
              <span className="gzm-cmp__wave" aria-hidden="true">
                {bars.map((h, i) => (
                  <span key={i} className="gzm-cmp__bar" style={{ blockSize: h }} />
                ))}
              </span>
              {rec.mode === 'holding' ? (
                <span className={`gzm-cmp__hint gz-t-caption${rec.cancel ? ' is-cancel' : ''}`} aria-live="polite">
                  <Icon name={rec.cancel ? 'trash' : 'chevron-left'} size="xs" tone={rec.cancel ? 'danger' : 'secondary'} />
                  <span>{rec.cancel ? t('clientMessagesReleaseCancel') : t('clientMessagesSlideCancel')}</span>
                </span>
              ) : null}
            </span>
          ) : (
            <label className="gzm-cmp__field">
              <span className="gz-sr-only">{t('clientMessagesComposerLabel')}</span>
              <input
                ref={inputRef}
                className="gzm-cmp__input gz-t-body gz-auto"
                dir="auto"
                value={value}
                placeholder={t('clientMessagesComposerPlaceholder')}
                disabled={disabled}
                enterKeyHint="send"
                onChange={e => onChange(e.target.value)}
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
            <button key="send-locked" type="button" className="gz-reset gzm-cmp__send gz-press" onClick={sendLocked} aria-label={t('clientMessagesRecordSend')}>
              <Icon name="send" size="sm" tone="on-dark" />
            </button>
          ) : !rec && value.trim() ? (
            <button key="send" type="button" className="gz-reset gzm-cmp__send gz-press" onClick={submit} aria-label={tc('commonActionSend')}>
              <Icon name="send" size="sm" tone="on-dark" />
            </button>
          ) : (
            /* The microphone stays mounted while it is held: the pointer is captured by this very element, and it must be the one that hears the release. */
            <button
              key="mic"
              type="button"
              className={`gz-reset gzm-cmp__mic gz-press${rec ? ' is-live' : ''}`}
              aria-label={t('clientMessagesRecordHold')}
              disabled={disabled}
              onPointerDown={begin}
              onPointerMove={move}
              onPointerUp={end}
              onPointerCancel={end}
              onKeyDown={e => {
                // Keyboard and switch access: Enter or Space starts a locked recording (send or delete follows).
                if ((e.key === 'Enter' || e.key === ' ') && !recRef.current) {
                  e.preventDefault()
                  setRec({ mode: 'locked', ticks: 0, cancel: false })
                  run()
                }
              }}
            >
              <MicIcon />
            </button>
          )}
        </div>
      </div>
    </div>
  )
}
