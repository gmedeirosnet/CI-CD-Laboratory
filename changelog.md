# Changelog

All notable changes to the DevOps CI/CD Learning Laboratory project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added - Phase 2: Port Configuration Fixes (2026-03-09)
- Added Application port (8001) to README.md quick access list
- Added comprehensive health check endpoints table with expected responses for all services
- Added extensive Docker network vs host networking explanation with practical examples
- Added comprehensive kubectl port-forward examples section with 20+ usage scenarios
- Added port mapping rules table explaining container-to-container vs external access
- Added automated health check testing script examples
- Enhanced Port-Reference.md with Docker bridge network and Kind network details
- Added troubleshooting section for port conflicts and network issues

### Changed - Phase 2: Port Configuration Fixes (2026-03-09)
- **CRITICAL FIX**: Corrected SonarQube port from 8090 to 9000 across all documentation
  - Updated README.md, Port-Reference.md, Architecture-Diagram.md
  - Updated SonarQube.md, SonarQube-QuickRef.md, Lab-Setup-Guide.md
  - Fixed .env.template SONARQUBE_PORT from 8090 to 9000
  - Resolved port conflict between SonarQube and ArgoCD
- Standardized ArgoCD port to 8090 (HTTPS) throughout documentation
  - Clarified ArgoCD uses port 8090 to avoid Jenkins conflict (8080)
  - Updated Port-Reference.md with clear ArgoCD port mapping explanation
- Enhanced Port-Reference.md port summary table with accurate internal/external mappings
- Updated health check endpoints with correct URLs and expected JSON responses
- Enhanced k8s-permissions_port-forward.sh header documentation:
  - Added comprehensive purpose and features section
  - Added troubleshooting guide within script comments
  - Added exit codes and prerequisites documentation
  - Added practical usage examples
  - Updated version to 2.0 with detailed managed services list
- Clarified port mapping strategy (ArgoCD:8090 avoids Jenkins:8080 conflict)
- Updated Port Testing Commands section with better examples

### Fixed - Phase 2: Port Configuration Fixes (2026-03-09)
- Fixed SonarQube port conflict (was incorrectly documented as 8090, conflicting with ArgoCD)
- Fixed missing Application port (8001) in quick access documentation
- Fixed inconsistent SonarQube host URLs in code examples (8090 → 9000)
- Fixed Port-Reference.md table to show correct SonarQube internal/external ports (9000/9000)
- Fixed health check endpoint URLs for SonarQube and ArgoCD
- Fixed port conflict documentation and resolution strategies

### Documentation - Phase 2: Port Configuration Fixes (2026-03-09)
- Updated 7 documentation files with correct SonarQube port (9000)
- Enhanced Port-Reference.md from ~400 lines to ~850 lines with comprehensive examples
- Added 120+ lines of kubectl port-forward best practices and examples
- Added Docker networking conceptual explanations with service-to-service communication patterns
- Documented port forward PID management strategy (/tmp/k8s-port-forward/*.pid)

### Added - Phase 1: Documentation Standardization (2026-03-09)
- Created comprehensive documentation index at `docs/INDEX.md` with 32 guides across 7 categories
- Added "Related Documents" cross-references to ArgoCD.md, Harbor.md, Jenkins.md, Kind-K8s.md, and StudyPlan.md
- Created `AGENTS.md` with DevOps Professional agent specification
- Added learning path navigation (Beginner, Intermediate, Advanced) to documentation index
- Added Quick Find section to documentation index for rapid navigation

### Changed - Phase 1: Documentation Standardization (2026-03-09)
- Renamed `argocd-setup.md` to `ArgoCD-QuickStart.md` for naming consistency
- Updated directory reference from `/ai` to `/instructions` in Project-Overview.md
- Fixed 4 broken documentation links in README.md (removed # from Lab-Setup-Guide references)
- Removed reference to non-existent `QUICK-START-Harbor-Kind.md` from README
- Updated 3 files referencing renamed ArgoCD documentation (README.md, setup-argocd-repo.sh, ArgoCD_setup-argocd-repo.md)
- Enhanced README.md with prominent link to documentation index

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

| Version | Date | Highlights |
|---------|------|------------|
| **Unreleased** | 2026-03-09 | Phase 1: Documentation Standardization Complete |
| **2.0.0** | 2025-12-12 | Full-Stack Architecture, PostgreSQL, Kyverno, Policy Reporter |
| **1.5.0** | 2025-12-07 | Setup Automation, Script Improvements |
| **1.0.0** | 2025-11-01 | Initial Release, 14-Tool Environment |

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
**Last Updated**: 2026-03-09
**Status**: Active Development
