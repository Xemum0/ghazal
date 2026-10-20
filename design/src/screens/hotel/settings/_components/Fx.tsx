// Fx: a formatter string that mixes digits with words (`11 December`, `11 ديسمبر`, `9:00`) as a value, in the reading direction.
// The figure roles (`gz-t-fig-*`) force an LTR isolate, right for a bare number and wrong for a date: inside the isolate the Arabic month
// lands to the RIGHT of the day and the line reads backwards. Fx sets the language's direction back inside the role and keeps each digit run
// an LTR island (Figures). Flow-local twin of the planner's Fx; goes when the system FactChip handles word values (filed in requests.md).
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
