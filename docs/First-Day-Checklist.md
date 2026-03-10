# First Day Checklist

Complete these tasks to validate and explore your new DevOps lab environment.

## Pre-Setup Checklist (Before Running Setup)

- [ ] Docker Desktop installed and running
- [ ] At least 50GB free disk space available
- [ ] At least 16GB RAM available (verify with `docker system info`)
- [ ] Git configured with username and email
- [ ] GitHub account accessible
- [ ] Terminal open in project directory
- [ ] Read QUICK-START.md

## Setup Verification (After Running ./scripts/setup-all.sh)

### Environment Setup
- [ ] `./scripts/verify-environment.sh` passed all checks
- [ ] `.env` file created from `.env.template`
- [ ] Environment variables configured with valid credentials

### Kind Cluster
- [ ] `kubectl get nodes` shows 1 control-plane + 2 worker nodes
- [ ] All nodes status is "Ready"
- [ ] `kubectl get namespaces` includes "app-demo" namespace

### Services Started
- [ ] `./k8s/k8s-permissions_port-forward.sh status` shows all forwarding active
- [ ] Harbor registry running: `curl http://localhost:8082/api/v2.0/health`
- [ ] Jenkins available: `curl http://localhost:8080/login`
- [ ] SonarQube available: `curl http://localhost:9000/api/system/status`
- [ ] Grafana available: `curl http://localhost:3000/api/health`
- [ ] ArgoCD available: `curl -k https://localhost:8090/healthz`
- [ ] PostgreSQL pod running: `kubectl get pods -n app-demo | grep postgres`

### Test Deployment
- [ ] `./scripts/test-deployment.sh` passed 20/20 tests
- [ ] No critical failures in test output

## Service Configuration Checklist

### Jenkins Configuration (http://localhost:8080)
- [ ] Logged in with admin user
- [ ] Installed suggested plugins
- [ ] Created admin user account
- [ ] GitHub plugin configured
- [ ] Maven integration verified
- [ ] Docker integration verified
- [ ] Credentials stored for:
  - [ ] GitHub repository access
  - [ ] Harbor registry push
  - [ ] SonarQube analysis

### Harbor Configuration (http://localhost:8082)
- [ ] Logged in: admin / Harbor12345
- [ ] Created project named "cicd-demo"
- [ ] Robot account created: `./scripts/create-harbor-robot.sh`
- [ ] Robot credentials saved and updated in .env
- [ ] Docker login successful: `docker login localhost:8082`

### Docker Configuration
- [ ] Added Harbor to insecure registries in Docker daemon.json:
```json
{
  "insecure-registries": ["localhost:8082"]
}
```
- [ ] Docker Desktop restarted after daemon.json change
- [ ] Harbor connectivity verified: `docker pull localhost:8082/cicd-demo/hello:latest`

### SonarQube Configuration (http://localhost:9000)
- [ ] Logged in: admin / admin
- [ ] Changed admin password
- [ ] Generated authentication token
- [ ] Token saved in .env as SONAR_TOKEN
- [ ] Project "cicd-demo" created (or will be created by pipeline)

