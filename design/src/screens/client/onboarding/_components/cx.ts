// Class-name joiner (the system's own `cx` is internal to system/core, so the flow keeps a two-line copy).
export const cx = (...parts: Array<string | false | null | undefined>): string => parts.filter(Boolean).join(' ')
