# app/main.py

import logging
from fastapi import FastAPI
from app.core.exception_handlers import setup_exception_handlers
from app.api.routes.company import router as company_router
from app.api.routes.company_detail import router as company_detail_router
from app.api.routes.recommendation import router as recommendation_router

logging.basicConfig(level=logging.WARNING)
print(">>> app/main.py loaded")

app = FastAPI()

setup_exception_handlers(app)

app.include_router(company_router, tags=["companies"])
app.include_router(company_detail_router, tags=["companies"])
app.include_router(recommendation_router, tags=["recommendation"])


print("Registered routes:")
for route in app.routes:
    print(route.path, route.name)
