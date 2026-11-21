import { Fragment, useEffect, useRef, type JSX, type RefObject, type UIEvent } from 'react'
import type { ChatAnswer, ChatItem } from '../chat/types'
import { ErrorFlash } from './FormParts'

export interface ThreadProps {
  items: ChatItem[]
  loading: boolean
  loadError: string | null
}

/** 세션의 질문과 답변. 비어 있으면 새 세션 안내. */
export function Thread({ items, loading, loadError }: ThreadProps): JSX.Element {
  const { end, onScroll }: FollowBottom = useFollowBottom(items)

  if (items.length === 0 && !loading && loadError === null) {
    return (
      <div className="empty">
        <p className="empty__title">Iris에게 질문하세요</p>
        <p className="empty__desc">지난 대화는 세션 목록에서 볼 수 있습니다.</p>
      </div>
    )
  }
  return (
    <div className="thread" onScroll={onScroll}>
      <div className="thread__inner">
        {loadError !== null && <ErrorFlash text={loadError} />}
        {items.map((item: ChatItem) => (
          <Fragment key={item.key}>
            <p className="question">{item.question}</p>
            {item.answer !== null && <Answer answer={item.answer} />}
            {item.error !== null && <ErrorFlash text={item.error} />}
          </Fragment>
        ))}
        <div ref={end} />
      </div>
    </div>
  )
}

/** 맨 아래에서 이만큼(px) 안쪽이면 "맨 아래를 보는 중"으로 본다. */
const NEAR_BOTTOM: number = 64

interface FollowBottom {
  end: RefObject<HTMLDivElement | null>
  onScroll: (event: UIEvent<HTMLDivElement>) => void
}

/**
 * 답변이 늘어날 때 맨 아래를 보고 있으면 따라 내려간다. 위로 올려 읽는 중이면 그대로 둔다.
 * 질문이 새로 붙거나 세션을 열면(항목 수가 늘면) 항상 맨 아래로 간다.
 */
function useFollowBottom(items: ChatItem[]): FollowBottom {
  const end: RefObject<HTMLDivElement | null> = useRef<HTMLDivElement>(null)
  const atBottom: RefObject<boolean> = useRef<boolean>(true)
  const count: RefObject<number> = useRef<number>(0)
  useEffect((): void => {
    const grew: boolean = items.length > count.current
    count.current = items.length
    if (grew || atBottom.current) end.current?.scrollIntoView({ block: 'end' })
  }, [items])
  const onScroll = (event: UIEvent<HTMLDivElement>): void => {
    const el: HTMLDivElement = event.currentTarget
    atBottom.current = el.scrollHeight - el.scrollTop - el.clientHeight < NEAR_BOTTOM
  }
  return { end, onScroll }
}

function Answer({ answer }: { answer: ChatAnswer }): JSX.Element {
  const streaming: boolean = answer.status === 'streaming'
  return (
    <div className="answer">
      {answer.text !== '' && (
        <p>
          {answer.text}
          {streaming && <span className="caret" aria-hidden="true" />}
        </p>
      )}
      {streaming && <div className="answer__meta" aria-live="polite">답변을 받는 중…</div>}
      {answer.status === 'stopped' && (
        <div className="answer__meta">
          <span className="label">중단됨</span>
        </div>
      )}
    </div>
  )
}
