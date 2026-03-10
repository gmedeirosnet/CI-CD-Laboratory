# Command Cheat Sheet

Quick reference for common commands organized by tool.

## Environment & Setup

### Initial Setup
```bash
# Copy environment template
cp .env.template .env

# Verify prerequisites
./scripts/verify-environment.sh

# Complete setup
./scripts/setup-all.sh

# Cleanup everything
./scripts/cleanup-all.sh
```

### Port Forwarding
```bash
# Start forwarding
./k8s/k8s-permissions_port-forward.sh start

# Stop forwarding
./k8s/k8s-permissions_port-forward.sh stop

# Check status
./k8s/k8s-permissions_port-forward.sh status

# Restart forwarding
./k8s/k8s-permissions_port-forward.sh restart
```

## Kubernetes & Kind

### Cluster Management
```bash
# Create cluster
kind create cluster --config kind-config.yaml

# Delete cluster
kind delete cluster --name app-demo

# Get clusters
kind get clusters

# List nodes
kubectl get nodes

# Describe node
kubectl describe node <node-name>
```

### Pods & Services
```bash
# List all resources
kubectl get all -A

# Get pods
kubectl get pods -n app-demo

# Get services
kubectl get svc -n app-demo

# Get deployments
kubectl get deployments -n app-demo

# Describe pod
kubectl describe pod <pod-name> -n app-demo

# Delete pod (will restart)
kubectl delete pod <pod-name> -n app-demo
```

### Logs & Debugging
```bash
# View logs (real-time)
kubectl logs -f <pod-name> -n app-demo

# View logs from specific container
kubectl logs <pod-name> -c <container-name> -n app-demo

# View logs from all pods with label
kubectl logs -l app=postgres -n app-demo

# Execute command in pod
kubectl exec -it <pod-name> -n app-demo -- /bin/bash

# Port forward to pod
kubectl port-forward <pod-name> 8080:8080 -n app-demo

# Get pod events
kubectl describe pod <pod-name> -n app-demo
```

### Namespaces
```bash
# List namespaces
kubectl get namespaces

# Create namespace
kubectl create namespace <namespace-name>

# Delete namespace
kubectl delete namespace <namespace-name>

# Set default namespace
kubectl config set-context --current --namespace=<namespace-name>
```

## Docker

### Image Management
```bash
# List images
docker images

# Build image
docker build -t <image-name>:<tag> .

# Tag image
docker tag <image-id> <registry>/<repository>/<image-name>:<tag>

# Push image
docker push <registry>/<repository>/<image-name>:<tag>

# Pull image
docker pull <image-name>:<tag>

# Remove image
docker rmi <image-id>

# Remove unused images
docker image prune -a
```

### Container Management
```bash
# List running containers
docker ps

# List all containers
docker ps -a

# Run container
docker run -d --name <name> -p 8080:8080 <image>

# Stop container
docker stop <container-id>

# Start container
docker start <container-id>

# Remove container
docker rm <container-id>

# View logs
docker logs -f <container-id>

# Execute command
docker exec -it <container-id> /bin/bash
```

### Registry Operations
```bash
# Login to registry
docker login <registry-url>

# Logout
docker logout <registry-url>

# Load image to Kind
kind load docker-image <image-name>:<tag> --name app-demo
```

## Database - PostgreSQL

### Connect to Database
```bash
# Connect directly in pod
kubectl exec -it postgres-0 -n app-demo -- psql -U postgres -d cicd_demo

# Port forward then connect locally
kubectl port-forward postgres-0 5432:5432 -n app-demo
psql -h localhost -U postgres -d cicd_demo
```

### Common SQL
```sql
-- List databases
\l

-- Connect to database
\c cicd_demo

-- List tables
\dt

-- Describe table
\d tasks

-- Query tasks
SELECT * FROM tasks;

-- Exit
\q
```

## Maven

### Build Commands
```bash
# Clean build
mvn clean package

# Build with tests
mvn clean package -DskipTests

# Run tests only
mvn test

# Run single test class
mvn test -Dtest=ClassName

# Run application locally
mvn spring-boot:run

# Install dependencies
mvn dependency:resolve

# Check for updates
mvn versions:display-dependency-updates
```

## Frontend - React/Node

