// The `?state=` of the frame a screen is drawn in (loading | offline | selected ...), or undefined in the live player and in the
// default frame. Reads the frame context directly so the same screen also renders outside a frame route without throwing.
import { useContext } from 'react'
import { useNav } from '../../../../system'
import { INERT_NAV } from '../../../../system/nav'
import { FrameContext } from '../../../../shell/frame'

export const useScreenState = (): string | undefined => useContext(FrameContext)?.state

/** True in a canvas / `#/frame` frame (no navigator provider: the nav operations are the inert ones), false in the live player and the launcher.
 *  Frames show the demo persona's answers so the story is visible at a glance; the player starts from what the visitor has
 *  really answered. */
export const useInStaticFrame = (): boolean => useNav().push === INERT_NAV.push
