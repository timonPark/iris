import { useRef, useState, type RefObject } from 'react'
import type { ApiClient } from '../api/client'
import { safely } from '../api/safely'
import { errorText } from '../auth/messages'
import type { IssuedSecret, User, UserWithTemporaryPassword } from './types'

/** 확인을 받는 작업(차단, 비밀번호 초기화). 해제는 확인 없이 바로 한다(샘플 #4). */
export interface Pending {
  kind: 'block' | 'reset'
  user: User
}

export interface UserActions {
  pending: Pending | null
  error: string | null
  busy: boolean
  /** 해제를 기다리는 계정의 ID. 없으면 null. */
  unblocking: string | null
  ask: (kind: Pending['kind'], user: User) => void
  cancel: () => void
  confirm: () => Promise<void>
  /** 해제. 실패하면 문구를 돌려준다. */
  unblock: (user: User) => Promise<string | null>
}

export interface ActionCallbacks {
  onChanged: (user: User) => void
  onIssued: (secret: IssuedSecret) => void
}

export function useUserActions(client: ApiClient, callbacks: ActionCallbacks): UserActions {
  const [pending, setPending] = useState<Pending | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState<boolean>(false)
  const unblock: Unblock = useUnblock(client, callbacks.onChanged)

  async function confirm(): Promise<void> {
    if (pending === null || busy) return
    setBusy(true)
    const problem: string | null = await perform(client, pending, callbacks)
    setBusy(false)
    if (problem === null) setPending(null)
    setError(problem)
  }

  return {
    pending, error, busy, confirm, unblock: unblock.run, unblocking: unblock.userId,
    ask: (kind: Pending['kind'], user: User): void => { setError(null); setPending({ kind, user }) },
    // 보낸 작업을 기다리는 동안에는 닫지 않는다(늦게 온 응답이 다른 확인 창을 바꾸지 않게).
    cancel: (): void => { if (!busy) setPending(null) },
  }
}

interface Unblock {
  userId: string | null
  run: (user: User) => Promise<string | null>
}

/** 해제는 확인 없이 바로 한다. 기다리는 동안 다시 눌러도 한 번만 보낸다. */
function useUnblock(client: ApiClient, onChanged: (user: User) => void): Unblock {
  const [userId, setUserId] = useState<string | null>(null)
  const inFlight: RefObject<boolean> = useRef<boolean>(false)

  async function runUnblock(user: User): Promise<string | null> {
    if (inFlight.current) return null
    inFlight.current = true
    setUserId(user.id)
    const problem: string | null = await run(client.POST('/api/v1/admin/users/{userId}/unblock', pathOf(user)), onChanged)
    inFlight.current = false
    setUserId(null)
    return problem
  }

  return { userId, run: runUnblock }
}

function pathOf(user: User): { params: { path: { userId: string } } } {
  return { params: { path: { userId: user.id } } }
}

/** 확인한 작업을 보낸다. 실패하면 화면 문구를 돌려준다. */
function perform(client: ApiClient, { kind, user }: Pending, callbacks: ActionCallbacks): Promise<string | null> {
  if (kind === 'block') {
    return run(client.POST('/api/v1/admin/users/{userId}/block', pathOf(user)), callbacks.onChanged)
  }
  return run(client.POST('/api/v1/admin/users/{userId}/password-reset', pathOf(user)), (data: UserWithTemporaryPassword): void => {
    callbacks.onChanged(data.user)
    callbacks.onIssued({ kind: 'reset', loginId: data.user.loginId, temporaryPassword: data.temporaryPassword })
  })
}

/** 호출해서 성공하면 `onData`, 실패하면 화면 문구를 돌려준다. */
async function run<D, E>(call: Promise<{ data?: D; error?: E }>, onData: (data: D) => void): Promise<string | null> {
  const { data, error } = await safely(call)
  if (data === undefined) return errorText(error)
  onData(data)
  return null
}
