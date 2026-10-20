// A small markdown renderer for the repo's design documents (headings, paragraphs, lists, tables, quotes, rules, fenced code,
// and inline code, bold, italic, links). No dependency: the documents use this subset only. Output is React elements, never
// HTML strings, so nothing in a document can inject markup.
import { Fragment, type ReactNode } from 'react'

type Block =
  | { t: 'h'; level: number; text: string; id: string }
  | { t: 'p'; text: string }
  | { t: 'ul' | 'ol'; items: string[] }
  | { t: 'quote'; text: string }
  | { t: 'hr' }
  | { t: 'code'; text: string }
  | { t: 'table'; head: string[]; rows: string[][] }

const slug = (s: string) =>
  s
    .toLowerCase()
    .replace(/[`*_]/g, '')
    .replace(/[^\p{L}\p{N}]+/gu, '-')
    .replace(/^-+|-+$/g, '')

const cells = (line: string) =>
  line
    .trim()
    .replace(/^\|/, '')
    .replace(/\|$/, '')
    .split(/(?<!\\)\|/)
    .map(c => c.trim().replace(/\\\|/g, '|'))

export function parseMarkdown(src: string): Block[] {
  const lines = src.replace(/\r\n/g, '\n').split('\n')
  const out: Block[] = []
  let i = 0
  while (i < lines.length) {
    const line = lines[i]!
    if (!line.trim()) {
      i++
      continue
    }
    const fence = /^```/.exec(line)
    if (fence) {
      const body: string[] = []
      i++
      while (i < lines.length && !/^```/.test(lines[i]!)) body.push(lines[i++]!)
      i++
      out.push({ t: 'code', text: body.join('\n') })
      continue
    }
    const h = /^(#{1,4})\s+(.*)$/.exec(line)
    if (h) {
      out.push({ t: 'h', level: h[1]!.length, text: h[2]!.trim(), id: slug(h[2]!) })
      i++
      continue
    }
    if (/^\s*(---+|\*\*\*+)\s*$/.test(line)) {
      out.push({ t: 'hr' })
      i++
      continue
    }
    if (/^\s*\|/.test(line) && i + 1 < lines.length && /^\s*\|?\s*:?-{2,}/.test(lines[i + 1]!)) {
      const head = cells(line)
      i += 2
      const rows: string[][] = []
      while (i < lines.length && /^\s*\|/.test(lines[i]!)) rows.push(cells(lines[i++]!))
      out.push({ t: 'table', head, rows })
      continue
    }
    if (/^>\s?/.test(line)) {
      const body: string[] = []
      while (i < lines.length && /^>\s?/.test(lines[i]!)) body.push(lines[i++]!.replace(/^>\s?/, ''))
      out.push({ t: 'quote', text: body.join(' ') })
      continue
    }
    const li = /^\s*([-*]|\d+\.)\s+/.exec(line)
    if (li) {
      const ordered = /\d/.test(li[1]!)
      const items: string[] = []
      while (i < lines.length && /^\s*([-*]|\d+\.)\s+/.test(lines[i]!)) {
        let item = lines[i++]!.replace(/^\s*([-*]|\d+\.)\s+/, '')
        // A wrapped list item continues on indented lines.
        while (i < lines.length && /^\s{2,}\S/.test(lines[i]!) && !/^\s*([-*]|\d+\.)\s+/.test(lines[i]!)) item += ' ' + lines[i++]!.trim()
        items.push(item)
      }
      out.push({ t: ordered ? 'ol' : 'ul', items })
      continue
    }
    const para: string[] = []
    while (i < lines.length && lines[i]!.trim() && !/^(#{1,4}\s|```|>\s?|\s*\||\s*([-*]|\d+\.)\s+|\s*---+\s*$)/.test(lines[i]!)) para.push(lines[i++]!.trim())
    if (para.length === 0) {
      para.push(line.trim())
      i++
    }
    out.push({ t: 'p', text: para.join(' ') })
  }
  return out
}

// ---------------------------------------------------------------- inline

const INLINE = /(`[^`]+`)|(\*\*[^*]+\*\*)|(\*[^*\s][^*]*\*)|(\[[^\]]+\]\([^)]+\))/g

export function Inline({ text }: { text: string }): ReactNode {
  const parts: ReactNode[] = []
  let last = 0
  let n = 0
  for (const m of text.matchAll(INLINE)) {
    const at = m.index ?? 0
    if (at > last) parts.push(text.slice(last, at))
    const tok = m[0]
    const key = n++
    if (tok.startsWith('`')) parts.push(<code key={key} className="gzs-md__code" dir="ltr">{tok.slice(1, -1)}</code>)
    else if (tok.startsWith('**')) parts.push(<strong key={key}><Inline text={tok.slice(2, -2)} /></strong>)
    else if (tok.startsWith('*')) parts.push(<em key={key}><Inline text={tok.slice(1, -1)} /></em>)
    else {
      const lm = /^\[([^\]]+)\]\(([^)]+)\)$/.exec(tok)!
      const href = lm[2]!
      const external = /^https?:/.test(href)
      parts.push(
        external ? (
          <a key={key} href={href} target="_blank" rel="noopener noreferrer">{lm[1]}</a>
        ) : (
          <span key={key} className="gzs-md__ref">{lm[1]}</span>
        ),
      )
    }
    last = at + tok.length
  }
  if (last < text.length) parts.push(text.slice(last))
  return <>{parts.map((p, i) => <Fragment key={i}>{p}</Fragment>)}</>
}

export type Heading = { level: number; text: string; id: string }
export const headingsOf = (blocks: Block[]): Heading[] => blocks.flatMap(b => (b.t === 'h' && b.level <= 3 ? [{ level: b.level, text: b.text.replace(/[`*]/g, ''), id: b.id }] : []))

export function Markdown({ blocks }: { blocks: Block[] }) {
  return (
    <div className="gzs-md">
      {blocks.map((b, i) => {
        switch (b.t) {
          case 'h': {
            const H = (`h${Math.min(4, b.level + 1)}`) as 'h2' | 'h3' | 'h4' | 'h5'
            return (
              <H key={i} id={b.id} className={`gzs-md__h gzs-md__h${b.level}`}>
                <Inline text={b.text} />
              </H>
            )
          }
          case 'p':
            return <p key={i} className="gzs-md__p"><Inline text={b.text} /></p>
          case 'ul':
          case 'ol': {
            const L = b.t
            return (
              <L key={i} className="gzs-md__list">
                {b.items.map((x, j) => (
                  <li key={j}><Inline text={x} /></li>
                ))}
              </L>
            )
          }
          case 'quote':
            return <blockquote key={i} className="gzs-md__quote"><Inline text={b.text} /></blockquote>
          case 'hr':
            return <hr key={i} className="gzs-md__hr" />
          case 'code':
            return <pre key={i} className="gzs-md__pre" dir="ltr"><code>{b.text}</code></pre>
          case 'table':
            return (
              <div key={i} className="gzs-md__tablewrap" data-scroll>
                <table className="gzs-md__table">
                  <thead>
                    <tr>
                      {b.head.map((c, j) => (
                        <th key={j}><Inline text={c} /></th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {b.rows.map((row, r) => (
                      <tr key={r}>
                        {row.map((c, j) => (
                          <td key={j}><Inline text={c} /></td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )
        }
      })}
    </div>
  )
}
