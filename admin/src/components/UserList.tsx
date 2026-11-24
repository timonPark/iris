import type { JSX } from 'react'
import { Button } from '@primer/react'
import { MESSAGES } from '../auth/messages'
import type { User } from '../users/types'
import type { Users } from '../users/useUsers'
import { ErrorFlash } from './FormParts'
import { UserTable } from './UserTable'

export interface UserListProps {
  list: Users
  /** 해제를 기다리는 계정의 ID. */
  unblocking: string | null
  onBlock: (user: User) => void
  onUnblock: (user: User) => void
  onReset: (user: User) => void
  onLoadMore: () => void
}

/** 목록 본문: 불러오는 중, 오류(다시 시도), 빈 목록, 목록과 "더 보기"(샘플 #4). */
export function UserList({ list, unblocking, onBlock, onUnblock, onReset, onLoadMore }: UserListProps): JSX.Element | null {
  if (list.state === 'loading') return null
  if (list.state === 'error') return <ListError onRetry={list.retry} />
  if (list.users.length === 0) return <EmptyList />
  return (
    <>
      <UserTable users={list.users} unblocking={unblocking} onBlock={onBlock} onUnblock={onUnblock} onReset={onReset} />
      {list.nextCursor !== undefined && (
        <div className="list-foot">
          <Button onClick={onLoadMore} loading={list.loadingMore}>더 보기</Button>
        </div>
      )}
    </>
  )
}

/** 목록을 받지 못했을 때(샘플 #4 `users-error`). */
function ListError({ onRetry }: { onRetry: () => void }): JSX.Element {
  return (
    <>
      <ErrorFlash text={MESSAGES.listError} />
      <div><Button onClick={onRetry}>다시 시도</Button></div>
    </>
  )
}

/** 등록한 사용자 계정이 없을 때(샘플 #4 `users-empty`). */
function EmptyList(): JSX.Element {
  return (
    <div className="card">
      <div className="empty">
        <p className="empty__title">등록한 사용자 계정이 없습니다</p>
        <p className="empty__desc">계정을 등록하면 임시 비밀번호가 만들어집니다. 사용자에게 아이디와 함께 전달해 주세요.</p>
      </div>
    </div>
  )
}
