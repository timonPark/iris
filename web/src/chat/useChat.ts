import { useCallback, useRef, useState, type RefObject } from 'react'
import type { ApiClient } from '../api/client'
import { safely } from '../api/safely'
import { chatErrorText, errorText, MESSAGES } from '../auth/messages'
import { keepReceivedAsStopped, streamAnswer, type AnswerUpdate } from './streamAnswer'
import type { components } from '../api/schema'
import type { ChatItem, Session } from './types'

type QuestionPage = components['schemas']['QuestionPage']

export interface ChatState {
  /** 저장된 세션의 ID. 새 세션은 첫 답변 조각을 받기 전까지 null. */
  sessionId: string | null
  title: string | null
  items: ChatItem[]
  streaming: boolean
  /** 중지할 수 있다(세션 ID를 안다). */
  canStop: boolean
  loading: boolean
  loadError: string | null
}

export interface Chat extends ChatState {
  send: (text: string) => Promise<void>
  stop: () => void
  open: (session: Session) => Promise<void>
  reset: () => void
}

/** 비동기 흐름이 공유하는 값. generation이 바뀌면(다른 세션을 열거나 새로 시작) 진행 중이던 흐름의 결과는 버린다. */
interface Live {
  generation: number
  controller: AbortController | null
  /** 중지와 첫 저장에 쓰는 세션 ID(`session` 이벤트 또는 지금 세션). */
  pendingId: string | null
  nextKey: number
}

interface Ctx {
  client: ApiClient
  live: RefObject<Live>
  state: RefObject<ChatState>
  patch: (fn: (s: ChatState) => Partial<ChatState>) => void
  onSessionActive: (session: Session) => void
}

const INITIAL: ChatState = { sessionId: null, title: null, items: [], streaming: false, canStop: false, loading: false, loadError: null }

/** 지금 보고 있는 세션(새 세션 또는 연 세션)의 질문과 답변. */
export function useChat(client: ApiClient, onSessionActive: (session: Session) => void): Chat {
  const [state, setState] = useState<ChatState>(INITIAL)
  const live: RefObject<Live> = useRef<Live>({ generation: 0, controller: null, pendingId: null, nextKey: 0 })
  const stateRef: RefObject<ChatState> = useRef<ChatState>(state)
  stateRef.current = state
  const patch = useCallback((fn: (s: ChatState) => Partial<ChatState>): void => setState((s: ChatState): ChatState => ({ ...s, ...fn(s) })), [])
  const ctx: Ctx = { client, live, state: stateRef, patch, onSessionActive }

  /** 화면을 바꾼다. 받던 답변은 끊지 않고 뒤에서 끝까지 읽어 저장되면 목록에 올린다(abort는 삭제 뒤 새로 시작할 때만). */
  const restart = (next: ChatState, abort: boolean): number => {
    if (abort) live.current.controller?.abort()
    live.current.controller = null
    live.current.pendingId = next.sessionId
    setState(next)
    stateRef.current = next
    return ++live.current.generation
  }

  return {
    ...state,
    send: (text: string): Promise<void> => sendQuestion(ctx, text),
    stop: (): void => stopAnswer(ctx),
    open: (session: Session): Promise<void> => openSession(ctx, session, restart),
    reset: (): void => void restart(INITIAL, true),
  }
}

async function sendQuestion(ctx: Ctx, text: string): Promise<void> {
  const live: Live = ctx.live.current
  const gen: number = live.generation
  const key: string = `new-${live.nextKey++}`
  const { sessionId, title } = ctx.state.current
  ctx.patch((s: ChatState) => ({ items: [...s.items, { key, question: text, answer: { text: '', status: 'streaming' }, error: null }], streaming: true, canStop: false }))
  live.pendingId = sessionId
  live.controller = new AbortController()
  const { data, error } = await safely(
    ctx.client.POST('/api/v1/sessions/questions', {
      body: sessionId === null ? { text } : { text, sessionId },
      parseAs: 'stream',
      signal: live.controller.signal,
    }),
  )
  const update = (fn: (item: ChatItem) => ChatItem): void => ctx.patch((s: ChatState) => ({ items: s.items.map((i: ChatItem) => (i.key === key ? fn(i) : i)) }))
  if (data === undefined || data === null) {
    if (gen === live.generation) update((i: ChatItem) => ({ ...i, answer: null, error: chatErrorText(error) }))
  } else {
    // 스트림이 열렸으면 서버에 진행 중인 답변이 있다. 지난 세션은 이때부터 중지할 수 있다(새 세션은 session 이벤트 뒤).
    if (sessionId !== null && gen === live.generation) ctx.patch(() => ({ canStop: true }))
    await readAnswer(ctx, data, { gen, update, title: title ?? text, sessionId })
  }
  if (gen === live.generation) ctx.patch(() => ({ streaming: false, canStop: false }))
}

