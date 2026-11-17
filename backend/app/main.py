from fastapi import FastAPI


def create_app() -> FastAPI:
    return FastAPI(title="Iris")


app: FastAPI = create_app()
