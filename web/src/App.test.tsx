import { render, screen } from '@testing-library/react'
import userEvent, { type UserEvent } from '@testing-library/user-event'
import { beforeEach, describe, expect, it } from 'vitest'
import indexHtml from '../index.html?raw'
import App from './App'
import { loadAuth, saveAuth } from './auth/storage'
import { apiError, fakeApi, type FakeApi, type FakeReply } from './test/fakeApi'

function renderApp(replies: Record<string, FakeReply[]> = {}): { api: FakeApi; user: UserEvent } {
  const api: FakeApi = fakeApi(replies)
  render(<App fetch={api.fetch} />)
  return { api, user: userEvent.setup() }
}

async function login(user: UserEvent, loginId: string, password: string): Promise<void> {
  await user.type(screen.getByLabelText('아이디'), loginId)
  await user.type(screen.getByLabelText('비밀번호'), password)
  await user.click(screen.getByRole('button', { name: '로그인' }))
}

async function changeSettingsPassword(user: UserEvent): Promise<void> {
  await user.click(screen.getByRole('button', { name: '설정' }))
  await user.type(screen.getByLabelText('현재 비밀번호'), 'old-password')
  await user.type(screen.getByLabelText('새 비밀번호'), 'new-password')
  await user.type(screen.getByLabelText('새 비밀번호 확인'), 'new-password')
  await user.click(screen.getByRole('button', { name: '비밀번호 변경' }))
}

describe('App', () => {
  beforeEach((): void => {
    localStorage.clear()
  })

  it('저장한 토큰이 없으면 Primer 기본 스타일 안에서 로그인 화면을 그린다', () => {
    renderApp()

    const heading: HTMLElement = screen.getByRole('heading', { level: 1, name: 'Iris' })
    expect(heading.closest('[data-component="BaseStyles"]')).not.toBeNull()
    expect(screen.getByRole('button', { name: '로그인' })).toBeInTheDocument()
  })

  it('임시 비밀번호로 로그인하면 변경 화면이 뜨고, 바꾸면 채팅 자리로 간다', async () => {
    const { api, user } = renderApp({
      'POST /api/v1/auth/login': [
        { status: 200, body: { accessToken: 'temp-tk', role: 'user', passwordChangeRequired: true } },
      ],
      'POST /api/v1/auth/password': [{ status: 200, body: { accessToken: 'new-tk' } }],
    })

    await login(user, 'user01', 'temp-pass')
    expect(await screen.findByRole('heading', { name: '비밀번호 변경' })).toBeInTheDocument()
    expect(loadAuth()).toEqual({ accessToken: 'temp-tk', passwordChangeRequired: true, loginId: 'user01' })

    await user.type(screen.getByLabelText('새 비밀번호'), 'new-password')
    await user.type(screen.getByLabelText('새 비밀번호 확인'), 'new-password')
    await user.click(screen.getByRole('button', { name: '변경하고 계속하기' }))

    expect(await screen.findByRole('button', { name: '설정' })).toBeInTheDocument()
    expect(api.sent[1].authorization).toBe('Bearer temp-tk')
    expect(loadAuth()).toEqual({ accessToken: 'new-tk', passwordChangeRequired: false, loginId: 'user01' })
  })

  it('비밀번호를 바꾸기 전에 새로고침해도 변경 화면이 다시 뜬다', () => {
    saveAuth({ accessToken: 'temp-tk', passwordChangeRequired: true, loginId: 'user01' })

    renderApp()

    expect(screen.getByRole('button', { name: '변경하고 계속하기' })).toBeInTheDocument()
  })

  it('로그인한 상태면 채팅 자리에서 시작하고, 설정에서 비밀번호를 바꾸면 새 토큰을 저장한다', async () => {
    saveAuth({ accessToken: 'tk', passwordChangeRequired: false, loginId: 'user01' })
    const { api, user } = renderApp({
      'POST /api/v1/auth/password': [{ status: 200, body: { accessToken: 'new-tk' } }],
    })

    await changeSettingsPassword(user)

    expect(await screen.findByRole('status')).toHaveTextContent('비밀번호를 변경했습니다.')
    expect(api.sent[0].authorization).toBe('Bearer tk')
    expect(loadAuth()?.accessToken).toBe('new-tk')
  })

  it('요청 중 차단됨을 받으면 토큰을 지우고 로그인 화면에서 차단 안내를 보여준다', async () => {
    saveAuth({ accessToken: 'tk', passwordChangeRequired: false, loginId: 'user01' })
    const { user } = renderApp({
      'POST /api/v1/auth/password': [apiError(403, 'ACCOUNT_BLOCKED', '차단된 계정입니다.')],
    })

    await changeSettingsPassword(user)

    expect(await screen.findByRole('button', { name: '로그인' })).toBeInTheDocument()
    expect(screen.getByRole('alert')).toHaveTextContent('차단된 계정입니다. 관리자에게 문의해 주세요.')
    expect(loadAuth()).toBeNull()
  })

  it('토큰이 무효(UNAUTHORIZED)가 되면 토큰을 지우고 다시 로그인하라고 안내한다', async () => {
    saveAuth({ accessToken: 'old-tk', passwordChangeRequired: false, loginId: 'user01' })
    const { user } = renderApp({
      'POST /api/v1/auth/password': [apiError(401, 'UNAUTHORIZED', '다시 로그인해 주세요.')],
    })

    await changeSettingsPassword(user)

    expect(await screen.findByRole('button', { name: '로그인' })).toBeInTheDocument()
    expect(screen.getByRole('alert')).toHaveTextContent('다시 로그인해 주세요.')
    expect(loadAuth()).toBeNull()
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
