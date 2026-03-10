# Port Reference Guide

## Overview
This document provides a comprehensive reference for all network ports used in the DevOps CI/CD learning laboratory environment.

## Port Summary Table

| Service | Internal Port | External Port | Protocol | Access URL | Purpose |
|---------|--------------|---------------|----------|------------|---------|
| **Application** | 8001 | 8001 | HTTP | http://localhost:8001 | Demo Spring Boot app |
| **ArgoCD** | 443 | 8090 | HTTPS | https://localhost:8090 | GitOps deployment UI |
| **Grafana** | 3000 | 3000 | HTTP | http://localhost:3000 | Observability & Logs UI |
| **Harbor (HTTP)** | 80 | 8082 | HTTP | http://localhost:8082 | Container registry web UI |
| **Harbor (HTTPS)** | 443 | 8443 | HTTPS | https://localhost:8443 | Secure container registry |
| **Jenkins** | 8080 | 8080 | HTTP | http://localhost:8080 | CI/CD orchestration |
| **Jenkins (Agent)** | 50000 | 50000 | TCP | - | Agent communication |
| **Kind API Server** | 6443 | 6443 | HTTPS | https://127.0.0.1:6443 | Kubernetes API |
| **Kyverno** | 8000 | - | HTTP | - | Policy engine metrics |
| **Loki** | 3100 | 31000 | HTTP | http://localhost:31000 | Log aggregation API |
| **Policy Reporter UI** | 8080 | 31002 | HTTP | http://localhost:31002 | Policy violation dashboard |
| **Policy Reporter API** | 8080 | 31001 | HTTP | http://localhost:31001 | Policy violation API |
| **Prometheus** | 9090 | 30090 | HTTP | http://localhost:30090 | Metrics & monitoring |
| **SonarQube** | 9000 | 9000 | HTTP | http://localhost:9000 | Code quality analysis |

**Note on Port Mappings**:
- **Internal Port**: Port the service listens on inside the container/pod
- **External Port**: Port exposed on localhost for access from your machine
- **ArgoCD 8090**: Avoids conflict with Jenkins (8080), used by automated script
- **Loki/Prometheus**: NodePort mappings match external ports for consistency

## Automated Port Forwarding

The lab includes an automated script for managing Kubernetes port forwards and Docker permissions.

**Script**: `scripts/k8s-permissions_port-forward.sh`

**Features**:
- Automatically fixes Docker socket permissions for Jenkins
- Manages port forwards for Loki, Prometheus, and ArgoCD
- PID-based tracking for reliable start/stop
- Status monitoring and orphaned process cleanup

**Usage**:
```bash
# Start all port forwards (includes Docker permission fix)
./scripts/k8s-permissions_port-forward.sh start

# Check status
./scripts/k8s-permissions_port-forward.sh status

# Stop all port forwards
./scripts/k8s-permissions_port-forward.sh stop

# Restart all
./scripts/k8s-permissions_port-forward.sh restart

# Fix Docker permissions only
./scripts/k8s-permissions_port-forward.sh fix-docker

# Cleanup orphaned processes
./scripts/k8s-permissions_port-forward.sh cleanup
```

**Managed Services**:
- **Loki**: localhost:31000 → logging/loki:3100
- **Prometheus**: localhost:30090 → monitoring/prometheus:9090
- **ArgoCD**: localhost:8090 → argocd/argocd-server:443

**Note**: When using automated script, ArgoCD is on 8090. For manual port-forward, use 8081 to avoid Jenkins conflict.

**PID Files**: Stored in `/tmp/k8s-port-forward/*.pid`

## Detailed Service Configurations

### Jenkins

```yaml
Ports:
  - 8080:8080    # Web UI and API
  - 50000:50000  # Agent communication (JNLP)

Environment Variables:
  JENKINS_PORT: 8080
  JENKINS_SLAVE_AGENT_PORT: 50000

Access:
  URL: http://localhost:8080
  Default User: admin
  Password: (set during initial setup)
```

