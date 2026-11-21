import { useRef, useState, type RefObject } from 'react'
import type { ApiClient, ErrorResponse } from '../api/client'
import { safely } from '../api/safely'
import { errorText, MESSAGES, newPasswordProblem } from './messages'

export interface PasswordChangeInput {
  /** 설정에서 바꿀 때만. 임시 비밀번호 직후 강제 변경에는 보내지 않는다. */
  currentPassword?: string
  newPassword: string
  confirm: string
}

export interface PasswordChange {
  error: string | null
  busy: boolean
  /** 성공하면 true. 받은 새 토큰은 onChanged로 넘긴다. */
  change: (input: PasswordChangeInput) => Promise<boolean>
}

export function usePasswordChange(client: ApiClient, onChanged: (accessToken: string) => void): PasswordChange {
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState<boolean>(false)
  // 응답 전 재제출을 막는다. 첫 요청이 토큰을 바꾼 뒤 두 번째 요청이 UNAUTHORIZED를 받아 로그인이 풀리는 것을 피한다.
  const inFlight: RefObject<boolean> = useRef<boolean>(false)

  async function change(input: PasswordChangeInput): Promise<boolean> {
    if (inFlight.current) return false
    const problem: string | null = newPasswordProblem(input.newPassword, input.confirm)
    setError(problem)
    if (problem !== null) {
      return false
    }
    inFlight.current = true
    setBusy(true)
    const { data, error: apiError } = await safely(
      client.POST('/api/v1/auth/password', {
        body: { currentPassword: input.currentPassword, newPassword: input.newPassword },
      }),
    )
    inFlight.current = false
    setBusy(false)
    if (data === undefined) {
      setError(changeErrorText(apiError, input.currentPassword !== undefined))
      return false
    }
    onChanged(data.accessToken)
    return true
  }

  return { error, busy, change }
}

function changeErrorText(error: ErrorResponse | undefined, sentCurrent: boolean): string {
  if (sentCurrent && error?.error.code === 'INVALID_CREDENTIALS') {
    return MESSAGES.currentPasswordWrong
  }
  return errorText(error)
}
