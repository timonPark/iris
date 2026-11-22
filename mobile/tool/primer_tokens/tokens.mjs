/** Primer CSS 변수 값을 읽고 Dart 값으로 바꾸는 함수들. */

const ROOT_FONT_SIZE = 16 // rem 기준(브라우저 기본). Flutter의 논리 픽셀로 바꿀 때 쓴다.

/**
 * CSS에서 `--이름: 값;` 선언을 읽는다. 주석은 뗀다.
 * firstBlockOnly면 첫 `{ … }` 블록만 읽는다(테마 파일 뒤쪽의 `@media` 블록은 다른 테마 조합이다).
 * @param {string} css
 * @param {{ firstBlockOnly?: boolean }} [options]
 * @returns {Map<string, string>}
 */
export function parseDeclarations(css, options = {}) {
  let text = css.replace(/\/\*[\s\S]*?\*\//g, '')
  if (options.firstBlockOnly) {
    const start = text.indexOf('{')
    text = text.slice(start + 1, text.indexOf('}', start))
  }
  const map = new Map()
  for (const m of text.matchAll(/(--[A-Za-z0-9-]+)\s*:\s*([^;]+);/g)) map.set(m[1], m[2].trim())
  return map
}

/**
 * `var(--x)` 참조를 끝까지 따라가 실제 값을 돌려준다(괄호 안 공백, 대체값이 있어도 이름만 본다). 없는 이름이면 null.
 * @param {string} name
 * @param {Map<string, string>} map
 * @returns {string | null}
 */
export function resolve(name, map) {
  let value = map.get(name)
  for (let depth = 0; value !== undefined && depth < 20; depth++) {
    const ref = value.match(/^var\(\s*(--[^,\s)]+)\s*(?:,[^)]*)?\)$/)
    if (ref === null) return value
    value = map.get(ref[1])
  }
  return null
}

/**
 * 한 가지 색(hex, rgb(), rgba(), transparent)을 ARGB로. 아니면 null.
 * @param {string} value
 * @returns {{ a: number, r: number, g: number, b: number } | null}
 */
export function parseColor(value) {
  const v = value.trim().toLowerCase()
  if (v === 'transparent') return { a: 0, r: 0, g: 0, b: 0 }
  const hex = v.match(/^#([0-9a-f]{3,8})$/)
  if (hex !== null) return parseHex(hex[1])
  const rgb = v.match(/^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+)\s*)?\)$/)
  if (rgb === null) return null
  const alpha = rgb[4] === undefined ? 1 : Number(rgb[4])
  return { a: Math.round(alpha * 255), r: Number(rgb[1]), g: Number(rgb[2]), b: Number(rgb[3]) }
}

/**
 * @param {string} digits # 뒤의 16진수 3·4·6·8자리
 * @returns {{ a: number, r: number, g: number, b: number } | null}
 */
function parseHex(digits) {
  if (![3, 4, 6, 8].includes(digits.length)) return null
  const full = digits.length <= 4 ? [...digits].map((c) => c + c).join('') : digits
  const n = (i) => parseInt(full.slice(i, i + 2), 16)
  return { r: n(0), g: n(2), b: n(4), a: full.length === 8 ? n(6) : 255 }
}

/**
 * @param {{ a: number, r: number, g: number, b: number }} c
 * @returns {string} 예: Color(0xFF0D1117)
 */
export function toDartColor(c) {
  const hex = [c.a, c.r, c.g, c.b].map((n) => n.toString(16).padStart(2, '0')).join('')
  return `Color(0x${hex.toUpperCase()})`
}

/**
 * 길이를 논리 픽셀로. rem은 16을 곱하고 px와 0은 그대로. 그 밖(em, 단위 없는 수 등)은 null.
 * @param {string} value
 * @returns {number | null}
 */
export function parseLength(value) {
  const v = value.trim()
  if (v === '0') return 0
  const m = v.match(/^(-?[\d.]+)(rem|px)$/)
  if (m === null) return null
  return m[2] === 'rem' ? Number(m[1]) * ROOT_FONT_SIZE : Number(m[1])
}

/**
 * CSS 변수 이름을 Dart 식별자(lowerCamelCase)로. 예: --bgColor-default → bgColorDefault
 * @param {string} name
 * @returns {string}
 */
export function dartName(name) {
  const [first, ...rest] = name.replace(/^--/, '').split('-')
  return first + rest.map((p) => p.charAt(0).toUpperCase() + p.slice(1)).join('')
}
