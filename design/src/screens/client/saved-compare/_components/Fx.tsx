// Fx: a formatter string that mixes digits with words (`14 يناير`, `4:00 م`, `18 دقيقة`) as a fact value, in the reading direction.
// The FactChip value role (`gz-t-fig-*`) is an LTR isolate, right for a bare figure (350, 4.8) and wrong for a date or a duration: in Arabic it
// puts the day to the LEFT of the month and the unit before the number, so the line reads backwards. Fx sets the direction of the language
// back inside the role and keeps each digit run an LTR island (Figures). The same twin lives in the bookings and discover flows; the system
// fix is requested in docs/engineering/requests.md and this file goes when FactChip handles word values.
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
