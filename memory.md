# Changelog

All notable changes to the DevOps CI/CD Learning Laboratory project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased] — branch: feature--Updated-versions

### Commit Log (chronological)

| Hash | Date | Description |
|------|------|-------------|
| `096755a` | 2026-03-09 15:54 | Add comprehensive improvement plan for DevOps CI/CD Learning Laboratory |
| `ebc9fa9` | 2026-03-09 16:01 | feat: Enhance documentation with detailed links and changelog |
| `d0747d2` | 2026-03-09 16:39 | feat: Update SonarQube port from 8090 to 9000 across documentation and configuration files |
| `388c875` | 2026-03-09 20:13 | feat: Create new memory.md file to document project changes and updates |
| `cf815b1` | 2026-03-09 20:21 | feat: Update references to CHANGELOG.md to point to memory.md |
| `c0835bc` | 2026-03-09 21:16 | feat: Mark documentation standardization and port configuration fixes as completed |

---

### Phase 1: Documentation Standardization (2026-03-09) — `096755a`

#### Added
- Created comprehensive documentation index at `docs/INDEX.md` with 32 guides across 7 categories
- Added "Related Documents" cross-references to ArgoCD.md, Harbor.md, Jenkins.md, Kind-K8s.md, and StudyPlan.md
- Created `AGENTS.md` with DevOps Professional agent specification (6-phase improvement plan context)
- Created `plan.md` — 6-phase improvement roadmap with success metrics and risk assessment
- Added learning path navigation (Beginner, Intermediate, Advanced) to documentation index
- Added Quick Find section to documentation index for rapid navigation

#### Changed
- Renamed `docs/argocd-setup.md` to `docs/ArgoCD-QuickStart.md` for naming consistency
- Renamed `docs/#Lab-Setup-Guide.md` to `docs/Lab-Setup-Guide.md` (removed hash prefix)
- Updated directory reference from `/ai` to `/instructions` in Project-Overview.md
- Fixed 4 broken documentation links in README.md (removed `#` from Lab-Setup-Guide references)
- Removed reference to non-existent `QUICK-START-Harbor-Kind.md` from README
- Updated 3 files referencing renamed ArgoCD doc (README.md, setup-argocd-repo.sh, ArgoCD_setup-argocd-repo.md)
- Enhanced README.md with prominent link to documentation index
- 14 files changed: +595 insertions, -9 deletions

---

### Changelog Bootstrap (2026-03-09) — `ebc9fa9`

#### Added
- Created `changelog.md` (253 lines) — full project history from v1.0.0 through current unreleased work
- Added comprehensive version history sections: [2.0.0], [1.5.0], [1.0.0]
- Added Upcoming Features section covering Phases 3–6 of the improvement plan

#### Changed
- Updated README.md with prominent link to changelog and documentation index
- Updated `docs/INDEX.md` with changelog reference
- 3 files changed: +260 insertions, -3 deletions

---

### Phase 2: Port Configuration Fixes (2026-03-09) — `d0747d2`

#### Added
- Added Application port (8001) to README.md quick access list
- Added comprehensive health check endpoints table with expected responses for all services
- Added extensive Docker network vs host networking explanation with practical examples
- Added comprehensive kubectl port-forward examples section (20+ usage scenarios)
- Added port mapping rules table explaining container-to-container vs external access
- Added automated health check testing script examples
- Enhanced Port-Reference.md with Docker bridge network and Kind network details
- Added troubleshooting section for port conflicts and network issues

#### Changed
- **CRITICAL FIX**: Corrected SonarQube port from 8090 to 9000 across all documentation
  - Updated README.md, Port-Reference.md, Architecture-Diagram.md
  - Updated SonarQube.md, SonarQube-QuickRef.md, Lab-Setup-Guide.md
  - Fixed `.env.template` SONARQUBE_PORT from 8090 to 9000
  - Resolved port conflict between SonarQube and ArgoCD
- Standardized ArgoCD port to 8090 (HTTPS) throughout documentation
  - Clarified ArgoCD uses port 8090 to avoid Jenkins conflict (8080)
  - Updated Port-Reference.md with clear ArgoCD port mapping explanation
- Enhanced Port-Reference.md port summary table with accurate internal/external mappings
- Updated health check endpoints with correct URLs and expected JSON responses
- Enhanced `k8s-permissions_port-forward.sh` header documentation (v2.0):
  - Added comprehensive purpose and features section
  - Added troubleshooting guide within script comments
  - Added exit codes and prerequisites documentation
  - Added practical usage examples
  - Updated managed services list

#### Fixed
- Fixed SonarQube port conflict (was incorrectly documented as 8090, conflicting with ArgoCD)
- Fixed missing Application port (8001) in quick access documentation
- Fixed inconsistent SonarQube host URLs in code examples (8090 → 9000)
- Fixed Port-Reference.md table to show correct SonarQube internal/external ports (9000/9000)
- Fixed health check endpoint URLs for SonarQube and ArgoCD
- 9 files changed: +451 insertions, -58 deletions
- Port-Reference.md grew from ~400 lines to ~850 lines

