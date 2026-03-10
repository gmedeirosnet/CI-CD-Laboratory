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
| `[pending]` | 2026-03-10 10:30 | feat: Create Phase 3 quick start enhancements - beginner-friendly onboarding guides |
| `[pending]` | 2026-03-10 11:45 | feat: Create Phase 4 security documentation - best practices, credential rotation, Kyverno policy explanations |

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

### Phase 3: Quick Start Enhancements (2026-03-10) — `[pending]`

#### Added
- Created `docs/QUICK-START.md` (220 lines) — 5-minute quick start guide for new users
  - Prerequisites checklist with system requirements
  - "What to expect" section showing estimated timeline and deliverables
  - 5-step setup process with clear instructions and commands
  - Service access URLs table with default credentials
  - First day tasks checklist (Jenkins, Harbor, Docker, Frontend, Monitoring, Policies)
  - Common issues and solutions troubleshooting section
  - Next steps for continued learning
  - Quick commands reference

- Created `docs/CHEAT-SHEET-Commands.md` (350 lines) — comprehensive command reference organized by tool
  - Environment & Setup commands (environment, port forwarding)
  - Kubernetes & Kind (cluster, pods, services, logs, namespaces)
  - Docker (images, containers, registry operations)
  - Database/PostgreSQL (connection, SQL queries)
  - Maven build commands
  - Frontend/React/Node npm commands
  - Jenkins pipeline operations
  - Harbor registry management
  - SonarQube quality analysis
  - ArgoCD application management
  - Helm chart operations
  - Grafana & Monitoring
  - Kyverno & Policy operations
  - Git repository commands
  - Troubleshooting & diagnostics
  - Cleanup commands

- Created `docs/First-Day-Checklist.md` (300 lines) — comprehensive first day validation checklist
  - Pre-setup checklist (prerequisites verification)
  - Setup verification (environment, cluster, services)
  - Service configuration checklist for each tool (Jenkins, Harbor, Docker, SonarQube, Grafana, ArgoCD)
  - Application deployment checklist (PostgreSQL, Spring Boot, React)
  - Monitoring & logging checklist (Prometheus, Loki, Grafana)
  - Policy & compliance checklist (Kyverno, Policy Reporter)
  - Learning objectives completed section
  - Troubleshooting verification guidance
  - Quick commands reference
  - Next steps after first day
  - Documentation review checklist
  - Success criteria checklist
  - 870+ lines, fully cross-referenced

#### Changed
- Updated plan.md Phase 3 section to mark as COMPLETED (2026-03-10)

#### Impact
- **Beginner-Friendly**: New users can follow QUICK-START.md for setup in ~15 minutes
- **Command Reference**: Engineers have consolidated command cheat sheet for all 14+ tools
- **Validation**: First-Day-Checklist ensures all components working correctly
- **Cross-Reference**: All 3 documents link to each other for navigation
- **Documentation Growth**: +870 lines of new user-facing documentation

#### User Journey
1. New user starts with QUICK-START.md (estimated 15 min setup)
2. Follows First-Day-Checklist to validate everything works
3. References CHEAT-SHEET-Commands.md when needing common commands
4. Moves to detailed tool guides for deeper learning

#### Stats
- 3 new files created
- ~870 lines of documentation added
- Commands organized by tool and use case
- All tools covered in cheat sheet
- 100+ checklist items for validation
- Cross-referenced with existing documentation

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

### Phase 4: Security Enhancements (2026-03-10) — `[pending]`

#### Added
- Created `docs/SECURITY-BestPractices.md` (685 lines, 18,090 chars) — comprehensive security best practices guide
  - Credential management with rotation schedules
  - RBAC configurations for Kubernetes, Harbor, and Jenkins
  - Kyverno policy enforcement (5 categories, 8 policies explained)
  - Network security (network policies, port security, TLS/SSL)
  - Container security (image scanning, non-root users, read-only filesystem)
  - Secret management (Kubernetes secrets, Jenkins credentials, SonarQube tokens)
  - Access control (MFA, IP whitelisting, session management)
  - Security monitoring (logging, policy violations, Prometheus metrics)
  - Compliance & auditing (CIS Kubernetes, NIST, OWASP)
  - Security checklists (initial setup, ongoing operations, production deployment)

