# Security Best Practices

This guide outlines security best practices for the DevOps CI/CD Learning Laboratory environment.

---

## Table of Contents

1. [Credential Management](#credential-management)
2. [RBAC Configurations](#rbac-configurations)
3. [Kyverno Policy Enforcement](#kyverno-policy-enforcement)
4. [Network Security](#network-security)
5. [Container Security](#container-security)
6. [Secret Management](#secret-management)
7. [Access Control](#access-control)
8. [Security Monitoring](#security-monitoring)
9. [Compliance & Auditing](#compliance-auditing)
10. [Security Checklist](#security-checklist)

---

## Credential Management

### Environment Variables

**Best Practices:**
- Never commit `.env` files to version control (already in `.gitignore`)
- Always use `.env.template` as a reference
- Use strong, unique passwords for each service
- Rotate credentials regularly (see [SECURITY-Credential-Rotation.md](SECURITY-Credential-Rotation.md))

**Required Credentials:**

```bash
# Copy template and fill with secure values
cp .env.template .env

# Edit with secure credentials
vim .env
```

**Key Credentials to Configure:**

| Service | Credential Type | Environment Variable | Rotation Frequency |
|---------|----------------|---------------------|-------------------|
| GitHub | Personal Access Token | `GITHUB_TOKEN` | 90 days |
| Harbor | Robot Account Secret | `HARBOR_ROBOT_SECRET` | 60 days |
| Jenkins | Admin Password | `JENKINS_PASSWORD` | 90 days |
| SonarQube | API Token | `SONAR_TOKEN` | 90 days |
| ArgoCD | Admin Password | `ARGOCD_ADMIN_PASSWORD` | 90 days |

### Password Complexity Requirements

**Minimum Requirements:**
- Length: 12+ characters
- Contains uppercase and lowercase letters
- Contains numbers
- Contains special characters
- Not based on dictionary words

**Example Strong Password Generation:**

```bash
# Generate secure password (macOS/Linux)
openssl rand -base64 16

# Generate alphanumeric password
head -c 24 /dev/urandom | base64 | tr -d /=+
```

---

## RBAC Configurations

### Kubernetes RBAC

**Namespace-Level Access:**

The lab uses namespaces to isolate resources:

```yaml
# Example: Read-only access to app-demo namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: app-demo
  name: viewer
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
```

**ClusterRole for Policy Management:**

```yaml
# Kyverno policies require cluster-level permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kyverno-policy-viewer
rules:
- apiGroups: ["kyverno.io"]
  resources: ["clusterpolicies", "policies"]
  verbs: ["get", "list", "watch"]
```

**Service Account Best Practices:**

```yaml
# Create dedicated service accounts
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cicd-demo-app
  namespace: app-demo
---
# Bind minimal permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cicd-demo-app-binding
  namespace: app-demo
subjects:
- kind: ServiceAccount
  name: cicd-demo-app
  namespace: app-demo
roleRef:
  kind: Role
  name: app-permissions
  apiGroup: rbac.authorization.k8s.io
```

### Harbor RBAC

**Robot Account Permissions:**

Robot accounts should have minimal permissions:

```bash
# Harbor robot account should have:
# - Project: cicd-demo
# - Permissions: Pull, Push (not Delete, Admin)
# - Scope: Specific repositories only
```

**User Access Levels:**

| Role | Permissions | Use Case |
|------|------------|----------|
| Project Admin | Full control | DevOps team leads |
| Developer | Push/Pull images | CI/CD pipelines |
| Guest | Pull only | Production deployments |
| Limited Guest | Pull specific tags | Testing environments |

### Jenkins RBAC

**Jenkins Security Realms:**

```groovy
// Use project-based matrix authorization
jenkins.authorizationStrategy = new hudson.security.ProjectMatrixAuthorizationStrategy()

// Admin permissions
jenkins.authorizationStrategy.add(Jenkins.ADMINISTER, "admin")

// Read-only access for developers
jenkins.authorizationStrategy.add(Jenkins.READ, "developers")
jenkins.authorizationStrategy.add(hudson.model.Item.READ, "developers")
```

---

## Kyverno Policy Enforcement

### Policy Categories

The lab implements 5 policy categories:

#### 1. Namespace Policies (00-namespace)

**Purpose:** Protect critical namespaces and enforce metadata requirements

**Policies:**
- `namespace-prevent-deletion.yaml` - Prevents deletion of protected namespaces
- `namespace-requirements.yaml` - Requires labels on all namespaces

**Security Impact:** HIGH - Prevents accidental deletion of production namespaces

#### 2. Security Policies (10-security)

**Purpose:** Enforce container security best practices

**Policies:**
- `disallow-privileged.yaml` - Blocks privileged containers
- `require-non-root.yaml` - Requires containers run as non-root users
- `require-ro-rootfs.yaml` - Enforces read-only root filesystem

**Security Impact:** CRITICAL - Mitigates container escape attacks

**Example Violation:**

```yaml
# BAD: Privileged container (will trigger policy violation)
spec:
  containers:
  - name: app
    image: nginx
    securityContext:
      privileged: true  # VIOLATION

# GOOD: Non-privileged container
spec:
  containers:
  - name: app
    image: nginx
    securityContext:
      privileged: false
      runAsNonRoot: true
      runAsUser: 1000
      readOnlyRootFilesystem: true
```

#### 3. Resource Policies (20-resources)

**Purpose:** Enforce resource limits to prevent resource exhaustion

**Policy:**
- `require-resource-limits.yaml` - Requires CPU and memory limits

**Security Impact:** HIGH - Prevents DoS from resource exhaustion

**Example Compliant Configuration:**

```yaml
spec:
  containers:
  - name: app
    image: my-app
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
```

#### 4. Registry Policies (30-registry)

**Purpose:** Ensure all images come from trusted Harbor registry

**Policy:**
- `harbor-only-images.yaml` - Blocks images from untrusted registries

**Security Impact:** HIGH - Prevents supply chain attacks

**Allowed Images:**
- `host.docker.internal:8082/cicd-demo/*` (Harbor registry)
- `postgres:*` (Exempt for database)

**Exempted Namespaces:**
- `kube-system`, `kube-public`, `kube-node-lease`
- `kyverno`, `argocd`, `monitoring`, `logging`

#### 5. Label Policies (40-labels)

**Purpose:** Enforce consistent labeling for monitoring and governance

**Policy:**
- `add-default-labels.yaml` - Adds standard labels to all resources

**Security Impact:** MEDIUM - Improves audit trail and compliance

### Policy Validation Mode

**Current Mode: Audit**

```yaml
spec:
  validationFailureAction: Audit  # Log violations, don't block
```

**When to use Enforce mode:**

```yaml
spec:
  validationFailureAction: Enforce  # Block violations
```

Use `Enforce` mode only after:
1. Testing all policies in Audit mode
2. Fixing existing violations
3. Team training on policy requirements
4. Approval from security team

**Check Policy Violations:**

```bash
# View policy violations
kubectl get policyreport -n app-demo

# Check specific policy
kubectl describe clusterpolicy disallow-privileged-containers

# Policy Reporter UI
open http://localhost:31002
```

---

## Network Security

### Network Policies

**Principle: Default Deny, Explicit Allow**

```yaml
# Example: Restrict backend to database communication only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-netpol
  namespace: app-demo
spec:
  podSelector:
    matchLabels:
      app: cicd-demo-backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: cicd-demo-frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
```

### Port Security

**Exposed Ports (controlled):**

| Service | Port | Access | Protocol |
|---------|------|--------|----------|
| Application | 8001 | Public | HTTP |
| Jenkins | 8080 | Internal | HTTP |
| Harbor | 8082 | Internal | HTTP |
| SonarQube | 9000 | Internal | HTTP |
| ArgoCD | 8090 | Internal | HTTPS |
| Prometheus | 30090 | Internal | HTTP |
| Grafana | 3000 | Internal | HTTP |

**Port Forwarding Security:**

```bash
# Use kubectl port-forward instead of exposing via NodePort
kubectl port-forward -n app-demo svc/cicd-demo-backend 8001:8080

# Bind to localhost only (not 0.0.0.0)
kubectl port-forward --address 127.0.0.1 -n app-demo svc/jenkins 8080:8080
```

**Firewall Recommendations:**

```bash
# Allow only specific ports on localhost
# Block external access to development tools

# Example iptables rules (Linux)
iptables -A INPUT -p tcp --dport 8001 -s 127.0.0.1 -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -s 127.0.0.1 -j ACCEPT
iptables -A INPUT -p tcp --dport 8082 -s 127.0.0.1 -j ACCEPT
```

### TLS/SSL Configuration

**ArgoCD (HTTPS):**

ArgoCD uses self-signed certificates by default:

```bash
# Access ArgoCD with HTTPS
open https://localhost:8090

# Skip certificate verification (development only)
argocd login localhost:8090 --insecure
```

**Production Recommendations:**
- Use valid TLS certificates (Let's Encrypt)
- Enable HTTPS for all services
- Enforce TLS 1.2+ minimum
- Disable weak ciphers

---

## Container Security

### Image Security

**Harbor Vulnerability Scanning:**

```bash
# View vulnerabilities in Policy Reporter
open http://localhost:31002

# Check Harbor UI for scan results
open http://localhost:8082
# Navigate to: Projects > cicd-demo > Repositories > app
```

**Image Signing:**

```bash
# Sign images with Docker Content Trust (recommended for production)
export DOCKER_CONTENT_TRUST=1
docker push localhost:8082/cicd-demo/app:latest
```

### Non-Root Containers

**Best Practice: Run as unprivileged user**

```dockerfile
# Dockerfile example
FROM openjdk:21-jdk-slim

# Create non-root user
RUN useradd -r -u 1000 -g appuser appuser

# Set ownership
COPY --chown=appuser:appuser target/app.jar /app/app.jar

# Switch to non-root user
USER appuser

CMD ["java", "-jar", "/app/app.jar"]
```

**Kubernetes Security Context:**

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
```

### Read-Only Root Filesystem

**Benefits:**
- Prevents malware from modifying container filesystem
- Reduces attack surface
- Enforces immutable infrastructure

**Implementation:**

```yaml
spec:
  containers:
  - name: app
    securityContext:
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: cache
      mountPath: /app/cache
  volumes:
  - name: tmp
    emptyDir: {}
  - name: cache
    emptyDir: {}
```

---

## Secret Management

### Kubernetes Secrets

**Create Secrets Securely:**

```bash
# Create from literal values
kubectl create secret generic db-credentials \
  --from-literal=username=postgres \
  --from-literal=password=$(openssl rand -base64 16) \
  -n app-demo

# Create from files
kubectl create secret generic tls-certs \
  --from-file=tls.crt=path/to/cert.crt \
  --from-file=tls.key=path/to/cert.key \
  -n app-demo
```

**Use Secrets in Pods:**

```yaml
spec:
  containers:
  - name: app
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
```

**Secret Encryption at Rest:**

```bash
# Verify encryption provider
kubectl get secret -n kube-system -o yaml | grep encryptionConfig

# Enable encryption (requires cluster configuration)
# See: https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
```

### Jenkins Credentials

**Credential Types:**

1. **Username/Password** - Harbor robot account
2. **Secret Text** - SonarQube token, API tokens
3. **SSH Username with private key** - GitHub SSH access
4. **Secret file** - Kubeconfig files

**Access Control:**

```bash
# Bind credentials to specific jobs only
# Use folder-level credentials for project isolation
# Enable audit logging for credential usage
```

### SonarQube Tokens

**Token Management:**

```bash
# Create project-specific tokens
# Token name: jenkins-cicd-demo
# Permissions: Execute Analysis, Browse

# Revoke unused tokens immediately
# Rotate tokens every 90 days
```

---

## Access Control

### Multi-Factor Authentication (MFA)

**Recommended for:**
- GitHub accounts (required for PAT creation)
- Harbor admin accounts
- Jenkins admin accounts
- ArgoCD admin accounts

**Implementation:**

```bash
# GitHub: Settings > Security > Two-factor authentication
# Harbor: User Profile > Configure TOTP
# Jenkins: Manage Jenkins > Configure Global Security > Enable MFA plugin
# ArgoCD: argocd account update-password --account admin --enable-mfa
```

### IP Whitelisting

**Jenkins Access Control:**

```groovy
// Restrict Jenkins access to specific IP ranges
import jenkins.model.Jenkins
import hudson.security.*

def jenkins = Jenkins.getInstance()
jenkins.setAuthorizationStrategy(new GlobalMatrixAuthorizationStrategy())

// Allow specific IPs only
jenkins.setSecurityRealm(new hudson.security.HudsonPrivateSecurityRealm(false))
```

### Session Management

**Best Practices:**
- Session timeout: 30 minutes of inactivity
- Force re-authentication for sensitive operations
- Logout after completing tasks
- Use incognito mode for testing

---

## Security Monitoring

### Logging & Auditing

**Loki Log Aggregation:**

```bash
# View logs in Grafana
open http://localhost:3000

# Query logs for security events
# LogQL: {namespace="app-demo"} |= "authentication failed"
# LogQL: {namespace="app-demo"} |= "unauthorized"
```

**Kubernetes Audit Logs:**

```bash
# Check audit policy (if enabled)
kubectl get pods -n kube-system

# View audit logs
kubectl logs -n kube-system kube-apiserver-app-demo-control-plane | grep audit
```

### Policy Violations

**Policy Reporter Dashboard:**

```bash
# Open Policy Reporter UI
open http://localhost:31002

# Check violations via API
curl http://localhost:31001/v1/violations

# Get violations for specific policy
kubectl get policyreport -n app-demo -o yaml
```

**Alert on Critical Violations:**

```yaml
# Prometheus alert rule example
- alert: PrivilegedContainerDetected
  expr: kyverno_policy_results_total{policy="disallow-privileged-containers",result="fail"} > 0
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Privileged container detected in {{ $labels.namespace }}"
```

### Prometheus Metrics

**Security Metrics to Monitor:**

```promql
# Failed authentication attempts
rate(authentication_attempts_total{result="failure"}[5m])

# Unauthorized access attempts
rate(http_requests_total{status="401"}[5m])

# Policy violations by severity
kyverno_policy_results_total{severity="high",result="fail"}
```

---

## Compliance & Auditing

### Compliance Standards

**Relevant Standards:**
- CIS Kubernetes Benchmark
- NIST Cybersecurity Framework
- OWASP Container Security Top 10
- PCI DSS (if applicable)

### Audit Checklist

**Monthly Security Audit:**

- [ ] Review all active credentials and rotate if needed
- [ ] Check for unused user accounts in all services
- [ ] Review RBAC permissions for least privilege
- [ ] Audit Kyverno policy violations
- [ ] Review Harbor vulnerability scan results
- [ ] Check for outdated container images
- [ ] Review network policies and firewall rules
- [ ] Validate TLS certificates (expiration dates)
- [ ] Review access logs for suspicious activity
- [ ] Update security documentation

### Compliance Reports

**Generate Compliance Reports:**

```bash
# Kyverno policy report
kubectl get clusterpolicyreport -o yaml > compliance-report.yaml

# Harbor vulnerability report
# Navigate to: Projects > cicd-demo > Reports

# SonarQube quality gate report
# Access via: http://localhost:9000/dashboard?id=cicd-demo
```

---

## Security Checklist

### Initial Setup

- [ ] Change all default passwords
- [ ] Create `.env` file from template with strong passwords
- [ ] Enable MFA on GitHub account
- [ ] Configure RBAC for all services
- [ ] Review and understand all Kyverno policies
- [ ] Enable Harbor vulnerability scanning
- [ ] Configure network policies
- [ ] Set up audit logging
- [ ] Configure TLS/SSL for production services
- [ ] Review firewall rules

### Ongoing Operations

- [ ] Rotate credentials every 60-90 days
- [ ] Review policy violations weekly
- [ ] Update container images monthly
- [ ] Check for CVEs in dependencies
- [ ] Review access logs for anomalies
- [ ] Backup secrets and configurations
- [ ] Test disaster recovery procedures
- [ ] Update security documentation
- [ ] Train team on security best practices
- [ ] Perform security audits quarterly

### Before Production Deployment

- [ ] Switch Kyverno policies from Audit to Enforce mode
- [ ] Enable secrets encryption at rest
- [ ] Configure production-grade TLS certificates
- [ ] Implement network segmentation
- [ ] Enable comprehensive audit logging
- [ ] Configure automated security scanning
- [ ] Set up security monitoring and alerting
- [ ] Perform penetration testing
- [ ] Create incident response plan
- [ ] Obtain security team approval

---

## Related Documentation

- [SECURITY-Credential-Rotation.md](SECURITY-Credential-Rotation.md) - Credential rotation procedures
- [KYVERNO-Policy-CheatSheet.md](KYVERNO-Policy-CheatSheet.md) - Kyverno policy quick reference
- [Port-Reference.md](Port-Reference.md) - Port mappings and network access
- [Troubleshooting.md](Troubleshooting.md) - Security-related troubleshooting
- [k8s/kyverno/README.md](../k8s/kyverno/README.md) - Kyverno setup and configuration

---

**Maintained by**: DevOps Lab Team
**Last Updated**: 2026-03-10
**Review Frequency**: Quarterly or when security incidents occur
