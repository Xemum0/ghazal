// EmptyState, SuccessState and ErrorState (ADR 0034, docs/design/02-text-diet.md section 5): one composition, an illustration, a title of at
// most four words and one action. The sentence that used to sit under the title (what happened, what to do, what was not charged) is not on
// the screen: `detail` opens it from an info glyph (the error-recovery exception), and a legacy `body` is treated the same way unless it is a
// helper of six words or fewer, so the screens built before the diet get shorter without being edited.
// Single-purpose state screens may centre their one composition (ADR 0034 D7); content screens never do.
// Props stay a superset of the previous EmptyState: `icon` is mapped to the matching illustration, `body` still renders.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { useT } from '../../i18n'
import { useAppKind } from '../../shell/device/context'
import { Button, type ButtonProps } from '../core/Button'
import { cx } from '../core/cx'
import { Illustration, type IllustrationSize, type IllustrationTone } from '../illustration/Illustration'
import type { IllustrationName } from '../illustration/registry'
import { InfoButton } from '../inputs/Info'
import './states.css'

export type StateAction = { label: string; onPress?: () => void; variant?: ButtonProps['variant']; iconStart?: IconName; loading?: boolean }

/** The drawing a glyph stands for, so a caller that still passes only an `icon` gets the matching illustration. */
const ART: Partial<Record<IconName, IllustrationName>> = {
  heart: 'empty-saved',
  'heart-fill': 'empty-saved',
  bookmark: 'empty-saved',
  'bookmark-fill': 'empty-saved',
  star: 'empty-saved',
  search: 'no-result',
  filter: 'no-result',
  offline: 'wifi-off',
  lock: 'shield',
  'shield-check': 'shield',
  warning: 'warning',
  'warning-circle': 'warning',
  'x-circle': 'warning',
  card: 'card',
  chat: 'empty-messages',
  'chat-text': 'empty-messages',
  mail: 'empty-messages',
  calendar: 'empty-bookings',
  'calendar-check': 'empty-bookings',
  'calendar-plus': 'empty-bookings',
  'calendar-dots': 'empty-bookings',
  'calendar-x': 'empty-bookings',
  clipboard: 'empty-bookings',
  checklist: 'empty-bookings',
  document: 'empty-bookings',
  ticket: 'empty-vouchers',
  offer: 'empty-vouchers',
  gift: 'empty-vouchers',
  bell: 'empty-notifications',
  pin: 'empty-visits',
  map: 'empty-visits',
  navigate: 'empty-visits',
  door: 'empty-visits',
  key: 'empty-visits',
  hall: 'empty-results',
  venue: 'empty-results',
  hotel: 'empty-results',
  home: 'empty-results',
  team: 'empty-messages',
  guests: 'empty-messages',
  staff: 'empty-messages',
  'users-three': 'empty-messages',
  'qr-code': 'qr',
  scan: 'partner-scanner',
  megaphone: 'partner-ads',
  clock: 'hourglass',
  'clock-off': 'hourglass',
  hourglass: 'hourglass',
  check: 'seal',
  'check-circle': 'seal',
  'check-double': 'seal',
  verified: 'seal',
  camera: 'camera',
  gallery: 'camera',
  image: 'camera',
  wallet: 'card',
  money: 'card',
  coins: 'card',
  receipt: 'empty-bookings',
  'chart-line': 'empty-results',
  'chart-bar': 'empty-results',
  'chart-up': 'empty-results',
}

const wordCount = (s: string) => s.trim().split(/\s+/).filter(Boolean).length
/** A helper is a fragment of six words or fewer; anything longer is a paragraph and belongs behind the info glyph. */
const HELPER_WORDS = 6

export type EmptyStateProps = {
  /** The drawing. Without it, `icon` is mapped to one, else a quiet shelf (or the warning triangle for the danger tone). */
  illustration?: IllustrationName
  /** Legacy: a glyph. Kept so existing callers compile; it only selects the illustration. */
  icon?: IconName
  /** At most four words. */
  title?: ReactNode
  /** Legacy and helper text. Six words or fewer render as a quiet caption; longer text moves behind the info glyph. */
  body?: ReactNode
  /** The paragraph behind the info glyph (error recovery, a rule). */
  detail?: ReactNode
  /** Sheet title of the detail (at most three words). Default: "Details". */
  detailTitle?: string
  action?: StateAction
  /** A second, quieter way out (tertiary). */
  secondary?: StateAction
  tone?: 'neutral' | 'danger'
  /** Rebinds the drawing's colour roles (the drawing never changes). */
  artTone?: IllustrationTone
  /** `fill` takes the free height of the screen body (a whole-screen blank); `inline` hugs its content (a blank inside a list). */
  fill?: boolean
  /** `hero` (200) for a whole screen, `lg` (144) inside a list. Default follows `fill`. */
  size?: Extract<IllustrationSize, 'lg' | 'hero'>
  /** Centred (default) or aligned to inline-start. */
  align?: 'center' | 'start'
  /** One line of facts (a `FactRow`) between the title and the action: the date and time of a booked visit, the trust period of a device. */
  facts?: ReactNode
  /** `none` drops the state's own gutter and block padding, for a state placed inside a shelf or body that already has them. */
  inset?: 'default' | 'none'
  /** Internal: a success composition (primary action by default, no danger tone). */
  kind?: 'empty' | 'success' | 'error'
}