**Port Conflicts**: If port 8080 is in use, modify `docker-compose.yml` or Jenkins startup script.

---

### Harbor Registry

```yaml
HTTP Port:
  External: 8082
  Internal: 80
  Protocol: HTTP
  URL: http://localhost:8082

HTTPS Port:
  External: 8443
  Internal: 443
  Protocol: HTTPS
  URL: https://localhost:8443

Docker Registry API:
  URL: localhost:8082 (for docker push/pull)

Environment Variables:
  HARBOR_HTTP_PORT: 8082
  HARBOR_HTTPS_PORT: 8443
```

**Docker Configuration**:
```json
{
  "insecure-registries": ["localhost:8082"]
}
```

---

### SonarQube

```yaml
Port:
  External: 9000
  Internal: 9000
  Protocol: HTTP
  URL: http://localhost:9000

Environment Variables:
  SONAR_HOST: http://localhost:9000
  SONAR_PORT: 9000

Docker Network:
  Jenkins communicates using container name: http://sonarqube:9000
  Host access uses: http://localhost:9000

Health Check:
  URL: http://localhost:9000/api/system/status
  Expected Response: {"status":"UP"}

Note:
  - Both external and internal ports are 9000 (no port mapping)
  - Jenkins uses Docker network name 'sonarqube' for internal communication

Database:
  Internal Port: 5432 (PostgreSQL)
  Not exposed externally
```

---

### Grafana, Loki & Prometheus

```yaml
Grafana:
  External: 3000
  Internal: 3000
  Protocol: HTTP
  URL: http://localhost:3000
  Deployment: Docker Desktop

  Environment Variables:
    GF_SECURITY_ADMIN_USER: admin
    GF_SECURITY_ADMIN_PASSWORD: admin

  Access:
    Username: admin
    Password: admin

  Datasources:
    - Loki (logs)
    - Prometheus (metrics)

Loki:
  Internal: 3100 (ClusterIP in K8s)
  NodePort: 31000 (for external access)
  Protocol: HTTP
  Namespace: logging (Kind K8s)

  API Endpoints:
    Ready: http://localhost:31000/ready
    Metrics: http://localhost:31000/metrics
    Labels: http://localhost:31000/loki/api/v1/labels
    Query: http://localhost:31000/loki/api/v1/query

Promtail:
  Internal: 9080 (metrics)
  Deployment: DaemonSet (Kind K8s)
  Namespace: logging

Prometheus:
  Internal: 9090 (ClusterIP in K8s)
  NodePort: 30090 (for external access)
  Protocol: HTTP
  Namespace: monitoring (Kind K8s)

  API Endpoints:
    UI: http://localhost:30090
    Ready: http://localhost:30090/-/ready
    Healthy: http://localhost:30090/-/healthy
    Targets: http://localhost:30090/targets
    Config: http://localhost:30090/config
    Query: http://localhost:30090/api/v1/query

kube-state-metrics:
  Internal: 8080 (metrics), 8081 (telemetry)
  Deployment: Deployment (Kind K8s)
  Namespace: monitoring

node-exporter:
  Internal: 9100 (metrics)
  Deployment: DaemonSet (Kind K8s)
  Namespace: monitoring

Connections:
  Grafana -> Loki: http://host.docker.internal:31000
  Grafana -> Prometheus: http://host.docker.internal:30090
  Prometheus -> kube-state-metrics: kube-state-metrics.monitoring.svc.cluster.local:8080
  Prometheus -> node-exporter: Pod IP discovery
  Prometheus -> Loki: loki.logging.svc.cluster.local:3100
```

**Port Forward Commands (Manual)**:

For automated port forwarding, use `scripts/k8s-permissions_port-forward.sh start`

