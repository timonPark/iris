import { useEffect, useRef, type JSX, type MouseEvent, type RefObject } from 'react'
import { Button, IconButton } from '@primer/react'
import { GearIcon, PlusIcon, TrashIcon, XIcon } from '@primer/octicons-react'
import type { Sessions } from '../chat/useSessions'
import type { Session } from '../chat/types'

export interface SidebarProps {
  sessions: Sessions
  /** 지금 보고 있는 세션(설정을 보는 중이면 null). */
  currentId: string | null
  loginId: string
  onOpen: (session: Session) => void
  /** [새 세션] 버튼(`ssot/GLOSSARY.md` "세션"). */
  onNew: () => void
  onDelete: (session: Session) => void
  onSettings: () => void
  onClose: () => void
}

/** 세션 목록 사이드바. 좁은 화면에서는 서랍으로 열린다(CSS). */
export function Sidebar(props: SidebarProps): JSX.Element {
  const { sessions } = props
  return (
    <nav className="sidebar" aria-label="세션 목록">
      <SidebarHead onNew={props.onNew} onClose={props.onClose} />
      <h2 className="sidebar__heading">세션</h2>
      <ul className="sessions">
        {sessions.items.map((s: Session) => (
          <SessionRow key={s.id} session={s} current={s.id === props.currentId} onOpen={props.onOpen} onDelete={props.onDelete} />
        ))}
        {sessions.error !== null && (
          <li className="sessions__more sessions__more--error">
            <span role="alert">{sessions.error}</span>
            <Button size="small" onClick={(): void => void sessions.loadMore()}>다시 시도</Button>
          </li>
        )}
        {sessions.hasMore && sessions.error === null && <MoreSentinel key={sessions.items.length} onVisible={sessions.loadMore} />}
      </ul>
      <div className="sidebar__foot">
        <span className="sidebar__user">{props.loginId}</span>
        <Button variant="invisible" leadingVisual={GearIcon} onClick={props.onSettings}>설정</Button>
      </div>
    </nav>
  )
}

/** 브랜드, 좁은 화면의 서랍 닫기, [새 세션] 버튼. */
function SidebarHead({ onNew, onClose }: Pick<SidebarProps, 'onNew' | 'onClose'>): JSX.Element {
  return (
    <>
      <div className="sidebar__head">
        <h1 className="sidebar__brand">Iris</h1>
        <IconButton className="sidebar__close" icon={XIcon} variant="invisible" aria-label="세션 목록 닫기" unsafeDisableTooltip onClick={onClose} />
      </div>
      <div className="sidebar__new">
        <Button block leadingVisual={PlusIcon} onClick={onNew}>새 세션</Button>
      </div>
    </>
  )
}

interface SessionRowProps {
  session: Session
  current: boolean
  onOpen: (session: Session) => void
  onDelete: (session: Session) => void
}

function SessionRow({ session, current, onOpen, onDelete }: SessionRowProps): JSX.Element {
  const open = (event: MouseEvent<HTMLAnchorElement>): void => {
    event.preventDefault()
    onOpen(session)
  }
  return (
    <li className="session">
      <a className="session__link" href="#" aria-current={current ? 'page' : undefined} onClick={open}>{session.title}</a>
      <IconButton className="session__delete" icon={TrashIcon} variant="invisible" aria-label={`'${session.title}' 세션 삭제`} unsafeDisableTooltip onClick={(): void => onDelete(session)} />
    </li>
  )
}

/** 목록 끝. 화면에 보이면 다음 페이지를 부른다. 페이지가 늘 때마다 새로 만들어(key) 다시 관찰한다. */
function MoreSentinel({ onVisible }: { onVisible: () => Promise<void> }): JSX.Element {
  const el: RefObject<HTMLLIElement | null> = useRef<HTMLLIElement>(null)
  useEffect((): (() => void) => {
    const observer: IntersectionObserver = new IntersectionObserver((entries: IntersectionObserverEntry[]): void => {
      if (entries.some((e: IntersectionObserverEntry) => e.isIntersecting)) void onVisible()
    })
    if (el.current !== null) observer.observe(el.current)
    return (): void => observer.disconnect()
  }, [onVisible])
  return <li ref={el} className="sessions__more" aria-live="polite">이전 세션을 불러오는 중…</li>
}
