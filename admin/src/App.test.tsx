import { render, screen } from '@testing-library/react'
import userEvent, { type UserEvent } from '@testing-library/user-event'
import { afterEach, describe, expect, it } from 'vitest'
import indexHtml from '../index.html?raw'
import App from './App'
import { loadAuth, saveAuth } from './auth/storage'
import { apiError, fakeApi, loginOk, userPage, type FakeApi } from './test/fakeApi'

async function login(user: UserEvent, loginId: string): Promise<void> {
  await user.type(screen.getByLabelText('아이디'), loginId)
  await user.type(screen.getByLabelText('비밀번호'), 'password1')
  await user.click(screen.getByRole('button', { name: '로그인' }))
}

describe('App', () => {
  afterEach((): void => {
    sessionStorage.clear()
  })

  it('로그인 전에는 Primer 기본 스타일 안에서 로그인 화면을 그린다', () => {
    render(<App />)

    const heading: HTMLElement = screen.getByRole('heading', { level: 1, name: 'Iris' })
    expect(heading.closest('[data-component="BaseStyles"]')).not.toBeNull()
  })

  it('관리자로 로그인하면 로그인 상태를 저장하고 관리자 화면으로 간다', async () => {
    const api: FakeApi = fakeApi({ 'POST /api/v1/auth/login': [loginOk('admin', 'admin-tk')] })
    render(<App fetch={api.fetch} />)

    await login(userEvent.setup(), 'admin')

    expect(await screen.findByRole('heading', { level: 1, name: 'Iris 관리자' })).toBeInTheDocument()
    expect(screen.getByText('admin')).toBeInTheDocument()
    expect(loadAuth()).toEqual({ accessToken: 'admin-tk', loginId: 'admin' })
  })

  it('사용자 계정으로는 로그인 상태를 저장하지 않고 로그인 화면에 남는다', async () => {
    const api: FakeApi = fakeApi({ 'POST /api/v1/auth/login': [loginOk('user')] })
    render(<App fetch={api.fetch} />)

    await login(userEvent.setup(), 'user01')

    expect(await screen.findByRole('alert')).toHaveTextContent('관리자 계정만 로그인할 수 있습니다.')
    expect(screen.queryByRole('heading', { name: 'Iris 관리자' })).toBeNull()
    expect(loadAuth()).toBeNull()
  })

  it('이 탭에 로그인 상태가 있으면 바로 관리자 화면이다', () => {
    saveAuth({ accessToken: 'tk', loginId: 'admin' })
    render(<App />)

    expect(screen.getByRole('heading', { level: 1, name: 'Iris 관리자' })).toBeInTheDocument()
    expect(screen.getByText('admin')).toBeInTheDocument()
  })
})

describe('App 인증 오류', () => {
  afterEach((): void => {
    sessionStorage.clear()
  })

  it('관리자 API가 토큰을 받지 않으면 로그인 상태를 지우고 로그인 화면에서 다시 로그인하라고 안내한다', async () => {
    saveAuth({ accessToken: 'expired', loginId: 'admin' })
    const api: FakeApi = fakeApi({
      'GET /api/v1/admin/users': [apiError(401, 'UNAUTHORIZED', '다시 로그인해 주세요.')],
    })
    render(<App fetch={api.fetch} />)

    expect(await screen.findByRole('alert')).toHaveTextContent('다시 로그인해 주세요.')
    expect(screen.getByRole('button', { name: '로그인' })).toBeInTheDocument()
    expect(loadAuth()).toBeNull()
  })

  it('관리자 API가 권한 없음(FORBIDDEN)이면 같은 방식으로 로그인 화면에 보낸다', async () => {
    saveAuth({ accessToken: 'user-token', loginId: 'someone' })
    const api: FakeApi = fakeApi({
      'GET /api/v1/admin/users': [apiError(403, 'FORBIDDEN', '권한이 없습니다.')],
    })
    render(<App fetch={api.fetch} />)

    expect(await screen.findByRole('alert')).toHaveTextContent('다시 로그인해 주세요.')
    expect(loadAuth()).toBeNull()
  })

  it('관리자로 로그인하면 계정 목록을 받는다', async () => {
    const api: FakeApi = fakeApi({
      'POST /api/v1/auth/login': [loginOk('admin', 'admin-tk')],
      'GET /api/v1/admin/users': [userPage([])],
    })
    render(<App fetch={api.fetch} />)

    await login(userEvent.setup(), 'admin')

    expect(await screen.findByText('등록한 사용자 계정이 없습니다')).toBeInTheDocument()
    expect(api.sent[1].authorization).toBe('Bearer admin-tk')
  })
})

describe('index.html', () => {
  it('html 요소가 기기 설정을 따르는 Primer 테마 속성을 가진다', () => {
    const htmlTag: string = indexHtml.match(/<html[^>]*>/)?.[0] ?? ''

    expect(htmlTag).toContain('lang="ko"')
    expect(htmlTag).toContain('data-color-mode="auto"')
    expect(htmlTag).toContain('data-light-theme="light"')
    expect(htmlTag).toContain('data-dark-theme="dark"')
  })
})
