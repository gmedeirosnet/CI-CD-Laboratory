# Black Duck Detect

## What is Black Duck Detect

Black Duck Detect (formerly Synopsys Detect) is a Software Composition Analysis (SCA) tool. It scans dependency manifests (such as `pom.xml`) and compiled JARs to identify open-source components, match them against the NVD and Black Duck's own KnowledgeBase for known CVEs, and report license information for every detected dependency.

In this lab, Detect runs as a one-shot Docker container. It scans the workspace, writes reports to the filesystem, and exits. No persistent Hub server is required — the stage operates in offline/audit mode by default, which means findings are recorded locally rather than uploaded to a central server.

## How it Fits in the Pipeline

The Black Duck stage occupies position 7 of 17 in the Jenkins pipeline. It runs after the Docker image has been built from the compiled artifact and before that image is pushed to Harbor. This placement ensures the SCA scan covers the same code that will be shipped.

```
Stage 1  — Checkout
Stage 2  — Set Build Info
Stage 3  — Build and Test (Maven)
Stage 4  — SonarQube Analysis
Stage 5  — Quality Gate (SonarQube)
Stage 6  — Build Docker Image
Stage 7  — Black Duck Detect          <-- here
Stage 8  — Push to Harbor
Stage 9  — Load Image into Kind
Stage 10 — Package Helm Chart
Stage 11 — ArgoCD Sync
...
```

## Offline vs Hub-Connected Mode

Black Duck Detect supports two operating modes.

**Offline / audit mode** is the default in this lab. Detect downloads vulnerability data as part of its container image and writes results to the local workspace. No network connection to a Hub server is needed. This mode is sufficient for learning and for generating local reports.

**Hub-connected mode** uploads scan results to a Black Duck Hub server, which stores scan history, provides a web UI, supports policy enforcement, and enables team-level dashboards. This mode requires a licensed Hub instance and credentials.

To toggle between modes, set the `BLACKDUCK_URL` environment variable:

- Unset (empty): offline/audit mode
- Set to a Hub server URL (e.g., `https://blackduck.example.com`): Hub-connected mode

When `BLACKDUCK_URL` is unset, the stage skips the Hub upload step automatically.

## Setup

No setup is required. The Black Duck Detect stage is already present in the `Jenkinsfile`. When the stage runs, Jenkins pulls the `blackducksoftware/detect` Docker image automatically. The image includes the Detect JAR and a snapshot of vulnerability data. No additional plugins, credentials, or configuration are needed to run in offline mode.

## Optional: Connect to a Hub Server

If you have access to a Black Duck Hub instance and want to upload scan results, add the following credentials to Jenkins (Manage Jenkins > Credentials > Global):

| Credential ID | Type | Value |
|---|---|---|
| `blackduck-url` | Secret Text | Full URL of your Hub server, e.g. `https://blackduck.example.com` |
| `blackduck-api-token` | Secret Text | API token generated in the Hub UI under your user profile |

Once these credentials exist, the Jenkinsfile reads them via `credentials()` and passes them to Detect. No other changes are needed.

Note: A Hub server requires a commercial license and 8-16 GB of RAM. It is not part of this lab environment and is out of scope.

## Environment Variables

The following variables control Detect behavior. All are optional. Set them in the Jenkins pipeline environment block or as Jenkins global environment variables.

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `BLACKDUCK_DETECT_VERSION` | No | `latest` | Pins the `blackducksoftware/detect` image tag |
| `BLACKDUCK_PROJECT_NAME` | No | `cicd-demo` | Project name displayed in Hub (ignored in offline mode) |
| `BLACKDUCK_PROJECT_VERSION` | No | `${BUILD_NUMBER}` | Version label for this scan in Hub (ignored in offline mode) |
| `BLACKDUCK_URL` | No | (unset) | Hub server URL; if unset, offline mode is used |
| `BLACKDUCK_API_TOKEN` | No | (unset) | Hub API token for authentication; required only when Hub URL is set |

## Running Manually (Standalone)

A Docker Compose file is provided at `docker/blackduck/docker-compose.yml` for running scans outside Jenkins, for example on a developer workstation.

To scan the project locally:

```bash
# From the repository root
cd docker/blackduck

# Run the scan against the project root
docker compose run --rm detect

# View the console output
cat ../../blackduck-reports/detect-output.txt
```

The Compose file mounts the repository root into the container and writes output to `blackduck-reports/` relative to the repository root. Edit `docker/blackduck/docker-compose.yml` to change the scan target or pass additional Detect arguments.

## Reading the Reports

After each Jenkins build, Black Duck Detect writes its output to the `blackduck-reports/` directory inside the Jenkins workspace. Jenkins archives this directory as a build artifact, so reports are accessible from the build page under "Build Artifacts".

Key output files:

| File | Contents |
|---|---|
| `detect-output.txt` | Full console log from the Detect run, including component counts, policy evaluations, and any errors |
| `risk-report.json` | Machine-readable findings: component name, version, CVE identifiers, CVSS scores, and license identifiers for each detected dependency |

To review findings after a build, open the Jenkins build, click "Build Artifacts", and download `blackduck-reports/risk-report.json`. The file can be parsed with `jq` or imported into any JSON viewer.

## Audit Mode

The Black Duck stage is configured in audit mode. The stage records findings but never fails the build, regardless of the number or severity of CVEs detected. This keeps the pipeline moving during the learning phase and avoids blocking deployments on security findings that have not yet been reviewed.

To introduce build failure based on severity at a later stage, add the following argument to the Detect invocation in the Jenkinsfile:

```
--detect.policy.check.fail.on.severities=HIGH,CRITICAL
```

Alternatively, set the `BLACKDUCK_FAIL_ON_SEVERITY` variable if the Jenkinsfile is written to read it. With this flag set, Detect exits with a non-zero code when it finds components with matching severity, and Jenkins marks the build as failed.

## Out of Scope

The following topics are intentionally excluded from this lab:

- Hub server installation, licensing, or administration
- Build failure triggered automatically by CVE findings
- Docker image layer scanning (Detect scans manifests and JARs, not image layers)
- Frontend dependency scanning (`frontend/node_modules`; only the Maven project is scanned)
