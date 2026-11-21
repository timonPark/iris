import { describe, expect, it, vi } from 'vitest'
import { createApiClient, type ApiClient } from './client'
import type { components } from './schema'

type ErrorBody = components['schemas']['ErrorResponse']

interface Captured {
  request: Request | null
}

function fakeFetch(captured: Captured, response: Response): typeof fetch {
  return vi.fn(async (input: RequestInfo | URL): Promise<Response> => {
    captured.request = input as Request
    return response
  }) as unknown as typeof fetch
}

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

describe('createApiClient', () => {
  it('서버 주소 뒤에 규격의 경로를 붙이고, 토큰이 있으면 Bearer 헤더를 보낸다', async () => {
    const captured: Captured = { request: null }
    const client: ApiClient = createApiClient({
      baseUrl: 'https://example.ngrok-free.dev',
      getAccessToken: (): string | null => 'token-123',
      fetch: fakeFetch(captured, jsonResponse(200, { items: [] })),
    })

    const { data } = await client.GET('/api/v1/sessions')

    expect(data).toEqual({ items: [] })
    expect(captured.request?.url).toBe('https://example.ngrok-free.dev/api/v1/sessions')
    expect(captured.request?.headers.get('Authorization')).toBe('Bearer token-123')
    expect(captured.request?.headers.get('ngrok-skip-browser-warning')).toBe('1')
  })

  it('토큰이 없으면 Authorization 헤더를 보내지 않는다', async () => {
    const captured: Captured = { request: null }
    const client: ApiClient = createApiClient({
      baseUrl: 'http://localhost:8000',
      getAccessToken: (): string | null => null,
      fetch: fakeFetch(captured, jsonResponse(200, { accessToken: 't', account: {} })),
    })

    await client.POST('/api/v1/auth/login', {
      body: { loginId: 'user01', password: 'password1' },
    })

    expect(captured.request?.headers.has('Authorization')).toBe(false)
  })

  it('오류 응답은 규격의 error 모양으로 돌려준다', async () => {
    const captured: Captured = { request: null }
    const body: ErrorBody = { error: { code: 'ACCOUNT_BLOCKED', message: '차단된 계정입니다.' } }
    const client: ApiClient = createApiClient({
      baseUrl: 'http://localhost:8000',
      getAccessToken: (): string | null => 'token',
      fetch: fakeFetch(captured, jsonResponse(403, body)),
    })

    const { error } = await client.GET('/api/v1/sessions')

    expect(error?.error.code).toBe('ACCOUNT_BLOCKED')
  })
})
