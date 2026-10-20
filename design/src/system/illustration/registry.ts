// The illustration registry: name -> drawing, kind and mirror flag (ADR 0034 D9, ADR 0014).
// A drawing mirrors in Arabic only when it carries reading-direction meaning (a spout, a pegbox, a key bow, a route, a car's heading,
// a bubble staircase, a handle). Clocks, rings, QR, symmetric architecture and hangers never flip.
import type { ComponentType } from 'react'
import { BeachArch, Chandelier, Doorway, Fanous, GardenArch, Hall, Kosha } from './spots-arch'
import { Buffet, Bouquet, Cake, Camera, Car, Dallah, Dress, Envelope, Finjan, Invitation, Key, Oud, Palette, Rings, Suitcase, Vase } from './spots-objects'
import { Bell, Calendar, Card, Chat, Clock, GroupChat, Hourglass, NoResult, Qr, Route, Seal, Shelf, Shield, Voucher, Warning, WifiOff } from './spots-ui'
import { scenes } from './scenes'

export type IllustrationKind = 'spot' | 'scene'
type Entry = { Draw: ComponentType; kind: IllustrationKind; mirror: boolean }
const spot = (Draw: ComponentType, mirror = false): Entry => ({ Draw, kind: 'spot', mirror })

const spots = {
  doorway: spot(Doorway),
  chandelier: spot(Chandelier),
  fanous: spot(Fanous),
  dallah: spot(Dallah, true),
  finjan: spot(Finjan),
  bouquet: spot(Bouquet),
  rings: spot(Rings),
  cake: spot(Cake),
  invitation: spot(Invitation),
  envelope: spot(Envelope),
  voucher: spot(Voucher),
  qr: spot(Qr),
  calendar: spot(Calendar),
  key: spot(Key, true),
  hall: spot(Hall),
  kosha: spot(Kosha),
  'beach-arch': spot(BeachArch),
  'garden-arch': spot(GardenArch),
  hourglass: spot(Hourglass),
  clock: spot(Clock),
  'group-chat': spot(GroupChat, true),
  chat: spot(Chat, true),
  seal: spot(Seal),
  route: spot(Route, true),
  camera: spot(Camera),
  vase: spot(Vase),
  buffet: spot(Buffet),
  oud: spot(Oud, true),
  car: spot(Car, true),
  suitcase: spot(Suitcase),
  palette: spot(Palette),
  dress: spot(Dress),
  shield: spot(Shield),
  shelf: spot(Shelf),
  'no-result': spot(NoResult, true),
  'wifi-off': spot(WifiOff),
  warning: spot(Warning),
  bell: spot(Bell),
  card: spot(Card),
} as const

const all = { ...spots, ...scenes } as const satisfies Record<string, Entry>

export type IllustrationName = keyof typeof all
export const illustrationNames = Object.keys(all) as IllustrationName[]
export const spotNames = Object.keys(spots) as (keyof typeof spots)[]
export const sceneNames = Object.keys(scenes) as (keyof typeof scenes)[]
export const illustrationEntry = (name: IllustrationName): Entry => all[name]
/** The mirror registry for drawings (ADR 0014 D2, extended by ADR 0034 D9). */
export const illustrationMirrors: readonly IllustrationName[] = illustrationNames.filter(n => all[n].mirror)