---

### Changelog Renamed to memory.md (2026-03-09) — `388c875`, `cf815b1`

#### Changed
- Renamed `changelog.md` to `memory.md` to better reflect its role as persistent project knowledge
- Updated all references from `changelog.md` / `CHANGELOG.md` to `memory.md` in:
  - README.md
  - docs/INDEX.md
  - plan.md (3 references)

---

### Plan Progress Update (2026-03-09) — `c0835bc`

#### Changed
- Marked Phase 1 (Documentation Standardization) tasks as completed in `plan.md`
- Marked Phase 2 (Port Configuration Fixes) tasks as completed in `plan.md`
- Updated task checkboxes and status markers across 22 items in plan.md

---

### AI Context File (2026-03-10) — working session

#### Added
- Created `CLAUDE.md` — guidance file for Claude Code with build commands, service port table, architecture overview, CI/CD pipeline flow, and key configuration file references

---

## [2.0.0] - 2025-12-12

### Added - Full-Stack Application Architecture
- PostgreSQL 16 database layer with StatefulSet deployment and 2Gi persistent storage
- Spring Boot 3.5.7 backend with Java 21, JPA/Hibernate, and REST API (8 endpoints)
- React 19 frontend with TypeScript, Vite, React Query, and Tailwind CSS
- Flyway database migration support for version-controlled schema management
- Full-stack deployment script `deploy-fullstack.sh`
- Comprehensive test suite with 20 automated tests in `test-deployment.sh`
- PostgreSQL verification script `verify-postgres.sh`
- Documentation: FULLSTACK-DEPLOYMENT.md, POSTGRES-TEST-REPORT.md, DEPLOYMENT-TEST-RESULTS.md

### Added - Policy & Monitoring
- Kyverno policy engine with 8+ security and compliance policies (Audit mode)
- Policy Reporter with UI (port 31002) and API (port 31001) for violation monitoring
- Grafana + Loki + Prometheus observability stack
- Resource limit policies for CPU and memory
- Harbor registry enforcement policies
- Non-root container policies
- Read-only root filesystem policies

### Added - ArgoCD GitOps Integration
- ArgoCD application definitions in `argocd-apps/` directory
- `cicd-demo.yaml` - Main application deployment
- `kyverno-policies.yaml` - Policy-as-Code deployment
- `sample-nginx-app.yaml` - Sample application for testing
- Automated ArgoCD repository setup script
- Application sync automation in Jenkins pipeline

### Added - Documentation
- Architecture diagram showing complete CI/CD pipeline
- Port reference guide with all 14 service ports documented
- Harbor-Kind integration guide
- Harbor-Jenkins credential setup guide
- GitHub-Jenkins credential setup guide
- SonarQube quick reference guide
- Jenkins-Kyverno setup guide
- Troubleshooting guide with common issues and solutions
- Cleanup guide for teardown procedures
- Scripts documentation reference

### Changed - Infrastructure
- Upgraded to Java 21 from Java 17
- Upgraded to Spring Boot 3.5.7
- Enhanced Kind cluster configuration with proper networking
- Improved port forwarding automation with PID management
- Updated Jenkins pipeline to support multi-tier deployment
- Refactored Helm chart with separate backend and frontend templates

### Changed - Security
- Implemented non-root containers (UID 999 for PostgreSQL)
- Added security contexts with fsGroup configuration
- Added liveness and readiness probes to all services
- Configured resource limits (CPU: 250m-500m, Memory: 256Mi-512Mi)
- Added init container for PostgreSQL permission fixes

### Fixed - Deployment Issues
- Fixed PostgreSQL CrashLoopBackOff due to permission issues
- Added init container to fix PVC permissions for non-root PostgreSQL
- Fixed Kyverno policy blocking PostgreSQL image (added exemption for postgres:*)
- Disabled legacy Helm templates (deployment.yaml, service.yaml) to prevent duplicates
- Fixed namespace creation webhook failures with existence checks
- Fixed ArgoCD application conflicts with delete-before-create strategy
- Resolved container resource limit violations
- Fixed frontend TypeScript build errors

### Fixed - Kyverno Policies
- Updated `harbor-only-images.yaml` to exempt PostgreSQL pods using label selectors
- Added anyPattern support for multiple allowed image patterns (Harbor + postgres)
- Configured policies in Audit mode to prevent blocking deployments
- Enhanced policy testing suite with valid and invalid test cases

---

## [1.5.0] - 2025-12-07

