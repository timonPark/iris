from fastapi import FastAPI
from fastapi.testclient import TestClient
from httpx import Response

from app.main import create_app


def test_create_app_returns_iris_app() -> None:
    app: FastAPI = create_app()
    assert app.title == "Iris"


def test_openapi_document_is_served() -> None:
    client: TestClient = TestClient(create_app())
    response: Response = client.get("/openapi.json")
    assert response.status_code == 200
    assert response.json()["info"]["title"] == "Iris"
