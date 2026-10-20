import { Fragment, isValidElement, cloneElement, type ReactElement, type ReactNode } from 'react'
import type { MessageValues, Namespace } from '@gz/i18n'
import { useTranslator, type MessageKey } from './useT'

/** A tag in a message (`<link>…</link>`) becomes an element: either a function of its children or an element to clone. */
export type TagComponent = ((children: ReactNode) => ReactNode) | ReactElement<{ children?: ReactNode }>

export type TProps<N extends Namespace> = {
  ns?: N
  /** Message key (typed from the namespace's English JSON). */
  k: MessageKey<N>
  values?: MessageValues
  /** One entry per tag used in the message: `components={{ link: c => <a href="…">{c}</a> }}`. */
  components?: Record<string, TagComponent>
}

/**
 * Rich text with components. The translated string decides the order of words and where the tags fall, in either
 * language; the component only says what each tag is. `<T k="…" />` without tags is the same as `t('…')`.
 */
export function T<N extends Namespace = 'common'>({ ns = 'common' as N, k, values, components }: TProps<N>) {
  const { rich } = useTranslator(ns)
  let counter = 0
  const tagFns: Record<string, unknown> = {}
  for (const [name, comp] of Object.entries(components ?? {})) {
    tagFns[name] = (chunks: ReactNode[]): ReactNode => {
      const children = chunks.length === 1 ? chunks[0] : chunks
      const node = typeof comp === 'function' ? comp(children) : isValidElement(comp) ? cloneElement(comp, undefined, children) : children
      return <Fragment key={`t${counter++}`}>{node}</Fragment>
    }
  }
  const parts = rich<ReactNode>(k, { ...values, ...tagFns })
  const text = parts.length === 1 && typeof parts[0] === 'string' ? parts[0] : null
  if (text !== null && text.startsWith('⟦') && text.endsWith('⟧')) {
    return <span className="gz-i18n-missing" data-gz-missing-key={k}>{text}</span>
  }
  return <>{parts.map((p, i) => (typeof p === 'string' ? <Fragment key={`s${i}`}>{p}</Fragment> : p))}</>
}
