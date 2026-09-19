import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
from app.api.v1.profile import router as profile_router
from app.api.v1.emergencies import router as emergencies_router
from app.models.domain import User, DisasterZone

app = FastAPI()
app.include_router(profile_router, prefix="/api/v1")
app.include_router(emergencies_router, prefix="/api/v1")

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
    # Seed a zone for emergency testing
    zone = DisasterZone(
        id="zone_test_profile",
        name="Test Coastal Zone",
        code="ZONE_TCZ_01",
        disaster_type="FLOOD",
        geometry_geojson={
            "type": "Polygon",
            "coordinates": [[[80.0, 16.0], [81.0, 16.0], [81.0, 17.0], [80.0, 17.0], [80.0, 16.0]]]
        },
        expected_population=2000,
        is_active=True
    )
    db.add(zone)
    db.commit()
    db.close()
    yield
    Base.metadata.drop_all(bind=test_engine)


@pytest.fixture
def client():
    return TestClient(app)


def test_get_nonexistent_profile_returns_404(client):
    response = client.get("/api/v1/profile/nonexistent_user")
    assert response.status_code == 404
    assert "not found" in response.json()["detail"].lower()


def test_put_profile_creates_and_retrieves(client):
    user_id = "usr_test_101"
    payload = {
        "full_name": "Ravi Kumar",
        "phone": "+91 9876543210",
        "email": "ravi.kumar@example.com",
        "gender": "MALE",
        "address": "Flat 4B, Coastal Heights",
        "city": "Vijayawada",
        "emergency_contact_name": "Lakshmi Kumar",
        "emergency_contact_phone": "9123456780"
    }

    # PUT to create/update
    put_res = client.put(f"/api/v1/profile/{user_id}", json=payload)
    assert put_res.status_code == 200
    data = put_res.json()
    assert data["id"] == user_id
    assert data["full_name"] == "Ravi Kumar"
    assert data["phone"] == "+91 9876543210"
    assert data["email"] == "ravi.kumar@example.com"
    assert data["gender"] == "MALE"
    assert data["city"] == "Vijayawada"
    assert data["emergency_contact_name"] == "Lakshmi Kumar"
    assert data["emergency_contact_phone"] == "9123456780"

    # GET to verify persistence
    get_res = client.get(f"/api/v1/profile/{user_id}")
    assert get_res.status_code == 200
    assert get_res.json()["full_name"] == "Ravi Kumar"
    assert get_res.json()["city"] == "Vijayawada"


def test_put_profile_update_existing_fields(client):
    user_id = "usr_test_102"
    initial_payload = {
        "full_name": "Priya Sharma",
        "phone": "9876543211",
        "city": "Guntur"
    }
    client.put(f"/api/v1/profile/{user_id}", json=initial_payload)

    # Update phone and city
    update_payload = {
        "full_name": "Priya Sharma",
        "phone": "9876543299",
        "city": "Amaravati",
        "emergency_contact_name": "Anil Sharma",
        "emergency_contact_phone": "9876543288"
    }
    res = client.put(f"/api/v1/profile/{user_id}", json=update_payload)
    assert res.status_code == 200
    assert res.json()["phone"] == "9876543299"
    assert res.json()["city"] == "Amaravati"
    assert res.json()["emergency_contact_name"] == "Anil Sharma"


def test_profile_validation_rejects_invalid_inputs(client):
    user_id = "usr_test_val"

    # Name too short (<2 chars)
    res = client.put(f"/api/v1/profile/{user_id}", json={
        "full_name": "A",
        "phone": "9876543210"
    })
    assert res.status_code == 422

    # Phone too short (<8 digits)
    res = client.put(f"/api/v1/profile/{user_id}", json={
        "full_name": "Valid Name",
        "phone": "123"
    })
    assert res.status_code == 422

    # Invalid email
    res = client.put(f"/api/v1/profile/{user_id}", json={
        "full_name": "Valid Name",
        "phone": "9876543210",
        "email": "not-an-email"
    })
    assert res.status_code == 422

    # Invalid emergency contact phone (<8 digits)
    res = client.put(f"/api/v1/profile/{user_id}", json={
        "full_name": "Valid Name",
        "phone": "9876543210",
        "emergency_contact_phone": "12"
    })
    assert res.status_code == 422


def test_profile_user_isolation(client):
    user_a = "usr_alice"
    user_b = "usr_bob"

    client.put(f"/api/v1/profile/{user_a}", json={
        "full_name": "Alice Smith",
        "phone": "9876543210",
        "city": "City A"
    })
    client.put(f"/api/v1/profile/{user_b}", json={
        "full_name": "Bob Jones",
        "phone": "9123456789",
        "city": "City B"
    })

    res_a = client.get(f"/api/v1/profile/{user_a}").json()
    res_b = client.get(f"/api/v1/profile/{user_b}").json()

    assert res_a["full_name"] == "Alice Smith"
    assert res_a["city"] == "City A"
    assert res_b["full_name"] == "Bob Jones"
    assert res_b["city"] == "City B"


def test_emergency_reporter_details_and_snapshot_isolation(client):
    """Verifies reporter identity is at top level of Emergency, NOT inside vulnerability_snapshot."""
    emergency_payload = {
        "title": "Severe flood rescue",
        "description": "Family trapped on second floor",
        "category": "FLOOD_RESCUE",
        "latitude": 16.5,
        "longitude": 80.5,
        "affected_count": 3,
        "reporter_name": "Ravi Kumar",
        "contact_phone": "+91 9876543210",
        "vulnerability_snapshot": {
            "age": 65,
            "age_group": "ELDERLY",
            "can_swim": False,
            "mobility_status": "LIMITED",
            "medical_conditions": ["ASTHMA"]
        }
    }

    res = client.post("/api/v1/emergencies/", json=emergency_payload)
    assert res.status_code in (200, 201)
    data = res.json()

    # Reporter info must be at top level
    assert data["reporter_name"] == "Ravi Kumar"
    assert data["contact_phone"] == "+91 9876543210"

    # Vulnerability snapshot must be strictly isolated (no reporter identity inside)
    snapshot = data["vulnerability_snapshot"]
    assert "reporter_name" not in snapshot
    assert "contact_phone" not in snapshot
    assert "full_name" not in snapshot
    assert snapshot["age_group"] == "ELDERLY"
    assert snapshot["mobility_status"] == "LIMITED"
