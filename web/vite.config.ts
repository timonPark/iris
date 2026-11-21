/// <reference types="vitest/config" />
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    // @primer/react는 CSS 파일을 import한다. Node가 직접 읽지 않고 Vite가 처리하게 한다.
    server: { deps: { inline: ['@primer/react'] } },
  },
})
