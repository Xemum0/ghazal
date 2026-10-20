// Barrel for system/charts: SVG and flex charts drawn from tokens (no chart library), direction-aware per ADR 0014 D5, each with a
// table twin, animate-in once and a reduced-motion fallback. Owner: hotel-domain-owner. Screens import from the system barrel.
export { Sparkline, type SparklineProps } from './Sparkline'
export { BarChart, type Bar, type BarChartProps } from './BarChart'
export { LineChart, type LineChartProps, type LineSeries } from './LineChart'
export { BreakdownChart, DonutOrStackedBar, type BreakdownChartProps, type Segment } from './BreakdownChart'
export { FunnelBars, type FunnelBarsProps, type FunnelStage } from './FunnelBars'
export { RankedBars, type RankedBarsProps, type RankedItem } from './RankedBars'
export { HeatStrip, type HeatDay, type HeatStripProps, type LaneState } from './HeatStrip'
export type { FillPattern } from './internal/kit'
