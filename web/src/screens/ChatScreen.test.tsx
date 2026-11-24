import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent, { type UserEvent } from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { createApiClient, type ApiClient } from '../api/client'
import { showElement } from '../test/intersection'
import { apiError, controlledSse, fakeApi, sseReply, type ControlledSse, type FakeApi, type FakeReply } from '../test/fakeApi'
import { ChatScreen } from './ChatScreen'

interface SessionJson {
  id: string
  title: string
  updatedAt: string
}

function session(id: string, title: string): SessionJson {
  return { id, title, updatedAt: '2026-11-21T00:00:00Z' }
}

function sessionsPage(items: SessionJson[], nextCursor?: string): FakeReply {
  return { status: 200, body: { items, nextCursor } }
}

const EMPTY_LIST: FakeReply = sessionsPage([])

interface Setup {
  api: FakeApi
  user: UserEvent
}

function setup(replies: Record<string, FakeReply[]>): Setup {
  const api: FakeApi = fakeApi({ 'GET /api/v1/sessions': [EMPTY_LIST], ...replies })
  const client: ApiClient = createApiClient({
    baseUrl: 'http://localhost:8000',
    getAccessToken: (): string | null => 'tk',
    fetch: api.fetch,
  })
  render(<ChatScreen client={client} loginId="user01" onPasswordChanged={vi.fn()} />)
  return { api, user: userEvent.setup() }
}

function composer(): HTMLElement {
  return screen.getByRole('textbox', { name: '질문' })
}

async function ask(user: UserEvent, text: string): Promise<void> {
  await user.type(composer(), text)
  await user.keyboard('{Enter}')
}

function sessionList(): HTMLElement {
  return screen.getByRole('navigation', { name: '세션 목록' })
}

describe('ChatScreen: 새 세션', () => {
  it('빈 새 세션으로 시작하고, 입력이 비어 있으면 보내기 버튼이 비활성이다', async () => {
    setup({ 'GET /api/v1/sessions': [sessionsPage([session('s1', '다음 주 일정 정리해 줘')])] })

    expect(screen.getByRole('heading', { level: 2, name: '새 세션' })).toBeInTheDocument()
    expect(screen.getByText('Iris에게 질문하세요')).toBeInTheDocument()
    expect(screen.getByText('지난 대화는 세션 목록에서 볼 수 있습니다.')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: '질문 보내기' })).toBeDisabled()
    expect(within(sessionList()).getByRole('heading', { level: 1, name: 'Iris' })).toBeInTheDocument()
    expect(await within(sessionList()).findByText('다음 주 일정 정리해 줘')).toBeInTheDocument()
    expect(within(sessionList()).getByText('user01')).toBeInTheDocument()
    expect(screen.getByText('Enter로 보내고 Shift+Enter로 줄을 바꿉니다.')).toBeInTheDocument()
  })
})

