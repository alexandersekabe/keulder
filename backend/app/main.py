
from fastapi import Depends, FastAPI
from sqlalchemy import select
from sqlalchemy.orm import Session


from app.db.database import get_db
from app.shared.models.organisation import Organisation
from app.api.routes.agriculture import router as agriculture_router

app = FastAPI(
    title="Keulder Platform API",
    description="API for the Keulder intelligence platform",
    version="0.1.0",
)
app.include_router(agriculture_router)

@app.get("/health")
def health_check():
    return {"status": "ok", "service": "keulder-api"}


@app.get("/api/organisations")
def list_organisations(db: Session = Depends(get_db)):
    statement = (
        select(Organisation)
        .order_by(Organisation.name)
        .limit(50)
    )

    organisations = db.scalars(statement).all()

    return [
        {
            "id": str(organisation.id),
            "name": organisation.name,
            "country_code": organisation.country_code,
            "is_active": organisation.is_active,
        }
        for organisation in organisations
    ]
