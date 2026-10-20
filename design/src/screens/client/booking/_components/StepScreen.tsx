// StepScreen: the scaffold every step of the request flow draws itself in, so the five steps feel like one place.
// Pinned top: the TopBar (venue name, back or close) and the progress thread as IconProgress (ADR 0034): a glyph per step on one gold
// thread, no words (the step is the glyph; "Step 2 of 5" is its accessible name). The body opens with the step's serif title, at most
// two words, and an optional info glyph for the one paragraph a step may keep. The pinned bottom is the ActionBar with the one gold action.
// Back is always safe: the draft autosaves in the prototype store, and step 1 asks before leaving.
import { useEffect, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { useT, useFormat } from '../../../../i18n'
import { ActionBar, IconProgress, Screen, TopBar, useNav, type ActionBarProps, type IconProgressStep } from '../../../../system'
import { STEP_COUNT, useFlowStore } from './flow'
import './step.css'

const STEP_ICONS: readonly IconName[] = ['calendar', 'package', 'sparkle', 'user', 'checklist']

export type StepScreenProps = {
  step: 1 | 2 | 3 | 4 | 5
  venueName: string
  title: ReactNode
  /** The info glyph beside the title (an InfoButton): where the step's one paragraph lives. */
  info?: ReactNode
  /** State line under the progress thread (offline, price error, a taken date). */
  notice?: ReactNode
  children: ReactNode
  /** The pinned action. `null` when the screen is one state composition that carries its own single action (the load error). */
  bar: ActionBarProps | null
}

export function StepScreen({ step, venueName, title, info, notice, children, bar }: StepScreenProps) {
  const t = useT('client-booking')
  const tc = useT('common')
  const f = useFormat()
  const nav = useNav()

  useEffect(() => {
    const store = useFlowStore.getState()
    store.set({ entered: { ...store.entered, [step]: true } })
    return () => {
      const s = useFlowStore.getState()
      s.set({ entered: { ...s.entered, [step]: false } })
    }
  }, [step])

  const leave = async () => {
    const answer = await nav.openDialog({
      title: t('clientBookingLeaveTitle'),
      body: t('clientBookingLeaveBody'),
      icon: 'bookmark',
      confirmLabel: t('clientBookingLeaveConfirm'),
      cancelLabel: t('clientBookingLeaveKeep'),
    })
    if (answer === 'confirm') nav.pop()
  }

  const names = [t('clientBookingEventTitle'), t('clientBookingPackageTitle'), t('clientBookingExtrasTitle'), t('clientBookingDetailsTitle'), t('clientBookingReviewTitle')]
  const steps: IconProgressStep[] = STEP_ICONS.map((icon, i) => ({
    key: `step${i + 1}`,
    icon,
    label: names[i]!,
    state: i + 1 < step ? 'tied' : i + 1 === step ? 'now' : 'open',
  }))

  return (
    <Screen
      top={
        <>
          <TopBar
            title={<bdi dir="auto">{venueName}</bdi>}
            back={step === 1 ? 'close' : 'auto'}
            onBack={step === 1 ? leave : undefined}
            backLabel={step === 1 ? tc('commonActionClose') : undefined}
            rule={false}
          />
          <div className="bk-progress" data-gz="StepProgress">
            <IconProgress
              steps={steps}
              label={t('clientBookingStepsLabel')}
              describe={t('clientBookingStepOf', { step: f.integer(step), total: f.integer(STEP_COUNT) })}
              labels="none"
              draw="mount"
            />
          </div>
        </>
      }
      bottom={bar ? <ActionBar {...bar} /> : undefined}
      bodyClassName="bk-body"
    >
      {notice}
      <header className="bk-head">
        <h2 className="bk-head__title gz-t-d3">{title}</h2>
        {info}
      </header>
      {children}
    </Screen>
  )
}
