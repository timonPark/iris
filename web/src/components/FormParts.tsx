import type { ChangeEvent, JSX } from 'react'
import { Flash, FormControl, TextInput } from '@primer/react'
import { AlertIcon, CheckCircleIcon } from '@primer/octicons-react'

export interface TextFieldProps {
  label: string
  value: string
  onChange: (value: string) => void
  type?: 'text' | 'password'
  autoComplete: string
  caption?: string
}

/** 샘플(#3)의 입력칸: 굵은 라벨, 큰 입력칸, 필요하면 아래에 힌트(aria-describedby로 연결). */
export function TextField(props: TextFieldProps): JSX.Element {
  return (
    <FormControl>
      <FormControl.Label>{props.label}</FormControl.Label>
      <TextInput
        className="field-input"
        type={props.type ?? 'text'}
        autoComplete={props.autoComplete}
        value={props.value}
        onChange={(e: ChangeEvent<HTMLInputElement>): void => props.onChange(e.target.value)}
        size="large"
        block
      />
      {props.caption !== undefined && <FormControl.Caption>{props.caption}</FormControl.Caption>}
    </FormControl>
  )
}

/** 오류 안내(빨간 상자). 스크린 리더가 바로 읽도록 role="alert". */
export function ErrorFlash({ text }: { text: string }): JSX.Element {
  return (
    <Flash variant="danger" role="alert" className="form-flash">
      <AlertIcon aria-hidden="true" />
      <p>{text}</p>
    </Flash>
  )
}

/** 완료 안내(초록 상자). */
export function SuccessFlash({ text }: { text: string }): JSX.Element {
  return (
    <Flash variant="success" role="status" className="form-flash">
      <CheckCircleIcon aria-hidden="true" />
      <p>{text}</p>
    </Flash>
  )
}
