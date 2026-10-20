// useSheetFill: the height a full-height sheet screen (Filters, Brief) gives its own column, so the header and the footer stay put and only
// the middle scrolls. The Sheet is at most 90% of the frame (snapped to the 4-pt grid); inside it sit the top padding (12), the grab zone (20),
// the body's bottom padding (24) and the home-indicator inset. The screen's root takes what is left. Flutter: DraggableScrollableSheet with a
// Column(Expanded(ListView)) between a pinned header and footer.
import { flat } from '@gz/tokens'
import { useDevice } from '../../../../shell/device/context'

export function useSheetFill(share = 0.9): number {
  const { height, safeBottom } = useDevice()
  const max = Math.floor((height * share) / flat['space.1']) * flat['space.1']
  return max - (flat['space.3'] + flat['space.5'] + flat['space.6'] + safeBottom)
}
