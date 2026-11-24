import { useMemo, useState } from 'react'
import { createApiClient, type ApiClient } from '../api/client'
import { apiBaseUrl } from '../config'
import { MESSAGES } from './messages'
import { clearAuth, loadAuth, saveAuth, type StoredAuth } from './storage'

export interface AuthFlow {
  /** 로그인한 관리자. 로그인 전이면 null. */
  auth: StoredAuth | null
  /** 로그인 화면으로 보낸 이유. 없으면 null. */
  notice: string | null
  client: ApiClient
  loggedIn: (auth: StoredAuth) => void
}

/** 로그인 상태와 화면 전환. 로그인 상태의 기준은 sessionStorage(`auth/storage.ts`)다.
 * 관리자 API가 토큰을 받지 않으면(UNAUTHORIZED, FORBIDDEN) 로그인 상태를 지우고 로그인 화면으로 보낸다. */
export function useAuthFlow(fetchImpl?: typeof fetch): AuthFlow {
  const [auth, setAuth] = useState<StoredAuth | null>(() => loadAuth())
  const [notice, setNotice] = useState<string | null>(null)
  const client: ApiClient = useMemo(
    (): ApiClient =>
      createApiClient({
        baseUrl: apiBaseUrl,
        getAccessToken: (): string | null => loadAuth()?.accessToken ?? null,
        onAuthError: (): void => {
          clearAuth()
          setAuth(null)
          setNotice(MESSAGES.relogin)
        },
        fetch: fetchImpl,
      }),
    [fetchImpl],
  )

  function loggedIn(next: StoredAuth): void {
    saveAuth(next)
    setNotice(null)
    setAuth(next)
  }

  return { auth, notice, client, loggedIn }
}
