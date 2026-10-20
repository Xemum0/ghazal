// FactValue: the value of a FactChip when it holds words as well as digits (a date `14 يناير`, a clock `3:12 م`, a duration `2 س`).
// FactChip wraps its value in the figures role, which forces the whole value into one LTR island: right for a bare number, wrong for an
// Arabic month or unit, which then lands on the wrong side of its digits. This wrapper gives the value its own direction from its first
// strong letter (an Arabic month reads right to left, an English one left to right) and keeps every digit run an LTR island through
// `Figures`. Flow-local until FactChip does it itself (docs/engineering/requests.md, "flow:client-messages").
import { Figures } from '../../../../system'

export function FactValue({ text }: { text: string }) {
  return (
    <bdi dir="auto">
      <Figures text={text} />
    </bdi>
  )
}
