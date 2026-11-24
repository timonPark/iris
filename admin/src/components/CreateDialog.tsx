import { useState, type ChangeEvent, type FormEvent, type JSX } from 'react'
import { Dialog, FormControl, TextInput } from '@primer/react'
import { TitleOnly } from './TitleOnly'

export interface CreateDialogProps {
  error: string | null
  busy: boolean
  onCancel: () => void
  onEdit: () => void
  onSubmit: (loginId: string) => void
}

const FORM_ID: string = 'create-user-form'

/** 사용자 계정 등록(샘플 #4 `create`, `create-taken`). 아이디만 입력하고 비밀번호는 시스템이 만든다. */
export function CreateDialog({ error, busy, onCancel, onEdit, onSubmit }: CreateDialogProps): JSX.Element {
  const [loginId, setLoginId] = useState<string>('')
  const submit = (e: FormEvent<HTMLFormElement>): void => { e.preventDefault(); onSubmit(loginId) }

  return (
    <Dialog
      title="사용자 계정 등록"
      width="medium"
      onClose={onCancel}
      renderHeader={TitleOnly}
      footerButtons={[
        { buttonType: 'default', content: '취소', onClick: onCancel },
        { buttonType: 'primary', content: '등록', type: 'submit', form: FORM_ID, loading: busy },
      ]}
    >
      <form id={FORM_ID} className="dialog__form" onSubmit={submit}>
        <LoginIdField value={loginId} onChange={(v: string): void => { setLoginId(v); onEdit() }} error={error} />
        <p className="dialog__body dialog__hint">비밀번호는 시스템이 만들어 다음 화면에 한 번만 보여 줍니다.</p>
      </form>
    </Dialog>
  )
}

interface LoginIdFieldProps {
  value: string
  onChange: (value: string) => void
  error: string | null
}

/** 아이디 입력칸. 오류(아이디 중복, 형식)는 입력칸 아래에 규격의 문구로 보여 준다. */
function LoginIdField({ value, onChange, error }: LoginIdFieldProps): JSX.Element {
  return (
    <FormControl>
      <FormControl.Label>아이디</FormControl.Label>
      <TextInput
        className="field-input"
        autoComplete="off"
        value={value}
        onChange={(e: ChangeEvent<HTMLInputElement>): void => onChange(e.target.value)}
        validationStatus={error === null ? undefined : 'error'}
        size="large"
        block
      />
      {error !== null && <FormControl.Validation variant="error">{error}</FormControl.Validation>}
      <FormControl.Caption>영문 소문자와 숫자 4~20자</FormControl.Caption>
    </FormControl>
  )
}
