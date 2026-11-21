/**
 * @primer/primitives의 CSS 변수 값을 읽어 Flutter용 Dart 토큰 파일을 만든다 (#6).
 * 실행: npm run generate  →  mobile/lib/theme/primer_tokens.dart
 * Primer 버전을 올리면 package.json의 버전을 웹과 같게 바꾸고 다시 실행한다(ssot/PRIMER.md).
 */
import { mkdir, readFile, writeFile } from 'node:fs/promises'
import { fileURLToPath } from 'node:url'
import { dartName, parseColor, parseDeclarations, parseLength, resolve, toDartColor } from './tokens.mjs'

const PACKAGE = new URL('./node_modules/@primer/primitives/', import.meta.url)
const CSS = new URL('dist/css/', PACKAGE)
export const OUTPUT = new URL('../../lib/theme/primer_tokens.dart', import.meta.url)

/**
 * 읽을 파일. 순서는 웹의 primitives.css가 불러오는 순서와 같다(뒤 파일이 같은 이름을 덮는다).
 * 터치 화면용 값(size-coarse.css)은 모바일 앱이 늘 터치 화면이라 넣고, 마우스용(size-fine.css)은 넣지 않는다.
 * 그래서 size.css가 뒤에서 다시 정하는 controlStack-*-auto는 웹처럼 size.css 값이 된다.
 */
const GROUPS = {
  size: ['base/size/size.css', 'functional/size/border.css', 'functional/size/breakpoints.css', 'functional/size/size-coarse.css', 'functional/size/size.css'],
  radius: ['functional/size/radius.css'],
  text: ['base/typography/typography.css', 'functional/typography/typography.css'],
}

const read = (path) => readFile(new URL(path, CSS), 'utf8')

/** @returns {Promise<string>} 생성할 Dart 파일 내용 */
export async function buildDart() {
  const { version } = JSON.parse(await readFile(new URL('package.json', PACKAGE), 'utf8'))
  const light = parseDeclarations(await read('functional/themes/light.css'), { firstBlockOnly: true })
  const dark = parseDeclarations(await read('functional/themes/dark.css'), { firstBlockOnly: true })
  const groups = {}
  const all = new Map()
  for (const [key, files] of Object.entries(GROUPS)) {
    groups[key] = new Map()
    for (const f of files) for (const [n, v] of parseDeclarations(await read(f))) groups[key].set(n, v)
    for (const [n, v] of groups[key]) all.set(n, v)
  }
  return [
    header(version),
    colorClass(colorTokens(light, dark)),
    constClass('PrimerSize', '간격, 컨트롤 크기, 테두리 두께, 화면 너비 기준. 논리 픽셀(rem × 16).', lengthEntries(groups.size, all)),
    constClass('PrimerRadius', '모서리. 논리 픽셀(rem × 16).', lengthEntries(groups.radius, all)),
    constClass('PrimerText', '글자 크기(논리 픽셀), 줄 간격(배수), 굵기.', textEntries(groups.text, all)),
  ].join('\n')
}

function header(version) {
  return `// 생성 파일입니다. 직접 고치지 마세요.
// mobile/tool/primer_tokens에서 \`npm run generate\`로 만듭니다.
// 원본: @primer/primitives ${version}의 CSS 변수 (웹과 같은 값, ssot/PRIMER.md)

import 'dart:ui' show Color, FontWeight;
`
}

/**
 * 라이트와 다크 모두 한 가지 색으로 끝나는 토큰. 이름순.
 * Primer에는 옛 이름과 새 이름(예: --focus-outline-color, --focus-outlineColor)이 함께 있어 Dart 이름이 겹친다.
 * 값이 같으면 하나만 넣고, 다르면 멈춘다. 라이트와 다크의 이름이 다르면(한쪽에만 있는 색) 멈춘다.
 * @param {Map<string, string>} light
 * @param {Map<string, string>} dark
 * @returns {{ name: string, light: string, dark: string }[]}
 */
