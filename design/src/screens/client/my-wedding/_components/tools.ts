// Flow-local state of the planning tools: what the couple ticked, added and typed in Checklist and Budget. The shared prototype store has no
// slice for these yet (request filed), so the flow keeps its own small zustand store; it resets whenever the prototype's user changes
// (story start, sign-in, sign-out), so "Restart" in the player really restarts. Static frames never read it (see useWedding).
import { create } from 'zustand'
import { usePrototype } from '../../../../shell/state'
import type { CustomTask, ManualExpense } from './model'

export type ToolsState = {
  /** Checklist ids the couple ticked, with the time. */
  done: Record<string, string>
  custom: CustomTask[]
  /** Default items the couple deleted (none today; custom ones are removed from `custom`). */
  removed: string[]
  expenses: ManualExpense[]
  /** Total as typed in Set budget; undefined = the seed's. */
  total: number | null | undefined
  alloc: Record<string, number>
  plannerHidden: boolean

  toggleTask: (id: string, done: boolean, at: string) => void
  addTask: (task: Omit<CustomTask, 'id'>) => string
  editTask: (id: string, patch: Partial<Omit<CustomTask, 'id'>>) => void
  removeTask: (id: string) => CustomTask | null
  restoreTask: (task: CustomTask) => void
  addExpense: (e: Omit<ManualExpense, 'id'>) => string
  editExpense: (id: string, patch: Partial<Omit<ManualExpense, 'id'>>) => void
  removeExpense: (id: string) => ManualExpense | null
  restoreExpense: (e: ManualExpense) => void
  saveBudget: (total: number, alloc: Record<string, number>) => void
  hidePlanner: () => void
}

const initial = () => ({
  done: {} as Record<string, string>,
  custom: [] as CustomTask[],
  removed: [] as string[],
  expenses: [] as ManualExpense[],
  total: undefined as number | null | undefined,
  alloc: {} as Record<string, number>,
  plannerHidden: false,
})

let seq = 0
const nextId = (prefix: string) => `${prefix}-${++seq}`

export const useTools = create<ToolsState>()((set, get) => ({
  ...initial(),
  toggleTask: (id, done, at) =>
    set(s => {
      const next = { ...s.done }
      if (done) next[id] = at
      else delete next[id]
      return { done: next }
    }),
  addTask: task => {
    const id = nextId('task')
    set(s => ({ custom: [...s.custom, { id, ...task }] }))
    return id
  },
  editTask: (id, patch) => set(s => ({ custom: s.custom.map(c => (c.id === id ? { ...c, ...patch } : c)) })),
  removeTask: id => {
    const found = get().custom.find(c => c.id === id) ?? null
    set(s => {
      const done = { ...s.done }
      delete done[id]
      return { custom: s.custom.filter(c => c.id !== id), done }
    })
    return found
  },
  restoreTask: task => set(s => (s.custom.some(c => c.id === task.id) ? s : { custom: [...s.custom, task] })),
  addExpense: e => {
    const id = nextId('exp')
    set(s => ({ expenses: [{ id, ...e }, ...s.expenses] }))
    return id
  },
  editExpense: (id, patch) => set(s => ({ expenses: s.expenses.map(e => (e.id === id ? { ...e, ...patch } : e)) })),
  removeExpense: id => {
    const found = get().expenses.find(e => e.id === id) ?? null
    set(s => ({ expenses: s.expenses.filter(e => e.id !== id) }))
    return found
  },
  restoreExpense: e => set(s => (s.expenses.some(x => x.id === e.id) ? s : { expenses: [e, ...s.expenses] })),
  saveBudget: (total, alloc) => set({ total, alloc }),
  hidePlanner: () => set({ plannerHidden: true }),
}))

// A new user (story start, sign-in, sign-out) means a fresh file.
usePrototype.subscribe((s, prev) => {
  if (s.user !== prev.user) useTools.setState(initial())
})
