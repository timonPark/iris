export interface ApiResult<D, E> {
  data?: D
  error?: E
}

/** 연결 실패처럼 fetch가 던지는 오류를 `{ data, error }`가 모두 없는 결과로 바꾼다. */
export async function safely<D, E>(call: Promise<ApiResult<D, E>>): Promise<ApiResult<D, E>> {
  try {
    const { data, error } = await call
    return { data, error }
  } catch {
    return {}
  }
}
