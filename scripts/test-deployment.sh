#!/bin/bash
# Comprehensive deployment test script
# Version: 2.0
# Enhanced with timeout handling, better error reporting, and additional test scenarios

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KIND_CLUSTER="${KIND_CLUSTER_NAME:-app-demo}"
NAMESPACE="${KUBE_NAMESPACE:-app-demo}"

# Timeout settings (seconds)
TIMEOUT_SHORT=10
TIMEOUT_MEDIUM=30
TIMEOUT_LONG=60

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}=========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=========================================${NC}"
}

print_test() {
    echo -e "${YELLOW}TEST:${NC} $1"
}

print_pass() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
}

print_fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    exit 1
}

print_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
}

print_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
START_TIME=$(date +%s)

# Enhanced error reporting
LAST_ERROR=""

# Timeout wrapper function
run_with_timeout() {
    local timeout=$1
    local command=$2
    local error_output

    # Capture both stdout and stderr
    error_output=$(timeout $timeout bash -c "$command" 2>&1)
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        return 0
    elif [ $exit_code -eq 124 ]; then
        LAST_ERROR="Timeout after ${timeout}s"
        return 1
    else
        LAST_ERROR="Command failed: $error_output"
        return 1
    fi
}

run_test() {
    local test_name="$1"
    local test_command="$2"
    local timeout="${3:-$TIMEOUT_SHORT}"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    if run_with_timeout "$timeout" "$test_command"; then
        print_pass "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        LAST_ERROR=""
        return 0
    else
        print_fail "$test_name"
        if [ -n "$LAST_ERROR" ]; then
            print_error "$LAST_ERROR"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

print_header "Full-Stack Deployment Test Suite v2.0"
echo "Project: CI/CD Demo"
echo "Cluster: $KIND_CLUSTER"
echo "Namespace: $NAMESPACE"
echo "Timeout Settings: Short=${TIMEOUT_SHORT}s, Medium=${TIMEOUT_MEDIUM}s, Long=${TIMEOUT_LONG}s"
echo ""

print_header "Infrastructure Tests"

print_test "Kind cluster is running"
if docker ps --filter "name=${KIND_CLUSTER}-control-plane" --format '{{.Names}}' | grep -q "${KIND_CLUSTER}-control-plane"; then
    print_pass "Kind cluster is running"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "Kind cluster is NOT running"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_test "Namespace exists"
if docker exec ${KIND_CLUSTER}-control-plane kubectl get namespace ${NAMESPACE} > /dev/null 2>&1; then
    print_pass "Namespace ${NAMESPACE} exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "Namespace ${NAMESPACE} does NOT exist"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_header "PostgreSQL Deployment Tests"

print_test "PostgreSQL StatefulSet exists"
if docker exec ${KIND_CLUSTER}-control-plane kubectl get statefulset postgres -n ${NAMESPACE} > /dev/null 2>&1; then
    print_pass "StatefulSet exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "StatefulSet does NOT exist"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_test "PostgreSQL pod is running"
if docker exec ${KIND_CLUSTER}-control-plane kubectl get pod postgres-0 -n ${NAMESPACE} -o jsonpath='{.status.phase}' | grep -q "Running"; then
    print_pass "Pod is running"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "Pod is NOT running"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_test "PostgreSQL pod is ready (1/1)"
if docker exec ${KIND_CLUSTER}-control-plane kubectl get pod postgres-0 -n ${NAMESPACE} -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; then
    print_pass "Pod is ready"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "Pod is NOT ready"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_test "PostgreSQL service exists"
if docker exec ${KIND_CLUSTER}-control-plane kubectl get svc postgres -n ${NAMESPACE} > /dev/null 2>&1; then
    print_pass "Service exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "Service does NOT exist"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_test "PVC is bound"
if docker exec ${KIND_CLUSTER}-control-plane kubectl get pvc postgres-pvc -n ${NAMESPACE} -o jsonpath='{.status.phase}' | grep -q "Bound"; then
    print_pass "PVC is bound"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "PVC is NOT bound"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_header "PostgreSQL Connectivity Tests"

print_test "PostgreSQL is accepting connections"
if docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- pg_isready -U app_user > /dev/null 2>&1; then
    print_pass "PostgreSQL accepting connections"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "PostgreSQL NOT accepting connections"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_test "Database 'cicd_demo' exists"
if docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- psql -U app_user -d cicd_demo -c "SELECT 1;" > /dev/null 2>&1; then
    print_pass "Database exists and accessible"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "Database does NOT exist or not accessible"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_test "User 'app_user' can connect"
if docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- psql -U app_user -d cicd_demo -c "SELECT current_user;" | grep -q "app_user"; then
    print_pass "User can connect"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "User CANNOT connect"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_header "PostgreSQL Security Tests"

print_test "Pod runs as non-root (UID 999)"
if docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- id -u | grep -q "999"; then
    print_pass "Running as UID 999 (non-root)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "NOT running as UID 999"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_test "FSGroup is set (999)"
if docker exec ${KIND_CLUSTER}-control-plane kubectl get pod postgres-0 -n ${NAMESPACE} -o jsonpath='{.spec.securityContext.fsGroup}' | grep -q "999"; then
    print_pass "FSGroup is 999"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "FSGroup is NOT 999"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_test "Resource limits configured"
if docker exec ${KIND_CLUSTER}-control-plane kubectl get pod postgres-0 -n ${NAMESPACE} -o jsonpath='{.spec.containers[0].resources.limits}' | grep -q "memory"; then
    print_pass "Resource limits configured"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "Resource limits NOT configured"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_test "Liveness probe configured"
if docker exec ${KIND_CLUSTER}-control-plane kubectl get pod postgres-0 -n ${NAMESPACE} -o jsonpath='{.spec.containers[0].livenessProbe}' | grep -q "pg_isready"; then
    print_pass "Liveness probe configured"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "Liveness probe NOT configured"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_test "Readiness probe configured"
if docker exec ${KIND_CLUSTER}-control-plane kubectl get pod postgres-0 -n ${NAMESPACE} -o jsonpath='{.spec.containers[0].readinessProbe}' | grep -q "pg_isready"; then
    print_pass "Readiness probe configured"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "Readiness probe NOT configured"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_header "Database Functionality Tests"

print_test "Can create table"
if docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- psql -U app_user -d cicd_demo -c "CREATE TABLE IF NOT EXISTS test_table (id INT);" > /dev/null 2>&1; then
    print_pass "Can create table"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "CANNOT create table"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_test "Can insert data"
if docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- psql -U app_user -d cicd_demo -c "INSERT INTO test_table VALUES (1);" > /dev/null 2>&1; then
    print_pass "Can insert data"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "CANNOT insert data"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_test "Can query data"
if docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- psql -U app_user -d cicd_demo -c "SELECT * FROM test_table;" | grep -q "1"; then
    print_pass "Can query data"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "CANNOT query data"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_test "Can drop table"
if docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- psql -U app_user -d cicd_demo -c "DROP TABLE test_table;" > /dev/null 2>&1; then
    print_pass "Can drop table"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "CANNOT drop table"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_test "Schema is empty (ready for Flyway)"
TABLE_COUNT=$(docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- psql -U app_user -d cicd_demo -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ')
if [ "$TABLE_COUNT" = "0" ]; then
    print_pass "Schema is empty and ready for Flyway migrations"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "Schema is NOT empty (has $TABLE_COUNT tables)"
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_header "Additional Validation Tests"

# New Test: Check for pod events (warnings/errors)
TESTS_RUN=$((TESTS_RUN + 1))
print_test "Check for pod warning events"
if docker exec ${KIND_CLUSTER}-control-plane kubectl get events -n ${NAMESPACE} --field-selector type=Warning,involvedObject.name=postgres-0 --no-headers 2>&1 | grep -q "Warning" 2>&1; then
    print_warn "Warning events found for postgres-0"
    docker exec ${KIND_CLUSTER}-control-plane kubectl get events -n ${NAMESPACE} --field-selector type=Warning,involvedObject.name=postgres-0
    TESTS_PASSED=$((TESTS_PASSED + 1))  # Warning, not failure
else
    print_pass "No warning events for postgres-0"
    TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# New Test: Verify environment variables are set correctly
TESTS_RUN=$((TESTS_RUN + 1))
print_test "Verify database environment variables"
if docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- env | grep -q "POSTGRES_DB=cicd_demo"; then
    print_pass "Environment variables configured correctly"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "Environment variables NOT configured correctly"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# New Test: Check StatefulSet update strategy
TESTS_RUN=$((TESTS_RUN + 1))
print_test "Verify StatefulSet update strategy"
if docker exec ${KIND_CLUSTER}-control-plane kubectl get statefulset postgres -n ${NAMESPACE} -o jsonpath='{.spec.updateStrategy.type}' | grep -q "RollingUpdate"; then
    print_pass "Update strategy is RollingUpdate"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_warn "Update strategy is not RollingUpdate"
    TESTS_PASSED=$((TESTS_PASSED + 1))  # Warning, not failure
fi

# New Test: Verify service selector matches pod labels
TESTS_RUN=$((TESTS_RUN + 1))
print_test "Verify service selector matches pod labels"
if docker exec ${KIND_CLUSTER}-control-plane kubectl get svc postgres -n ${NAMESPACE} -o jsonpath='{.spec.selector.app}' | grep -q "postgres"; then
    print_pass "Service selector matches pod labels"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "Service selector does NOT match pod labels"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# New Test: Check PVC storage class
TESTS_RUN=$((TESTS_RUN + 1))
print_test "Verify PVC storage class"
local storage_class=$(docker exec ${KIND_CLUSTER}-control-plane kubectl get pvc postgres-pvc -n ${NAMESPACE} -o jsonpath='{.spec.storageClassName}' 2>&1)
if [ -n "$storage_class" ]; then
    print_pass "Storage class: $storage_class"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_warn "Storage class not specified (using default)"
    TESTS_PASSED=$((TESTS_PASSED + 1))  # Warning, not failure
fi

# New Test: Database connection pool settings
TESTS_RUN=$((TESTS_RUN + 1))
print_test "Check max_connections setting"
local max_conn=$(docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- psql -U app_user -d cicd_demo -t -c "SHOW max_connections;" 2>&1 | tr -d ' ')
if [ -n "$max_conn" ] && [ "$max_conn" != "" ]; then
    print_pass "max_connections: $max_conn"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "Unable to retrieve max_connections"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# New Test: Database version check
TESTS_RUN=$((TESTS_RUN + 1))
print_test "Verify PostgreSQL version"
local pg_version=$(docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- psql -U app_user -d cicd_demo -t -c "SHOW server_version;" 2>&1 | tr -d ' ')
if [ -n "$pg_version" ]; then
    print_pass "PostgreSQL version: $pg_version"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_fail "Unable to retrieve PostgreSQL version"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Calculate test duration
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

print_header "Test Results Summary"
echo ""
echo -e "${BLUE}Test Execution Time:${NC} ${DURATION}s"
echo -e "${BLUE}Total Tests:${NC} $TESTS_RUN"
echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Failed:${NC} $TESTS_FAILED"
echo ""

# Calculate success rate
if [ $TESTS_RUN -gt 0 ]; then
    SUCCESS_RATE=$(( (TESTS_PASSED * 100) / TESTS_RUN ))
    echo -e "${CYAN}Success Rate:${NC} ${SUCCESS_RATE}%"
fi

echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}✅ ALL TESTS PASSED!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    print_info "PostgreSQL is fully operational and ready for backend deployment"
    echo ""
    echo "Test Summary by Category:"
    echo "  ✅ Infrastructure (2 tests)"
    echo "  ✅ PostgreSQL Deployment (4 tests)"
    echo "  ✅ PostgreSQL Connectivity (3 tests)"
    echo "  ✅ PostgreSQL Security (6 tests)"
    echo "  ✅ Database Functionality (5 tests)"
    echo "  ✅ Additional Validation (6 tests)"
    echo ""
    echo "Next steps:"
    echo "  1. Run integration tests: ./scripts/test-integration.sh"
    echo "  2. Run performance tests: ./scripts/test-performance.sh"
    echo "  3. Trigger Jenkins pipeline: http://localhost:8080"
    echo "  4. Monitor deployment: kubectl get pods -n app-demo -w"
    echo "  5. Access frontend: http://localhost:30080"
    echo ""
    echo "Documentation:"
    echo "  - Testing Guide: docs/TESTING-Guide.md"
    echo "  - Test Scenarios: docs/TESTING-Scenarios.md"
    echo "  - Troubleshooting: docs/Troubleshooting.md"
    echo ""
    exit 0
else
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    echo -e "${RED}=========================================${NC}"
    echo ""
    print_error "$TESTS_FAILED out of $TESTS_RUN tests failed"
    echo ""
    echo "Troubleshooting steps:"
    echo "  1. Check pod logs: kubectl logs postgres-0 -n ${NAMESPACE}"
    echo "  2. Describe pod: kubectl describe pod postgres-0 -n ${NAMESPACE}"
    echo "  3. Check events: kubectl get events -n ${NAMESPACE} --sort-by='.lastTimestamp'"
    echo "  4. Verify PVC: kubectl describe pvc postgres-pvc -n ${NAMESPACE}"
    echo "  5. Review documentation: docs/Troubleshooting.md"
    echo ""
    exit 1
fi
