// Loads whatever CSS the token pipeline has generated (packages/design-tokens/dist/*.css, ADR 0023) without naming
// files: the tokens-owner may add tokens.css, tokens.en.css, tokens.ar.css. Nothing here defines a token value.
import.meta.glob('../../../packages/design-tokens/dist/*.css', { eager: true })
export {}