Manual commands:
```bash
# Loki (from K8s to host)
kubectl port-forward -n logging svc/loki 31000:3100

# Prometheus (from K8s to host)
kubectl port-forward -n monitoring svc/prometheus 30090:9090

# ArgoCD (from K8s to host)
# Manual Port Forward Examples
# Note: Use 8081 for manual setup (8080 conflicts with Jenkins)
# Automated script uses 8090
kubectl port-forward -n argocd svc/argocd-server 8081:443

# Grafana (if in K8s)
kubectl port-forward -n grafana svc/grafana 3000:3000
```

---

### Kind Kubernetes Cluster

```yaml
API Server:
  Port: 6443
  Protocol: HTTPS
  URL: https://127.0.0.1:6443

Control Plane:
  Container Port: 6443
  Mapped Port: 6443

Worker Nodes:
  NodePort Range: 30000-32767
  Used for exposing services externally

DNS:
  Internal Port: 53
  Service: CoreDNS

Metrics Server:
  Internal Port: 443
```

**kubeconfig Location**: `~/.kube/config`

---

### Spring Boot Application

```yaml
Application Port:
  External: 8001
  Internal: 8001
  Protocol: HTTP

Health Endpoint:
  URL: http://localhost:8001/health

API Endpoints:
  Base URL: http://localhost:8001

Kubernetes Service:
  Type: LoadBalancer or NodePort
  Port: 80 -> 8001
  TargetPort: 8001
```

---

### ArgoCD

```yaml
Server Port:
  External: 8090 (HTTPS - automated script)
  Internal: 443 (HTTPS)
  Protocol: HTTPS

API Server:
  URL: https://localhost:8090
  gRPC Port: 8080 (internal only)

Repo Server:
  Internal Port: 8081

Redis:
  Internal Port: 6379

Metrics:
  Internal Port: 8082

Namespace:
  argocd (Kind K8s)

Health Check:
  URL: https://localhost:8090/healthz
  Expected Response: {"status":"Healthy"}
```

**Automated Access (Recommended)**:
```bash
# Start port forward (includes Docker permission fix)
./k8s/k8s-permissions_port-forward.sh start

# Access UI
open https://localhost:8090
```

**Manual Port Forward Command**:
```bash
# Note: Use port 8090 to match automated setup and avoid Jenkins conflict (8080)
kubectl port-forward -n argocd svc/argocd-server 8090:443
```

**Port Mapping Explanation**:
- **Kubernetes Service**: argocd-server runs on port 443 (HTTPS) inside the cluster
- **Port Forward**: kubectl forwards localhost:8090 → cluster:443
- **Why 8090?**: Avoids conflict with Jenkins (8080) and provides consistent access URL

**Note**: Automated script uses port 8090 to avoid conflict with Jenkins (8080). For manual setup, always use 8090 for consistency.

---

### Kyverno

```yaml
Metrics Port:
  Internal: 8000
  Protocol: HTTP
  Namespace: kyverno (Kind K8s)
  Note: Port 8000 often conflicts with k9s or other tools

Webhook Server:
  Internal Port: 9443 (HTTPS)

Metrics Endpoints:
  URL: http://kyverno-svc-metrics.kyverno.svc.cluster.local:8000/metrics

  Key Metrics:
    - kyverno_policy_rule_results_total: Policy evaluation results
    - kyverno_admission_requests_total: Total admission requests
    - kyverno_admission_review_duration_seconds: Request processing time
    - kyverno_policy_changes_total: Policy lifecycle tracking

Prometheus Integration:
  ServiceMonitor: k8s/kyverno/monitoring/prometheus-servicemonitor.yaml
  Scrape Interval: 30s
  Target: kyverno-svc-metrics.kyverno.svc.cluster.local:8000

Policy Reports:
  Access via kubectl:
    - kubectl get clusterpolicyreport -A
    - kubectl get policyreport -n app-demo
    - kubectl describe policyreport -n app-demo

Webhooks:
  Validating: kyverno-resource-validating-webhook-cfg
  Mutating: kyverno-resource-mutating-webhook-cfg
  Port: 9443
```

