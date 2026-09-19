import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
from app.api.v1.auth import router as auth_router
from app.api.v1.emergencies import router as emergencies_router
from app.api.v1.resources import router as resources_router
from app.models.domain import DisasterZone

app = FastAPI()
app.include_router(auth_router, prefix="/api/v1")
app.include_router(emergencies_router, prefix="/api/v1")
app.include_router(resources_router, prefix="/api/v1")

TEST_DATABASE_URL = "sqlite:///:memory:"

test_engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(autouse=True)
def setup_database():
    Base.metadata.create_all(bind=test_engine)
    db = TestingSessionLocal()
    # Seed zone for emergency tests
    zone = DisasterZone(
        id="zone_auth_test",
        name="Auth Test Zone",
        code="ZONE_AUTH_01",
        disaster_type="FLOOD",
        geometry_geojson={
            "type": "Polygon",
            "coordinates": [[[80.0, 16.0], [81.0, 16.0], [81.0, 17.0], [80.0, 17.0], [80.0, 16.0]]]
        },
        expected_population=5000,
        is_active=True
    )
    db.add(zone)
    db.commit()
    db.close()
    yield
    Base.metadata.drop_all(bind=test_engine)


client = TestClient(app)


def test_auth_register_with_citizen_fields():
    payload = {
        "email": "priya.sharma@example.com",
        "full_name": "Priya Sharma",
        "phone": "+919876543210",
        "gender": "Female",
        "address": "42 Flood Relief Colony",
        "city": "Vijayawada",
        "emergency_contact_name": "Rajesh Sharma",
        "emergency_contact_phone": "+919876543211",
        "password": "securepassword123",
        "role": "CITIZEN"
    }
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["email"] == "priya.sharma@example.com"
    assert data["full_name"] == "Priya Sharma"
    assert data["phone"] == "+919876543210"
    assert data["gender"] == "Female"
    assert data["address"] == "42 Flood Relief Colony"
    assert data["city"] == "Vijayawada"
    assert data["emergency_contact_name"] == "Rajesh Sharma"
    assert data["emergency_contact_phone"] == "+919876543211"
    assert "id" in data


def test_auth_register_duplicate_email_rejected():
    payload = {
        "email": "duplicate@example.com",
        "full_name": "Original User",
        "phone": "+919876543212"
    }
    res1 = client.post("/api/v1/auth/register", json=payload)
    assert res1.status_code == 200

    payload_dup = {
        "email": "duplicate@example.com",
        "full_name": "Second User",
        "phone": "+919876543213"
    }
    res2 = client.post("/api/v1/auth/register", json=payload_dup)
    assert res2.status_code == 400
    assert "already exists" in res2.text


def test_auth_register_duplicate_phone_rejected():
    payload = {
        "email": "phone1@example.com",
        "full_name": "Phone User 1",
        "phone": "+919876543299"
    }
    res1 = client.post("/api/v1/auth/register", json=payload)
    assert res1.status_code == 200

    payload_dup = {
        "email": "phone2@example.com",
        "full_name": "Phone User 2",
        "phone": "+919876543299"
    }
    res2 = client.post("/api/v1/auth/register", json=payload_dup)
    assert res2.status_code == 400
    assert "phone number already exists" in res2.text


def test_auth_login_and_me_endpoint():
    # Register user
    reg_payload = {
        "email": "commander@disaster.gov",
        "full_name": "Commander Sarah",
        "phone": "+919876543220",
        "role": "ADMIN",
        "password": "adminpassword"
    }
    reg_res = client.post("/api/v1/auth/register", json=reg_payload)
    assert reg_res.status_code == 200

    # Login
    login_payload = {
        "email": "commander@disaster.gov",
        "full_name": "Commander Sarah",
        "password": "adminpassword"
    }
    login_res = client.post("/api/v1/auth/login", json=login_payload)
    assert login_res.status_code == 200
    token_data = login_res.json()
    assert "access_token" in token_data
    token = token_data["access_token"]
    assert token_data["token_type"] == "bearer"
    assert token_data["user"]["email"] == "commander@disaster.gov"

    # GET /auth/me without token -> 401
    me_unauth = client.get("/api/v1/auth/me")
    assert me_unauth.status_code == 401

    # GET /auth/me with invalid token -> 401
    me_invalid = client.get("/api/v1/auth/me", headers={"Authorization": "Bearer invalid.fake.token"})
    assert me_invalid.status_code == 401

    # GET /auth/me with valid token -> 200
    me_valid = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert me_valid.status_code == 200
    user_me = me_valid.json()
    assert user_me["email"] == "commander@disaster.gov"
    assert user_me["full_name"] == "Commander Sarah"
    assert user_me["role"] == "ADMIN"


def test_dual_trailing_slash_routes():
    # Test emergencies with and without trailing slash
    res_no_slash = client.get("/api/v1/emergencies")
    assert res_no_slash.status_code == 200
    res_slash = client.get("/api/v1/emergencies/")
    assert res_slash.status_code == 200

    # Test resources with and without trailing slash
    res_res_no_slash = client.get("/api/v1/resources")
    assert res_res_no_slash.status_code == 200
    res_res_slash = client.get("/api/v1/resources/")
    assert res_res_slash.status_code == 200
