import type { ErrorResponse } from '../api/client'

/** 화면 문구. 오류 문구는 `docs/api/openapi.yaml`의 `message`를 그대로 쓰고, 샘플(#4)에서 정한 안내만 덧붙인다. */
export const MESSAGES = {
  notAdmin: '관리자 계정만 로그인할 수 있습니다.',
  serverError: '서버 오류가 발생했습니다.',
  relogin: '다시 로그인해 주세요.',
  listError: '서버 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.',
} as const

/** 관리자 API 오류를 화면 문구로. 응답이 없거나 규격 모양이 아니면 서버 오류, 그 밖에는 규격의 `message`. */
export function errorText(error: unknown): string {
  return isErrorResponse(error) ? error.error.message : MESSAGES.serverError
}

/** 로그인 오류를 화면 문구로. 차단된 계정은 사용자 계정이므로 관리자 아님과 같게 안내한다.
 * 응답이 없거나(연결 실패) 규격 모양이 아니면(터널이 꺼졌을 때의 HTML 등) 서버 오류. */
export function loginErrorText(error: ErrorResponse | undefined): string {
  if (!isErrorResponse(error)) {
    return MESSAGES.serverError
  }
  if (error.error.code === 'ACCOUNT_BLOCKED') {
    return MESSAGES.notAdmin
  }
  return error.error.message
}

function isErrorResponse(value: unknown): value is ErrorResponse {
  if (typeof value !== 'object' || value === null) return false
  const inner: unknown = (value as { error?: unknown }).error
  return typeof inner === 'object' && inner !== null && typeof (inner as { message?: unknown }).message === 'string'
}
