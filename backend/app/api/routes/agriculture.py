
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.services.maize_heat import calculate_maize_heat
from datetime import date


router = APIRouter(
    prefix="/api/agriculture",
    tags=["Agriculture"],
)


@router.get("/maize-heat")
def get_maize_heat(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    start_date: date = Query(...),
    end_date: date = Query(...),
    threshold_c: float = Query(30.0, ge=-100, le=100),
    db: Session = Depends(get_db),
):
    try:
        return calculate_maize_heat(
            db=db,
            latitude=latitude,
            longitude=longitude,
            start_date=start_date,
            end_date=end_date,
            threshold_c=threshold_c,
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        ) from exc