describe('ChatScreen: 새 세션 버튼', () => {
  /** 지난 세션 하나. 가짜 fetch가 응답을 꺼내 쓰므로(shift) 테스트마다 새로 만든다. */
  function old(): Record<string, FakeReply[]> {
    return {
      'GET /api/v1/sessions': [sessionsPage([session('s1', '지난 세션')])],
      'GET /api/v1/sessions/s1/questions': [{
        status: 200,
        body: { items: [{ id: 'q1', text: '지난 질문', createdAt: '', answer: { id: 'a1', text: '지난 답', status: 'completed', createdAt: '' } }] },
      }],
    }
  }

  function newSessionButton(): HTMLElement {
    return within(sessionList()).getByRole('button', { name: '새 세션' })
  }

  it('사이드바의 "세션" 제목 위에 있다', () => {
    setup({})

    const heading: HTMLElement = within(sessionList()).getByRole('heading', { level: 2, name: '세션' })
    expect(newSessionButton().compareDocumentPosition(heading) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
  })

  it('지난 세션을 연 뒤 누르면 빈 새 세션이 되고, 다음 질문은 sessionId 없이 새 세션으로 간다', async () => {
    const { api, user } = setup({
      ...old(),
      'POST /api/v1/sessions/questions': [sseReply([['session', { id: 's-new' }], ['delta', { text: '새 답' }], ['done', { answerId: 'a2' }]])],
    })
    await user.click(await within(sessionList()).findByRole('link', { name: '지난 세션' }))
    await screen.findByText('지난 답')

    await user.click(newSessionButton())

    expect(screen.getByRole('heading', { level: 2, name: '새 세션' })).toBeInTheDocument()
    expect(screen.queryByText('지난 답')).toBeNull()
    expect(screen.getByText('Iris에게 질문하세요')).toBeInTheDocument()
    expect(within(sessionList()).getByRole('link', { name: '지난 세션' })).not.toHaveAttribute('aria-current')
    await ask(user, '새 질문')
    await screen.findByText('새 답')
    expect(api.sent.find((r) => r.method === 'POST')?.body).toEqual({ text: '새 질문' })
    const links: string[] = (await within(sessionList()).findAllByRole('link')).map((l: HTMLElement): string => l.textContent ?? '')
    expect(links).toEqual(['새 질문', '지난 세션'])
  })

  it('이미 빈 새 세션이면 아무 일도 없고, 적어 둔 입력도 그대로다', async () => {
    const { api, user } = setup({})
    await user.type(composer(), '쓰는 중')

    await user.click(newSessionButton())

    expect(composer()).toHaveValue('쓰는 중')
    expect(api.sent.filter((r) => r.method === 'POST')).toHaveLength(0)
  })

  it('답변을 받는 중에 누르면 화면은 새 세션이 되고, 받던 답변은 끝까지 받아 목록에 생긴다', async () => {
    const sse: ControlledSse = controlledSse()
    const { user } = setup({ 'POST /api/v1/sessions/questions': [sse.reply] })
    await ask(user, '긴 질문')
    sse.push('session', { id: 's-long' })
    sse.push('delta', { text: '받는 중' })
    await screen.findByText('받는 중')

    await user.click(newSessionButton())
    expect(screen.getByRole('heading', { level: 2, name: '새 세션' })).toBeInTheDocument()
    expect(screen.queryByText('받는 중')).toBeNull()
    sse.push('done', { answerId: 'a1' })
    sse.close()

    const link: HTMLElement = await within(sessionList()).findByRole('link', { name: '긴 질문' })
    expect(link).not.toHaveAttribute('aria-current')
    expect(screen.getByRole('heading', { level: 2, name: '새 세션' })).toBeInTheDocument()
  })

  it('설정을 보다가 누르면 채팅의 빈 새 세션으로 돌아온다', async () => {
    const { user } = setup({})
    await user.click(within(sessionList()).getByRole('button', { name: '설정' }))

    await user.click(newSessionButton())

    expect(screen.getByRole('heading', { level: 2, name: '새 세션' })).toBeInTheDocument()
    expect(composer()).toBeInTheDocument()
  })

  it('지난 세션을 보다가 설정으로 간 뒤 누르면 지난 대화 없이 빈 새 세션이다', async () => {
    const { user } = setup(old())
    await user.click(await within(sessionList()).findByRole('link', { name: '지난 세션' }))
    await screen.findByText('지난 답')
    await user.click(within(sessionList()).getByRole('button', { name: '설정' }))

    await user.click(newSessionButton())

    expect(screen.getByRole('heading', { level: 2, name: '새 세션' })).toBeInTheDocument()
    expect(screen.queryByText('지난 답')).toBeNull()
    expect(within(sessionList()).getByRole('link', { name: '지난 세션' })).not.toHaveAttribute('aria-current')
  })

  it('답변을 받는 중에 누르고 바로 질문하면, 새 질문은 sessionId 없이 가고 두 세션이 따로 생긴다', async () => {
    const first: ControlledSse = controlledSse()
    const { api, user } = setup({
      'POST /api/v1/sessions/questions': [first.reply, sseReply([['session', { id: 's-two' }], ['delta', { text: '둘째 답' }], ['done', { answerId: 'a2' }]])],
    })
    await ask(user, '첫째 질문')
    first.push('session', { id: 's-one' })
    first.push('delta', { text: '첫째 받는 중' })
    await screen.findByText('첫째 받는 중')

    await user.click(newSessionButton())
    await ask(user, '둘째 질문')
    await screen.findByText('둘째 답')
    first.push('done', { answerId: 'a1' })
    first.close()

    const posts: unknown[] = api.sent.filter((r) => r.method === 'POST').map((r) => r.body)
    expect(posts).toEqual([{ text: '첫째 질문' }, { text: '둘째 질문' }])
    await within(sessionList()).findByRole('link', { name: '첫째 질문' })
    expect(within(sessionList()).getByRole('link', { name: '둘째 질문' })).toHaveAttribute('aria-current', 'page')
    expect(screen.queryByText('첫째 받는 중')).toBeNull()
  })

  it('지난 세션을 불러오는 중에 누르면, 늦게 온 지난 대화가 새 세션 화면을 덮지 않는다', async () => {
    let release: () => void = (): void => {}
    const wait: Promise<void> = new Promise<void>((resolve: () => void): void => { release = resolve })
    const base: Record<string, FakeReply[]> = old()
    const { user } = setup({ ...base, 'GET /api/v1/sessions/s1/questions': [{ ...base['GET /api/v1/sessions/s1/questions'][0], wait }] })
    await user.click(await within(sessionList()).findByRole('link', { name: '지난 세션' }))

    await user.click(newSessionButton())
    release()

    await waitFor((): void => expect(screen.getByRole('heading', { level: 2, name: '새 세션' })).toBeInTheDocument())
    await new Promise<void>((r: () => void): void => { setTimeout(r, 50) })
    expect(screen.queryByText('지난 답')).toBeNull()
    expect(screen.getByRole('heading', { level: 2, name: '새 세션' })).toBeInTheDocument()
  })

  it('좁은 화면의 서랍에서 누르면 서랍을 닫는다', async () => {
    const { user } = setup({})
    await user.click(screen.getByRole('button', { name: '세션 목록 열기' }))
    expect(document.querySelector('.app')).toHaveClass('is-drawer-open')

    await user.click(newSessionButton())

    expect(document.querySelector('.app')).not.toHaveClass('is-drawer-open')
  })
})

describe('ChatScreen: 질문과 스트리밍', () => {
  it('질문하면 답변이 조각마다 이어 붙고, 끝나면 세션이 목록 맨 위에 생긴다', async () => {
    const sse: ControlledSse = controlledSse()
    const { api, user } = setup({ 'POST /api/v1/sessions/questions': [sse.reply] })

    await ask(user, '주간 보고서 초안을 써 줘')

    expect(screen.getByText('주간 보고서 초안을 써 줘', { selector: '.question' })).toBeInTheDocument()
    expect(await screen.findByText('답변을 받는 중…')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: '중지' })).toBeInTheDocument()
    sse.push('session', { id: 's-new' })
    sse.push('delta', { text: '이번 주 ' })
    sse.push('delta', { text: '보고서입니다.' })
    expect(await screen.findByText('이번 주 보고서입니다.')).toBeInTheDocument()
    expect(screen.getByRole('heading', { level: 2, name: '주간 보고서 초안을 써 줘' })).toBeInTheDocument()
    // 새 세션은 답변이 끝나 저장된 뒤에 목록에 생긴다(백엔드는 답변을 끝낼 때 세션을 저장한다).
    expect(within(sessionList()).queryByRole('link', { name: '주간 보고서 초안을 써 줘' })).toBeNull()
    sse.push('done', { answerId: 'a1' })
    sse.close()

    const link: HTMLElement = await within(sessionList()).findByRole('link', { name: '주간 보고서 초안을 써 줘' })
    expect(link).toHaveAttribute('aria-current', 'page')
    await waitFor((): void => expect(screen.queryByText('답변을 받는 중…')).toBeNull())
    expect(screen.queryByRole('button', { name: '중지' })).toBeNull()
    expect(screen.getByRole('heading', { level: 2, name: '주간 보고서 초안을 써 줘' })).toBeInTheDocument()
    expect(api.sent.find((r) => r.path === '/api/v1/sessions/questions')?.body).toEqual({ text: '주간 보고서 초안을 써 줘' })
    expect(composer()).toHaveValue('')
  })

  it('같은 세션에서 이어서 질문하면 sessionId를 함께 보낸다', async () => {
    const { api, user } = setup({
      'POST /api/v1/sessions/questions': [
        sseReply([['session', { id: 's-new' }], ['delta', { text: '첫 답' }], ['done', { answerId: 'a1' }]]),
        sseReply([['delta', { text: '둘째 답' }], ['done', { answerId: 'a2' }]]),
      ],
    })

    await ask(user, '첫 질문')
    await screen.findByText('첫 답')
    await ask(user, '둘째 질문')
    await screen.findByText('둘째 답')

    const bodies: unknown[] = api.sent.filter((r) => r.path === '/api/v1/sessions/questions').map((r) => r.body)
    expect(bodies).toEqual([{ text: '첫 질문' }, { text: '둘째 질문', sessionId: 's-new' }])
  })

  it('중지를 누르면 중지 API를 부르고, stopped를 받으면 받은 부분이 "중단됨"으로 남는다', async () => {
    const sse: ControlledSse = controlledSse()
    const { api, user } = setup({
      'POST /api/v1/sessions/questions': [sse.reply],
      'POST /api/v1/sessions/s-new/stop': [{ status: 204 }],
    })

    await ask(user, '긴 답을 줘')
    sse.push('session', { id: 's-new' })
    sse.push('delta', { text: '받은 부분' })
    await screen.findByText('받은 부분')
    await user.click(screen.getByRole('button', { name: '중지' }))
    sse.push('stopped', { answerId: 'a1' })
    sse.close()

    expect(await screen.findByText('중단됨')).toBeInTheDocument()
    expect(api.sent.some((r) => r.method === 'POST' && r.path === '/api/v1/sessions/s-new/stop')).toBe(true)
    expect(screen.getByRole('button', { name: '질문 보내기' })).toBeInTheDocument()
  })

  it('같은 순간에 두 번 보내도 한 번만 보낸다', async () => {
    const sse: ControlledSse = controlledSse()
    const { api, user } = setup({ 'POST /api/v1/sessions/questions': [sse.reply] })

    await user.type(composer(), '한 번만')
    await user.keyboard('{Enter}{Enter}')

    expect(api.sent.filter((r) => r.path === '/api/v1/sessions/questions')).toHaveLength(1)
    expect(screen.getAllByText('한 번만', { selector: '.question' })).toHaveLength(1)
    sse.close()
  })

  it('지난 세션에 질문하면 스트림이 열린 뒤에 중지할 수 있다', async () => {
    let release: () => void = (): void => {}
    const wait: Promise<void> = new Promise<void>((resolve: () => void): void => {
      release = resolve
    })
    const sse: ControlledSse = controlledSse()
    const { user } = setup({
      'GET /api/v1/sessions': [sessionsPage([session('s1', '지난 세션')])],
      'GET /api/v1/sessions/s1/questions': [{ status: 200, body: { items: [] } }],
      'POST /api/v1/sessions/questions': [{ ...sse.reply, wait }],
    })
    await user.click(await within(sessionList()).findByRole('link', { name: '지난 세션' }))
    await screen.findByRole('heading', { level: 2, name: '지난 세션' })

    await ask(user, '이어서')
    // 서버가 아직 스트리밍을 시작하지 않았으면 중지할 것이 없다(NOT_STREAMING).
    expect(screen.getByRole('button', { name: '중지' })).toBeDisabled()
    release()

    await waitFor((): void => expect(screen.getByRole('button', { name: '중지' })).toBeEnabled())
    sse.close()
  })

  it('Shift+Enter는 줄을 바꾸고 보내지 않는다', async () => {
    const { api, user } = setup({})

    await user.type(composer(), '첫 줄{Shift>}{Enter}{/Shift}둘째 줄')

    expect(composer()).toHaveValue('첫 줄\n둘째 줄')
    expect(api.sent.some((r) => r.path === '/api/v1/sessions/questions')).toBe(false)
  })

  it('한글 조합 중의 Enter는 보내지 않는다', async () => {
    const { api, user } = setup({})
    await user.type(composer(), '안녕')

    const textarea: HTMLElement = composer()
    textarea.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true, isComposing: true }))

    expect(api.sent.some((r) => r.path === '/api/v1/sessions/questions')).toBe(false)
  })

  it('65,536자를 넘으면 보내지 않고 안내한다', async () => {
    const { api, user } = setup({})

    await user.click(composer())
    await user.paste('가'.repeat(65_537))
    await user.click(screen.getByRole('button', { name: '질문 보내기' }))

    expect(await screen.findByRole('alert')).toHaveTextContent('질문은 65,536자까지 보낼 수 있습니다.')
    expect(api.sent.some((r) => r.path === '/api/v1/sessions/questions')).toBe(false)
  })
})

