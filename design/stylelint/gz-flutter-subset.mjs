// Stylelint plugin: the Flutter-translatable CSS subset (ADR 0024 D2, relaxed to warnings by ADR 0031 D3).
// Rules it enforces (everything else, logical properties and token-only values, is configured in stylelint.config.mjs):
//   - denied properties: grid*, backdrop-filter, mix-blend-mode, filter, clip-path, mask*, scroll-snap*, text-transform, float
//   - denied values: display:grid, position:fixed|sticky, font-style:italic|oblique, text-align:left|right, inset box-shadow,
//     more than two shadow layers, calc(), negative margins, container opacity (use alpha tokens)
//   - denied units: em rem vh vw vmin vmax dvh svh lvh ch ex and % (except flex/flex-basis)
//   - raw colours outside the token package (hex, rgb(), hsl(), oklch(), color-mix()) and raw motion values (ms, s, cubic-bezier)
//   - px on spacing/size properties must be on the 4-pt grid (exceptions: 0, 1 hairline, 2, 6, 10, and 9999 = radius.pill)
//   - :hover selectors (touch UI)
// Waiver: a `/* flutter-ok: <reason> */` comment directly above the declaration or its rule, or trailing on the same line.
// `position: sticky` is waived with `/* flutter-ok: pinned sliver */` (ADR 0031 D3); the reason text is required.
import stylelint from 'stylelint'

const { createPlugin, utils } = stylelint
export const ruleName = 'gz/flutter-subset'
const messages = utils.ruleMessages(ruleName, { violation: m => m })

