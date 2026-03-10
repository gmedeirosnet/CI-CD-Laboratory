# Troubleshooting Guide

## Overview
This guide provides solutions to common issues encountered while setting up and running the DevOps CI/CD learning laboratory.

## Table of Contents
- [Docker Issues](#docker-issues)
- [Jenkins Problems](#jenkins-problems)
- [Harbor Registry Issues](#harbor-registry-issues)
- [Kind Kubernetes Issues](#kind-kubernetes-issues)
- [Maven Build Problems](#maven-build-problems)
- [SonarQube Issues](#sonarqube-issues)
- [ArgoCD Problems](#argocd-problems)
- [Helm Chart Issues](#helm-chart-issues)
- [Ansible Problems](#ansible-problems)
- [Network and Connectivity](#network-and-connectivity)

---

## Docker Issues

### Docker Desktop Not Starting (macOS)

**Symptom**: Docker Desktop fails to start or shows "Starting..." indefinitely

**Solutions**:
```bash
# 1. Restart Docker Desktop
killall Docker && open /Applications/Docker.app

# 2. Clear Docker data (WARNING: removes all containers/images)
rm -rf ~/Library/Containers/com.docker.docker
rm -rf ~/Library/Group\ Containers/group.com.docker

# 3. Check system resources
# Ensure at least 4GB RAM and 20GB disk space available

# 4. Check macOS version compatibility
sw_vers
```

### Docker Daemon Not Accessible

**Symptom**: `Cannot connect to the Docker daemon`

**Solutions**:
```bash
# Check Docker status
docker info

# Verify Docker is running
ps aux | grep -i docker

# Restart Docker service (Linux)
sudo systemctl restart docker

# Check permissions (Linux)
sudo usermod -aG docker $USER
newgrp docker
```

### Port Already in Use

**Symptom**: `Bind for 0.0.0.0:8080 failed: port is already allocated`

**Solutions**:
```bash
# Find process using the port
lsof -i :8080

# Kill the process
kill -9 <PID>

# Or modify docker-compose.yml to use different port
ports:
  - "8081:8080"  # Change external port
```

### Insufficient Disk Space

**Symptom**: `no space left on device`

**Solutions**:
```bash
# Check disk usage
df -h

# Remove unused Docker resources
docker system prune -a --volumes

# Remove specific items
docker container prune
docker image prune -a
docker volume prune
docker network prune

# Check Docker disk usage
docker system df
```

---

## Jenkins Problems

### Cannot Access Jenkins UI

**Symptom**: `This site can't be reached` at http://localhost:8080

**Solutions**:
```bash
# 1. Verify Jenkins container is running
docker ps | grep jenkins

# 2. Check Jenkins logs
docker logs jenkins

# 3. Check port mapping
docker port jenkins

# 4. Restart Jenkins container
docker restart jenkins

# 5. Verify no firewall blocking
curl http://localhost:8080
```

### Jenkins Initial Password Not Found

**Symptom**: Cannot find initial admin password

**Solutions**:
```bash
# Method 1: Check container logs
docker logs jenkins | grep -A 5 "password"

# Method 2: Execute command in container
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Method 3: Check Jenkins volume
docker volume inspect jenkins_home
# Then access the mount point
```

### Pipeline Fails with Maven Not Found

**Symptom**: `mvn: command not found` in Jenkins pipeline

**Solutions**:
```bash
# 1. Install Maven in Jenkins container
docker exec -it jenkins bash
apt-get update && apt-get install -y maven

# 2. Or use Maven Docker image in Jenkinsfile
agent {
    docker {
        image 'maven:3.9-eclipse-temurin-21'
    }
}

# 3. Configure Maven tool in Jenkins
# Jenkins > Manage Jenkins > Tools > Maven installations
```

### Docker Permission Denied in Jenkins

**Symptom**: `permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock`

**Root Cause**: Jenkins user inside the container doesn't have permission to access the Docker socket mounted from the host.

**Solutions**:

**Quick Fix (Immediate)**:
```bash
# Fix Docker socket permissions (works immediately but temporary)
docker exec -u root jenkins chmod 666 /var/run/docker.sock

# Verify Docker access
docker exec jenkins docker ps
docker exec jenkins docker --version
```

**Permanent Fix (Recommended)**:
```bash
# Method 1: Re-run the Jenkins setup script (includes permission fix)
./scripts/setup-jenkins-docker.sh

# Method 2: Restart Jenkins with updated entrypoint (automatic permission fix)
docker stop jenkins
docker rm jenkins

docker run -d \
  --name jenkins \
  --restart unless-stopped \
  --network cicd-network \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --entrypoint /bin/bash \
  jenkins/jenkins:lts \
  -c "chmod 666 /var/run/docker.sock 2>/dev/null || true; exec /usr/bin/tini -- /usr/local/bin/jenkins.sh"

# Method 3: Add Jenkins user to Docker group (Linux only, not for macOS Docker Desktop)
docker exec -u root jenkins bash -c "groupadd -g $(stat -c '%g' /var/run/docker.sock) docker && usermod -aG docker jenkins"
docker restart jenkins
```

**Verification**:
```bash
# Test Docker commands from Jenkins user
docker exec jenkins docker ps
docker exec jenkins docker images
docker exec jenkins docker info

# Test in Jenkins pipeline
pipeline {
    agent any
    stages {
        stage('Test Docker') {
            steps {
                sh 'docker --version'
                sh 'docker ps'
            }
        }
    }
}
```

**Note**: On macOS and Windows with Docker Desktop, the `chmod 666` approach is the recommended solution. The socket permissions may reset on Docker daemon restart, so the setup script includes an automatic fix on container startup.

### GitHub Webhook Not Triggering

**Symptom**: Push to GitHub doesn't trigger Jenkins build

**Solutions**:
1. **Check webhook configuration**:
   - GitHub > Repository > Settings > Webhooks
   - Payload URL: `http://YOUR_JENKINS_URL/github-webhook/`
   - Content type: `application/json`
   - Events: Push events

2. **Verify Jenkins GitHub plugin**:
   - Jenkins > Manage Plugins > Installed
   - Search for "GitHub Integration Plugin"

3. **Check Jenkins job configuration**:
   ```groovy
   triggers {
       githubPush()
   }
   ```

4. **Use ngrok for local testing**:
   ```bash
   ngrok http 8080
   # Use ngrok URL in GitHub webhook
   ```

---

## Harbor Registry Issues

### Cannot Access Harbor UI

**Symptom**: `ERR_CONNECTION_REFUSED` at http://localhost:8082

**Solutions**:
```bash
# 1. Check Harbor containers
docker-compose -f harbor/docker-compose.yml ps

# 2. Check Harbor logs
docker-compose -f harbor/docker-compose.yml logs

# 3. Restart Harbor
cd harbor
docker-compose down
docker-compose up -d

# 4. Verify port binding
netstat -an | grep 8082
```

### Docker Push to Harbor Fails

**Symptom**: `http: server gave HTTP response to HTTPS client`

**Solutions**:
```bash
# Add Harbor to Docker insecure registries
# Edit Docker Desktop settings or daemon.json

# macOS: Docker Desktop > Preferences > Docker Engine
{
  "insecure-registries": ["localhost:8082"]
}

# Linux: /etc/docker/daemon.json
{
  "insecure-registries": ["localhost:8082"]
}

# Restart Docker
sudo systemctl restart docker  # Linux
# Or restart Docker Desktop on macOS
```

### Harbor Login Fails

**Symptom**: `Error response from daemon: login attempt failed`

**Solutions**:
```bash
# 1. Verify Harbor is running
curl http://localhost:8082

# 2. Use correct credentials
docker login localhost:8082
# Username: admin
# Password: Harbor12345 (default)

# 3. Check Harbor user exists
# Harbor UI > Administration > Users

# 4. Create robot account for CI/CD
./scripts/create-harbor-robot.sh
```

### Harbor Database Initialization Failed

**Symptom**: `database initialization failed`

**Solutions**:
```bash
# 1. Remove Harbor data and start fresh
cd harbor
docker-compose down -v
rm -rf data/database/*
docker-compose up -d

# 2. Check database logs
docker logs harbor-db

# 3. Verify PostgreSQL port not in use
lsof -i :5432
```

### Cannot Create Project in Harbor

**Symptom**: API returns 403 or project creation fails in UI

**Solutions**:
```bash
# 1. Verify you're logged in as admin or project admin
# Regular users cannot create projects unless given permission

# 2. Create project via API with proper authentication
curl -X POST "http://localhost:8082/api/v2.0/projects" \
  -H "Content-Type: application/json" \
  -u "admin:Harbor12345" \
  -d '{
    "project_name": "cicd-demo",
    "public": false
  }'

# 3. Verify project doesn't already exist
curl -X GET "http://localhost:8082/api/v2.0/projects?name=cicd-demo" \
  -u "admin:Harbor12345"

# 4. Check Harbor logs for errors
docker-compose -f harbor/docker-compose.yml logs core
```

### Robot Account Creation Fails

**Symptom**: `create-harbor-robot.sh` script fails with 403 or permission error

**Solutions**:
```bash
# 1. Ensure cicd-demo project exists first
# Check in Harbor UI: Projects tab

# 2. Verify API user has project admin permissions
# The 'jenkins' user must be a project admin or use 'admin' account

# 3. Create robot account manually via UI
# Harbor UI > Projects > cicd-demo > Robot Accounts > NEW ROBOT ACCOUNT
# Name: robot-ci-cd-demo
# Permissions: Push Artifact, Pull Artifact
# Copy the token immediately (shown only once)

# 4. If script requires jq and it's missing
brew install jq  # macOS
# Or let it use python3 fallback

# 5. Test robot account credentials
echo "ROBOT_TOKEN" | docker login localhost:8082 \
  -u "robot\$robot-ci-cd-demo" --password-stdin
```

### Robot Account Token Lost

**Symptom**: Need robot token but it wasn't saved during creation

**Solutions**:
```bash
# Robot tokens are shown only once and cannot be retrieved
# You must create a new robot account or regenerate the secret

# 1. Delete old robot account
# Harbor UI > Projects > cicd-demo > Robot Accounts
# Find the robot, click Actions > Delete

# 2. Create new robot account
./scripts/create-harbor-robot.sh
# Or create via UI and save token immediately

# 3. Update Jenkins credentials with new token
# Jenkins > Manage Jenkins > Credentials
# Update the 'harbor-robot-credentials' password
```

---

## Kind Kubernetes Issues

### Kind Cluster Creation Fails

**Symptom**: `ERROR: failed to create cluster`

**Solutions**:
```bash
# 1. Check Docker is running
docker ps

# 2. Delete existing cluster and recreate
kind delete cluster --name kind
kind create cluster --config kind-config.yaml

# 3. Check available resources
docker system df

# 4. Use simpler configuration
kind create cluster
```

### Cannot Connect to Kind Cluster

**Symptom**: `Unable to connect to the server`

**Solutions**:
```bash
# 1. Verify cluster exists
kind get clusters

# 2. Set kubeconfig context
kubectl cluster-info --context kind-kind

# 3. Export kubeconfig
kind export kubeconfig --name kind

# 4. Verify connectivity
kubectl get nodes

# 5. Check API server
docker ps | grep kind-control-plane
```

### Pods Stuck in Pending State

**Symptom**: `kubectl get pods` shows pods in Pending

**Solutions**:
```bash
# 1. Describe pod to see events
kubectl describe pod <pod-name>

# 2. Check node resources
kubectl describe nodes

# 3. Check if image can be pulled
kubectl get events --sort-by='.lastTimestamp'

# 4. Check for ImagePullBackOff
kubectl get pods
# If ImagePullBackOff, check image name and registry access
```

### Kind Node Out of Disk Space

**Symptom**: Pods failing due to disk pressure

**Solutions**:
```bash
# 1. Clean up Docker
docker system prune -a

# 2. Delete unused images in Kind nodes
docker exec kind-control-plane crictl rmi --prune

# 3. Increase Docker disk space
# Docker Desktop > Preferences > Resources > Disk

# 4. Recreate cluster with more space
kind delete cluster
kind create cluster --config kind-config.yaml
```

---

## Maven Build Problems

### Maven Dependencies Cannot Be Downloaded

**Symptom**: `Could not resolve dependencies`

**Solutions**:
```bash
# 1. Clear Maven cache
rm -rf ~/.m2/repository

# 2. Force update dependencies
mvn clean install -U

# 3. Check Maven settings
cat ~/.m2/settings.xml

# 4. Use Maven wrapper
./mvnw clean install

# 5. Check internet connectivity
ping repo.maven.apache.org
```

### Compilation Errors

**Symptom**: `compilation failed`

**Solutions**:
```bash
# 1. Verify Java version
java -version
# Should be Java 21

# 2. Set JAVA_HOME
export JAVA_HOME=/path/to/jdk-21

# 3. Clean and rebuild
mvn clean compile

# 4. Check pom.xml for version mismatches
cat pom.xml | grep version
```

### Tests Failing

**Symptom**: `Tests run: X, Failures: Y`

**Solutions**:
```bash
# 1. Run tests with more details
mvn test -X

# 2. Run specific test
mvn test -Dtest=TestClassName

# 3. Skip tests temporarily (not recommended)
mvn package -DskipTests

# 4. Check test logs
cat target/surefire-reports/*.txt
```

---

## SonarQube Issues

### SonarQube Not Starting

**Symptom**: Container exits immediately

**Solutions**:
```bash
# 1. Check logs
docker logs sonarqube

# 2. Increase max_map_count (Linux)
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf

# 3. Check memory allocation
# SonarQube needs at least 2GB RAM

# 4. Remove and recreate
docker rm sonarqube
docker run -d --name sonarqube -p 9000:9000 sonarqube:latest
```

### Quality Gate Fails

**Symptom**: SonarQube analysis shows failures

**Solutions**:
```bash
# 1. Review quality gate rules
# SonarQube UI > Quality Gates

# 2. Check specific issues
# SonarQube UI > Projects > Your Project > Issues

# 3. Run analysis locally
mvn sonar:sonar -Dsonar.host.url=http://localhost:9000

# 4. Adjust quality gate thresholds (for learning)
# SonarQube UI > Quality Gates > Copy > Modify conditions
```

### Cannot Generate Token

**Symptom**: Token generation fails

**Solutions**:
```bash
# 1. Login as admin
# Default: admin/admin

# 2. Change default password
# SonarQube will force password change on first login

# 3. Generate token
# User Menu > My Account > Security > Generate Token

# 4. Save token immediately (shown only once)
```

### Jenkins Cannot Connect to SonarQube

**Symptom**: `Failed to connect to localhost/[0:0:0:0:0:0:0:1]:9000: Connection refused`

**Root Cause**: Jenkins is trying to connect to SonarQube using `localhost`, but inside the Jenkins container, `localhost` refers to the Jenkins container itself, not the host machine or the SonarQube container.

**Solutions**:

```bash
# 1. Verify both containers are on the same Docker network
docker network inspect cicd-network | grep -E 'jenkins|sonarqube'

# Expected: You should see both containers listed

# 2. If Jenkins is NOT on the network, connect it
docker network connect cicd-network jenkins

# 3. Verify SonarQube is accessible from Jenkins
docker exec jenkins curl -I http://sonarqube:9000

# Expected: HTTP/1.1 200 or 302
```

**Fix Jenkins SonarQube Configuration**:

1. **Check Jenkins SonarQube Server URL**:
   - Go to **Manage Jenkins** > **System**
   - Scroll to **SonarQube servers**
   - Verify **Server URL** is: `http://sonarqube:9000` (NOT `http://localhost:9000`)
   - If wrong, update it and click **Save**

2. **Verify Environment Variable** (if used):
   ```bash
   # In your Jenkins job configuration or Jenkinsfile
   # Ensure SONAR_HOST uses container name:
   SONAR_HOST = 'http://sonarqube:9000'  # CORRECT
   # NOT:
   # SONAR_HOST = 'http://localhost:9000'  # WRONG - won't work in container
   ```

3. **Test Connection from Jenkins**:
   ```bash
   # SSH into Jenkins container
   docker exec -it jenkins bash

   # Test connection using container name
   curl http://sonarqube:9000/api/system/status

   # Expected output: {"id":"...","version":"...","status":"UP"}

   # Exit container
   exit
   ```

4. **Restart Jenkins after configuration change**:
   ```bash
   docker restart jenkins

   # Wait 30 seconds for Jenkins to start
   sleep 30
   ```

5. **Re-run the pipeline** and verify the SonarQube stage succeeds

**Prevention**:
- Always use **container names** (not `localhost`) when connecting between Docker containers
- Use `localhost` only when accessing services from the **host machine** (your computer)
- Container-to-container communication requires:
  - Both containers on the same Docker network
  - Using container names or service names for addressing

---

## ArgoCD Problems

### Cannot Access ArgoCD UI

**Symptom**: Connection refused on port 8080

**Solutions**:
```bash
# 1. Check ArgoCD pods
kubectl get pods -n argocd

# 2. Port forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 3. Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# 4. Check service
kubectl get svc -n argocd
```

### Application Sync Fails

**Symptom**: ArgoCD shows "OutOfSync" or sync errors

**Solutions**:
```bash
# 1. Check application status
kubectl get applications -n argocd

# 2. Describe application
kubectl describe application <app-name> -n argocd

# 3. Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller

# 4. Manually sync
argocd app sync <app-name>

# 5. Hard refresh
argocd app sync <app-name> --force
```

### Git Repository Connection Issues

**Symptom**: Cannot connect to GitHub repository

**Solutions**:
```bash
# 1. Add repository credentials
argocd repo add https://github.com/user/repo \
  --username <user> --password <token>

# 2. Verify repository
argocd repo list

# 3. Test connection
argocd repo get https://github.com/user/repo

# 4. Use HTTPS instead of SSH
# Or add SSH key to ArgoCD
```

---

## Helm Chart Issues

### Helm Install Fails

**Symptom**: `Error: INSTALLATION FAILED`

**Solutions**:
```bash
# 1. Dry run to check template
helm install --dry-run --debug myapp ./helm-charts/cicd-demo

# 2. Lint chart
helm lint ./helm-charts/cicd-demo

# 3. Check values
helm template myapp ./helm-charts/cicd-demo --values values.yaml

# 4. Install with debug
helm install myapp ./helm-charts/cicd-demo --debug

# 5. Check release status
helm list
helm status myapp
```

### Chart Template Errors

**Symptom**: Template rendering fails

**Solutions**:
```bash
# 1. Validate syntax
helm template ./helm-charts/cicd-demo

# 2. Check for missing values
helm template ./helm-charts/cicd-demo --values values.yaml --debug

# 3. Use helm lint
helm lint ./helm-charts/cicd-demo

# 4. Verify indentation in YAML files
```

---

## Ansible Problems

### Cannot Connect to Hosts

**Symptom**: `Failed to connect to host`

**Solutions**:
```bash
# 1. Test connectivity
ansible all -m ping -i ansible/inventory.ini

# 2. Check inventory
cat ansible/inventory.ini

# 3. Use verbose mode
ansible-playbook playbook.yml -vvv

# 4. Check SSH keys
ssh-add -l
```

### Playbook Execution Fails

**Symptom**: Task fails during execution

**Solutions**:
```bash
# 1. Run with check mode (dry run)
ansible-playbook playbook.yml --check

# 2. Run step by step
ansible-playbook playbook.yml --step

# 3. Start at specific task
ansible-playbook playbook.yml --start-at-task="task name"

# 4. Check syntax
ansible-playbook playbook.yml --syntax-check
```

---

## Network and Connectivity

### Services Cannot Communicate

**Symptom**: Service A cannot reach Service B

**Solutions**:
```bash
# 1. Check network connectivity
docker network ls
docker network inspect bridge

# 2. Use container names for DNS
# Instead of localhost, use container name

# 3. Verify containers are on same network
docker inspect <container> | grep NetworkMode

# 4. Test from inside container
docker exec -it <container> curl http://other-container:port
```

### DNS Resolution Failures

**Symptom**: `could not resolve host`

**Solutions**:
```bash
# 1. Check Docker DNS
docker run --rm alpine nslookup google.com

# 2. Add DNS servers to Docker
# Edit daemon.json
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}

# 3. Restart Docker
sudo systemctl restart docker
```

---

## General Debugging Tips

### Enable Debug Logging

```bash
# Docker
docker logs --follow <container>

# Kubernetes
kubectl logs <pod> --follow
kubectl logs <pod> --previous  # For crashed pods

# Jenkins
# Manage Jenkins > System Log > All Jenkins Logs

# Maven
mvn -X clean install  # Debug mode
```

### Check System Resources

```bash
# Disk space
df -h

# Memory
free -h  # Linux
vm_stat  # macOS

# Docker resources
docker system df
docker stats

# Kubernetes resources
kubectl top nodes
kubectl top pods
```

### Reset Everything

```bash
# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all volumes (WARNING: data loss)
docker volume prune -a

# Delete Kind cluster
kind delete cluster --name kind

# Restart Docker Desktop
killall Docker && open /Applications/Docker.app

# Start fresh
./scripts/setup-all.sh
```

---

## Getting Help

If issues persist:

1. Check logs with verbose/debug mode
2. Search GitHub issues: https://github.com/gmedeirosnet/CI.CD/issues
3. Review tool-specific documentation in `docs/` directory
4. Verify system meets prerequisites (16GB RAM, 50GB disk)
5. Check official documentation for each tool

## Quick Reference Commands

```bash
# Check all services status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check Kubernetes
kubectl get all --all-namespaces

# Check logs for all services
docker-compose logs -f

# Restart everything
docker-compose restart

# Clean restart
docker-compose down && docker-compose up -d
```

---

## Problem Diagnosis Decision Tree

Use these decision trees to systematically diagnose common issues.

### Decision Tree 1: Service Not Accessible

```
Is the service not accessible?
├─YES→ Is it a Kubernetes service?
│      ├─YES→ Are port forwards running?
│      │      ├─YES→ Is the pod running?
│      │      │      ├─YES→ Check pod logs: `kubectl logs <pod> -n app-demo`
│      │      │      │       └─ Check service endpoints: `kubectl get ep -n app-demo`
│      │      │      └─NO→ Why is pod not running?
│      │      │             └─ Check: `kubectl describe pod <pod> -n app-demo`
│      │      │                  ├─ ImagePullBackOff → Fix image name/registry
│      │      │                  ├─ CrashLoopBackOff → Check logs
│      │      │                  ├─ Pending → Check resources/PVC
│      │      │                  └─ Error → Check pod events
│      │      └─NO→ Start port forwarding:
│      │             `./k8s/k8s-permissions_port-forward.sh start`
│      └─NO→ Is it a Docker Compose service?
│             ├─YES→ Is the container running?
│             │      ├─YES→ Check port mapping:
│             │      │       `docker port <container>`
│             │      └─NO→ Start the service:
│             │             `docker-compose up -d <service>`
│             └─NO→ Check firewall/network:
│                    `curl -v http://localhost:<port>`
```

### Decision Tree 2: Pod Failure Diagnosis

```
Is your pod failing?
├─YES→ What is the pod status?
│      ├─ ImagePullBackOff
│      │  └─> Is it a registry issue?
│      │      ├─YES→ Check registry is accessible
│      │      │      ├─ Harbor: `curl http://localhost:8082`
│      │      │      └─ Login: `docker login localhost:8082`
│      │      └─NO→ Is the image name correct?
│      │             └─ Check: `kubectl describe pod <pod> -n app-demo`
│      │                  Look for "Failed to pull image"
│      │
│      ├─ CrashLoopBackOff
│      │  └─> Check pod logs:
│      │      `kubectl logs <pod> -n app-demo --previous`
│      │      Common causes:
│      │      ├─ Application error → Fix code
│      │      ├─ Database connection failed → Check DB
│      │      ├─ Missing environment variables → Check ConfigMap/Secret
│      │      └─ Port already in use → Check port conflicts
│      │
│      ├─ Pending
│      │  └─> Check pod events:
│      │      `kubectl describe pod <pod> -n app-demo`
│      │      Common causes:
│      │      ├─ Insufficient CPU/Memory → Scale nodes or reduce requests
│      │      ├─ PVC not bound → Check `kubectl get pvc -n app-demo`
│      │      ├─ Node selector mismatch → Check node labels
│      │      └─ Admission webhook denied → Check Kyverno policies
│      │
│      ├─ Error
│      │  └─> Pod configuration issue
│      │      Check: `kubectl get pod <pod> -n app-demo -o yaml`
│      │      Common causes:
│      │      ├─ Invalid container spec
│      │      ├─ Missing volume mount
│      │      ├─ Invalid security context
│      │      └─ Wrong resource limits format
│      │
│      └─ OOMKilled (Out of Memory)
│         └─> Increase memory limits:
│             `kubectl edit deployment <name> -n app-demo`
│             Update:
│             resources:
│               limits:
│                 memory: "1Gi"  # Increase from current
```

### Decision Tree 3: Pipeline Failure Diagnosis

```
Is your Jenkins pipeline failing?
├─YES→ Which stage is failing?
│      ├─ Checkout
│      │  └─> GitHub credentials correct?
│      │      ├─YES→ Check repository URL
│      │      └─NO→ Update credentials in Jenkins
│      │
│      ├─ Build (Maven)
│      │  └─> What error?
│      │      ├─ "mvn: command not found"
│      │      │  └─ Install Maven in Jenkins container or use Maven Docker image
│      │      ├─ "Could not resolve dependencies"
│      │      │  └─ Check internet connection, clear Maven cache
│      │      ├─ "Compilation failed"
│      │      │  └─ Check Java version, verify code compiles locally
│      │      └─ "Tests failed"
│      │         └─ Run tests locally, fix failures
│      │
│      ├─ SonarQube Analysis
│      │  └─> Connection issue?
│      │      ├─ "Connection refused"
│      │      │  └─ Use `http://sonarqube:9000` (not localhost)
│      │      │     Both containers must be on same network
│      │      ├─ "Unauthorized"
│      │      │  └─ Check SonarQube token in Jenkins credentials
│      │      └─ "Quality gate failed"
│      │         └─ Review issues in SonarQube UI, adjust rules
│      │
│      ├─ Docker Build
│      │  └─> Permission denied?
│      │      ├─YES→ Fix Docker socket permissions:
│      │      │      `docker exec -u root jenkins chmod 666 /var/run/docker.sock`
│      │      └─NO→ Check Dockerfile syntax, build context
│      │
│      ├─ Harbor Push
│      │  └─> Authentication issue?
│      │      ├─YES→ Check Harbor robot account credentials
│      │      └─NO→ Check Harbor project exists, registry is insecure-registry
│      │
│      └─ ArgoCD Sync
│         └─> Sync failed?
│             ├─ Check ArgoCD application status
│             ├─ Verify Git repository accessible
│             ├─ Check Helm chart syntax
│             └─ Review ArgoCD logs
```

### Decision Tree 4: Database Connection Issues

```
Cannot connect to database?
├─YES→ Is PostgreSQL pod running?
│      ├─YES→ Can you connect from pod?
│      │      ├─YES→ Connection string correct?
│      │      │      ├─YES→ Credentials correct?
│      │      │      │      ├─YES→ Connection pool exhausted?
│      │      │      │      │      └─ Run: `./scripts/test-db-pool.sh`
│      │      │      │      └─NO→ Check password in secret
│      │      │      └─NO→ Verify:
│      │      │             Host: postgres
│      │      │             Port: 5432
│      │      │             Database: cicd_demo
│      │      └─NO→ Network issue
│      │             ├─ Check service: `kubectl get svc postgres -n app-demo`
│      │             └─ Test connectivity: `kubectl exec -n app-demo postgres-0 -- nc -zv postgres 5432`
│      └─NO→ Start PostgreSQL:
│             └─ Check: `kubectl get pod postgres-0 -n app-demo`
│                  ├─ Not exist → Deploy: `./scripts/deploy-fullstack.sh`
│                  └─ Failing → Check: `kubectl describe pod postgres-0 -n app-demo`
│
└─NO→ Other database issue?
       └─ Run database tests: `./scripts/test-db-pool.sh`
```

---

## Checklist Before Reporting an Issue

Before opening a GitHub issue or asking for help, please complete this checklist. This helps you resolve issues faster and provides useful information if you need to report a bug.

### Step 1: Basic Verification

- [ ] Docker Desktop is running
  ```bash
  docker ps
  ```
- [ ] You have sufficient disk space (>20GB free)
  ```bash
  df -h
  ```
- [ ] You have sufficient RAM (>8GB)
  ```bash
  free -h  # Linux
  vm_stat  # macOS
  ```
- [ ] You are using the correct branch
  ```bash
  git branch
  ```
- [ ] Your code is up to date
  ```bash
  git pull origin main
  ```

### Step 2: Environment Check

- [ ] Verify prerequisites are met
  ```bash
  ./scripts/verify-environment.sh
  ```
- [ ] Check all expected services are running
  ```bash
  docker ps --format "table {{.Names}}\t{{.Status}}"
  kubectl get pods -n app-demo
  ```
- [ ] Port forwarding is active (for K8s services)
  ```bash
  ./k8s/k8s-permissions_port-forward.sh status
  ```

### Step 3: Review Documentation

- [ ] Read [FAQ.md](FAQ.md) - Is your question answered?
- [ ] Read this Troubleshooting Guide - Is your issue listed?
- [ ] Read the specific tool guide (e.g., Jenkins.md, Harbor.md)
- [ ] Check [TESTING-Guide.md](TESTING-Guide.md) if test-related

### Step 4: Run Diagnostic Tests

- [ ] Run deployment tests
  ```bash
  ./scripts/test-deployment.sh
  ```
  **Result**: ___ tests passed, ___ tests failed

- [ ] Run integration tests (optional but helpful)
  ```bash
  ./scripts/test-integration.sh
  ```
  **Result**: ___ tests passed, ___ tests failed

- [ ] Check specific service health
  ```bash
  # For Kubernetes services
  kubectl get pods -n app-demo
  kubectl logs <failing-pod> -n app-demo

  # For Docker Compose services
  docker logs <container-name>
  ```

### Step 5: Collect Error Information

If you're still having issues, collect this information:

- [ ] **Error message** (copy exact error text):
  ```
  [Paste error message here]
  ```

- [ ] **Service logs** (last 50 lines):
  ```bash
  # For Kubernetes
  kubectl logs <pod> -n app-demo --tail=50

  # For Docker
  docker logs <container> --tail=50
  ```

- [ ] **Pod/container status**:
  ```bash
  kubectl get pod <pod> -n app-demo -o yaml
  # OR
  docker inspect <container>
  ```

- [ ] **Events** (for Kubernetes issues):
  ```bash
  kubectl get events -n app-demo --sort-by='.lastTimestamp' | tail -20
  ```

- [ ] **System information**:
  ```bash
  # OS version
  sw_vers  # macOS
  cat /etc/os-release  # Linux

  # Docker version
  docker --version

  # Kubernetes version
  kubectl version --short
  ```

### Step 6: Attempted Solutions

- [ ] I have tried restarting the failing service:
  ```bash
  # Kubernetes
  kubectl rollout restart deployment/<name> -n app-demo
  # Docker
  docker restart <container>
  ```

- [ ] I have tried cleaning and redeploying:
  ```bash
  ./scripts/cleanup-all.sh
  ./scripts/setup-all.sh
  ```

- [ ] I have checked for port conflicts:
  ```bash
  lsof -i :8080  # Replace with relevant port
  ```

- [ ] I have reviewed recent changes:
  ```bash
  git log --oneline -10
  git diff HEAD~1
  ```

### Step 7: Search Existing Issues

- [ ] I have searched GitHub issues:
  - https://github.com/gmedeirosnet/CI.CD/issues
  - Search keywords: [your error message keywords]

- [ ] I have checked closed issues for solutions

### Step 8: Prepare Issue Report

If the issue persists after completing all steps above, prepare your issue report with:

**Required Information**:
1. **Environment**:
   - OS: [macOS/Linux/Windows]
   - Docker version: [run `docker --version`]
   - RAM: [8GB/16GB/etc]
   - Disk space free: [run `df -h`]

2. **Issue Description**:
   - What were you trying to do?
   - What did you expect to happen?
   - What actually happened?

3. **Steps to Reproduce**:
   - List exact commands you ran
   - Include any configuration changes
   - Specify which script/tool failed

4. **Error Messages**:
   - Include full error message (use code blocks)
   - Include relevant logs (last 50 lines)
   - Include pod events (for Kubernetes)

5. **What You've Tried**:
   - List troubleshooting steps from this checklist
   - Include results of each attempt

6. **Test Results**:
   - Output from `./scripts/test-deployment.sh`
   - Output from `./scripts/test-integration.sh`

**Issue Template**:

```markdown
## Environment
- OS: [macOS 13.2 / Ubuntu 22.04 / Windows 11 WSL2]
- Docker version: [24.0.7]
- RAM: [16GB]
- Disk free: [50GB]

## Issue Description
[What were you trying to do?]

## Expected Behavior
[What should happen?]

## Actual Behavior
[What actually happened?]

## Steps to Reproduce
1. [First step]
2. [Second step]
3. [Error occurs]

## Error Message
```
[Full error message here]
```

## Logs
```
[Relevant logs here - last 50 lines]
```

## What I've Tried
- [x] Restarted service
- [x] Checked documentation
- [ ] Other steps...

## Test Results
- Deployment tests: 20/26 passed
- Integration tests: Skipped
- Specific failure: [describe]

## Additional Context
[Any other relevant information]
```

---

## Additional Troubleshooting Resources

### Log Locations

**Docker Compose Services**:
```bash
# Jenkins
docker logs jenkins --tail=100 --follow

# Harbor
docker-compose -f harbor/docker-compose.yml logs --tail=100

# SonarQube
docker logs sonarqube --tail=100
```

**Kubernetes Services**:
```bash
# PostgreSQL
kubectl logs -n app-demo postgres-0 --tail=100

# Backend
kubectl logs -n app-demo -l app=cicd-demo-backend --tail=100

# All pods in namespace
kubectl logs -n app-demo --all-containers=true --tail=50
```

**System Logs**:
```bash
# Docker daemon logs (Linux)
sudo journalctl -u docker --since "1 hour ago"

# macOS Console.app
# Open Console.app and filter for "Docker"

# Kind cluster logs
kind export logs ./kind-logs
```

### Common Error Patterns

#### "Connection Refused" Errors

**Pattern**: `connect: connection refused` or `dial tcp: connect: connection refused`

**Likely Causes**:
1. Service not running
2. Wrong hostname (use container name, not localhost)
3. Port forwarding not active
4. Firewall blocking connection

**Fix Strategy**:
1. Verify service is running: `docker ps` or `kubectl get pods`
2. Check hostname in configuration (container-to-container use container names)
3. Restart port forwarding: `./k8s/k8s-permissions_port-forward.sh restart`

#### "Permission Denied" Errors

**Pattern**: `permission denied` or `dial unix /var/run/docker.sock: connect: permission denied`

**Likely Causes**:
1. Docker socket permissions (Jenkins)
2. File ownership in volumes
3. Security context restrictions

**Fix Strategy**:
1. For Docker socket: `docker exec -u root jenkins chmod 666 /var/run/docker.sock`
2. For file permissions: Check pod init containers, fsGroup settings
3. For security context: Review pod security context and Kyverno policies

#### "Out of Memory" Errors

**Pattern**: `OOMKilled`, `OutOfMemory`, or `exit code 137`

**Likely Causes**:
1. Memory limits too low
2. Memory leak in application
3. Insufficient cluster resources

**Fix Strategy**:
1. Increase memory limits: `kubectl edit deployment <name> -n app-demo`
2. Check memory usage: `kubectl top pods -n app-demo`
3. Review application logs for memory leaks
4. Scale down other services if needed

#### "Image Pull" Errors

**Pattern**: `ImagePullBackOff`, `ErrImagePull`, `Failed to pull image`

**Likely Causes**:
1. Image doesn't exist
2. Registry not accessible
3. Authentication failed
4. Image name typo

**Fix Strategy**:
1. Verify image exists: `docker images` or check Harbor UI
2. Check registry accessible: `curl http://localhost:8082`
3. Verify credentials: `docker login localhost:8082`
4. Check image name in deployment YAML

---

## Preventive Maintenance

### Daily Checks

```bash
# Check all services health
./scripts/test-deployment.sh

# Check disk space
docker system df
df -h

# Check pod status
kubectl get pods -n app-demo
```

### Weekly Maintenance

```bash
# Clean unused Docker resources
docker system prune

# Check for updates
git pull

# Review logs for errors
docker logs jenkins | grep ERROR
kubectl logs -n app-demo -l app=cicd-demo-backend | grep ERROR
```

### Monthly Maintenance

```bash
# Update tool versions (review release notes first)
# Update docker-compose.yml image tags
# Update Helm chart versions

# Rotate credentials
# Follow: docs/SECURITY-Credential-Rotation.md

# Review and update policies
# Check: k8s/kyverno/policies/
```

---

## Getting Help

### Documentation Resources

1. **This Repository**:
   - [FAQ.md](FAQ.md) - Frequently Asked Questions
   - [QUICK-START.md](QUICK-START.md) - Quick start guide
   - [INDEX.md](INDEX.md) - Complete documentation index
   - Tool-specific guides in `docs/`

2. **Official Documentation**:
   - [Kubernetes docs](https://kubernetes.io/docs/)
   - [Docker docs](https://docs.docker.com/)
   - [Jenkins docs](https://www.jenkins.io/doc/)
   - [ArgoCD docs](https://argo-cd.readthedocs.io/)
   - [Harbor docs](https://goharbor.io/docs/)

3. **Community**:
   - GitHub Issues: https://github.com/gmedeirosnet/CI.CD/issues
   - GitHub Discussions: https://github.com/gmedeirosnet/CI.CD/discussions

### Reporting Bugs

When reporting bugs, use the checklist above and provide:
- Environment details
- Exact steps to reproduce
- Expected vs actual behavior
- Full error messages and logs
- What you've already tried

### Requesting Features

When requesting features:
- Explain the use case
- Describe expected behavior
- Suggest implementation approach (optional)
- Link to relevant documentation or examples

---

**Last Updated**: 2026-03-10
**Version**: 2.0.0 (Enhanced with decision trees and pre-issue checklist)
**Maintained By**: DevOps Lab Team
