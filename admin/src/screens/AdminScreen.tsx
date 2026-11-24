import { useState, type JSX } from 'react'
import { Button } from '@primer/react'
import { PlusIcon } from '@primer/octicons-react'
import type { ApiClient } from '../api/client'
import { ConfirmDialog } from '../components/ConfirmDialog'
import { CreateDialog } from '../components/CreateDialog'
import { ErrorFlash } from '../components/FormParts'
import { SecretDialog } from '../components/SecretDialog'
import { UserList } from '../components/UserList'
import type { IssuedSecret, User } from '../users/types'
import { useCreateUser, type CreateUser } from '../users/useCreateUser'
import { useUserActions, type UserActions } from '../users/useUserActions'
import { useUsers, type Users } from '../users/useUsers'

export interface AdminScreenProps {
  client: ApiClient
  loginId: string
}

/** 로그인 뒤 관리자 화면: 머리글과 사용자 계정 관리(샘플 #4). */
export function AdminScreen({ client, loginId }: AdminScreenProps): JSX.Element {
  const list: Users = useUsers(client)
  const [secret, setSecret] = useState<IssuedSecret | null>(null)
  const [notice, setNotice] = useState<string | null>(null)
  const create: CreateUser = useCreateUser(client, (user: User, issued: IssuedSecret): void => {
    list.prepend(user)
    setSecret(issued)
  })
  const actions: UserActions = useUserActions(client, { onChanged: list.replace, onIssued: setSecret })
  const report = (work: Promise<string | null>): void => { setNotice(null); void work.then(setNotice) }

  return (
    <div className="shell">
      <Header loginId={loginId} />
      <main className="page">
        <div className="page__inner">
          <div className="page__head">
            <h2 className="page__title">사용자 계정</h2>
            <Button variant="primary" leadingVisual={PlusIcon} onClick={create.start} disabled={list.state === 'loading'}>계정 등록</Button>
          </div>
          {notice !== null && <ErrorFlash text={notice} />}
          <UserList list={list} unblocking={actions.unblocking} onBlock={(u: User): void => actions.ask('block', u)} onReset={(u: User): void => actions.ask('reset', u)}
            onUnblock={(u: User): void => report(actions.unblock(u))} onLoadMore={(): void => report(list.loadMore())} />
        </div>
      </main>
      <Dialogs create={create} actions={actions} secret={secret} onSecretDone={(): void => setSecret(null)} />
    </div>
  )
}

function Header({ loginId }: { loginId: string }): JSX.Element {
  return (
    <header className="header">
      <h1 className="header__brand">Iris 관리자</h1>
      <span className="header__user">{loginId}</span>
    </header>
  )
}

interface DialogsProps {
  create: CreateUser
  actions: UserActions
  secret: IssuedSecret | null
  onSecretDone: () => void
}

/** 지금 열린 대화상자(등록, 차단·초기화 확인, 임시 비밀번호). */
function Dialogs({ create, actions, secret, onSecretDone }: DialogsProps): JSX.Element {
  return (
    <>
      {create.open && (
        <CreateDialog error={create.error} busy={create.busy} onCancel={create.cancel} onEdit={create.clearError} onSubmit={(id: string): void => { void create.submit(id) }} />
      )}
      {actions.pending !== null && (
        <ConfirmDialog pending={actions.pending} error={actions.error} busy={actions.busy} onCancel={actions.cancel} onConfirm={(): void => { void actions.confirm() }} />
      )}
      {secret !== null && <SecretDialog secret={secret} onDone={onSecretDone} />}
    </>
  )
}
