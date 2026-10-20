// The figures voice inside running text and the bilingual picker, shared by every domain (was copied into the client, hotel and inputs groups).
import { Fragment, type ReactNode } from 'react'
import { plainText } from '@gz/i18n'
import type { Bilingual } from '@gz/contracts'
import { useLang } from '../../shell/lang'

/** The current language's side of a bilingual fixture value. */
export function useBi() {
  const { lang } = useLang()
  return (b: Bilingual | null | undefined): string => (b ? b[lang] : '')
}

/**
 * The figures voice inside running text (direction 2.4): every number inside a Poppins or Cairo line becomes a Cairo tabular LTR
 * island (`.gz-num`), sized by the surrounding role. The string comes from the shared formatter; this only wraps its digit runs
 * (`9:00`, `14`, `2027`, `1,500`) and strips the formatter's invisible isolates so the wrapper is the only isolate.
 * One inline span around the run: inside a flex row the pieces stay ONE item, so the row's gap never opens between digits and words.
 */
export function Figures({ text }: { text: string }): ReactNode {
  // A sign directly before the digits and a percent or plus sign directly after (`35,000+`) belong to the number: `−15%` is one LTR island,
  // so in Arabic the minus never lands on the far side and the percent sign never flips to the left of the digits (direction 6).
  const parts = plainText(text).split(/([−+]?(?:\d[\d:.,]*\d|\d)[%٪+]?)/)
  return (
    <span>
      {parts.map((part, i) =>
        i % 2 === 1 ? (
          <bdi key={i} dir="ltr" className="gz-num">
            {part}
          </bdi>
        ) : (
          <Fragment key={i}>{part}</Fragment>
        ),
      )}
    </span>
  )
}

/** A number from the formatter as a standalone figure run (an LTR island in the figures face). */
export function Fig({ children }: { children: ReactNode }) {
  return (
    <bdi dir="ltr" className="gz-num">
      {children}
    </bdi>
  )
}
