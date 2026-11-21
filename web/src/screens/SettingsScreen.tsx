import { useState, type FormEvent, type JSX } from 'react'
import { Button } from '@primer/react'
import type { ApiClient } from '../api/client'
import { MESSAGES } from '../auth/messages'
import { usePasswordChange, type PasswordChange } from '../auth/usePasswordChange'
import { ErrorFlash, SuccessFlash, TextField } from '../components/FormParts'

export interface SettingsScreenProps {
  client: ApiClient
  onChanged: (accessToken: string) => void
}

interface Fields {
  current: string
  newPassword: string
  confirm: string
}

const EMPTY: Fields = { current: '', newPassword: '', confirm: '' }

/** 설정 본문. 채팅 화면 틀(ChatScreen)의 본문 자리에 들어가고, 제목 "설정"은 틀의 위쪽 막대에 있다. */
export function SettingsScreen(props: SettingsScreenProps): JSX.Element {
  return (
    <div className="page">
      <PasswordPanel {...props} />
    </div>
  )
}

function PasswordPanel({ client, onChanged }: SettingsScreenProps): JSX.Element {
  const [fields, setFields] = useState<Fields>(EMPTY)
  const [done, setDone] = useState<boolean>(false)
  const { error, busy, change }: PasswordChange = usePasswordChange(client, onChanged)
  const set: (key: keyof Fields) => (value: string) => void = (key) => (value) =>
    setFields((prev: Fields): Fields => ({ ...prev, [key]: value }))

  async function submit(event: FormEvent<HTMLFormElement>): Promise<void> {
    event.preventDefault()
    setDone(false)
    const ok: boolean = await change({ currentPassword: fields.current, newPassword: fields.newPassword, confirm: fields.confirm })
    if (ok) setFields(EMPTY)
    setDone(ok)
  }

  return (
    <form className="panel" onSubmit={submit}>
      <h3 className="panel__title">비밀번호 변경</h3>
      {error !== null && <ErrorFlash text={error} />}
      {done && <SuccessFlash text={MESSAGES.passwordChanged} />}
      <TextField label="현재 비밀번호" type="password" value={fields.current} onChange={set('current')} autoComplete="current-password" />
      <TextField label="새 비밀번호" type="password" value={fields.newPassword} onChange={set('newPassword')} autoComplete="new-password" caption="8자 이상" />
      <TextField label="새 비밀번호 확인" type="password" value={fields.confirm} onChange={set('confirm')} autoComplete="new-password" />
      <div className="panel__actions">
        <Button type="submit" variant="primary" loading={busy}>비밀번호 변경</Button>
      </div>
    </form>
  )
}
