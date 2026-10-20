// The canvas exposes a handful of commands to the toolbar, the sidebar and the inspector. They live on one module-level handle
// (there is one canvas at a time); the Canvas component sets it while mounted. Nothing here holds state.
export type CanvasApi = {
  fitAll: () => void
  fitFlow: (flowId: string) => void
  /** Select a screen and bring it into view (zooms in when the frame would be tiny). */
  focusScreen: (screenId: string) => void
  fitSelected: () => void
  zoomIn: () => void
  zoomOut: () => void
  zoomTo: (k: number) => void
  /** Select the previous / next frame along the flow (reading order: inline-start to inline-end). */
  step: (dir: 1 | -1) => void
  frameCount: number
}

export const canvasBridge: { current: CanvasApi | null } = { current: null }

export const canvas = {
  fitAll: () => canvasBridge.current?.fitAll(),
  fitFlow: (id: string) => canvasBridge.current?.fitFlow(id),
  focusScreen: (id: string) => canvasBridge.current?.focusScreen(id),
  fitSelected: () => canvasBridge.current?.fitSelected(),
  zoomIn: () => canvasBridge.current?.zoomIn(),
  zoomOut: () => canvasBridge.current?.zoomOut(),
  zoomTo: (k: number) => canvasBridge.current?.zoomTo(k),
  step: (dir: 1 | -1) => canvasBridge.current?.step(dir),
}
