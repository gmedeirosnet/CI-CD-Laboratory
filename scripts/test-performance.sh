#!/bin/bash
# Performance Benchmark Test Suite
# Measures application performance metrics and generates reports

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KIND_CLUSTER="${KIND_CLUSTER_NAME:-app-demo}"
NAMESPACE="${KUBE_NAMESPACE:-app-demo}"
BACKEND_URL="${BACKEND_URL:-http://localhost:8001}"
FRONTEND_URL="${FRONTEND_URL:-http://localhost:30080}"

# Performance test parameters
WARMUP_REQUESTS=50
LOAD_TEST_REQUESTS=500
CONCURRENT_USERS=10
TIMEOUT=30

# Results directory
RESULTS_DIR="${PROJECT_ROOT}/test-results/performance"
mkdir -p "${RESULTS_DIR}"

# Timestamp for this test run
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${RESULTS_DIR}/benchmark_${TIMESTAMP}.txt"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}=========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=========================================${NC}"
}

print_metric() {
    echo -e "${CYAN}$1:${NC} $2"
}

print_pass() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
}

print_fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
}

# Initialize report
init_report() {
    cat > "${REPORT_FILE}" << EOF
========================================
Performance Benchmark Report
========================================
Date: $(date)
Cluster: ${KIND_CLUSTER}
Namespace: ${NAMESPACE}
Backend URL: ${BACKEND_URL}
Frontend URL: ${FRONTEND_URL}
Test Configuration:
  - Warmup Requests: ${WARMUP_REQUESTS}
  - Load Test Requests: ${LOAD_TEST_REQUESTS}
  - Concurrent Users: ${CONCURRENT_USERS}
  - Timeout: ${TIMEOUT}s

========================================

EOF
}

# Log to both console and report file
log_result() {
    echo "$1" | tee -a "${REPORT_FILE}"
}

# Check if required tools are installed
check_prerequisites() {
    print_header "Checking Prerequisites"

    local missing_tools=()

    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    else
        print_pass "curl is installed"
    fi

    if ! command -v ab &> /dev/null; then
        print_warn "Apache Bench (ab) not found - skipping load tests"
        print_info "Install with: brew install httpd (macOS) or apt-get install apache2-utils (Linux)"
    else
        print_pass "Apache Bench (ab) is installed"
    fi

    if ! command -v hey &> /dev/null; then
        print_warn "hey not found - using alternative tools"
        print_info "Install with: brew install hey (macOS) or go install github.com/rakyll/hey@latest"
    else
        print_pass "hey is installed"
    fi

    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_fail "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
}

# Test 1: Response Time Baseline
test_response_time() {
    print_header "1. Response Time Baseline Test"
    log_result "\n=== Response Time Baseline ===" >> "${REPORT_FILE}"

    local endpoints=(
        "${BACKEND_URL}/actuator/health"
        "${BACKEND_URL}/actuator/info"
        "${BACKEND_URL}/actuator/prometheus"
        "${FRONTEND_URL}"
    )

    local endpoint_names=(
        "Backend Health"
        "Backend Info"
        "Backend Metrics"
        "Frontend"
    )

    for i in "${!endpoints[@]}"; do
        local endpoint="${endpoints[$i]}"
        local name="${endpoint_names[$i]}"

        print_info "Testing: $name"

        # Perform multiple requests to get average
        local total_time=0
        local successful_requests=0

        for j in {1..10}; do
            local response_time=$(curl -s -o /dev/null -w "%{time_total}" "$endpoint" 2>/dev/null || echo "0")
            if [ "$response_time" != "0" ]; then
                total_time=$(echo "$total_time + $response_time" | bc)
                successful_requests=$((successful_requests + 1))
            fi
        done

        if [ $successful_requests -gt 0 ]; then
            local avg_time=$(echo "scale=3; $total_time / $successful_requests" | bc)
            print_metric "$name Response Time" "${avg_time}s"
            log_result "  $name: ${avg_time}s (avg over $successful_requests requests)"

            # Benchmark thresholds
            local threshold=1.0
            if (( $(echo "$avg_time < $threshold" | bc -l) )); then
                print_pass "$name meets performance threshold (<${threshold}s)"
            else
                print_fail "$name exceeds performance threshold (${avg_time}s > ${threshold}s)"
            fi
        else
            print_fail "$name endpoint not responding"
            log_result "  $name: FAILED (no successful requests)"
        fi
    done
}