/** 질문 하나의 답변 읽기. 다른 세션으로 바꿔도(generation이 바뀌어도) 끝까지 읽는다. */
interface Run {
  gen: number
  update: (fn: (item: ChatItem) => ChatItem) => void
  title: string
  /** 이 질문의 세션. 새 세션이면 `session` 이벤트로 정해진다. */
  sessionId: string | null
}

async function readAnswer(ctx: Ctx, stream: ReadableStream<Uint8Array>, run: Run): Promise<void> {
  const current = (): boolean => run.gen === ctx.live.current.generation
  const setAnswer = (fn: AnswerUpdate): void => run.update((i: ChatItem) => ({ ...i, answer: fn(i.answer) }))
  try {
    await streamAnswer(stream, {
      onSessionId: (id: string): void => {
        run.sessionId = id
        if (!current()) return
        ctx.live.current.pendingId = id
        ctx.patch(() => ({ canStop: true }))
      },
      onFirstDelta: (): void => {
        if (current()) ctx.patch(() => ({ title: run.title }))
      },
      onSaved: (): void => markSaved(ctx, run, current()),
      onAnswer: (fn: AnswerUpdate): void => {
        if (current()) setAnswer(fn)
      },
      onError: (message: string): void => {
        if (current()) run.update((i: ChatItem) => ({ ...i, error: message }))
      },
    })
  } catch {
    // 다른 세션을 열어 읽기를 그만뒀거나(무시) 연결이 끊겼다(서버는 답변을 끝까지 저장한다. ADR 0003).
    if (!current()) return
    setAnswer(keepReceivedAsStopped)
    run.update((i: ChatItem) => ({ ...i, error: MESSAGES.serverErrorRetry }))
  }
}

/** 질문과 답변이 저장되었다: 목록 맨 위에 올리고, 아직 보고 있는 세션이면 지금 세션으로 정한다. */
function markSaved(ctx: Ctx, run: Run, current: boolean): void {
  const id: string | null = run.sessionId
  if (id === null) return
  if (current) ctx.patch(() => ({ sessionId: id, title: run.title }))
  ctx.onSessionActive({ id, title: run.title, updatedAt: new Date().toISOString() })
}

function stopAnswer(ctx: Ctx): void {
  const id: string | null = ctx.live.current.pendingId
  if (id === null) return
  // 결과는 SSE의 stopped 이벤트로 온다. 이미 끝났으면(NOT_STREAMING) 할 일이 없다.
  void safely(ctx.client.POST('/api/v1/sessions/{sessionId}/stop', { params: { path: { sessionId: id } } }))
}

async function openSession(ctx: Ctx, session: Session, restart: (next: ChatState, abort: boolean) => number): Promise<void> {
  const gen: number = restart({ ...INITIAL, sessionId: session.id, title: session.title, loading: true }, false)
  const result: ChatItem[] | string = await fetchQuestions(ctx.client, session.id)
  if (gen !== ctx.live.current.generation) return
  ctx.patch(() => (typeof result === 'string' ? { loading: false, loadError: result } : { loading: false, items: result }))
}

/** 질문을 100개씩 끝까지 받아 오래된 순으로 바꾼다. 실패하면 오류 문구. */
async function fetchQuestions(client: ApiClient, sessionId: string): Promise<ChatItem[] | string> {
  const all: ChatItem[] = []
  let cursor: string | undefined = undefined
  do {
    const page: QuestionPage | string = await fetchQuestionPage(client, sessionId, cursor)
    if (typeof page === 'string') return page
    for (const q of page.items) all.push({ key: q.id, question: q.text, answer: { text: q.answer.text, status: q.answer.status }, error: null })
    cursor = page.nextCursor
  } while (cursor !== undefined)
  return all.reverse()
}

async function fetchQuestionPage(client: ApiClient, sessionId: string, cursor: string | undefined): Promise<QuestionPage | string> {
  const { data, error } = await safely(
    client.GET('/api/v1/sessions/{sessionId}/questions', { params: { path: { sessionId }, query: { cursor, limit: 100 } } }),
  )
  return data ?? errorText(error)
}
