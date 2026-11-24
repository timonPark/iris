import { useState, type FormEvent, type JSX } from 'react'
import { Button } from '@primer/react'
import type { ApiClient } from '../api/client'
import type { StoredAuth } from '../auth/storage'
import { useLogin, type Login } from '../auth/useLogin'
import { ErrorFlash, TextField } from '../components/FormParts'

export interface LoginScreenProps {
  client: ApiClient
  onLoggedIn: (auth: StoredAuth) => void
}

/** 샘플(#4) `login`, `login-not-admin`. 관리자 계정은 설정으로만 만들므로 계정 요청 안내는 없다. */
export function LoginScreen({ client, onLoggedIn }: LoginScreenProps): JSX.Element {
  const [loginId, setLoginId] = useState<string>('')
  const [password, setPassword] = useState<string>('')
  const { error, busy, login }: Login = useLogin(client, onLoggedIn)

  function submit(e: FormEvent<HTMLFormElement>): void {
    e.preventDefault()
    void login(loginId, password)
  }

  return (
    <main className="auth">
      <form className="auth__card" onSubmit={submit}>
        <h1 className="auth__brand">Iris</h1>
        <p className="auth__sub">관리자 웹</p>
        {error !== null && <ErrorFlash text={error} />}
        <TextField label="아이디" value={loginId} onChange={setLoginId} autoComplete="username" />
        <TextField label="비밀번호" type="password" value={password} onChange={setPassword} autoComplete="current-password" />
        <Button type="submit" variant="primary" size="large" block loading={busy}>
          로그인
        </Button>
      </form>
    </main>
  )
}
