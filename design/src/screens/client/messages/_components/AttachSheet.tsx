// AttachSheet: what a couple can add to a message (CA-CHAT-06). Camera, Photos and Document as three equal tiles (a glyph and one word, no
// hint), then the recent photographs as a rail of 80 squares (one tap sends). The size limits and the privacy line are the one paragraph
// the sheet may hold, behind an info glyph. Sent media is private between the two sides (ADR 0015). The sheet carries no gold: choosing an
// item sends it, and a send is not a verb of booking.
import type { IconName } from '@gz/tokens'
import { Icon, InfoButton, Photo, imageSrc, useBi } from '../../../../system'
import { libraryPhotos, type LibraryPhoto } from './media'
import { useMsg } from './useMsg'
import './attach.css'

export type AttachPick = { kind: 'camera' } | { kind: 'photo' } | { kind: 'document' } | { kind: 'recent'; photo: LibraryPhoto }

export function AttachSheet({ onPick }: { onPick?: (pick: AttachPick) => void }) {
  const { t, limits } = useMsg()
  const bi = useBi()
  const tiles: { kind: 'camera' | 'photo' | 'document'; icon: IconName; label: string }[] = [
    { kind: 'camera', icon: 'camera', label: t('clientMessagesAttachCamera') },
    { kind: 'photo', icon: 'image', label: t('clientMessagesAttachPhoto') },
    { kind: 'document', icon: 'document', label: t('clientMessagesAttachDocument') },
  ]
  return (
    <div className="gzm-att" data-gz="AttachSheet">
      <ul className="gzm-att__tiles">
        {tiles.map(r => (
          <li key={r.kind} className="gzm-att__cell">
            <button type="button" className="gz-reset gzm-att__tile gz-press" onClick={() => onPick?.({ kind: r.kind })}>
              <span className="gzm-att__icon">
                <Icon name={r.icon} size="md" />
              </span>
              <span className="gzm-att__label gz-t-body-s">{r.label}</span>
            </button>
          </li>
        ))}
      </ul>
      <div className="gzm-att__head">
        <Icon name="gallery" size="sm" tone="secondary" label={t('clientMessagesAttachRecent')} />
        <InfoButton title={t('clientMessagesAttachLimitsTitle')}>{t('clientMessagesAttachLimits', { photo: limits.photo, video: limits.video })}</InfoButton>
      </div>
      <div className="gzm-att__rail" role="group" aria-label={t('clientMessagesAttachRecent')}>
        {libraryPhotos.slice(0, 6).map(p => (
          <button key={p.file} type="button" className="gz-reset gzm-att__thumb gz-press" onClick={() => onPick?.({ kind: 'recent', photo: p })} aria-label={bi(p.alt)}>
            <Photo src={imageSrc(p.file)} alt="" sizes="80px" className="gzm-att__photo" />
          </button>
        ))}
      </div>
    </div>
  )
}
