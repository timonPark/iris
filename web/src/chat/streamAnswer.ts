import type { ErrorResponse } from '../api/client'
import { chatErrorText } from '../auth/messages'
import { readSse, type SseEvent } from './sse'
import type { ChatAnswer } from './types'

export type AnswerUpdate = (answer: ChatAnswer | null) => ChatAnswer | null

export interface AnswerCallbacks {
  /** `session` 이벤트. 중지 API에 쓸 세션 ID. */
  onSessionId: (id: string) => void
  /** 첫 답변 조각. 화면 제목을 정할 때 쓴다(세션은 아직 저장 전이다). */
  onFirstDelta: () => void
  /**
   * 질문과 답변이 저장되었다(`done`, `stopped`, 조각을 받은 뒤의 `error`).
   * 백엔드는 답변을 끝낼 때 세션을 만들므로, 새 세션은 이때부터 목록에 올리고 열 수 있다.
   */
  onSaved: () => void
  onAnswer: (update: AnswerUpdate) => void
  onError: (message: string) => void
}

/** 받은 조각이 있으면 "중단됨"으로 남기고, 없으면 답변을 지운다(서버의 저장 규칙과 같다). */
export const keepReceivedAsStopped: AnswerUpdate = (a: ChatAnswer | null): ChatAnswer | null =>
  a !== null && a.text !== '' ? { text: a.text, status: 'stopped' } : null

/**
 * 질문 전송 SSE를 끝까지 읽어 답변 상태로 바꾼다.
 * `done`/`stopped`/`error` 없이 스트림이 끝나면 오류를 던진다(연결이 끊긴 경우).
 */
export async function streamAnswer(stream: ReadableStream<Uint8Array>, cb: AnswerCallbacks): Promise<void> {
  let received: boolean = false
  let finished: boolean = false
  await readSse(stream, (e: SseEvent): void => {
    if (e.event === 'session') cb.onSessionId(e.data.id)
    if (e.event === 'delta') {
      if (!received) cb.onFirstDelta()
      received = true
      cb.onAnswer((a: ChatAnswer | null): ChatAnswer => ({ text: (a?.text ?? '') + e.data.text, status: 'streaming' }))
    }
    if (e.event === 'done' || e.event === 'stopped') {
      const status: ChatAnswer['status'] = e.event === 'done' ? 'completed' : 'stopped'
      cb.onAnswer((a: ChatAnswer | null): ChatAnswer => ({ text: a?.text ?? '', status }))
    }
    if (e.event === 'error') {
      cb.onAnswer(keepReceivedAsStopped)
      cb.onError(chatErrorText({ error: e.data } as ErrorResponse))
    }
    if (e.event === 'done' || e.event === 'stopped' || (e.event === 'error' && received)) cb.onSaved()
    finished ||= e.event === 'done' || e.event === 'stopped' || e.event === 'error'
  })
  if (!finished) throw new Error('답변이 끝나기 전에 스트림이 닫혔다')
}
