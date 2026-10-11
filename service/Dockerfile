# --- Builder Stage ---
FROM python:3.11-slim AS builder
WORKDIR /app

# 1. Create the user and switch to it in the builder stage
RUN useradd -m appuser
USER appuser

COPY requirements.txt .
RUN pip install --user -r requirements.txt

# --- Final Stage ---
FROM python:3.11-slim
RUN useradd -m appuser
WORKDIR /app

# 2. This will now work perfectly because the folder exists
COPY --from=builder /home/appuser/.local /home/appuser/.local

ENV PATH=/home/appuser/.local/bin:$PATH
USER appuser
COPY --chown=appuser:appuser . .
EXPOSE 5000
CMD ["python", "app.py"]
