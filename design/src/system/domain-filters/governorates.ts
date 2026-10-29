// Governorates of the Client app (ADR 0038, CA-FLT-08): the only region the client chooses. The list is configuration (GET /areas returns
// `governorates`); the fixtures start with Kuwait's six official ones. Areas stay in the data for a venue's address line only.
import { getArea, governorates } from '../../mock'

/** What a Brief (or a profile) may carry: governorates chosen by the client, or the legacy areas of an older build (mapped up). */
export type RegionSource = { governorateIds?: readonly string[] | null; areaIds?: readonly string[] | null }

/**
 * The governorates a Brief speaks about, in list order. An explicit `governorateIds` wins (an empty list = every governorate); a
 * source that only has areas (an account saved before round 2) is mapped to the governorates of those areas, so nothing breaks.
 */
export function briefGovernorates(source: RegionSource | null | undefined): string[] {
  if (!source) return []
  if (source.governorateIds) return governorates.filter(g => source.governorateIds?.includes(g.id)).map(g => g.id)
  const ids = new Set((source.areaIds ?? []).map(id => getArea(id)?.governorateId).filter((x): x is string => Boolean(x)))
  return governorates.filter(g => ids.has(g.id)).map(g => g.id)
}