**Port Forward for Metrics** (optional):
```bash
# Check if port 8000 is available
lsof -i :8000

# If port 8000 is in use, use alternative port (recommended)
kubectl port-forward -n kyverno svc/kyverno-svc-metrics 8002:8000

# Test metrics endpoint
curl -s http://localhost:8002/metrics | head -20

# View Kyverno-specific metrics
curl -s http://localhost:8002/metrics | grep "^kyverno_"

# Check policy execution details
curl -s http://localhost:8002/metrics | grep -E "kyverno_(policy_|rule_)"

# Stop port-forward when done
pkill -f "port-forward.*kyverno-svc-metrics"
```

---

## Port Conflict Resolution

### Common Conflicts

| Port | Common Conflicts | Solution |
|------|-----------------|----------|
| 8080 | Jenkins, Application, Tomcat | Use different external ports (ArgoCD→8090) |
| 9000 | SonarQube, Other applications | Change SonarQube port |
| 8082 | Harbor, Other services | Modify Harbor configuration |
| 3000 | Node.js apps, Grafana, Dev servers | Use alternative port (3001) |
| 3100 | Loki, Other log collectors | Use NodePort 31000 mapping |
| 5432 | PostgreSQL databases | Use Docker networks |

### Checking Port Usage

The automated script (`k8s-permissions_port-forward.sh`) includes port conflict detection using `lsof`.

**macOS/Linux**:
```bash
# Check if port is in use
lsof -i :8080

# Check all listening ports
netstat -an | grep LISTEN

# Find process using specific port
lsof -ti:8080

# Check script-managed port forwards
./scripts/k8s-permissions_port-forward.sh status
```

**Kill process on port**:
```bash
# macOS/Linux
kill -9 $(lsof -ti:8080)

# Or using pkill
pkill -f "process-name"
```

---

## Docker Network Configuration

### Understanding Port Mappings

**Host Network vs Docker Network**:

```yaml
Host Network (localhost):
  - Used for external access from your machine
  - Example: http://localhost:8080 (Jenkins UI in browser)
  - Port mappings: HOST_PORT:CONTAINER_PORT

Docker Internal Network:
  - Used for container-to-container communication
  - Example: http://jenkins:8080 (from another container)
  - No port mapping needed - direct container name resolution

Kubernetes Network:
  - Used for pod-to-pod or pod-to-service communication
  - Example: http://myapp.default.svc.cluster.local:8080
  - Port forwarding needed for external access
```

**Practical Examples**:

```bash
# 1. Docker Container accessing Jenkins
# From another container on same network:
curl http://jenkins:8080/api/json

# From host machine (your browser):
curl http://localhost:8080/api/json

# 2. Jenkins accessing SonarQube
# Jenkins uses Docker network - container name:
SONAR_HOST_URL=http://sonarqube:9000

# You access from browser - localhost:
http://localhost:9000

# 3. Jenkins accessing Harbor
# Jenkins pushes to: host.docker.internal:8082
# You access UI at: http://localhost:8082

# 4. Kind cluster accessing host services
# Use special hostname: host.docker.internal
# Example: Harbor registry at host.docker.internal:8082
```

**Port Mapping Rules**:

| Service | Container Port | Host Port | Container-to-Container URL | External URL |
|---------|---------------|-----------|---------------------------|--------------|
| Jenkins | 8080 | 8080 | http://jenkins:8080 | http://localhost:8080 |
| Harbor | 80 | 8082 | http://harbor:80 | http://localhost:8082 |
| SonarQube | 9000 | 9000 | http://sonarqube:9000 | http://localhost:9000 |
| PostgreSQL | 5432 | - (not exposed) | http://postgres:5432 | N/A (internal only) |

### Bridge Network

```yaml
Network: cicd-network (custom bridge)
Subnet: 172.17.0.0/16 (default bridge)
Gateway: 172.17.0.1

Containers can communicate using:
  - Container names (DNS resolution)
  - IP addresses (less reliable, can change)
  - Exposed ports on host (via localhost)

Created by:
  docker network create cicd-network

Connected containers:
  - Jenkins
  - Harbor (core, db, redis, jobservice, registry)
  - SonarQube + SonarQube DB
```

