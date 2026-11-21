import type { JSX } from 'react'
import { BaseStyles } from '@primer/react'
import { ThemeProvider } from '@primer/react/next'
import { useAuthFlow, type AuthFlow } from './auth/useAuthFlow'
import { ChatScreen } from './screens/ChatScreen'
import { ForceChangeScreen } from './screens/ForceChangeScreen'
import { LoginScreen } from './screens/LoginScreen'

export interface AppProps {
  /** 테스트에서 가짜 fetch를 넣는다. */
  fetch?: typeof fetch
}

export default function App({ fetch }: AppProps): JSX.Element {
  const { screen, notice, client, loggedIn, passwordChanged, loginId }: AuthFlow = useAuthFlow(fetch)

  return (
    <ThemeProvider colorMode="auto" dayScheme="light" nightScheme="dark" contextOnly>
      <BaseStyles className="root">
        {screen === 'login' && <LoginScreen client={client} notice={notice} onLoggedIn={loggedIn} />}
        {screen === 'force-change' && <ForceChangeScreen client={client} onChanged={passwordChanged} />}
        {screen === 'chat' && <ChatScreen client={client} loginId={loginId} onPasswordChanged={passwordChanged} />}
      </BaseStyles>
    </ThemeProvider>
  )
}
