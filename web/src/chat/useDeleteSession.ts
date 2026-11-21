import { useState } from 'react'
import type { ApiClient } from '../api/client'
import { safely } from '../api/safely'
import { errorText } from '../auth/messages'
import type { Session } from './types'

export interface DeleteSession {
  /** 삭제를 확인 중인 세션. 없으면 대화상자를 닫는다. */
  target: Session | null
  error: string | null
  busy: boolean
  ask: (session: Session) => void
  cancel: () => void
  confirm: () => Promise<void>
}

export function useDeleteSession(client: ApiClient, onDeleted: (id: string) => void): DeleteSession {
  const [target, setTarget] = useState<Session | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState<boolean>(false)

  async function confirm(): Promise<void> {
    if (target === null || busy) return
    setBusy(true)
    const { response, error: apiError } = await safely(
      client.DELETE('/api/v1/sessions/{sessionId}', { params: { path: { sessionId: target.id } } }),
    )
    setBusy(false)
    // 이미 없는 세션(SESSION_NOT_FOUND)도 목록에서 지운다.
    if (response?.ok === true || apiError?.error.code === 'SESSION_NOT_FOUND') {
      onDeleted(target.id)
      setTarget(null)
      return
    }
    setError(errorText(apiError))
  }

  const ask = (session: Session): void => {
    setError(null)
    setTarget(session)
  }

  return { target, error, busy, ask, cancel: (): void => setTarget(null), confirm }
}
