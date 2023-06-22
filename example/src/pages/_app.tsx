import type { AppProps } from 'next/app'
import 'nhsuk-frontend/dist/nhsuk.css'

export default function App({ Component, pageProps }: AppProps) {
  return <Component {...pageProps} />
}
