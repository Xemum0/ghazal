// Barrel for system/domain-voucher: the voucher marketplace pieces of ADR 0033 (voucher ticket and chip, QR, the two-price block, the
// purchase summary, the 24 hour confirm window). Single writer: system-owner. Screens import from the system barrel.
export { QrCode, qrModules, type QrCodeProps } from './QrCode'
export { VoucherCard, VoucherChip, AnyVenueMark, useVoucherTarget, type VoucherCardProps, type VoucherChipProps } from './VoucherCard'
export { PriceCompare, type PriceCompareProps } from './PriceCompare'
export { VoucherPurchaseSummary, type VoucherPurchaseSummaryProps } from './VoucherPurchaseSummary'
export { ConfirmWindow, CONFIRM_WINDOW_HOURS, useConfirmLeft, type ConfirmWindowProps } from './ConfirmWindow'
