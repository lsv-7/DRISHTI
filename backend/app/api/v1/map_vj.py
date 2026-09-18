import json
import os
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.repositories import crud

router = APIRouter(prefix="/map", tags=["Vijayawada Offline Map Layer"])

DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), "data", "vijayawada")


def load_geojson(subpath: str) -> dict:
    file_path = os.path.join(DATA_DIR, subpath)
    if os.path.exists(file_path):
        with open(file_path, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"type": "FeatureCollection", "features": []}


@router.get("/vijayawada")
def get_vijayawada_full_map():
    """
    Returns complete local Vijayawada geographic dataset for 100% offline rendering.
    """
    return {
        "center": {"latitude": 16.5062, "longitude": 80.6480},
        "boundary": load_geojson("boundary/Vijayawada_Boundary.geojson"),
        "wards": load_geojson("wards/Vijayawada_Wards.geojson"),
        "roads": load_geojson("roads/roads.geojson"),
        "shelters": load_geojson("shelters/shelters.geojson"),
        "hospitals": load_geojson("hospitals/hospitals.geojson"),
        "disaster_zones": load_geojson("disaster-zones/disaster-zones.geojson"),
        "evacuation_routes": load_geojson("evacuation/evacuation-routes.geojson")
    }


@router.get("/layers")
def get_map_layers():
    """
    Returns metadata for 12 toggleable map layers.
    """
    return {
        "layers": [
            {"id": "layer_boundary", "name": "Vijayawada Boundary", "active": True},
            {"id": "layer_wards", "name": "Ward Boundaries (Demo)", "active": True},
            {"id": "layer_roads", "name": "Road Network (OSM)", "active": True},
            {"id": "layer_zones", "name": "Disaster Zones (DEMO)", "active": True},
            {"id": "layer_emergencies", "name": "Emergency Incidents", "active": True},
            {"id": "layer_shelters", "name": "Relief Shelters", "active": True},
            {"id": "layer_hospitals", "name": "Hospitals", "active": True},
            {"id": "layer_responders", "name": "Responders / Resources", "active": True},
            {"id": "layer_evacuation", "name": "Evacuation Routes", "active": True},
            {"id": "layer_blocked_roads", "name": "Blocked / Restricted Roads", "active": True},
            {"id": "layer_missing_search", "name": "Missing-Person Search Areas", "active": True},
            {"id": "layer_population_zones", "name": "Population Reconciliation Zones", "active": True}
        ]
    }


@router.get("/roads")
def get_vijayawada_roads():
    return load_geojson("roads/roads.geojson")


@router.get("/zones")
def get_vijayawada_zones():
    return load_geojson("disaster-zones/disaster-zones.geojson")


@router.get("/shelters")
def get_vijayawada_shelters():
    return load_geojson("shelters/shelters.geojson")


@router.get("/hospitals")
def get_vijayawada_hospitals():
    return load_geojson("hospitals/hospitals.geojson")


@router.get("/emergencies")
def get_map_emergencies(db: Session = Depends(get_db)):
    return crud.get_all_emergencies(db)


@router.get("/resources")
def get_map_resources(db: Session = Depends(get_db)):
    return crud.get_all_resources(db)