# Test 2: Database Query Performance
test_database_performance() {
    print_header "2. Database Performance Test"
    log_result "\n=== Database Performance ===" >> "${REPORT_FILE}"

    print_info "Testing PostgreSQL query performance"

    # Simple query test
    local start_time=$(date +%s.%N)
    docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- \
        psql -U app_user -d cicd_demo -c "SELECT COUNT(*) FROM pg_stat_activity;" > /dev/null 2>&1
    local end_time=$(date +%s.%N)
    local query_time=$(echo "$end_time - $start_time" | bc)

    print_metric "Simple Query Time" "${query_time}s"
    log_result "  Simple Query: ${query_time}s"

    # Connection pool test
    print_info "Testing concurrent connections"
    local start_time=$(date +%s.%N)
    for i in {1..10}; do
        docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- \
            psql -U app_user -d cicd_demo -c "SELECT 1;" > /dev/null 2>&1 &
    done
    wait
    local end_time=$(date +%s.%N)
    local concurrent_time=$(echo "$end_time - $start_time" | bc)

    print_metric "10 Concurrent Connections" "${concurrent_time}s"
    log_result "  10 Concurrent Connections: ${concurrent_time}s"

    # Get database statistics
    local db_size=$(docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- \
        psql -U app_user -d cicd_demo -t -c "SELECT pg_size_pretty(pg_database_size('cicd_demo'));" | tr -d ' ')
    print_metric "Database Size" "$db_size"
    log_result "  Database Size: $db_size"

    local active_connections=$(docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} postgres-0 -- \
        psql -U app_user -d cicd_demo -t -c "SELECT count(*) FROM pg_stat_activity WHERE datname='cicd_demo';" | tr -d ' ')
    print_metric "Active Connections" "$active_connections"
    log_result "  Active Connections: $active_connections"
}

# Test 3: Load Testing with Apache Bench
test_load_ab() {
    print_header "3. Load Test (Apache Bench)"

    if ! command -v ab &> /dev/null; then
        print_warn "Apache Bench not available - skipping load test"
        log_result "\n=== Load Test (Apache Bench) ===" >> "${REPORT_FILE}"
        log_result "  SKIPPED: Apache Bench not installed" >> "${REPORT_FILE}"
        return
    fi

    log_result "\n=== Load Test (Apache Bench) ===" >> "${REPORT_FILE}"

    # Warmup
    print_info "Warming up with ${WARMUP_REQUESTS} requests..."
    ab -n ${WARMUP_REQUESTS} -q "${BACKEND_URL}/actuator/health" > /dev/null 2>&1 || true

    # Load test
    print_info "Running load test: ${LOAD_TEST_REQUESTS} requests, ${CONCURRENT_USERS} concurrent users"
    local ab_output=$(ab -n ${LOAD_TEST_REQUESTS} -c ${CONCURRENT_USERS} "${BACKEND_URL}/actuator/health" 2>&1)

    # Parse results
    local requests_per_sec=$(echo "$ab_output" | grep "Requests per second" | awk '{print $4}')
    local time_per_request=$(echo "$ab_output" | grep "Time per request" | head -1 | awk '{print $4}')
    local failed_requests=$(echo "$ab_output" | grep "Failed requests" | awk '{print $3}')

    print_metric "Requests per Second" "$requests_per_sec"
    print_metric "Time per Request" "${time_per_request}ms"
    print_metric "Failed Requests" "$failed_requests"

    log_result "  Requests per Second: $requests_per_sec"
    log_result "  Time per Request: ${time_per_request}ms"
    log_result "  Failed Requests: $failed_requests"

    # Benchmark thresholds
    if (( $(echo "$requests_per_sec > 100" | bc -l) )); then
        print_pass "Throughput meets target (>100 req/s)"
    else
        print_warn "Throughput below target: $requests_per_sec req/s"
    fi

    if [ "$failed_requests" -eq 0 ]; then
        print_pass "No failed requests"
    else
        print_fail "$failed_requests requests failed"
    fi
}

