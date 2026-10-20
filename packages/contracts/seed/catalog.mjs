// Venue catalogue: venues, halls, packages, price rules and extras, assembled from the specs.
import { buildVenue } from './venue-build.mjs'
import { resetRuleSeq } from './venue-kit.mjs'
import { prestige } from './venues-prestige.mjs'
import { signature } from './venues-signature.mjs'
import { classic } from './venues-classic.mjs'

resetRuleSeq()
const order = ['V01', 'V02', 'V03', 'V04', 'V05', 'V06', 'V07', 'V08', 'V09', 'V10', 'V11', 'V12', 'V13', 'V14', 'V17', 'V19']
const specs = [...prestige, ...signature, ...classic].sort((a, b) => order.indexOf(a.id) - order.indexOf(b.id))

const built = specs.map(buildVenue)
export const venues = built.map((b) => b.venue)
export const packages = built.flatMap((b) => b.packages)
export const priceRules = built.flatMap((b) => b.rules)
export const extras = built.flatMap((b) => b.extras)
