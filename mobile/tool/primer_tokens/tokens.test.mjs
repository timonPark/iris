import assert from 'node:assert/strict'
import { describe, it } from 'node:test'
import {
  dartName,
  parseColor,
  parseDeclarations,
  parseLength,
  resolve,
  toDartColor,
} from './tokens.mjs'

describe('parseDeclarations', () => {
  it('변수 이름과 값을 읽고 주석을 뗀다', () => {
    const css = ':root {\n  --a: #fff; /** 설명 */\n  --b: var(--a);\n}'
    assert.deepEqual([...parseDeclarations(css)], [['--a', '#fff'], ['--b', 'var(--a)']])
  })

  it('firstBlockOnly면 첫 블록만 읽는다(테마 파일 뒤쪽의 다른 테마 블록 무시)', () => {
    const css = '[x] {\n  --a: #111111;\n}\n@media (prefers-color-scheme: dark) {\n  [y] {\n  --a: #222222;\n  }\n}'
    assert.equal(parseDeclarations(css, { firstBlockOnly: true }).get('--a'), '#111111')
  })
})

describe('resolve', () => {
  it('var() 참조를 끝까지 따라간다', () => {
    const map = new Map([['--a', '#fff'], ['--b', 'var(--a)'], ['--c', 'var(--b)']])
    assert.equal(resolve('--c', map), '#fff')
  })

  it('괄호 안 공백과 대체값(fallback)이 있어도 참조를 따라간다', () => {
    const map = new Map([['--a', '#fff'], ['--b', 'var( --a )'], ['--c', 'var(--a, #000)']])
    assert.equal(resolve('--b', map), '#fff')
    assert.equal(resolve('--c', map), '#fff')
  })

  it('없는 이름을 가리키면 null', () => {
    assert.equal(resolve('--x', new Map([['--x', 'var(--없음)']])), null)
  })
})

describe('parseColor', () => {
  it('hex 3·4·6·8자리를 ARGB로 읽는다', () => {
    assert.deepEqual(parseColor('#fff'), { a: 255, r: 255, g: 255, b: 255 })
    assert.deepEqual(parseColor('#0d1117'), { a: 255, r: 13, g: 17, b: 23 })
    assert.deepEqual(parseColor('#ffffff00'), { a: 0, r: 255, g: 255, b: 255 })
    assert.deepEqual(parseColor('#f008'), { a: 136, r: 255, g: 0, b: 0 })
  })

  it('rgb()와 rgba(), transparent를 읽는다', () => {
    assert.deepEqual(parseColor('rgba(31, 35, 40, 0.5)'), { a: 128, r: 31, g: 35, b: 40 })
    assert.deepEqual(parseColor('rgb(1,2,3)'), { a: 255, r: 1, g: 2, b: 3 })
    assert.deepEqual(parseColor('transparent'), { a: 0, r: 0, g: 0, b: 0 })
  })

  it('한 가지 색이 아니면 null(그림자 등)', () => {
    assert.equal(parseColor('0 1px 1px 0 #1f23280a'), null)
    assert.equal(parseColor('1rem'), null)
  })
})

describe('toDartColor', () => {
  it('Color(0xAARRGGBB)로 쓴다', () => {
    assert.equal(toDartColor({ a: 255, r: 13, g: 17, b: 23 }), 'Color(0xFF0D1117)')
    assert.equal(toDartColor({ a: 0, r: 255, g: 255, b: 255 }), 'Color(0x00FFFFFF)')
  })
})

describe('parseLength', () => {
  it('rem은 16을 곱한 논리 픽셀, px와 0은 그대로', () => {
    assert.equal(parseLength('1rem'), 16)
    assert.equal(parseLength('0.0625rem'), 1)
    assert.equal(parseLength('-0.125rem'), -2)
    assert.equal(parseLength('20px'), 20)
    assert.equal(parseLength('0'), 0)
  })

  it('em 같은 상대 단위나 숫자만 있는 값은 null', () => {
    assert.equal(parseLength('0.9285em'), null)
    assert.equal(parseLength('1.5'), null)
  })
})

describe('dartName', () => {
  it('CSS 변수 이름을 lowerCamelCase로 바꾼다', () => {
    assert.equal(dartName('--bgColor-default'), 'bgColorDefault')
    assert.equal(dartName('--base-size-2'), 'baseSize2')
    assert.equal(dartName('--button-primary-bgColor-rest'), 'buttonPrimaryBgColorRest')
    assert.equal(dartName('--base-text-size-2xl'), 'baseTextSize2xl')
  })
})
