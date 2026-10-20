// Day overrides that pin the hero dates of the shared story for venues that use the seeded occupancy generator.
// V01 (the hotel venue) is decided by explicit calendar claims instead (see hotel.mjs).
const O = (venueId, hall, date, state, reason) => ({ venueId, hallId: `${venueId}-${hall}`, date, state, reason })

export const dayOverrides = [
  // Thu 14 Jan 2027, the story date: free at Lumi, Wasl, Qasr Al-Nakheel and Khaitan; on hold at Jawharat (CL-DISC-03).
  O('V05', 'marina', '2027-01-14', 'available', 'story date, free'),
  O('V07', 'ladies', '2027-01-14', 'held', 'story date, on hold for another couple'),
  O('V08', 'grand', '2027-01-14', 'available', 'story date, free (instant)'),
  O('V08', 'hall-a', '2027-01-14', 'available', 'story date, free (instant)'),
  O('V09', 'ladies', '2027-01-14', 'available', 'story date, free (winter rate)'),
  O('V14', 'ladies', '2027-01-14', 'available', 'story date, free (instant)'),
  O('V11', 'ladies', '2027-01-14', 'available', 'story date, free (instant)'),
  O('V02', 'qamar', '2027-01-14', 'available', 'story date, free'),
  // Qasr Al-Nakheel date rate, Thu 3 Dec.
  O('V09', 'ladies', '2026-12-03', 'available', 'date rate on offer'),
  // Last-minute offers need open dates inside 14 days.
  O('V06', 'diwan', '2026-11-21', 'available', 'last-minute offer'),
  O('V14', 'ladies', '2026-11-20', 'available', 'last-minute offer'),
  O('V11', 'ladies', '2026-11-26', 'available', 'last-minute offer'),
  // Alternatives for the lost-slot screen (CL-BOOK-07): free at Lumi on the story date and the days around it.
  O('V05', 'marina', '2027-01-21', 'available', 'alternative date'),
  O('V05', 'marina', '2027-01-22', 'available', 'alternative date'),
  O('V05', 'marina', '2027-01-23', 'available', 'alternative date'),
]
