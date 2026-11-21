/** 질문 전송 SSE 이벤트(docs/api/openapi.yaml 상단의 SSE 표). 음성 전용 `question`은 사용자 웹에서 쓰지 않는다. */
export type SseEvent =
  | { event: 'session'; data: { id: string } }
  | { event: 'delta'; data: { text: string } }
  | { event: 'done'; data: { answerId: string } }
  | { event: 'stopped'; data: { answerId: string } }
  | { event: 'error'; data: { code: string; message: string } }

const KNOWN_EVENTS: ReadonlySet<string> = new Set(['session', 'delta', 'done', 'stopped', 'error'])

/** 스트림을 끝까지 읽으며 이벤트마다 onEvent를 부른다. 주석 줄(`: keepalive`)과 모르는 이벤트는 건너뛴다. */
export async function readSse(
  stream: ReadableStream<Uint8Array>,
  onEvent: (event: SseEvent) => void,
): Promise<void> {
  const reader: ReadableStreamDefaultReader<string> = stream
    .pipeThrough(new TextDecoderStream())
    .getReader()
  let buffer: string = ''
  for (;;) {
    const { done, value } = await reader.read()
    if (done) break
    // 누적한 버퍼 전체를 바꿔야 조각 경계에서 나뉜 \r\n도 합쳐진다.
    buffer = (buffer + value).replace(/\r\n/g, '\n')
    let end: number = buffer.indexOf('\n\n')
    while (end !== -1) {
      const parsed: SseEvent | null = parseBlock(buffer.slice(0, end))
      if (parsed !== null) onEvent(parsed)
      buffer = buffer.slice(end + 2)
      end = buffer.indexOf('\n\n')
    }
  }
}

function parseBlock(block: string): SseEvent | null {
  let name: string = 'message'
  const dataLines: string[] = []
  for (const line of block.split('\n')) {
    if (line.startsWith('event:')) name = fieldValue(line, 'event:')
    else if (line.startsWith('data:')) dataLines.push(fieldValue(line, 'data:'))
  }
  if (!KNOWN_EVENTS.has(name) || dataLines.length === 0) return null
  try {
    return { event: name, data: JSON.parse(dataLines.join('\n')) } as SseEvent
  } catch {
    return null
  }
}

/** SSE 표준: 콜론 뒤의 공백 하나만 뗀다. */
function fieldValue(line: string, field: string): string {
  const value: string = line.slice(field.length)
  return value.startsWith(' ') ? value.slice(1) : value
}
