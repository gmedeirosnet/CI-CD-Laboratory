# Kyverno Policy CheatSheet

Quick reference guide for Kyverno policies in the DevOps CI/CD Learning Laboratory.

---

## Table of Contents

1. [Quick Commands](#quick-commands)
2. [Policy Overview](#policy-overview)
3. [Policy Categories](#policy-categories)
4. [Common Use Cases](#common-use-cases)
5. [Troubleshooting Policies](#troubleshooting-policies)
6. [Policy Templates](#policy-templates)
7. [Best Practices](#best-practices)

---

## Quick Commands

### View Policies

```bash
# List all cluster policies
kubectl get clusterpolicies

# List policies in namespace
kubectl get policies -n app-demo

# Describe specific policy
kubectl describe clusterpolicy disallow-privileged-containers

# View policy in YAML
kubectl get clusterpolicy require-non-root -o yaml
```

### Check Policy Reports

```bash
# View policy reports for namespace
kubectl get policyreport -n app-demo

# View cluster-level policy reports
kubectl get clusterpolicyreport

# Describe report (shows violations)
kubectl describe policyreport -n app-demo

# Get violations in JSON
kubectl get policyreport -n app-demo -o json | jq '.results[] | select(.result=="fail")'
```

### Policy Reporter UI

```bash
# Open Policy Reporter dashboard
open http://localhost:31002

# Query violations via API
curl http://localhost:31001/v1/violations

# Get violations for specific policy
curl http://localhost:31001/v1/violations?policy=disallow-privileged-containers
```

### Apply/Update Policies

```bash
# Apply single policy
kubectl apply -f k8s/kyverno/policies/10-security/disallow-privileged.yaml

# Apply all policies in directory
kubectl apply -f k8s/kyverno/policies/

# Update policy (edit and apply)
kubectl edit clusterpolicy harbor-registry-only

# Delete policy
kubectl delete clusterpolicy disallow-privileged-containers
```

### Test Policies

```bash
# Dry-run test a manifest against policies
kubectl create -f test-pod.yaml --dry-run=server

# Apply policy in dry-run mode
kubectl apply -f policy.yaml --dry-run=server

# Test with kubectl-kyverno plugin
kubectl kyverno test policy.yaml --resource test-pod.yaml
```

---

## Policy Overview

### All Policies at a Glance

| # | Policy Name | Category | Severity | Mode | Description |
|---|------------|----------|----------|------|-------------|
| 1 | `namespace-prevent-deletion` | Namespace | high | Audit | Prevents deletion of protected namespaces |
| 2 | `namespace-requirements` | Namespace | medium | Audit | Requires labels on all namespaces |
| 3 | `disallow-privileged-containers` | Security | high | Audit | Blocks privileged containers |
| 4 | `require-non-root` | Security | high | Audit | Requires containers run as non-root |
| 5 | `require-ro-rootfs` | Security | medium | Audit | Enforces read-only root filesystem |
| 6 | `require-resource-limits` | Resources | medium | Audit | Requires CPU/memory limits |
| 7 | `harbor-registry-only` | Registry | high | Audit | Enforces Harbor registry images |
| 8 | `add-default-labels` | Labels | low | Audit | Adds standard labels to resources |

### Policy Locations

```
k8s/kyverno/policies/
├── 00-namespace/
│   ├── namespace-prevent-deletion.yaml
│   └── namespace-requirements.yaml
├── 10-security/
│   ├── disallow-privileged.yaml
│   ├── require-non-root.yaml
│   └── require-ro-rootfs.yaml
├── 20-resources/
│   └── require-resource-limits.yaml
├── 30-registry/
│   └── harbor-only-images.yaml
└── 40-labels/
    └── add-default-labels.yaml
```

---

## Policy Categories

### 00-namespace: Namespace Policies

#### namespace-prevent-deletion

**Purpose:** Prevent accidental deletion of critical namespaces

**Protected Namespaces:**
- `kube-system`
- `kube-public`
- `kube-node-lease`
- `app-demo`
- `argocd`
- `kyverno`

**Violation Example:**

```bash
# This will fail (in Enforce mode)
kubectl delete namespace app-demo

# Error: admission webhook "validate.kyverno.svc" denied the request
```

**Policy Snippet:**

```yaml
validate:
  message: "Deletion of namespace {{ request.object.metadata.name }} is not allowed"
  deny:
    conditions:
      all:
      - key: "{{ request.object.metadata.name }}"
        operator: In
        value: ["kube-system", "app-demo", "argocd", "kyverno"]
```

#### namespace-requirements

**Purpose:** Ensure all namespaces have required labels

**Required Labels:**
- `team` - Team owning the namespace
- `environment` - Environment type (dev, staging, prod)

**Compliant Example:**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-app
  labels:
    team: platform
    environment: dev
```

**Non-Compliant Example:**

```yaml
# Missing required labels
apiVersion: v1
kind: Namespace
metadata:
  name: my-app
```

---

### 10-security: Security Policies

#### disallow-privileged-containers

**Purpose:** Block containers running in privileged mode

**Impact:** HIGH - Prevents container escape attacks

**Violation Example:**

```yaml
# BAD: Privileged container
spec:
  containers:
  - name: app
    image: nginx
    securityContext:
      privileged: true  # ❌ VIOLATION
```

**Compliant Example:**

```yaml
# GOOD: Non-privileged container
spec:
  containers:
  - name: app
    image: nginx
    securityContext:
      privileged: false  # ✅ COMPLIANT
```

**Why This Matters:**
- Privileged containers have access to all Linux capabilities
- Can access host devices and kernel features
- Major security risk in multi-tenant environments

#### require-non-root

**Purpose:** Enforce containers run as non-root users

**Impact:** HIGH - Reduces attack surface

**Violation Example:**

```yaml
# BAD: Running as root
spec:
  containers:
  - name: app
    image: nginx
    # No securityContext = runs as root (UID 0)
```

**Compliant Example:**

```yaml
# GOOD: Running as non-root user
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
  containers:
  - name: app
    image: nginx
    securityContext:
      runAsUser: 1000
      allowPrivilegeEscalation: false
```

**Why This Matters:**
- Root user inside container = root on host (if container escapes)
- Non-root limits damage from compromised containers
- Best practice for defense in depth

#### require-ro-rootfs

**Purpose:** Enforce read-only root filesystem

**Impact:** MEDIUM - Prevents malware persistence

**Violation Example:**

```yaml
# BAD: Writable root filesystem
spec:
  containers:
  - name: app
    image: nginx
    # No readOnlyRootFilesystem = writable
```

**Compliant Example:**

```yaml
# GOOD: Read-only root filesystem with temp volumes
spec:
  containers:
  - name: app
    image: nginx
    securityContext:
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: cache
      mountPath: /var/cache/nginx
  volumes:
  - name: tmp
    emptyDir: {}
  - name: cache
    emptyDir: {}
```

**Why This Matters:**
- Prevents attackers from modifying container filesystem
- Malware can't persist across container restarts
- Enforces immutable infrastructure

---

### 20-resources: Resource Policies

#### require-resource-limits

**Purpose:** Ensure all containers have resource limits

**Impact:** MEDIUM - Prevents resource exhaustion DoS

**Violation Example:**

```yaml
# BAD: No resource limits
spec:
  containers:
  - name: app
    image: nginx
    # No resources defined = unlimited usage
```

**Compliant Example:**

```yaml
# GOOD: Resource limits defined
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
```

**Why This Matters:**
- Prevents noisy neighbor problems
- Ensures fair resource allocation
- Protects against resource-based DoS attacks

**Recommended Limits:**

| App Type | CPU Request | CPU Limit | Memory Request | Memory Limit |
|----------|------------|-----------|----------------|--------------|
| Frontend | 100m | 500m | 128Mi | 512Mi |
| Backend API | 250m | 1000m | 256Mi | 1Gi |
| Database | 500m | 2000m | 512Mi | 2Gi |
| Worker/Job | 200m | 800m | 256Mi | 1Gi |

---

### 30-registry: Registry Policies

#### harbor-registry-only

**Purpose:** Enforce all images come from Harbor registry

**Impact:** HIGH - Prevents supply chain attacks

**Allowed Image Patterns:**
- `host.docker.internal:8082/cicd-demo/*` (Harbor registry)
- `postgres:*` (Exempt for database)

**Exempted Namespaces:**
- `kube-system`, `kube-public`, `kube-node-lease`
- `kyverno`, `argocd`, `monitoring`, `logging`

**Violation Example:**

```yaml
# BAD: Image from Docker Hub
spec:
  containers:
  - name: app
    image: nginx:latest  # ❌ VIOLATION - not from Harbor
```

**Compliant Example:**

```yaml
# GOOD: Image from Harbor registry
spec:
  containers:
  - name: app
    image: host.docker.internal:8082/cicd-demo/app:latest  # ✅ COMPLIANT
```

**Why This Matters:**
- Harbor scans images for vulnerabilities
- Ensures only approved images are deployed
- Prevents malicious images from unknown sources

**Exemption for PostgreSQL:**

```yaml
# PostgreSQL is exempt (uses official image)
spec:
  containers:
  - name: postgres
    image: postgres:16  # ✅ COMPLIANT (exempt)
```

---

### 40-labels: Label Policies

#### add-default-labels

**Purpose:** Automatically add standard labels to resources

**Impact:** LOW - Improves observability

**Labels Added:**
- `managed-by: kyverno`
- `environment: dev`
- `lab: cicd-demo`

**Example Mutation:**

```yaml
# Before mutation
apiVersion: v1
kind: Pod
metadata:
  name: my-app

# After mutation
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  labels:
    managed-by: kyverno
    environment: dev
    lab: cicd-demo
```

**Why This Matters:**
- Consistent labeling for monitoring/alerting
- Easier to query and filter resources
- Supports compliance requirements

---

## Common Use Cases

### Fix Privileged Container Violation

**Violation:**

```
Policy: disallow-privileged-containers
Message: Privileged mode is not allowed
```

**Fix:**

```yaml
# Remove or set to false
securityContext:
  privileged: false
```

### Fix Non-Root Violation

**Violation:**

```
Policy: require-non-root
Message: Container must run as non-root user
```

**Fix:**

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
  containers:
  - name: app
    securityContext:
      runAsUser: 1000
```

### Fix Resource Limits Violation

**Violation:**

```
Policy: require-resource-limits
Message: Resource limits are required
```

**Fix:**

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### Fix Harbor Registry Violation

**Violation:**

```
Policy: harbor-registry-only
Message: Image 'nginx:latest' is not from Harbor
```

**Fix Option 1 - Push image to Harbor:**

```bash
# Pull from Docker Hub
docker pull nginx:latest

# Tag for Harbor
docker tag nginx:latest localhost:8082/cicd-demo/nginx:latest

# Push to Harbor
docker push localhost:8082/cicd-demo/nginx:latest

# Update manifest
image: host.docker.internal:8082/cicd-demo/nginx:latest
```

**Fix Option 2 - Add exemption:**

```yaml
# Add label to pod for exemption
metadata:
  labels:
    app: postgres  # This label exempts from policy
```

---

## Troubleshooting Policies

### Policy Not Working

**Check policy installation:**

```bash
kubectl get clusterpolicy disallow-privileged-containers
```

**Check Kyverno is running:**

```bash
kubectl get pods -n kyverno
```

**Check webhook configuration:**

```bash
kubectl get validatingwebhookconfigurations | grep kyverno
```

### Violations Not Showing

**Check validation mode:**

```yaml
spec:
  validationFailureAction: Audit  # Logs violations
  # vs
  validationFailureAction: Enforce  # Blocks deployments
```

**View policy reports:**

```bash
kubectl get policyreport -n app-demo
```

**Check Policy Reporter:**

```bash
open http://localhost:31002
```

### Policy Blocking Legitimate Deployments

**Option 1 - Add namespace exemption:**

```yaml
exclude:
  any:
  - resources:
      namespaces:
      - my-namespace
```

**Option 2 - Add label exemption:**

```yaml
exclude:
  any:
  - resources:
      selector:
        matchLabels:
          exempt-from-policy: "true"
```

**Option 3 - Switch to Audit mode:**

```yaml
spec:
  validationFailureAction: Audit
```

### Check Specific Resource Compliance

```bash
# Test if resource would pass policies
kubectl apply -f my-pod.yaml --dry-run=server

# Check existing resource violations
kubectl describe policyreport -n app-demo | grep -A 5 "my-pod"
```

---

## Policy Templates

### Create Custom Security Policy

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: my-security-policy
  annotations:
    policies.kyverno.io/title: My Security Policy
    policies.kyverno.io/category: Security
    policies.kyverno.io/severity: high
    policies.kyverno.io/description: Custom security requirement
spec:
  validationFailureAction: Audit
  background: true
  rules:
  - name: my-rule
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Custom validation failed"
      pattern:
        spec:
          containers:
          - securityContext:
              runAsNonRoot: true
```

### Create Mutation Policy

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-security-context
spec:
  rules:
  - name: add-runAsNonRoot
    match:
      any:
      - resources:
          kinds:
          - Pod
    mutate:
      patchStrategicMerge:
        spec:
          securityContext:
            runAsNonRoot: true
```

### Create Generate Policy

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: generate-network-policy
spec:
  rules:
  - name: generate-default-deny
    match:
      any:
      - resources:
          kinds:
          - Namespace
    generate:
      kind: NetworkPolicy
      name: default-deny
      namespace: "{{ request.object.metadata.name }}"
      data:
        spec:
          podSelector: {}
          policyTypes:
          - Ingress
          - Egress
```

---

## Best Practices

### Policy Development

1. **Start in Audit Mode**
   - Test policies without blocking deployments
   - Identify false positives
   - Train team on requirements

2. **Use Meaningful Names**
   - `disallow-privileged-containers` (good)
   - `security-policy-1` (bad)

3. **Add Clear Messages**
   ```yaml
   message: >-
     Privileged mode is not allowed.
     Remove securityContext.privileged or set to false.

     Why: Containers should run with minimal privileges.
   ```

4. **Document Exemptions**
   ```yaml
   exclude:
     any:
     - resources:
         namespaces:
         - kube-system  # System components need privileges
   ```

### Policy Organization

1. **Use Numbered Directories**
   ```
   00-namespace/  # Applied first
   10-security/   # Security controls
   20-resources/  # Resource management
   30-registry/   # Registry enforcement
   40-labels/     # Labeling and metadata
   ```

2. **One Policy Per File**
   - Easier to manage
   - Clear ownership
   - Simpler testing

3. **Consistent Naming**
   - `category-action-target.yaml`
   - `security-require-non-root.yaml`
   - `registry-harbor-only-images.yaml`

### Testing Policies

1. **Create Test Cases**
   ```bash
   k8s/kyverno/tests/
   ├── valid/
   │   └── compliant-pod.yaml
   └── invalid/
       └── privileged-pod.yaml
   ```

2. **Automate Testing**
   ```bash
   # Test valid resources
   kubectl create -f tests/valid/ --dry-run=server

   # Test invalid resources (should fail)
   kubectl create -f tests/invalid/ --dry-run=server
   ```

3. **Use Policy Reporter**
   - Monitor violations in real-time
   - Analyze trends
   - Generate compliance reports

### Performance Optimization

1. **Exclude System Namespaces**
   ```yaml
   exclude:
     any:
     - resources:
         namespaces:
         - kube-system
         - kube-public
   ```

2. **Use Background: False for Generate Policies**
   ```yaml
   spec:
     background: false  # Don't scan existing resources
   ```

3. **Limit Match Scope**
   ```yaml
   match:
     any:
     - resources:
         kinds:
         - Pod  # Only pods, not all resources
         namespaces:
         - app-demo  # Only specific namespace
   ```

### Migration to Enforce Mode

**Step-by-step process:**

1. **Deploy in Audit Mode** (Week 1-2)
   ```yaml
   validationFailureAction: Audit
   ```

2. **Fix All Violations** (Week 3-4)
   ```bash
   kubectl get policyreport -A
   # Address all violations
   ```

3. **Enable Enforce Mode** (Week 5)
   ```yaml
   validationFailureAction: Enforce
   ```

4. **Monitor and Adjust** (Ongoing)
   - Add exemptions as needed
   - Update policies based on feedback

---

## Quick Reference Card

### Essential Commands

```bash
# View all policies
kubectl get clusterpolicies

# Check violations
kubectl get policyreport -n app-demo

# Test manifest
kubectl apply -f pod.yaml --dry-run=server

# Open dashboard
open http://localhost:31002

# Apply policy
kubectl apply -f policy.yaml

# Describe policy
kubectl describe clusterpolicy policy-name
```

### Validation Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| `Audit` | Log violations, allow deployment | Testing, development |
| `Enforce` | Block non-compliant resources | Production |

### Policy Categories

| # | Category | Purpose | Priority |
|---|----------|---------|----------|
| 00 | Namespace | Protect namespaces | HIGH |
| 10 | Security | Container security | CRITICAL |
| 20 | Resources | Resource limits | MEDIUM |
| 30 | Registry | Image provenance | HIGH |
| 40 | Labels | Metadata | LOW |

---

## Related Documentation

- [SECURITY-BestPractices.md](SECURITY-BestPractices.md) - Security best practices
- [k8s/kyverno/README.md](../k8s/kyverno/README.md) - Kyverno setup guide
- [Troubleshooting.md](Troubleshooting.md) - Policy troubleshooting
- [Kyverno Official Docs](https://kyverno.io/docs/) - Kyverno documentation

---

**Maintained by**: DevOps Lab Team
**Last Updated**: 2026-03-10
**Version**: 1.0 (Audit Mode)
