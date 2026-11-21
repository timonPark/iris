import { useMemo, useState } from 'react'
import { createApiClient, type ApiClient, type AuthErrorCode } from '../api/client'
import { apiBaseUrl } from '../config'
import type { LoginNotice } from '../screens/LoginScreen'
import { clearAuth, loadAuth, saveAuth, type StoredAuth } from './storage'

export type Screen = 'login' | 'force-change' | 'chat' | 'settings'

export interface AuthFlow {
  screen: Screen
  notice: LoginNotice | null
  client: ApiClient
  loggedIn: (auth: StoredAuth) => void
  passwordChanged: (accessToken: string) => void
  go: (screen: Screen) => void
}

type SetScreen = (screen: Screen) => void
type SetNotice = (notice: LoginNotice | null) => void

function initialScreen(auth: StoredAuth | null): Screen {
  if (auth === null) return 'login'
  return auth.passwordChangeRequired ? 'force-change' : 'chat'
}

/** 어느 API에서 받든: 차단·토큰 무효면 토큰을 지우고 로그인 화면, 임시 비밀번호 상태면 강제 변경 화면. */
function authErrorHandler(setScreen: SetScreen, setNotice: SetNotice): (code: AuthErrorCode) => void {
  return (code: AuthErrorCode): void => {
    const stored: StoredAuth | null = loadAuth()
    if (code === 'PASSWORD_CHANGE_REQUIRED' && stored !== null) {
      saveAuth({ ...stored, passwordChangeRequired: true })
      setScreen('force-change')
      return
    }
    clearAuth()
    setNotice(code === 'ACCOUNT_BLOCKED' ? 'blocked' : 'unauthorized')
    setScreen('login')
  }
}

/** 로그인 상태와 화면 전환. 로그인 상태의 기준은 localStorage(`auth/storage.ts`)다. */
export function useAuthFlow(fetchImpl?: typeof fetch): AuthFlow {
  const [screen, setScreen] = useState<Screen>(() => initialScreen(loadAuth()))
  const [notice, setNotice] = useState<LoginNotice | null>(null)
  const client: ApiClient = useMemo(
    (): ApiClient =>
      createApiClient({
        baseUrl: apiBaseUrl,
        getAccessToken: (): string | null => loadAuth()?.accessToken ?? null,
        onAuthError: authErrorHandler(setScreen, setNotice),
        fetch: fetchImpl,
      }),
    [fetchImpl],
  )

  function loggedIn(auth: StoredAuth): void {
    saveAuth(auth)
    setNotice(null)
    setScreen(initialScreen(auth))
  }

  function passwordChanged(accessToken: string): void {
    const stored: StoredAuth | null = loadAuth()
    if (stored !== null) saveAuth({ ...stored, accessToken, passwordChangeRequired: false })
    setScreen((current: Screen): Screen => (current === 'force-change' ? 'chat' : current))
  }

  return { screen, notice, client, loggedIn, passwordChanged, go: setScreen }
}
