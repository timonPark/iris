import { vi } from 'vitest'

export interface FakeReply {
  status: number
  body: unknown
}

export interface SentRequest {
  method: string
  path: string
  authorization: string | null
  body: unknown
}

export interface FakeApi {
  fetch: typeof fetch
  sent: SentRequest[]
}

/** 경로("POST /api/v1/auth/login")별 응답을 순서대로 돌려주는 가짜 fetch. 응답이 없으면 네트워크 오류. */
export function fakeApi(replies: Record<string, FakeReply[]>): FakeApi {
  const sent: SentRequest[] = []
  const fetchImpl = vi.fn(async (input: RequestInfo | URL): Promise<Response> => {
    const request: Request = input as Request
    const path: string = new URL(request.url).pathname
    const text: string = await request.text()
    sent.push({
      method: request.method,
      path,
      authorization: request.headers.get('Authorization'),
      body: text === '' ? null : JSON.parse(text),
    })
    const reply: FakeReply | undefined = replies[`${request.method} ${path}`]?.shift()
    if (reply === undefined) {
      throw new TypeError('Failed to fetch')
    }
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
