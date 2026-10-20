// Fx: a formatter string that mixes digits with words (`6 نوفمبر`, `أكتوبر 2026`, `6 November`) as a fact value, in the reading direction.
// The figure roles (`gz-t-fig-*`) force an LTR isolate, right for a bare number and wrong for a date: inside the isolate the Arabic day lands
// to the LEFT of the month and the year to the RIGHT of it, so the line reads backwards. Fx sets the language's direction back inside the role
// and keeps each digit run an LTR island (Figures). Flow-local twin of `client/payment/_components/Fx.tsx`; goes when the system FactChip
// handles word values (filed in docs/engineering/requests.md).
import { Figures } from '../../../../system'
import { useLang } from '../../../../shell/lang'

export function Fx({ text }: { text: string }) {
  const { isRtl } = useLang()
  return (
    <bdi dir={isRtl ? 'rtl' : 'ltr'}>
      <Figures text={text} />
    </bdi>
  )
}
