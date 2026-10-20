// Rich-text tags shared by the flow's messages: `<num>` is an LTR figure island (phones), `<terms>` and `<privacy>` are text links.
import type { ReactNode } from 'react'
import { Ltr } from '../../../../i18n'

export const numTag = (children: ReactNode) => <Ltr className="gz-num">{children}</Ltr>
