#!/usr/bin/env bash
# INFRA-02 — SQL Server native backup (infrastructure-level; NOT application logic).
#
# Runs BACKUP DATABASE against the SQL Server container and writes a timestamped .bak to the mounted
# backup volume (/var/opt/mssql/backups → docker volume `mssql-backups`). Designed for scheduled
# execution. It is intended to run INSIDE the `db` container, where sqlcmd (mssql-tools18) exists:
#
#   docker compose exec -e MSSQL_SA_PASSWORD="$MSSQL_SA_PASSWORD" db /scripts/backup.sh
#
# Schedule it from the host with cron, e.g. (hourly):
#   0 * * * * cd /opt/planyourtrip && docker compose exec -T -e MSSQL_SA_PASSWORD="$(grep '^MSSQL_SA_PASSWORD=' .env | cut -d= -f2-)" db /scripts/backup.sh >> /var/log/pyt-backup.log 2>&1
#
# The password is read from the environment and is NEVER echoed or written to any log by this script.
set -euo pipefail

: "${MSSQL_SA_PASSWORD:?MSSQL_SA_PASSWORD must be set in the environment}"
APP_DB_NAME="${APP_DB_NAME:-PlanYourTrip}"
BACKUP_DIR="${BACKUP_DIR:-/var/opt/mssql/backups}"
SQLCMD="${SQLCMD:-/opt/mssql-tools18/bin/sqlcmd}"
DB_HOST="${DB_HOST:-localhost}"

mkdir -p "${BACKUP_DIR}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_FILE="${BACKUP_DIR}/${APP_DB_NAME}_${STAMP}.bak"

# -C trusts the container's self-signed certificate; -b makes sqlcmd exit non-zero on any SQL error
# so `set -e` aborts (and cron/monitoring sees the failure). CHECKSUM guards backup integrity.
# NOTE: WITH COMPRESSION is NOT supported on SQL Server Express — add it only on editions that support it.
"${SQLCMD}" -S "${DB_HOST}" -U sa -P "${MSSQL_SA_PASSWORD}" -C -b \
  -Q "BACKUP DATABASE [${APP_DB_NAME}] TO DISK = N'${BACKUP_FILE}' WITH INIT, CHECKSUM, STATS = 10;"

echo "INFRA-02 backup completed: ${BACKUP_FILE}"
