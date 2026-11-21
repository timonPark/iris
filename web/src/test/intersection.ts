import { act } from '@testing-library/react'

type Callback = (entries: IntersectionObserverEntry[]) => void

const observed: Map<Element, Callback> = new Map()

/** jsdom에는 IntersectionObserver가 없다. 관찰 중인 요소를 테스트가 직접 "보이게" 만든다. */
class FakeIntersectionObserver {
  private readonly callback: Callback
  constructor(callback: Callback) {
    this.callback = callback
  }
  observe(target: Element): void {
    observed.set(target, this.callback)
  }
  unobserve(target: Element): void {
    observed.delete(target)
  }
  disconnect(): void {
    for (const [el, cb] of observed) if (cb === this.callback) observed.delete(el)
  }
  takeRecords(): IntersectionObserverEntry[] {
    return []
  }
}

export function installIntersectionObserver(): void {
  ;(window as unknown as { IntersectionObserver: unknown }).IntersectionObserver = FakeIntersectionObserver
}

/** 관찰 중인 요소가 화면에 들어온 것처럼 알린다. */
export async function showElement(target: Element): Promise<void> {
  const callback: Callback | undefined = observed.get(target)
  if (callback === undefined) throw new Error('관찰 중인 요소가 아니다')
  await act(async (): Promise<void> => {
    callback([{ isIntersecting: true, target } as IntersectionObserverEntry])
  })
}
