// PromptSheet: the notification pre-prompt (CA-NOTI-07). A bell drawn once, the title, two actions: what the couple gets (and the promise
// never to write late at night) is the paragraph behind the info glyph. It is shown after the first booking request, never at launch.
// `Turn on` is the one gold action; it opens the system permission dialog (simulated here with the navigator's dialog), and `Not now`
// leaves the choice for later. The answer is kept in the Messages flow's memory and drives the denied banner.
import { Button, Illustration, InfoButton, useNav } from '../../../../system'
import { MsgSheetHead as SheetHead } from './MsgSheetHead'
import { useMsgStore } from './store'
import { useMsg } from './useMsg'
import './prompt-sheet.css'

export function PromptSheet({ inert = false }: { inert?: boolean }) {
  const nav = useNav()
  const { t } = useMsg()
  const close = () => nav.closeSheet()

  const turnOn = async () => {
    if (inert) return
    const answer = await nav.openDialog({
      title: t('clientMessagesOsTitle'),
      body: t('clientMessagesOsBody'),
      icon: 'bell',
      confirmLabel: t('clientMessagesOsAllow'),
      cancelLabel: t('clientMessagesOsDeny'),
    })
    useMsgStore.getState().setPermission(answer === 'confirm' ? 'granted' : 'denied')
    nav.closeSheet()
    if (answer === 'confirm') nav.toast({ message: t('clientMessagesPromptOnToast'), tone: 'success' })
  }

  return (
    <div className="gzm-prompt" data-gz="NotificationPrePrompt">
      <SheetHead
        title={t('clientMessagesPromptTitle')}
        onClose={close}
        info={
          <InfoButton title={t('clientMessagesPromptTitle')}>
            <p>{t('clientMessagesPromptBody')}</p>
            <p>{t('clientMessagesPromptNote')}</p>
          </InfoButton>
        }
      />
      <span className="gzm-prompt__art">
        <Illustration name="bell" size="lg" />
      </span>
      <div className="gzm-prompt__actions">
        <Button variant="primary" fullWidth onClick={turnOn}>
          {t('clientMessagesPromptOn')}
        </Button>
        <Button variant="tertiary" onClick={close}>
          {t('clientMessagesPromptLater')}
        </Button>
      </div>
    </div>
  )
}
