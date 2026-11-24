import type { components } from '../api/schema'

export type User = components['schemas']['User']
export type UserWithTemporaryPassword = components['schemas']['UserWithTemporaryPassword']
export type UserPage = components['schemas']['UserPage']

/** 임시 비밀번호를 한 번만 보여 줄 대화상자의 내용(등록, 초기화 공통). */
export interface IssuedSecret {
  kind: 'created' | 'reset'
  loginId: string
  temporaryPassword: string
}

/** 등록일. 기기 시간대의 날짜(YYYY-MM-DD). */
export function formatDate(iso: string): string {
  const d: Date = new Date(iso)
  const pad = (n: number): string => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}
