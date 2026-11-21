import type { components } from '../api/schema'

export type Session = components['schemas']['Session']

/** 화면의 답변 상태. 저장된 답변은 completed 또는 stopped("중단됨")이고, 받는 중이면 streaming. */
export type ChatAnswerStatus = 'streaming' | 'completed' | 'stopped'

export interface ChatAnswer {
  text: string
  status: ChatAnswerStatus
}

/** 스레드의 질문 하나와 그 답변. 답변 전에 실패하면 answer 없이 error만 있다. */
export interface ChatItem {
  key: string
  question: string
  answer: ChatAnswer | null
  error: string | null
}

/** 백엔드와 같이 코드 포인트(글자) 수로 센다. */
export const MAX_QUESTION_LENGTH: number = 65_536

export function questionLength(text: string): number {
  return [...text].length
}
