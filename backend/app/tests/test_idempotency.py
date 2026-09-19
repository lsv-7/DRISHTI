import threading
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from fastapi import FastAPI
from app.core.database import Base, get_db
from app.api.v1.emergencies import router as emergencies_router
from app.models.domain import Emergency, DisasterZone

app = FastAPI()
app.include_router(emergencies_router, prefix="/api/v1")

# Isolated in-memory SQLite database for idempotency tests
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
    # Seed a test disaster zone for zone resolution
    db = TestingSessionLocal()
    zone = DisasterZone(
        id="zone_test_01",
        name="Krishna River Basin",
        code="ZONE_KB_01",
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


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


def test_create_emergency_initial_success(client):
    payload = {
        "title": "Family trapped on rooftop",
        "description": "Water rising rapidly",
        "category": "FLOOD_RESCUE",
        "latitude": 16.5062,
        "longitude": 80.6480,
        "affected_count": 4,
        "idempotency_key": "idemp-backend-001",
        "vulnerability_snapshot": {
            "age": 72,
            "age_group": "ELDERLY",
            "can_swim": False,
            "mobility_status": "WHEELCHAIR",
            "medical_conditions": ["HYPERTENSION"],
        }
    }

    response = client.post("/api/v1/emergencies", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["id"].startswith("emg_")
    assert data["title"] == "Family trapped on rooftop"
    assert data["idempotency_key"] == "idemp-backend-001"
    assert data["priority_score"] >= 70.0
    assert data["priority_level"] in ["HIGH", "CRITICAL"]
    assert data["vulnerability_snapshot"]["age_group"] == "ELDERLY"
    assert data["vulnerability_snapshot"]["can_swim"] is False


def test_idempotent_duplicate_returns_existing(client):
    payload = {
        "title": "Hospital basement flooded",
        "description": "Oxygen generator at risk",
        "category": "FLOOD_RESCUE",
        "latitude": 16.5062,
        "longitude": 80.6480,
        "affected_count": 10,
        "idempotency_key": "idemp-backend-002",
        "vulnerability_snapshot": {
            "age": 45,
            "age_group": "ADULT",
            "can_swim": True,
            "mobility_status": "FULL",
            "medical_conditions": [],
        }
    }

    # First request -> 201 Created
    res1 = client.post("/api/v1/emergencies", json=payload)
    assert res1.status_code == 201
    data1 = res1.json()

    # Second request with identical key and payload -> 200 OK
    res2 = client.post("/api/v1/emergencies", json=payload)
    assert res2.status_code == 200
    data2 = res2.json()

    # Verify identical authoritative entity
    assert data1["id"] == data2["id"]
    assert data1["created_at"] == data2["created_at"]
    assert data1["priority_score"] == data2["priority_score"]
    assert data1["priority_level"] == data2["priority_level"]
    assert data1["priority_reasons"] == data2["priority_reasons"]
    assert data1["vulnerability_snapshot"] == data2["vulnerability_snapshot"]

    # Verify database contains exactly one record
    db = TestingSessionLocal()
    count = db.query(Emergency).filter(Emergency.idempotency_key == "idemp-backend-002").count()
    db.close()
    assert count == 1


def test_idempotency_conflict_different_category(client):
    key = "idemp-backend-003"
    payload1 = {
        "title": "Flash flood evacuation",
        "category": "FLOOD_RESCUE",
        "latitude": 16.5062,
        "longitude": 80.6480,
        "affected_count": 2,
        "idempotency_key": key,
    }
    res1 = client.post("/api/v1/emergencies", json=payload1)
    assert res1.status_code == 201

    payload2 = dict(payload1)
    payload2["category"] = "FIRE_OUTBREAK"

    res2 = client.post("/api/v1/emergencies", json=payload2)
    assert res2.status_code == 409
    assert "Idempotency key conflict" in res2.json()["detail"]


def test_idempotency_conflict_different_coordinates(client):
    key = "idemp-backend-004"
    payload1 = {
        "title": "Evacuation assistance",
        "category": "FLOOD_RESCUE",
        "latitude": 16.5062,
        "longitude": 80.6480,
        "affected_count": 2,
        "idempotency_key": key,
    }
    res1 = client.post("/api/v1/emergencies", json=payload1)
    assert res1.status_code == 201

    payload2 = dict(payload1)
    payload2["latitude"] = 12.9716 # Shifted to Bangalore
    payload2["longitude"] = 77.5946

    res2 = client.post("/api/v1/emergencies", json=payload2)
    assert res2.status_code == 409
    assert "Idempotency key conflict" in res2.json()["detail"]


def test_idempotency_conflict_different_affected_count(client):
    key = "idemp-backend-005"
    payload1 = {
        "title": "Stranded group",
        "category": "FLOOD_RESCUE",
        "latitude": 16.5062,
        "longitude": 80.6480,
        "affected_count": 3,
        "idempotency_key": key,
    }
    res1 = client.post("/api/v1/emergencies", json=payload1)
    assert res1.status_code == 201

    payload2 = dict(payload1)
    payload2["affected_count"] = 50

    res2 = client.post("/api/v1/emergencies", json=payload2)
    assert res2.status_code == 409
    assert "Idempotency key conflict" in res2.json()["detail"]


def test_idempotency_conflict_different_vulnerability_snapshot(client):
    key = "idemp-backend-006"
    payload1 = {
        "title": "Elderly rescue",
        "category": "FLOOD_RESCUE",
        "latitude": 16.5062,
        "longitude": 80.6480,
        "affected_count": 1,
        "idempotency_key": key,
        "vulnerability_snapshot": {
            "age": 80,
            "age_group": "ELDERLY",
            "can_swim": False,
            "mobility_status": "WHEELCHAIR",
        }
    }
    res1 = client.post("/api/v1/emergencies", json=payload1)
    assert res1.status_code == 201

    payload2 = dict(payload1)
    payload2["vulnerability_snapshot"] = {
        "age": 25,
        "age_group": "ADULT",
        "can_swim": True,
        "mobility_status": "FULL",
    }

    res2 = client.post("/api/v1/emergencies", json=payload2)
    assert res2.status_code == 409
    assert "Idempotency key conflict" in res2.json()["detail"]


def test_concurrent_duplicate_submissions_produce_exactly_one_record():
    """Verifies that multi-threaded concurrent requests with identical key never violate uniqueness."""
    payload = {
        "title": "Concurrent storm surge alert",
        "category": "FLOOD_RESCUE",
        "latitude": 16.5062,
        "longitude": 80.6480,
        "affected_count": 1,
        "idempotency_key": "idemp-concurrent-007",
    }

    results = []
    errors = []

    def send_request():
        try:
            with TestClient(app) as c:
                r = c.post("/api/v1/emergencies", json=payload)
                results.append((r.status_code, r.json()))
        except Exception as e:
            errors.append(e)

    threads = [threading.Thread(target=send_request) for _ in range(5)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    assert len(errors) == 0
    assert len(results) == 5

    # All responses must be either 201 (the creator) or 200 (the idempotent match)
    status_codes = [code for code, _ in results]
    assert all(code in [200, 201] for code in status_codes)
    assert 201 in status_codes

    # All returned emergency IDs must be identical
    ids = {data["id"] for _, data in results}
    assert len(ids) == 1

    # Exactly 1 row exists in database
    db = TestingSessionLocal()
    count = db.query(Emergency).filter(Emergency.idempotency_key == "idemp-concurrent-007").count()
    db.close()
    assert count == 1


def test_requests_without_idempotency_key_create_distinct_records(client):
    payload = {
        "title": "Ad-hoc observation",
        "category": "FLOOD_RESCUE",
        "latitude": 16.5062,
        "longitude": 80.6480,
        "affected_count": 1,
    }

    res1 = client.post("/api/v1/emergencies", json=payload)
    assert res1.status_code == 201

    res2 = client.post("/api/v1/emergencies", json=payload)
    assert res2.status_code == 201

    assert res1.json()["id"] != res2.json()["id"]
