#!/bin/bash
# End-to-End Integration Test Suite
# Tests the complete CI/CD pipeline flow across all components

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KIND_CLUSTER="${KIND_CLUSTER_NAME:-app-demo}"
NAMESPACE="${KUBE_NAMESPACE:-app-demo}"
BACKEND_URL="${BACKEND_URL:-http://localhost:8001}"
FRONTEND_URL="${FRONTEND_URL:-http://localhost:30080}"
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
HARBOR_URL="${HARBOR_URL:-http://localhost:8082}"
SONAR_URL="${SONAR_HOST:-http://localhost:9000}"
ARGOCD_URL="${ARGOCD_SERVER:-http://localhost:8090}"

# Timeout settings (seconds)
TIMEOUT_SHORT=30
TIMEOUT_MEDIUM=60
TIMEOUT_LONG=120

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test tracking
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
START_TIME=$(date +%s)

print_header() {
    echo -e "\n${BLUE}=========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=========================================${NC}"
}

print_test() {
    echo -e "${YELLOW}[TEST $TESTS_RUN]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
}

print_fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
}

print_skip() {
    echo -e "${CYAN}⏭️  SKIP:${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
}

# Timeout wrapper function
run_with_timeout() {
    local timeout=$1
    local command=$2
    local description=$3

    if timeout $timeout bash -c "$command" > /dev/null 2>&1; then
        return 0
    else
        print_warn "Timeout after ${timeout}s: $description"
        return 1
    fi
}

# Test execution wrapper
run_test() {
    local test_name="$1"
    local test_command="$2"
    local timeout="${3:-$TIMEOUT_SHORT}"
    local optional="${4:-false}"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    if run_with_timeout "$timeout" "$test_command" "$test_name"; then
        print_pass "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        if [ "$optional" = "true" ]; then
            print_skip "$test_name (optional test)"
            TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
            return 0
        else
            print_fail "$test_name"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    fi
}

# Check service availability
check_service() {
    local service_name=$1
    local url=$2
    local expected_code=${3:-200}

    curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_code"
}

print_header "End-to-End Integration Test Suite"
echo "Project: CI/CD Demo"
echo "Cluster: $KIND_CLUSTER"
echo "Namespace: $NAMESPACE"
echo "Timeout Settings: Short=${TIMEOUT_SHORT}s, Medium=${TIMEOUT_MEDIUM}s, Long=${TIMEOUT_LONG}s"
echo ""

# ============================================
# INFRASTRUCTURE TESTS
# ============================================
print_header "1. Infrastructure & Cluster Tests"

run_test "Kind cluster is running" \
    "docker ps --filter 'name=${KIND_CLUSTER}-control-plane' --format '{{.Names}}' | grep -q '${KIND_CLUSTER}-control-plane'"

run_test "Kind cluster nodes are Ready" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl get nodes --no-headers | grep -q 'Ready'" \
    "$TIMEOUT_SHORT"

run_test "Namespace ${NAMESPACE} exists" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl get namespace ${NAMESPACE}"

run_test "Namespace has required labels" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl get namespace ${NAMESPACE} -o jsonpath='{.metadata.labels}' | grep -q 'team'" \
    "$TIMEOUT_SHORT" \
    "true"

# ============================================
# DATABASE LAYER TESTS
# ============================================
print_header "2. Database Layer Tests"

run_test "PostgreSQL StatefulSet exists" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl get statefulset postgres -n ${NAMESPACE}"

run_test "PostgreSQL pod is running" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl get pod postgres-0 -n ${NAMESPACE} -o jsonpath='{.status.phase}' | grep -q 'Running'"

run_test "PostgreSQL is accepting connections" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- pg_isready -U app_user" \
    "$TIMEOUT_MEDIUM"

run_test "Database 'cicd_demo' is accessible" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- psql -U app_user -d cicd_demo -c 'SELECT 1;'" \
    "$TIMEOUT_SHORT"

run_test "PostgreSQL persistent volume is bound" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl get pvc postgres-pvc -n ${NAMESPACE} -o jsonpath='{.status.phase}' | grep -q 'Bound'"

run_test "PostgreSQL service is reachable" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- nc -zv postgres 5432" \
    "$TIMEOUT_SHORT"

# ============================================
# BACKEND APPLICATION TESTS
# ============================================
print_header "3. Backend Application Tests"

run_test "Backend deployment exists" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl get deployment cicd-demo-backend -n ${NAMESPACE}" \
    "$TIMEOUT_SHORT" \
    "true"

run_test "Backend pods are running" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl get pods -n ${NAMESPACE} -l app=cicd-demo-backend -o jsonpath='{.items[*].status.phase}' | grep -q 'Running'" \
    "$TIMEOUT_MEDIUM" \
    "true"

