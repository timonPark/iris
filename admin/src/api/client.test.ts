import { describe, expect, it, vi } from 'vitest'
import { createApiClient, type ApiClient, type AuthErrorCode, type ErrorResponse } from './client'

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
  it('서버 주소 뒤에 관리자 API 경로를 붙이고, 토큰이 있으면 Bearer 헤더를 보낸다', async () => {
    const captured: Captured = { request: null }
    const client: ApiClient = createApiClient({
      baseUrl: 'https://example.ngrok-free.dev',
      getAccessToken: (): string | null => 'admin-token',
      fetch: fakeFetch(captured, jsonResponse(200, { items: [] })),
    })

    const { data } = await client.GET('/api/v1/admin/users')

    expect(data).toEqual({ items: [] })
    expect(captured.request?.url).toBe('https://example.ngrok-free.dev/api/v1/admin/users')
    expect(captured.request?.headers.get('Authorization')).toBe('Bearer admin-token')
    expect(captured.request?.headers.get('ngrok-skip-browser-warning')).toBe('1')
  })

  it('토큰이 없으면 Authorization 헤더를 보내지 않는다', async () => {
    const captured: Captured = { request: null }
    const client: ApiClient = createApiClient({
      baseUrl: 'http://localhost:8000',
      getAccessToken: (): string | null => null,
      fetch: fakeFetch(captured, jsonResponse(200, { accessToken: 't', role: 'admin', passwordChangeRequired: false })),
    })

    await client.POST('/api/v1/auth/login', {
      body: { loginId: 'admin', password: 'password1' },
    })

    expect(captured.request?.headers.has('Authorization')).toBe(false)
    expect(captured.request?.headers.get('ngrok-skip-browser-warning')).toBe('1')
  })

  it('오류 응답은 규격의 error 모양으로 돌려준다', async () => {
    const captured: Captured = { request: null }
    const body: ErrorResponse = { error: { code: 'FORBIDDEN', message: '권한이 없습니다.' } }
    const client: ApiClient = createApiClient({
      baseUrl: 'http://localhost:8000',
      getAccessToken: (): string | null => 'user-token',
      fetch: fakeFetch(captured, jsonResponse(403, body)),
    })

    const { error } = await client.GET('/api/v1/admin/users')

    expect(error?.error.code).toBe('FORBIDDEN')
  })

  it('관리자 API가 UNAUTHORIZED·FORBIDDEN이면 onAuthError를 부르고, 그 밖의 오류는 부르지 않는다', async () => {
    const seen: string[] = []
    const replies: Response[] = [
      jsonResponse(401, { error: { code: 'UNAUTHORIZED', message: '다시 로그인해 주세요.' } }),
      jsonResponse(403, { error: { code: 'FORBIDDEN', message: '권한이 없습니다.' } }),
      jsonResponse(404, { error: { code: 'USER_NOT_FOUND', message: '계정을 찾을 수 없습니다.' } }),
    ]
    const client: ApiClient = createApiClient({
      baseUrl: 'http://localhost:8000',
      getAccessToken: (): string | null => 'tk',
      onAuthError: (code: AuthErrorCode): void => { seen.push(code) },
      fetch: vi.fn(async (): Promise<Response> => replies.shift() as Response) as unknown as typeof fetch,
    })

    await client.GET('/api/v1/admin/users')
    await client.GET('/api/v1/admin/users')
    await client.POST('/api/v1/admin/users/{userId}/block', { params: { path: { userId: 'x' } } })

    expect(seen).toEqual(['UNAUTHORIZED', 'FORBIDDEN'])
  })

  it('로그인 요청의 오류에는 onAuthError를 부르지 않는다(로그인 화면이 직접 안내한다)', async () => {
    const seen: string[] = []
    const client: ApiClient = createApiClient({
      baseUrl: 'http://localhost:8000',
      getAccessToken: (): string | null => null,
      onAuthError: (code: AuthErrorCode): void => { seen.push(code) },
      fetch: vi.fn(async (): Promise<Response> =>
        jsonResponse(403, { error: { code: 'FORBIDDEN', message: '권한이 없습니다.' } })) as unknown as typeof fetch,
    })

    await client.POST('/api/v1/auth/login', { body: { loginId: 'a', password: 'b' } })

    expect(seen).toEqual([])
  })
})
