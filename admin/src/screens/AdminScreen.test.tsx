import { render, screen, within } from '@testing-library/react'
import userEvent, { type UserEvent } from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { createApiClient, type ApiClient } from '../api/client'
import { apiError, fakeApi, userOf, userPage, type FakeApi, type FakeReply } from '../test/fakeApi'
import { AdminScreen } from './AdminScreen'

interface Setup {
  api: FakeApi
  user: UserEvent
}

function setup(replies: Record<string, FakeReply[]>): Setup {
  const api: FakeApi = fakeApi(replies)
  const client: ApiClient = createApiClient({
    baseUrl: 'http://localhost:8000',
    getAccessToken: (): string | null => 'admin-tk',
    fetch: api.fetch,
  })
  render(<AdminScreen client={client} loginId="admin" />)
  return { api, user: userEvent.setup() }
}

const LIST: string = 'GET /api/v1/admin/users'

function row(loginId: string): HTMLElement {
  return screen.getByRole('rowheader', { name: loginId }).closest('tr') as HTMLElement
}

describe('AdminScreen 목록', () => {
  it('샘플(#4)의 머리글, 제목, 등록 버튼과 계정 목록을 보여 준다', async () => {
    const { api } = setup({
      [LIST]: [userPage([
        userOf('kimdh', { passwordChangeRequired: true, createdAt: '2026-11-21T01:00:00Z' }),
        userOf('leesy', { status: 'blocked' }),
      ])],
    })

    expect(screen.getByRole('heading', { level: 1, name: 'Iris 관리자' })).toBeInTheDocument()
    expect(screen.getByRole('heading', { level: 2, name: '사용자 계정' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: '계정 등록' })).toBeInTheDocument()
    await screen.findByRole('rowheader', { name: 'kimdh' })
    expect(api.sent[0].query).toBe('?limit=20')
    expect(screen.getAllByRole('columnheader').map((c: HTMLElement): string => c.textContent ?? ''))
      .toEqual(['아이디', '상태', '비밀번호', '등록일', '작업'])
    const kim: HTMLElement = row('kimdh')
    expect(within(kim).getByText('활성')).toBeInTheDocument()
    expect(within(kim).getByText('임시 비밀번호')).toBeInTheDocument()
    expect(within(kim).getByText('2026-11-21')).toBeInTheDocument()
    expect(within(kim).getByRole('button', { name: 'kimdh 차단' })).toBeInTheDocument()
    expect(within(kim).getByRole('button', { name: 'kimdh 비밀번호 초기화' })).toBeInTheDocument()
    const lee: HTMLElement = row('leesy')
    expect(within(lee).getByText('차단 중')).toBeInTheDocument()
    expect(within(lee).getByText('설정함')).toBeInTheDocument()
    expect(within(lee).getByRole('button', { name: 'leesy 차단 해제' })).toBeInTheDocument()
  })

  it('다음 페이지가 있으면 "더 보기"로 이어 받고, 끝이면 버튼이 사라진다', async () => {
    const { api, user } = setup({ [LIST]: [userPage([userOf('first')], 'c1'), userPage([userOf('second')])] })

    await user.click(await screen.findByRole('button', { name: '더 보기' }))

    expect(await screen.findByRole('rowheader', { name: 'second' })).toBeInTheDocument()
    expect(screen.getByRole('rowheader', { name: 'first' })).toBeInTheDocument()
    expect(api.sent[1].query).toBe('?cursor=c1&limit=20')
    expect(screen.queryByRole('button', { name: '더 보기' })).toBeNull()
  })

  it('계정이 없으면 빈 목록 안내를 보여 준다', async () => {
    setup({ [LIST]: [userPage([])] })

    expect(await screen.findByText('등록한 사용자 계정이 없습니다')).toBeInTheDocument()
    expect(screen.getByText('계정을 등록하면 임시 비밀번호가 만들어집니다. 사용자에게 아이디와 함께 전달해 주세요.')).toBeInTheDocument()
    expect(screen.queryByRole('table')).toBeNull()
  })

  it('목록을 받지 못하면 오류와 "다시 시도"를 보여 주고, 다시 시도하면 다시 받는다', async () => {
    const { user } = setup({ [LIST]: [apiError(500, 'SERVER_ERROR', '서버 오류가 발생했습니다.'), userPage([userOf('kimdh')])] })

    expect(await screen.findByRole('alert')).toHaveTextContent('서버 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.')
    await user.click(screen.getByRole('button', { name: '다시 시도' }))

    expect(await screen.findByRole('rowheader', { name: 'kimdh' })).toBeInTheDocument()
    expect(screen.queryByRole('alert')).toBeNull()
  })
})

