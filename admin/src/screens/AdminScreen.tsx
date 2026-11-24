import type { JSX } from 'react'

export interface AdminScreenProps {
  loginId: string
}

/** 로그인 뒤 관리자 화면 틀(샘플 #4의 머리글). 사용자 계정 목록은 #28에서 채운다. */
export function AdminScreen({ loginId }: AdminScreenProps): JSX.Element {
  return (
    <div className="shell">
      <header className="header">
        <h1 className="header__brand">Iris 관리자</h1>
        <span className="header__user">{loginId}</span>
      </header>
      <main className="page">
        <div className="page__inner">
          <h2 className="page__title">사용자 계정</h2>
          <p className="page__note">사용자 계정 관리 화면은 준비 중입니다.</p>
        </div>
      </main>
    </div>
  )
}
