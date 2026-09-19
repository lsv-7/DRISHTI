from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import create_access_token, verify_token
from app.schemas.domain import UserCreate, UserLogin, UserResponse, Token
from app.models.domain import User
from app.repositories import crud

router = APIRouter(prefix="/auth", tags=["Authentication"])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login", auto_error=False)


def get_current_user(token: Optional[str] = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
            headers={"WWW-Authenticate": "Bearer"},
        )
    payload = verify_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user = crud.get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    return user


@router.post("/register", response_model=UserResponse)
def register_user(user_in: UserCreate, db: Session = Depends(get_db)):
    if user_in.email:
        existing = crud.get_user_by_email(db, user_in.email)
        if existing:
            raise HTTPException(status_code=400, detail="User with this email already exists.")
    if user_in.phone:
        existing_phone = crud.get_user_by_phone(db, user_in.phone)
        if existing_phone:
            raise HTTPException(status_code=400, detail="User with this phone number already exists.")
    user = crud.create_user(db, user_in)
    return user


@router.post("/login", response_model=Token)
def login_user(login_in: UserLogin, db: Session = Depends(get_db)):
    user = None
    if login_in.email:
        user = crud.get_user_by_email(db, login_in.email)
    if not user and login_in.phone:
        user = crud.get_user_by_phone(db, login_in.phone)
    if not user:
        # Create demo user on login if missing for seamless UI testing
        demo_name = login_in.full_name or (login_in.email.split("@")[0].capitalize() if login_in.email else "Citizen User")
        user_create = UserCreate(
            email=login_in.email,
            phone=login_in.phone,
            full_name=demo_name,
            role=login_in.role or "CITIZEN",
            password=login_in.password
        )
        user = crud.create_user(db, user_create)
    access_token = create_access_token(data={"sub": user.id, "role": user.role.value})
    return Token(access_token=access_token, user=UserResponse.model_validate(user))


@router.get("/me", response_model=UserResponse)
def get_current_user_profile(current_user: User = Depends(get_current_user)):
    return current_user
