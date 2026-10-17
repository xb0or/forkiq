# ForkIQ panel: one uvicorn worker, all mutable state on a mounted volume.
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    FORKIQ_STATE_DIR=/data \
    FORKIQ_PEM_PATH=/data/app.pem

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

# The SQLite database and the GitHub App private key live under
# FORKIQ_STATE_DIR, which is a mounted volume. The container stays root so a
# volume first mounted as root:root remains writable without an entrypoint shim.
RUN mkdir -p /data
EXPOSE 8792

# Exactly one worker: the sync engine runs an in-process background thread
# guarded by a file lock, and a second worker would duplicate every GitHub call.
# --proxy-headers keeps X-Forwarded-Proto honoured so the session cookie is
# marked Secure behind the HTTPS reverse proxy.
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8792} --workers 1 --proxy-headers --forwarded-allow-ips='*'"]
