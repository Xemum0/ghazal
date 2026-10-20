// The draft the Brief sheet edits: the global Brief plus the one local choice the Brief does not store (separate ladies and men receptions).
import type { SearchBrief } from '../data'

export type BriefDraft = {
  brief: SearchBrief
  /** Ladies and men have their own guest counts; the Brief carries the one being searched (ADR 0007 D3). */
  split: boolean
  counts: { women: number; men: number }
  /** The person chose "Not decided yet" (a skipped answer is a different thing: it keeps its placeholder). */
  later?: boolean
}

export type PanelProps = {
  draft: BriefDraft
  set: (next: BriefDraft | ((d: BriefDraft) => BriefDraft)) => void
}

export type PanelId = 'date' | 'area' | 'guests' | 'budget'
