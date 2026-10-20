// System chrome: the iOS status bar (47) and the home indicator. Drawn, not photographed: time, signal, wifi, battery
// are SVG on a fixed viewBox in currentColor, so the two tones are one colour switch. Direction: the status bar is LTR in
// both languages (direction section 2.5: "47, 15/20 Cairo 600, LTR"); the OS draws it from the system locale, not the app's.
import type { ChromeTone } from './context'
import './statusbar.css'

type Props = { tone: ChromeTone; time: string }

export function StatusBar({ tone, time }: Props) {
  return (
    <div className="gz-statusbar" data-gz="StatusBar" data-tone={tone} aria-hidden="true">
      <div className="gz-statusbar__zone gz-statusbar__zone--time">
        <span className="gz-statusbar__time gz-t-statusbar">{time}</span>
      </div>
      <div className="gz-statusbar__notch-gap" />
      <div className="gz-statusbar__zone gz-statusbar__zone--icons">
        <svg className="gz-statusbar__signal" viewBox="0 0 18 12" width="18" height="12" fill="currentColor">
          <rect x="0" y="8" width="3" height="4" rx="1" />
          <rect x="5" y="5.5" width="3" height="6.5" rx="1" />
          <rect x="10" y="3" width="3" height="9" rx="1" />
          <rect x="15" y="0" width="3" height="12" rx="1" />
        </svg>
        <svg className="gz-statusbar__wifi" viewBox="0 0 17 12" width="17" height="12" fill="currentColor">
          <path d="M1.71 4.21A9.6 9.6 0 0 1 15.29 4.21" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" />
          <path d="M3.97 6.47A6.4 6.4 0 0 1 13.03 6.47" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" />
          <path d="M8.5 11 6.24 8.74A3.2 3.2 0 0 1 10.76 8.74Z" />
        </svg>
        <svg className="gz-statusbar__battery" viewBox="0 0 27 13" width="27" height="13" fill="currentColor">
          <rect x="0.5" y="0.5" width="22" height="12" rx="3.5" fill="none" stroke="currentColor" opacity="0.4" />
          <rect x="2" y="2" width="19" height="9" rx="2" />
          <path d="M24 4.5v4a2.2 2.2 0 0 0 1.5-2.1v0A2.2 2.2 0 0 0 24 4.5Z" opacity="0.5" />
        </svg>
      </div>
    </div>
  )
}

export function HomeIndicator({ tone }: { tone: ChromeTone }) {
  return (
    <div className="gz-homebar" data-gz="HomeIndicator" data-tone={tone} aria-hidden="true">
      <span className="gz-homebar__pill" />
    </div>
  )
}
