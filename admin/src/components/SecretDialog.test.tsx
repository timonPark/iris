import { render, screen } from '@testing-library/react'
import userEvent, { type UserEvent } from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { SecretDialog } from './SecretDialog'

describe('SecretDialog 복사', () => {
  afterEach((): void => {
    vi.unstubAllGlobals()
  })

  it('클립보드를 쓸 수 없는 환경(HTTP 주소 등)에서도 오류 없이 그대로 둔다', async () => {
    const user: UserEvent = userEvent.setup()
    vi.stubGlobal('navigator', { ...navigator, clipboard: undefined })
    render(<SecretDialog secret={{ kind: 'created', loginId: 'newbie', temporaryPassword: 'Kp7wRx3eNq2T' }} onDone={(): void => {}} />)

    await user.click(screen.getByRole('button', { name: '임시 비밀번호 복사' }))

    expect(screen.getByRole('button', { name: '임시 비밀번호 복사' })).toHaveTextContent('복사')
    expect(screen.getByText('Kp7wRx3eNq2T')).toBeInTheDocument()
  })
})
