import { useCallback, useEffect, useRef, useState, type RefObject } from 'react'
import type { ApiClient } from '../api/client'
import { safely, type ApiResult } from '../api/safely'
import { errorText } from '../auth/messages'
import type { User, UserPage } from './types'

/** 한 번에 받는 개수(샘플 #4: 최근 등록 순으로 20개씩). */
export const PAGE_SIZE: number = 20

export type ListState = 'loading' | 'ready' | 'error'

export interface Users {
  users: User[]
  state: ListState
  /** 다음 페이지가 있으면 있다. */
  nextCursor: string | undefined
  loadingMore: boolean
  retry: () => void
  /** 다음 페이지를 받는다. 실패하면 문구를 돌려준다. */
  loadMore: () => Promise<string | null>
  /** 바뀐 계정을 목록에 반영한다. */
  replace: (user: User) => void
  /** 새로 등록한 계정을 맨 위에 올린다. */
  prepend: (user: User) => void
}

type FetchPage = (cursor?: string) => Promise<ApiResult<UserPage, unknown>>

/** 사용자 계정 목록(최근 등록 순, 커서로 이어 받기). */
export function useUsers(client: ApiClient): Users {
  const [users, setUsers] = useState<User[]>([])
  const [nextCursor, setNextCursor] = useState<string | undefined>(undefined)
  const [loadingMore, setLoadingMore] = useState<boolean>(false)
  const fetchPage: FetchPage = useCallback(
    (cursor?: string): Promise<ApiResult<UserPage, unknown>> => safely(client.GET('/api/v1/admin/users', { params: { query: { cursor, limit: PAGE_SIZE } } })),
    [client],
  )
  const { state, retry } = useFirstPage(fetchPage, (page: UserPage): void => {
    setUsers(page.items)
    setNextCursor(page.nextCursor)
  })

  async function loadMore(): Promise<string | null> {
    if (nextCursor === undefined || loadingMore) return null
    setLoadingMore(true)
    const { data, error } = await fetchPage(nextCursor)
    setLoadingMore(false)
    if (data === undefined) return errorText(error)
    setUsers((prev: User[]): User[] => [...prev, ...data.items])
    setNextCursor(data.nextCursor)
    return null
  }

  return {
    users, state, nextCursor, loadingMore, loadMore, retry,
    replace: (user: User): void => setUsers((prev: User[]): User[] => prev.map((u: User): User => (u.id === user.id ? user : u))),
    prepend: (user: User): void => setUsers((prev: User[]): User[] => [user, ...prev]),
  }
}

/** 첫 페이지를 받는다. `retry`로 다시 받는다. 화면이 사라진 뒤 온 응답은 버린다. */
function useFirstPage(fetchPage: FetchPage, onPage: (page: UserPage) => void): { state: ListState; retry: () => void } {
  const [state, setState] = useState<ListState>('loading')
  const [attempt, setAttempt] = useState<number>(0)
  // 응답이 왔을 때의 최신 onPage를 쓴다(매번 새로 만들어지는 함수라 effect 의존성에 넣지 않는다).
  const apply: RefObject<(page: UserPage) => void> = useRef<(page: UserPage) => void>(onPage)
  useEffect((): void => { apply.current = onPage })

  useEffect((): (() => void) => {
    let live: boolean = true
    void fetchPage().then(({ data }: ApiResult<UserPage, unknown>): void => {
      if (!live) return
      if (data !== undefined) apply.current(data)
      setState(data === undefined ? 'error' : 'ready')
    })
    return (): void => { live = false }
  }, [fetchPage, attempt])

  return { state, retry: (): void => { setState('loading'); setAttempt((n: number): number => n + 1) } }
}
