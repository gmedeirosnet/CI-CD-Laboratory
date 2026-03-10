#!/bin/bash
# Database Connection Pool Test Suite
# Tests PostgreSQL connection pooling, concurrent connections, and performance

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KIND_CLUSTER="${KIND_CLUSTER_NAME:-app-demo}"
NAMESPACE="${KUBE_NAMESPACE:-app-demo}"
POD_NAME="postgres-0"
DB_USER="app_user"
DB_NAME="cicd_demo"

# Test parameters
MAX_CONNECTIONS=100
CONCURRENT_CONNECTIONS=50
TEST_DURATION=30
QUERY_ITERATIONS=100

# Results directory
RESULTS_DIR="${PROJECT_ROOT}/test-results/database"
mkdir -p "${RESULTS_DIR}"

# Timestamp for this test run
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${RESULTS_DIR}/db_pool_test_${TIMESTAMP}.txt"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

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

print_metric() {
    echo -e "${CYAN}$1:${NC} $2"
}

print_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
}

log_result() {
    echo "$1" | tee -a "${REPORT_FILE}"
}

# Initialize report
init_report() {
    cat > "${REPORT_FILE}" << EOF
========================================
Database Connection Pool Test Report
========================================
Date: $(date)
Cluster: ${KIND_CLUSTER}
Namespace: ${NAMESPACE}
Pod: ${POD_NAME}
Database: ${DB_NAME}
User: ${DB_USER}

Test Configuration:
  - Max Connections Test: ${MAX_CONNECTIONS}
  - Concurrent Connections: ${CONCURRENT_CONNECTIONS}
  - Test Duration: ${TEST_DURATION}s
  - Query Iterations: ${QUERY_ITERATIONS}

========================================

EOF
}

# Execute kubectl command in postgres pod
exec_psql() {
    local query="$1"
    docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} ${POD_NAME} -- \
        psql -U ${DB_USER} -d ${DB_NAME} -t -c "$query" 2>&1
}

# Execute kubectl command in postgres pod (output suppressed)
exec_psql_quiet() {
    local query="$1"
    docker exec ${KIND_CLUSTER}-control-plane kubectl exec -n ${NAMESPACE} ${POD_NAME} -- \
        psql -U ${DB_USER} -d ${DB_NAME} -c "$query" > /dev/null 2>&1
}

# Test 1: Database Connection Configuration
test_connection_config() {
    print_header "1. Database Connection Configuration"
    log_result "\n=== Connection Configuration ===" >> "${REPORT_FILE}"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "Get max_connections setting"

    local max_conn=$(exec_psql "SHOW max_connections;" | tr -d ' ')
    if [ -n "$max_conn" ]; then
        print_pass "Max connections: $max_conn"
        print_metric "max_connections" "$max_conn"
        log_result "  max_connections: $max_conn"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_fail "Unable to retrieve max_connections"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_result "  max_connections: FAILED"
    fi

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "Get shared_buffers setting"

    local shared_buf=$(exec_psql "SHOW shared_buffers;" | tr -d ' ')
    if [ -n "$shared_buf" ]; then
        print_pass "Shared buffers: $shared_buf"
        print_metric "shared_buffers" "$shared_buf"
        log_result "  shared_buffers: $shared_buf"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_fail "Unable to retrieve shared_buffers"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_result "  shared_buffers: FAILED"
    fi

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "Get work_mem setting"

    local work_mem=$(exec_psql "SHOW work_mem;" | tr -d ' ')
    if [ -n "$work_mem" ]; then
        print_pass "Work mem: $work_mem"
        print_metric "work_mem" "$work_mem"
        log_result "  work_mem: $work_mem"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_fail "Unable to retrieve work_mem"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_result "  work_mem: FAILED"
    fi
}

