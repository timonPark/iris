import { useState, type FormEvent, type JSX } from 'react'
import { Button } from '@primer/react'
import type { ApiClient } from '../api/client'
import { usePasswordChange, type PasswordChange } from '../auth/usePasswordChange'
import { ErrorFlash, TextField } from '../components/FormParts'

export interface ForceChangeScreenProps {
  client: ApiClient
  onChanged: (accessToken: string) => void
}

/** 임시 비밀번호로 로그인한 직후. 바꾸기 전에는 다른 화면으로 갈 수 없다. */
export function ForceChangeScreen({ client, onChanged }: ForceChangeScreenProps): JSX.Element {
  const [newPassword, setNewPassword] = useState<string>('')
  const [confirm, setConfirm] = useState<string>('')
  const { error, busy, change }: PasswordChange = usePasswordChange(client, onChanged)

  async function submit(event: FormEvent<HTMLFormElement>): Promise<void> {
    event.preventDefault()
    await change({ newPassword, confirm })
  }

  return (
    <section className="auth">
      <form className="auth__card" onSubmit={submit}>
        <h1 className="auth__title">비밀번호 변경</h1>
        <p className="auth__desc">임시 비밀번호로 로그인했습니다. 계속하려면 새 비밀번호로 바꿔 주세요.</p>
        {error !== null && <ErrorFlash text={error} />}
        <TextField label="새 비밀번호" type="password" value={newPassword} onChange={setNewPassword} autoComplete="new-password" caption="8자 이상" />
        <TextField label="새 비밀번호 확인" type="password" value={confirm} onChange={setConfirm} autoComplete="new-password" />
        <Button type="submit" variant="primary" size="large" block loading={busy}>
          변경하고 계속하기
        </Button>
      </form>
    </section>
  )
}
