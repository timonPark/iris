import { useCallback, useEffect, useRef, useState, type RefObject } from 'react'
import type { ApiClient } from '../api/client'
import { safely } from '../api/safely'
import { errorText } from '../auth/messages'
import type { Session } from './types'

const PAGE_SIZE: number = 20

export interface Sessions {
  items: Session[]
  /** 아직 불러오지 않은 페이지가 있다. */
  hasMore: boolean
  error: string | null
  loadMore: () => Promise<void>
  /** 새로 생겼거나 질문이 온 세션을 맨 위로. */
  putOnTop: (session: Session) => void
  remove: (id: string) => void
}

interface Page {
  items: Session[]
  nextCursor?: string
}

const appendNew = (prev: Session[], next: Session[]): Session[] => [...prev, ...next.filter((s: Session) => !prev.some((p: Session) => p.id === s.id))]
const without = (prev: Session[], id: string): Session[] => prev.filter((s: Session) => s.id !== id)

async function fetchPage(client: ApiClient, cursor: string | undefined): Promise<Page | string> {
  const { data, error } = await safely(client.GET('/api/v1/sessions', { params: { query: { cursor, limit: PAGE_SIZE } } }))
  return data ?? errorText(error)
}

/** 세션 목록(최근 활동 순). 처음 한 페이지를 불러오고, 목록 끝이 보이면 loadMore로 이어 불러온다. */
export function useSessions(client: ApiClient): Sessions {
  const [items, setItems] = useState<Session[]>([])
  const [cursor, setCursor] = useState<string | undefined>(undefined)
  const [hasMore, setHasMore] = useState<boolean>(true)
  const [error, setError] = useState<string | null>(null)
  const inFlight: RefObject<boolean> = useRef<boolean>(false)

  const loadMore = useCallback(async (): Promise<void> => {
    if (inFlight.current || !hasMore) return
    inFlight.current = true
    const page: Page | string = await fetchPage(client, cursor)
    inFlight.current = false
    setError(typeof page === 'string' ? page : null)
    if (typeof page === 'string') return
    setItems((prev: Session[]): Session[] => appendNew(prev, page.items))
    setCursor(page.nextCursor)
    setHasMore(page.nextCursor !== undefined)
  }, [client, cursor, hasMore])

  // 처음 한 번만 부른다. 이후 페이지는 목록 끝이 보일 때 불러온다.
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect((): void => void loadMore(), [])

  const putOnTop = useCallback((s: Session): void => setItems((prev: Session[]): Session[] => [s, ...without(prev, s.id)]), [])
  const remove = useCallback((id: string): void => setItems((prev: Session[]): Session[] => without(prev, id)), [])
  return { items, hasMore, error, loadMore, putOnTop, remove }
}
