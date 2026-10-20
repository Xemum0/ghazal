// StepBar (flow-local): the bar of the profile steps CL-ONBD-03 to 06. Back at inline-start, the 2 px thread in the middle showing
// the step, the info glyph (what happens to the answers: optional, kept on the device, editable in Profile; CA-ONB-08, CA-ONB-09, the
// one paragraph this flow keeps, behind the glyph per docs/design/02-text-diet.md section 6) and a text `Skip` at inline-end. The
// system TopBar has no text action slot (requests.md), so this repeats its geometry: safe-top inset, a 56 row, the glyph edge of
// Back and the text edge of Skip on the 20 gutter.
import { flat } from '@gz/tokens'
import { BarButton, Button, InfoButton, useNav } from '../../../../system'
import { useT } from '../../../../i18n'
import { ThreadProgress } from './ThreadProgress'
import './stepbar.css'

export type StepBarProps = {
  /** 1-based step (3 intro-less profile steps start at 1). */
  step: number
  total: number
  onSkip?: () => void
  /** Hide Back (never on these screens, kept for the gallery). */
  back?: boolean
}

const GUTTER = flat['space.gutter']
const START_PAD = GUTTER - (flat['size.touch-min'] - flat['size.icon.md']) / 2
const END_PAD = GUTTER - flat['space.2']

export function StepBar({ step, total, onSkip, back = true }: StepBarProps) {
  const nav = useNav()
  const t = useT('common')
  const o = useT('client-onboarding')
  return (
    <header
      className="obd-stepbar"
      data-gz-id="onboarding.stepbar"
      style={{ paddingInlineStart: START_PAD, paddingInlineEnd: END_PAD }}
    >
      <div className="obd-stepbar__row">
        <div className="obd-stepbar__start">
          {back ? <BarButton icon="back" label={t('commonActionBack')} onPress={() => nav.pop()} dataId="bar.back" /> : null}
        </div>
        <div className="obd-stepbar__thread">
          <ThreadProgress count={total} index={step - 1} label={o('clientOnboardingStepProgress', { current: step, total })} />
        </div>
        <div className="obd-stepbar__end">
          <InfoButton title={o('clientOnboardingInfoTitle')}>{o('clientOnboardingInfoBody')}</InfoButton>
          <Button variant="tertiary" onClick={onSkip}>
            {t('commonActionSkip')}
          </Button>
        </div>
      </div>
    </header>
  )
}
