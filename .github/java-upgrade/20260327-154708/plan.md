# Java Upgrade Plan

**Session ID**: 20260327-154708
**Project**: CI-CD-Laboratory
**Created**: 2026-03-27 15:47:08
**Current Branch**: main
**Current Commit**: 09895e1105db03b5810f01af68e144817ced9bc7
**Working Branch**: appmod/java-upgrade-20260327-154708

---

## Overview

This plan upgrades the CI-CD-Laboratory project from Java 21 to Java 25 (LTS).

### Upgrade Goals

| Component | Current Version | Target Version | Status |
|-----------|----------------|----------------|---------|
| Java      | 21 (LTS)       | 25 (LTS)       | Target  |

### Options

- **Run tests before and after the upgrade**: true
- **Git version control**: true
- **Build tool wrapper**: Maven Wrapper (mvnw) present

### Guidelines

- Maintain compatibility with Spring Boot 3.5.7
- Ensure all integration points (Jenkins, Harbor, ArgoCD) continue to function
- Preserve existing CI/CD pipeline behavior
- Maintain backward compatibility with Kubernetes deployments

---

## Environment Analysis

### Available Tools

| Tool | Version | Path | Compatible | Notes |
|------|---------|------|------------|-------|
| Maven | 3.9.14 | /opt/homebrew/Cellar/maven/3.9.14/libexec | ✅ Yes | Supports Java 25 |
| Maven Wrapper | (wrapper-defined) | ./mvnw | ✅ Yes | Will use wrapper for builds |
| Java 21 | 21.0.10 | /opt/homebrew/Cellar/openjdk@21/21.0.10/libexec/openjdk.jdk/Contents/Home | ✅ Current | Baseline for testing |
| Java 25 | TBD | `<TO_BE_INSTALLED>` | ⏳ Pending | Required for Step 1; will install via Homebrew |

**Note**: Maven Wrapper will be used for all build operations to ensure consistency.

---

## Technology Stack

### Core Dependencies

| Dependency | Current Version | Compatible with Java 25? | Upgrade Required? | Target Version |
|------------|----------------|--------------------------|-------------------|----------------|
| Spring Boot | 3.5.7 | ✅ Yes | No | 3.5.7 |
| Spring Framework | (managed by Boot) | ✅ Yes | No | (managed) |
| PostgreSQL Driver | 42.7.7 | ✅ Yes | No | 42.7.7 |
| Flyway | 10.21.0 | ✅ Yes | No | 10.21.0 |
| Lombok | 1.18.36 | ✅ Yes | No | 1.18.36 |
| JUnit Jupiter | 5.10.3 | ✅ Yes | No | 5.10.3 |
| Jackson BOM | 2.19.2 | ✅ Yes | No | 2.19.2 |

### Build Plugins

| Plugin | Current Version | Compatible with Java 25? | Upgrade Required? | Target Version |
|--------|----------------|--------------------------|-------------------|----------------|
| spring-boot-maven-plugin | 3.5.7 | ✅ Yes | No | 3.5.7 |
| maven-compiler-plugin | 3.13.0 | ✅ Yes | No | 3.13.0 |

**Analysis**: All dependencies and plugins are compatible with Java 25. No dependency upgrades required.

---

## Derived Upgrades

| Component | Reason | Upgrade Strategy |
|-----------|--------|------------------|
| None | All dependencies are compatible with Java 25 | Direct upgrade to Java 25 |

---

## Key Challenges

### Challenge 1: Java 25 Installation
**Risk**: Medium
**Description**: Java 25 needs to be installed on the system. If installation fails, the upgrade cannot proceed.
**Mitigation**: Use Homebrew package manager for reliable installation. Verify installation before proceeding to compilation steps.

### Challenge 2: Maven Compiler Plugin Configuration
**Risk**: Low
**Description**: Compiler plugin needs source/target/release updated from 21 to 25.
**Mitigation**: Update all three properties atomically in a single step. Verify compilation of both main and test code.

