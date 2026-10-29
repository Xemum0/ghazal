// The two voucher moves every step of the request flow shares: get one (the commit moment of ADR 0033; the client is always signed in,
// ADR 0038), and change the quote a voucher is bound to (CL-VCHR-04, where the saving test is re-run).
import { useNav } from '../../../../system'
import { voucherParams, type FlowModel } from './flow'

export function useVoucherActions(flow: FlowModel, from: string) {
  const nav = useNav()
  const getVoucher = () => {
    const params = voucherParams(flow, from)
    nav.openSheet('CL-VCHR-01', { params })
  }

  const changeVoucher = () => nav.openSheet('CL-VCHR-04', { params: { ...voucherParams(flow, from), voucherId: flow.voucher?.id } })

  return { getVoucher, changeVoucher }
}
