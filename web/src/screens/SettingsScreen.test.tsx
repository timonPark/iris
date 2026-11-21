import { render, screen } from '@testing-library/react'
import userEvent, { type UserEvent } from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { createApiClient, type ApiClient } from '../api/client'
import { apiError, fakeApi, type FakeApi, type FakeReply } from '../test/fakeApi'
import { SettingsScreen } from './SettingsScreen'

interface Setup {
  api: FakeApi
  onChanged: (accessToken: string) => void
  user: UserEvent
}

function setup(replies: FakeReply[]): Setup {
  const api: FakeApi = fakeApi({ 'POST /api/v1/auth/password': replies })
  const client: ApiClient = createApiClient({
    baseUrl: 'http://localhost:8000',
    getAccessToken: (): string | null => 'tk',
    fetch: api.fetch,
  })
  const onChanged = vi.fn<(accessToken: string) => void>()
  render(<SettingsScreen client={client} onChanged={onChanged} />)
  return { api, onChanged, user: userEvent.setup() }
}

async function submit(user: UserEvent, current: string, next: string, confirm: string): Promise<void> {
  await user.type(screen.getByLabelText('현재 비밀번호'), current)
  await user.type(screen.getByLabelText('새 비밀번호'), next)
  await user.type(screen.getByLabelText('새 비밀번호 확인'), confirm)
  await user.click(screen.getByRole('button', { name: '비밀번호 변경' }))
}

describe('SettingsScreen', () => {
  it('샘플(#3)의 설정 화면 요소가 있다', () => {
    setup([])

    expect(screen.getByRole('heading', { name: '설정' })).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: '비밀번호 변경' })).toBeInTheDocument()
    expect(screen.getByLabelText('현재 비밀번호')).toHaveAttribute('autocomplete', 'current-password')
    expect(screen.getByLabelText('새 비밀번호')).toHaveAccessibleDescription('8자 이상')
    expect(screen.getByLabelText('새 비밀번호 확인')).toBeInTheDocument()
  })

  it('현재 비밀번호와 새 비밀번호를 보내고, 성공하면 새 토큰을 넘기고 칸을 비운다', async () => {
    const { api, onChanged, user } = setup([{ status: 200, body: { accessToken: 'new-tk' } }])

    await submit(user, 'old-password', 'new-password', 'new-password')

    expect(api.sent[0].body).toEqual({ currentPassword: 'old-password', newPassword: 'new-password' })
    expect(onChanged).toHaveBeenCalledWith('new-tk')
    expect(await screen.findByRole('status')).toHaveTextContent('비밀번호를 변경했습니다.')
    expect(screen.getByLabelText('현재 비밀번호')).toHaveValue('')
    expect(screen.getByLabelText('새 비밀번호')).toHaveValue('')
  })

  it('현재 비밀번호가 틀리면 그렇게 안내한다', async () => {
    const { onChanged, user } = setup([
      apiError(401, 'INVALID_CREDENTIALS', '아이디 또는 비밀번호가 올바르지 않습니다.'),
    ])

    await submit(user, 'wrong-password', 'new-password', 'new-password')

    expect(onChanged).not.toHaveBeenCalled()
    expect(await screen.findByRole('alert')).toHaveTextContent('현재 비밀번호가 올바르지 않습니다.')
  })

  it('확인 값이 다르면 보내지 않는다', async () => {
    const { api, user } = setup([])

    await submit(user, 'old-password', 'new-password', 'new-passwordX')

    expect(api.sent).toEqual([])
    expect(await screen.findByRole('alert')).toHaveTextContent('새 비밀번호가 서로 다릅니다.')
  })
})
