/// <reference types="vite/client" />

interface ImportMetaEnv {
  /** 백엔드 주소. 예: http://localhost:8000, https://….ngrok-free.dev */
  readonly VITE_API_BASE_URL?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
