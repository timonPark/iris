import type { JSX } from 'react'
import { Button } from '@primer/react'
import { GearIcon } from '@primer/octicons-react'

export interface ChatPlaceholderProps {
  onOpenSettings: () => void
}

/** 채팅 화면(#24)이 들어갈 자리. 그때까지는 설정으로 가는 버튼만 둔다. */
export function ChatPlaceholder({ onOpenSettings }: ChatPlaceholderProps): JSX.Element {
  return (
    <div className="main">
      <div className="topbar">
        <h2 className="topbar__title">새 세션</h2>
      </div>
      <div className="empty">
        <p className="empty__desc">채팅 화면은 준비 중입니다.</p>
        <Button leadingVisual={GearIcon} onClick={onOpenSettings}>
          설정
        </Button>
      </div>
    </div>
  )
}
