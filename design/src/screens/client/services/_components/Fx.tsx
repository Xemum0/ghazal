// Fx: a formatter string that mixes digits with words (`2 h`, `2 س`, an area name) as a FactChip value, in the reading direction.
// The chip draws its value in a figure role (`gz-t-fig-*`: LTR isolate), right for a bare number and wrong for a duration or a name in
// Arabic (the unit would sit before the number). Fx sets the direction of the language back inside the role and keeps each digit run an
// LTR island (Figures). Flow-local twin of the one in client/bookings until the system FactChip handles word values (requests.md).
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
