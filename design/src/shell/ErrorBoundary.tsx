import { Component, type ErrorInfo, type ReactNode } from 'react'

type Props = { children: ReactNode; label: string }
type State = { error: Error | null }

/** Per-route boundary: a broken gallery page or screen shows a readable error, never a white page. */
export class ErrorBoundary extends Component<Props, State> {
  override state: State = { error: null }

  static getDerivedStateFromError(error: Error): State {
    return { error }
  }

  override componentDidCatch(error: Error, info: ErrorInfo) {
    // console.error is what shots.mjs reports as a page error.
    console.error(`[${this.props.label}] ${error.message}`, info.componentStack)
  }

  override render() {
    const { error } = this.state
    if (!error) return this.props.children
    return (
      <div className="gz-shell-notice gz-shell-notice--error" role="alert" data-gz-error={this.props.label}>
        <p className="gz-shell-notice__title">Could not render {this.props.label}</p>
        <pre className="gz-shell-notice__body">{error.message}</pre>
      </div>
    )
  }
}