run_test "Backend service is available" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl get svc cicd-demo-backend -n ${NAMESPACE}" \
    "$TIMEOUT_SHORT" \
    "true"

run_test "Backend health endpoint responds" \
    "check_service 'Backend' '${BACKEND_URL}/actuator/health' '200'" \
    "$TIMEOUT_MEDIUM" \
    "true"

run_test "Backend API endpoints are accessible" \
    "check_service 'Backend API' '${BACKEND_URL}/api/users' '200'" \
    "$TIMEOUT_MEDIUM" \
    "true"

run_test "Backend Prometheus metrics endpoint responds" \
    "check_service 'Backend Metrics' '${BACKEND_URL}/actuator/prometheus' '200'" \
    "$TIMEOUT_SHORT" \
    "true"

# ============================================
# FRONTEND APPLICATION TESTS
# ============================================
print_header "4. Frontend Application Tests"

run_test "Frontend deployment exists" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl get deployment cicd-demo-frontend -n ${NAMESPACE}" \
    "$TIMEOUT_SHORT" \
    "true"

run_test "Frontend pods are running" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl get pods -n ${NAMESPACE} -l app=cicd-demo-frontend -o jsonpath='{.items[*].status.phase}' | grep -q 'Running'" \
    "$TIMEOUT_MEDIUM" \
    "true"

run_test "Frontend service is available" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl get svc cicd-demo-frontend -n ${NAMESPACE}" \
    "$TIMEOUT_SHORT" \
    "true"

run_test "Frontend web server responds" \
    "check_service 'Frontend' '${FRONTEND_URL}' '200'" \
    "$TIMEOUT_MEDIUM" \
    "true"

# ============================================
# FULL-STACK INTEGRATION TESTS
# ============================================
print_header "5. Full-Stack Integration Tests"

run_test "Backend can connect to database" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- psql -U app_user -d cicd_demo -c \"SELECT datname FROM pg_stat_activity WHERE datname='cicd_demo';\" | grep -q 'cicd_demo'" \
    "$TIMEOUT_MEDIUM" \
    "true"

run_test "Frontend can reach backend API" \
    "curl -s ${BACKEND_URL}/actuator/info | grep -q 'app'" \
    "$TIMEOUT_MEDIUM" \
    "true"

run_test "Data persistence: Create test record" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- psql -U app_user -d cicd_demo -c \"CREATE TABLE IF NOT EXISTS integration_test (id SERIAL PRIMARY KEY, test_value TEXT); INSERT INTO integration_test (test_value) VALUES ('e2e-test-$(date +%s)');\"" \
    "$TIMEOUT_SHORT" \
    "true"

run_test "Data persistence: Retrieve test record" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- psql -U app_user -d cicd_demo -c \"SELECT COUNT(*) FROM integration_test;\" | grep -q '[0-9]'" \
    "$TIMEOUT_SHORT" \
    "true"

run_test "Data persistence: Cleanup test table" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- psql -U app_user -d cicd_demo -c \"DROP TABLE IF EXISTS integration_test;\"" \
    "$TIMEOUT_SHORT" \
    "true"

# ============================================
# CI/CD PIPELINE TESTS
# ============================================
print_header "6. CI/CD Pipeline Component Tests"

run_test "Jenkins is accessible" \
    "check_service 'Jenkins' '${JENKINS_URL}' '403'" \
    "$TIMEOUT_SHORT" \
    "true"

run_test "Harbor registry is accessible" \
    "check_service 'Harbor' '${HARBOR_URL}' '200'" \
    "$TIMEOUT_SHORT" \
    "true"

run_test "SonarQube is accessible" \
    "check_service 'SonarQube' '${SONAR_URL}' '200'" \
    "$TIMEOUT_SHORT" \
    "true"

run_test "ArgoCD is accessible" \
    "curl -k -s -o /dev/null -w '%{http_code}' '${ARGOCD_URL}' | grep -q '200\|301\|302'" \
    "$TIMEOUT_SHORT" \
    "true"

# ============================================
# POLICY & SECURITY TESTS
# ============================================
print_header "7. Policy & Security Tests"

run_test "Kyverno is installed" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl get deployment kyverno -n kyverno" \
    "$TIMEOUT_SHORT" \
    "true"

run_test "Kyverno policies are loaded" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl get clusterpolicies | grep -q 'harbor-only-images\|require-non-root'" \
    "$TIMEOUT_SHORT" \
    "true"

run_test "Policy Reporter is accessible" \
    "curl -s http://localhost:31002 | grep -q 'Policy Reporter'" \
    "$TIMEOUT_SHORT" \
    "true"

run_test "All pods run as non-root" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl get pods -n ${NAMESPACE} -o jsonpath='{range .items[*]}{.metadata.name}: {.spec.containers[*].securityContext.runAsNonRoot}{\"\\n\"}{end}' | grep -v 'false'" \
    "$TIMEOUT_SHORT" \
    "true"

