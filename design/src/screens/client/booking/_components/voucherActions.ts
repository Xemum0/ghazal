// The two voucher moves every step of the request flow shares: get one (the commit moment of ADR 0033, gated for a guest, restoring
// the exact quote after sign-in), and change the quote a voucher is bound to (CL-VCHR-04, where the saving test is re-run).
import { useNav } from '../../../../system'
import { usePrototype } from '../../../../shell/state'
import { voucherParams, useLive, type FlowModel } from './flow'

export function useVoucherActions(flow: FlowModel, from: string) {
  const nav = useNav()
  const live = useLive()
  const auth = usePrototype(s => s.auth)

  const getVoucher = () => {
    const params = voucherParams(flow, from)
    if (live && auth === 'guest') {
      usePrototype.getState().openGate('voucher', { screenId: 'CL-VCHR-01', params })
      nav.openSheet('CL-AUTH-01', { params: { reason: 'voucher', resume: 'CL-VCHR-01' } })
      return
    }
    nav.openSheet('CL-VCHR-01', { params })
  }

  const changeVoucher = () => nav.openSheet('CL-VCHR-04', { params: { ...voucherParams(flow, from), voucherId: flow.voucher?.id } })

  return { getVoucher, changeVoucher }
}