### Challenge 3: Integration Test Compatibility
**Risk**: Medium
**Description**: Integration tests may reveal runtime behavior changes between Java 21 and 25, particularly in areas like garbage collection, concurrency, or reflection.
**Mitigation**: Establish baseline test results with Java 21 first. Document any test failures and investigate root causes. Fix tests or update implementation as needed.

### Challenge 4: Docker Image Build
**Risk**: Low
**Description**: Dockerfile uses openjdk:21-jdk-slim as base image. Harbor registry integration may need verification.
**Mitigation**: Update Dockerfile to openjdk:25-jdk-slim. Verify Docker build locally before pipeline integration.

---

## Upgrade Steps

### Step 1: Setup Environment
**Goal**: Install Java 25 and verify Maven compatibility
**Dependencies**: None
**Risk**: Medium

**Actions**:
1. Install Java 25 LTS using Homebrew: `brew install openjdk@25`
2. Verify installation: `java -version` and `/usr/libexec/java_home -V`
3. Set JAVA_HOME for build: `export JAVA_HOME=$(/usr/libexec/java_home -v 25)`
4. Verify Maven can use Java 25: `mvn --version`
5. Document Java 25 installation path for subsequent steps

**Verification**:
- Command: `java -version`
- Expected: openjdk version "25.x.x"
- JDK: Java 25

---

### Step 2: Setup Baseline
**Goal**: Establish baseline compilation and test results with current Java 21
**Dependencies**: None
**Risk**: Low

**Actions**:
1. Stash any uncommitted changes: `git stash push -u -m "java-upgrade-baseline-20260327-154708"`
2. Switch to working branch: `git checkout -b appmod/java-upgrade-20260327-154708`
3. Compile with Java 21: `./mvnw clean test-compile -DskipTests`
4. Run tests with Java 21: `./mvnw clean test`
5. Document baseline test pass rate and any pre-existing failures
6. Record baseline metrics (test count, pass rate, compilation time)

**Verification**:
- Command: `./mvnw clean test`
- Expected: Compilation success; document test results (pass/fail counts)
- JDK: Java 21

---

### Step 3: Update Maven Compiler Plugin Configuration
**Goal**: Configure Maven to compile with Java 25
**Dependencies**: Step 1 (Java 25 installed)
**Risk**: Low

**Actions**:
1. Update `pom.xml` properties:
   - Change `<maven.compiler.source>21</maven.compiler.source>` to `25`
   - Change `<maven.compiler.target>21</maven.compiler.target>` to `25`
2. Update `maven-compiler-plugin` configuration:
   - Change `<source>21</source>` to `25`
   - Change `<target>21</target>` to `25`
   - Change `<release>21</release>` to `25`
3. Commit changes with message: "Step 3: Update Maven compiler to Java 25"

**Verification**:
- Command: `./mvnw clean test-compile`
- Expected: Compilation success for both main and test code
- JDK: Java 25

---

### Step 4: Update Dockerfile Base Image
**Goal**: Update Docker base image to Java 25
**Dependencies**: Step 3 (compiler configuration updated)
**Risk**: Low

**Actions**:
1. Update `Dockerfile`:
   - Change `FROM openjdk:21-jdk-slim` to `FROM openjdk:25-jdk-slim`
   - Update any JAVA_VERSION or similar environment variables if present
2. Verify Docker build: `docker build -t cicd-demo:test .`
3. Commit changes with message: "Step 4: Update Dockerfile to Java 25"

**Verification**:
- Command: `docker build -t cicd-demo:test .`
- Expected: Docker build succeeds with Java 25 base image
- JDK: Java 25

---

### Step 5: Run Full Test Suite
**Goal**: Verify all tests pass with Java 25
**Dependencies**: Steps 1-4
**Risk**: Medium

**Actions**:
1. Clean and run full test suite: `./mvnw clean test`
2. Investigate any test failures:
   - Compare against baseline (Step 2) to identify new failures
   - For each failure: analyze root cause, determine if application or test needs fix
   - Document findings and fixes
