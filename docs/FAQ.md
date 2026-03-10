# Frequently Asked Questions (FAQ)

Common questions and answers for the DevOps CI/CD Learning Laboratory.

## Table of Contents

- [General Questions](#general-questions)
- [Setup and Installation](#setup-and-installation)
- [Tools and Components](#tools-and-components)
- [Deployment and Operations](#deployment-and-operations)
- [Testing and Validation](#testing-and-validation)
- [Security and Best Practices](#security-and-best-practices)
- [Performance and Scaling](#performance-and-scaling)
- [Troubleshooting](#troubleshooting)
- [Learning and Development](#learning-and-development)

---

## General Questions

### What is the DevOps CI/CD Learning Laboratory?

The DevOps CI/CD Learning Laboratory is a comprehensive, hands-on environment for learning industry-standard DevOps tools and practices. It includes a full-stack application (PostgreSQL + Spring Boot + React) that flows through a complete CI/CD pipeline with 14+ integrated DevOps tools.

**Key Features**:
- Production-grade CI/CD pipeline
- Full observability stack (Grafana, Loki, Prometheus)
- Policy enforcement with Kyverno
- Container orchestration with Kubernetes (Kind)
- Automated deployment and testing

### What tools are included?

The laboratory includes 14 industry-standard tools:

**CI/CD**: Jenkins, ArgoCD
**Containers**: Docker, Kind (Kubernetes), Harbor (registry)
**Build Tools**: Maven, Helm Charts
**Code Quality**: SonarQube
**Policy**: Kyverno
**Monitoring**: Grafana, Loki, Prometheus, Policy Reporter

### What are the system requirements?

**Minimum Requirements**:
- CPU: 4 cores
- RAM: 8GB (16GB recommended)
- Disk: 40GB free space
- OS: macOS, Linux, or Windows with WSL2
- Docker Desktop installed and running
- Internet connection for downloading images

**Recommended**:
- CPU: 8 cores
- RAM: 16GB
- Disk: 60GB SSD
- Good network connection (initial setup downloads ~10GB)

### How long does the initial setup take?

**Setup Time**:
- Environment verification: 2-3 minutes
- Full automated setup (`setup-all.sh`): 10-15 minutes
- Manual setup (step-by-step): 30-45 minutes
- First deployment and validation: 5-10 minutes

**Total**: 20-30 minutes for automated setup, 45-60 minutes for manual setup.

### Is this suitable for beginners?

Yes! The laboratory is designed for learners at all levels:

**Beginners**: Follow the [QUICK-START.md](QUICK-START.md) and [First-Day-Checklist.md](First-Day-Checklist.md) for guided setup.

**Intermediate**: Explore individual tool guides and customize configurations.

**Advanced**: Modify pipelines, add new tools, implement production patterns.

### Can I use this in production?

The laboratory is designed for **learning and development**. While it uses production-grade tools and practices, it requires additional hardening for production use:

**Production Considerations**:
- Replace Kind with managed Kubernetes (EKS, GKE, AKS)
- Implement proper secret management (Vault, AWS Secrets Manager)
- Set up proper backup and disaster recovery
- Configure high availability and auto-scaling
- Implement network security (firewalls, VPNs)
- Enable audit logging and compliance monitoring

---

## Setup and Installation

### Do I need to install all 14 tools manually?

No! The automated setup script handles everything:

```bash
# One-command setup
./scripts/setup-all.sh
```

This script:
- Verifies prerequisites
- Creates Kind cluster
- Deploys all services
- Configures integrations
- Sets up monitoring

### What if the automated setup fails?

**Troubleshooting Steps**:

1. Check the error message in the script output
2. Verify prerequisites: `./scripts/verify-environment.sh`
3. Check Docker is running: `docker ps`
4. Review logs in setup output
5. Consult [Troubleshooting.md](Troubleshooting.md)
6. Try manual setup following individual tool guides

**Common Fixes**:
```bash
# Clean up and retry
./scripts/cleanup-all.sh
./scripts/setup-all.sh

# Check specific service
docker ps | grep jenkins
kubectl get pods -n app-demo
```

### Can I install only specific tools?

Yes! Each tool has its own setup script:

```bash
# Jenkins only
./scripts/setup-jenkins.sh

# Harbor only
./scripts/setup-harbor.sh

# SonarQube only
./scripts/setup-sonarqube.sh

# ArgoCD only
./scripts/setup-argocd.sh
```

Refer to individual tool guides in `docs/` for manual configuration.

### How do I update the tools to newer versions?

**Update Process**:

1. Check `docker-compose.yml` or Helm charts for current versions
2. Update image tags to newer versions
3. Review release notes for breaking changes
4. Test in isolated environment first
5. Apply updates:

```bash
# Update Docker Compose services
docker-compose down
docker-compose pull
docker-compose up -d

# Update Kubernetes deployments
kubectl set image deployment/app app=new-image:version
```

### Can I run this on Windows?

Yes, with Windows Subsystem for Linux 2 (WSL2):

**Setup**:
1. Install WSL2
2. Install Docker Desktop for Windows (with WSL2 backend)
3. Run all commands inside WSL2 Ubuntu terminal
4. Access services via localhost (same as macOS/Linux)

**Note**: Performance may be slower than Linux/macOS. Allocate at least 8GB RAM to WSL2.

---

## Tools and Components

### What is Kind and why use it instead of Docker Compose?

**Kind** (Kubernetes in Docker) runs a real Kubernetes cluster inside Docker containers.

**Benefits**:
- Authentic Kubernetes experience
- Test Helm charts and K8s manifests
- Practice kubectl commands
- Learn pod orchestration
- Simulate production K8s environment

**When to Use Docker Compose Instead**:
- Simpler single-service testing
- Faster startup times
- Less resource usage

### Why is Jenkins used instead of GitHub Actions?

**Jenkins** is included because it's:
- Industry-standard in enterprise environments
- Highly customizable with 1500+ plugins
- Self-hosted (no cloud dependency)
- Supports complex pipeline workflows

**GitHub Actions** is excellent for cloud-native workflows. You can integrate it later by:
1. Creating `.github/workflows/` directory
2. Defining YAML workflows
3. Using same build/test commands

### What is Harbor and do I need it?

**Harbor** is an enterprise container registry with:
- Vulnerability scanning
- Image signing
- Replication
- Access control

**Do You Need It?**
- **Yes** for learning enterprise practices
- **Yes** if practicing private registries
- **Optional** if only using Docker Hub

**Alternative**: Use Docker Hub or GitHub Container Registry for simpler setups.

### How does ArgoCD differ from Jenkins?

**Jenkins**: Continuous Integration (CI)
- Builds code
- Runs tests
- Creates artifacts
- Pushes images

**ArgoCD**: Continuous Deployment (CD)
- Monitors Git repos
- Syncs Kubernetes state
- Implements GitOps
- Auto-deploys changes

**Together**: Complete CI/CD pipeline (Jenkins builds, ArgoCD deploys)

### What is Kyverno and why enforce policies?

**Kyverno** is a Kubernetes-native policy engine that:
- Validates resource configurations
- Mutates resources (adds labels, defaults)
- Generates resources automatically
- Reports violations

**Use Cases**:
- Enforce security standards (no root containers)
- Require resource limits
- Validate image sources (Harbor-only)
- Add mandatory labels
- Ensure compliance (PCI, HIPAA, SOC2)

**Current Mode**: Audit (logs violations but doesn't block)

---

## Deployment and Operations

### How do I deploy the full-stack application?

**Quick Deployment**:
```bash
# Deploy all three tiers (PostgreSQL, Backend, Frontend)
./scripts/deploy-fullstack.sh

# Verify deployment
./scripts/test-deployment.sh
```

**Manual Deployment**:
```bash
# 1. Deploy database
kubectl apply -f k8s/postgres/

# 2. Build and deploy backend
mvn clean package -DskipTests
docker build -t app:latest .
kind load docker-image app:latest --name app-demo

# 3. Deploy with Helm
helm upgrade --install cicd-demo ./helm-charts/cicd-demo -n app-demo
```

### How do I access the deployed services?

**Service URLs**:
```
Application:     http://localhost:8001
Frontend:        http://localhost:30080
Jenkins:         http://localhost:8080
Harbor:          http://localhost:8082
SonarQube:       http://localhost:9000
ArgoCD:          https://localhost:8090
Grafana:         http://localhost:3000
Prometheus:      http://localhost:30090
Policy Reporter: http://localhost:31002
```

**Port Forwarding**:
```bash
# Start all port forwards
./k8s/k8s-permissions_port-forward.sh start

# Check status
./k8s/k8s-permissions_port-forward.sh status

# Stop all
./k8s/k8s-permissions_port-forward.sh stop
```

### How do I check if everything is running correctly?

**Quick Health Check**:
```bash
# 1. Check cluster
kubectl get nodes
kubectl get pods -n app-demo

# 2. Run automated tests
./scripts/test-deployment.sh       # 26 deployment tests
./scripts/test-integration.sh      # 40+ integration tests

# 3. Check services manually
curl http://localhost:8001/actuator/health
curl http://localhost:30080
```

**Expected Results**:
- All nodes: Ready
- All pods: Running (1/1)
- Health endpoints: HTTP 200
- Tests: 100% pass rate

### How do I view logs?

**Application Logs**:
```bash
# Pod logs
kubectl logs -n app-demo <pod-name>
kubectl logs -n app-demo postgres-0
kubectl logs -n app-demo deployment/cicd-demo-backend

# Follow logs (tail -f)
kubectl logs -n app-demo -f postgres-0

# Previous container logs
kubectl logs -n app-demo postgres-0 --previous

# All pods with label
kubectl logs -n app-demo -l app=cicd-demo-backend
```

**Centralized Logs**:
- Grafana Loki: http://localhost:3000 (Explore → Loki)
- View logs by pod, namespace, or label

### How do I restart a service?

**Kubernetes Services**:
```bash
# Restart deployment (rolling restart)
kubectl rollout restart deployment/cicd-demo-backend -n app-demo

# Restart StatefulSet (PostgreSQL)
kubectl rollout restart statefulset/postgres -n app-demo

# Delete pod (auto-recreated)
kubectl delete pod postgres-0 -n app-demo

# Check rollout status
kubectl rollout status deployment/cicd-demo-backend -n app-demo
```

**Docker Compose Services**:
```bash
# Restart specific service
docker-compose restart jenkins
docker-compose restart sonarqube

# Restart all
docker-compose down && docker-compose up -d
```

---

## Testing and Validation

### What testing tools are available?

**4 Comprehensive Test Scripts**:

1. **Deployment Tests** (`test-deployment.sh`)
   - 26 tests validating PostgreSQL deployment
   - Security, connectivity, functionality checks

2. **Integration Tests** (`test-integration.sh`)
   - 40+ end-to-end tests
   - Full-stack validation (database → backend → frontend)

3. **Performance Tests** (`test-performance.sh`)
   - Response time benchmarks
   - Load testing with Apache Bench
   - Resource usage monitoring

4. **Database Tests** (`test-db-pool.sh`)
   - Connection pool validation
   - Throughput measurement (queries/sec, TPS)
   - Leak detection

### How do I know if my deployment is successful?

**Success Criteria**:

1. **All Tests Pass**:
   ```bash
   ./scripts/test-deployment.sh    # Should see: ✅ ALL TESTS PASSED!
   ./scripts/test-integration.sh   # >95% pass rate
   ```

2. **All Pods Running**:
   ```bash
   kubectl get pods -n app-demo
   # All pods should show: Running (1/1)
   ```

3. **Services Accessible**:
   ```bash
   curl http://localhost:8001/actuator/health
   # Should return: {"status":"UP"}
   ```

4. **No Policy Violations** (or only expected ones):
   - Visit http://localhost:31002 (Policy Reporter)
   - Check for critical violations

### How often should I run tests?

**Recommended Testing Schedule**:

**During Development**:
- Before committing: `./scripts/test-deployment.sh`
- After changes: Relevant test suite

**Daily/Continuous**:
- Integration tests: Once daily
- Performance tests: Weekly

**Before Deployment**:
- All test suites: Full validation

**Automated**:
- Add to Jenkins pipeline for continuous testing

---

## Security and Best Practices

### Is the default setup secure?

**Current Security**:
- ✅ Non-root containers
- ✅ Resource limits enforced
- ✅ Kyverno policies active (Audit mode)
- ✅ RBAC configured
- ⚠️ Default passwords (change for production)
- ⚠️ HTTP connections (enable TLS for production)
- ⚠️ Secrets in environment variables (use secret management)

**For Production**: See [SECURITY-BestPractices.md](SECURITY-BestPractices.md)

### How do I change default passwords?

**Key Services**:

```bash
# Jenkins
# UI → Manage Jenkins → Security → Configure Global Security

# Harbor
# UI → Admin → Users → Change Password

# ArgoCD
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {"admin.password": "new-bcrypt-hash"}}'

# PostgreSQL
# Update secret, restart pod

# SonarQube
# UI → Administration → Security → Users
```

See [SECURITY-Credential-Rotation.md](SECURITY-Credential-Rotation.md) for complete procedures.

### How do I rotate credentials?

Follow the credential rotation guide:

**Recommended Rotation Schedule**:
- Tokens/Passwords: Every 60-90 days
- Robot accounts: Every 90-180 days
- TLS certificates: Every 365 days
- API keys: Every 90 days

**Procedure**: [SECURITY-Credential-Rotation.md](SECURITY-Credential-Rotation.md)

### What are Kyverno policies enforcing?

**Active Policies** (Audit mode):

1. **Harbor-Only Images**: Only Harbor registry allowed
2. **Require Non-Root**: Containers must run as non-root
3. **Resource Limits**: CPU and memory limits required
4. **Disallow Privileged**: No privileged containers
5. **Read-Only RootFS**: Immutable root filesystem
6. **Namespace Labels**: Required namespace labels
7. **Default Labels**: Auto-add standard labels

**View Violations**:
- Policy Reporter UI: http://localhost:31002
- Command line: `kubectl get policyreport -A`

See [KYVERNO-Policy-CheatSheet.md](KYVERNO-Policy-CheatSheet.md)

---

## Performance and Scaling

### What is the expected performance?

**Performance Baselines**:

| Metric | Target | Threshold |
|--------|--------|-----------|
| Health Endpoint | <100ms | <1.0s |
| API Response | <500ms | <2.0s |
| Throughput | >100 req/s | >50 req/s |
| Database Query | <50ms | <200ms |

**Measure Performance**:
```bash
./scripts/test-performance.sh
# Review report: test-results/performance/benchmark_*.txt
```

### How do I scale the application?

**Horizontal Scaling** (more replicas):
```bash
# Scale backend
kubectl scale deployment cicd-demo-backend -n app-demo --replicas=3

# Scale frontend
kubectl scale deployment cicd-demo-frontend -n app-demo --replicas=2

# Verify
kubectl get pods -n app-demo
```

**Vertical Scaling** (more resources):
```yaml
# Edit deployment
kubectl edit deployment cicd-demo-backend -n app-demo

# Update resources
resources:
  limits:
    cpu: "1000m"      # Was 500m
    memory: "1024Mi"  # Was 512Mi
  requests:
    cpu: "500m"
    memory: "512Mi"
```

### How many concurrent users can it handle?

**Default Configuration**:
- ~50-100 concurrent users
- ~100-200 requests/second
- Limited by resource constraints

**To Support More**:
1. Scale horizontally (more replicas)
2. Increase resource limits
3. Optimize database connection pool
4. Add caching (Redis)
5. Use load balancer

**Load Testing**:
```bash
# Test with Apache Bench
ab -n 1000 -c 50 http://localhost:8001/actuator/health

# Test with hey
hey -n 1000 -c 50 http://localhost:8001/api/users
```

### Can I add more Kubernetes nodes?

Yes! Modify `kind-config.yaml`:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker  # Add more worker nodes
```

Then recreate cluster:
```bash
kind delete cluster --name app-demo
kind create cluster --config kind-config.yaml
```

---

## Troubleshooting

### Where do I find troubleshooting information?

**Documentation**:
1. [Troubleshooting.md](Troubleshooting.md) - Detailed problem-solution guide
2. [TESTING-Guide.md](TESTING-Guide.md) - Test failure analysis
3. This FAQ - Common questions

**Tool-Specific Guides**:
- [Jenkins.md](Jenkins.md)
- [Harbor.md](Harbor.md)
- [Kind-K8s.md](Kind-K8s.md)
- Individual tool documentation

### Pods are stuck in Pending state

**Causes**:
1. Insufficient cluster resources
2. PVC not bound
3. Image pull errors
4. Node selector mismatch

**Diagnosis**:
```bash
kubectl describe pod <pod-name> -n app-demo
kubectl get events -n app-demo --sort-by='.lastTimestamp'
```

**Solutions**: See [Troubleshooting.md](Troubleshooting.md#pods-stuck-in-pending)

### Services are not accessible

**Check List**:
```bash
# 1. Port forwarding running?
./k8s/k8s-permissions_port-forward.sh status

# 2. Pods running?
kubectl get pods -n app-demo

# 3. Services exist?
kubectl get svc -n app-demo

# 4. Firewall blocking?
curl -v http://localhost:8001/actuator/health
```

**Fix**:
```bash
# Restart port forwarding
./k8s/k8s-permissions_port-forward.sh restart

# Check pod logs
kubectl logs -n app-demo <pod-name>
```

### Database connection failed

**Common Causes**:
1. PostgreSQL pod not running
2. Incorrect credentials
3. Network connectivity issues
4. Connection pool exhausted

**Diagnosis**:
```bash
# Check PostgreSQL
kubectl get pod postgres-0 -n app-demo
kubectl logs postgres-0 -n app-demo

# Test connectivity
kubectl exec -n app-demo postgres-0 -- pg_isready -U app_user

# Check connections
./scripts/test-db-pool.sh
```

**Fix**: See [Troubleshooting.md](Troubleshooting.md#database-connection-issues)

### How do I clean up and start fresh?

**Complete Cleanup**:
```bash
# Nuclear option - removes everything
./scripts/cleanup-all.sh

# Then rebuild
./scripts/setup-all.sh
```

**Partial Cleanup**:
```bash
# Delete Kind cluster only
kind delete cluster --name app-demo

# Remove Docker Compose services only
docker-compose down -v

# Clean Docker resources
docker system prune -a --volumes
```

---

## Learning and Development

### What is the recommended learning path?

**Beginner Path** (2-4 weeks):
1. Complete [QUICK-START.md](QUICK-START.md) - Get everything running
2. Follow [First-Day-Checklist.md](First-Day-Checklist.md) - Validate setup
3. Read [Architecture-Diagram.md](Architecture-Diagram.md) - Understand components
4. Explore individual tool guides (Jenkins, Harbor, etc.)
5. Modify application code and redeploy

**Intermediate Path** (4-8 weeks):
1. Customize Jenkins pipeline
2. Create custom Kyverno policies
3. Build your own Helm charts
4. Implement monitoring dashboards
5. Practice troubleshooting scenarios

**Advanced Path** (2-3 months):
1. Migrate to cloud Kubernetes (EKS/GKE/AKS)
2. Implement advanced GitOps workflows
3. Add service mesh (Istio/Linkerd)
4. Implement chaos engineering
5. Build production-grade pipelines

### Where can I find more learning resources?

**Included Documentation**:
- [StudyPlan.md](StudyPlan.md) - Comprehensive learning guide
- Tool-specific guides in `docs/`
- [CHEAT-SHEET-Commands.md](CHEAT-SHEET-Commands.md) - Quick reference

**External Resources**:
- Kubernetes documentation: https://kubernetes.io/docs/
- Jenkins documentation: https://www.jenkins.io/doc/
- ArgoCD documentation: https://argo-cd.readthedocs.io/
- Cloud Native Computing Foundation: https://www.cncf.io/

### Can I contribute or modify the project?

Yes! This is a learning laboratory:

**How to Contribute**:
1. Fork the repository
2. Create feature branch
3. Make changes and test
4. Submit pull request
5. Participate in discussions

**Customization Ideas**:
- Add new tools (Vault, Consul, etc.)
- Create additional pipelines
- Add more Kyverno policies
- Enhance monitoring dashboards
- Write additional documentation
- Share your configurations

### How do I get help?

**Support Channels**:

1. **Documentation**: Check relevant guide in `docs/`
2. **FAQ**: This document
3. **Troubleshooting**: [Troubleshooting.md](Troubleshooting.md)
4. **Issues**: GitHub Issues for bug reports
5. **Discussions**: GitHub Discussions for questions
6. **Community**: DevOps Slack channels, forums

**Before Asking**:
- Review documentation thoroughly
- Run diagnostic commands
- Check similar GitHub issues
- Include error messages and logs in questions

---

## Quick Reference

### Essential Commands

```bash
# Setup
./scripts/setup-all.sh           # Full setup
./scripts/verify-environment.sh  # Check prerequisites

# Deployment
./scripts/deploy-fullstack.sh    # Deploy application
./scripts/test-deployment.sh     # Validate deployment

# Testing
./scripts/test-integration.sh    # Integration tests
./scripts/test-performance.sh    # Performance tests
./scripts/test-db-pool.sh        # Database tests

# Port Forwarding
./k8s/k8s-permissions_port-forward.sh start|stop|status|restart

# Kubernetes
kubectl get pods -n app-demo     # List pods
kubectl logs <pod> -n app-demo   # View logs
kubectl describe pod <pod> -n app-demo  # Pod details

# Cleanup
./scripts/cleanup-all.sh         # Remove everything
```

### Quick Health Check

```bash
# 1. Check cluster
kubectl get nodes
kubectl get pods -n app-demo

# 2. Check services
curl http://localhost:8001/actuator/health
curl http://localhost:30080

# 3. Run tests
./scripts/test-deployment.sh
```

### Important URLs

```
Frontend:        http://localhost:30080
Backend API:     http://localhost:8001
Jenkins:         http://localhost:8080
Harbor:          http://localhost:8082
SonarQube:       http://localhost:9000
ArgoCD:          https://localhost:8090
Grafana:         http://localhost:3000
Prometheus:      http://localhost:30090
Policy Reporter: http://localhost:31002
```

---

## Related Documents

- [QUICK-START.md](QUICK-START.md) - 5-minute quick start
- [First-Day-Checklist.md](First-Day-Checklist.md) - Complete validation checklist
- [Troubleshooting.md](Troubleshooting.md) - Detailed troubleshooting
- [TESTING-Guide.md](TESTING-Guide.md) - Testing framework documentation
- [SECURITY-BestPractices.md](SECURITY-BestPractices.md) - Security guidelines
- [CHEAT-SHEET-Commands.md](CHEAT-SHEET-Commands.md) - Command reference
- [INDEX.md](INDEX.md) - Complete documentation index

---

**Last Updated**: 2026-03-10
**Version**: 1.0.0
**Maintained By**: DevOps Lab Team

**Have a question not answered here?** Check [Troubleshooting.md](Troubleshooting.md) or open a GitHub Discussion.
