import type { JSX } from 'react'
import { Dialog, type DialogHeaderProps } from '@primer/react'
import type { Session } from '../chat/types'
import { ErrorFlash } from './FormParts'

export interface DeleteDialogProps {
  session: Session
  error: string | null
  busy: boolean
  onCancel: () => void
  onConfirm: () => void
}

/** 제목만 있는 머리. 샘플(#3)에는 닫기(X) 버튼이 없고, Primer 기본 닫기 버튼 이름은 영어("Close")다. Esc로는 닫힌다. */
function TitleOnly({ dialogLabelId, title }: DialogHeaderProps): JSX.Element {
  return (
    <Dialog.Header>
      <Dialog.Title id={dialogLabelId}>{title}</Dialog.Title>
    </Dialog.Header>
  )
}

/** 세션 삭제 확인(샘플 #3). 삭제한 세션은 다시 볼 수 없다. */
export function DeleteDialog({ session, error, busy, onCancel, onConfirm }: DeleteDialogProps): JSX.Element {
  return (
    <Dialog
      title="세션을 삭제할까요?"
      width="medium"
      onClose={onCancel}
      renderHeader={TitleOnly}
      footerButtons={[
        { buttonType: 'default', content: '취소', onClick: onCancel },
        { buttonType: 'danger', content: '삭제', onClick: onConfirm, loading: busy },
      ]}
    >
      {error !== null && <ErrorFlash text={error} />}
      <p className="dialog__body">'{session.title}' 세션이 목록에서 사라지고 다시 볼 수 없습니다.</p>
    </Dialog>
  )
}