# Test 4: Resource Usage Metrics
test_resource_usage() {
    print_header "4. Resource Usage Metrics"
    log_result "\n=== Resource Usage ===" >> "${REPORT_FILE}"

    print_info "Collecting pod resource usage"

    # Get pod metrics (requires metrics-server in production)
    local pods=$(docker exec ${KIND_CLUSTER}-control-plane kubectl get pods -n ${NAMESPACE} -o jsonpath='{.items[*].metadata.name}')

    for pod in $pods; do
        print_info "Pod: $pod"

        # CPU and Memory limits
        local cpu_limit=$(docker exec ${KIND_CLUSTER}-control-plane kubectl get pod $pod -n ${NAMESPACE} -o jsonpath='{.spec.containers[0].resources.limits.cpu}' 2>/dev/null || echo "N/A")
        local mem_limit=$(docker exec ${KIND_CLUSTER}-control-plane kubectl get pod $pod -n ${NAMESPACE} -o jsonpath='{.spec.containers[0].resources.limits.memory}' 2>/dev/null || echo "N/A")

        print_metric "  CPU Limit" "$cpu_limit"
        print_metric "  Memory Limit" "$mem_limit"

        log_result "  $pod:"
        log_result "    CPU Limit: $cpu_limit"
        log_result "    Memory Limit: $mem_limit"

        # Container restarts
        local restarts=$(docker exec ${KIND_CLUSTER}-control-plane kubectl get pod $pod -n ${NAMESPACE} -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0")
        print_metric "  Restart Count" "$restarts"
        log_result "    Restarts: $restarts"

        if [ "$restarts" -eq 0 ]; then
            print_pass "  No restarts detected"
        else
            print_warn "  Pod has restarted $restarts times"
        fi
    done
}

# Test 5: Cluster Health Metrics
test_cluster_health() {
    print_header "5. Cluster Health Metrics"
    log_result "\n=== Cluster Health ===" >> "${REPORT_FILE}"

    # Node metrics
    local node_count=$(docker exec ${KIND_CLUSTER}-control-plane kubectl get nodes --no-headers | wc -l)
    print_metric "Total Nodes" "$node_count"
    log_result "  Nodes: $node_count"

    local ready_nodes=$(docker exec ${KIND_CLUSTER}-control-plane kubectl get nodes --no-headers | grep " Ready " | wc -l)
    print_metric "Ready Nodes" "$ready_nodes"
    log_result "  Ready Nodes: $ready_nodes"

    # Pod metrics
    local total_pods=$(docker exec ${KIND_CLUSTER}-control-plane kubectl get pods -n ${NAMESPACE} --no-headers | wc -l)
    local running_pods=$(docker exec ${KIND_CLUSTER}-control-plane kubectl get pods -n ${NAMESPACE} --no-headers | grep "Running" | wc -l)

    print_metric "Total Pods in $NAMESPACE" "$total_pods"
    print_metric "Running Pods" "$running_pods"
    log_result "  Total Pods: $total_pods"
    log_result "  Running Pods: $running_pods"

    if [ "$running_pods" -eq "$total_pods" ]; then
        print_pass "All pods are running"
    else
        print_warn "Only $running_pods of $total_pods pods are running"
    fi

    # Storage metrics
    local pvcs=$(docker exec ${KIND_CLUSTER}-control-plane kubectl get pvc -n ${NAMESPACE} --no-headers | wc -l)
    local bound_pvcs=$(docker exec ${KIND_CLUSTER}-control-plane kubectl get pvc -n ${NAMESPACE} --no-headers | grep "Bound" | wc -l)

    print_metric "Total PVCs" "$pvcs"
    print_metric "Bound PVCs" "$bound_pvcs"
    log_result "  PVCs: $pvcs"
    log_result "  Bound PVCs: $bound_pvcs"
}

# Test 6: API Endpoint Performance
test_api_endpoints() {
    print_header "6. API Endpoint Performance"
    log_result "\n=== API Endpoint Performance ===" >> "${REPORT_FILE}"

    local api_endpoints=(
        "${BACKEND_URL}/api/users"
        "${BACKEND_URL}/api/products"
        "${BACKEND_URL}/actuator/health"
        "${BACKEND_URL}/actuator/metrics"
    )

    for endpoint in "${api_endpoints[@]}"; do
        print_info "Testing: $endpoint"

        local total_time=$(curl -s -o /dev/null -w "%{time_total}" "$endpoint" 2>/dev/null || echo "0")
        local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$endpoint" 2>/dev/null || echo "000")
        local size_download=$(curl -s -o /dev/null -w "%{size_download}" "$endpoint" 2>/dev/null || echo "0")

        if [ "$http_code" != "000" ]; then
            print_metric "  HTTP Code" "$http_code"
            print_metric "  Response Time" "${total_time}s"
            print_metric "  Response Size" "${size_download} bytes"

            log_result "  $endpoint:"
            log_result "    HTTP Code: $http_code"
            log_result "    Response Time: ${total_time}s"
            log_result "    Size: ${size_download} bytes"

            if [ "$http_code" = "200" ]; then
                print_pass "  Endpoint healthy"
            else
                print_warn "  Endpoint returned HTTP $http_code"
            fi
        else
            print_fail "  Endpoint not responding"
            log_result "  $endpoint: FAILED"
        fi
    done
}

# Generate summary
generate_summary() {
    print_header "Performance Test Summary"

    log_result "\n========================================" >> "${REPORT_FILE}"
    log_result "Performance Test Summary" >> "${REPORT_FILE}"
    log_result "========================================" >> "${REPORT_FILE}"
    log_result "Report saved to: ${REPORT_FILE}" >> "${REPORT_FILE}"
    log_result "" >> "${REPORT_FILE}"
    log_result "Recommendations:" >> "${REPORT_FILE}"
    log_result "  1. Monitor response times over extended periods" >> "${REPORT_FILE}"
    log_result "  2. Set up alerts for response time thresholds (>1s)" >> "${REPORT_FILE}"
    log_result "  3. Review resource limits if pods are restarting" >> "${REPORT_FILE}"
    log_result "  4. Scale horizontally if throughput is below target" >> "${REPORT_FILE}"
    log_result "  5. Implement caching for frequently accessed endpoints" >> "${REPORT_FILE}"
    log_result "" >> "${REPORT_FILE}"

    print_info "Full report saved to: ${REPORT_FILE}"
    print_pass "Performance benchmark completed successfully"
}

# Main execution
main() {
    print_header "Performance Benchmark Test Suite"
    echo "Cluster: ${KIND_CLUSTER}"
    echo "Namespace: ${NAMESPACE}"
    echo "Backend: ${BACKEND_URL}"
    echo "Frontend: ${FRONTEND_URL}"
    echo "Report: ${REPORT_FILE}"
    echo ""

    init_report
    check_prerequisites
    test_response_time
    test_database_performance
    test_load_ab
    test_resource_usage
    test_cluster_health
    test_api_endpoints
    generate_summary

    echo ""
    print_header "View Report"
    echo "cat ${REPORT_FILE}"
}

main
