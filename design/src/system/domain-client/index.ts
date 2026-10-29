// Barrel for system/domain-client. Owner: client-domain-owner (design/src/system/domain-client/**). Screens import from the system
// barrel, never from a file here. Typed props are exported with every component.
export { VenueCard, type VenueCardProps, type VenueCardVariant } from './VenueCard'
export { CardPriceLine, type PriceLineSize } from './bits'
export { BookingThread, THREAD_KEYS, threadModel, type BookingThreadProps, type BookingThreadVariant, type ThreadInput, type ThreadKey, type ThreadKnotModel } from './BookingThread'
export { BookingCard, type BookingCardProps } from './BookingCard'
export { PackageCard, type PackageCardProps } from './PackageCard'
export { PriceBreakdown, type PriceBreakdownProps, type PriceBreakdownSource } from './PriceBreakdown'
export { BriefSentence, type BriefField, type BriefSentenceProps, type BriefSentenceVariant } from './BriefSentence'
export { BriefCard, type BriefCardProps } from './BriefCard'
export { CategoryTile, type CategoryTileProps } from './CategoryTile'
export { VoucherWindowCard, type VoucherWindowCardProps } from './VoucherWindowCard'
export { CountdownCard, countdownMilestone, type CountdownCardProps, type CountdownMilestone } from './CountdownCard'
export { CompareTray, COMPARE_MAX, type CompareTrayProps } from './CompareTray'
export {
  BestInRow, CompareActionBar, CompareBand, CompareHeader, CompareRow, DifferencesToggle, RangeBar,
  type CompareActionBarProps, type CompareActionColumn, type CompareActionKind, type CompareHeaderColumn, type CompareHeaderProps, type CompareRowProps, type RangeBarProps,
} from './CompareParts'
export { CompareTable, type CompareTableProps } from './CompareTable'
export { ReviewCard, RatingSummary, type RatingSummaryProps, type ReviewCardProps } from './ReviewCard'
export { AmenityGrid, FaqAccordion, MapPreview, PolicyList, type AmenityGridProps, type MapPreviewProps, type PolicyListProps } from './VenueInfo'
export { ProviderNote, type ProviderNoteProps } from './ProviderNote'
export { PlannerTierCard, ServiceTile, VendorCard, type PlannerTierCardProps, type ServiceTileProps, type VendorCardProps } from './ServiceCards'
export { ChatBubble, ChatDateDivider, ConversationRow, type ChatBubbleProps, type ChatSide, type ConversationRowProps } from './Chat'
export { ChecklistItem, ChecklistProgress, BudgetSummary, type BudgetSummaryProps, type ChecklistItemProps } from './Planning'
export { NotificationRow, type NotificationRowProps } from './NotificationRow'
export { PaymentMethodRow, ReceiptSheet, toPaymentMethod, type ReceiptSheetProps, type PaymentMethodKey, type PaymentMethodRowProps } from './Payments'
