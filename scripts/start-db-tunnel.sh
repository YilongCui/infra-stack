#!/usr/bin/env bash
set -euo pipefail

LOCAL_PORT="54320"
REMOTE_DB_HOST="127.0.0.1"
REMOTE_DB_PORT="5432"
SSH_TARGET="app@122.35.189.9"
SSH_TARGET_LABEL="app@<hidden>"

echo "[db-tunnel] Starting SSH tunnel"
echo "[db-tunnel] Local:  127.0.0.1:${LOCAL_PORT}"
echo "[db-tunnel] Remote: ${REMOTE_DB_HOST}:${REMOTE_DB_PORT} via ${SSH_TARGET_LABEL}"
echo "[db-tunnel] Keep this terminal open while using the database connection."

ssh \
  -o ExitOnForwardFailure=yes \
  -N \
  -L "${LOCAL_PORT}:${REMOTE_DB_HOST}:${REMOTE_DB_PORT}" \
  "${SSH_TARGET}" &

SSH_PID="$!"

cleanup() {
  echo "[db-tunnel] Stopping SSH tunnel"
  kill "${SSH_PID}" >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM

for _ in {1..20}; do
  if ! kill -0 "${SSH_PID}" >/dev/null 2>&1; then
    echo "[db-tunnel] SSH process exited before the tunnel became ready" >&2
    exit 1
  fi

  if nc -z 127.0.0.1 "${LOCAL_PORT}" >/dev/null 2>&1; then
    echo "[db-tunnel] Tunnel is ready: 127.0.0.1:${LOCAL_PORT} -> ${SSH_TARGET_LABEL}:${REMOTE_DB_PORT}"
    echo "[db-tunnel] Press Ctrl+C to stop the tunnel."
    wait "${SSH_PID}"
  fi
  sleep 0.25
done

echo "[db-tunnel] Tunnel did not become ready on 127.0.0.1:${LOCAL_PORT}" >&2
exit 1
