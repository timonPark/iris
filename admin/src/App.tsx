import type { JSX } from 'react'
import { BaseStyles } from '@primer/react'
import { ThemeProvider } from '@primer/react/next'
import { useAuthFlow, type AuthFlow } from './auth/useAuthFlow'
import { AdminScreen } from './screens/AdminScreen'
import { LoginScreen } from './screens/LoginScreen'

export interface AppProps {
  /** 테스트에서 가짜 fetch를 넣는다. */
  fetch?: typeof fetch
}

export default function App({ fetch }: AppProps): JSX.Element {
  const { auth, client, loggedIn }: AuthFlow = useAuthFlow(fetch)

  return (
    <ThemeProvider colorMode="auto" dayScheme="light" nightScheme="dark" contextOnly>
      <BaseStyles className="root">
        {auth === null ? <LoginScreen client={client} onLoggedIn={loggedIn} /> : <AdminScreen loginId={auth.loginId} />}
      </BaseStyles>
    </ThemeProvider>
  )
}
