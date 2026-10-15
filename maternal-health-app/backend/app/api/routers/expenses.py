"""Expenses router - family expenses in ₹ INR."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ...core.database import get_db
from ...models.models import Expense
from ...schemas.schemas import ExpenseCreate, ExpenseUpdate, ExpenseResponse

router = APIRouter(prefix="/expenses", tags=["expenses"])


@router.post("/", response_model=ExpenseResponse)
async def create_expense(
    expense: ExpenseCreate,
    db: Session = Depends(get_db),
):
    """Create a new expense record."""
    new_expense = Expense(**expense.dict())
    db.add(new_expense)
    db.commit()
    db.refresh(new_expense)
    return new_expense


@router.get("/", response_model=List[ExpenseResponse])
async def get_expenses(
    db: Session = Depends(get_db),
):
    """Get all expenses."""
    expenses = db.query(Expense).all()
    return expenses


@router.get("/{expense_id}", response_model=ExpenseResponse)
async def get_expense(
    expense_id: int,
    db: Session = Depends(get_db),
):
    """Get a specific expense."""
    expense = db.query(Expense).filter(Expense.id == expense_id).first()
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
    return expense


@router.patch("/{expense_id}", response_model=ExpenseResponse)
async def update_expense(
    expense_id: int,
    expense_update: ExpenseUpdate,
    db: Session = Depends(get_db),
):
    """Update an expense."""
    expense = db.query(Expense).filter(Expense.id == expense_id).first()
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
    
    update_data = expense_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(expense, field, value)
    
    db.commit()
    db.refresh(expense)
    return expense