describe('AdminScreen 느린 응답', () => {
  it('목록을 받는 동안에는 계정 등록을 막는다(늦게 온 목록이 새 계정을 덮지 않게)', async () => {
    let release: () => void = (): void => {}
    const wait: Promise<void> = new Promise<void>((resolve: () => void): void => { release = resolve })
    setup({ [LIST]: [{ ...userPage([userOf('old')]), wait }] })

    expect(screen.getByRole('button', { name: '계정 등록' })).toBeDisabled()
    release()

    await screen.findByRole('rowheader', { name: 'old' })
    expect(screen.getByRole('button', { name: '계정 등록' })).toBeEnabled()
  })

  it('확인한 작업을 기다리는 동안에는 대화상자를 닫지 않는다', async () => {
    let release: () => void = (): void => {}
    const wait: Promise<void> = new Promise<void>((resolve: () => void): void => { release = resolve })
    const { user } = setup({
      [LIST]: [userPage([userOf('jhpark')])],
      'POST /api/v1/admin/users/id-jhpark/block': [{ status: 200, body: userOf('jhpark', { status: 'blocked' }), wait }],
    })

    await user.click(await screen.findByRole('button', { name: 'jhpark 차단' }))
    await user.click(screen.getByRole('button', { name: '차단' }))
    await user.click(screen.getByRole('button', { name: '취소' }))
    await user.keyboard('{Escape}')
    expect(screen.getByRole('dialog', { name: "'jhpark' 계정을 차단할까요?" })).toBeInTheDocument()
    release()

    expect(await within(row('jhpark')).findByText('차단 중')).toBeInTheDocument()
    expect(screen.queryByRole('dialog')).toBeNull()
  })

  it('차단 해제를 기다리는 동안 다시 눌러도 한 번만 보낸다', async () => {
    let release: () => void = (): void => {}
    const wait: Promise<void> = new Promise<void>((resolve: () => void): void => { release = resolve })
    const { api, user } = setup({
      [LIST]: [userPage([userOf('leesy', { status: 'blocked' })])],
      'POST /api/v1/admin/users/id-leesy/unblock': [{ status: 200, body: userOf('leesy'), wait }],
    })

    const unblock: HTMLElement = await screen.findByRole('button', { name: 'leesy 차단 해제' })
    await user.click(unblock)
    await user.click(unblock)
    release()

    expect(await within(row('leesy')).findByText('활성')).toBeInTheDocument()
    expect(api.sent.filter((r): boolean => r.path.endsWith('/unblock'))).toHaveLength(1)
  })

  it('"더 보기"에 실패하면 목록 위에 오류를 보여 주고, 다시 누를 수 있다', async () => {
    const { user } = setup({
      [LIST]: [userPage([userOf('first')], 'c1'), apiError(500, 'SERVER_ERROR', '서버 오류가 발생했습니다.'), userPage([userOf('second')])],
    })

    await user.click(await screen.findByRole('button', { name: '더 보기' }))
    expect(await screen.findByRole('alert')).toHaveTextContent('서버 오류가 발생했습니다.')
    await user.click(screen.getByRole('button', { name: '더 보기' }))

    expect(await screen.findByRole('rowheader', { name: 'second' })).toBeInTheDocument()
    expect(screen.queryByRole('alert')).toBeNull()
  })
})

