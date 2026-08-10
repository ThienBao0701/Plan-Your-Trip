# Plan Your Trip — Deployment (INFRA-02)

Single-host **Docker Compose** stack: `db` (self-managed SQL Server) → `db-init` (create database) →
`app` (Spring Boot, `prod` profile, Flyway-owned schema) → `web` (Nginx: serves Flutter Web + proxies
`/api`, **same-origin, no CORS**).

> **Two clearly-separated things in this document:**
> - **LOCAL DOCKER VERIFICATION** — bringing the stack up on a dev machine to prove the production chain.
> - **REAL VPS PRODUCTION DEPLOYMENT** — running it on a Linux VPS with TLS, real secrets, and backups.
>
> As of INFRA-02, **neither has been executed in this environment** (Docker is not installed here). All
> files are prepared and statically reviewed; the live chain is **NOT YET VERIFIED**.

> **Monorepo note.** The backend (this worktree, `pom.xml` + `src/` at root) is on branch `develop`; the
> Flutter frontend is on `feature/frontend-ui-v2` under `frontend/`. The `web` service serves a *prebuilt*
> Flutter bundle via the `WEB_ROOT` bind mount, so the backend image build does **not** need the frontend
> source. Build the web bundle from the frontend branch and point `WEB_ROOT` at its `build/web`.

---

## 1. Prerequisites
- Docker Engine + Docker Compose v2.
- To build the web bundle: Flutter (stable, Dart SDK ≥ 3.3).
- ~4 GB RAM available (SQL Server needs ~2 GB).

## 2. Linux VPS requirements
- 64-bit Linux, Docker installed, ≥ 2 vCPU / 4 GB RAM / 20 GB disk (SQL Server + volumes + backups).
- Open inbound 80/443 only. **Do not** open 1433 (SQL Server) or 8080 (app) to the internet.

## 3. Docker installation (VPS, Debian/Ubuntu)
Use Docker's official convenience script or apt repository, then verify `docker --version` and
`docker compose version`. (Left to the operator; no vendor prescribed by this repo.)

## 4. Environment setup
```bash
cp .env.example .env
chmod 600 .env         # host-only; git-ignored; never committed
# edit .env and replace every placeholder
```

## 5. Secret generation
```bash
openssl rand -base64 48   # JWT_SECRET  (>=32 chars, keep STABLE across restarts)
openssl rand -base64 48   # VOUCHER_SIGNING_SECRET (>=32 chars, keep STABLE)
```
Set `MSSQL_SA_PASSWORD` (strong: upper/lower/digit/symbol, ≥ 8) and use the **same value** in
`SPRING_DATASOURCE_PASSWORD`. Never commit `.env`.

## 6. Compose startup
```bash
# Build the Flutter Web bundle first (see §11), then:
docker compose up -d --build
docker compose ps
docker compose logs -f app
```
Order is enforced by healthchecks: `db` healthy → `db-init` creates the database → `app` runs Flyway +
validate + bootstrap → `web` serves.

## 7. Database initialization
SQL Server cannot auto-create a database, so the one-shot `db-init` runs `db/init/create-database.sql`,
which creates **only** the `APP_DB_NAME` database (no tables). It is idempotent and never touches schema.

## 8. Flyway behavior
Under the `prod` profile, Flyway runs **before** Hibernate and applies `db/migration/V1__initial_schema.sql`
(90 tables) into the database, recording `flyway_schema_history`. Migrations are **forward-only**
(Community edition — no undo). Never edit an applied migration; add `V2+` for changes.

## 9. Bootstrap behavior
`ProductionBootstrap` (`@Profile("prod")`) idempotently seeds the default referral campaign and loyalty
redemption policy, and — **only if** `ADMIN_BOOTSTRAP_EMAIL` + `ADMIN_BOOTSTRAP_PASSWORD` are set — an
initial admin (BCrypt-hashed, never logged, never overwrites an existing user).

## 10. Health checks
- Liveness: `GET /api/health` → `{"status":"UP", ...}`.
- Readiness: `GET /api/health/ready` → `SELECT 1` → `200 {"status":"UP","db":"UP"}` or `503` when the DB is
  unreachable. The `app` container healthcheck uses `/api/health/ready`.
Through Nginx: `curl -fsS http://<host>:${WEB_HTTP_PORT}/api/health/ready`.

## 11. Flutter build (same-origin)
From the frontend worktree:
```bash
cd frontend
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=/api
```
Output: `frontend/build/web/`. Point `WEB_ROOT` in `.env` at that directory (relative or absolute). The
`/api` value makes the browser call the API on the **same origin**, so no CORS is involved.

## 12. Nginx
`nginx/nginx.conf` serves the SPA (`try_files … /index.html`) and proxies `location /api/` →
`http://app:8080` (path preserved), forwarding `Authorization` and `X-Forwarded-*`. It emits **no** CORS
headers (same-origin). SQL Server and `app` are never exposed by Nginx.

