# BlackDuck Integration Design

**Date:** 2026-05-16
**Branch:** BlackDuck
**Goal:** Add Black Duck Detect as a Docker-based Jenkins pipeline stage to demonstrate a production-like SCA (Software Composition Analysis) security gate alongside SonarQube and Kyverno.

---

## 1. Approach

Run `blackducksoftware/detect` as a one-shot Docker container inside a new Jenkins pipeline stage. No persistent Black Duck Hub server is required. Detect scans the project's dependency manifests (`pom.xml`, `frontend/package.json`) and the built JAR for known vulnerabilities and license information, then writes a report to the Jenkins workspace. The stage runs in audit mode — it never fails the build.

This follows the existing lab pattern of Docker Compose-based services and env-var-driven configuration.

---

## 2. Pipeline Position

The new stage is inserted at position 7, between `Build Docker Image` and `Push to Harbor`:

```
1. Setup Maven Wrapper
2. Checkout
3. Maven Build
4. Unit Tests
5. SonarQube Analysis
6. Build Docker Image
7. BlackDuck Detect Scan   ← NEW
8. Push to Harbor
9. Load Image into Kind
10. Build Frontend Image
11. Push Frontend to Harbor
12. Load Frontend into Kind
13. Update Helm Chart
14. Prepare Namespace
15. Deploy with ArgoCD
16. Deploy Kyverno Policies
17. Verify Deployment
```

Scanning after the Docker image is built allows Detect to inspect the full dependency graph from both the built JAR and the source manifests.

---

## 3. Components

### 3.1 Jenkins Stage — `BlackDuck Detect Scan`

Added to `Jenkinsfile` as a new declarative stage. The stage:

1. Creates `blackduck-reports/` in the workspace
2. Runs `blackducksoftware/detect:${BLACKDUCK_DETECT_VERSION:-latest}` via `docker run --rm`
3. Mounts the workspace as `/workspace` inside the container
4. Passes `DETECT_SOURCE_PATH`, `DETECT_OUTPUT_PATH`, `DETECT_PROJECT_NAME`, and `DETECT_PROJECT_VERSION_NAME` as environment variables
5. Passes `BLACKDUCK_URL` and `BLACKDUCK_API_TOKEN` only when set (Hub integration is optional)
6. Always exits 0 (`|| true`) — audit mode
7. Archives `blackduck-reports/**` as Jenkins build artifacts

### 3.2 Optional Standalone Runner — `docker/blackduck/docker-compose.yml`

A Docker Compose file for running Detect outside of Jenkins (manual scans, local development). Mounts the project root and writes reports to `./blackduck-reports`. Useful for learning and troubleshooting outside the CI context.

### 3.3 Environment Variables

Added to `.env.template`:

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `BLACKDUCK_DETECT_VERSION` | No | `latest` | Pin Detect image version |
| `BLACKDUCK_PROJECT_NAME` | No | `cicd-demo` | Project name in Hub (if connected) |
| `BLACKDUCK_PROJECT_VERSION` | No | `${BUILD_NUMBER}` | Version tag per build |
| `BLACKDUCK_URL` | No | _(unset)_ | Hub server URL — omit for offline mode |
| `BLACKDUCK_API_TOKEN` | No | _(unset)_ | Hub API token — omit for offline mode |

### 3.4 Jenkins Credentials (optional)

Two Secret Text credentials, only needed when a Hub server is available:

- `blackduck-url` — the Hub server URL
- `blackduck-api-token` — a Hub API token with scan permissions

---

## 4. Data Flow

```
Inputs:
  - ${WORKSPACE}/pom.xml
  - ${WORKSPACE}/frontend/package.json
  - ${WORKSPACE}/target/*.jar
  - BLACKDUCK_URL (optional)
  - BLACKDUCK_API_TOKEN (optional)

Process:
  docker run --rm blackducksoftware/detect \
    → scans dependency manifests and JAR
    → (optional) uploads results to Hub
    → writes report files to blackduck-reports/

Outputs:
  - blackduck-reports/detect-output.txt  (console log)
  - blackduck-reports/risk-report.json   (structured findings)
  - Jenkins artifact: blackduck-reports/**
```

---

## 5. Error Handling

| Scenario | Behaviour |
|---|---|
| Detect image pull fails (no network) | Stage emits warning, continues (`\|\| true`) |
| Hub unreachable (`BLACKDUCK_URL` set but server offline) | Detect falls back to offline scan; local report still generated |
| HIGH/CRITICAL CVEs found | Logged in report artifact; pipeline continues (audit mode) |
| No credentials configured | Detect runs offline — no Hub upload, local report only |
| Report directory not writable | `mkdir -p blackduck-reports` runs before container starts |

---

## 6. Files Changed

| File | Change |
|---|---|
| `Jenkinsfile` | New stage `BlackDuck Detect Scan` added at position 7 |
| `docker/blackduck/docker-compose.yml` | New file — optional standalone runner |
| `docs/BlackDuck.md` | New tool guide: setup, credentials, reading reports, connecting to Hub |
| `.env.template` | 5 new commented variables with descriptions |
| `docs/INDEX.md` | BlackDuck.md entry added under Security section |
| `docs/Port-Reference.md` | Note: Detect-only uses no new port; Hub would use 8083 if added later |
| `CLAUDE.md` | BlackDuck added to CI/CD Pipeline Flow section |

---

## 7. Out of Scope

- Standing up a full Black Duck Hub server (requires license, 8–16 GB RAM)
- Failing the build on vulnerability findings (can be added later via `BLACKDUCK_FAIL_ON_SEVERITY`)
- Scanning the built Docker image layers for OS-level packages (requires Hub's container scan feature)
- Frontend image scanning (only backend/Maven project scanned in this iteration)