### Added
- Comprehensive setup automation script `setup-all.sh`
- Environment verification script `verify-environment.sh`
- Automated port forwarding with `k8s-permissions_port-forward.sh`
- Harbor robot account creation script `create-harbor-robot.sh`
- Jenkins Docker setup script with pre-configured plugins
- SonarQube setup script with Docker Compose
- ArgoCD repository setup automation

### Changed
- Improved repository structure with clear separation of concerns
- Enhanced README with detailed quick start guide
- Updated study plan with tool priorities and learning paths
- Reorganized Kubernetes manifests by service type

### Fixed
- Docker Desktop networking issues with Kind cluster
- Harbor insecure registry configuration for localhost
- Jenkins credential binding for GitHub and Harbor
- SonarQube token generation and Maven integration

---

## [1.0.0] - 2025-11-01

### Added - Initial Release
- DevOps CI/CD Learning Laboratory foundation
- 14-tool integrated environment:
  - **CI/CD**: Jenkins, ArgoCD
  - **Containers**: Docker, Kind (Kubernetes in Docker), Harbor registry
  - **Package Management**: Maven, Helm Charts
  - **Code Quality**: SonarQube
  - **Policy**: Kyverno
  - **Monitoring**: Grafana, Loki, Prometheus, Policy Reporter
- Spring Boot demo application with REST API
- Jenkins declarative pipeline with SonarQube analysis
- Harbor registry with vulnerability scanning
- Kind cluster with multi-node support
- Helm chart for application deployment
- Basic Kubernetes manifests for sample deployments
- Comprehensive documentation for each tool
- Study plan with beginner, intermediate, and advanced paths

### Added - Documentation
- Lab Setup Guide with 11-phase installation
- Individual tool guides (ArgoCD, Docker, Harbor, Jenkins, Kind, Helm, Maven, SonarQube, Grafana/Loki)
- Project overview with architecture details
- Troubleshooting guide
- Port reference for all services

### Added - Configuration
- Kind cluster configuration with port mappings
- Jenkins pipeline configuration (Jenkinsfile)
- Harbor Docker Compose setup
- SonarQube Docker Compose setup
- Environment variable template (.env.template)
- Git ignore rules for security and build artifacts

---

## Version History Summary

| Version | Branch | Date | Highlights |
|---------|--------|------|------------|
| **Unreleased** | feature--Updated-versions | 2026-03-10 | Phase 1 + Phase 2 complete; memory.md; CLAUDE.md |
| **2.0.0** | main | 2025-12-12 | Full-Stack Architecture, PostgreSQL, Kyverno, Policy Reporter |
| **1.5.0** | main | 2025-12-07 | Setup Automation, Script Improvements |
| **1.0.0** | main | 2025-11-01 | Initial Release, 14-Tool Environment |

---

## Migration Notes

### Upgrading from 1.x to 2.0

**Breaking Changes:**
- Helm chart structure changed: legacy `deployment.yaml` and `service.yaml` disabled
- New backend and frontend deployments use separate templates
- PostgreSQL StatefulSet added as new dependency
- Port 30080 now used for frontend (NodePort)
- ArgoCD applications require updated sync strategies

**Required Actions:**
1. Delete existing ArgoCD applications before upgrade
2. Run database deployment: `./scripts/deploy-fullstack.sh`
3. Verify deployment: `./scripts/test-deployment.sh`
4. Update Jenkins pipeline to use new Helm templates
5. Configure Kyverno policies if not using default Audit mode

**New Features to Leverage:**
- Full-stack application demonstration
- PostgreSQL for data persistence
- Kyverno policy enforcement
- Policy Reporter for compliance monitoring
- Enhanced observability with Grafana dashboards

---

## Upcoming Features (Planned)

### Phase 3: Quick Start Enhancements (Planned)
- Create `docs/QUICK-START.md` - First 5 minutes guide
- Command cheat sheets for common tasks
- First day checklist for new users
- Prerequisite verification checklist

### Phase 4: Security Enhancements (Planned)
- Security best practices guide
- Credential rotation procedures
- Enhanced RBAC documentation
- Network security recommendations
- Kyverno policy explanations

### Phase 5: Testing Improvements (Planned)
- Integration test suite expansion
- Performance benchmark scripts
- Load testing guide
- Enhanced test result reporting

### Phase 6: User Experience (Planned)
- FAQ section with common questions
- Enhanced troubleshooting with decision trees
- Success metrics and verification checklists
- Performance benchmarks

---

## Contributing

See [plan.md](plan.md) for the complete improvement roadmap and contribution guidelines.

## References

- **Project Repository**: https://github.com/gmedeirosnet/CI.CD
- **Documentation**: [docs/INDEX.md](docs/INDEX.md)
- **Study Plan**: [docs/StudyPlan.md](docs/StudyPlan.md)
- **Improvement Plan**: [plan.md](plan.md)

---

**Maintained by**: DevOps Lab Team
**Last Updated**: 2026-03-10
**Status**: Active Development
