import type { LatLng } from '../types/common.ts'

/** Great-circle distance in kilometres. */
export function haversineKm(a: LatLng, b: LatLng): number {
  const R = 6371
  const toRad = (d: number) => (d * Math.PI) / 180
  const dLat = toRad(b.lat - a.lat)
  const dLng = toRad(b.lng - a.lng)
  const h =
    Math.sin(dLat / 2) ** 2 + Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLng / 2) ** 2
  return 2 * R * Math.asin(Math.sqrt(h))
}

/**
 * Typical drive: road distance is 1.3x the straight line. The first 10 km run at city speed (1.5 min per km), the rest at
 * highway speed (0.65 min per km), with a 3-minute floor. Kuwait is small: most venues sit 10 to 45 minutes apart.
 */
export function driveEstimate(a: LatLng, b: LatLng): { km: number; minutes: number } {
  const road = haversineKm(a, b) * 1.3
  const km = Math.max(1, Math.round(road))
  const minutes = Math.max(3, Math.round(Math.min(road, 10) * 1.5 + Math.max(0, road - 10) * 0.65))
  return { km, minutes }
}
