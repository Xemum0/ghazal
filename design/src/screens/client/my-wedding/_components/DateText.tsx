// DateText: a date or a time that carries a month or day word, safe inside a FactChip. The chip's value role (`gz-t-fig-*`) is an LTR
// island, which is right for a bare number and wrong for "15 نوفمبر" (the day must come first when read from the right). The wrapper
// takes its direction from the text itself (ADR 0014 D8), so Arabic reads day then month and English is unchanged. (A shared fix is
// requested in docs/engineering/requests.md; drop this wrapper when FactChip does it.)
import { Figures } from '../../../../system'

export function DateText({ text }: { text: string }) {
  return (
    <bdi dir="auto">
      <Figures text={text} />
    </bdi>
  )
}