### Kind Network

```yaml
Network: kind
Driver: bridge
Subnet: (dynamically assigned)

Container Communication:
  - All Kind nodes in same network
  - Can access host via host.docker.internal
  - Isolated from other Docker networks

Special Hostname:
  host.docker.internal → Docker host (your machine)

Use Cases:
  - Pods pulling from Harbor: host.docker.internal:8082
  - ArgoCD accessing Git on host
  - Accessing services running on Docker Desktop
```

### Host Access from Containers

```yaml
macOS/Windows Docker Desktop:
  Hostname: host.docker.internal
  Example: curl http://host.docker.internal:8080

Linux:
  Add to docker run: --add-host=host.docker.internal:host-gateway
  Or use: 172.17.0.1 (Docker gateway)

Common Use Cases:
  - Kind cluster → Harbor (host.docker.internal:8082)
  - Jenkins → ArgoCD (host.docker.internal:8090)
  - Container → Service on host
```

---

## Firewall Configuration

### macOS

```bash
# Allow Docker
# No specific firewall rules needed for localhost

# If using remote access, add rules for:
# - Jenkins: 8080
# - Harbor: 8082, 8443
# - SonarQube: 9000
```

### Linux (UFW)

```bash
# Allow Jenkins
sudo ufw allow 8080/tcp

# Allow Harbor
sudo ufw allow 8082/tcp
sudo ufw allow 8443/tcp

# Allow SonarQube
sudo ufw allow 9000/tcp

# Allow Kubernetes API
sudo ufw allow 6443/tcp
```

---

## Service-to-Service Communication

### Internal Docker Network

```yaml
Jenkins -> Harbor:
  URL: http://harbor:80 or harbor:443
  Note: Use container name, not localhost

Jenkins -> SonarQube:
  URL: http://sonarqube:9000

Jenkins -> Kind:
  Use kubectl with kubeconfig
  API: https://kind-control-plane:6443
```

### Within Kubernetes

```yaml
Service Communication:
  Format: <service-name>.<namespace>.svc.cluster.local
  Example: myapp.default.svc.cluster.local

Pod to Service:
  Direct service name within same namespace
  Example: myapp:8080
```

---

## Health Check Endpoints

| Service | Endpoint | Expected Response |
|---------|----------|-------------------|
| Application | http://localhost:8001/actuator/health | {"status":"UP"} |
| Jenkins | http://localhost:8080/login | 200 OK |
| Harbor | http://localhost:8082/api/v2.0/health | {"status":"healthy"} |
| SonarQube | http://localhost:9000/api/system/status | {"status":"UP"} |
| Grafana | http://localhost:3000/api/health | {"database":"ok"} |
| Loki | http://localhost:31000/ready | ready |
| Prometheus | http://localhost:30090/-/ready | Prometheus is Ready. |
| Prometheus (Healthy) | http://localhost:30090/-/healthy | Prometheus is Healthy. |
| ArgoCD | https://localhost:8090/healthz | {"status":"Healthy"} |
| Kind API | kubectl get --raw='/healthz' | ok |

**Testing Health Checks**:
```bash
# Test all services at once
for service in "Application:8001/actuator/health" "Jenkins:8080/login" "Harbor:8082/api/v2.0/health" "SonarQube:9000/api/system/status"; do
    IFS=':' read -r name port_path <<< "$service"
    echo -n "$name: "
    curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port_path" || echo "FAILED"
    echo
done

# Test Kubernetes services
kubectl get --raw='/healthz'
kubectl get --raw='/livez'
kubectl get --raw='/readyz'
```

---

## Port Testing Commands

### Test Port Connectivity

```bash
# Using netcat
nc -zv localhost 8080

# Using telnet
telnet localhost 8080

# Using curl
curl -I http://localhost:8001

# Using kubectl (for K8s services)
kubectl port-forward svc/service-name 8080:80
```

### Check Service Status

