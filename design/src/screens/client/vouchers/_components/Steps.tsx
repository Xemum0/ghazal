// Steps: how the voucher works as three knots on the thread (ADR 0034: icon knots instead of three paragraphs). Pay the KD 2 to Ghazal now
// (the knot you are about to tie), send the request at the voucher price, pay the venue directly (off-app). Each knot is a glyph and one or two
// words; nothing is recorded yet, so only the first knot is "now". The sentences (windows, off-app payment) are in the terms behind (i).
import { IconProgress } from '../../../../system'
import { useVc } from './useVc'

export function Steps({ fee, provider }: { fee: string; provider?: boolean }) {
  const { t, f } = useVc()
  return (
    <IconProgress
      label={t('clientVouchersStepsLabel')}
      describe={f.list([t('clientVouchersPayFee', { fee }), t('clientVouchersStepRequest'), t('clientVouchersStepDirect')])}
      labels="all"
      draw={false}
      steps={[
        { key: 'pay', icon: 'card', label: fee, state: 'now' },
        { key: 'request', icon: 'send', label: t('clientVouchersStepRequest'), state: 'open' },
        { key: 'direct', icon: provider ? 'receipt' : 'hall', label: t('clientVouchersStepDirect'), state: 'open' },
      ]}
    />
  )
}
