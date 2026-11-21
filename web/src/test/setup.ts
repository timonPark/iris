import '@testing-library/jest-dom/vitest'
import { cleanup } from '@testing-library/react'
import { afterEach } from 'vitest'
import { installIntersectionObserver } from './intersection'

installIntersectionObserver()

// jsdom에는 ResizeObserver가 없다. Primer Dialog가 쓴다.
if (!('ResizeObserver' in window)) {
  ;(window as unknown as { ResizeObserver: unknown }).ResizeObserver = class {
    observe(): void {}
    unobserve(): void {}
    disconnect(): void {}
  }
}

// jsdom은 스크롤을 하지 않는다. 스레드 끝으로 스크롤하는 코드가 오류 없이 돌게 한다.
Element.prototype.scrollIntoView = (): void => {}

afterEach((): void => {
  cleanup()
})

// jsdom에는 matchMedia가 없다. Primer ThemeProvider가 기기 테마를 읽을 때 쓴다.
if (!window.matchMedia) {
  window.matchMedia = (query: string): MediaQueryList =>
    ({
      matches: false,
      media: query,
      onchange: null,
      addEventListener: (): void => {},
      removeEventListener: (): void => {},
      addListener: (): void => {},
      removeListener: (): void => {},
      dispatchEvent: (): boolean => false,
    }) as MediaQueryList
}
