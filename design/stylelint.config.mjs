// Stylelint for design/src/**/*.css: the Flutter-translatable subset (ADR 0024 D2) as WARNINGS during the design pass
// (ADR 0031 D3); they become errors at design freeze (flip defaultSeverity). Single writer: integrator.
const SPACING = ['gap', 'row-gap', 'column-gap', '/^padding/', '/^margin/']
const RADIUS = ['border-radius', '/^border-(start|end)-(start|end)-radius$/', '/^border-(top|bottom)-(left|right)-radius$/']
const COLOR = ['/color$/', 'fill', 'stroke', 'box-shadow', 'outline', 'border', '/^border-(block|inline|top|bottom|left|right|start|end)(-start|-end)?$/']
const TYPE = ['font-family', 'font-size', 'font-weight', 'line-height', 'letter-spacing']
const MOTION = ['transition-duration', 'transition-timing-function', 'animation-duration', 'animation-timing-function']
// `0`, `auto` and the CSS-wide keywords carry no magic number; `currentcolor`/`transparent` are not palette values.
const IGNORE = ['0', 'auto', 'inherit', 'initial', 'unset', 'none', 'normal', 'transparent', 'currentcolor', 'currentColor']

export default {
  defaultSeverity: 'warning',
  plugins: ['stylelint-use-logical', 'stylelint-declaration-strict-value', './stylelint/gz-flutter-subset.mjs'],
  rules: {
    'gz/flutter-subset': true,
    // Logical properties only: margin-inline-start, inset-inline-end, never left/right (ADR 0014).
    'csstools/use-logical': 'always',
    // Tokens are the only source of colour, space, radius, type and motion values (AGENTS.md hard rules).
    'scale-unlimited/declaration-strict-value': [
      [...COLOR, ...SPACING, ...RADIUS, ...TYPE, ...MOTION],
      { ignoreValues: IGNORE, ignoreFunctions: false, disableFix: true, severity: 'warning' },
    ],
  },
  overrides: [
    {
      // Harness-only CSS (Studio shell chrome, the gallery harness pages and the per-group gallery sections): not product
      // CSS (and @font-face declarations, whose family and weight are literals by definition), so token strictness is relaxed; logical properties and the subset deny-list still apply.
      files: ['src/shell/**/*.css', 'src/gallery/**/*.css', 'src/system/*/gallery/**/*.css', 'src/styles/fonts.css'],
      rules: { 'scale-unlimited/declaration-strict-value': null },
    },
  ],
}
