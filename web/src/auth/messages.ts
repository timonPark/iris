import type { ErrorResponse } from '../api/client'

/**
 * 화면 문구. 오류 문구는 `docs/api/openapi.yaml`의 `message`를 그대로 쓰고,
 * 샘플(#3)에서 정한 안내만 덧붙인다.
 */
export const MESSAGES = {
  blocked: '차단된 계정입니다. 관리자에게 문의해 주세요.',
  adminAccount: '관리자 계정은 관리자 웹을 이용해 주세요.',
  unauthorized: '다시 로그인해 주세요.',
  serverError: '서버 오류가 발생했습니다.',
  passwordMismatch: '새 비밀번호가 서로 다릅니다.',
  passwordTooShort: '새 비밀번호는 8자 이상이어야 합니다.',
  currentPasswordWrong: '현재 비밀번호가 올바르지 않습니다.',
  passwordChanged: '비밀번호를 변경했습니다.',
  serverErrorRetry: '서버 오류가 발생했습니다. 잠시 후 다시 질문해 주세요.',
  questionTooLong: '질문은 65,536자까지 보낼 수 있습니다.',
} as const

export const MIN_PASSWORD_LENGTH: number = 8

/** 오류 응답을 화면 문구로. 응답 본문이 없으면(연결 실패 등) 서버 오류. */
export function errorText(error: ErrorResponse | undefined): string {
  if (error === undefined) {
    return MESSAGES.serverError
  }
  if (error.error.code === 'ACCOUNT_BLOCKED') {
    return MESSAGES.blocked
  }
  return error.error.message
}

/** 채팅의 오류 문구. 서버 오류와 연결 실패에는 샘플(#3)의 "잠시 후 다시 질문해 주세요."를 덧붙인다. */
export function chatErrorText(error: ErrorResponse | undefined): string {
  if (error === undefined || error.error.code === 'SERVER_ERROR') {
    return MESSAGES.serverErrorRetry
  }
  return errorText(error)
}

/** 새 비밀번호 확인. 문제가 없으면 null. */
export function newPasswordProblem(newPassword: string, confirm: string): string | null {
  if (newPassword.length < MIN_PASSWORD_LENGTH) {
    return MESSAGES.passwordTooShort
  }
  if (newPassword !== confirm) {
    return MESSAGES.passwordMismatch
  }
  return null
}
