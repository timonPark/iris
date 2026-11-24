import type { JSX } from 'react'
import { Dialog } from '@primer/react'
import type { Pending } from '../users/useUserActions'
import { ErrorFlash } from './FormParts'
import { TitleOnly } from './TitleOnly'

export interface ConfirmDialogProps {
  pending: Pending
  error: string | null
  busy: boolean
  onCancel: () => void
  onConfirm: () => void
}

interface Copy {
  title: string
  body: string
  action: string
}

function copyOf({ kind, user }: Pending): Copy {
  if (kind === 'block') {
    return {
      title: `'${user.loginId}' 계정을 차단할까요?`,
      body: '바로 로그인할 수 없고, 쓰고 있던 화면에서도 로그인이 풀립니다. 세션 기록은 남고, 언제든 차단을 해제할 수 있습니다.',
      action: '차단',
    }
  }
  return {
    title: `'${user.loginId}' 비밀번호를 초기화할까요?`,
    body: '새 임시 비밀번호를 만듭니다. 지금 비밀번호와 로그인 중인 화면은 모두 무효가 됩니다.',
    action: '초기화',
  }
}

/** 차단, 비밀번호 초기화 확인(샘플 #4 `block`, `reset`). */
export function ConfirmDialog({ pending, error, busy, onCancel, onConfirm }: ConfirmDialogProps): JSX.Element {
  const copy: Copy = copyOf(pending)
  return (
    <Dialog
      title={copy.title}
      width="medium"
      onClose={onCancel}
      renderHeader={TitleOnly}
      footerButtons={[
        { buttonType: 'default', content: '취소', onClick: onCancel },
        { buttonType: 'danger', content: copy.action, onClick: onConfirm, loading: busy },
      ]}
    >
      <div className="dialog__stack">
        {error !== null && <ErrorFlash text={error} />}
        <p className="dialog__body">{copy.body}</p>
      </div>
    </Dialog>
  )
}
