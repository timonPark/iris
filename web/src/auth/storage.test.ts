import { beforeEach, describe, expect, it } from 'vitest'
import { AUTH_STORAGE_KEY, clearAuth, loadAuth, saveAuth, type StoredAuth } from './storage'

const auth: StoredAuth = { accessToken: 't1', passwordChangeRequired: false, loginId: 'user01' }

describe('auth storage', () => {
  beforeEach((): void => {
    localStorage.clear()
  })

  it('저장한 값을 다시 읽는다(localStorage)', () => {
    saveAuth(auth)

    expect(loadAuth()).toEqual(auth)
    expect(localStorage.getItem(AUTH_STORAGE_KEY)).not.toBeNull()
  })

  it('저장한 값이 없으면 null', () => {
    expect(loadAuth()).toBeNull()
  })

  it('지우면 null', () => {
    saveAuth(auth)
    clearAuth()

    expect(loadAuth()).toBeNull()
  })

  it('모양이 맞지 않는 값은 무시하고 null', () => {
    localStorage.setItem(AUTH_STORAGE_KEY, '{"accessToken":1}')
    expect(loadAuth()).toBeNull()

    localStorage.setItem(AUTH_STORAGE_KEY, 'not json')
    expect(loadAuth()).toBeNull()
  })
})
