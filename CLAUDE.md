# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **DevOps CI/CD Learning Laboratory** — a hands-on environment for learning industry-standard DevOps tools. It contains a full-stack production-grade demo application (PostgreSQL + Spring Boot + React) that flows through a complete CI/CD pipeline.

## Key Rules (from copilot-instructions.md)

- Do not run Git commands without explicit user permission
- Do not use emojis in any files or responses
- Documentation must only be created in the `docs/` directory
- Use environment variables for configuration instead of hardcoded values
- Do not modify `src/main/java` unless explicitly requested

## Build Commands

### Backend (Spring Boot / Maven)

```bash
# Build and package (skips tests)
mvn clean package -DskipTests

# Build with tests
mvn clean package

# Run a single test class
mvn test -Dtest=ClassName

# Run the app locally (requires PostgreSQL)
mvn spring-boot:run
```

### Frontend (React / Vite)

```bash
cd frontend

# Install dependencies
npm install

# Start dev server
npm run dev

# Build for production
npm run build

# Lint
npm run lint
```

## Setup & Operations

### Full Environment Setup

```bash
# 1. Verify prerequisites
./scripts/verify-environment.sh

# 2. Set up environment variables
cp .env.template .env
# Edit .env with your credentials

# 3. Run complete setup (~10-15 min)
./scripts/setup-all.sh

# 4. Start port forwarding
./k8s/k8s-permissions_port-forward.sh start

# 5. Deploy full-stack application
./scripts/deploy-fullstack.sh

# 6. Run deployment verification (20 tests)
./scripts/test-deployment.sh
```

### Port Forwarding Management

```bash
./k8s/k8s-permissions_port-forward.sh start|stop|status|restart
```

### Cluster Management

```bash
# Create Kind cluster
kind create cluster --config kind-config.yaml

# Load image into Kind
./scripts/load-harbor-image-to-kind.sh

# Cleanup everything
./scripts/cleanup-all.sh
```

## Service Ports

| Service         | Port  | URL                              |
|-----------------|-------|----------------------------------|
| Application     | 8001  | http://localhost:8001            |
| Jenkins         | 8080  | http://localhost:8080            |
| Harbor          | 8082  | http://localhost:8082            |
| SonarQube       | 9000  | http://localhost:9000            |
| Grafana         | 3000  | http://localhost:3000            |
| Prometheus      | 30090 | http://localhost:30090           |
| Loki            | 31000 | http://localhost:31000           |
| ArgoCD          | 8090  | https://localhost:8090 (HTTPS)   |
| Policy Reporter | 31002 | http://localhost:31002 (UI)      |
| Policy Reporter | 31001 | http://localhost:31001 (API)     |

**Important**: ArgoCD uses port 8090 (not 8080) to avoid conflict with Jenkins. SonarQube uses port 9000.

## Architecture

### Application Stack (Three-Tier)

- **Database**: PostgreSQL 16 via StatefulSet + PVC (2Gi). Schema managed by Flyway migrations at `src/main/resources/db/migration/`.
- **Backend**: Spring Boot 3.5.7 / Java 21. REST API at `src/main/java/com/example/demo/`. Exposes Actuator metrics at `/actuator`.
- **Frontend**: React 19 + TypeScript + Vite at `frontend/`. Uses TanStack Query for state and Tailwind CSS for styling. Served via Nginx in production.

### CI/CD Pipeline Flow

```
GitHub → Jenkins → Maven build → SonarQube quality gate
                              → Docker build → Harbor registry
                              → Kind image load → Helm package → ArgoCD → Kind K8s
                                                                    ↓
                                                           Kyverno policy validation
                                                                    ↓
                                                    Logs→Loki, Metrics→Prometheus→Grafana
```

### Key Configuration Files

- [Jenkinsfile](Jenkinsfile) — 11-stage declarative pipeline (build, test, quality gate, Docker, Harbor, Kind, Helm, ArgoCD, monitoring)
- [Jenkinsfile-kyverno-policies](Jenkinsfile-kyverno-policies) — Pipeline for Kyverno policy deployment
- [helm-charts/cicd-demo/values.yaml](helm-charts/cicd-demo/values.yaml) — Helm chart values for all three tiers
- [kind-config.yaml](kind-config.yaml) — Kind cluster: 1 control-plane + 2 workers, named `app-demo`
- [k8s/kyverno/policies/](k8s/kyverno/policies/) — 8+ Kyverno policies in Audit mode (namespace, security, resources, registry, labels)
- [argocd-apps/cicd-demo.yaml](argocd-apps/cicd-demo.yaml) — ArgoCD GitOps application definition

### Kyverno Policy Layout

Policies are organized by numbered directories under `k8s/kyverno/policies/`:
- `00-namespace/` — Prevent namespace deletion, require labels
- `10-security/` — Disallow privileged, require non-root, require read-only rootfs
- `20-resources/` — Require resource limits
- `30-registry/` — Enforce Harbor-only images
- `40-labels/` — Add default labels

All policies run in **Audit** mode (violations are logged, not blocked).

### Observability

- Grafana, Loki, and Prometheus run via Docker Compose at `k8s/grafana/`
- Prometheus scrapes the Spring Boot `/actuator/prometheus` endpoint
- Promtail ships container logs to Loki
- Policy Reporter UI (`localhost:31002`) surfaces Kyverno violations

## Environment Configuration

Copy `.env.template` to `.env` and fill in credentials. The `.env` file is gitignored. Key variables:

- `HARBOR_REGISTRY`, `HARBOR_PROJECT`, `HARBOR_ROBOT_NAME`, `HARBOR_ROBOT_SECRET`
- `JENKINS_URL`, `JENKINS_PASSWORD`
- `SONAR_HOST` (default: `http://localhost:9000`), `SONAR_TOKEN`
- `ARGOCD_SERVER` (default: `localhost:8090`), `ARGOCD_ADMIN_PASSWORD`
- `KIND_CLUSTER_NAME` (default: `app-demo`), `KUBE_NAMESPACE` (default: `app-demo`)

## Documentation Structure

All documentation is in `docs/`. Key references:
- [docs/Port-Reference.md](docs/Port-Reference.md) — Authoritative port mapping table
- [docs/Troubleshooting.md](docs/Troubleshooting.md) — Common issues and solutions
- [docs/FULLSTACK-DEPLOYMENT.md](docs/FULLSTACK-DEPLOYMENT.md) — Full-stack deployment guide
- [k8s/kyverno/README.md](k8s/kyverno/README.md) — Kyverno setup and policy guide

## AI / Agent Configuration

The `instructions/` directory contains JSON configs used for AI-assisted learning. The `.github/agents/DevOps.agent.md` defines the specialized DevOps Professional agent for pipeline and infrastructure tasks.
