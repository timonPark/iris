import { useState, type JSX } from 'react'
import { IconButton } from '@primer/react'
import { ThreeBarsIcon } from '@primer/octicons-react'
import type { ApiClient } from '../api/client'
import type { Session } from '../chat/types'
import { useChat, type Chat } from '../chat/useChat'
import { useDeleteSession, type DeleteSession } from '../chat/useDeleteSession'
import { useSessions, type Sessions } from '../chat/useSessions'
import { Composer } from '../components/Composer'
import { DeleteDialog } from '../components/DeleteDialog'
import { Sidebar } from '../components/Sidebar'
import { Thread } from '../components/Thread'
import { SettingsScreen } from './SettingsScreen'

export interface ChatScreenProps {
  client: ApiClient
  loginId: string
  onPasswordChanged: (accessToken: string) => void
}

type View = 'chat' | 'settings'

/** 로그인 뒤의 화면 틀: 세션 목록 사이드바 + 본문(채팅 또는 설정). 새로고침하면 빈 새 세션에서 시작한다. */
export function ChatScreen({ client, loginId, onPasswordChanged }: ChatScreenProps): JSX.Element {
  const { view, drawerOpen, setDrawerOpen, show }: ViewState = useViewState()
  const sessions: Sessions = useSessions(client)
  const chat: Chat = useChat(client, sessions.putOnTop)
  const deletion: DeleteSession = useDeleteSession(client, (id: string): void => {
    sessions.remove(id)
    if (id === chat.sessionId) chat.reset()
  })
  const openSession = (session: Session): void => {
    show('chat')
    void chat.open(session)
  }

  return (
    <div className={drawerOpen ? 'app is-drawer-open' : 'app'}>
      <Sidebar sessions={sessions} currentId={view === 'chat' ? chat.sessionId : null} loginId={loginId} onOpen={openSession} onDelete={deletion.ask} onSettings={(): void => show('settings')} onClose={(): void => setDrawerOpen(false)} />
      <div className="drawer-backdrop" onClick={(): void => setDrawerOpen(false)} />
      <div className="main">
        <div className="topbar">
          <IconButton className="menu-btn" icon={ThreeBarsIcon} variant="invisible" aria-label="세션 목록 열기" unsafeDisableTooltip onClick={(): void => setDrawerOpen(true)} />
          <h2 className="topbar__title">{view === 'settings' ? '설정' : (chat.title ?? '새 세션')}</h2>
        </div>
        {view === 'settings' ? <SettingsScreen client={client} onChanged={onPasswordChanged} /> : <ChatBody chat={chat} />}
      </div>
      {deletion.target !== null && <DeleteDialog session={deletion.target} error={deletion.error} busy={deletion.busy} onCancel={deletion.cancel} onConfirm={(): void => void deletion.confirm()} />}
    </div>
  )
}

interface ViewState {
  view: View
  drawerOpen: boolean
  setDrawerOpen: (open: boolean) => void
  /** 본문을 바꾸고 좁은 화면의 서랍을 닫는다. */
  show: (next: View) => void
}

function useViewState(): ViewState {
  const [view, setView] = useState<View>('chat')
  const [drawerOpen, setDrawerOpen] = useState<boolean>(false)
  const show = (next: View): void => {
    setView(next)
    setDrawerOpen(false)
  }
  return { view, drawerOpen, setDrawerOpen, show }
}

function ChatBody({ chat }: { chat: Chat }): JSX.Element {
  return (
    <>
      <Thread items={chat.items} loading={chat.loading} loadError={chat.loadError} />
      <Composer streaming={chat.streaming} loading={chat.loading} canStop={chat.canStop} onSend={(text: string): void => void chat.send(text)} onStop={chat.stop} />
    </>
  )
}