describe('ChatScreen: 오류', () => {
  it('답변을 받기 전에 서버 오류가 나면 질문 아래에 안내하고 세션은 생기지 않는다', async () => {
    const { user } = setup({
      'POST /api/v1/sessions/questions': [apiError(500, 'SERVER_ERROR', '서버 오류가 발생했습니다.')],
    })

    await ask(user, '오늘 회의록을 요약해 줘')

    expect(await screen.findByRole('alert')).toHaveTextContent('서버 오류가 발생했습니다. 잠시 후 다시 질문해 주세요.')
    expect(within(sessionList()).queryByRole('link', { name: '오늘 회의록을 요약해 줘' })).toBeNull()
    expect(screen.getByRole('heading', { level: 2, name: '새 세션' })).toBeInTheDocument()
  })

  it('답변 일부를 받은 뒤 오류 이벤트가 오면 받은 부분이 "중단됨"으로 남고 안내한다', async () => {
    const { user } = setup({
      'POST /api/v1/sessions/questions': [
        sseReply([
          ['session', { id: 's-new' }],
          ['delta', { text: '일부 답' }],
          ['error', { code: 'SERVER_ERROR', message: '서버 오류가 발생했습니다.' }],
        ]),
      ],
    })

    await ask(user, '질문')

    expect(await screen.findByText('중단됨')).toBeInTheDocument()
    expect(screen.getByText('일부 답')).toBeInTheDocument()
    expect(screen.getByRole('alert')).toHaveTextContent('서버 오류가 발생했습니다. 잠시 후 다시 질문해 주세요.')
    // 받은 부분이 "중단됨"으로 저장되므로 세션이 생긴다.
    expect(await within(sessionList()).findByRole('link', { name: '질문' })).toBeInTheDocument()
  })

  it('답변 조각 없이 오류 이벤트로 끝나면 세션이 생기지 않는다', async () => {
    const { user } = setup({
      'POST /api/v1/sessions/questions': [
        sseReply([['session', { id: 's-new' }], ['error', { code: 'SERVER_ERROR', message: '서버 오류가 발생했습니다.' }]]),
      ],
    })

    await ask(user, '질문')

    expect(await screen.findByRole('alert')).toHaveTextContent('서버 오류가 발생했습니다. 잠시 후 다시 질문해 주세요.')
    expect(within(sessionList()).queryByRole('link', { name: '질문' })).toBeNull()
    expect(screen.queryByText('중단됨')).toBeNull()
  })

  it('그 밖의 오류는 규격의 문구를 보여준다(답변 중인 세션에 질문 등)', async () => {
    const { user } = setup({
      'POST /api/v1/sessions/questions': [apiError(409, 'SESSION_BUSY', '답변이 끝난 뒤에 질문해 주세요.')],
    })

    await ask(user, '질문')

    expect(await screen.findByRole('alert')).toHaveTextContent('답변이 끝난 뒤에 질문해 주세요.')
  })
})

