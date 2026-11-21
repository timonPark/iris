import { useState, type FormEvent, type JSX } from 'react'
import { Button } from '@primer/react'
import type { ApiClient } from '../api/client'
import { MESSAGES } from '../auth/messages'
import type { StoredAuth } from '../auth/storage'
import { useLogin, type Login } from '../auth/useLogin'
import { ErrorFlash, TextField } from '../components/FormParts'

/** 다른 화면에서 로그인 화면으로 보내진 이유. */
export type LoginNotice = 'blocked' | 'unauthorized'

export interface LoginScreenProps {
  client: ApiClient
  notice: LoginNotice | null
  onLoggedIn: (auth: StoredAuth) => void
}

const NOTICE_TEXT: Record<LoginNotice, string> = {
  blocked: MESSAGES.blocked,
  unauthorized: MESSAGES.unauthorized,
}

export function LoginScreen({ client, notice, onLoggedIn }: LoginScreenProps): JSX.Element {
  const [loginId, setLoginId] = useState<string>('')
  const [password, setPassword] = useState<string>('')
  const { error, busy, login }: Login = useLogin(client, onLoggedIn)
  const flash: string | null = error ?? (notice === null ? null : NOTICE_TEXT[notice])

  return (
    <section className="auth">
      <form className="auth__card" onSubmit={(e: FormEvent<HTMLFormElement>): void => { e.preventDefault(); void login(loginId, password) }}>
        <h1 className="auth__brand">Iris</h1>
        {flash !== null && <ErrorFlash text={flash} />}
        <TextField label="아이디" value={loginId} onChange={setLoginId} autoComplete="username" />
        <TextField label="비밀번호" type="password" value={password} onChange={setPassword} autoComplete="current-password" />
        <Button type="submit" variant="primary" size="large" block loading={busy}>
          로그인
        </Button>
        <p className="auth__note">계정이 없으면 관리자에게 요청해 주세요.</p>
      </form>
    </section>
  )
}
