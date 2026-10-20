// Upload limits for partner media (ADR 0035 D10). Photos and videos are the only media; limits are constants here, never literals in the UI.
// Replaces the old short-clip limits (60 s, 100 MB, 720p): venue videos may be high quality, up to 500 MB each.
export const MEDIA = {
  /** 500 MB per video (decimal megabytes, as stores and gateways count them). */
  videoMaxBytes: 500 * 1000 * 1000,
  videoMaxMb: 500,
} as const
