/** 로그인 상태. 탭을 닫으면 로그아웃되도록 sessionStorage에 둔다(ssot/GLOSSARY.md "관리자 웹", #20에서 정함). */
export interface StoredAuth {
  accessToken: string
  /** 로그인할 때 입력한 아이디. 머리글에 보여 준다. */
  loginId: string
}

export const AUTH_STORAGE_KEY: string = 'iris.admin.auth'

export function saveAuth(auth: StoredAuth): void {
  sessionStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(auth))
}

export function clearAuth(): void {
  sessionStorage.removeItem(AUTH_STORAGE_KEY)
}

export function loadAuth(): StoredAuth | null {
  const raw: string | null = sessionStorage.getItem(AUTH_STORAGE_KEY)
  if (raw === null) {
    return null
  }
  try {
    const value: unknown = JSON.parse(raw)
    return isStoredAuth(value) ? value : null
  } catch {
    return null
  }
}

function isStoredAuth(value: unknown): value is StoredAuth {
  if (typeof value !== 'object' || value === null) {
    return false
  }
  const v: Record<string, unknown> = value as Record<string, unknown>
  return typeof v.accessToken === 'string' && typeof v.loginId === 'string'
}
