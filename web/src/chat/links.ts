/** 화면 요소(카드)로 보여 주는 구글 링크의 종류(`ssot/GLOSSARY.md` "자료 링크"). */
export type GoogleLinkKind = 'document' | 'spreadsheet' | 'presentation' | 'file'

/** 답변 글 속의 구글 링크. start와 end는 글 안의 위치(end는 포함하지 않음)다. */
export interface GoogleLink {
  url: string
  kind: GoogleLinkKind
  start: number
  end: number
}

const KIND_BY_PATH: Record<string, GoogleLinkKind> = {
  'docs.google.com/document': 'document',
  'docs.google.com/spreadsheets': 'spreadsheet',
  'docs.google.com/presentation': 'presentation',
  'drive.google.com/file': 'file',
}

/**
 * 경로 뒤에는 주소에 쓰는 ASCII 글자만 이어 붙인다(한글, 괄호, 꺾쇠, `*`에서 멈춘다).
 * 끝의 문장부호(`.`, `,` 등)는 문장의 것으로 보고 뺀다.
 */
const LINK: RegExp =
  /https:\/\/(docs\.google\.com\/(?:document|spreadsheets|presentation)|drive\.google\.com\/file)\/d\/[\w-]+(?:[\w\-.~:/?#@!$&+,;=%]*[\w\-~/#=&%])?/g

/** 답변 글에서 구글 문서·시트·슬라이드·드라이브 파일 주소를 찾는다. */
export function findGoogleLinks(text: string): GoogleLink[] {
  return [...text.matchAll(LINK)].map((match: RegExpExecArray): GoogleLink => ({
    url: match[0],
    kind: KIND_BY_PATH[match[1]],
    start: match.index,
    end: match.index + match[0].length,
  }))
}
