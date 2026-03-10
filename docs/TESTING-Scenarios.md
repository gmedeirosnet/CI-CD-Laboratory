# Testing Scenarios

Detailed test scenario descriptions for the DevOps CI/CD Learning Laboratory.

## Table of Contents

- [Deployment Test Scenarios](#deployment-test-scenarios)
- [Integration Test Scenarios](#integration-test-scenarios)
- [Performance Test Scenarios](#performance-test-scenarios)
- [Database Test Scenarios](#database-test-scenarios)
- [Security Test Scenarios](#security-test-scenarios)
- [Failure and Recovery Scenarios](#failure-and-recovery-scenarios)
- [Load Test Scenarios](#load-test-scenarios)
- [End-to-End User Scenarios](#end-to-end-user-scenarios)

## Deployment Test Scenarios

### Scenario 1: PostgreSQL Deployment Validation

**Objective**: Verify PostgreSQL StatefulSet deploys correctly with all security and operational configurations.

**Prerequisites**:
- Kind cluster running
- Namespace `app-demo` exists
- Helm chart available

**Test Steps**:
1. Check StatefulSet exists
2. Verify pod is in Running state
3. Verify pod is Ready (1/1)
4. Check service is created
5. Verify PVC is Bound
6. Test database connectivity (`pg_isready`)
7. Verify database exists and accessible
8. Check user permissions

**Expected Results**:
- StatefulSet: `postgres` exists
- Pod: `postgres-0` Running, Ready
- Service: `postgres` ClusterIP on port 5432
- PVC: `postgres-pvc` Bound, 2Gi
- Database: `cicd_demo` accessible by `app_user`

**Pass Criteria**: All 8 checks pass

**Script**: `scripts/test-deployment.sh` (Tests 1-8)

---

### Scenario 2: Security Context Validation

**Objective**: Ensure PostgreSQL pod runs with proper security contexts (non-root, fsGroup).

**Test Steps**:
1. Verify pod runs as UID 999 (non-root)
2. Verify fsGroup is set to 999
3. Check resource limits are configured
4. Verify liveness probe is configured
5. Verify readiness probe is configured

**Expected Results**:
- Pod UID: 999
- fsGroup: 999
- Resource limits: CPU and Memory defined
- Liveness probe: `pg_isready -U app_user`
- Readiness probe: `pg_isready -U app_user`

**Pass Criteria**: All 5 security checks pass

**Script**: `scripts/test-deployment.sh` (Tests 9-13)

---

### Scenario 3: Database Functionality Validation

**Objective**: Verify full CRUD operations work in PostgreSQL.

**Test Steps**:
1. Create test table
2. Insert data into table
3. Query data from table
4. Drop table
5. Verify schema is clean (ready for Flyway migrations)

**SQL Commands**:
```sql
CREATE TABLE IF NOT EXISTS test_table (id INT);
INSERT INTO test_table VALUES (1);
SELECT * FROM test_table;
DROP TABLE test_table;
SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';
```

**Expected Results**:
- Table created successfully
- Data inserted successfully
- Data retrieved successfully
- Table dropped successfully
- Schema is empty (0 tables)

**Pass Criteria**: All 5 functionality tests pass

**Script**: `scripts/test-deployment.sh` (Tests 14-18)

---

## Integration Test Scenarios

### Scenario 4: Full-Stack Health Check

**Objective**: Verify all layers of the application stack are healthy and accessible.

**Architecture Layers**:
1. Infrastructure (Kind cluster, Kubernetes nodes)
2. Database (PostgreSQL)
3. Backend (Spring Boot)
4. Frontend (React/Nginx)

**Test Steps**:
1. Verify Kind cluster is running
2. Check all nodes are Ready
3. Verify namespace exists with labels
4. Check PostgreSQL is running and accepting connections
5. Verify backend deployment exists and pods are running
6. Check backend health endpoint: `/actuator/health`
7. Verify frontend deployment exists and pods are running
8. Check frontend web server responds (HTTP 200)

**Expected Results**:
- Kind cluster: Running
- Nodes: All Ready
- PostgreSQL: Running, accepting connections
- Backend: Running, health check returns `{"status":"UP"}`
- Frontend: Running, returns HTML page

**Pass Criteria**: All layers healthy

**Script**: `scripts/test-integration.sh` (Tests 1-15)

---

### Scenario 5: Data Persistence and Cross-Layer Communication

**Objective**: Verify data flows correctly from frontend through backend to database and persists.

**Test Steps**:
1. Backend can connect to PostgreSQL
2. Frontend can reach backend API endpoints
3. Create test data in database via SQL
4. Retrieve test data to verify persistence
5. Cleanup test data

**Data Flow**:
```
Frontend (React) → Backend (Spring Boot) → Database (PostgreSQL)
```

**Test Queries**:
```sql
-- Create test data
CREATE TABLE IF NOT EXISTS integration_test (
    id SERIAL PRIMARY KEY,
    test_value TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
INSERT INTO integration_test (test_value) VALUES ('e2e-test-123456');

-- Verify data
SELECT COUNT(*) FROM integration_test;

-- Cleanup
DROP TABLE IF EXISTS integration_test;
```

**Expected Results**:
- Backend connects to database successfully
- Frontend API calls succeed (HTTP 200)
- Test data persists across queries
- Cleanup completes successfully

**Pass Criteria**: Data persists and is retrievable

**Script**: `scripts/test-integration.sh` (Tests 16-20)

---

### Scenario 6: CI/CD Pipeline Component Availability

**Objective**: Verify all CI/CD pipeline components are accessible.

**Components to Test**:
1. Jenkins (CI/CD orchestration)
2. Harbor (Container registry)
3. SonarQube (Code quality)
4. ArgoCD (GitOps deployment)

**Test Steps**:
1. Test Jenkins accessibility: `curl http://localhost:8080` → HTTP 403 (auth required)
2. Test Harbor accessibility: `curl http://localhost:8082` → HTTP 200
3. Test SonarQube accessibility: `curl http://localhost:9000` → HTTP 200
4. Test ArgoCD accessibility: `curl -k https://localhost:8090` → HTTP 200/301/302

**Expected Results**:
- Jenkins: HTTP 403 (login page)
- Harbor: HTTP 200 (login page)
- SonarQube: HTTP 200 (dashboard)
- ArgoCD: HTTP 200/301/302 (UI)

**Pass Criteria**: All 4 services accessible

**Script**: `scripts/test-integration.sh` (Tests 21-24)

---

### Scenario 7: Policy Enforcement and Security

**Objective**: Verify Kyverno policies are enforced and violations are tracked.

**Test Steps**:
1. Verify Kyverno is installed and running
2. Check cluster policies are loaded
3. Test Policy Reporter UI is accessible
4. Verify all pods run as non-root
5. Verify all pods have resource limits

**Policies to Check**:
- `harbor-only-images` - Only Harbor images allowed
- `require-non-root` - No root containers
- `require-resource-limits` - CPU/memory limits required
- `disallow-privileged` - No privileged containers
- `require-ro-rootfs` - Read-only root filesystem

**Expected Results**:
- Kyverno deployment: Running
- Policies loaded: 5+ cluster policies
- Policy Reporter: HTTP 200
- All pods: non-root (runAsNonRoot: true)
- All pods: resource limits defined

**Pass Criteria**: All 5 security checks pass

**Script**: `scripts/test-integration.sh` (Tests 25-29)

---

### Scenario 8: Monitoring and Observability

**Objective**: Ensure monitoring stack is operational and collecting metrics.

**Components**:
1. Prometheus (Metrics collection)
2. Grafana (Visualization)
3. Loki (Log aggregation)

**Test Steps**:
1. Verify Prometheus is accessible
2. Verify Grafana is accessible
3. Verify Loki is accessible
4. Check Prometheus is scraping targets (health: up)

**Expected Results**:
- Prometheus: http://localhost:30090 → HTTP 200
- Grafana: http://localhost:3000 → HTTP 200
- Loki: http://localhost:31000/ready → HTTP 200
- Prometheus targets: At least 1 target with `"health":"up"`

**Pass Criteria**: All 4 monitoring components operational

**Script**: `scripts/test-integration.sh` (Tests 30-33)

---

### Scenario 9: Network Connectivity

**Objective**: Validate cluster networking and DNS resolution.

**Test Steps**:
1. Test DNS resolution within cluster
2. Test pod-to-pod communication
3. Test external connectivity from pods

**Test Commands**:
```bash
# DNS resolution
kubectl run dns-test --image=busybox:1.28 --rm -it --restart=Never -- \
  nslookup kubernetes.default

# Pod-to-pod communication
kubectl exec -n app-demo postgres-0 -- nc -zv postgres 5432

# External connectivity
kubectl run connectivity-test --image=curlimages/curl:latest --rm -it --restart=Never -- \
  curl -s https://www.google.com
```

**Expected Results**:
- DNS: `kubernetes.default` resolves successfully
- Pod-to-Pod: Connection to postgres:5432 succeeds
- External: Google homepage retrieved

**Pass Criteria**: All 3 connectivity tests pass

**Script**: `scripts/test-integration.sh` (Tests 34-36)

---

## Performance Test Scenarios

### Scenario 10: Response Time Baseline

**Objective**: Establish baseline response times for key endpoints.

**Endpoints to Test**:
1. `/actuator/health` - Health check
2. `/actuator/info` - Application info
3. `/actuator/prometheus` - Metrics endpoint
4. Frontend homepage

**Test Method**:
- Run 10 requests per endpoint
- Calculate average response time
- Compare against threshold (1.0s)

**Expected Results**:
| Endpoint | Target | Threshold |
|----------|--------|-----------|
| /actuator/health | <100ms | <1.0s |
| /actuator/info | <200ms | <1.0s |
| /actuator/prometheus | <300ms | <1.0s |
| Frontend | <500ms | <1.0s |

**Pass Criteria**: All endpoints respond within threshold

**Script**: `scripts/test-performance.sh` (Test 1)

---

### Scenario 11: Database Query Performance

**Objective**: Measure database query execution time and concurrent connection handling.

**Test Steps**:
1. Simple query test: `SELECT COUNT(*) FROM pg_stat_activity;`
2. Concurrent connections test: 10 simultaneous queries
3. Database size check
4. Active connections count

**Expected Results**:
- Simple query: <100ms
- 10 concurrent queries: <2s total
- Database size: Reasonable (<100MB for empty database)
- Active connections: <10

**Pass Criteria**: Query times within acceptable range

**Script**: `scripts/test-performance.sh` (Test 2)

---

### Scenario 12: Load Testing with Apache Bench

**Objective**: Measure application throughput under load.

**Configuration**:
- Warmup: 50 requests
- Load test: 500 requests
- Concurrent users: 10
- Target endpoint: `/actuator/health`

**Test Command**:
```bash
ab -n 500 -c 10 http://localhost:8001/actuator/health
```

**Metrics to Collect**:
- Requests per second
- Time per request (mean)
- Failed requests

**Expected Results**:
- Requests per second: >100
- Time per request: <100ms
- Failed requests: 0

**Pass Criteria**: Throughput >100 req/s with 0 failures

**Script**: `scripts/test-performance.sh` (Test 3)

---

### Scenario 13: Resource Usage Metrics

**Objective**: Monitor pod resource consumption during normal operations.

**Metrics to Collect**:
- CPU limit (per pod)
- Memory limit (per pod)
- Restart count (per pod)

**Test Steps**:
1. List all pods in namespace
2. Get CPU and memory limits for each pod
3. Check restart count for each pod

**Expected Results**:
- CPU limits: Defined (e.g., 500m)
- Memory limits: Defined (e.g., 512Mi)
- Restart count: 0

**Pass Criteria**: All pods have limits defined, 0 restarts

**Script**: `scripts/test-performance.sh` (Test 4)

---

### Scenario 14: Cluster Health Metrics

**Objective**: Validate cluster-level health indicators.

**Metrics to Collect**:
- Total nodes
- Ready nodes
- Total pods in namespace
- Running pods
- Total PVCs
- Bound PVCs

**Expected Results**:
- All nodes: Ready
- All pods: Running
- All PVCs: Bound

**Pass Criteria**: 100% of nodes, pods, and PVCs healthy

**Script**: `scripts/test-performance.sh` (Test 5)

---

### Scenario 15: API Endpoint Performance

**Objective**: Measure response time, status, and size for API endpoints.

**Endpoints to Test**:
1. `/api/users` - User list API
2. `/api/products` - Product list API
3. `/actuator/health` - Health check
4. `/actuator/metrics` - Metrics endpoint

**Metrics per Endpoint**:
- HTTP status code
- Response time (seconds)
- Response size (bytes)

**Expected Results**:
- HTTP status: 200 (or 404 if endpoint not implemented)
- Response time: <1s
- Response size: >0 bytes

**Pass Criteria**: All endpoints respond within 1s

**Script**: `scripts/test-performance.sh` (Test 6)

---

## Database Test Scenarios

### Scenario 16: Connection Pool Configuration

**Objective**: Verify PostgreSQL connection pool settings.

**Settings to Check**:
1. `max_connections` - Maximum concurrent connections
2. `shared_buffers` - Shared memory for caching
3. `work_mem` - Memory per query operation

**Test Commands**:
```sql
SHOW max_connections;
SHOW shared_buffers;
SHOW work_mem;
```

**Expected Results**:
- max_connections: >=100
- shared_buffers: Appropriate for workload
- work_mem: Appropriate for workload

**Pass Criteria**: All configuration values retrieved successfully

**Script**: `scripts/test-db-pool.sh` (Test 1)

---

### Scenario 17: Current Connection Statistics

**Objective**: Monitor active database connections and their states.

**Queries**:
```sql
-- Active connections to cicd_demo
SELECT count(*) FROM pg_stat_activity WHERE datname='cicd_demo';

-- Idle connections
SELECT count(*) FROM pg_stat_activity WHERE datname='cicd_demo' AND state='idle';

-- Connections by state
SELECT state, count(*) FROM pg_stat_activity WHERE datname='cicd_demo' GROUP BY state;
```

**Expected Results**:
- Active connections: >0
- Idle connections: Reasonable number
- Connection states: idle, active, idle in transaction

**Pass Criteria**: Connection statistics retrieved successfully

**Script**: `scripts/test-db-pool.sh` (Test 2)

---

### Scenario 18: Connection Pool Capacity

**Objective**: Test database handling of concurrent connections.

**Test Configuration**:
- Concurrent connections: 50
- Query: `SELECT pg_sleep(1);` (1 second sleep)

**Test Method**:
1. Open 50 concurrent connections
2. Execute sleep query simultaneously
3. Measure total duration
4. Check for connection failures

**Expected Results**:
- All 50 connections succeed
- Total duration: ~1-2 seconds (parallel execution)
- No connection errors

**Pass Criteria**: All concurrent connections succeed

**Script**: `scripts/test-db-pool.sh` (Test 3)

---

### Scenario 19: Connection Throughput

**Objective**: Measure database query throughput (queries per second).

**Test Configuration**:
- Query iterations: 100
- Query: `SELECT 1;`

**Test Method**:
1. Execute 100 sequential queries
2. Measure total duration
3. Calculate throughput (queries/second)
4. Count failed queries

**Expected Results**:
- Total duration: <10s
- Throughput: >10 queries/sec
- Failed queries: 0

**Pass Criteria**: Throughput >10 queries/sec, 0 failures

**Script**: `scripts/test-db-pool.sh` (Test 4)

---

### Scenario 20: Connection Leak Detection

**Objective**: Detect potential connection leaks over time.

**Test Configuration**:
- Test duration: 30 seconds
- Operations: Continuous queries with short sleeps

**Test Method**:
1. Measure initial connection count
2. Perform operations for 30 seconds
3. Measure final connection count
4. Calculate difference

**Expected Results**:
- Connection count difference: <=2
- No significant connection leak

**Pass Criteria**: Connection count stable (diff <=2)

**Script**: `scripts/test-db-pool.sh` (Test 5)

---

### Scenario 21: Transaction Performance

**Objective**: Measure transaction commit performance (TPS - Transactions Per Second).

**Test Configuration**:
- Transaction count: 50
- Transaction: INSERT into test table

**Test Method**:
```sql
CREATE TABLE IF NOT EXISTS conn_pool_test (
    id SERIAL PRIMARY KEY,
    value TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Run 50 transactions
BEGIN;
INSERT INTO conn_pool_test (value) VALUES ('test-1');
COMMIT;
-- ... repeat 50 times

DROP TABLE conn_pool_test;
```

**Expected Results**:
- 50 transactions complete successfully
- Total duration: <10s
- TPS (Transactions Per Second): >5

**Pass Criteria**: TPS >5, all transactions succeed

**Script**: `scripts/test-db-pool.sh` (Test 7)

---

## Security Test Scenarios

### Scenario 22: Kyverno Policy Validation

**Objective**: Verify Kyverno policies are enforced correctly.

**Policies to Test**:
1. **harbor-only-images**: Only Harbor registry images allowed
2. **require-non-root**: Containers must run as non-root
3. **require-resource-limits**: CPU/memory limits required
4. **disallow-privileged**: No privileged containers
5. **require-ro-rootfs**: Read-only root filesystem

**Test Method**:
1. Deploy test pod violating policy
2. Check policy violation is logged
3. Verify Policy Reporter shows violation
4. Deploy compliant pod
5. Verify no violations

**Expected Results**:
- Violations logged in Kyverno
- Policy Reporter shows violations
- Compliant pods deploy successfully

**Pass Criteria**: All policies enforced correctly

**Related**: [docs/KYVERNO-Policy-CheatSheet.md](KYVERNO-Policy-CheatSheet.md)

---

### Scenario 23: Pod Security Context Enforcement

**Objective**: Ensure all pods run with secure defaults.

**Security Checks**:
1. `runAsNonRoot: true` - No root containers
2. `fsGroup` set - File system group ownership
3. `readOnlyRootFilesystem: true` - Immutable root filesystem
4. Resource limits defined

**Test Commands**:
```bash
# Check runAsNonRoot
kubectl get pods -n app-demo -o json | \
  jq '.items[] | select(.spec.securityContext.runAsNonRoot == false) | .metadata.name'

# Check resource limits
kubectl get pods -n app-demo -o json | \
  jq '.items[] | select(.spec.containers[].resources.limits == null) | .metadata.name'
```

**Expected Results**:
- No pods running as root
- All pods have fsGroup set
- All pods have resource limits

**Pass Criteria**: All security contexts properly configured

---

### Scenario 24: Network Policy Validation

**Objective**: Verify network policies restrict traffic appropriately.

**Test Cases**:
1. Pod can access allowed services
2. Pod cannot access restricted services
3. External traffic allowed/blocked as configured

**Test Commands**:
```bash
# Test allowed connection (PostgreSQL)
kubectl exec -n app-demo postgres-0 -- nc -zv postgres 5432

# Test restricted connection (should fail)
kubectl exec -n app-demo postgres-0 -- nc -zv external-service 80
```

**Expected Results**:
- Allowed connections succeed
- Restricted connections fail
- Network policies enforced

**Pass Criteria**: Network policies correctly restrict traffic

---

## Failure and Recovery Scenarios

### Scenario 25: Pod Failure Recovery

**Objective**: Verify Kubernetes restarts failed pods automatically.

**Test Steps**:
1. Identify running pod
2. Delete pod: `kubectl delete pod <pod-name> -n app-demo`
3. Monitor pod recreation
4. Verify new pod becomes Ready
5. Test service availability

**Expected Results**:
- Pod is recreated automatically
- New pod reaches Ready state
- Service remains available (minimal downtime)

**Recovery Time**: <2 minutes

**Pass Criteria**: Pod recovers successfully, service available

---

### Scenario 26: Database Connection Loss Recovery

**Objective**: Verify backend reconnects to database after connection loss.

**Test Steps**:
1. Simulate database restart: `kubectl rollout restart statefulset postgres -n app-demo`
2. Monitor backend pods
3. Check backend logs for reconnection
4. Test API endpoints

**Expected Results**:
- Backend detects connection loss
- Backend reconnects automatically
- API endpoints functional after reconnection

**Recovery Time**: <1 minute

**Pass Criteria**: Backend recovers without manual intervention

---

### Scenario 27: Persistent Volume Data Persistence

**Objective**: Verify data persists across pod restarts.

**Test Steps**:
1. Create test data in database
2. Restart PostgreSQL pod: `kubectl delete pod postgres-0 -n app-demo`
3. Wait for pod to be Ready
4. Query test data
5. Verify data still exists

**Expected Results**:
- Data persists across pod restart
- No data loss

**Pass Criteria**: Test data retrieved successfully after restart

---

## Load Test Scenarios

### Scenario 28: Sustained Load Test

**Objective**: Measure performance under sustained load.

**Configuration**:
- Duration: 5 minutes
- Concurrent users: 20
- Target: Health endpoint

**Test Command**:
```bash
hey -z 5m -c 20 http://localhost:8001/actuator/health
```

**Metrics to Monitor**:
- Response time (avg, p95, p99)
- Throughput (req/s)
- Error rate
- Pod resource usage
- Pod restarts

**Expected Results**:
- Response time stable over duration
- Throughput >100 req/s
- Error rate <1%
- No pod restarts

**Pass Criteria**: Stable performance over 5 minutes

---

### Scenario 29: Spike Load Test

**Objective**: Test behavior under sudden traffic spike.

**Configuration**:
- Baseline: 10 concurrent users
- Spike: 100 concurrent users
- Duration: 2 minutes

**Test Steps**:
1. Run baseline load (10 users) for 1 minute
2. Increase to spike load (100 users) for 30 seconds
3. Return to baseline load for 30 seconds

**Expected Results**:
- System handles spike without crashing
- Response times increase but remain acceptable (<5s)
- Error rate <5% during spike
- System recovers to baseline performance

**Pass Criteria**: System survives spike, recovers successfully

---

### Scenario 30: Endurance Test

**Objective**: Verify stability over extended period.

**Configuration**:
- Duration: 24 hours
- Concurrent users: 10
- Target: API endpoints (mixed)

**Metrics to Monitor**:
- Memory leaks (increasing memory usage)
- Connection leaks (increasing connection count)
- Response time degradation
- Error rate over time

**Expected Results**:
- No memory leaks (stable memory usage)
- No connection leaks (stable connection count)
- Consistent response times
- Error rate <0.1%

**Pass Criteria**: System stable over 24 hours

---

## End-to-End User Scenarios

### Scenario 31: New User Onboarding

**Objective**: Simulate complete new user setup and validation.

**User Journey**:
1. Clone repository
2. Run `./scripts/setup-all.sh`
3. Deploy application with `./scripts/deploy-fullstack.sh`
4. Run tests with `./scripts/test-deployment.sh`
5. Access frontend at http://localhost:30080
6. Access backend API at http://localhost:8001/api/users
7. View monitoring in Grafana at http://localhost:3000

**Expected Results**:
- Setup completes without errors
- All services accessible
- Tests pass
- User can interact with application

**Pass Criteria**: Complete onboarding in <30 minutes

**Related**: [docs/QUICK-START.md](QUICK-START.md), [docs/First-Day-Checklist.md](First-Day-Checklist.md)

---

### Scenario 32: Developer CI/CD Workflow

**Objective**: Simulate developer code change through full CI/CD pipeline.

**Workflow Steps**:
1. Developer commits code to GitHub
2. Jenkins pipeline triggered
3. Maven build and tests
4. SonarQube quality analysis
5. Docker image built and pushed to Harbor
6. ArgoCD syncs new image
7. Kyverno validates deployment
8. Monitoring shows new deployment

**Expected Results**:
- Pipeline completes successfully
- Quality gates pass
- Image stored in Harbor
- Application deployed to Kind cluster
- No policy violations
- Metrics visible in Prometheus/Grafana

**Duration**: 5-10 minutes end-to-end

**Pass Criteria**: Code reaches production successfully

---

### Scenario 33: Operations Team Monitoring

**Objective**: Validate operations team can monitor and troubleshoot.

**Monitoring Tasks**:
1. View application metrics in Grafana
2. Check Prometheus alerts
3. Review Loki logs
4. Check Kyverno policy violations
5. Review resource usage
6. Investigate pod issues

**Expected Results**:
- Grafana dashboards show metrics
- Prometheus has active targets
- Loki contains application logs
- Policy Reporter shows violations (if any)
- Resource usage within limits

**Pass Criteria**: All monitoring tools functional

---

## Related Documents

- [TESTING-Guide.md](TESTING-Guide.md) - Testing framework overview
- [Troubleshooting.md](Troubleshooting.md) - Troubleshooting guide
- [KYVERNO-Policy-CheatSheet.md](KYVERNO-Policy-CheatSheet.md) - Kyverno policy reference
- [First-Day-Checklist.md](First-Day-Checklist.md) - Validation checklist
- [SECURITY-BestPractices.md](SECURITY-BestPractices.md) - Security guidelines

---

**Last Updated**: 2026-03-10
**Version**: 1.0.0
**Maintained By**: DevOps Lab Team
