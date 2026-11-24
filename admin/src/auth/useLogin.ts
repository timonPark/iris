import { useRef, useState, type RefObject } from 'react'
import type { ApiClient } from '../api/client'
import { safely } from '../api/safely'
import { loginErrorText, MESSAGES } from './messages'
import type { StoredAuth } from './storage'

export interface Login {
  error: string | null
  busy: boolean
  login: (loginId: string, password: string) => Promise<void>
}

/** 로그인 호출. 관리자 역할만 통과시킨다(ssot/GLOSSARY.md "관리자 웹"). */
export function useLogin(client: ApiClient, onLoggedIn: (auth: StoredAuth) => void): Login {
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState<boolean>(false)
  // Primer Button의 loading은 제출을 막지 않으므로(aria-disabled만) 응답 전 재제출을 여기서 막는다.
  const inFlight: RefObject<boolean> = useRef<boolean>(false)

  async function login(loginId: string, password: string): Promise<void> {
    if (inFlight.current) return
    inFlight.current = true
    setBusy(true)
    setError(null)
    const { data, error: apiError } = await safely(
      client.POST('/api/v1/auth/login', { body: { loginId, password } }),
    )
    inFlight.current = false
    setBusy(false)
    if (data === undefined) {
      setError(loginErrorText(apiError))
    } else if (data.role !== 'admin') {
      setError(MESSAGES.notAdmin)
    } else {
      onLoggedIn({ accessToken: data.accessToken, loginId })
    }
  }

  return { error, busy, login }
}
