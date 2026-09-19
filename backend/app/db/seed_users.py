"""
Seed script for populating test user credentials for Admin and Organization accounts.
"""
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.models.domain import User, UserRole
from app.core.security import get_password_hash

TEST_USERS = [
    {
        "id": "USR-ADMIN-01",
        "email": "admin@disaster.gov",
        "full_name": "Commander Sarah Jenkins",
        "role": UserRole.ADMIN,
        "password": "AdminPass123!"
    },
    {
        "id": "USR-HOSP-01",
        "email": "hospital@disaster.gov",
        "full_name": "Dr. A. Sharma (Chief Medical Officer)",
        "role": UserRole.MEDICAL,
        "password": "Hospital123!"
    },
    {
        "id": "USR-POL-01",
        "email": "police@disaster.gov",
        "full_name": "Inspector R. Verma",
        "role": UserRole.COORDINATOR,
        "password": "Police123!"
    },
    {
        "id": "USR-FIRE-01",
        "email": "fire@disaster.gov",
        "full_name": "Captain K. Mohan",
        "role": UserRole.RESPONDER,
        "password": "Fire123!"
    },
    {
        "id": "USR-SHEL-01",
        "email": "shelter@disaster.gov",
        "full_name": "Manager P. Rao",
        "role": UserRole.SHELTER_MANAGER,
        "password": "Shelter123!"
    },
    {
        "id": "USR-ROAD-01",
        "email": "road@disaster.gov",
        "full_name": "Engineer S. Reddy",
        "role": UserRole.COORDINATOR,
        "password": "Road123!"
    }
]

def seed_users():
    db: Session = SessionLocal()
    try:
        for udata in TEST_USERS:
            existing = db.query(User).filter(User.email == udata["email"]).first()
            if not existing:
                user = User(
                    id=udata["id"],
                    email=udata["email"],
                    full_name=udata["full_name"],
                    role=udata["role"],
                    hashed_password=get_password_hash(udata["password"])
                )
                db.add(user)
        db.commit()
        print("Test users successfully seeded into database.")
    except Exception as e:
        db.rollback()
        print("Seeding error:", e)
    finally:
        db.close()

if __name__ == "__main__":
    seed_users()
