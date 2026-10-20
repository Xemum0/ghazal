// VoucherCard (CL-VCHR, CL-BKNG, the confirmation hero): the KD 2 voucher as a ticket. Ink hairline card, a perforation with two notches,
// the QR on the canvas, the code as an LTR isolate in the figures voice, the venue or provider it is bound to, the bound quote
// (standard struck through, voucher price) and the state chip. No gold fill (a voucher is a fact, the primary action lives on the screen).
// ADR 0034 (text diet): the card speaks in glyphs and figures. The eyebrow word, the price captions, the code label and the hint sentences are
// gone: a ticket glyph names the voucher, a ticket and a tag glyph name the two prices (the words stay as accessible names), the facts are
// `[calendar] 14 Jan` and `[users] 350`, the state is the StatusPill word, and the date a voucher was used is a fact.
//
// variants   full     header, target, bound quote, perforation, QR + code + validity (voucher detail, booking detail)
//            compact  one row for the wallet list: target, code, state chip, validity (no QR)
//            slim     the voucher shown on the booking it belongs to (booking confirmed, booking detail): the venue, package, date, guests and
//                     both prices are already on that screen, so the card is the QR, the code and its validity, then Copy and Full screen;
//                     a state chip only when the voucher is no longer live (used, expired)
// Credit voucher (kind `credit`): the same ticket with a gift glyph, the "any hall, hotel or service" mark instead of a venue, no quote.
// The QR is drawn from `voucher.qr.payload`; a used, expired, forfeited or credit-issued voucher keeps its code but its QR is muted (the state chip says why).
import type { CreditVoucher, Voucher, WalletVoucher } from '@gz/contracts'
import { getPackage, getProvider, getVenue, meta } from '../../mock'
import { useFormat, useT } from '../../i18n'
import { Button, FactChip, FactRow, Icon, Money, StatusPill, type VoucherState } from '../core'
import { cx } from '../core/cx'
import { Figures, useBi } from '../domain-client/bits'
import { defineWords, p } from '../domain-client/copy'
import { QrCode } from './QrCode'
import './voucher-card.css'

const useW = defineWords({
  eyebrow: p('Voucher', 'كوبون'),
  code: p('Code', 'الرمز'),
  qrLabel: p('QR code of voucher {code}', 'رمز QR للكوبون {code}'),
  copy: p('Copy', 'نسخ'),
  full: p('Full screen', 'ملء الشاشة'),
  standard: p('Standard price', 'السعر العادي'),
  voucherPrice: p('Voucher price', 'سعر الكوبون'),
  date: p('Event date', 'تاريخ المناسبة'),
  guests: p('Guests', 'الضيوف'),
  package: p('Package', 'الباقة'),
  validUntil: p('Valid until', 'صالح حتى'),
  usedOn: p('Redeemed on', 'استُخدم في'),
})

export type VoucherCardProps = {
  /** A bound voucher (venue or provider) or a credit voucher granted by support (unbound, any venue or service). */
  voucher: WalletVoucher
  variant?: 'full' | 'compact' | 'slim'
  /** Opens the voucher (the compact row is one 44+ target; the full card has its own buttons). */
  onOpen?: () => void
  onCopy?: () => void
  /** The full-screen QR view (brightness raised by the screen). Omit to hide the button. */
  onShowFull?: () => void
  className?: string
}

/** The venue or provider a voucher is bound to, from the fixtures (display name and where it happens). */
export function useVoucherTarget(v: Voucher): { name: string; sub: string | null } {
  const bi = useBi()
  if (v.targetType === 'provider') {
    const provider = getProvider(v.venueOrProviderId)
    return { name: provider ? bi(provider.name) : '', sub: null }
  }
  const venue = getVenue(v.venueOrProviderId)
  return { name: venue ? bi(venue.name) : '', sub: null }
}

export function VoucherCard(props: VoucherCardProps) {
  const { voucher, ...rest } = props
  return voucher.kind === 'credit' ? <CreditVoucherCard voucher={voucher} {...rest} /> : <BoundVoucherCard voucher={voucher} {...rest} />
}

