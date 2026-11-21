import { describe, expect, it } from 'vitest'
import { readSse, type SseEvent } from './sse'

function streamOf(chunks: string[]): ReadableStream<Uint8Array> {
  const encoder: TextEncoder = new TextEncoder()
  return new ReadableStream<Uint8Array>({
    start(controller: ReadableStreamDefaultController<Uint8Array>): void {
      chunks.forEach((c: string): void => controller.enqueue(encoder.encode(c)))
      controller.close()
    },
  })
}

async function collect(chunks: string[]): Promise<SseEvent[]> {
  const events: SseEvent[] = []
  await readSse(streamOf(chunks), (e: SseEvent): void => {
    events.push(e)
  })
  return events
}

describe('readSse', () => {
  it('이벤트 이름과 JSON 데이터를 읽는다', async () => {
    const events: SseEvent[] = await collect([
      'event: session\ndata: {"id": "s1"}\n\n',
      'event: delta\ndata: {"text": "안녕"}\n\n',
      'event: done\ndata: {"answerId": "a1"}\n\n',
    ])

    expect(events).toEqual([
      { event: 'session', data: { id: 's1' } },
      { event: 'delta', data: { text: '안녕' } },
      { event: 'done', data: { answerId: 'a1' } },
    ])
  })

  it('조각이 이벤트 중간에서 잘려 와도 이어 붙인다(한글 바이트 포함)', async () => {
    const encoder: TextEncoder = new TextEncoder()
    const bytes: Uint8Array = encoder.encode('event: delta\ndata: {"text": "하세요"}\n\n')
    const stream: ReadableStream<Uint8Array> = new ReadableStream<Uint8Array>({
      start(controller: ReadableStreamDefaultController<Uint8Array>): void {
        controller.enqueue(bytes.slice(0, 25))
        controller.enqueue(bytes.slice(25))
        controller.close()
      },
    })
    const events: SseEvent[] = []

    await readSse(stream, (e: SseEvent): void => {
      events.push(e)
    })

    expect(events).toEqual([{ event: 'delta', data: { text: '하세요' } }])
  })

  it('keepalive 주석 줄은 무시하고 CRLF 줄바꿈도 읽는다', async () => {
    const events: SseEvent[] = await collect([
      ': keepalive\n\n',
      'event: stopped\r\ndata: {"answerId": "a2"}\r\n\r\n',
    ])

    expect(events).toEqual([{ event: 'stopped', data: { answerId: 'a2' } }])
  })

  it('CRLF가 조각 경계에서 \\r과 \\n으로 나뉘어 와도 읽는다', async () => {
    const events: SseEvent[] = await collect(['event: delta\r', '\ndata: {"text": "가"}\r\n\r', '\n'])

    expect(events).toEqual([{ event: 'delta', data: { text: '가' } }])
  })

  it('콜론 뒤에 공백이 없어도 읽는다(SSE 표준)', async () => {
    const events: SseEvent[] = await collect(['event:delta\ndata:{"text": " 앞 공백"}\n\n'])

    expect(events).toEqual([{ event: 'delta', data: { text: ' 앞 공백' } }])
  })

  it('알 수 없는 이벤트와 JSON이 아닌 데이터는 건너뛴다', async () => {
    const events: SseEvent[] = await collect([
      'event: unknown\ndata: {}\n\n',
      'event: delta\ndata: not-json\n\n',
      'event: error\ndata: {"code": "SERVER_ERROR", "message": "서버 오류가 발생했습니다."}\n\n',
    ])

    expect(events).toEqual([
      { event: 'error', data: { code: 'SERVER_ERROR', message: '서버 오류가 발생했습니다.' } },
    ])
  })
})
