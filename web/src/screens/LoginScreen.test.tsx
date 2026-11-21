import { render, screen } from '@testing-library/react'
import userEvent, { type UserEvent } from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { createApiClient, type ApiClient } from '../api/client'
import type { StoredAuth } from '../auth/storage'
import { apiError, fakeApi, type FakeApi, type FakeReply } from '../test/fakeApi'
import { LoginScreen, type LoginNotice } from './LoginScreen'

interface Setup {
  api: FakeApi
  onLoggedIn: (auth: StoredAuth) => void
  user: UserEvent
}

function setup(loginReplies: FakeReply[], notice: LoginNotice | null = null): Setup {
  const api: FakeApi = fakeApi({ 'POST /api/v1/auth/login': loginReplies })
  const client: ApiClient = createApiClient({
    baseUrl: 'http://localhost:8000',
    getAccessToken: (): string | null => null,
    fetch: api.fetch,
  })
  const onLoggedIn = vi.fn<(auth: StoredAuth) => void>()
  render(<LoginScreen client={client} notice={notice} onLoggedIn={onLoggedIn} />)
  return { api, onLoggedIn, user: userEvent.setup() }
}

async function submit(user: UserEvent, loginId: string, password: string): Promise<void> {
  await user.type(screen.getByLabelText('아이디'), loginId)
  await user.type(screen.getByLabelText('비밀번호'), password)
  await user.click(screen.getByRole('button', { name: '로그인' }))
}

describe('LoginScreen', () => {
  it('샘플(#3)의 로그인 화면 요소가 있다', () => {
    setup([])

    expect(screen.getByRole('heading', { level: 1, name: 'Iris' })).toBeInTheDocument()
    expect(screen.getByLabelText('아이디')).toHaveAttribute('autocomplete', 'username')
    expect(screen.getByLabelText('비밀번호')).toHaveAttribute('type', 'password')
    expect(screen.getByText('계정이 없으면 관리자에게 요청해 주세요.')).toBeInTheDocument()
    expect(screen.queryByRole('alert')).toBeNull()
  })

  it('로그인에 성공하면 토큰, 비밀번호 변경 필요 여부, 아이디를 넘긴다', async () => {
    const ok: FakeReply = {
      status: 200,
      body: { accessToken: 'tk', role: 'user', passwordChangeRequired: true },
    }
    const { api, onLoggedIn, user } = setup([ok])

    await submit(user, 'user01', 'temp-pass')

    expect(api.sent[0].body).toEqual({ loginId: 'user01', password: 'temp-pass' })
    expect(onLoggedIn).toHaveBeenCalledWith({
      accessToken: 'tk',
      passwordChangeRequired: true,
      loginId: 'user01',
    })
  })

  it('응답을 기다리는 동안 다시 제출해도 한 번만 보낸다', async () => {
    let release: (r: Response) => void = (): void => {}
    const pending: Promise<Response> = new Promise<Response>((resolve: (r: Response) => void): void => {
      release = resolve
    })
    const fetchImpl = vi.fn((): Promise<Response> => pending)
    const client: ApiClient = createApiClient({
      baseUrl: 'http://localhost:8000',
      getAccessToken: (): string | null => null,
      fetch: fetchImpl as unknown as typeof fetch,
    })
    const onLoggedIn = vi.fn<(auth: StoredAuth) => void>()
    render(<LoginScreen client={client} notice={null} onLoggedIn={onLoggedIn} />)
    const user: UserEvent = userEvent.setup()

    await user.type(screen.getByLabelText('아이디'), 'user01')
    await user.type(screen.getByLabelText('비밀번호'), 'password1{Enter}')
    await user.type(screen.getByLabelText('비밀번호'), '{Enter}')
    const body: string = JSON.stringify({ accessToken: 'tk', role: 'user', passwordChangeRequired: false })
    release(new Response(body, { status: 200, headers: { 'Content-Type': 'application/json' } }))

    await vi.waitFor((): void => expect(onLoggedIn).toHaveBeenCalledTimes(1))
    expect(fetchImpl).toHaveBeenCalledTimes(1)
  })

  it('관리자 계정이면 넘기지 않고 관리자 웹을 안내한다', async () => {
    const admin: FakeReply = {
      status: 200,
      body: { accessToken: 'tk', role: 'admin', passwordChangeRequired: false },
    }
    const { onLoggedIn, user } = setup([admin])

    await submit(user, 'admin', 'password1')

    expect(onLoggedIn).not.toHaveBeenCalled()
    expect(await screen.findByRole('alert')).toHaveTextContent(
      '관리자 계정은 관리자 웹을 이용해 주세요.',
    )
  })

  it('아이디나 비밀번호가 틀리면 규격의 문구를 보여준다', async () => {
    const wrong: FakeReply = apiError(
      401,
      'INVALID_CREDENTIALS',
      '아이디 또는 비밀번호가 올바르지 않습니다.',
    )
    const { onLoggedIn, user } = setup([wrong])

    await submit(user, 'user01', 'wrong-pass')

    expect(onLoggedIn).not.toHaveBeenCalled()
    expect(await screen.findByRole('alert')).toHaveTextContent(
      '아이디 또는 비밀번호가 올바르지 않습니다.',
    )
  })

  it('차단된 계정이면 차단 안내를 보여준다', async () => {
    const { user } = setup([apiError(403, 'ACCOUNT_BLOCKED', '차단된 계정입니다.')])

    await submit(user, 'user01', 'password1')

    expect(await screen.findByRole('alert')).toHaveTextContent(
      '차단된 계정입니다. 관리자에게 문의해 주세요.',
    )
  })

  it('다른 화면에서 차단되어 넘어오면 처음부터 차단 안내가 보인다', () => {
    setup([], 'blocked')

    expect(screen.getByRole('alert')).toHaveTextContent(
      '차단된 계정입니다. 관리자에게 문의해 주세요.',
    )
  })

  it('토큰이 무효가 되어 넘어오면 다시 로그인하라고 안내한다', () => {
    setup([], 'unauthorized')

    expect(screen.getByRole('alert')).toHaveTextContent('다시 로그인해 주세요.')
  })

  it('서버에 연결하지 못하면 서버 오류를 보여준다', async () => {
    const { user } = setup([])

    await submit(user, 'user01', 'password1')

    expect(await screen.findByRole('alert')).toHaveTextContent('서버 오류가 발생했습니다.')
  })
})
