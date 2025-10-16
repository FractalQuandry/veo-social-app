
FROM python:3.11-slim
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
RUN pip install --no-cache-dir uvicorn fastapi pydantic httpx python-dotenv google-cloud-firestore google-cloud-storage google-cloud-pubsub
COPY src/ /app/src/
EXPOSE 8080
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8080"]
