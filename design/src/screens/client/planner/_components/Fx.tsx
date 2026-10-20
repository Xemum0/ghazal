// Fx: a formatter string that mixes digits with words (`14 Jan`, `14 يناير`, `7:30 PM`, `7:30 م`, `63 d`, `63 ي`) as a fact value, in the reading direction.
// The figure roles (`gz-t-fig-*`) force an LTR isolate, right for a bare number and wrong for a date or a clock with its marker: inside the
// isolate the Arabic month lands to the RIGHT of the day, so the line reads backwards. Fx sets the language's direction back inside the role
// and keeps each digit run an LTR island (Figures). Flow-local twin of `client/reviews-rewards/_components/Fx.tsx`; goes when the system
// FactChip handles word values (filed in docs/engineering/requests.md by several flows).
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
