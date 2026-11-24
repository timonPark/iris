import type { JSX } from 'react'
import { BaseStyles, Heading, Text } from '@primer/react'
import { ThemeProvider } from '@primer/react/next'

/** 화면은 #20(관리자 로그인), #28(사용자 계정 관리)에서 만든다. 지금은 Primer 테마 확인용 자리다. */
export default function App(): JSX.Element {
  return (
    <ThemeProvider colorMode="auto" dayScheme="light" nightScheme="dark" contextOnly>
      <BaseStyles>
        <main className="app">
          <Heading as="h1">Iris 관리자 웹</Heading>
          <Text as="p">관리자 웹 준비 중입니다.</Text>
        </main>
      </BaseStyles>
    </ThemeProvider>
  )
}
