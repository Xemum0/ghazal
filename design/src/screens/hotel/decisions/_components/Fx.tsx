// Fx: a formatter string that mixes digits with words (`14 Jan`, `4:00 PM`, `14 يناير`, `4:00 م`) as a fact value, in the reading direction.
// The figure roles (`gz-t-fig-*`) force an LTR isolate, which is right for a bare number and wrong for a date or a clock with its marker:
// in Arabic it puts the day to the left of the month. Fx sets the direction of the language back and keeps each digit run an LTR island.
// FactChip takes a node as its value, so this flow wraps such values here until the system does it (docs/engineering/requests.md).
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