## 13. DNS
Point an A/AAAA record at the VPS public IP. Use that hostname in the TLS cert and as the canonical origin.

## 14. HTTPS / TLS (production only)
Terminate TLS in front of `web`. Options: add a certbot/Let's Encrypt companion or a host reverse proxy
(Caddy/Traefik/nginx) on 443 → `web:80`. Local verification uses plain HTTP on `WEB_HTTP_PORT`. After TLS,
set `SPRING_DATASOURCE_URL` `trustServerCertificate=false` (see §21) and set `CORS_ALLOWED_ORIGIN_PATTERNS`
to the `https://` origin if any cross-origin client exists.

## 15. Backup setup
`scripts/backup.sh` runs `BACKUP DATABASE` inside the `db` container to the `mssql-backups` volume with a
timestamped filename; it fails on SQL error and never logs the password. Schedule via host cron:
```bash
0 * * * * cd /opt/planyourtrip && docker compose exec -T \
  -e MSSQL_SA_PASSWORD="$(grep '^MSSQL_SA_PASSWORD=' .env | cut -d= -f2-)" \
  db /scripts/backup.sh >> /var/log/pyt-backup.log 2>&1
```
Copy the `.bak` files off-host for disaster recovery. **Backup scheduling is not production-verified by
this repo** — validate it in your environment.

## 16. Restore procedure
Copy the chosen `.bak` into the backup volume, then:
```bash
docker compose exec -e MSSQL_SA_PASSWORD=... db /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa \
  -P "$MSSQL_SA_PASSWORD" -C -b -Q "RESTORE DATABASE [PlanYourTrip] FROM DISK=N'/var/opt/mssql/backups/<file>.bak' WITH REPLACE"
```
For point-in-time recovery, use the FULL recovery model + regular log backups (an infrastructure decision).

## 17. Logs
`docker compose logs -f app` (Spring), `… db`, `… web`. Spring logs to stdout (captured by Docker); no
secrets are logged (`show-sql=false`; secret validators never echo values).

## 18. Troubleshooting
- **`app` unhealthy / restarting:** check `logs app`. Fail-fast on a weak/missing `JWT_SECRET` or
  `VOUCHER_SIGNING_SECRET`, or an unresolved datasource → the context refuses to start by design.
- **TLS/login errors app→db:** locally ensure `trustServerCertificate=true`; verify `MSSQL_SA_PASSWORD`
  matches `SPRING_DATASOURCE_PASSWORD`.
- **Flyway validation/`validate` failure:** schema drift vs entities — do not hand-edit V1; investigate.
- **`web` 404s on refresh:** confirm `WEB_ROOT` points at a real `build/web` with `index.html`.

## 19. Rollback
- **App:** redeploy the previous image tag (`docker compose up -d` with the prior `app` image).
- **Database:** Flyway is forward-only → roll back by **restoring a backup** (§16) and shipping a new `V2+`
  migration. Never edit or delete an applied migration.

## 20. DB-05 verification (live SQL Server chain)
Use the **existing gated test** (do not invent another mechanism). Against the Compose SQL Server:
```bash
docker compose up -d db db-init
DB05_SQLSERVER_VERIFY=true \
SPRING_PROFILES_ACTIVE=prod \
SPRING_DATASOURCE_URL='jdbc:sqlserver://localhost:1433;databaseName=PlanYourTrip;encrypt=true;trustServerCertificate=true;sendStringParametersAsUnicode=true' \
SPRING_DATASOURCE_USERNAME=sa SPRING_DATASOURCE_PASSWORD='...' \
JWT_SECRET='<32+>' VOUCHER_SIGNING_SECRET='<32+>' \
./mvnw -Dtest=SqlServerProdChainVerificationTest test
```
(Requires temporarily publishing `db`'s 1433 to the host, or running the test from inside the network.)
This proves Flyway apply + Hibernate `validate` + ProductionBootstrap against a real SQL Server. **Status:
NOT RUN in this environment (no Docker).**

## 21. Security checklist
- [ ] `.env` is git-ignored and never committed; no real secrets in the repo.
- [ ] SQL Server has **no** published host port (internal network only).
- [ ] `app` 8080 is **not** published (reachable only via Nginx).
- [ ] `JWT_SECRET` / `VOUCHER_SIGNING_SECRET` are strong (≥32), stable, injected via env.
- [ ] `SPRING_PROFILES_ACTIVE=prod` → Swagger/OpenAPI disabled, H2 console unavailable, `ddl-auto=validate`,
      Flyway enabled, `ProductionBootstrap` active (all from DB-06 — unchanged by INFRA-02).
- [ ] **Production** datasource uses a trusted certificate with `encrypt=true;trustServerCertificate=false`
      (the `true` in `.env.example` is a LOCAL-ONLY allowance for the container's self-signed cert).
- [ ] TLS terminates in front of `web` in production (§14).
- [ ] Same-origin preserved (`API_BASE_URL=/api`) → no CORS surface.