export function colorTokens(light, dark) {
  const onlyOne = [...light.keys(), ...dark.keys()].filter((n) => !light.has(n) || !dark.has(n))
  if (onlyOne.length > 0) throw new Error(`라이트와 다크 한쪽에만 있는 토큰: ${onlyOne.join(', ')}`)
  const byName = new Map()
  for (const name of [...light.keys()].sort()) {
    const l = parseColor(resolve(name, light) ?? '')
    const d = parseColor(resolve(name, dark) ?? '')
    if (l === null || d === null) continue
    const token = { name: dartName(name), light: toDartColor(l), dark: toDartColor(d) }
    const seen = byName.get(token.name)
    if (seen !== undefined && (seen.light !== token.light || seen.dark !== token.dark)) {
      throw new Error(`Dart 이름이 겹치는데 값이 다르다: ${name} → ${token.name}`)
    }
    byName.set(token.name, token)
  }
  return [...byName.values()]
}

function colorClass(tokens) {
  const fields = tokens.map((t) => `  final Color ${t.name};`).join('\n')
  const params = tokens.map((t) => `    required this.${t.name},`).join('\n')
  const values = (key) => tokens.map((t) => `    ${t.name}: ${t[key]},`).join('\n')
  return `/// Primer 색 토큰. 라이트와 다크에서 이름이 같고 값만 다르다.
final class PrimerColors {
  const PrimerColors._({
${params}
  });

${fields}

  static const PrimerColors light = PrimerColors._(
${values('light')}
  );

  static const PrimerColors dark = PrimerColors._(
${values('dark')}
  );
}
`
}

/**
 * @typedef {{ name: string, type: string, value: string }} ConstEntry  Dart 상수 한 줄
 */

/**
 * @param {Map<string, string>} group 이 클래스에 넣을 파일들의 선언
 * @param {Map<string, string>} all 참조를 풀 때 쓰는 모든 선언
 * @returns {ConstEntry[]}
 */
function lengthEntries(group, all) {
  const entries = []
  for (const name of [...group.keys()].sort()) {
    const px = parseLength(resolve(name, all) ?? '')
    if (px !== null) entries.push({ name: dartName(name), type: 'double', value: String(px) })
  }
  return entries
}

/**
 * 굵기는 FontWeight, 길이는 논리 픽셀, 단위 없는 수(줄 간격)는 그대로. 글꼴 이름과 묶음(shorthand)은 넣지 않는다.
 * @param {Map<string, string>} group
 * @param {Map<string, string>} all
 * @returns {ConstEntry[]}
 */
function textEntries(group, all) {
  const entries = []
  for (const name of [...group.keys()].sort()) {
    const value = resolve(name, all) ?? ''
    const px = parseLength(value)
    if (name.includes('weight') && /^[1-9]00$/.test(value)) entries.push({ name: dartName(name), type: 'FontWeight', value: `FontWeight.w${value}` })
    else if (px !== null) entries.push({ name: dartName(name), type: 'double', value: String(px) })
    else if (/^\d*\.?\d+$/.test(value)) entries.push({ name: dartName(name), type: 'double', value: String(Number(value)) })
  }
  return entries
}

/**
 * @param {string} name 클래스 이름
 * @param {string} doc 클래스 설명
 * @param {ConstEntry[]} entries
 * @returns {string}
 */
function constClass(name, doc, entries) {
  assertUnique(entries.map((e) => e.name))
  const lines = entries.map((e) => `  static const ${e.type} ${e.name} = ${e.value};`)
  return `/// ${doc}
abstract final class ${name} {
${lines.join('\n')}
}
`
}

/** @param {string[]} names */
function assertUnique(names) {
  const seen = new Set()
  for (const n of names) {
    if (seen.has(n)) throw new Error(`Dart 이름이 겹친다: ${n}`)
    seen.add(n)
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const dart = await buildDart()
  await mkdir(new URL('.', OUTPUT), { recursive: true })
  await writeFile(OUTPUT, dart)
  const count = (re) => (dart.match(re) ?? []).length
  console.log(`생성: ${fileURLToPath(OUTPUT)}`)
  console.log(`색 ${count(/^  final Color /gm)}개(라이트·다크), 크기·모서리·글자 ${count(/^  static const (double|FontWeight) /gm)}개`)
}