- Created `docs/SECURITY-Credential-Rotation.md` (686 lines, 18,535 chars) — step-by-step credential rotation procedures
  - Rotation schedule with recommended frequencies (60-180 days)
  - Harbor robot account rotation (7 steps with rollback procedure)
  - Jenkins credentials rotation (admin password and API token)
  - SonarQube token rotation (6 steps)
  - ArgoCD password rotation (using CLI and kubectl)
  - GitHub token rotation (with scope configuration)
  - PostgreSQL password rotation (user and application credentials)
  - Kubernetes secrets rotation (registry, TLS, service accounts)
  - Automation scripts template
  - Post-rotation verification checklist

- Created `docs/KYVERNO-Policy-CheatSheet.md` (664 lines, 18,086 chars) — quick reference for Kyverno policies
  - Quick commands (view policies, check violations, apply/update, test)
  - Policy overview table (8 policies with severity and mode)
  - Policy categories deep dive (namespace, security, resources, registry, labels)
  - Common use cases with fix examples
  - Troubleshooting guide (policy not working, violations not showing)
  - Policy templates (security, mutation, generate)
  - Best practices (development, organization, testing, performance)
  - Migration to Enforce mode (4-step process)
  - Quick reference card

#### Changed
- Enhanced all 8 Kyverno policy files with detailed explanations:
  - `00-namespace/namespace-prevent-deletion.yaml` — Added 28-line header explaining protection, impact, and override procedure
  - `00-namespace/namespace-requirements.yaml` — Added 41-line header explaining required labels and exemptions
  - `10-security/disallow-privileged.yaml` — Added 45-line header explaining privilege risks and migration to Enforce mode
  - `10-security/require-non-root.yaml` — Added 48-line header explaining non-root benefits and best practices
  - `10-security/require-ro-rootfs.yaml` — Added 68-line header explaining read-only filesystem and migration strategy
  - `20-resources/require-resource-limits.yaml` — Added 85-line header explaining resource limits with recommendations by app type
  - `30-registry/harbor-only-images.yaml` — Added 84-line header explaining Harbor-only enforcement and CI/CD integration
  - `40-labels/add-default-labels.yaml` — Added 79-line header explaining label mutations and querying resources

- Updated `plan.md` to mark Phase 4 as COMPLETED (2026-03-10)
  - Checked all 10 Phase 4 tasks

#### Impact
- **Security Posture**: Comprehensive security documentation covering 10 security domains
- **Credential Management**: Structured rotation procedures for all 7 credential types
- **Policy Governance**: 100% of Kyverno policies have detailed inline documentation
- **Knowledge Transfer**: Engineers have quick reference for all security operations
- **Compliance Ready**: Documentation supports CIS Kubernetes, NIST, and OWASP compliance
- **Documentation Growth**: +2,035 lines of security documentation added

#### User Journey
1. Security team reads SECURITY-BestPractices.md for baseline security posture
2. Operations team follows SECURITY-Credential-Rotation.md for quarterly rotations
3. Developers reference KYVERNO-Policy-CheatSheet.md when fixing policy violations
4. All teams read policy file headers for in-context explanations

#### Stats
- 3 new security documentation files created
- ~2,035 lines of security documentation added
- 8 Kyverno policy files enhanced with 438+ lines of explanations
- 10 security domains covered
- 7 credential types with rotation procedures
- 8 policies with complete documentation
- 100% policy coverage with inline explanations

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
| **Unreleased** | feature--Updated-versions | 2026-03-10 | Phase 1-4 complete; Documentation, Ports, Quick Start, Security |
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
**Last Updated**: 2026-03-10 (Phase 4 Security Enhancements Complete)
**Status**: Active Development (Phase 5 - Testing Improvements scheduled next)