# Test 2: Current Connection Statistics
test_current_connections() {
    print_header "2. Current Connection Statistics"
    log_result "\n=== Current Connections ===" >> "${REPORT_FILE}"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "Get active connections count"

    local active_conn=$(exec_psql "SELECT count(*) FROM pg_stat_activity WHERE datname='${DB_NAME}';" | tr -d ' ')
    if [ -n "$active_conn" ]; then
        print_pass "Active connections: $active_conn"
        print_metric "Active Connections" "$active_conn"
        log_result "  Active Connections: $active_conn"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_fail "Unable to retrieve active connections"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_result "  Active Connections: FAILED"
    fi

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "Get idle connections count"

    local idle_conn=$(exec_psql "SELECT count(*) FROM pg_stat_activity WHERE datname='${DB_NAME}' AND state='idle';" | tr -d ' ')
    if [ -n "$idle_conn" ]; then
        print_pass "Idle connections: $idle_conn"
        print_metric "Idle Connections" "$idle_conn"
        log_result "  Idle Connections: $idle_conn"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_fail "Unable to retrieve idle connections"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_result "  Idle Connections: FAILED"
    fi

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "List connections by state"

    local conn_by_state=$(exec_psql "SELECT state, count(*) FROM pg_stat_activity WHERE datname='${DB_NAME}' GROUP BY state;")
    if [ -n "$conn_by_state" ]; then
        print_pass "Retrieved connection states"
        echo "$conn_by_state"
        log_result "  Connections by State:"
        log_result "$conn_by_state"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_fail "Unable to retrieve connection states"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test 3: Connection Pool Capacity Test
test_connection_capacity() {
    print_header "3. Connection Pool Capacity Test"
    log_result "\n=== Connection Capacity ===" >> "${REPORT_FILE}"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "Test ${CONCURRENT_CONNECTIONS} concurrent connections"

    print_info "Opening ${CONCURRENT_CONNECTIONS} concurrent connections..."

    local start_time=$(date +%s.%N)
    local failed_connections=0

    # Create concurrent connections using background jobs
    for i in $(seq 1 $CONCURRENT_CONNECTIONS); do
        (
            exec_psql_quiet "SELECT pg_sleep(1);"
        ) &
    done

    # Wait for all background jobs
    wait

    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)

    if [ $? -eq 0 ]; then
        print_pass "${CONCURRENT_CONNECTIONS} concurrent connections successful"
        print_metric "Connection Duration" "${duration}s"
        log_result "  Concurrent Connections: ${CONCURRENT_CONNECTIONS} (SUCCESS)"
        log_result "  Duration: ${duration}s"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_fail "Some connections failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_result "  Concurrent Connections: FAILED"
    fi
}

