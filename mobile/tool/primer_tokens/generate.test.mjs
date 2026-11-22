import assert from 'node:assert/strict'
import { describe, it } from 'node:test'
import { buildDart, colorTokens } from './generate.mjs'

describe('colorTokens', () => {
  it('라이트와 다크의 토큰 이름이 다르면 멈춘다(한쪽에만 있는 색이 조용히 빠지지 않게)', () => {
    const light = new Map([['--a', '#fff']])
    const dark = new Map([['--a', '#000'], ['--b', '#111']])
    assert.throws(() => colorTokens(light, dark), /--b/)
  })
})

const dart = await buildDart()

function colorIn(block, name) {
  return block.match(new RegExp(`\\b${name}: (Color\\(0x[0-9A-F]{8}\\))`))?.[1]
}

describe('buildDart (실제 @primer/primitives 11.10.0)', () => {
  const light = dart.slice(dart.indexOf('static const PrimerColors light'), dart.indexOf('static const PrimerColors dark'))
  const dark = dart.slice(dart.indexOf('static const PrimerColors dark'))

  it('생성 파일임과 Primer 버전을 머리에 적는다', () => {
    assert.match(dart, /생성 파일/)
    assert.match(dart, /@primer\/primitives 11\.10\.0/)
  })

  it('라이트와 다크 색을 모두 같은 이름으로 담는다', () => {
    assert.equal(colorIn(light, 'bgColorDefault'), 'Color(0xFFFFFFFF)')
    assert.equal(colorIn(dark, 'bgColorDefault'), 'Color(0xFF0D1117)')
    assert.equal(colorIn(light, 'fgColorDefault'), 'Color(0xFF1F2328)')
  })

  it('var() 참조를 따라간 값을 담는다(버튼 기본 색 = 성공 강조 배경)', () => {
    assert.equal(colorIn(light, 'buttonPrimaryBgColorRest'), colorIn(light, 'bgColorSuccessEmphasis'))
  })

  it('간격, 모서리, 글자 크기를 논리 픽셀로 담는다', () => {
    assert.match(dart, /static const double stackGapNormal = 16(\.0)?;/)
    assert.match(dart, /static const double borderRadiusMedium = 6(\.0)?;/)
    assert.match(dart, /static const double textBodySizeMedium = 14(\.0)?;/)
    assert.match(dart, /static const double textBodyLineHeightMedium = 1\.5;/)
    assert.match(dart, /static const FontWeight baseTextWeightSemibold = FontWeight\.w600;/)
  })

  it('터치 화면용 크기는 터치 값을 쓴다', () => {
    assert.match(dart, /static const double controlMinTargetAuto = 44(\.0)?;/)
  })

  it('파일을 웹(primitives.css)과 같은 순서로 읽어, 뒤 파일이 덮은 값은 웹과 같게 쓴다', () => {
    // size.css가 size-coarse.css 뒤에서 controlStack-*-auto를 다시 정해 웹에서는 터치 화면에서도 8px이다.
    assert.match(dart, /static const double controlStackMediumGapAuto = 8(\.0)?;/)
  })

  it('같은 Dart 이름이 되는 옛 이름과 새 이름(값이 같은 별칭)은 하나만 넣는다', () => {
    assert.equal((light.match(/\bfocusOutlineColor: /g) ?? []).length, 1)
    assert.equal((dart.match(/^  final Color focusOutlineColor;/gm) ?? []).length, 1)
  })

  it('그림자처럼 한 가지 색이 아닌 값과 em 단위는 넣지 않는다', () => {
    assert.doesNotMatch(dart, /shadowRestingSmall/)
    assert.doesNotMatch(dart, /textCodeInlineSize/)
  })
})
