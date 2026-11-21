import { vi } from 'vitest'

/** JSON 응답, 또는 SSE 스트림 응답(`stream`). status 204는 본문 없이 돌려준다. */
export interface FakeReply {
  status: number
  body?: unknown
  stream?: ReadableStream<Uint8Array>
  /** 이 약속이 풀릴 때까지 응답을 미룬다(불러오는 중 화면 확인용). */
  wait?: Promise<void>
}

export interface SentRequest {
  method: string
  path: string
  query: string
  authorization: string | null
  body: unknown
}

export interface FakeApi {
  fetch: typeof fetch
  sent: SentRequest[]
}

async function record(request: Request): Promise<SentRequest> {
  const url: URL = new URL(request.url)
  const text: string = await request.text()
  return {
    method: request.method,
    path: url.pathname,
    query: url.search,
    authorization: request.headers.get('Authorization'),
    body: text === '' ? null : JSON.parse(text),
  }
}

function toResponse(reply: FakeReply): Response {
  if (reply.stream !== undefined) {
    return new Response(reply.stream, { status: reply.status, headers: { 'Content-Type': 'text/event-stream' } })
  }
  if (reply.status === 204) {
    return new Response(null, { status: 204 })
  }
  return new Response(JSON.stringify(reply.body), {
    status: reply.status,
    headers: { 'Content-Type': 'application/json' },
  })
}

/** 경로("POST /api/v1/auth/login")별 응답을 순서대로 돌려주는 가짜 fetch. 응답이 없으면 네트워크 오류. */
export function fakeApi(replies: Record<string, FakeReply[]>): FakeApi {
  const sent: SentRequest[] = []
  const fetchImpl = vi.fn(async (input: RequestInfo | URL): Promise<Response> => {
    const request: Request = input as Request
    const entry: SentRequest = await record(request)
    sent.push(entry)
    const reply: FakeReply | undefined = replies[`${entry.method} ${entry.path}`]?.shift()
    if (reply === undefined) {
      throw new TypeError('Failed to fetch')
    }
    await reply.wait
    return toResponse(reply)
  })
  return { fetch: fetchImpl as unknown as typeof fetch, sent }
}

export function apiError(status: number, code: string, message: string): FakeReply {
  return { status, body: { error: { code, message } } }
}

/** 한 번에 끝나는 SSE 응답. events: [이벤트 이름, 데이터] */
export function sseReply(events: Array<[string, unknown]>): FakeReply {
  const stream: ControlledSse = controlledSse()
  events.forEach(([name, data]: [string, unknown]): void => stream.push(name, data))
  stream.close()
  return stream.reply
}

export interface ControlledSse {
  reply: FakeReply
  push: (event: string, data: unknown) => void
  close: () => void
}

/** 테스트가 이벤트를 하나씩 흘려보내는 SSE 응답(스트리밍 중 화면 확인용). */
export function controlledSse(): ControlledSse {
  const encoder: TextEncoder = new TextEncoder()
  let controller: ReadableStreamDefaultController<Uint8Array> | null = null
  const stream: ReadableStream<Uint8Array> = new ReadableStream<Uint8Array>({
    start(c: ReadableStreamDefaultController<Uint8Array>): void {
      controller = c
    },
  })
  return {
    reply: { status: 200, stream },
    push: (event: string, data: unknown): void =>
      controller?.enqueue(encoder.encode(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`)),
    close: (): void => controller?.close(),
  }
}
