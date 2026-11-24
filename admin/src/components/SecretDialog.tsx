import { useState, type JSX } from 'react'
import { Button, Dialog, Flash } from '@primer/react'
import { AlertIcon, CheckIcon, CopyIcon } from '@primer/octicons-react'
import type { IssuedSecret } from '../users/types'
import { TitleOnly } from './TitleOnly'

export interface SecretDialogProps {
  secret: IssuedSecret
  onDone: () => void
}

const TITLE: Record<IssuedSecret['kind'], string> = {
  created: '계정을 등록했습니다',
  reset: '비밀번호를 초기화했습니다',
}

/** Esc로 닫으면 임시 비밀번호를 다시 볼 수 없으므로 "전달했습니다"로만 닫는다. */
const stayOpen = (): void => {}

/** 임시 비밀번호를 한 번만 보여 준다(샘플 #4 `create-done`, `reset-done`). 닫으면 다시 볼 수 없다. */
export function SecretDialog({ secret, onDone }: SecretDialogProps): JSX.Element {
  return (
    <Dialog
      title={TITLE[secret.kind]}
      width="large"
      onClose={stayOpen}
      renderHeader={TitleOnly}
      footerButtons={[{ buttonType: 'primary', content: '전달했습니다', leadingVisual: CheckIcon, onClick: onDone }]}
    >
      <div className="dialog__stack">
        <Flash variant="warning" className="form-flash">
          <AlertIcon aria-hidden="true" />
          <p>임시 비밀번호는 지금만 볼 수 있습니다. 창을 닫기 전에 사용자에게 전달해 주세요.</p>
        </Flash>
        <div className="secret">
          <span className="secret__label">아이디</span>
          <span className="secret__id">{secret.loginId}</span>
        </div>
        <div className="secret">
          <span className="secret__label">임시 비밀번호</span>
          <div className="secret__row">
            <span className="secret__value">{secret.temporaryPassword}</span>
            <CopyButton value={secret.temporaryPassword} />
          </div>
        </div>
        <p className="dialog__body dialog__hint">사용자는 이 비밀번호로 로그인한 뒤 바로 새 비밀번호로 바꿔야 합니다.</p>
      </div>
    </Dialog>
  )
}

/** 복사 버튼. 복사하면 "복사함"으로 바뀐다. 복사할 수 없는 환경이면 값을 직접 선택해 복사한다(user-select: all). */
function CopyButton({ value }: { value: string }): JSX.Element {
  const [copied, setCopied] = useState<boolean>(false)
  const copy = (): void => {
    navigator.clipboard?.writeText(value).then((): void => setCopied(true), (): void => {})
  }
  return (
    <Button size="small" leadingVisual={copied ? CheckIcon : CopyIcon} aria-label="임시 비밀번호 복사" onClick={copy}>
      {copied ? '복사함' : '복사'}
    </Button>
  )
}
