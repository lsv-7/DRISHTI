from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import create_access_token
from app.schemas.domain import UserCreate, UserResponse, Token
from app.repositories import crud

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=UserResponse)
def register_user(user_in: UserCreate, db: Session = Depends(get_db)):
    existing = crud.get_user_by_email(db, user_in.email)
    if existing:
        raise HTTPException(status_code=400, detail="User with this email already exists.")
    user = crud.create_user(db, user_in)
    return user


@router.post("/login", response_model=Token)
def login_user(user_in: UserCreate, db: Session = Depends(get_db)):
    user = crud.get_user_by_email(db, user_in.email)
    if not user:
        # Create demo user on login if missing for seamless UI testing
        user = crud.create_user(db, user_in)
    access_token = create_access_token(data={"sub": user.id, "role": user.role.value})
    return Token(access_token=access_token, user=UserResponse.model_validate(user))