/** The "any venue" mark of an unbound credit voucher: a globe and the short phrase, a quiet rose chip. Informative only. */
export function AnyVenueMark({ className }: { className?: string }) {
  const t = useT('common')
  return (
    <span data-gz="AnyVenueMark" className={cx('gz-vch__any gz-t-pill', className)}>
      <Icon name="globe" size="xs" />
      <span>{t('commonVoucherAnyVenue')}</span>
    </span>
  )
}

/** The chip state of a credit voucher: ready credit has its own rose pill; used and expired share the bound words. */
const creditState = (v: CreditVoucher): VoucherState => (v.status === 'active' ? 'voucher_credit' : (`voucher_${v.status}` as VoucherState))

/**
 * Credit voucher (ADR 0035 D5): the same ticket without a venue, a quote or an event date. The target line is the credit title with the
 * unbound mark (globe, "Any hall, hotel or service"); the QR, the code and the 60-day validity sit on the stub. Granted by support, never paid.
 */
function CreditVoucherCard({ voucher: v, variant = 'full', onOpen, onCopy, onShowFull, className }: Omit<VoucherCardProps, 'voucher'> & { voucher: CreditVoucher }) {
  const f = useFormat()
  const w = useW()
  const t = useT('common')
  const live = v.status === 'active'
  const state = creditState(v)
  const validUntil = v.validUntil ? f.date(v.validUntil.slice(0, 10), 'compact') : null
  const usedOn = v.status === 'used' && v.usedAt ? f.date(v.usedAt.slice(0, 10), 'compact') : null
  const validity =
    usedOn || validUntil ? (
      <FactRow>
        <FactChip icon={usedOn ? 'check-double' : 'calendar'} label={usedOn ? w('usedOn') : w('validUntil')} value={usedOn ?? validUntil} size="sm" tone="muted" />
      </FactRow>
    ) : null
  const title = t('commonVoucherCredit')
  if (variant === 'compact') {
    const body = (
      <>
        <span className="gz-vch__icon" aria-hidden="true">
          <Icon name="gift" size="md" />
        </span>
        <span className="gz-vch__row-text">
          <span className="gz-vch__name gz-t-title" dir="auto">
            {title}
          </span>
          <AnyVenueMark />
          <span className="gz-vch__code gz-t-fig-caption">
            <bdi dir="ltr">{v.code}</bdi>
          </span>
          {validity}
        </span>
        <StatusPill status={state} />
      </>
    )
    return (
      <div data-gz="VoucherCard" data-variant="compact" data-kind="credit" data-status={v.status} className={cx('gz-vch gz-vch--compact', className)}>
        {onOpen ? (
          <button type="button" className="gz-reset gz-vch__row gz-press" onClick={onOpen}>
            {body}
          </button>
        ) : (
          <div className="gz-vch__row">{body}</div>
        )}
      </div>
    )
  }
  const qrSize = variant === 'slim' ? 128 : 144
  return (
    <article data-gz="VoucherCard" data-variant={variant} data-kind="credit" data-status={v.status} className={cx('gz-vch', className)} aria-label={`${title} ${v.code}`}>
      <div className="gz-vch__top">
        <header className="gz-vch__head">
          <span className="gz-vch__eyebrow">
            <Icon name="gift" size="md" tone="secondary" />
            <span className="gz-sr-only">{title}</span>
          </span>
          <StatusPill status={state} />
        </header>
        <div className="gz-vch__who">
          <h3 className="gz-vch__target gz-t-d1" dir="auto">
            {title}
          </h3>
          <AnyVenueMark />
        </div>
      </div>
      <div className="gz-vch__perf" aria-hidden="true">
        <span className="gz-vch__cap" />
        <span className="gz-vch__dash" />
        <span className="gz-vch__cap" />
      </div>
      <div className="gz-vch__bottom">
        <div className="gz-vch__stub">
          <span className="gz-vch__qr">
            <QrCode payload={v.qr.payload} label={w('qrLabel', { code: v.code })} size={qrSize} muted={!live} />
          </span>
          <span className="gz-vch__codeblock">
            <span className="gz-vch__code-value gz-t-fig-title" data-gz-id="code">
              <span className="gz-sr-only">{w('code')}</span>
              <bdi dir="ltr">{v.code}</bdi>
            </span>
            {validity}
          </span>
        </div>
        {onCopy || onShowFull ? (
          <footer className="gz-vch__actions">
            {onCopy ? (
              <Button variant="secondary" iconStart="copy" onClick={onCopy}>
                {w('copy')}
              </Button>
            ) : null}
            {onShowFull && live ? (
              <Button variant="secondary" iconStart="qr-code" onClick={onShowFull}>
                {w('full')}
              </Button>
            ) : null}
          </footer>
        ) : null}
      </div>
    </article>
  )
}