```bash
# Docker containers
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"

# Kubernetes services
kubectl get svc --all-namespaces

# Kind cluster ports
docker ps | grep kind
```

---

## Kubectl Port-Forward Examples

### Basic Port Forwarding

```bash
# Format: kubectl port-forward [TYPE/NAME] [LOCAL_PORT]:[REMOTE_PORT] -n [NAMESPACE]

# Forward to a pod
kubectl port-forward pod/my-pod 8080:80 -n default

# Forward to a service (recommended - survives pod restarts)
kubectl port-forward svc/my-service 8080:80 -n default

# Forward to a deployment
kubectl port-forward deployment/my-deployment 8080:80 -n default
```

### Lab-Specific Examples

```bash
# ArgoCD Server (HTTPS)
kubectl port-forward -n argocd svc/argocd-server 8090:443
# Access: https://localhost:8090

# Loki (Log aggregation)
kubectl port-forward -n logging svc/loki 31000:3100
# Access: http://localhost:31000

# Prometheus (Metrics)
kubectl port-forward -n monitoring svc/prometheus 30090:9090
# Access: http://localhost:30090

# Application (if deployed in namespace)
kubectl port-forward -n app-demo svc/cicd-demo-app 8001:8001
# Access: http://localhost:8001

# PostgreSQL (database)
kubectl port-forward -n app-demo svc/postgres 5432:5432
# Access: postgresql://localhost:5432

# Kyverno Metrics
kubectl port-forward -n kyverno svc/kyverno-svc-metrics 8002:8000
# Access: http://localhost:8002/metrics

# Policy Reporter UI
kubectl port-forward -n policy-reporter svc/policy-reporter-ui 31002:8080
# Access: http://localhost:31002
```

### Advanced Port-Forward Scenarios

```bash
# Background process with output redirection
kubectl port-forward svc/loki 31000:3100 -n logging > /tmp/port-forward-loki.log 2>&1 &
echo $! > /tmp/port-forward-loki.pid

# Multiple ports for same service
kubectl port-forward svc/jenkins 8080:8080 50000:50000

# Listen on all interfaces (DANGEROUS - use with caution)
kubectl port-forward --address 0.0.0.0 svc/my-service 8080:80

# Specific pod selection
kubectl port-forward $(kubectl get pod -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].metadata.name}') 8090:8080 -n argocd
```

### Managing Port Forwards

```bash
# List active port forwards
ps aux | grep "kubectl port-forward"

# Kill specific port forward
pkill -f "port-forward.*loki"

# Kill all kubectl port forwards
pkill -f "kubectl port-forward"

# Check if port forward is working
lsof -i :8090

# Restart port forward programmatically
PORT_FORWARD_PID=$(pgrep -f "port-forward.*argocd")
if [ -n "$PORT_FORWARD_PID" ]; then
    kill $PORT_FORWARD_PID
fi
kubectl port-forward svc/argocd-server 8090:443 -n argocd &
```

### Port Forward Best Practices

```yaml
DO:
  - Use services (svc/) instead of pods for stability
  - Use background processes (&) for automation
  - Store PIDs for clean shutdown
  - Check port availability before forwarding (lsof)
  - Use specific namespaces (-n flag)

DON'T:
  - Forward to 0.0.0.0 in production
  - Hardcode pod names (they change)
  - Leave orphaned port-forward processes
  - Use same local port for multiple services
```

### Automated Script Usage

This lab includes an automated port-forward management script:

```bash
# Start all required port forwards
./k8s/k8s-permissions_port-forward.sh start

# Check status
./k8s/k8s-permissions_port-forward.sh status

# Stop all
./k8s/k8s-permissions_port-forward.sh stop

# Restart
./k8s/k8s-permissions_port-forward.sh restart

# Cleanup orphaned processes
./k8s/k8s-permissions_port-forward.sh cleanup
```

**Managed Services**:
- Loki: localhost:31000 → logging/loki:3100
- Prometheus: localhost:30090 → monitoring/prometheus:9090
- ArgoCD: localhost:8090 → argocd/argocd-server:443

