# Testing Guide

Comprehensive guide to testing the DevOps CI/CD Learning Laboratory.

## Table of Contents

- [Testing Overview](#testing-overview)
- [Test Framework Architecture](#test-framework-architecture)
- [Test Types](#test-types)
- [Test Scripts](#test-scripts)
- [Running Tests](#running-tests)
- [Test Result Interpretation](#test-result-interpretation)
- [Load Testing](#load-testing)
- [Performance Benchmarking](#performance-benchmarking)
- [Continuous Testing](#continuous-testing)
- [Best Practices](#best-practices)
- [Troubleshooting Test Failures](#troubleshooting-test-failures)

## Testing Overview

The CI/CD Learning Laboratory includes a comprehensive testing framework covering:

- **Deployment Tests**: Verify infrastructure and application deployments
- **Integration Tests**: Test full-stack application flow end-to-end
- **Performance Tests**: Measure response times, throughput, and resource usage
- **Database Tests**: Validate connection pooling and transaction performance
- **Security Tests**: Verify Kyverno policies and security configurations
- **Monitoring Tests**: Ensure observability stack is functioning

### Testing Goals

1. **Validate Deployment**: Ensure all components are deployed correctly
2. **Verify Integration**: Confirm services communicate properly
3. **Measure Performance**: Establish baseline metrics and detect regressions
4. **Ensure Security**: Validate policy enforcement and security controls
5. **Monitor Health**: Continuous health checks and alerting

## Test Framework Architecture

```
test-framework/
├── scripts/
│   ├── test-deployment.sh      # Deployment validation (PostgreSQL)
│   ├── test-integration.sh     # End-to-end integration tests
│   ├── test-performance.sh     # Performance benchmarking
│   └── test-db-pool.sh         # Database connection pool tests
├── test-results/
│   ├── performance/            # Performance test reports
│   └── database/               # Database test reports
└── docs/
    ├── TESTING-Guide.md        # This file
    └── TESTING-Scenarios.md    # Test scenario descriptions
```

### Test Dependencies

Required tools:
- `kubectl` - Kubernetes CLI
- `docker` - Docker CLI
- `curl` - HTTP client
- `bc` - Math calculations
- `ab` (optional) - Apache Bench for load testing
- `hey` (optional) - Modern load testing tool

Install optional tools:
```bash
# macOS
brew install httpd  # Apache Bench
brew install hey    # hey load tester

# Linux (Ubuntu/Debian)
apt-get install apache2-utils
go install github.com/rakyll/hey@latest
```

## Test Types

### 1. Deployment Tests

**Purpose**: Verify infrastructure components are deployed and configured correctly.

**Script**: `scripts/test-deployment.sh`

**Coverage**:
- Kind cluster health
- Namespace creation
- PostgreSQL StatefulSet deployment
- Pod readiness and health
- Persistent Volume Claims (PVCs)
- Security contexts (non-root, fsGroup)
- Resource limits
- Liveness/readiness probes
- Database connectivity
- SQL operations (CRUD)

**Run**:
```bash
./scripts/test-deployment.sh
```

**Expected Result**: 20/20 tests pass

### 2. Integration Tests

**Purpose**: Validate end-to-end application flow across all layers.

**Script**: `scripts/test-integration.sh`

**Coverage**:
- Infrastructure layer (Kind cluster, nodes, namespaces)
- Database layer (PostgreSQL deployment, connectivity, persistence)
- Backend layer (Spring Boot deployment, API endpoints, health)
- Frontend layer (React deployment, web server)
- Full-stack integration (frontend ↔ backend ↔ database)
- CI/CD pipeline components (Jenkins, Harbor, SonarQube, ArgoCD)
- Policy enforcement (Kyverno policies, violations)
- Monitoring stack (Prometheus, Grafana, Loki)
- Network connectivity (DNS, pod-to-pod, external)

**Run**:
```bash
./scripts/test-integration.sh
```

**Expected Result**: 40+ tests with >95% pass rate

### 3. Performance Tests

**Purpose**: Measure application performance and establish baselines.

**Script**: `scripts/test-performance.sh`

**Coverage**:
- Response time baseline (health, info, metrics endpoints)
- Database query performance
- Load testing (Apache Bench)
- Resource usage metrics (CPU, memory, restarts)
- Cluster health metrics (nodes, pods, PVCs)
- API endpoint performance (latency, throughput, size)

**Run**:
```bash
./scripts/test-performance.sh
```

**Report Location**: `test-results/performance/benchmark_YYYYMMDD_HHMMSS.txt`

### 4. Database Connection Pool Tests

**Purpose**: Validate database connection pooling and concurrent access.

**Script**: `scripts/test-db-pool.sh`

**Coverage**:
- Connection configuration (max_connections, shared_buffers, work_mem)
- Current connection statistics (active, idle, by state)
- Connection pool capacity (concurrent connections test)
- Connection throughput (queries per second)
- Connection leak detection (stability over time)
- Transaction performance (TPS - Transactions Per Second)

**Run**:
```bash
./scripts/test-db-pool.sh
```

**Report Location**: `test-results/database/db_pool_test_YYYYMMDD_HHMMSS.txt`

## Test Scripts

### test-deployment.sh

**Synopsis**: Validates PostgreSQL deployment and database functionality.

**Timeout**: 5 minutes

**Test Count**: 20 tests

**Test Categories**:
1. Infrastructure (2 tests)
2. PostgreSQL Deployment (4 tests)
3. PostgreSQL Connectivity (3 tests)
4. PostgreSQL Security (6 tests)
5. Database Functionality (5 tests)

**Exit Codes**:
- `0` - All tests passed
- `1` - One or more tests failed

### test-integration.sh

**Synopsis**: End-to-end integration tests across all layers.

**Timeout Configuration**:
- Short: 30s
- Medium: 60s
- Long: 120s

**Test Count**: 40+ tests (some optional)

**Test Categories**:
1. Infrastructure & Cluster (4 tests)
2. Database Layer (6 tests)
3. Backend Application (6 tests)
4. Frontend Application (4 tests)
5. Full-Stack Integration (5 tests)
6. CI/CD Pipeline (4 tests)
7. Policy & Security (5 tests)
8. Monitoring & Observability (4 tests)
9. Network & Connectivity (3 tests)

**Optional Tests**: Tests marked as optional will be skipped if they fail (e.g., if service not yet deployed).

**Exit Codes**:
- `0` - All required tests passed
- `1` - One or more required tests failed

### test-performance.sh

**Synopsis**: Measures application performance metrics.

**Test Count**: 6 performance test categories

**Prerequisites**:
- `curl` (required)
- `ab` (optional - for load tests)
- `hey` (optional - for load tests)
- `bc` (required - for calculations)

**Thresholds**:
- Response time: <1.0s
- Throughput: >100 req/s
- Failed requests: 0

**Exit Codes**:
- `0` - Performance tests completed successfully

### test-db-pool.sh

**Synopsis**: Database connection pool and concurrency tests.

**Test Count**: 7 test categories

**Test Parameters**:
- Max Connections Test: 100
- Concurrent Connections: 50
- Query Iterations: 100
- Test Duration: 30s

**Exit Codes**:
- `0` - All tests passed
- `1` - One or more tests failed

## Running Tests

### Quick Test Commands

```bash
# Run all tests sequentially
./scripts/test-deployment.sh && \
./scripts/test-integration.sh && \
./scripts/test-performance.sh && \
./scripts/test-db-pool.sh

# Run deployment tests only
./scripts/test-deployment.sh

# Run integration tests with verbose output
./scripts/test-integration.sh 2>&1 | tee integration-test.log

# Run performance tests
./scripts/test-performance.sh

# Run database pool tests
./scripts/test-db-pool.sh
```

### Test Workflow

Recommended test execution order:

1. **Deployment Tests** - Validate infrastructure
   ```bash
   ./scripts/test-deployment.sh
   ```

2. **Integration Tests** - Verify end-to-end flow
   ```bash
   ./scripts/test-integration.sh
   ```

3. **Performance Tests** - Measure baseline metrics
   ```bash
   ./scripts/test-performance.sh
   ```

4. **Database Tests** - Validate connection pooling
   ```bash
   ./scripts/test-db-pool.sh
   ```

### Environment Variables

Override default settings:

```bash
# Cluster and namespace
export KIND_CLUSTER_NAME=my-cluster
export KUBE_NAMESPACE=my-namespace

# Service URLs
export BACKEND_URL=http://localhost:8001
export FRONTEND_URL=http://localhost:30080
export JENKINS_URL=http://localhost:8080
export HARBOR_URL=http://localhost:8082
export SONAR_HOST=http://localhost:9000
export ARGOCD_SERVER=http://localhost:8090

# Run tests
./scripts/test-integration.sh
```

## Test Result Interpretation

### Success Indicators

**Deployment Tests**:
- ✅ 20/20 tests passed
- All pods in Running state
- All PVCs Bound
- Database accepting connections

**Integration Tests**:
- ✅ 40+ tests with >95% pass rate
- All required services accessible
- API endpoints responding
- Monitoring stack operational

**Performance Tests**:
- Response times <1s
- Throughput >100 req/s
- No failed requests
- All pods stable (0 restarts)

**Database Tests**:
- All connection tests pass
- No connection leaks detected
- Throughput >50 queries/sec
- Transaction rate >10 TPS

### Failure Analysis

**Common Failure Patterns**:

1. **Pod Not Ready**
   - Symptom: Pod status shows "Not Ready" or "CrashLoopBackOff"
   - Check: `kubectl describe pod <pod-name> -n <namespace>`
   - Fix: Review pod events and logs

2. **Service Unreachable**
   - Symptom: Connection timeouts to service endpoints
   - Check: Port forwarding status, service endpoints
   - Fix: Restart port forwarding script

3. **Database Connection Failed**
   - Symptom: PostgreSQL connection errors
   - Check: Pod logs, database credentials
   - Fix: Verify password, restart pod

4. **Performance Degradation**
   - Symptom: Response times >1s, low throughput
   - Check: Resource usage, pod restarts
   - Fix: Adjust resource limits, scale pods

5. **Connection Pool Exhausted**
   - Symptom: max_connections errors
   - Check: Active connections count
   - Fix: Increase max_connections, implement connection pooling

## Load Testing

### Apache Bench (ab)

Basic load test:
```bash
# 1000 requests, 10 concurrent
ab -n 1000 -c 10 http://localhost:8001/actuator/health

# POST request with JSON payload
ab -n 500 -c 10 -p payload.json -T application/json \
   http://localhost:8001/api/users
```

### hey - Modern Load Testing

```bash
# Install hey
go install github.com/rakyll/hey@latest

# Basic load test
hey -n 1000 -c 10 http://localhost:8001/actuator/health

# Load test with custom headers
hey -n 500 -c 10 \
    -H "Authorization: Bearer token" \
    http://localhost:8001/api/users

# Load test with rate limiting (100 req/s)
hey -n 1000 -q 100 http://localhost:8001/actuator/health
```

### Load Testing Best Practices

1. **Warm Up First**: Run warmup requests before measuring
2. **Gradual Ramp-Up**: Start with low concurrency, increase gradually
3. **Monitor Resources**: Watch CPU, memory, connections during tests
4. **Establish Baselines**: Run tests consistently to detect regressions
5. **Test Realistic Scenarios**: Use production-like request patterns

### Load Test Scenarios

**Scenario 1: Health Check Endpoint**
```bash
# Low load
ab -n 100 -c 5 http://localhost:8001/actuator/health

# Medium load
ab -n 500 -c 10 http://localhost:8001/actuator/health

# High load
ab -n 1000 -c 50 http://localhost:8001/actuator/health
```

**Scenario 2: API Endpoints**
```bash
# GET requests
hey -n 500 -c 10 http://localhost:8001/api/users

# POST requests
hey -n 200 -c 5 -m POST \
    -H "Content-Type: application/json" \
    -d '{"name":"test","email":"test@example.com"}' \
    http://localhost:8001/api/users
```

**Scenario 3: Frontend**
```bash
# Static content
ab -n 1000 -c 20 http://localhost:30080/

# API calls from frontend
hey -n 500 -c 10 http://localhost:30080/assets/index.js
```

## Performance Benchmarking

### Establishing Baselines

Run performance tests regularly to establish baselines:

```bash
# Run performance test
./scripts/test-performance.sh

# Review report
cat test-results/performance/benchmark_*.txt
```

### Key Performance Indicators (KPIs)

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Response Time (Health) | <100ms | >500ms |
| Response Time (API) | <500ms | >2s |
| Throughput | >100 req/s | <50 req/s |
| Database Query Time | <50ms | >200ms |
| Pod Restart Count | 0 | >1 in 24h |
| Failed Requests | 0% | >1% |
| Connection Pool Usage | <80% | >90% |

### Performance Monitoring

**Real-time Monitoring**:
```bash
# Watch pod resource usage
kubectl top pods -n app-demo

# Monitor PostgreSQL connections
kubectl exec -n app-demo postgres-0 -- \
  psql -U app_user -d cicd_demo -c \
  "SELECT count(*) FROM pg_stat_activity WHERE datname='cicd_demo';"

# Check Prometheus metrics
curl -s http://localhost:30090/api/v1/query?query=up | jq
```

**Continuous Monitoring**:
- Grafana Dashboards: http://localhost:3000
- Prometheus Metrics: http://localhost:30090
- Backend Metrics: http://localhost:8001/actuator/prometheus

## Continuous Testing

### Automated Testing in CI/CD

Add tests to Jenkins pipeline:

```groovy
stage('Test Deployment') {
    steps {
        sh './scripts/test-deployment.sh'
    }
}

stage('Integration Tests') {
    steps {
        sh './scripts/test-integration.sh'
    }
}

stage('Performance Tests') {
    steps {
        sh './scripts/test-performance.sh'
    }
}
```

### Pre-Deployment Testing

Before deploying to production:

1. Run full test suite
2. Review all test reports
3. Verify performance baselines
4. Check security policies
5. Validate monitoring alerts

### Scheduled Testing

Run tests on a schedule:

```bash
# Add to crontab
# Run integration tests daily at 2 AM
0 2 * * * cd /path/to/project && ./scripts/test-integration.sh

# Run performance tests weekly on Sundays at 3 AM
0 3 * * 0 cd /path/to/project && ./scripts/test-performance.sh
```

## Best Practices

### Test Design

1. **Idempotent Tests**: Tests should be repeatable without side effects
2. **Independent Tests**: Each test should run independently
3. **Clear Assertions**: Use descriptive test names and clear pass/fail criteria
4. **Timeout Handling**: Set appropriate timeouts for async operations
5. **Error Reporting**: Provide actionable error messages

### Test Data Management

1. **Cleanup After Tests**: Remove test data after test completion
2. **Use Test Fixtures**: Prepare consistent test data
3. **Avoid Production Data**: Never test with production data
4. **Isolate Test Environments**: Use separate namespaces for testing

### Test Execution

1. **Run Tests Locally**: Test before pushing to CI/CD
2. **Monitor During Tests**: Watch resource usage during test runs
3. **Archive Test Results**: Keep historical test reports
4. **Review Failures Promptly**: Investigate and fix failures quickly
5. **Update Tests Regularly**: Keep tests in sync with code changes

## Troubleshooting Test Failures

### Deployment Test Failures

**PostgreSQL Pod Not Running**:
```bash
# Check pod status
kubectl get pod postgres-0 -n app-demo

# Check pod events
kubectl describe pod postgres-0 -n app-demo

# Check pod logs
kubectl logs postgres-0 -n app-demo
```

**PVC Not Bound**:
```bash
# Check PVC status
kubectl get pvc postgres-pvc -n app-demo

# Check PV status
kubectl get pv

# Describe PVC for events
kubectl describe pvc postgres-pvc -n app-demo
```

### Integration Test Failures

**Service Unreachable**:
```bash
# Check service
kubectl get svc -n app-demo

# Check endpoints
kubectl get endpoints -n app-demo

# Test service from within cluster
kubectl run curl-test --image=curlimages/curl:latest -it --rm -- \
  curl http://service-name:port
```

**Timeout Errors**:
```bash
# Increase timeout in test script
export TIMEOUT_LONG=300  # 5 minutes

# Or edit scripts/test-integration.sh
# TIMEOUT_LONG=300
```

### Performance Test Failures

**High Response Times**:
```bash
# Check pod resource usage
kubectl top pods -n app-demo

# Check pod restarts
kubectl get pods -n app-demo

# Review pod logs for errors
kubectl logs -n app-demo <pod-name>
```

**Low Throughput**:
```bash
# Scale deployment
kubectl scale deployment cicd-demo-backend -n app-demo --replicas=3

# Increase resource limits
kubectl edit deployment cicd-demo-backend -n app-demo
```

### Database Test Failures

**Connection Errors**:
```bash
# Verify PostgreSQL is running
kubectl exec -n app-demo postgres-0 -- pg_isready -U app_user

# Check connection settings
kubectl exec -n app-demo postgres-0 -- \
  psql -U app_user -d cicd_demo -c "SHOW max_connections;"

# Test connectivity
kubectl exec -n app-demo postgres-0 -- \
  psql -U app_user -d cicd_demo -c "SELECT 1;"
```

**Connection Pool Exhausted**:
```bash
# Check active connections
kubectl exec -n app-demo postgres-0 -- \
  psql -U app_user -d cicd_demo -c \
  "SELECT count(*) FROM pg_stat_activity;"

# Terminate idle connections
kubectl exec -n app-demo postgres-0 -- \
  psql -U app_user -d cicd_demo -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state='idle' AND pid <> pg_backend_pid();"
```

## Related Documents

- [TESTING-Scenarios.md](TESTING-Scenarios.md) - Detailed test scenario descriptions
- [Troubleshooting.md](Troubleshooting.md) - General troubleshooting guide
- [FULLSTACK-DEPLOYMENT.md](FULLSTACK-DEPLOYMENT.md) - Deployment guide
- [First-Day-Checklist.md](First-Day-Checklist.md) - First day validation checklist
- [CHEAT-SHEET-Commands.md](CHEAT-SHEET-Commands.md) - Quick command reference

## Additional Resources

- [Apache Bench Documentation](https://httpd.apache.org/docs/2.4/programs/ab.html)
- [hey Load Testing Tool](https://github.com/rakyll/hey)
- [PostgreSQL Performance Monitoring](https://www.postgresql.org/docs/current/monitoring-stats.html)
- [Kubernetes Testing Best Practices](https://kubernetes.io/docs/tasks/debug/)

---

**Last Updated**: 2026-03-10
**Version**: 1.0.0
**Maintained By**: DevOps Lab Team
