/**
 * 생성한 Dart 파일의 값이 웹의 CSS 변수 값과 같은지 브라우저로 확인한다 (#6 완료 조건).
 * 같은 Primer CSS를 Chrome에 불러와 각 변수를 실제로 계산한 값(getComputedStyle)과 Dart의 값을 비교한다.
 * 실행: npm run verify   (Chrome 위치는 CHROME_PATH로 바꿀 수 있다)
 * 터치 화면용 값(*-auto)이 맞도록 모바일·터치 화면으로 연다.
 */
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { pathToFileURL } from 'node:url'
import { chromium } from 'playwright-core'
import { OUTPUT } from './generate.mjs'

const CHROME = process.env.CHROME_PATH ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const CSS = new URL('./node_modules/@primer/primitives/dist/css/', import.meta.url)

/**
 * Dart 이름(lowerCamelCase)을 CSS 변수 이름으로: 같은 규칙으로 만든 이름을 Primer CSS에서 찾는다.
 * @returns {Promise<Map<string, string>>} Dart 이름 → CSS 변수 이름
 */
async function cssNames() {
  const { dartName, parseDeclarations } = await import('./tokens.mjs')
  const files = ['functional/themes/light.css', 'base/size/size.css', 'functional/size/size.css', 'functional/size/border.css',
    'functional/size/breakpoints.css', 'functional/size/size-coarse.css', 'functional/size/radius.css',
    'base/typography/typography.css', 'functional/typography/typography.css']
  const map = new Map()
  for (const f of files) {
    for (const name of parseDeclarations(await readFile(new URL(f, CSS), 'utf8')).keys()) if (!map.has(dartName(name))) map.set(dartName(name), name)
  }
  return map
}

/**
 * Dart 파일에서 값을 읽는다.
 * @param {string} dart 생성한 Dart 파일 내용
 * @returns {{ light: Map<string, string>, dark: Map<string, string>, numbers: Map<string, number>, weights: Map<string, string> }}
 */
function dartValues(dart) {
  const section = (from, to) => dart.slice(dart.indexOf(from), to === null ? undefined : dart.indexOf(to))
  const colors = (text) => new Map([...text.matchAll(/^ {4}(\w+): Color\(0x([0-9A-F]{8})\),$/gm)].map((m) => [m[1], m[2]]))
  return {
    light: colors(section('static const PrimerColors light', 'static const PrimerColors dark')),
    dark: colors(section('static const PrimerColors dark', 'abstract final class PrimerSize')),
    numbers: new Map([...dart.matchAll(/^ {2}static const double (\w+) = (-?[\d.]+);$/gm)].map((m) => [m[1], Number(m[2])])),
    weights: new Map([...dart.matchAll(/^ {2}static const FontWeight (\w+) = FontWeight\.w(\d+);$/gm)].map((m) => [m[1], m[2]])),
  }
}

/**
 * 브라우저에서 변수 값을 계산한다. 색은 color, 길이는 margin-left, 줄 간격은 line-height(글자 1000px 기준), 굵기는 font-weight.
 * @param {{ css: string, kind: 'color' | 'length' | 'ratio' | 'weight' }[]} items
 * @returns {Record<string, string>} CSS 변수 이름 → 계산값
 */
function computeInPage(items) {
  const probe = document.createElement('div')
  probe.style.fontSize = '1000px'
  document.body.append(probe)
  const out = {}
  for (const { css, kind } of items) {
    const prop = { color: 'color', length: 'margin-left', ratio: 'line-height', weight: 'font-weight' }[kind]
    probe.style.setProperty(prop, `var(${css})`)
    out[css] = getComputedStyle(probe).getPropertyValue(prop)
    probe.style.removeProperty(prop)
  }
  return out
}

/**
 * @param {string} rgb 브라우저 계산값. 예: rgb(13, 17, 23), rgba(31, 35, 40, 0.5)
 * @returns {string} AARRGGBB
 */
function toArgb(rgb) {
  const m = rgb.match(/rgba?\((\d+), (\d+), (\d+)(?:, ([\d.]+))?\)/)
  const a = m[4] === undefined ? 255 : Math.round(Number(m[4]) * 255)
  return [a, m[1], m[2], m[3]].map((n) => Number(n).toString(16).padStart(2, '0')).join('').toUpperCase()
}

/**
 * 색은 알파 반올림 차이(±1)만 허용한다.
 * @param {string} expected AARRGGBB
 * @param {string} actual AARRGGBB
 * @returns {boolean}
 */