**PID Tracking**: PIDs stored in `/tmp/k8s-port-forward/*.pid`

---

## Environment Variable Reference

```bash
# Jenkins
export JENKINS_PORT=8080
export JENKINS_URL=http://localhost:${JENKINS_PORT}

# Harbor
export HARBOR_HTTP_PORT=8082
export HARBOR_HTTPS_PORT=8443
export HARBOR_REGISTRY=localhost:${HARBOR_HTTP_PORT}

# SonarQube
export SONAR_PORT=9000
export SONAR_URL=http://localhost:${SONAR_PORT}

# Grafana & Monitoring
export GRAFANA_PORT=3000
export GRAFANA_URL=http://localhost:${GRAFANA_PORT}
export LOKI_NODEPORT=31000
export LOKI_URL=http://localhost:${LOKI_NODEPORT}
export PROMETHEUS_NODEPORT=30090
export PROMETHEUS_URL=http://localhost:${PROMETHEUS_NODEPORT}
export SONAR_HOST=http://localhost:${SONAR_PORT}

# Application
export APP_PORT=8001
export APP_URL=http://localhost:${APP_PORT}

# Kubernetes
export KUBE_API_PORT=6443
export KUBE_API=https://127.0.0.1:${KUBE_API_PORT}
```

---

## Quick Reference Commands

```bash
# List all ports in use
lsof -i -P -n | grep LISTEN

# Check Docker container ports
docker ps --format "{{.Names}}: {{.Ports}}"

# Check Kubernetes service ports
kubectl get svc -o wide --all-namespaces

# Check monitoring stack
kubectl get svc -n logging
kubectl get svc -n monitoring

# Port forward to Kubernetes services
kubectl port-forward -n logging svc/loki 3100:3100
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Test connectivity
curl -v http://localhost:8001/health
curl -v http://localhost:31000/ready
curl -v http://localhost:30090/-/ready

# View Kind cluster configuration
kind get clusters
kubectl cluster-info --context kind-kind

# Check all monitoring endpoints
echo "Grafana: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/api/health)"
echo "Loki: $(curl -s http://localhost:31000/ready)"
echo "Prometheus: $(curl -s http://localhost:30090/-/ready | grep -o 'Ready')"
```

---

## Troubleshooting

### Port Already in Use

```bash
# 1. Identify the process
lsof -i :8080

# 2. Kill the process
kill -9 <PID>

# 3. Or change the service port
# Edit docker-compose.yml or service configuration
```

### Cannot Connect to Service

```bash
# 1. Verify service is running
docker ps | grep service-name

# 2. Check port binding
docker port <container-name>

# 3. Test from inside container
# Test from within container
docker exec -it <container> curl localhost:8001
```

# 4. Check firewall rules
sudo ufw status
```

### Kubernetes Service Not Accessible

```bash
# 1. Check service exists
kubectl get svc

# 2. Check endpoints
kubectl get endpoints service-name

# 3. Port forward to test
kubectl port-forward svc/service-name 8080:80

# 4. Check pod status
kubectl get pods
kubectl logs <pod-name>
```

---

## Security Considerations

1. **Localhost Only**: By default, all services bind to localhost for security
2. **Production**: Never expose these ports directly to the internet
3. **Credentials**: Use environment variables, not hardcoded passwords
4. **SSL/TLS**: Enable HTTPS for Harbor, ArgoCD in production environments
5. **Firewall**: Configure firewall rules for remote access scenarios

---

## See Also

- [Grafana & Loki Setup](Grafana-Loki.md) - Complete logging setup guide
- [Architecture Diagram](Architecture-Diagram.md) - Visual representation of service communication
- [Lab Setup Guide](#Lab-Setup-Guide.md) - Complete setup instructions
- [Troubleshooting Guide](Troubleshooting.md) - Common issues and solutions
- [Cleanup Guide](Cleanup-Guide.md) - How to tear down services