const DENIED_PROP = /^(grid($|-)|backdrop-filter$|mix-blend-mode$|filter$|clip-path$|mask($|-)|scroll-snap|text-transform$|float$)/
const GRID_PX_PROPS = /^(width|height|(min|max)-(width|height)|(inline|block)-size|(min|max)-(inline|block)-size|margin(-.+)?|padding(-.+)?|gap|row-gap|column-gap|inset(-.+)?|top|bottom|left|right|flex-basis|border-radius|border-(start|end)-(start|end)-radius|border-(top|bottom)-(left|right)-radius)$/
const GRID_OK = new Set([0, 1, 2, 6, 10, 9999])
const BAD_UNIT = /(?<![\w#.-])-?\d*\.?\d+(em|rem|vh|vw|vmin|vmax|dvh|svh|lvh|dvw|svw|lvw|ch|ex)\b/i
const RAW_COLOR = /#[0-9a-f]{3,8}\b|\b(rgb|rgba|hsl|hsla|hwb|lab|lch|oklab|oklch|color-mix|color)\(/i
const RAW_MOTION = /(?<![\w.-])\d*\.?\d+m?s\b|\bcubic-bezier\(|\bsteps\(|\b(ease|ease-in|ease-out|ease-in-out|linear)\b/i
const MOTION_PROP = /^(transition|animation)(-duration|-delay|-timing-function)?$/

/** Remove var(...) calls (with nested parentheses) so fallbacks do not count as raw values. */
function stripVars(value) {
  let out = ''
  for (let i = 0; i < value.length; ) {
    if (value.startsWith('var(', i)) {
      let depth = 0
      let j = i + 3
      for (; j < value.length; j++) {
        if (value[j] === '(') depth++
        else if (value[j] === ')' && --depth === 0) break
      }
      out += ' '
      i = j + 1
    } else out += value[i++]
  }
  return out
}

function topLevelCommas(value) {
  let depth = 0
  let n = 0
  for (const c of value) {
    if (c === '(') depth++
    else if (c === ')') depth--
    else if (c === ',' && depth === 0) n++
  }
  return n
}

const hasWaiver = node => {
  const isWaiver = n => n?.type === 'comment' && /flutter-ok\s*:\s*\S/.test(n.text)
  if (isWaiver(node.prev())) return true
  const next = node.next()
  if (isWaiver(next) && next.source?.start?.line === node.source?.end?.line) return true
  const rule = node.parent
  if (rule?.type === 'rule' && isWaiver(rule.prev())) return true
  return false
}

const plugin = createPlugin(ruleName, primary => (root, result) => {
  if (!primary) return
  const report = (node, text, word) => utils.report({ ruleName, result, node, message: messages.violation(text), word })

  root.walkRules(rule => {
    if (/:hover\b/.test(rule.selector) && !hasWaiver(rule)) report(rule, 'no :hover: the UI is touch-first (use :active / pressed state tokens)', ':hover')
  })

  root.walkDecls(decl => {
    if (hasWaiver(decl)) return
    const prop = decl.prop.toLowerCase()
    const value = decl.value
    const bare = stripVars(value)

    if (prop.startsWith('--')) {
      if (RAW_COLOR.test(bare)) report(decl, `raw colour in custom property ${prop}: colours live in packages/design-tokens only`, decl.value)
      return
    }
    if (DENIED_PROP.test(prop)) return report(decl, `\`${prop}\` has no cheap Flutter equivalent (ADR 0024 D2); waive with /* flutter-ok: reason */ only for the named arch clip`, prop)

    if (prop === 'display' && /grid/.test(value)) report(decl, '`display: grid` is not allowed: use flex + gap', value)
    if (prop === 'position' && /^fixed$/.test(value.trim())) report(decl, '`position: fixed` is not allowed', value)
    if (prop === 'position' && /^sticky$/.test(value.trim())) report(decl, '`position: sticky` only for pinned bars: add /* flutter-ok: pinned sliver */', value)
    if (prop === 'font-style' && /italic|oblique/.test(value)) report(decl, 'no italic or oblique (ADR 0030): the fonts ship no italics', value)
    if (prop === 'text-align' && /^(left|right)$/.test(value.trim())) report(decl, '`text-align: left|right` is physical: use start / end', value)
    if (prop === 'opacity') report(decl, 'container `opacity` becomes saveLayer in Flutter: use an alpha token', value)
    if (/calc\(/.test(bare) || /calc\(/.test(value)) report(decl, '`calc()` has no Flutter equivalent', 'calc(')
    if (/^margin/.test(prop) && /(^|\s)-\d/.test(bare)) report(decl, 'negative margins are not allowed', value)

    if (prop === 'box-shadow') {
      if (/\binset\b/.test(bare)) report(decl, 'inset shadows are not allowed', value)
      if (topLevelCommas(value) >= 2) report(decl, 'at most two shadow layers', value)
    }

    const unit = BAD_UNIT.exec(bare)
    if (unit) report(decl, `unit \`${unit[1]}\` is not translatable: use integer px or a token`, unit[0])
    if (/\d%/.test(bare) && !/^flex(-basis)?$/.test(prop)) report(decl, '`%` is only allowed in flex / flex-basis', bare)

    if (!/^(src|content|font-family)$/.test(prop) && RAW_COLOR.test(bare)) report(decl, 'raw colour: use a var(--gz-color-...) token (hex lives in packages/design-tokens only)', value)
    if (MOTION_PROP.test(prop) && RAW_MOTION.test(bare)) report(decl, 'raw motion value: durations and easings come from var(--gz-motion-...) tokens (ADR 0017)', value)

    if (GRID_PX_PROPS.test(prop)) {
      for (const m of value.matchAll(/(?<![\w#.-])(-?\d*\.?\d+)px\b/g)) {
        const n = Math.abs(Number(m[1]))
        if (!Number.isInteger(n) || (n % 4 !== 0 && !GRID_OK.has(n))) report(decl, `${m[0]} is off the 4-pt grid (allowed: multiples of 4, plus 0, 1, 2, 6, 10, and 9999 for the pill radius): use a spacing token`, m[0])
      }
    }
  })
})

export default plugin
