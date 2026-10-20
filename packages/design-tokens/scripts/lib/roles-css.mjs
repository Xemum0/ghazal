// One utility class per type role: .gz-t-<role> (design/src/styles/typography.roles.css, generated).
// The values are the --gz-type-<role>-* variables, which switch scale under :lang(ar), so a class is language-neutral.
import { HEADER } from './css.mjs'

/** Figure context: the Cairo figure role that matches the text role's size (EN Poppins x1.08, AR same size). */
export const NUM_CONTEXT = {
  label: 'fig-label', pill: 'fig-label', tab: 'fig-tab', caption: 'fig-caption', 'body-s': 'fig-body-s', button: 'fig-body-s',
  body: 'fig-body', title: 'fig-body', 'ui-title': 'fig-title', 'ui-xl': 'fig-xl',
}

export function buildRolesCss({ tokens }) {
  const roles = [...tokens.keys()].filter(p => p.startsWith('type.en.')).map(p => p.slice(8))
  const out = [`/* ${HEADER('Type role classes: .gz-t-<role>. Never edit; change src/tokens.json.')} */`, '']
  for (const r of roles) {
    const v = `--gz-type-${r}`
    const upper = tokens.get(`type.en.${r}`).value.textTransform === 'uppercase'
    out.push(`.gz-t-${r} {`)
    out.push(`  font-family: var(${v}-family);`, `  font-size: var(${v}-size);`, `  line-height: var(${v}-line);`, `  font-weight: var(${v}-weight);`)
    out.push(`  letter-spacing: var(${v}-tracking);`, `  word-spacing: var(${v}-word-spacing);`, `  font-variant-numeric: var(${v}-numeric);`)
    if (upper) out.push(`  /* flutter-ok: tracked uppercase eyebrow; Flutter uppercases the string in the shared label component (direction section 9) */`, `  text-transform: var(${v}-transform);`)
    // figures inside this text style take the matching Cairo figure size (see .gz-num in typography.css)
    out.push(NUM_CONTEXT[r] ? `  --gz-num-size: var(--gz-type-${NUM_CONTEXT[r]}-size);` : `  --gz-num-size: initial;`)
    out.push('}', '')
  }
  return out.join('\n')
}
