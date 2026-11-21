import createClient, {
  type Client,
  type Middleware,
  type MiddlewareCallbackParams,
} from 'openapi-fetch'
import type { paths } from './schema'

export type ApiClient = Client<paths>

export interface ApiClientOptions {
  baseUrl: string
  /** 저장된 accessToken. 없으면 null(로그인 전). */
  getAccessToken: () => string | null
  fetch?: typeof fetch
}

/** `docs/api/openapi.yaml`의 경로와 타입을 그대로 쓰는 API 클라이언트. */
export function createApiClient(options: ApiClientOptions): ApiClient {
  const client: ApiClient = createClient<paths>({
    baseUrl: options.baseUrl,
    fetch: options.fetch,
  })
  client.use(commonHeaders(options.getAccessToken))
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
