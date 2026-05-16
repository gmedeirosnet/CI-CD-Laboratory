# README Manual Setup Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the duplicate "Manual Setup Steps" subsection from README.md and replace it with a single pointer line to `docs/Lab-Setup-Guide.md`.

**Architecture:** Single-file edit — delete ~57 lines from README.md and insert one sentence in their place. No logic, no tests, no dependencies.

**Tech Stack:** Markdown, git

---

### Task 1: Edit README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Remove the "Manual Setup Steps" subsection**

In `README.md`, locate and delete the following block in its entirety (from the heading through the end of step 5):

```
### Manual Setup Steps

If you prefer step-by-step setup:

1. **Verify Prerequisites**
   ```bash
   ./scripts/verify-environment.sh
   ```

2. **Configure Environment**
   ```bash
   # Copy environment template and configure your credentials
   cp .env.template .env

   # Edit .env with your values:
   # - GitHub username and personal access token
   # - Harbor registry credentials
   # - Jenkins admin password
   # - SonarQube token
   # - ArgoCD admin password
   # - Other service credentials

   # IMPORTANT: Never commit .env to version control
   nano .env  # or use your preferred editor
   ```

3. **Create Kind Cluster**
   ```bash
   kind create cluster --config kind-config.yaml
   ```

4. **Start Services**
   ```bash
   # Harbor
   cd harbor && docker-compose up -d

   # Jenkins
   ./scripts/setup-jenkins-docker.sh

   # SonarQube
   ./scripts/setup-sonarqube.sh

   # Grafana + Loki + Prometheus
   cd k8s/grafana
   ./setup-loki.sh
   ./setup-prometheus.sh
   ./setup-grafana-docker.sh

   # ArgoCD
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

5. **Build Application**
   ```bash
   mvn clean package
   ```
```

- [ ] **Step 2: Add pointer line**

In the same location where the removed block was (between the port forwarding management block and the "### First Steps After Setup" heading), insert:

```
For manual step-by-step setup, see [Lab Setup Guide](docs/Lab-Setup-Guide.md).
```

The result should look like this in context:

```markdown
**Port Forwarding Management:**
```bash
# Check status of all port forwards
./k8s/k8s-permissions_port-forward.sh status

# Stop all port forwards
./k8s/k8s-permissions_port-forward.sh stop

# Restart all port forwards
./k8s/k8s-permissions_port-forward.sh restart
```

For manual step-by-step setup, see [Lab Setup Guide](docs/Lab-Setup-Guide.md).

### First Steps After Setup
```

- [ ] **Step 3: Verify the change visually**

Open `README.md` and confirm:
- The `### Manual Setup Steps` heading is gone
- The five numbered steps and all their code blocks are gone
- The pointer line appears between the port forwarding block and "### First Steps After Setup"
- No other sections were accidentally removed

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: remove duplicate manual setup steps from README, link to Lab-Setup-Guide"
```