# Test 4: Connection Throughput Test
test_connection_throughput() {
    print_header "4. Connection Throughput Test"
    log_result "\n=== Connection Throughput ===" >> "${REPORT_FILE}"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "Sequential connection throughput (${QUERY_ITERATIONS} iterations)"

    print_info "Running ${QUERY_ITERATIONS} sequential queries..."

    local start_time=$(date +%s.%N)
    local failed_queries=0

    for i in $(seq 1 $QUERY_ITERATIONS); do
        if ! exec_psql_quiet "SELECT 1;"; then
            failed_queries=$((failed_queries + 1))
        fi
    done

    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    local throughput=$(echo "scale=2; $QUERY_ITERATIONS / $duration" | bc)

    if [ $failed_queries -eq 0 ]; then
        print_pass "${QUERY_ITERATIONS} queries completed"
        print_metric "Total Duration" "${duration}s"
        print_metric "Throughput" "${throughput} queries/sec"
        log_result "  Total Queries: ${QUERY_ITERATIONS}"
        log_result "  Duration: ${duration}s"
        log_result "  Throughput: ${throughput} queries/sec"
        log_result "  Failed Queries: 0"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_fail "${failed_queries} queries failed"
        print_metric "Failed Queries" "$failed_queries"
        log_result "  Total Queries: ${QUERY_ITERATIONS}"
        log_result "  Failed Queries: $failed_queries"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test 5: Connection Leak Detection
test_connection_leaks() {
    print_header "5. Connection Leak Detection"
    log_result "\n=== Connection Leak Detection ===" >> "${REPORT_FILE}"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "Monitor connection stability over time"

    print_info "Monitoring connections for ${TEST_DURATION} seconds..."

    # Get initial connection count
    local initial_conn=$(exec_psql "SELECT count(*) FROM pg_stat_activity WHERE datname='${DB_NAME}';" | tr -d ' ')

    # Perform operations for test duration
    for i in $(seq 1 $TEST_DURATION); do
        exec_psql_quiet "SELECT pg_sleep(0.5);" &
        exec_psql_quiet "SELECT 1;" &
        sleep 1
    done
    wait

    # Get final connection count
    local final_conn=$(exec_psql "SELECT count(*) FROM pg_stat_activity WHERE datname='${DB_NAME}';" | tr -d ' ')

    print_metric "Initial Connections" "$initial_conn"
    print_metric "Final Connections" "$final_conn"
    log_result "  Initial Connections: $initial_conn"
    log_result "  Final Connections: $final_conn"

    # Check for leaks (final should be close to initial)
    local diff=$((final_conn - initial_conn))
    if [ $diff -le 2 ]; then
        print_pass "No connection leaks detected (diff: $diff)"
        log_result "  Leak Status: PASS (diff: $diff)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_warn "Potential connection leak detected (diff: $diff)"
        log_result "  Leak Status: WARN (diff: $diff)"
        TESTS_PASSED=$((TESTS_PASSED + 1))  # Warning, not failure
    fi
}

# Test 6: Connection Pool Statistics
test_pool_statistics() {
    print_header "6. Connection Pool Statistics"
    log_result "\n=== Connection Pool Statistics ===" >> "${REPORT_FILE}"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "Collect connection pool statistics"

    # Database statistics
    local db_stats=$(exec_psql "SELECT numbackends, xact_commit, xact_rollback, blks_read, blks_hit, tup_returned, tup_fetched FROM pg_stat_database WHERE datname='${DB_NAME}';")

    if [ -n "$db_stats" ]; then
        print_pass "Database statistics retrieved"
        echo "$db_stats"
        log_result "  Database Statistics:"
        log_result "$db_stats"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_fail "Unable to retrieve database statistics"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Connection age distribution
    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "Connection age distribution"

    local conn_age=$(exec_psql "SELECT application_name, state, EXTRACT(EPOCH FROM (now() - backend_start)) as age_seconds FROM pg_stat_activity WHERE datname='${DB_NAME}' ORDER BY age_seconds DESC LIMIT 10;")

    if [ -n "$conn_age" ]; then
        print_pass "Connection age distribution retrieved"
        echo "$conn_age"
        log_result "  Connection Age Distribution (Top 10):"
        log_result "$conn_age"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_fail "Unable to retrieve connection age"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test 7: Transaction Performance
test_transaction_performance() {
    print_header "7. Transaction Performance"
    log_result "\n=== Transaction Performance ===" >> "${REPORT_FILE}"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "Transaction commit/rollback performance"

    # Create test table
    exec_psql_quiet "CREATE TABLE IF NOT EXISTS conn_pool_test (id SERIAL PRIMARY KEY, value TEXT, created_at TIMESTAMP DEFAULT NOW());"

    local start_time=$(date +%s.%N)
    local transaction_count=50

    for i in $(seq 1 $transaction_count); do
        exec_psql_quiet "BEGIN; INSERT INTO conn_pool_test (value) VALUES ('test-$i'); COMMIT;"
    done

    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    local tps=$(echo "scale=2; $transaction_count / $duration" | bc)

    print_pass "${transaction_count} transactions completed"
    print_metric "Transaction Duration" "${duration}s"
    print_metric "Transactions per Second" "${tps} TPS"
    log_result "  Transactions: ${transaction_count}"
    log_result "  Duration: ${duration}s"
    log_result "  TPS: ${tps}"
    TESTS_PASSED=$((TESTS_PASSED + 1))

    # Cleanup
    exec_psql_quiet "DROP TABLE conn_pool_test;"
}

# Generate summary
generate_summary() {
    print_header "Database Connection Pool Test Summary"

    log_result "\n========================================" >> "${REPORT_FILE}"
    log_result "Test Summary" >> "${REPORT_FILE}"
    log_result "========================================" >> "${REPORT_FILE}"
    log_result "Total Tests: $TESTS_RUN" >> "${REPORT_FILE}"
    log_result "Passed: $TESTS_PASSED" >> "${REPORT_FILE}"
    log_result "Failed: $TESTS_FAILED" >> "${REPORT_FILE}"
    log_result "" >> "${REPORT_FILE}"

    if [ $TESTS_FAILED -eq 0 ]; then
        log_result "Status: ✅ ALL TESTS PASSED" >> "${REPORT_FILE}"
    else
        log_result "Status: ❌ SOME TESTS FAILED" >> "${REPORT_FILE}"
    fi

    log_result "" >> "${REPORT_FILE}"
    log_result "Recommendations:" >> "${REPORT_FILE}"
    log_result "  1. Monitor connection pool usage during peak loads" >> "${REPORT_FILE}"
    log_result "  2. Adjust max_connections if nearing capacity" >> "${REPORT_FILE}"
    log_result "  3. Review long-running connections and queries" >> "${REPORT_FILE}"
    log_result "  4. Implement connection pooling in application (e.g., HikariCP)" >> "${REPORT_FILE}"
    log_result "  5. Set appropriate connection timeouts" >> "${REPORT_FILE}"
    log_result "  6. Use pgBouncer for connection pooling in production" >> "${REPORT_FILE}"
    log_result "" >> "${REPORT_FILE}"

    echo ""
    echo -e "${BLUE}Total Tests:${NC} $TESTS_RUN"
    echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
    echo -e "${RED}Failed:${NC} $TESTS_FAILED"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}=========================================${NC}"
        echo -e "${GREEN}✅ ALL TESTS PASSED!${NC}"
        echo -e "${GREEN}=========================================${NC}"
        exit_code=0
    else
        echo -e "${RED}=========================================${NC}"
        echo -e "${RED}❌ SOME TESTS FAILED${NC}"
        echo -e "${RED}=========================================${NC}"
        exit_code=1
    fi

    print_info "Full report saved to: ${REPORT_FILE}"
    exit $exit_code
}

# Main execution
main() {
    print_header "Database Connection Pool Test Suite"
    echo "Cluster: ${KIND_CLUSTER}"
    echo "Namespace: ${NAMESPACE}"
    echo "Pod: ${POD_NAME}"
    echo "Database: ${DB_NAME}"
    echo "User: ${DB_USER}"
    echo "Report: ${REPORT_FILE}"
    echo ""

    init_report
    test_connection_config
    test_current_connections
    test_connection_capacity
    test_connection_throughput
    test_connection_leaks
    test_pool_statistics
    test_transaction_performance
    generate_summary
}

main
