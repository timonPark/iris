import { render, screen } from '@testing-library/react'
import userEvent, { type UserEvent } from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { createApiClient, type ApiClient } from '../api/client'
import { apiError, fakeApi, type FakeApi, type FakeReply } from '../test/fakeApi'
import { ForceChangeScreen } from './ForceChangeScreen'

interface Setup {
  api: FakeApi
  onChanged: (accessToken: string) => void
  user: UserEvent
}

function setup(replies: FakeReply[]): Setup {
  const api: FakeApi = fakeApi({ 'POST /api/v1/auth/password': replies })
  const client: ApiClient = createApiClient({
    baseUrl: 'http://localhost:8000',
    getAccessToken: (): string | null => 'temp-token',
    fetch: api.fetch,
  })
  const onChanged = vi.fn<(accessToken: string) => void>()
  render(<ForceChangeScreen client={client} onChanged={onChanged} />)
  return { api, onChanged, user: userEvent.setup() }
}

async function submit(user: UserEvent, newPassword: string, confirm: string): Promise<void> {
  await user.type(screen.getByLabelText('새 비밀번호'), newPassword)
  await user.type(screen.getByLabelText('새 비밀번호 확인'), confirm)
  await user.click(screen.getByRole('button', { name: '변경하고 계속하기' }))
}

describe('ForceChangeScreen', () => {
  it('샘플(#3)의 비밀번호 강제 변경 화면 요소가 있다', () => {
    setup([])

    expect(screen.getByRole('heading', { level: 1, name: '비밀번호 변경' })).toBeInTheDocument()
    expect(
      screen.getByText('임시 비밀번호로 로그인했습니다. 계속하려면 새 비밀번호로 바꿔 주세요.'),
    ).toBeInTheDocument()
    expect(screen.getByLabelText('새 비밀번호')).toHaveAccessibleDescription('8자 이상')
    expect(screen.queryByLabelText('현재 비밀번호')).toBeNull()
  })

  it('새 비밀번호만 보내고, 받은 새 토큰을 넘긴다', async () => {
    const { api, onChanged, user } = setup([{ status: 200, body: { accessToken: 'new-tk' } }])

    await submit(user, 'new-password', 'new-password')

    expect(api.sent[0].body).toEqual({ newPassword: 'new-password' })
    expect(api.sent[0].authorization).toBe('Bearer temp-token')
    expect(onChanged).toHaveBeenCalledWith('new-tk')
  })

  it('응답을 기다리는 동안 다시 제출해도 한 번만 보낸다', async () => {
    let release: (r: Response) => void = (): void => {}
    const pending: Promise<Response> = new Promise<Response>((resolve: (r: Response) => void): void => {
      release = resolve
    })
    const fetchImpl = vi.fn((): Promise<Response> => pending)
    const client: ApiClient = createApiClient({
      baseUrl: 'http://localhost:8000',
      getAccessToken: (): string | null => 'temp-token',
      fetch: fetchImpl as unknown as typeof fetch,
    })
    const onChanged = vi.fn<(accessToken: string) => void>()
    render(<ForceChangeScreen client={client} onChanged={onChanged} />)
    const user: UserEvent = userEvent.setup()

    await user.type(screen.getByLabelText('새 비밀번호'), 'new-password')
    await user.type(screen.getByLabelText('새 비밀번호 확인'), 'new-password{Enter}')
    await user.type(screen.getByLabelText('새 비밀번호 확인'), '{Enter}')
    release(new Response(JSON.stringify({ accessToken: 'new-tk' }), { status: 200, headers: { 'Content-Type': 'application/json' } }))

    await vi.waitFor((): void => expect(onChanged).toHaveBeenCalledTimes(1))
    expect(fetchImpl).toHaveBeenCalledTimes(1)
  })

  it('확인 값이 다르면 보내지 않고 안내한다', async () => {
    const { api, onChanged, user } = setup([])

    await submit(user, 'new-password', 'other-password')

    expect(api.sent).toEqual([])
    expect(onChanged).not.toHaveBeenCalled()
    expect(await screen.findByRole('alert')).toHaveTextContent('새 비밀번호가 서로 다릅니다.')
  })

  it('8자 미만이면 보내지 않고 안내한다', async () => {
    const { api, user } = setup([])

    await submit(user, 'short', 'short')

    expect(api.sent).toEqual([])
    expect(await screen.findByRole('alert')).toHaveTextContent(
      '새 비밀번호는 8자 이상이어야 합니다.',
    )
  })

  it('규격 오류는 받은 문구를 보여준다(임시 비밀번호와 같은 값 등)', async () => {
    const { onChanged, user } = setup([
      apiError(422, 'VALIDATION_FAILED', '입력 값을 확인해 주세요.'),
    ])

    await submit(user, 'temp-pass1', 'temp-pass1')

    expect(onChanged).not.toHaveBeenCalled()
    expect(await screen.findByRole('alert')).toHaveTextContent('입력 값을 확인해 주세요.')
  })
})
