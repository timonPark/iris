import { useRef, useState, type RefObject } from 'react'
import type { ApiClient } from '../api/client'
import { safely } from '../api/safely'
import { errorText } from '../auth/messages'
import type { IssuedSecret, User } from './types'

export interface CreateUser {
  open: boolean
  error: string | null
  busy: boolean
  start: () => void
  cancel: () => void
  /** 아이디를 고치면 이전 오류를 지운다. */
  clearError: () => void
  submit: (loginId: string) => Promise<void>
}

type OnCreated = (user: User, secret: IssuedSecret) => void

/** 계정 등록. 아이디만 보내고, 비밀번호는 시스템이 만든다. */
export function useCreateUser(client: ApiClient, onCreated: OnCreated): CreateUser {
  const [open, setOpen] = useState<boolean>(false)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState<boolean>(false)
  // Primer Button의 loading은 제출을 막지 않으므로(aria-disabled만) 응답 전 재제출을 여기서 막는다.
  const inFlight: RefObject<boolean> = useRef<boolean>(false)

  async function submit(loginId: string): Promise<void> {
    if (inFlight.current) return
    inFlight.current = true
    setBusy(true)
    const { data, error: apiError } = await safely(client.POST('/api/v1/admin/users', { body: { loginId } }))
    inFlight.current = false
    setBusy(false)
    setError(data === undefined ? errorText(apiError) : null)
    if (data === undefined) return
    setOpen(false)
    onCreated(data.user, { kind: 'created', loginId: data.user.loginId, temporaryPassword: data.temporaryPassword })
  }

  const start = (): void => { setError(null); setOpen(true) }
  const cancel = (): void => { if (!busy) setOpen(false) }
  return { open, error, busy, submit, start, cancel, clearError: (): void => setError(null) }
}
