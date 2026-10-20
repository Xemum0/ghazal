// ToolButton: the Studio's 44 x 44 icon button. A toggle (aria-pressed) fills ink-700 with a canvas glyph, like a selected segment;
// a plain action is an ink glyph that takes the ink-50 tone on press. The label is the accessible name and the tooltip.
import type { ButtonHTMLAttributes, ReactNode, Ref } from 'react'

export type ToolButtonProps = Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'children' | 'aria-label' | 'aria-pressed'> & {
  label: string
  /** Toggle state; leave undefined for a plain action. */
  pressed?: boolean
  /** Show the label next to the glyph (a wider button). */
  text?: ReactNode
  children: ReactNode
  ref?: Ref<HTMLButtonElement>
}

export function ToolButton({ label, pressed, text, children, className, type = 'button', ref, ...rest }: ToolButtonProps) {
  return (
    <button
      {...rest}
      ref={ref}
      type={type}
      aria-label={label}
      aria-pressed={pressed}
      title={label}
      data-gz="ToolButton"
      className={['gz-reset', 'gz-press', 'gzs-toolbtn', text ? 'gzs-toolbtn--text' : '', className ?? ''].filter(Boolean).join(' ')}
    >
      {children}
      {text ? <span className="gzs-toolbtn__text gz-t-button">{text}</span> : null}
    </button>
  )
}
