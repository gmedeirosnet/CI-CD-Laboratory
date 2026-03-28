# Upgrade Plan: CI-CD-Laboratory (20260327160618)

- **Generated**: 2026-03-27 16:06:18
- **HEAD Branch**: appmod/java-upgrade-20260327-154708
- **HEAD Commit ID**: 09895e1

## Available Tools

**JDKs**
- JDK 21.0.10: /opt/homebrew/Cellar/openjdk@21/21.0.10/libexec/openjdk.jdk/Contents/Home (current, used in step 2 baseline)
- JDK 25.0.2: /opt/homebrew/Cellar/openjdk/25.0.2/libexec/openjdk.jdk/Contents/Home (target, used in steps 3 and 4)

**Build Tools**
- Maven 3.9.14: /opt/homebrew/Cellar/maven/3.9.14/bin (used for all steps; Maven 3.9.x supports Java 25 compilation via maven-compiler-plugin)
- No Maven Wrapper present in project

## Guidelines

> Note: You can add any specific guidelines or constraints for the upgrade process here if needed, bullet points are preferred.

## Options

- Working branch: appmod/java-upgrade-20260327160618
- Run tests before and after the upgrade: true

## Upgrade Goals

- Upgrade Java from 21 to 25 (latest LTS)

### Technology Stack

| Technology/Dependency | Current | Min Compatible | Why Incompatible |
| --------------------- | ------- | -------------- | ---------------- |
| Java | 21 | 25 | User requested upgrade to latest LTS |
| maven-compiler-plugin | 3.13.0 | 3.13.0 | Already compatible; supports Java 25 via JDK delegation |
| Spring Boot | 3.5.7 | 3.3.x | Spring Boot 3.3+ supports Java 25; 3.5.7 already compatible |
| Lombok | 1.18.36 | 1.18.36 | Compatible with Java 25 |
| Maven | 3.9.14 | 3.9.x | Maven 3.9.x can invoke Java 25 compiler via maven-compiler-plugin |

### Derived Upgrades

- Update `maven.compiler.source` and `maven.compiler.target` properties from 21 to 25 (required to target Java 25 bytecode)
- Update `<source>`, `<target>`, `<release>` in maven-compiler-plugin configuration from 21 to 25

## Upgrade Steps

- **Step 1: Setup Environment**
  - **Rationale**: Confirm JDK 25 is available (already installed); no installations needed.
  - **Changes to Make**:
    - [ ] Verify JDK 25.0.2 is accessible at /opt/homebrew/Cellar/openjdk/25.0.2/...
  - **Verification**:
    - Command: `/opt/homebrew/Cellar/openjdk/25.0.2/libexec/openjdk.jdk/Contents/Home/bin/java -version`
    - Expected: Java 25 reported

---

- **Step 2: Setup Baseline**
  - **Rationale**: Establish pre-upgrade compile and test results using current Java 21.
  - **Changes to Make**:
    - [ ] Run compile and test with Java 21
  - **Verification**:
    - Command: `JAVA_HOME=/opt/homebrew/Cellar/openjdk@21/21.0.10/libexec/openjdk.jdk/Contents/Home mvn clean test -q`
    - JDK: Java 21
    - Expected: Document compile SUCCESS and test pass rate

---

- **Step 3: Upgrade Java source/target to 25**
  - **Rationale**: Update pom.xml compiler settings to target Java 25 bytecode.
  - **Changes to Make**:
    - [ ] Update `maven.compiler.source` from 21 to 25
    - [ ] Update `maven.compiler.target` from 21 to 25
    - [ ] Update `<source>`, `<target>`, `<release>` in maven-compiler-plugin from 21 to 25
  - **Verification**:
    - Command: `JAVA_HOME=/opt/homebrew/Cellar/openjdk/25.0.2/libexec/openjdk.jdk/Contents/Home mvn clean test-compile -q`
    - JDK: Java 25
    - Expected: Compilation SUCCESS

---

- **Step 4: Final Validation**
  - **Rationale**: Verify all upgrade goals met, all tests pass with Java 25.
  - **Changes to Make**:
    - [ ] Verify Java 25 in pom.xml
    - [ ] Run full test suite with Java 25
    - [ ] Fix any test failures
  - **Verification**:
    - Command: `JAVA_HOME=/opt/homebrew/Cellar/openjdk/25.0.2/libexec/openjdk.jdk/Contents/Home mvn clean test -q`
    - JDK: Java 25
    - Expected: Compilation SUCCESS + 100% tests pass

## Key Challenges

- **Java 25 Preview Features / JEP Changes**
  - **Challenge**: Java 25 introduces new language features and some deprecated APIs may be removed.
  - **Strategy**: The codebase uses standard Spring Boot patterns; no exotic Java 21 preview features are in use, so breaking changes are unlikely.

## Plan Review

- All steps are minimal and focused: only compiler version properties need updating in pom.xml.
- Spring Boot 3.5.7 is compatible with Java 25.
- Lombok 1.18.36 is compatible with Java 25.
- Direct upgrade from 21 to 25 is safe (no intermediate needed; both are LTS versions on adjacent release lines).
- No limitations identified.
