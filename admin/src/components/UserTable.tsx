import type { JSX } from 'react'
import { Button, Label } from '@primer/react'
import { formatDate, type User } from '../users/types'

export interface UserTableProps {
  users: User[]
  /** 해제를 기다리는 계정의 ID. */
  unblocking: string | null
  onBlock: (user: User) => void
  onUnblock: (user: User) => void
  onReset: (user: User) => void
}

/** 사용자 계정 목록(샘플 #4 `users`). 좁은 화면에서는 계정마다 한 장씩 쌓고 칸 이름을 data-label로 보여 준다. */
export function UserTable({ users, unblocking, onBlock, onUnblock, onReset }: UserTableProps): JSX.Element {
  return (
    <div className="card">
      <table className="table">
        <thead>
          <tr>
            <th scope="col">아이디</th><th scope="col">상태</th><th scope="col">비밀번호</th>
            <th scope="col">등록일</th><th scope="col">작업</th>
          </tr>
        </thead>
        <tbody>
          {users.map((user: User): JSX.Element => (
            <UserRow key={user.id} user={user} unblocking={unblocking === user.id} onBlock={onBlock} onUnblock={onUnblock} onReset={onReset} />
          ))}
        </tbody>
      </table>
    </div>
  )
}

interface UserRowProps extends Omit<UserTableProps, 'users' | 'unblocking'> {
  user: User
  unblocking: boolean
}

function UserRow({ user, unblocking, onBlock, onUnblock, onReset }: UserRowProps): JSX.Element {
  const blocked: boolean = user.status === 'blocked'
  return (
    <tr>
      <th scope="row" className="table__id">{user.loginId}</th>
      <td data-label="상태">
        {blocked ? <Label variant="danger">차단 중</Label> : <Label variant="success">활성</Label>}
      </td>
      <td data-label="비밀번호" className={user.passwordChangeRequired ? undefined : 'table__muted'}>
        {user.passwordChangeRequired ? <Label variant="attention">임시 비밀번호</Label> : '설정함'}
      </td>
      <td data-label="등록일" className="table__muted">{formatDate(user.createdAt)}</td>
      <td>
        <div className="table__actions">
          {blocked
            ? <Button size="small" loading={unblocking} aria-label={`${user.loginId} 차단 해제`} onClick={(): void => onUnblock(user)}>차단 해제</Button>
            : <Button size="small" aria-label={`${user.loginId} 차단`} onClick={(): void => onBlock(user)}>차단</Button>}
          <Button size="small" aria-label={`${user.loginId} 비밀번호 초기화`} onClick={(): void => onReset(user)}>비밀번호 초기화</Button>
        </div>
      </td>
    </tr>
  )
}
