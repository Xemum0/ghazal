// Fx: a formatter string that mixes digits with words (`14 يناير`, `13 Nov 12:40 PM`, `23 س 40 د`) as a fact value, in the reading direction.
// The figure roles (`gz-t-fig-*`, `gz-t-kpi`) force an LTR isolate, which is right for a bare number and wrong for a date: in Arabic it puts
// the day to the LEFT of the month, so the line reads backwards. Fx sets the direction of the language back inside the role and keeps each
// digit run an LTR island (Figures). A system fix (FactChip, IconStat) is requested in docs/engineering/requests.md; until then flow
// screens wrap such values here.
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