function BoundVoucherCard({ voucher: v, variant = 'full', onOpen, onCopy, onShowFull, className }: Omit<VoucherCardProps, 'voucher'> & { voucher: Voucher }) {
  const f = useFormat()
  const w = useW()
  const t = useT('common')
  const bi = useBi()
  const target = useVoucherTarget(v)
  const live = v.status === 'bound' || v.status === 'active'
  const pkg = getPackage(v.packageId)
  const state = (v.status === 'credit_issued' ? 'voucher_credit_issued' : `voucher_${v.status}`) as VoucherState
  // `compact` (no weekday) keeps the wallet row and the stub inside a 320 px column in both scripts.
  const validUntil = v.validUntil ? f.date(v.validUntil.slice(0, 10), 'compact') : null
  const usedOn = v.status === 'used' && v.usedAt ? f.date(v.usedAt.slice(0, 10), 'compact') : null
  const quote = (
    <dl className="gz-vch__quote" data-gz-id="quote">
      <div className="gz-vch__q">
        <dt className="gz-vch__qicon">
          <Icon name="offer" size="xs" tone="secondary" />
          <span className="gz-sr-only">{w('standard')}</span>
        </dt>
        <dd>
          <Money fils={v.quoteFils.standard} inline className="gz-t-fig-body-s gz-strike" />
        </dd>
      </div>
      <div className="gz-vch__q gz-vch__q--voucher">
        <dt className="gz-vch__qicon">
          <Icon name="ticket" size="sm" tone="success" />
          <span className="gz-sr-only">{w('voucherPrice')}</span>
        </dt>
        <dd>
          <Money fils={v.quoteFils.voucher} amountClass="gz-t-price-strong" />
        </dd>
      </div>
    </dl>
  )

  if (variant === 'compact') {
    const body = (
      <>
        <span className="gz-vch__icon" aria-hidden="true">
          <Icon name="ticket" size="md" />
        </span>
        <span className="gz-vch__row-text">
          <span className="gz-vch__name gz-t-title" dir="auto">
            {target.name}
          </span>
          <span className="gz-vch__code gz-t-fig-caption">
            <bdi dir="ltr">{v.code}</bdi>
          </span>
          {usedOn || validUntil ? (
            <FactRow className="gz-vch__facts-row">
              <FactChip icon={usedOn ? 'check-double' : 'calendar'} label={usedOn ? w('usedOn') : w('validUntil')} value={usedOn ?? validUntil} size="sm" tone="muted" />
            </FactRow>
          ) : null}
        </span>
        <StatusPill status={state} />
      </>
    )
    return (
      <div data-gz="VoucherCard" data-variant="compact" data-status={v.status} className={cx('gz-vch gz-vch--compact', className)}>
        {onOpen ? (
          <button type="button" className="gz-reset gz-vch__row gz-press" onClick={onOpen}>
            {body}
          </button>
        ) : (
          <div className="gz-vch__row">{body}</div>
        )}
      </div>
    )
  }

  const validity =
    usedOn || validUntil ? (
      <FactRow>
        <FactChip icon={usedOn ? 'check-double' : 'calendar'} label={usedOn ? w('usedOn') : w('validUntil')} value={usedOn ?? validUntil} size="sm" tone="muted" />
      </FactRow>
    ) : null
  const notValid =
    v.status === 'forfeited' ? (
      <span className="gz-vch__hint gz-t-caption" data-gz-id="not-valid">
        <Icon name="x-circle" size="xs" tone="danger" /> {t('commonVoucherNotValidNote', { hours: meta.config.confirmWindowHours })}
      </span>
    ) : null
  const actions =
    onCopy || onShowFull ? (
      <footer className="gz-vch__actions">
        {onCopy ? (
          <Button variant="secondary" iconStart="copy" onClick={onCopy}>
            {w('copy')}
          </Button>
        ) : null}
        {onShowFull && live ? (
          <Button variant="secondary" iconStart="qr-code" onClick={onShowFull}>
            {w('full')}
          </Button>
        ) : null}
      </footer>
    ) : null

  if (variant === 'slim') {
    return (
      <article data-gz="VoucherCard" data-variant="slim" data-status={v.status} className={cx('gz-vch gz-vch--slim', className)} aria-label={`${w('eyebrow')} ${v.code}, ${target.name}`}>
        <div className="gz-vch__stub gz-vch__stub--slim">
          <span className="gz-vch__qr">
            <QrCode payload={v.qr.payload} label={w('qrLabel', { code: v.code })} size={128} muted={!live} />
          </span>
          <span className="gz-vch__codeblock">
            {live ? null : <StatusPill status={state} />}
            <span className="gz-vch__code-value gz-t-fig-title" data-gz-id="code">
              <span className="gz-sr-only">{w('code')}</span>
              <bdi dir="ltr">{v.code}</bdi>
            </span>
            {validity}
            {notValid}
          </span>
        </div>
        {actions}
      </article>
    )
  }

  return (
    <article data-gz="VoucherCard" data-variant="full" data-status={v.status} className={cx('gz-vch', className)} aria-label={`${w('eyebrow')} ${v.code}`}>
      <div className="gz-vch__top">
        <header className="gz-vch__head">
          <span className="gz-vch__eyebrow">
            <Icon name="ticket" size="md" tone="secondary" />
            <span className="gz-sr-only">{w('eyebrow')}</span>
          </span>
          <StatusPill status={state} />
        </header>
        <div className="gz-vch__who">
          <h3 className="gz-vch__target gz-t-d1" dir="auto">
            {target.name}
          </h3>
          <FactRow className="gz-vch__facts">
            {pkg ? <FactChip icon="package" label={w('package')} value={bi(pkg.name)} size="sm" tone="muted" /> : null}
            <FactChip icon="calendar" label={w('date')} value={f.date(v.eventDate, 'short')} size="sm" tone="muted" />
            {v.guests ? <FactChip icon="users-three" label={w('guests')} value={f.integer(v.guests)} size="sm" tone="muted" /> : null}
          </FactRow>
        </div>
        {quote}
      </div>
      <div className="gz-vch__perf" aria-hidden="true">
        <span className="gz-vch__cap" />
        <span className="gz-vch__dash" />
        <span className="gz-vch__cap" />
      </div>
      <div className="gz-vch__bottom">
        <div className="gz-vch__stub">
          <span className="gz-vch__qr">
            <QrCode payload={v.qr.payload} label={w('qrLabel', { code: v.code })} size={144} muted={!live} />
          </span>
          <span className="gz-vch__codeblock">
            <span className="gz-vch__code-value gz-t-fig-title" data-gz-id="code">
              <span className="gz-sr-only">{w('code')}</span>
              <bdi dir="ltr">{v.code}</bdi>
            </span>
            {validity}
            {notValid}
          </span>
        </div>
        {actions}
      </div>
    </article>
  )
}

export type VoucherChipProps = {
  /** The voucher code; only its last four characters show (`…K7QM`). */
  code: string
  /** `ready` (green), `bound` (gold tint: attached to a live request), `quiet` (used, expired). */
  tone?: 'ready' | 'bound' | 'quiet'
  className?: string
}

/** The small ticket chip beside a request or a price: a ticket glyph and the last four characters (`K7QM`), the word is its accessible name. Informative only (never a button, never gold fill). */
export function VoucherChip({ code, tone = 'bound', className }: VoucherChipProps) {
  const w = useW()
  const last4 = code.slice(-4)
  return (
    <span data-gz="VoucherChip" data-tone={tone} className={cx('gz-vchip gz-t-pill', `gz-vchip--${tone}`, className)}>
      <Icon name="ticket" size="xs" />
      <span className="gz-sr-only">{w('eyebrow')}</span>
      <span className="gz-vchip__code gz-t-fig-caption">
        <bdi dir="ltr">{last4}</bdi>
      </span>
    </span>
  )
}
