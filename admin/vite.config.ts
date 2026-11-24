/// <reference types="vitest/config" />
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  // 사용자 웹(5173)과 함께 띄울 수 있게 포트를 따로 둔다.
  server: { port: 5174, strictPort: true },
  preview: { port: 4174, strictPort: true },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    // @primer/react는 CSS 파일을 import한다. Node가 직접 읽지 않고 Vite가 처리하게 한다.
    server: { deps: { inline: ['@primer/react'] } },
  },
})
