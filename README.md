# Docker Workshop — Starter Repo

In this workshop, You'll **containerize a Node.js + Express
web app backed by Postgres**, orchestrate it with **docker-compose**, and wire
up a **GitHub Actions CI pipeline** that builds your image, scans it with
**Trivy** (Image Scanning tools), and pushes it to **Docker Hub**.

The app code under `app/` is **complete**. Your job is to fill in the
`#TODO(...)` markers in the infrastructure files. Every TODO maps to a
checklist item in the Self-Verification section below — tick them off as you go.

---

## Self-Verification Checklist (10 items)

Tick each box as you complete it. The workshop is **done** when all 10 are ticked.

- [x] **AC-01:** `docker build -t workshop-app .` exits with status 0 locally.
- [x] **AC-02:** Dockerfile uses a multi-stage build (`grep -c '^FROM' Dockerfile` = 2).
- [x] **AC-03:** `.dockerignore` excludes at least `node_modules`, `.git`, and `.env`.
- [x] **AC-04:** Dockerfile contains a `HEALTHCHECK` instruction.
- [x] **AC-05:** `docker compose up -d` brings up two healthy containers within 60 seconds.
- [x] **AC-06:** `web` waits for `db` health (`docker compose config` shows `condition: service_healthy`).
- [x] **AC-07:** `.github/workflows/ci.yml` triggers on`push` to `main`.
- [x] **AC-08:** The CI step `scan` uses `aquasecurity/trivy-action` with `severity: CRITICAL` and `exit-code: '1'`, and reports **0 CRITICAL** findings.
- [x] **AC-09:** The CI step `push` pushes two tags: `:latest` and `:${{ github.sha }}`.
- [ ] **AC-10:** The `build-scan-push` job goes green on your fork after Docker Hub secrets are configured.

### Local verification — 2026-11-01

All infrastructure TODOs are filled in, and `.env` was copied from `.env.example`
(and remains ignored by Git). The application source, SQL, and `package.json`
are unchanged. The dependency lockfile contains a security patch for
`proxy-addr` from 2.0.7 to 2.0.8.

- The image build and `docker compose config --quiet` pass.
- `docker compose up -d --build --wait --wait-timeout 60` brought both services
  to healthy in 12.79 seconds, including the cached image build.
- `/` returns `{"ok":true,"service":"workshop-app"}`, `/health` returns
  `{"status":"ok"}`, and `/tasks` returns the seed task.
- `actionlint` passes. AC-07 and AC-09 are verified from the workflow
  configuration; publishing has not been exercised on GitHub.
- **AC-08 passes locally:** Trivy 0.76.1 with `--severity CRITICAL --exit-code 1`
  returns exit code 0 with zero CRITICAL findings, including unfixed issues.
  Both Docker stages now use `node:24.22.2-trixie-slim`; the original
  `node:20.11-slim` base and `proxy-addr` lockfile entry needed security
  updates. CI uses the same scanner version and does not ignore unfixed
  vulnerabilities. This is a deliberate security update to the starter's
  prescribed versions; the two-stage build and app behavior are preserved.
- **AC-10 remains open:** GitHub authentication and both Docker Hub secrets
  are configured. The hosted `build-scan-push` job must still be run and
  verified after pushing these changes to `main`.

To reproduce the local vulnerability check after building the image:

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v workshop-trivy-cache:/root/.cache/ aquasec/trivy:0.76.1 image --scanners vuln --severity CRITICAL --exit-code 1 workshop-app
```

---

## Step-by-Step Walkthrough

> **TODO convention:** look for `# TODO(step-N<letter>)` (or `// TODO(step-N<letter>)`)
> comments inside the target file. Each step below tells you which file and which
> TODOs to complete.

### Step 1 — Fork and clone

1. Fork this repo to your own GitHub account.
2. Clone your fork locally and `cd` into it.
3. Copy `.env.example` to `.env`.

### Step 2 — Look at the app (no changes)

Open `app/src/index.js`. Notice the three routes:
- `GET /` → `{ ok: true }`
- `GET /health` → 200 if it can reach Postgres, 503 otherwise (the Dockerfile HEALTHCHECK hits this)
- `GET /tasks` → list from the `tasks` table, seeded by `app/db/init.sql`

