// Mixed (flow-local): a fact value that holds digits and Arabic words (`2 س`, `9:00 م – 2:00 ص`, `2:00 ص`). The FactChip value role forces an
// LTR isolate, in which a value that starts with a number puts the number on the far left and the Arabic unit after it, so the Arabic
// reads backwards (unit before number). A nested RTL isolate restores the Arabic reading order; the digits stay LTR islands (Figures).
// In English it is a plain LTR run. Filed for the system FactChip in docs/engineering/requests.md (flow-client-messages, client-saved-compare).
import { useLang } from '../../../../shell/lang'
import { Figures } from '../../../../system'

export function Mixed({ text }: { text: string }) {
  const { lang } = useLang()
  return (
    <bdi dir={lang === 'ar' ? 'rtl' : 'ltr'}>
      <Figures text={text} />
    </bdi>
  )
}
