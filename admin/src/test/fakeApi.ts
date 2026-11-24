import { vi } from 'vitest'

/** JSON 응답. 응답을 미루려면 `wait`. */
export interface FakeReply {
  status: number
  body?: unknown
  /** 이 약속이 풀릴 때까지 응답을 미룬다(기다리는 중 화면 확인용). */
  wait?: Promise<void>
}

export interface SentRequest {
  method: string
  path: string
  query: string
  authorization: string | null
  body: unknown
}

export interface FakeApi {
  fetch: typeof fetch
  sent: SentRequest[]
}

async function record(request: Request): Promise<SentRequest> {
  const url: URL = new URL(request.url)
  const text: string = await request.text()
  return {
    method: request.method,
    path: url.pathname,
    query: url.search,
    authorization: request.headers.get('Authorization'),
    body: text === '' ? null : JSON.parse(text),
  }
}

/** 경로("POST /api/v1/auth/login")별 응답을 순서대로 돌려주는 가짜 fetch. 응답이 없으면 네트워크 오류. */
export function fakeApi(replies: Record<string, FakeReply[]>): FakeApi {
  const sent: SentRequest[] = []
  const fetchImpl = vi.fn(async (input: RequestInfo | URL): Promise<Response> => {
    const entry: SentRequest = await record(input as Request)
    sent.push(entry)
    const reply: FakeReply | undefined = replies[`${entry.method} ${entry.path}`]?.shift()
    if (reply === undefined) {
      throw new TypeError('Failed to fetch')
    }
    await reply.wait
    return new Response(JSON.stringify(reply.body), {
      status: reply.status,
      headers: { 'Content-Type': 'application/json' },
    })
  })
  return { fetch: fetchImpl as unknown as typeof fetch, sent }
}

export function apiError(status: number, code: string, message: string): FakeReply {
  return { status, body: { error: { code, message } } }
}

export function loginOk(role: 'admin' | 'user', accessToken: string = 'tk'): FakeReply {
  return { status: 200, body: { accessToken, role, passwordChangeRequired: role === 'user' } }
}

export interface UserFixture {
  id: string
  loginId: string
  status: 'active' | 'blocked'
  passwordChangeRequired: boolean
  createdAt: string
}

/** 관리자 API의 사용자 계정(`User`). */
export function userOf(loginId: string, extra: Partial<UserFixture> = {}): UserFixture {
  return {
    id: `id-${loginId}`,
    loginId,
    status: 'active',
    passwordChangeRequired: false,
    createdAt: '2026-11-20T03:00:00Z',
    ...extra,
  }
}

export function userPage(items: UserFixture[], nextCursor?: string): FakeReply {
  return { status: 200, body: nextCursor === undefined ? { items } : { items, nextCursor } }
}