function sameColor(expected, actual) {
  return expected.slice(2) === actual.slice(2) && Math.abs(parseInt(expected.slice(0, 2), 16) - parseInt(actual.slice(0, 2), 16)) <= 1
}

/**
 * 웹과 같은 Primer CSS를 불러온 페이지. file:// CSS(상대 @import 포함)를 불러오려면 페이지도 file://이어야 한다.
 * @param {import('playwright-core').Browser} browser
 * @returns {Promise<import('playwright-core').Page>}
 */
async function openPrimerPage(browser) {
  const page = await browser.newPage({ isMobile: true, hasTouch: true, viewport: { width: 400, height: 800 } })
  const links = ['primitives.css', 'functional/themes/light.css', 'functional/themes/dark.css'].map((f) => `<link rel="stylesheet" href="${new URL(f, CSS)}">`).join('')
  const dir = await mkdtemp(join(tmpdir(), 'primer-verify-'))
  const html = join(dir, 'index.html')
  await writeFile(html, `<html data-color-mode="light" data-light-theme="light" data-dark-theme="dark"><head>${links}</head><body></body></html>`)
  await page.goto(pathToFileURL(html).href, { waitUntil: 'load' })
  await rm(dir, { recursive: true })
  return page
}

/**
 * @typedef {ReturnType<typeof dartValues>} DartValues
 */

/**
 * 라이트·다크 색을 비교해 다른 것을 problems에 넣는다.
 * @param {import('playwright-core').Page} page
 * @param {DartValues} values
 * @param {(dart: string) => string} css Dart 이름 → CSS 변수 이름
 * @param {string[]} problems
 * @returns {Promise<void>}
 */
async function compareColors(page, values, css, problems) {
  for (const mode of ['light', 'dark']) {
    await page.evaluate((m) => (document.documentElement.dataset.colorMode = m), mode)
    const got = await page.evaluate(computeInPage, [...values[mode].keys()].map((d) => ({ css: css(d), kind: 'color' })))
    for (const [d, argb] of values[mode]) if (!sameColor(argb, toArgb(got[css(d)] || 'rgb(0, 0, 0, 0)'))) problems.push(`${mode} ${css(d)}: Dart ${argb}, 웹 ${got[css(d)]}`)
  }
}

/**
 * 크기·줄 간격·굵기를 비교해 다른 것을 problems에 넣는다. 브라우저가 값을 못 읽으면(NaN) 다른 것으로 본다.
 * @param {import('playwright-core').Page} page
 * @param {DartValues} values
 * @param {(dart: string) => string} css
 * @param {string[]} problems
 * @returns {Promise<void>}
 */
async function compareNumbers(page, values, css, problems) {
  const kindOf = (d) => (/LineHeight/.test(d) && values.numbers.get(d) < 4 ? 'ratio' : 'length')
  const got = await page.evaluate(computeInPage, [
    ...[...values.numbers.keys()].map((d) => ({ css: css(d), kind: kindOf(d) })),
    ...[...values.weights.keys()].map((d) => ({ css: css(d), kind: 'weight' })),
  ])
  for (const [d, n] of values.numbers) {
    const web = parseFloat(got[css(d)]) / (kindOf(d) === 'ratio' ? 1000 : 1)
    if (Number.isNaN(web) || Math.abs(web - n) > 0.01) problems.push(`${css(d)}: Dart ${n}, 웹 ${got[css(d)]}`)
  }
  for (const [d, w] of values.weights) if (got[css(d)] !== w) problems.push(`${css(d)}: Dart ${w}, 웹 ${got[css(d)]}`)
}

/** @returns {Promise<void>} 다른 값이 있으면 종료 코드 1 */
async function main() {
  const values = dartValues(await readFile(OUTPUT, 'utf8'))
  const names = await cssNames()
  const css = (dart) => names.get(dart) ?? `--없음-${dart}`
  const browser = await chromium.launch({ executablePath: CHROME })
  const page = await openPrimerPage(browser)
  const problems = []
  await compareColors(page, values, css, problems)
  await compareNumbers(page, values, css, problems)
  await browser.close()
  const total = values.light.size + values.dark.size + values.numbers.size + values.weights.size
  console.log(`비교 ${total}개 (색 라이트 ${values.light.size}, 다크 ${values.dark.size}, 크기·줄 간격 ${values.numbers.size}, 굵기 ${values.weights.size}), 다른 값 ${problems.length}개`)
  problems.slice(0, 20).forEach((p) => console.log('  ' + p))
  process.exitCode = problems.length === 0 ? 0 : 1
}

await main()
