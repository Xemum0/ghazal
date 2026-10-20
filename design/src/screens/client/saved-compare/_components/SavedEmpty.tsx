// The empty Saved segments (CL-SAVD-01 empty-venues, empty-services, empty-packages): one drawing, a title of three words and the single way
// out (ADR 0034). The shelf with the heart says "nothing kept yet" for halls; a bouquet and an invitation say it for services and packages.
// The old plate, sentence and tap-the-heart instruction are gone: the heart is on every card the family will meet next.
import { useT } from '../../../../i18n'
import { EmptyState } from '../../../../system'

export type EmptyKind = 'venues' | 'services' | 'packages'

export type SavedEmptyProps = {
  kind: EmptyKind
  onAction: () => void
}

export function SavedEmpty({ kind, onAction }: SavedEmptyProps) {
  const t = useT('client-saved-compare')
  const copy = {
    venues: { art: 'empty-saved', title: t('clientSavedCompareSavedEmptyVenuesTitle'), action: t('clientSavedCompareSavedEmptyVenuesAction') },
    services: { art: 'bouquet', title: t('clientSavedCompareSavedEmptyServicesTitle'), action: t('clientSavedCompareSavedEmptyServicesAction') },
    packages: { art: 'invitation', title: t('clientSavedCompareSavedEmptyPackagesTitle'), action: t('clientSavedCompareSavedEmptyPackagesAction') },
  } as const
  const { art, title, action } = copy[kind]
  return <EmptyState illustration={art} title={title} action={{ label: action, variant: 'primary', onPress: onAction }} fill={false} size="hero" />
}