describe('AdminScreen 등록', () => {
  it('아이디만 받아 등록하고, 임시 비밀번호를 한 번만 보여 준 뒤 목록 맨 위에 올린다', async () => {
    const created: FakeReply = {
      status: 201,
      body: { user: userOf('newbie', { passwordChangeRequired: true }), temporaryPassword: 'Kp7wRx3eNq2T' },
    }
    const { api, user } = setup({ [LIST]: [userPage([userOf('old')])], 'POST /api/v1/admin/users': [created] })
    await screen.findByRole('rowheader', { name: 'old' })

    await user.click(screen.getByRole('button', { name: '계정 등록' }))
    const form: HTMLElement = screen.getByRole('dialog', { name: '사용자 계정 등록' })
    expect(within(form).getByText('영문 소문자와 숫자 4~20자')).toBeInTheDocument()
    expect(within(form).getByText('비밀번호는 시스템이 만들어 다음 화면에 한 번만 보여 줍니다.')).toBeInTheDocument()
    await user.type(within(form).getByLabelText('아이디'), 'newbie')
    await user.click(within(form).getByRole('button', { name: '등록' }))

    const secret: HTMLElement = await screen.findByRole('dialog', { name: '계정을 등록했습니다' })
    expect(api.sent[1].body).toEqual({ loginId: 'newbie' })
    expect(within(secret).getByText('임시 비밀번호는 지금만 볼 수 있습니다. 창을 닫기 전에 사용자에게 전달해 주세요.')).toBeInTheDocument()
    expect(within(secret).getByText('newbie')).toBeInTheDocument()
    expect(within(secret).getByText('Kp7wRx3eNq2T')).toBeInTheDocument()
    expect(within(secret).getByText('사용자는 이 비밀번호로 로그인한 뒤 바로 새 비밀번호로 바꿔야 합니다.')).toBeInTheDocument()

    await user.click(within(secret).getByRole('button', { name: '전달했습니다' }))
    expect(screen.queryByRole('dialog')).toBeNull()
    expect(screen.queryByText('Kp7wRx3eNq2T')).toBeNull()
    const rows: HTMLElement[] = screen.getAllByRole('rowheader')
    expect(rows.map((r: HTMLElement): string => r.textContent ?? '')).toEqual(['newbie', 'old'])
    expect(within(row('newbie')).getByText('임시 비밀번호')).toBeInTheDocument()
  })

  it('이미 있는 아이디면 대화상자 안에 규격의 문구를 보여 주고 닫지 않는다', async () => {
    const { user } = setup({
      [LIST]: [userPage([userOf('jhpark')])],
      'POST /api/v1/admin/users': [apiError(409, 'LOGIN_ID_TAKEN', '이미 사용 중인 아이디입니다.')],
    })
    await screen.findByRole('rowheader', { name: 'jhpark' })

    await user.click(screen.getByRole('button', { name: '계정 등록' }))
    const form: HTMLElement = screen.getByRole('dialog', { name: '사용자 계정 등록' })
    await user.type(within(form).getByLabelText('아이디'), 'jhpark')
    await user.click(within(form).getByRole('button', { name: '등록' }))

    expect(await within(form).findByText('이미 사용 중인 아이디입니다.')).toBeInTheDocument()
    expect(within(form).getByLabelText('아이디')).toHaveAttribute('aria-invalid', 'true')
    expect(screen.getByRole('dialog', { name: '사용자 계정 등록' })).toBeInTheDocument()

    await user.type(within(form).getByLabelText('아이디'), '2')
    expect(within(form).queryByText('이미 사용 중인 아이디입니다.')).toBeNull()
    expect(within(form).getByLabelText('아이디')).not.toHaveAttribute('aria-invalid', 'true')
  })

  it('등록을 취소하면 보내지 않고, 다시 열면 입력칸이 비어 있다', async () => {
    const { api, user } = setup({ [LIST]: [userPage([])] })
    await screen.findByText('등록한 사용자 계정이 없습니다')

    await user.click(screen.getByRole('button', { name: '계정 등록' }))
    await user.type(screen.getByLabelText('아이디'), 'draft')
    await user.click(screen.getByRole('button', { name: '취소' }))
    await user.click(screen.getByRole('button', { name: '계정 등록' }))

    expect(screen.getByLabelText('아이디')).toHaveValue('')
    expect(api.sent).toHaveLength(1)
  })

  it('임시 비밀번호 창은 Esc로 닫히지 않는다("전달했습니다"로만 닫는다)', async () => {
    const created: FakeReply = { status: 201, body: { user: userOf('newbie'), temporaryPassword: 'Kp7wRx3eNq2T' } }
    const { user } = setup({ [LIST]: [userPage([])], 'POST /api/v1/admin/users': [created] })
    await screen.findByText('등록한 사용자 계정이 없습니다')

    await user.click(screen.getByRole('button', { name: '계정 등록' }))
    await user.type(screen.getByLabelText('아이디'), 'newbie')
    await user.click(screen.getByRole('button', { name: '등록' }))
    await screen.findByRole('dialog', { name: '계정을 등록했습니다' })
    await user.keyboard('{Escape}')

    expect(screen.getByText('Kp7wRx3eNq2T')).toBeInTheDocument()
  })

  it('복사 버튼은 임시 비밀번호를 클립보드에 넣는다', async () => {
    const created: FakeReply = { status: 201, body: { user: userOf('newbie'), temporaryPassword: 'Kp7wRx3eNq2T' } }
    const { user } = setup({ [LIST]: [userPage([])], 'POST /api/v1/admin/users': [created] })
    const writeText = vi.spyOn(navigator.clipboard, 'writeText')
    await screen.findByText('등록한 사용자 계정이 없습니다')

    await user.click(screen.getByRole('button', { name: '계정 등록' }))
    await user.type(screen.getByLabelText('아이디'), 'newbie')
    await user.click(screen.getByRole('button', { name: '등록' }))
    await user.click(await screen.findByRole('button', { name: '임시 비밀번호 복사' }))

    expect(writeText).toHaveBeenCalledWith('Kp7wRx3eNq2T')
    expect(await screen.findByRole('button', { name: '임시 비밀번호 복사' })).toHaveTextContent('복사함')
  })
})

