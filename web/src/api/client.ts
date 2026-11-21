import createClient, {
  type Client,
  type Middleware,
  type MiddlewareCallbackParams,
} from 'openapi-fetch'
import type { components, paths } from './schema'

export type ApiClient = Client<paths>
export type ErrorCode = components['schemas']['ErrorCode']
export type ErrorResponse = components['schemas']['ErrorResponse']

/** 어느 API에서 받든 로그인 상태를 바꿔야 하는 오류. */
export type AuthErrorCode = Extract<
  ErrorCode,
  'UNAUTHORIZED' | 'ACCOUNT_BLOCKED' | 'PASSWORD_CHANGE_REQUIRED'
>

const AUTH_ERROR_CODES: readonly AuthErrorCode[] = [
  'UNAUTHORIZED',
  'ACCOUNT_BLOCKED',
  'PASSWORD_CHANGE_REQUIRED',
]

export interface ApiClientOptions {
  baseUrl: string
  /** 저장된 accessToken. 없으면 null(로그인 전). */
  getAccessToken: () => string | null
  /** UNAUTHORIZED, ACCOUNT_BLOCKED, PASSWORD_CHANGE_REQUIRED 응답을 받으면 호출한다. */
  onAuthError?: (code: AuthErrorCode) => void
  fetch?: typeof fetch
}

/** `docs/api/openapi.yaml`의 경로와 타입을 그대로 쓰는 API 클라이언트. */
export function createApiClient(options: ApiClientOptions): ApiClient {
  const client: ApiClient = createClient<paths>({
    baseUrl: options.baseUrl,
    fetch: options.fetch,
  })
  client.use(commonHeaders(options.getAccessToken))
  if (options.onAuthError !== undefined) {
    client.use(authErrors(options.onAuthError))
  }
  return client
}

function commonHeaders(getAccessToken: () => string | null): Middleware {
  return {
    onRequest({ request }: MiddlewareCallbackParams): Request {
      // ngrok 무료 도메인의 안내 페이지를 건너뛴다. localhost에서는 영향이 없다.
      request.headers.set('ngrok-skip-browser-warning', '1')
      const token: string | null = getAccessToken()
      if (token !== null) {
        request.headers.set('Authorization', `Bearer ${token}`)
      }
      return request
    },
  }
}

function authErrors(onAuthError: (code: AuthErrorCode) => void): Middleware {
  return {
    async onResponse({ response }: MiddlewareCallbackParams & { response: Response }): Promise<undefined> {
      if (response.status !== 401 && response.status !== 403) {
        return undefined
      }
      const code: string | null = await readErrorCode(response.clone())
      const match: AuthErrorCode | undefined = AUTH_ERROR_CODES.find((c: AuthErrorCode) => c === code)
      if (match !== undefined) {
        onAuthError(match)
      }
      return undefined
    },
  }
}

async function readErrorCode(response: Response): Promise<string | null> {
  try {
    const body: ErrorResponse = (await response.json()) as ErrorResponse
    return body.error.code
  } catch {
    return null
  }
}