3. Fix any Java 25-specific issues (if found)
4. Rerun tests until 100% pass rate achieved (or ≥ baseline)
5. Commit any test fixes with message: "Step 5: Fix tests for Java 25 compatibility"

**Verification**:
- Command: `./mvnw clean test`
- Expected: 100% test pass rate (or ≥ baseline pass rate from Step 2)
- JDK: Java 25

---

### Step 6: Verify Package and Build
**Goal**: Verify Maven package creates working artifact
**Dependencies**: Steps 1-5
**Risk**: Low

**Actions**:
1. Clean and package: `./mvnw clean package`
2. Verify JAR artifact created in `target/` directory
3. Test artifact: `java -jar target/cicd-demo-1.0.0-SNAPSHOT.jar` (with PostgreSQL available)
4. Verify application starts successfully and Actuator endpoints respond
5. Commit if any build configuration changes needed

**Verification**:
- Command: `./mvnw clean package && java -jar target/cicd-demo-1.0.0-SNAPSHOT.jar`
- Expected: JAR builds successfully, application starts without errors
- JDK: Java 25

---

### Step 7: Update CI/CD Pipeline Configuration
**Goal**: Update Jenkinsfile to use Java 25
**Dependencies**: Steps 1-6
**Risk**: Low

**Actions**:
1. Review `Jenkinsfile` for Java version references
2. Update agent/tools configuration if Java version is specified
3. Add note/comment indicating Java 25 requirement
4. Review `Jenkinsfile-kyverno-policies` for similar updates
5. Commit changes with message: "Step 7: Update CI/CD pipelines for Java 25"

**Verification**:
- Command: Review file changes
- Expected: Pipeline configurations updated; no syntax errors
- JDK: Java 25

---

### Step 8: Final Validation
**Goal**: Comprehensive validation of all upgrade success criteria
**Dependencies**: Steps 1-7
**Risk**: Low

**Actions**:
1. **Compilation Check**:
   - Run: `./mvnw clean test-compile`
   - Verify: Both main and test code compile successfully
2. **Test Check**:
   - Run: `./mvnw clean test`
   - Verify: 100% test pass rate (or ≥ baseline)
3. **Package Check**:
   - Run: `./mvnw clean package`
   - Verify: JAR artifact created successfully
4. **Docker Check**:
   - Run: `docker build -t cicd-demo:test .`
   - Verify: Image builds successfully
5. **Version Verification**:
   - Verify all pom.xml references show Java 25
   - Verify Dockerfile references Java 25
6. **TODO Review**:
   - Search codebase for any TODOs added during upgrade
   - Ensure all are resolved or documented as acceptable technical debt
7. If any checks fail: return to relevant step, fix issues, and repeat validation

**Verification**:
- Command: `./mvnw clean package && docker build -t cicd-demo:test .`
- Expected: All compilation, tests, packaging, and Docker build succeed
- JDK: Java 25

---

## Plan Review

### Completeness
- ✅ All upgrade goals defined and achievable
- ✅ Environment setup covers Java 25 installation
- ✅ Baseline establishment ensures comparison point
- ✅ Compiler configuration updates identified
- ✅ Docker image updates included
- ✅ Test validation strategy defined
- ✅ CI/CD pipeline updates considered
- ✅ Final validation covers all success criteria

### Feasibility
- ✅ Java 25 available via Homebrew
- ✅ Maven 3.9.14 supports Java 25
- ✅ Spring Boot 3.5.7 compatible with Java 25
- ✅ All dependencies compatible with Java 25
- ✅ No intermediate versions needed (direct upgrade viable)
- ✅ Rollback possible via git branch management

### Known Limitations
- **None identified**: This is a straightforward Java LTS upgrade with no dependency changes required. All components are already compatible with Java 25.

### Unfixable Issues
- **None anticipated**: All dependencies have been verified for Java 25 compatibility. If unexpected runtime issues emerge during testing, they will be addressed iteratively in Step 5.

---

**Plan Generated**: 2026-03-27 15:47:08
**Ready for Execution**: ✅ Yes