### Setup & Build
```bash
cd frontend

# Install dependencies
npm install

# Start dev server
npm run dev

# Build for production
npm run build

# Run linter
npm run lint

# Fix linting issues
npm run lint --fix
```

## Jenkins

### Access Jenkins
```bash
# Get initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# View Jenkins logs
docker logs -f jenkins

# Restart Jenkins
docker restart jenkins
```

### Pipeline Operations
```bash
# Trigger build via CLI
curl -X POST http://localhost:8080/job/<job-name>/build \
  -u username:password

# Get build status
curl http://localhost:8080/api/json
```

## Harbor Registry

### Login & Management
```bash
# Login to Harbor
docker login localhost:8082 -u admin -p Harbor12345

# Create project (via UI or API)
# Projects > New Project > cicd-demo

# List repositories
curl -u admin:Harbor12345 http://localhost:8082/api/v2.0/repositories

# Create robot account
./scripts/create-harbor-robot.sh
```

## SonarQube

### Quality Analysis
```bash
# Run SonarQube analysis
mvn clean package sonar:sonar \
  -Dsonar.projectKey=cicd-demo \
  -Dsonar.sources=src \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=<token>

# Get quality gate status
curl http://localhost:9000/api/qualitygates/project_status?projectKey=cicd-demo
```

## ArgoCD

### Application Management
```bash
# Login to ArgoCD CLI
argocd login localhost:8090 --username admin --password <password>

# List applications
argocd app list

# Get application status
argocd app get cicd-demo

# Sync application
argocd app sync cicd-demo

# Hard refresh
argocd app sync cicd-demo --hard-refresh

# View logs
argocd app logs cicd-demo

# Diff
argocd app diff cicd-demo
```

## Helm

### Chart Operations
```bash
# List installed releases
helm list -n app-demo

# Install chart
helm install cicd-demo ./helm-charts/cicd-demo -n app-demo

# Upgrade release
helm upgrade cicd-demo ./helm-charts/cicd-demo -n app-demo

# Uninstall release
helm uninstall cicd-demo -n app-demo

# Get chart values
helm get values cicd-demo -n app-demo

# Template chart
helm template cicd-demo ./helm-charts/cicd-demo

# Validate chart
helm lint ./helm-charts/cicd-demo
```

## Grafana & Monitoring

### Access Grafana
```bash
# Get Grafana admin password
kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# View Prometheus queries
curl http://localhost:30090/api/v1/labels

# View Loki logs
curl http://localhost:31000/loki/api/v1/labels
```

## Kyverno & Policy

### Policy Operations
```bash
# Apply policies
kubectl apply -f k8s/kyverno/policies/ -R

# List policies
kubectl get clusterpolicies

# View policy details
kubectl describe clusterpolicy <policy-name>

# View violations (Audit mode)
kubectl get policyreport -n app-demo

# Check Policy Reporter
curl http://localhost:31001/api/v1/policyreports
```

## Git Operations

### Repository Management
```bash
# Clone repository
git clone <repository-url>

# Create branch
git checkout -b feature/new-feature

# Commit changes
git add .
git commit -m "commit message"

# Push branch
git push origin feature/new-feature

# Create pull request (via GitHub CLI)
gh pr create --title "PR Title" --body "Description"

# View branch
git log --oneline

# Merge branches
git merge <branch-name>
```

## Troubleshooting Commands

### Diagnostics
```bash
# Check all pod status
kubectl get pods -A

# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods -n app-demo

# View events
kubectl get events -n app-demo

# Check persistent volumes
kubectl get pv,pvc -n app-demo

# View service endpoints
kubectl get endpoints -n app-demo

# Check DNS
kubectl run -it --rm debug --image=busybox:1.28 --restart=Never -- nslookup postgres.app-demo
```

### Cleanup Commands
```bash
# Delete all pods in namespace
kubectl delete pods --all -n app-demo

# Delete all resources in namespace
kubectl delete all --all -n app-demo

# Prune Docker system
docker system prune -a --volumes

# Clear Kind cache
kind delete cluster --name app-demo

# Remove stopped containers
docker container prune

# Remove dangling images
docker image prune
```

---

**Pro Tip:** Combine commands with pipes and grep to filter output:
```bash
kubectl get pods -n app-demo | grep postgres
docker ps | grep jenkins
```

For more detailed information, see the tool-specific documentation in docs/ directory.
