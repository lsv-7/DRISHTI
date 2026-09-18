from fastapi import FastAPI

app = FastAPI(title="Production Backend API")


@app.get("/")
def read_root():
    return {"message": "FastAPI backend running via uv!"}


@app.get("/health")
def health_check():
    return {"status": "healthy"}