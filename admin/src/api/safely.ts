export interface ApiResult<D, E> {
  data?: D
  error?: E
  /** 응답이 왔으면 있다(204처럼 본문이 없는 성공을 확인할 때 쓴다). */
  response?: Response
}

/** 연결 실패처럼 fetch가 던지는 오류를 `{ data, error, response }`가 모두 없는 결과로 바꾼다. */
export async function safely<D, E>(call: Promise<ApiResult<D, E>>): Promise<ApiResult<D, E>> {
  try {
    const { data, error, response } = await call
    return { data, error, response }
  } catch {
    return {}
  }
}