describe('ChatScreen: 세션 목록', () => {
  it('지난 세션을 열면 오래된 순으로 보여주고, 이어서 질문할 수 있다', async () => {
    const questions: FakeReply = {
      status: 200,
      body: {
        items: [
          { id: 'q2', text: '둘째 질문', createdAt: '', answer: { id: 'a2', text: '둘째 답', status: 'stopped', createdAt: '' } },
          { id: 'q1', text: '첫 질문', createdAt: '', answer: { id: 'a1', text: '첫 답', status: 'completed', createdAt: '' } },
        ],
      },
    }
    const { api, user } = setup({
      'GET /api/v1/sessions': [sessionsPage([session('s1', '첫 질문')])],
      'GET /api/v1/sessions/s1/questions': [questions],
      'POST /api/v1/sessions/questions': [sseReply([['delta', { text: '셋째 답' }], ['done', { answerId: 'a3' }]])],
    })

    await user.click(await within(sessionList()).findByRole('link', { name: '첫 질문' }))

    const texts: string[] = (await screen.findAllByText(/질문$|답$/, { selector: '.question, .answer p' })).map((e) => e.textContent ?? '')
    expect(texts).toEqual(['첫 질문', '첫 답', '둘째 질문', '둘째 답'])
    expect(screen.getAllByText('중단됨')).toHaveLength(1)
    expect(screen.getByRole('heading', { level: 2, name: '첫 질문' })).toBeInTheDocument()

    await ask(user, '셋째 질문')
    await screen.findByText('셋째 답')
    expect(api.sent.find((r) => r.method === 'POST')?.body).toEqual({ text: '셋째 질문', sessionId: 's1' })
  })

  it('새 세션 답변 중에 다른 세션을 열어도, 답변이 끝나 저장되면 목록에 생긴다', async () => {
    const sse: ControlledSse = controlledSse()
    const { user } = setup({
      'GET /api/v1/sessions': [sessionsPage([session('s1', '지난 세션')])],
      'GET /api/v1/sessions/s1/questions': [{ status: 200, body: { items: [] } }],
      'POST /api/v1/sessions/questions': [sse.reply],
    })
    await ask(user, '새 질문')
    sse.push('session', { id: 's-new' })
    sse.push('delta', { text: '받는 중' })
    await screen.findByText('받는 중')

    await user.click(within(sessionList()).getByRole('link', { name: '지난 세션' }))
    await screen.findByRole('heading', { level: 2, name: '지난 세션' })
    sse.push('done', { answerId: 'a1' })
    sse.close()

    const link: HTMLElement = await within(sessionList()).findByRole('link', { name: '새 질문' })
    expect(link).not.toHaveAttribute('aria-current')
    expect(screen.queryByText('받는 중')).toBeNull()
  })

  it('지난 세션을 불러오는 동안에는 보내지 못한다', async () => {
    let release: () => void = (): void => {}
    const wait: Promise<void> = new Promise<void>((resolve: () => void): void => {
      release = resolve
    })
    const { user } = setup({
      'GET /api/v1/sessions': [sessionsPage([session('s1', '지난 세션')])],
      'GET /api/v1/sessions/s1/questions': [{ status: 200, body: { items: [] }, wait }],
    })

    await user.click(await within(sessionList()).findByRole('link', { name: '지난 세션' }))
    await user.type(composer(), '빨리 보내기')
    expect(screen.getByRole('button', { name: '질문 보내기' })).toBeDisabled()

    release()
    await waitFor((): void => expect(screen.getByRole('button', { name: '질문 보내기' })).toBeEnabled())
  })

  it('목록 끝이 보이면 다음 페이지를 이어서 불러온다', async () => {
    const { api } = setup({
      'GET /api/v1/sessions': [
        sessionsPage([session('s1', '첫 페이지 세션')], 'cursor-2'),
        sessionsPage([session('s2', '둘째 페이지 세션')]),
      ],
    })

    await within(sessionList()).findByText('첫 페이지 세션')
    await showElement(within(sessionList()).getByText('이전 세션을 불러오는 중…'))

    expect(await within(sessionList()).findByText('둘째 페이지 세션')).toBeInTheDocument()
    expect(api.sent.filter((r) => r.path === '/api/v1/sessions').map((r) => r.query)).toEqual([
      '?limit=20',
      '?cursor=cursor-2&limit=20',
    ])
    expect(within(sessionList()).queryByText('이전 세션을 불러오는 중…')).toBeNull()
  })

  it('목록을 불러오지 못하면 안내하고, 다시 시도할 수 있다', async () => {
    const { user } = setup({
      'GET /api/v1/sessions': [apiError(500, 'SERVER_ERROR', '서버 오류가 발생했습니다.'), sessionsPage([session('s1', '다시 불러온 세션')])],
    })

    expect(await within(sessionList()).findByText('서버 오류가 발생했습니다.')).toBeInTheDocument()
    await user.click(within(sessionList()).getByRole('button', { name: '다시 시도' }))

    expect(await within(sessionList()).findByText('다시 불러온 세션')).toBeInTheDocument()
    expect(within(sessionList()).queryByText('서버 오류가 발생했습니다.')).toBeNull()
  })

  it('삭제를 확인하면 목록에서 지우고, 취소하면 그대로 둔다', async () => {
    const { api, user } = setup({
      'GET /api/v1/sessions': [sessionsPage([session('s1', '운동 루틴 짜 줘')])],
      'DELETE /api/v1/sessions/s1': [{ status: 204 }],
    })
    const deleteButton: HTMLElement = await within(sessionList()).findByRole('button', { name: "'운동 루틴 짜 줘' 세션 삭제" })

    await user.click(deleteButton)
    const dialog: HTMLElement = await screen.findByRole('dialog', { name: '세션을 삭제할까요?' })
    expect(dialog).toHaveTextContent("'운동 루틴 짜 줘' 세션이 목록에서 사라지고 다시 볼 수 없습니다.")
    // 샘플처럼 닫기(X) 버튼 없이 취소와 삭제만 둔다(Primer 기본 닫기 버튼은 영어 "Close").
    expect(within(dialog).getAllByRole('button').map((b: HTMLElement) => b.textContent)).toEqual(['취소', '삭제'])
    await user.click(within(dialog).getByRole('button', { name: '취소' }))
    expect(screen.queryByRole('dialog')).toBeNull()
    expect(api.sent.some((r) => r.method === 'DELETE')).toBe(false)

    await user.click(deleteButton)
    await user.click(within(await screen.findByRole('dialog')).getByRole('button', { name: '삭제' }))

    await waitFor((): void => expect(within(sessionList()).queryByText('운동 루틴 짜 줘')).toBeNull())
    expect(api.sent.some((r) => r.method === 'DELETE' && r.path === '/api/v1/sessions/s1')).toBe(true)
  })

  it('보고 있는 세션을 삭제하면 빈 새 세션으로 돌아간다', async () => {
    const { user } = setup({
      'GET /api/v1/sessions': [sessionsPage([session('s1', '첫 질문')])],
      'GET /api/v1/sessions/s1/questions': [{ status: 200, body: { items: [] } }],
      'DELETE /api/v1/sessions/s1': [{ status: 204 }],
    })
    await user.click(await within(sessionList()).findByRole('link', { name: '첫 질문' }))
    await screen.findByRole('heading', { level: 2, name: '첫 질문' })

    await user.click(within(sessionList()).getByRole('button', { name: "'첫 질문' 세션 삭제" }))
    await user.click(within(await screen.findByRole('dialog')).getByRole('button', { name: '삭제' }))

    expect(await screen.findByRole('heading', { level: 2, name: '새 세션' })).toBeInTheDocument()
  })

  it('설정을 누르면 본문에 설정이 열리고, 세션을 누르면 채팅으로 돌아온다', async () => {
    const { user } = setup({
      'GET /api/v1/sessions': [sessionsPage([session('s1', '첫 질문')])],
      'GET /api/v1/sessions/s1/questions': [{ status: 200, body: { items: [] } }],
    })

    await user.click(within(sessionList()).getByRole('button', { name: '설정' }))
    expect(screen.getByRole('heading', { level: 2, name: '설정' })).toBeInTheDocument()
    expect(screen.queryByRole('textbox', { name: '질문' })).toBeNull()

    await user.click(await within(sessionList()).findByRole('link', { name: '첫 질문' }))
    expect(await screen.findByRole('heading', { level: 2, name: '첫 질문' })).toBeInTheDocument()
    expect(composer()).toBeInTheDocument()
  })
})
