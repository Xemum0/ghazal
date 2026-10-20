// Language chip (top inline-end of the sign-in screen): shows the OTHER language in its own script and flips the whole screen in place.
// The URL is the source of truth for the language, so the screen re-renders in the new direction the moment it is tapped.
import { LANGUAGE_NATIVE_NAME } from '@gz/i18n'
import { Icon } from '../../../../system'
import { useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { usePrototype } from '../../../../shell/state'
import './access.css'

export function LangChip({ disabled = false }: { disabled?: boolean }) {
  const t = useT('hotel-access')
  const { lang } = useLang()
  const other = lang === 'ar' ? 'en' : 'ar'
  return (
    <button
      type="button"
      className="hxa-lang gz-reset gz-press gz-t-body-s"
      disabled={disabled}
      aria-label={`${t('hotelAccessLanguageSwitch')}: ${LANGUAGE_NATIVE_NAME[other]}`}
      onClick={() => usePrototype.getState().setLanguage(other)}
      lang={other}
    >
      <Icon name="translate" size="sm" />
      <span>{LANGUAGE_NATIVE_NAME[other]}</span>
    </button>
  )
}
