"""Users router - authentication and profile management."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ...core.database import get_db
from ...core.security import create_access_token, decode_access_token, get_password_hash, verify_password
from ...models.models import User, MotherPregnancyProfile
from ...schemas.schemas import (
    UserResponse, UserCreate, LoginRequest, Token, DailyCheckInResponse
)
from pydantic import EmailStr

router = APIRouter(prefix="/users", tags=["users"])


@router.post("/login", response_model=Token)
async def login(
    login_data: LoginRequest,
    db: Session = Depends(get_db),
):
    """Authenticate user and return JWT token."""
    user = db.query(User).filter(User.email == login_data.email).first()
    if not user or not verify_password(login_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    
    if not user.is_verified:
        raise HTTPException(status_code=400, detail="Unverified email")
    
    access_token = create_access_token(subject=user.id)
    return {"access_token": access_token, "token_type": "bearer"}


@router.post("/register", response_model=UserResponse)
async def register(
    user_data: UserCreate,
    db: Session = Depends(get_db),
):
    """Register a new user."""
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_password = get_password_hash(user_data.password)
    
    new_user = User(
        email=user_data.email,
        full_name=user_data.full_name,
        password_hash=hashed_password,
        role=user_data.role,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Create pregnancy profile for mothers
    if new_user.role == "mother":
        profile = MotherPregnancyProfile(user_id=new_user.id)
        db.add(profile)
        db.commit()
        db.refresh(profile)
    
    return new_user


@router.get("/me", response_model=UserResponse)
async def get_current_user(
    # In a full implementation, would extract token from auth header
    # For now, returns a placeholder
    db: Session = Depends(get_db),
):
    """Get current user profile."""
    # This would normally decode the JWT token
    # For demo purposes, return a basic user
    user = db.query(User).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user