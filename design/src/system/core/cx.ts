// Class-name joiner for the core components: falsy parts drop out. No dependency on purpose.
export type ClassPart = string | false | null | undefined

export const cx = (...parts: ClassPart[]): string => parts.filter(Boolean).join(' ')