### Grafana Configuration (http://localhost:3000)
- [ ] Logged in: admin / admin
- [ ] Changed admin password
- [ ] Datasources configured:
  - [ ] Prometheus (http://prometheus:9090)
  - [ ] Loki (http://loki:3100)
- [ ] At least one dashboard visible
- [ ] Can query metrics in Prometheus

### ArgoCD Configuration (https://localhost:8090)
- [ ] Logged in: admin / (password from setup output)
- [ ] GitHub repository configured for sync
- [ ] cicd-demo application synced and healthy
- [ ] Auto-sync enabled (optional but recommended)

## Application Deployment Checklist

### PostgreSQL Database
- [ ] Pod running: `kubectl get pod postgres-0 -n app-demo`
- [ ] PersistentVolumeClaim created: `kubectl get pvc -n app-demo`
- [ ] Database accessible:
```bash
kubectl exec -it postgres-0 -n app-demo -- psql -U postgres -d cicd_demo -c "SELECT * FROM tasks LIMIT 1;"
```
- [ ] Schema initialized (Flyway migrations applied)
- [ ] Sample data present

### Spring Boot Backend
- [ ] Pod running: `kubectl get pods -n app-demo | grep spring-boot`
- [ ] Health endpoint responds: `curl http://localhost:8001/actuator/health`
- [ ] API endpoints available:
  - [ ] GET http://localhost:8001/api/tasks
  - [ ] GET http://localhost:8001/actuator/prometheus

### React Frontend
- [ ] Pod running: `kubectl get pods -n app-demo | grep frontend` (or nginx)
- [ ] UI accessible: http://localhost:8001
- [ ] Can interact with UI:
  - [ ] View existing tasks
  - [ ] Create new task
  - [ ] Update task
  - [ ] Delete task
  - [ ] See changes reflected

## Monitoring & Logging Checklist

### Prometheus (http://localhost:30090)
- [ ] Prometheus UI accessible
- [ ] Targets page shows "app-demo" job UP
- [ ] Can query metrics:
  - [ ] jvm_memory_used_bytes
  - [ ] http_requests_total
  - [ ] kubernetes_build_info

### Loki (http://localhost:31000)
- [ ] Loki API responds: `curl http://localhost:31000/ready`
- [ ] Can query logs in Grafana
- [ ] Application logs visible

### Grafana (http://localhost:3000)
- [ ] Explore shows Prometheus and Loki datasources
- [ ] Can create graph from Prometheus metrics
- [ ] Can query logs from Loki
- [ ] Dashboard shows application metrics

## Policy & Compliance Checklist

### Kyverno Policies
- [ ] Policies applied: `kubectl get clusterpolicies`
- [ ] Expected policies found (at least 5):
  - [ ] disallow-privileged-containers
  - [ ] require-non-root-user
  - [ ] require-read-only-filesystem
  - [ ] require-resources
  - [ ] require-image-registry

- [ ] Policies in Audit mode (violations logged, not blocked)
- [ ] No errors in policy deployment

### Policy Reporter (http://localhost:31002)
- [ ] Policy Reporter UI accessible
- [ ] Shows policy violations dashboard
- [ ] Can see violation details
- [ ] API accessible: http://localhost:31001/api/v1/policyreports

## Learning Objectives Completed

### Understanding
- [ ] Can explain what CI/CD pipeline does
- [ ] Can identify all 14+ DevOps tools in the stack
- [ ] Can describe three-tier architecture (DB, Backend, Frontend)
- [ ] Can explain what Kubernetes does
- [ ] Can explain what ArgoCD does
- [ ] Can describe how Kyverno policies work

### Practical Skills
- [ ] Can use kubectl basic commands
- [ ] Can view logs with `kubectl logs`
- [ ] Can port-forward services
- [ ] Can commit and push code to GitHub
- [ ] Can trigger Jenkins pipeline
- [ ] Can check SonarQube quality gates
- [ ] Can view metrics in Grafana
- [ ] Can query logs in Loki

### Configuration
- [ ] Can edit .env file
- [ ] Can modify port-forward script
- [ ] Can update Helm values
- [ ] Can modify Kubernetes manifests
- [ ] Can write SQL queries

## Troubleshooting Verification

If any checklist item failed:

1. **Check logs**: `kubectl logs <pod-name> -n app-demo`
2. **Describe pod**: `kubectl describe pod <pod-name> -n app-demo`
3. **Review guide**: See [Troubleshooting.md](Troubleshooting.md)
4. **Check ports**: `./k8s/k8s-permissions_port-forward.sh status`
5. **Verify network**: `kubectl get svc -n app-demo`

Common issues and solutions in [Troubleshooting.md](Troubleshooting.md)

## Quick Commands Reference

```bash
# Verify everything
./scripts/test-deployment.sh

# Check service status
./k8s/k8s-permissions_port-forward.sh status

# View all resources
kubectl get all -n app-demo

# View logs
kubectl logs -f <pod-name> -n app-demo

# Port forward specific service
kubectl port-forward <service> 8080:8080 -n app-demo

# Get cluster info
kubectl cluster-info
kubectl get nodes
```

## Next Steps After First Day

1. **Run Your First Pipeline**
   - Create Jenkins job from Jenkinsfile
   - Configure GitHub webhook
   - Make code change and trigger pipeline

2. **Explore Code Quality**
   - Review SonarQube issues
   - Fix critical bugs
   - Re-run analysis

3. **Study Architecture**
   - Review Jenkinsfile (11 stages)
   - Study Helm charts
   - Examine Kubernetes manifests

4. **Learn Security**
   - Review Kyverno policies
   - Understand policy violations
   - Check compliance status

5. **Hands-On Labs**
   - Follow docs/StudyPlan.md
   - Complete each tool's learning objectives
   - Build your own modifications

## Documentation to Review

- [ ] [QUICK-START.md](QUICK-START.md) - First steps overview
- [ ] [Lab-Setup-Guide.md](Lab-Setup-Guide.md) - Detailed setup steps
- [ ] [Architecture-Diagram.md](Architecture-Diagram.md) - Pipeline visualization
- [ ] [Port-Reference.md](Port-Reference.md) - All service ports
- [ ] [StudyPlan.md](StudyPlan.md) - Learning curriculum
- [ ] [Troubleshooting.md](Troubleshooting.md) - Common issues
- [ ] [CHEAT-SHEET-Commands.md](CHEAT-SHEET-Commands.md) - Common commands

## Success Criteria

You've completed First Day successfully when:

✅ All services accessible and responding
✅ Application deployed and functioning
✅ Database populated with sample data
✅ Can view logs in Grafana
✅ Can see metrics in Prometheus
✅ Policies applied without critical errors
✅ Understand basic pipeline workflow
✅ Can use kubectl to inspect resources

---

**Congratulations! You're ready to start learning DevOps!**

Next: Review [StudyPlan.md](StudyPlan.md) for structured learning path.
