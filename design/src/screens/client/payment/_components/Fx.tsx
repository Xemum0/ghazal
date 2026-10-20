// Fx: a formatter string that mixes digits with words or a currency (`14 يناير`, `4:30 م`, `2.000 د.ك`, `Save KD 2,800`) as a fact value, in the
// reading direction. The figure roles (`gz-t-fig-*`) force an LTR isolate, right for a bare number and wrong for a date, a time or an Arabic
// amount: inside the isolate the day lands to the LEFT of the month and the currency to the RIGHT of the number, so the line reads backwards.
// Fx sets the language's direction back inside the role and keeps each digit run an LTR island (Figures). Flow-local twin of
// `client/bookings/_components/Fx.tsx`; both go when the system FactChip handles word values (filed in docs/engineering/requests.md).
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
