import { afterEach, describe, expect, it } from 'vitest'
import { AUTH_STORAGE_KEY, clearAuth, loadAuth, saveAuth } from './storage'

describe('로그인 상태 저장', () => {
  afterEach((): void => {
    sessionStorage.clear()
    localStorage.clear()
  })

  it('탭에만 둔다(sessionStorage). 브라우저를 닫으면 사라진다', () => {
    saveAuth({ accessToken: 'tk', loginId: 'admin' })

    expect(loadAuth()).toEqual({ accessToken: 'tk', loginId: 'admin' })
    expect(sessionStorage.getItem(AUTH_STORAGE_KEY)).not.toBeNull()
    expect(localStorage.length).toBe(0)
  })

  it('저장한 적이 없으면 로그인 전이다', () => {
    expect(loadAuth()).toBeNull()
  })

  it('지우면 로그인 전 상태다', () => {
    saveAuth({ accessToken: 'tk', loginId: 'admin' })
    clearAuth()

    expect(loadAuth()).toBeNull()
  })

  it('모양이 다르거나 깨진 값은 로그인 전으로 본다', () => {
    sessionStorage.setItem(AUTH_STORAGE_KEY, '{"accessToken":1}')
    expect(loadAuth()).toBeNull()

    sessionStorage.setItem(AUTH_STORAGE_KEY, 'not-json')
    expect(loadAuth()).toBeNull()
  })
})
