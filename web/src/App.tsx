import type { JSX } from 'react'
import { BaseStyles, Heading, Text } from '@primer/react'
import { ThemeProvider } from '@primer/react/next'

/** 화면은 #18(로그인), #24(채팅)에서 만든다. 지금은 Primer 테마 확인용 자리다. */
export default function App(): JSX.Element {
  return (
    <ThemeProvider colorMode="auto" dayScheme="light" nightScheme="dark" contextOnly>
      <BaseStyles>
        <main className="app">
          <Heading as="h1">Iris</Heading>
          <Text as="p">사용자 웹 준비 중입니다.</Text>
        </main>
      </BaseStyles>
    </ThemeProvider>
  )
}
