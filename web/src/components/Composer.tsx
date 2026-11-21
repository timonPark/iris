import { useRef, useState, type ChangeEvent, type JSX, type KeyboardEvent, type RefObject } from 'react'
import { Button, IconButton } from '@primer/react'
import { ArrowUpIcon, SquareFillIcon } from '@primer/octicons-react'
import { MESSAGES } from '../auth/messages'
import { MAX_QUESTION_LENGTH, questionLength } from '../chat/types'
import { ErrorFlash } from './FormParts'

export interface ComposerProps {
  streaming: boolean
  /** 지난 세션을 불러오는 중. 끝나기 전에 보내면 불러온 내용이 보낸 질문을 덮는다. */
  loading: boolean
  canStop: boolean
  onSend: (text: string) => void
  onStop: () => void
}

/** 질문 입력. Enter로 보내고 Shift+Enter로 줄을 바꾼다. 답변을 받는 동안에는 보내기 자리에 중지 버튼. */
export function Composer({ streaming, loading, canStop, onSend, onStop }: ComposerProps): JSX.Element {
  const box: ComposerInput = useComposerInput(streaming || loading, onSend)
  return (
    <div className="composer">
      {box.tooLong && <div className="composer__notice"><ErrorFlash text={MESSAGES.questionTooLong} /></div>}
      <div className="composer__box">
        <textarea ref={box.ref} className="composer__input" rows={1} placeholder="질문을 입력하세요" aria-label="질문" value={box.text} onChange={box.onChange} onKeyDown={box.onKeyDown} />
        {streaming ? (
          <Button leadingVisual={SquareFillIcon} onClick={onStop} disabled={!canStop}>중지</Button>
        ) : (
          <IconButton icon={ArrowUpIcon} variant="primary" aria-label="질문 보내기" unsafeDisableTooltip onClick={box.submit} disabled={loading || box.text.trim() === ''} />
        )}
      </div>
      <p className="composer__hint">Enter로 보내고 Shift+Enter로 줄을 바꿉니다.</p>
    </div>
  )
}

interface ComposerInput {
  ref: RefObject<HTMLTextAreaElement | null>
  text: string
  tooLong: boolean
  submit: () => void
  onChange: (event: ChangeEvent<HTMLTextAreaElement>) => void
  onKeyDown: (event: KeyboardEvent<HTMLTextAreaElement>) => void
}

function useComposerInput(busy: boolean, onSend: (text: string) => void): ComposerInput {
  const [text, setText] = useState<string>('')
  const [tooLong, setTooLong] = useState<boolean>(false)
  const ref: RefObject<HTMLTextAreaElement | null> = useRef<HTMLTextAreaElement>(null)

  function submit(): void {
    if (busy || text.trim() === '') return
    const over: boolean = questionLength(text) > MAX_QUESTION_LENGTH
    setTooLong(over)
    if (over) return
    onSend(text)
    setText('')
    if (ref.current !== null) ref.current.style.height = ''
  }

  function onKeyDown(event: KeyboardEvent<HTMLTextAreaElement>): void {
    // 한글 조합 중의 Enter는 글자를 확정하는 키라서 보내지 않는다.
    if (event.key !== 'Enter' || event.shiftKey || event.nativeEvent.isComposing) return
    event.preventDefault()
    submit()
  }

  function onChange(event: ChangeEvent<HTMLTextAreaElement>): void {
    setText(event.target.value)
    setTooLong(false)
    autoGrow(event.target)
  }

  return { ref, text, tooLong, submit, onChange, onKeyDown }
}

/** 내용에 맞춰 높이를 늘린다. 최대 높이는 CSS(max-height)가 정한다. */
function autoGrow(el: HTMLTextAreaElement): void {
  el.style.height = 'auto'
  el.style.height = `${el.scrollHeight}px`
}
