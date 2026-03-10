# Quick Start Guide - First 5 Minutes

Get the DevOps CI/CD Learning Laboratory up and running in under 5 minutes.

## Prerequisites Checklist

Before starting, verify you have:

- [ ] 16GB RAM minimum (32GB recommended)
- [ ] 50GB free disk space
- [ ] Docker Desktop installed and running
- [ ] Git installed
- [ ] Terminal access (macOS, Linux, or WSL2 on Windows)
- [ ] Administrator privileges (for Docker)

## What to Expect

After completing this guide, you will have:

1. A local Kind Kubernetes cluster with 1 control plane + 2 worker nodes
2. All DevOps tools running (Jenkins, Harbor, SonarQube, Grafana, Prometheus, Loki, ArgoCD)
3. Port forwarding configured for service access
4. Full-stack application deployed (PostgreSQL + Spring Boot + React)
5. Monitoring and logging active
6. Policy enforcement enabled with Kyverno

**Estimated time: 10-15 minutes for automated setup**

## Quick Start Steps

### Step 1: Environment Verification (1 min)

```bash
cd /path/to/ci-cd-laboratory
./scripts/verify-environment.sh
```

This checks Docker, disk space, and system requirements. Fix any issues before proceeding.

### Step 2: Configure Credentials (2 min)

```bash
cp .env.template .env
nano .env  # Edit with your credentials
```

**Required credentials:**
- GitHub: username, personal access token (for repository access)
- Harbor: robot account credentials (generated after setup)
- Jenkins: admin password (you choose)
- SonarQube: authentication token (generated after setup)
- ArgoCD: admin password (you choose)

**Tip:** Start with empty credentials, generate them during setup, then update .env.

### Step 3: Run Automated Setup (10-15 min)

```bash
./scripts/setup-all.sh
```

This script:
1. Creates Kind cluster
2. Starts Harbor registry
3. Starts Jenkins
4. Configures SonarQube
5. Deploys Grafana + Loki + Prometheus
6. Sets up ArgoCD
7. Creates database schema
8. Deploys full-stack application

### Step 4: Start Port Forwarding (1 min)

```bash
./k8s/k8s-permissions_port-forward.sh start
```

Verify port forwarding:
```bash
./k8s/k8s-permissions_port-forward.sh status
```

### Step 5: Verify Deployment (2 min)

```bash
./scripts/test-deployment.sh
```

Runs 20 comprehensive tests to validate:
- Cluster connectivity
- Service availability
- Application health
- Database functionality
- Monitoring setup

## Access Services

Open these URLs in your browser:

| Service | URL | Default Login |
|---------|-----|----------------|
| Application | http://localhost:8001 | N/A |
| Jenkins | http://localhost:8080 | See Step 6 |
| Harbor | http://localhost:8082 | admin / Harbor12345 |
| SonarQube | http://localhost:9000 | admin / admin |
| Grafana | http://localhost:3000 | admin / admin |
| Prometheus | http://localhost:30090 | N/A |
| Loki | http://localhost:31000 | N/A |
| ArgoCD | https://localhost:8090 | admin / (see setup output) |
| Policy Reporter | http://localhost:31002 | N/A |

## First Day Tasks

1. **Configure Jenkins**
   - Access http://localhost:8080
   - Get initial admin password: `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`
   - Install suggested plugins
   - Create admin user

2. **Configure Harbor**
   - Access http://localhost:8082
   - Login: admin / Harbor12345
   - Create project: cicd-demo
   - Run robot account script: `./scripts/create-harbor-robot.sh`
   - Update .env with robot credentials

3. **Configure Docker Registry**
   - Add Harbor to Docker daemon.json:
   ```json
   {
     "insecure-registries": ["localhost:8082"]
   }
   ```
   - Restart Docker Desktop

4. **Access Frontend**
   - Application UI: http://localhost:8001
   - Try creating and updating tasks through the interface

5. **Monitor Activity**
   - Check Grafana dashboards: http://localhost:3000
   - Review logs in Loki
   - View metrics in Prometheus

6. **View Policies**
   - Policy Reporter UI: http://localhost:31002
   - See Kyverno policy violations in real-time

## Common Issues & Solutions

### Docker Desktop not responding
```bash
# Restart Docker
docker system prune -a  # Clean up resources
# Restart Docker Desktop from taskbar
```

### Port already in use
```bash
# Find process using port (example: 8080)
lsof -i :8080
# Kill process if needed
kill -9 <PID>
```

### Kind cluster not found
```bash
# Recreate cluster
kind delete cluster --name app-demo
./scripts/setup-all.sh
```

### Database connection failed
```bash
# Verify PostgreSQL is running
kubectl get pods -n app-demo | grep postgres

# Check database logs
kubectl logs -n app-demo -l app=postgres
```

### Port forwarding not working
```bash
# Restart port forwarding
./k8s/k8s-permissions_port-forward.sh restart

# Check status
./k8s/k8s-permissions_port-forward.sh status
```

## Next Steps

After successful setup:

1. **Learn the Pipeline**: Review Jenkinsfile to understand the 11-stage pipeline
2. **Explore Kyverno**: Check k8s/kyverno/README.md for policy details
3. **Study Architecture**: Review docs/Architecture-Diagram.md
4. **Hands-On Labs**: Follow docs/StudyPlan.md for structured learning
5. **Troubleshooting**: Check docs/Troubleshooting.md for detailed solutions

## Quick Commands Reference

```bash
# View cluster
kubectl get nodes

# View all services
kubectl get svc -A

# View application logs
kubectl logs -n app-demo -l app=spring-boot

# View database
kubectl exec -it postgres-0 -n app-demo -- psql -U postgres

# Restart port forwarding
./k8s/k8s-permissions_port-forward.sh restart

# Cleanup everything
./scripts/cleanup-all.sh
```

## Getting Help

1. **Documentation**: See [docs/README.md](../README.md) for comprehensive guides
2. **Troubleshooting**: Check [docs/Troubleshooting.md](Troubleshooting.md)
3. **Port Reference**: Review [docs/Port-Reference.md](Port-Reference.md)
4. **Tool-Specific**: Check tool guide in docs/ directory

---

**Ready to start?** Run `./scripts/setup-all.sh` and watch the magic happen!

For detailed information, see [Lab Setup Guide](Lab-Setup-Guide.md) or [Architecture Diagram](Architecture-Diagram.md).