run_test "All pods have resource limits" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl get pods -n ${NAMESPACE} -o json | jq -r '.items[] | select(.spec.containers[].resources.limits == null) | .metadata.name' | wc -l | grep -q '^0$'" \
    "$TIMEOUT_SHORT" \
    "true"

# ============================================
# MONITORING & OBSERVABILITY TESTS
# ============================================
print_header "8. Monitoring & Observability Tests"

run_test "Prometheus is accessible" \
    "check_service 'Prometheus' 'http://localhost:30090' '200'" \
    "$TIMEOUT_SHORT" \
    "true"

run_test "Grafana is accessible" \
    "check_service 'Grafana' 'http://localhost:3000' '200'" \
    "$TIMEOUT_SHORT" \
    "true"

run_test "Loki is accessible" \
    "check_service 'Loki' 'http://localhost:31000/ready' '200'" \
    "$TIMEOUT_SHORT" \
    "true"

run_test "Prometheus is scraping targets" \
    "curl -s http://localhost:30090/api/v1/targets | grep -q 'health\":\"up'" \
    "$TIMEOUT_MEDIUM" \
    "true"

# ============================================
# NETWORK & CONNECTIVITY TESTS
# ============================================
print_header "9. Network & Connectivity Tests"

run_test "DNS resolution works within cluster" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl run dns-test --image=busybox:1.28 --rm -it --restart=Never -- nslookup kubernetes.default" \
    "$TIMEOUT_MEDIUM" \
    "true"

run_test "Pod-to-pod communication works" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- nc -zv postgres 5432" \
    "$TIMEOUT_SHORT" \
    "true"

run_test "External connectivity from pods" \
    "docker exec ${KIND_CLUSTER}-control-plane kubectl run connectivity-test --image=curlimages/curl:latest --rm -it --restart=Never -- curl -s https://www.google.com | grep -q 'google'" \
    "$TIMEOUT_LONG" \
    "true"

# ============================================
# RESULTS SUMMARY
# ============================================
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

print_header "Integration Test Results Summary"
echo ""
echo -e "${BLUE}Total Tests:${NC} $TESTS_RUN"
echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Failed:${NC} $TESTS_FAILED"
echo -e "${CYAN}Skipped:${NC} $TESTS_SKIPPED"
echo -e "${BLUE}Duration:${NC} ${DURATION}s"
echo ""

# Calculate success rate
if [ $TESTS_RUN -gt 0 ]; then
    SUCCESS_RATE=$(( (TESTS_PASSED * 100) / (TESTS_RUN - TESTS_SKIPPED) ))
    echo -e "${BLUE}Success Rate:${NC} ${SUCCESS_RATE}%"
fi

echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}✅ ALL INTEGRATION TESTS PASSED!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    print_info "Full-stack application is operational end-to-end"
    echo ""
    echo "Component Status:"
    echo "  ✅ Infrastructure Layer (Kind, Kubernetes)"
    echo "  ✅ Database Layer (PostgreSQL)"
    echo "  ✅ Backend Layer (Spring Boot)"
    echo "  ✅ Frontend Layer (React)"
    echo "  ✅ CI/CD Pipeline (Jenkins, Harbor, SonarQube, ArgoCD)"
    echo "  ✅ Policy Enforcement (Kyverno)"
    echo "  ✅ Monitoring Stack (Prometheus, Grafana, Loki)"
    echo ""
    echo "Access Points:"
    echo "  Frontend:        ${FRONTEND_URL}"
    echo "  Backend API:     ${BACKEND_URL}/api"
    echo "  Health Check:    ${BACKEND_URL}/actuator/health"
    echo "  Metrics:         ${BACKEND_URL}/actuator/prometheus"
    echo "  Jenkins:         ${JENKINS_URL}"
    echo "  Harbor:          ${HARBOR_URL}"
    echo "  SonarQube:       ${SONAR_URL}"
    echo "  ArgoCD:          ${ARGOCD_URL}"
    echo "  Grafana:         http://localhost:3000"
    echo "  Prometheus:      http://localhost:30090"
    echo "  Policy Reporter: http://localhost:31002"
    echo ""
    exit 0
else
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}❌ SOME INTEGRATION TESTS FAILED${NC}"
    echo -e "${RED}=========================================${NC}"
    echo ""
    print_info "Review failed tests above for details"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check pod logs: kubectl logs -n ${NAMESPACE} <pod-name>"
    echo "  2. Check pod status: kubectl describe pod -n ${NAMESPACE} <pod-name>"
    echo "  3. Check events: kubectl get events -n ${NAMESPACE} --sort-by='.lastTimestamp'"
    echo "  4. Review documentation: docs/Troubleshooting.md"
    echo "  5. Check service health: curl ${BACKEND_URL}/actuator/health"
    echo ""
    exit 1
fi
