import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import indexHtml from '../index.html?raw'
import App from './App'

describe('App', () => {
  it('Primer 기본 스타일 안에서 화면을 그린다', () => {
    render(<App />)

    const heading: HTMLElement = screen.getByRole('heading', { name: 'Iris 관리자 웹' })
    expect(heading.closest('[data-component="BaseStyles"]')).not.toBeNull()
  })
})

describe('index.html', () => {
  it('html 요소가 기기 설정을 따르는 Primer 테마 속성을 가진다', () => {
    const htmlTag: string = indexHtml.match(/<html[^>]*>/)?.[0] ?? ''

    expect(htmlTag).toContain('lang="ko"')
    expect(htmlTag).toContain('data-color-mode="auto"')
    expect(htmlTag).toContain('data-light-theme="light"')
    expect(htmlTag).toContain('data-dark-theme="dark"')
  })
})