export function EmptyState({
  illustration,
  icon,
  title,
  body,
  detail,
  detailTitle,
  action,
  secondary,
  tone = 'neutral',
  artTone,
  fill = true,
  size,
  align = 'center',
  facts,
  inset = 'default',
  kind,
}: EmptyStateProps) {
  const app = useAppKind()
  const t = useT('common')
  const name: IllustrationName = illustration ?? (icon ? ART[icon] : undefined) ?? (tone === 'danger' ? 'warning' : 'shelf')
  const bodyIsHelper = typeof body === 'string' ? wordCount(body) <= HELPER_WORDS : false
  const info = detail ?? (body && !bodyIsHelper ? body : null)
  const helper = body && bodyIsHelper ? body : null
  const role = kind ?? (tone === 'danger' ? 'error' : 'empty')
  return (
    <section
      className={cx('gz-state', fill && 'gz-state--fill', `gz-state--${tone}`, align === 'start' && 'gz-state--start', inset === 'none' && 'gz-state--flush')}
      data-gz={role === 'error' ? 'ErrorState' : role === 'success' ? 'SuccessState' : 'EmptyState'}
      data-gz-illustration={name}
    >
      <span className="gz-state__art" data-gz-id="state.art">
        <Illustration name={name} size={size ?? (fill ? 'hero' : 'lg')} tone={artTone ?? (tone === 'danger' ? 'danger' : 'default')} />
      </span>
      {title ? <h2 className={cx('gz-state__title', app === 'client' ? 'gz-t-d2' : 'gz-t-ui-title')}>{title}</h2> : null}
      {helper ? <p className="gz-state__helper gz-t-caption">{helper}</p> : null}
      {facts ? <div className="gz-state__facts">{facts}</div> : null}
      {action || secondary ? (
        <div className="gz-state__actions">
          {action ? (
            <Button variant={action.variant ?? (role === 'success' ? 'primary' : 'secondary')} iconStart={action.iconStart} loading={action.loading} onClick={action.onPress}>
              {action.label}
            </Button>
          ) : null}
          {secondary ? (
            <Button variant="tertiary" iconStart={secondary.iconStart} onClick={secondary.onPress}>
              {secondary.label}
            </Button>
          ) : null}
        </div>
      ) : null}
      {info ? (
        <InfoButton title={detailTitle ?? t('commonLabelDetails')} className="gz-state__info">
          {info}
        </InfoButton>
      ) : null}
    </section>
  )
}

export type SuccessStateProps = Omit<EmptyStateProps, 'tone' | 'kind' | 'artTone'>

/** A finished thing: request sent, voucher ready, booking confirmed, payment done, visit booked. One drawing, the outcome in at most four words, one gold action. */
export function SuccessState({ illustration = 'seal', ...rest }: SuccessStateProps) {
  return <EmptyState illustration={illustration} kind="success" {...rest} />
}

export type ErrorKind = 'generic' | 'load' | 'network' | 'no-access' | 'not-found' | 'payment'

type ErrorMeta = {
  title: 'commonStateTitleGeneric' | 'commonStateTitleLoad' | 'commonStateTitleNetwork' | 'commonStateTitleNoAccess' | 'commonStateTitleNotFound' | 'commonStateTitlePayment'
  detail: 'commonStateErrorGeneric' | 'commonStateErrorLoad' | 'commonStateErrorNetwork' | 'commonStateErrorNoAccess' | 'commonStateErrorNotFound' | 'commonStateErrorPayment'
  art: IllustrationName
  tone: IllustrationTone
  retry: boolean
}

const KIND: Record<ErrorKind, ErrorMeta> = {
  generic: { title: 'commonStateTitleGeneric', detail: 'commonStateErrorGeneric', art: 'warning', tone: 'danger', retry: true },
  load: { title: 'commonStateTitleLoad', detail: 'commonStateErrorLoad', art: 'warning', tone: 'danger', retry: true },
  network: { title: 'commonStateTitleNetwork', detail: 'commonStateErrorNetwork', art: 'wifi-off', tone: 'default', retry: true },
  'no-access': { title: 'commonStateTitleNoAccess', detail: 'commonStateErrorNoAccess', art: 'shield', tone: 'default', retry: false },
  'not-found': { title: 'commonStateTitleNotFound', detail: 'commonStateErrorNotFound', art: 'no-result', tone: 'default', retry: false },
  payment: { title: 'commonStateTitlePayment', detail: 'commonStateErrorPayment', art: 'card', tone: 'danger', retry: true },
}

export type ErrorStateProps = {
  kind?: ErrorKind
  /** Overrides the catalogue title (at most four words). */
  title?: ReactNode
  /** The recovery text: what happened, what was (not) changed. It lives behind the info glyph; overrides the catalogue sentence of the kind. */
  body?: ReactNode
  /** Sheet title of the recovery text (at most three words). Default: "Details". */
  detailTitle?: string
  /** Retry handler; a kind that cannot be retried (no access, not found) shows none unless given. */
  onRetry?: () => void
  retrying?: boolean
  secondary?: StateAction
  fill?: boolean
}

/** What went wrong in at most four words, one retry that is one tap, and the recovery text one tap further (info glyph). */
export function ErrorState({ kind = 'generic', title, body, detailTitle, onRetry, retrying, secondary, fill }: ErrorStateProps) {
  const t = useT('common')
  const meta = KIND[kind]
  const showRetry = meta.retry || onRetry
  return (
    <EmptyState
      tone="danger"
      kind="error"
      illustration={meta.art}
      artTone={meta.tone}
      title={title ?? t(meta.title)}
      detail={body ?? t(meta.detail)}
      detailTitle={detailTitle}
      action={showRetry ? { label: t('commonActionRetry'), onPress: onRetry, variant: 'secondary', iconStart: 'refresh', loading: retrying } : undefined}
      secondary={secondary}
      fill={fill}
    />
  )
}
