import type { JSX } from 'react'
import { BaseStyles } from '@primer/react'
import { ThemeProvider } from '@primer/react/next'
import { useAuthFlow, type AuthFlow } from './auth/useAuthFlow'
import { ChatPlaceholder } from './screens/ChatPlaceholder'
import { ForceChangeScreen } from './screens/ForceChangeScreen'
import { LoginScreen } from './screens/LoginScreen'
import { SettingsScreen } from './screens/SettingsScreen'

export interface AppProps {
  /** 테스트에서 가짜 fetch를 넣는다. */
  fetch?: typeof fetch
}

export default function App({ fetch }: AppProps): JSX.Element {
  const { screen, notice, client, loggedIn, passwordChanged, go }: AuthFlow = useAuthFlow(fetch)

  return (
    <ThemeProvider colorMode="auto" dayScheme="light" nightScheme="dark" contextOnly>
      <BaseStyles className="root">
        {screen === 'login' && <LoginScreen client={client} notice={notice} onLoggedIn={loggedIn} />}
        {screen === 'force-change' && <ForceChangeScreen client={client} onChanged={passwordChanged} />}
        {screen === 'chat' && <ChatPlaceholder onOpenSettings={(): void => go('settings')} />}
        {screen === 'settings' && <SettingsScreen client={client} onChanged={passwordChanged} />}
      </BaseStyles>
    </ThemeProvider>
  )
}
