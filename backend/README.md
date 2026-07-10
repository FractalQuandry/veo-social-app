# Backend

FastAPI backend service for Veo Social App.

## Structure

```
backend/
├── src/
│   ├── main.py              # FastAPI app entry point
│   ├── config.py            # Configuration management
│   ├── models/              # Pydantic data models
│   ├── services/            # Business logic
│   │   ├── generation.py    # AI generation service
│   │   ├── store.py         # Firestore operations
│   │   └── storage.py       # Firebase Storage operations
│   └── tests/               # Unit tests
├── .env.example             # Environment template
├── pyproject.toml           # Python dependencies
├── Dockerfile               # Container image for Cloud Run
└── README.md               # This file
```

## Setup

See [Setup Guide](../docs/SETUP.md) for detailed instructions.

### Quick Start

```bash
# Create virtual environment
python -m venv .venv

# Activate (Windows)
.venv\Scripts\activate

# Install dependencies (from pyproject.toml)
pip install -e .

# Configure environment
copy .env.example .env

# Run server
uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
```

## Development Mode

Set `ENABLE_MOCKS=true` in `.env` to run without GCP costs.

## API Documentation

Once running, visit:

- Swagger UI: <http://localhost:8000/docs>
- ReDoc: <http://localhost:8000/redoc>
