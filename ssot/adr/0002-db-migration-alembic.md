# DB 마이그레이션은 Alembic(SQLAlchemy)으로 한다

테이블 구조는 코드로 정의하고 변경 이력을 마이그레이션 파일로 남긴다. 도구는 Alembic, DB 접근은 SQLAlchemy 2.0이다. 계정, 세션, 질문, 답변 모델(#15, #22)이 모두 이 방식으로 만들어지고, 백엔드가 Python 타입 힌트와 Pydantic 모델을 쓰는 규칙과 맞으며, 소규모 PostgreSQL 하나에는 이 조합이 가장 표준적이고 가볍다.

- DB 접속 정보는 `backend/.env`에만 둔다. `alembic.ini`에는 적지 않는다.
- PostgreSQL 호스트 포트는 이 PC의 다른 PostgreSQL(n8n)과 겹치지 않게 5433을 쓴다.
