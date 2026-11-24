import { render, screen } from '@testing-library/react'
import userEvent, { type UserEvent } from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { createApiClient, type ApiClient } from '../api/client'
import type { StoredAuth } from '../auth/storage'
import { apiError, fakeApi, loginOk, type FakeApi, type FakeReply } from '../test/fakeApi'
import { LoginScreen } from './LoginScreen'

interface Setup {
  api: FakeApi
  onLoggedIn: (auth: StoredAuth) => void
  user: UserEvent
}

function setup(loginReplies: FakeReply[]): Setup {
  const api: FakeApi = fakeApi({ 'POST /api/v1/auth/login': loginReplies })
  const client: ApiClient = createApiClient({
    baseUrl: 'http://localhost:8000',
    getAccessToken: (): string | null => null,
    fetch: api.fetch,
  })
  const onLoggedIn = vi.fn<(auth: StoredAuth) => void>()
  render(<LoginScreen client={client} onLoggedIn={onLoggedIn} />)
  return { api, onLoggedIn, user: userEvent.setup() }
}

async function submit(user: UserEvent, loginId: string, password: string): Promise<void> {
  await user.type(screen.getByLabelText('아이디'), loginId)
  await user.type(screen.getByLabelText('비밀번호'), password)
  await user.click(screen.getByRole('button', { name: '로그인' }))
}

const NOT_ADMIN: string = '관리자 계정만 로그인할 수 있습니다.'

describe('LoginScreen', () => {
  it('샘플(#4)의 로그인 화면 요소가 있다', () => {
    setup([])

    expect(screen.getByRole('heading', { level: 1, name: 'Iris' })).toBeInTheDocument()
    expect(screen.getByText('관리자 웹')).toBeInTheDocument()
    expect(screen.getByLabelText('아이디')).toHaveAttribute('autocomplete', 'username')
    expect(screen.getByLabelText('비밀번호')).toHaveAttribute('type', 'password')
    expect(screen.getByLabelText('비밀번호')).toHaveAttribute('autocomplete', 'current-password')
    expect(screen.getByRole('button', { name: '로그인' })).toBeInTheDocument()
    expect(screen.queryByRole('alert')).toBeNull()
  })

  it('관리자 계정이면 토큰과 아이디를 넘긴다', async () => {
    const { api, onLoggedIn, user } = setup([loginOk('admin', 'admin-tk')])

    await submit(user, 'admin', 'admin-pass')

    expect(api.sent[0].body).toEqual({ loginId: 'admin', password: 'admin-pass' })
    expect(onLoggedIn).toHaveBeenCalledWith({ accessToken: 'admin-tk', loginId: 'admin' })
  })

  it('사용자 계정이면 넘기지 않고 관리자 계정만 로그인할 수 있다고 안내한다', async () => {
    const { onLoggedIn, user } = setup([loginOk('user')])

    await submit(user, 'user01', 'password1')

    expect(await screen.findByRole('alert')).toHaveTextContent(NOT_ADMIN)
    expect(onLoggedIn).not.toHaveBeenCalled()
  })

  it('차단된 사용자 계정도 같은 문구로 안내한다', async () => {
    const { onLoggedIn, user } = setup([apiError(403, 'ACCOUNT_BLOCKED', '차단된 계정입니다.')])

    await submit(user, 'user01', 'password1')

    expect(await screen.findByRole('alert')).toHaveTextContent(NOT_ADMIN)
    expect(onLoggedIn).not.toHaveBeenCalled()
  })

  it('아이디나 비밀번호가 틀리면 규격의 문구를 그대로 보여 준다', async () => {
    const { user } = setup([apiError(401, 'INVALID_CREDENTIALS', '아이디 또는 비밀번호가 올바르지 않습니다.')])

    await submit(user, 'admin', 'wrong')

    expect(await screen.findByRole('alert')).toHaveTextContent('아이디 또는 비밀번호가 올바르지 않습니다.')
  })

  it('서버에 연결하지 못하면 서버 오류로 안내한다', async () => {
    const { user } = setup([])

    await submit(user, 'admin', 'admin-pass')

    expect(await screen.findByRole('alert')).toHaveTextContent('서버 오류가 발생했습니다.')
  })

  it('규격 모양이 아닌 오류 응답(터널이 꺼졌을 때의 HTML 등)은 서버 오류로 안내한다', async () => {
    const { user } = setup([{ status: 502, body: 'Bad Gateway' }])

    await submit(user, 'admin', 'admin-pass')

    expect(await screen.findByRole('alert')).toHaveTextContent('서버 오류가 발생했습니다.')
  })

  it('다시 제출하면 응답을 기다리는 동안 이전 안내를 지운다', async () => {
    const wait: Promise<void> = new Promise<void>((): void => {})
    const { user } = setup([loginOk('user'), { ...loginOk('admin'), wait }])

    await submit(user, 'user01', 'password1')
    expect(await screen.findByRole('alert')).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: '로그인' }))

    await vi.waitFor((): void => expect(screen.queryByRole('alert')).toBeNull())
  })

  it('화면의 주 영역(main)이다', () => {
    setup([])

    expect(screen.getByRole('main')).toContainElement(screen.getByRole('heading', { level: 1, name: 'Iris' }))
  })

  it('응답을 기다리는 동안 다시 제출해도 한 번만 보낸다', async () => {
    let release: () => void = (): void => {}
    const wait: Promise<void> = new Promise<void>((resolve: () => void): void => {
      release = resolve
    })
    const { api, onLoggedIn, user } = setup([{ ...loginOk('admin'), wait }])

    await user.type(screen.getByLabelText('아이디'), 'admin')
    await user.type(screen.getByLabelText('비밀번호'), 'admin-pass{Enter}')
    await user.type(screen.getByLabelText('비밀번호'), '{Enter}')
    release()

    await vi.waitFor((): void => expect(onLoggedIn).toHaveBeenCalledTimes(1))
    expect(api.sent).toHaveLength(1)
  })
})