Keep the application source and database initialization code unchanged.
The completed workshop updates only `app/package-lock.json` for the
`proxy-addr` security patch described above.

### Step 3 — `.dockerignore`

Open `.dockerignore` and complete `TODO(step-3)`. Required entries:

**Verify (AC-03):**
```bash
grep -E '^(node_modules|\.git|\.env)$' .dockerignore
```
Should print three matching lines.

### Step 4 — Multi-stage Dockerfile

Open `Dockerfile` and complete `TODO(step-4a)` through `TODO(step-4g)` (7 markers).
Pay special attention to **step-4f** — the HEALTHCHECK uses a **Node one-liner**
because the slim Node image does **not** include `curl` or `wget`.
The completed Dockerfile uses the pinned `node:24.22.2-trixie-slim` tag for
both stages to address vulnerabilities in the starter's older Node image.

### Step 5 — docker-compose.yml

Open `docker-compose.yml` and complete `TODO(step-5a)` through `TODO(step-5h)` (8 markers).
The key wiring: `web` `depends_on` `db` with `condition: service_healthy`, so the
app doesn't try to connect before Postgres is ready.

**Verify (AC-05, AC-06):**
```bash
docker compose up -d
docker compose ps                 
docker compose config | grep -A1 depends_on
```

Smoke test (also confirms AC-04 at runtime):
```bash
docker inspect --format='{{.State.Health.Status}}' \
  $(docker compose ps -q web)            # should print: healthy
curl -fsS http://localhost:3000/health   # should print {"status":"ok"}
curl -fsS http://localhost:3000/tasks    # should list the seed task
```

### Step 6 — GitHub Actions CI

Open `.github/workflows/ci.yml` and complete `TODO(step-6a)` through `TODO(step-6e)` (5 markers).
The completed workflow triggers on pushes to `main` and also supports
`workflow_dispatch` for manually starting or retrying the workshop pipeline.

**Add secrets to your fork** *before* pushing:
- GitHub → your fork → **Settings → Secrets and variables → Actions → New repository secret**
- Add `DOCKERHUB_USERNAME` (your Docker Hub username)
- Add `DOCKERHUB_TOKEN` (the Personal Access Token from Prerequisites)

**Verify (AC-07..AC-10):**
```bash
git add .
git commit -m "complete docker workshop"
git push
# Then open the "Actions" tab on your fork and watch the job run.
```

When `build-scan-push` goes green, your image is live on Docker Hub at
`docker.io/<your-username>/workshop-app:latest` and `:${{ github.sha }}`.

---

## File Map

```
.
├── README.md                    # this file
├── .gitignore
├── .dockerignore                # 1 TODO
├── .env.example
├── Dockerfile                   # 7 TODOs (step-4a..g)
├── docker-compose.yml           # 8 TODOs (step-5a..h)
├── .github/workflows/ci.yml     # 5 TODOs (step-6a..e)
└── app/
    ├── package.json             # complete — do not edit
    ├── package-lock.json        # proxy-addr security patch applied
    ├── db/init.sql              # complete — do not edit
    └── src/
        ├── index.js             # complete — do not edit
        └── db.js                # complete — do not edit
```

## Peer Review — Pull and Run a Classmate's Image

Use these commands to pull a classmate's published image from Docker Hub and verify it works end-to-end.

```bash
# 1. Pull your classmate's image from Docker Hub
docker pull <their-dockerhub-username>/workshop-app:latest

# 2. Create an isolated network and start a temporary Postgres container
docker network create peer-test

docker run -d \
  --name peer-db \
  --network peer-test \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=workshop \
  postgres:16-alpine

# 3. Run their app connected to the database
docker run -d \
  --name peer-app \
  --network peer-test \
  -p 3000:3000 \
  -e DATABASE_URL=postgres://postgres:postgres@peer-db:5432/workshop \
  <their-dockerhub-username>/workshop-app:latest

# 4. Wait ~10 seconds for Postgres to initialize, then verify
curl -fsS http://localhost:3000/health   # expected: {"status":"ok"}

# 5. Clean up when done
docker rm -f peer-app peer-db
docker network rm peer-test
```


Good luck! 
