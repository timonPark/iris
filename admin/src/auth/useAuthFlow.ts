import { useMemo, useState } from 'react'
import { createApiClient, type ApiClient } from '../api/client'
import { apiBaseUrl } from '../config'
import { loadAuth, saveAuth, type StoredAuth } from './storage'

export interface AuthFlow {
  /** 로그인한 관리자. 로그인 전이면 null. */
  auth: StoredAuth | null
  client: ApiClient
  loggedIn: (auth: StoredAuth) => void
}

/** 로그인 상태와 화면 전환. 로그인 상태의 기준은 sessionStorage(`auth/storage.ts`)다. */
export function useAuthFlow(fetchImpl?: typeof fetch): AuthFlow {
  const [auth, setAuth] = useState<StoredAuth | null>(() => loadAuth())
  const client: ApiClient = useMemo(
    (): ApiClient =>
      createApiClient({
        baseUrl: apiBaseUrl,
        getAccessToken: (): string | null => loadAuth()?.accessToken ?? null,
        fetch: fetchImpl,
      }),
    [fetchImpl],
  )

  function loggedIn(next: StoredAuth): void {
    saveAuth(next)
    setAuth(next)
  }

  return { auth, client, loggedIn }
}
