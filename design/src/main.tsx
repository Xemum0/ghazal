import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './shell/tokens'
import './styles/index.css'
import './shell/shell.css'
import { App } from './shell/App'
import { GzProvider } from './shell/lang'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <GzProvider>
      <App />
    </GzProvider>
  </StrictMode>,
)
