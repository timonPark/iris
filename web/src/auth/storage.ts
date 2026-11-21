/** 로그인 상태. 브라우저를 닫았다 열어도 유지되도록 localStorage에 둔다(#18에서 사용자와 정함). */
export interface StoredAuth {
  accessToken: string
  /** 임시 비밀번호 상태. true면 비밀번호 강제 변경 화면만 쓸 수 있다. */
  passwordChangeRequired: boolean
  /** 로그인할 때 입력한 아이디. 사이드바 아래에 보여준다(#24). */
  loginId: string
}

export const AUTH_STORAGE_KEY: string = 'iris.auth'

export function saveAuth(auth: StoredAuth): void {
  localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(auth))
}

export function clearAuth(): void {
  localStorage.removeItem(AUTH_STORAGE_KEY)
}

export function loadAuth(): StoredAuth | null {
  const raw: string | null = localStorage.getItem(AUTH_STORAGE_KEY)
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
  return (
    typeof v.accessToken === 'string' &&
    typeof v.passwordChangeRequired === 'boolean' &&
    typeof v.loginId === 'string'
  )
}
