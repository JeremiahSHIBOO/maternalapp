"""Notifications router."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing: List

from ...core.database import get_db
from ...models.models import Notification
from ...schemas.schemas import NotificationCreate, NotificationResponse

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.post("/", response_model=NotificationResponse)
async def create_notification(
    notification: NotificationCreate,
    db: Session = Depends(get_db),
):
    """Create a new notification."""
    new_notification = Notification(**notification.dict())
    db.add(new_notification)
    db.commit()
    db.refresh(new_notification)
    return new_notification


@router.get("/", response_model=List[NotificationResponse])
async def get_notifications(
    user_id: int,
    db: Session = Depends(get_db),
):
    """Get all notifications for a user."""
    notifications = db.query(Notification).filter(
        Notification.user_id == user_id
    ).all()
    return notifications


@router.patch("/{notification_id}/read", response_model=NotificationResponse)
async def mark_notification_read(
    notification_id: int,
    db: Session = Depends(get_db),
):
    """Mark a notification as read."""
    notification = db.query(Notification).filter(Notification.id == notification_id).first()
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    notification.is_read = True
    db.commit()
    db.refresh(notification)
    return notification