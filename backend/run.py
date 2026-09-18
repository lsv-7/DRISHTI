import os
import sys
import uvicorn

# Fix utf-8 encoding for Windows console output
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8')


def main():
    env = os.getenv("APP_ENV", "development").lower()

    config = {
        "app": "app.main:app",
        "host": "0.0.0.0",
        "port": 3000,
        "log_level": "info",
    }

    if env == "production":
        print("Starting FastAPI backend in PRODUCTION mode...")
        config.update({
            "reload": False,
            "workers": 4,
        })
    else:
        print("Starting FastAPI backend in DEVELOPMENT mode with hot-reload...")
        config.update({
            "reload": True,
            "workers": 1,
        })

    uvicorn.run(**config)


if __name__ == "__main__":
    main()