describe('AdminScreen 차단, 해제, 초기화', () => {
  it('차단은 확인을 받고, 차단하면 목록에 "차단 중"과 "차단 해제"가 보인다', async () => {
    const { api, user } = setup({
      [LIST]: [userPage([userOf('jhpark')])],
      'POST /api/v1/admin/users/id-jhpark/block': [{ status: 200, body: userOf('jhpark', { status: 'blocked' }) }],
    })

    await user.click(await screen.findByRole('button', { name: 'jhpark 차단' }))
    const ask: HTMLElement = screen.getByRole('dialog', { name: "'jhpark' 계정을 차단할까요?" })
    expect(within(ask).getByText('바로 로그인할 수 없고, 쓰고 있던 화면에서도 로그인이 풀립니다. 세션 기록은 남고, 언제든 차단을 해제할 수 있습니다.')).toBeInTheDocument()
    await user.click(within(ask).getByRole('button', { name: '차단' }))

    expect(await within(row('jhpark')).findByText('차단 중')).toBeInTheDocument()
    expect(api.sent[1].method).toBe('POST')
    expect(screen.queryByRole('dialog')).toBeNull()
    expect(within(row('jhpark')).getByRole('button', { name: 'jhpark 차단 해제' })).toBeInTheDocument()
  })

  it('차단을 취소하면 아무것도 보내지 않는다', async () => {
    const { api, user } = setup({ [LIST]: [userPage([userOf('jhpark')])] })

    await user.click(await screen.findByRole('button', { name: 'jhpark 차단' }))
    await user.click(screen.getByRole('button', { name: '취소' }))

    expect(screen.queryByRole('dialog')).toBeNull()
    expect(api.sent).toHaveLength(1)
  })

  it('초기화를 취소하면 아무것도 보내지 않는다', async () => {
    const { api, user } = setup({ [LIST]: [userPage([userOf('jhpark')])] })

    await user.click(await screen.findByRole('button', { name: 'jhpark 비밀번호 초기화' }))
    await user.click(screen.getByRole('button', { name: '취소' }))

    expect(screen.queryByRole('dialog')).toBeNull()
    expect(api.sent).toHaveLength(1)
  })

  it('해제는 확인 없이 바로 하고 목록에 "활성"이 보인다', async () => {
    const { api, user } = setup({
      [LIST]: [userPage([userOf('leesy', { status: 'blocked' })])],
      'POST /api/v1/admin/users/id-leesy/unblock': [{ status: 200, body: userOf('leesy') }],
    })

    await user.click(await screen.findByRole('button', { name: 'leesy 차단 해제' }))

    expect(await within(row('leesy')).findByText('활성')).toBeInTheDocument()
    expect(screen.queryByRole('dialog')).toBeNull()
    expect(api.sent[1].path).toBe('/api/v1/admin/users/id-leesy/unblock')
  })

  it('해제에 실패하면 목록 위에 오류를 보여 준다', async () => {
    const { user } = setup({
      [LIST]: [userPage([userOf('leesy', { status: 'blocked' })])],
      'POST /api/v1/admin/users/id-leesy/unblock': [apiError(404, 'USER_NOT_FOUND', '계정을 찾을 수 없습니다.')],
    })

    await user.click(await screen.findByRole('button', { name: 'leesy 차단 해제' }))

    expect(await screen.findByRole('alert')).toHaveTextContent('계정을 찾을 수 없습니다.')
    expect(within(row('leesy')).getByText('차단 중')).toBeInTheDocument()
  })

  it('초기화는 확인을 받고, 새 임시 비밀번호를 한 번 보여 주며 목록에 "임시 비밀번호"가 보인다', async () => {
    const reset: FakeReply = {
      status: 200,
      body: { user: userOf('jhpark', { passwordChangeRequired: true }), temporaryPassword: 'Zx8vQm4tHw9R' },
    }
    const { user } = setup({
      [LIST]: [userPage([userOf('jhpark')])],
      'POST /api/v1/admin/users/id-jhpark/password-reset': [reset],
    })

    await user.click(await screen.findByRole('button', { name: 'jhpark 비밀번호 초기화' }))
    const ask: HTMLElement = screen.getByRole('dialog', { name: "'jhpark' 비밀번호를 초기화할까요?" })
    expect(within(ask).getByText('새 임시 비밀번호를 만듭니다. 지금 비밀번호와 로그인 중인 화면은 모두 무효가 됩니다.')).toBeInTheDocument()
    await user.click(within(ask).getByRole('button', { name: '초기화' }))

    const secret: HTMLElement = await screen.findByRole('dialog', { name: '비밀번호를 초기화했습니다' })
    expect(within(secret).getByText('Zx8vQm4tHw9R')).toBeInTheDocument()
    await user.click(within(secret).getByRole('button', { name: '전달했습니다' }))
    expect(screen.queryByText('Zx8vQm4tHw9R')).toBeNull()
    expect(within(row('jhpark')).getByText('임시 비밀번호')).toBeInTheDocument()
  })

  it('확인 대화상자에서 실패하면 대화상자 안에 규격의 문구를 보여 준다', async () => {
    const { user } = setup({
      [LIST]: [userPage([userOf('jhpark')])],
      'POST /api/v1/admin/users/id-jhpark/block': [apiError(404, 'USER_NOT_FOUND', '계정을 찾을 수 없습니다.')],
    })

    await user.click(await screen.findByRole('button', { name: 'jhpark 차단' }))
    await user.click(screen.getByRole('button', { name: '차단' }))

    const ask: HTMLElement = screen.getByRole('dialog', { name: "'jhpark' 계정을 차단할까요?" })
    expect(await within(ask).findByRole('alert')).toHaveTextContent('계정을 찾을 수 없습니다.')
  })
})
