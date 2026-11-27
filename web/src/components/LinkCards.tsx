import { BrowserIcon, FileIcon, LinkExternalIcon, NoteIcon, TableIcon, type Icon } from '@primer/octicons-react'
import type { JSX, ReactNode } from 'react'
import type { GoogleLink, GoogleLinkKind } from '../chat/links'

/** 링크 종류의 화면 이름. 본문의 짧은 링크 글자와 카드 제목에 쓴다. */
const KIND_NAME: Record<GoogleLinkKind, string> = {
  document: '구글 문서',
  spreadsheet: '구글 시트',
  presentation: '구글 슬라이드',
  file: '구글 드라이브',
}

/** 링크 종류의 아이콘. 색은 CSS의 `link-card--종류`가 정한다. */
const KIND_ICON: Record<GoogleLinkKind, Icon> = {
  document: NoteIcon,
  spreadsheet: TableIcon,
  presentation: BrowserIcon,
  file: FileIcon,
}

/** 누르면 새 탭에서 해당 구글 앱이 열린다. 열린 탭이 이 화면에 손대지 못하게 rel을 붙인다. */
function ExternalLink({ link, className, children }: { link: GoogleLink; className?: string; children: ReactNode }): JSX.Element {
  return (
    <a href={link.url} target="_blank" rel="noopener noreferrer" className={className}>
      {children}
    </a>
  )
}

/** 답변 글에서 구글 주소 자리를 짧은 링크 글자(종류 이름)로 바꿔 보여 준다. */
export function LinkedText({ text, links }: { text: string; links: GoogleLink[] }): JSX.Element {
  const parts: ReactNode[] = []
  let at: number = 0
  for (const link of links) {
    parts.push(text.slice(at, link.start))
    parts.push(<ExternalLink key={link.start} link={link}>{KIND_NAME[link.kind]}</ExternalLink>)
    at = link.end
  }
  parts.push(text.slice(at))
  return <>{parts}</>
}

/** 답변 아래에 링크마다 붙는 카드: 종류 아이콘, 종류 이름, 도메인, 새 탭 표시. */
export function LinkCards({ links }: { links: GoogleLink[] }): JSX.Element {
  return (
    <ul className="link-cards" aria-label="링크">
      {links.map((link: GoogleLink) => (
        <li key={link.start}>
          <LinkCard link={link} />
        </li>
      ))}
    </ul>
  )
}

function LinkCard({ link }: { link: GoogleLink }): JSX.Element {
  const KindIcon: Icon = KIND_ICON[link.kind]
  return (
    <ExternalLink link={link} className={`link-card link-card--${link.kind}`}>
      <KindIcon size={24} className="link-card__icon" aria-hidden="true" />
      <span className="link-card__name">{KIND_NAME[link.kind]}</span>
      <span className="link-card__host">{new URL(link.url).host}</span>
      <LinkExternalIcon size={16} className="link-card__open" aria-hidden="true" />
    </ExternalLink>
  )
}
