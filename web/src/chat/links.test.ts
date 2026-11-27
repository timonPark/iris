import { describe, expect, it } from 'vitest'
import { findGoogleLinks, type GoogleLink } from './links'

const DRIVE: string = 'https://drive.google.com/file/d/1AbC_d-9/view?usp=drivesdk'

describe('findGoogleLinks', () => {
  it('답변 글 속의 드라이브 파일 주소를 찾아 종류와 위치를 알려 준다', () => {
    const text: string = `자료를 올렸습니다.\n링크: ${DRIVE}\n확인해 보세요.`

    expect(findGoogleLinks(text)).toEqual([{ url: DRIVE, kind: 'file', start: 15, end: 15 + DRIVE.length }])
  })

  it('구글 문서, 시트, 슬라이드 주소의 종류를 가린다', () => {
    const doc: string = 'https://docs.google.com/document/d/D1/edit'
    const sheet: string = 'https://docs.google.com/spreadsheets/d/S1/edit#gid=0'
    const slide: string = 'https://docs.google.com/presentation/d/P1/edit?usp=sharing'

    const kinds: string[] = findGoogleLinks(`${doc} ${sheet} ${slide}`).map((link: GoogleLink): string => `${link.kind} ${link.url}`)

    expect(kinds).toEqual([`document ${doc}`, `spreadsheet ${sheet}`, `presentation ${slide}`])
  })

  it.each([
    ['한글이 바로 붙음', `${DRIVE}입니다`],
    ['문장 끝 마침표', `여기 있습니다: ${DRIVE}.`],
    ['쉼표', `${DRIVE}, 그리고`],
    ['괄호', `(${DRIVE})`],
    ['마크다운 링크', `[자료](${DRIVE})`],
    ['마크다운 굵게', `**${DRIVE}**`],
    ['꺾쇠', `<${DRIVE}>`],
  ])('주소 끝에 붙은 글자는 주소에 넣지 않는다: %s', (_name: string, text: string) => {
    expect(findGoogleLinks(text).map((link: GoogleLink): string => link.url)).toEqual([DRIVE])
  })

  it('구글이 아니거나 다른 경로의 주소는 찾지 않는다', () => {
    const text: string = 'https://example.com/file/d/1 https://drive.google.com/drive/folders/F1 https://docs.google.com/forms/d/X/edit'

    expect(findGoogleLinks(text)).toEqual([])
  })
})
