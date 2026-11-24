const DEFAULT_API_BASE_URL: string = 'http://localhost:8000'

/** 백엔드 주소. 설정(`VITE_API_BASE_URL`)이 없으면 로컬 백엔드를 쓴다. */
export function resolveApiBaseUrl(configured: string | undefined): string {
  const trimmed: string = (configured ?? '').trim()
  if (trimmed === '') {
    return DEFAULT_API_BASE_URL
  }
  return trimmed.replace(/\/+$/, '')
}

export const apiBaseUrl: string = resolveApiBaseUrl(import.meta.env.VITE_API_BASE_URL)
