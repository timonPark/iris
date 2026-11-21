import { describe, expect, it } from 'vitest'
import { resolveApiBaseUrl } from './config'

describe('resolveApiBaseUrl', () => {
  it('설정이 없으면 로컬 백엔드 주소를 쓴다', () => {
    expect(resolveApiBaseUrl(undefined)).toBe('http://localhost:8000')
    expect(resolveApiBaseUrl('')).toBe('http://localhost:8000')
    expect(resolveApiBaseUrl('   ')).toBe('http://localhost:8000')
  })

  it('설정한 주소를 쓰고 끝의 슬래시를 뗀다', () => {
    expect(resolveApiBaseUrl('https://example.ngrok-free.dev/')).toBe(
      'https://example.ngrok-free.dev',
    )
    expect(resolveApiBaseUrl(' http://127.0.0.1:8000 ')).toBe('http://127.0.0.1:8000')
  })
})
