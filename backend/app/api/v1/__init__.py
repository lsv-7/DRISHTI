from fastapi import APIRouter
from app.api.v1.auth import router as auth_router
from app.api.v1.emergencies import router as emergencies_router
from app.api.v1.vulnerability import router as vulnerability_router
from app.api.v1.resources import router as resources_router
from app.api.v1.policies import router as policies_router
from app.api.v1.population import router as population_router
from app.api.v1.missing_persons import router as missing_persons_router
from app.api.v1.simulations import router as simulations_router
from app.api.v1.agents import router as agents_router
from app.api.v1.map_vj import router as map_vj_router
from app.api.v1.decision import router as decision_router

api_v1_router = APIRouter(prefix="/api/v1")

api_v1_router.include_router(auth_router)
api_v1_router.include_router(emergencies_router)
api_v1_router.include_router(vulnerability_router)
api_v1_router.include_router(resources_router)
api_v1_router.include_router(policies_router)
api_v1_router.include_router(population_router)
api_v1_router.include_router(missing_persons_router)
api_v1_router.include_router(simulations_router)
api_v1_router.include_router(agents_router)
api_v1_router.include_router(map_vj_router)
api_v1_router.include_router(decision_router)
