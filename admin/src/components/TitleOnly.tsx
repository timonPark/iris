import type { JSX } from 'react'
import { Dialog, type DialogHeaderProps } from '@primer/react'

/** 제목만 있는 대화상자 머리. 샘플(#4)에는 닫기(X) 버튼이 없고, Primer 기본 닫기 버튼 이름은 영어("Close")다. Esc로는 닫힌다. */
export function TitleOnly({ dialogLabelId, title }: DialogHeaderProps): JSX.Element {
  return (
    <Dialog.Header>
      <Dialog.Title id={dialogLabelId}>{title}</Dialog.Title>
    </Dialog.Header>
  )
}
