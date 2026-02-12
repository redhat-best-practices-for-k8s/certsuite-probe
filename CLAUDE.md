# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

certsuite-probe is a container image repository (no application code). It builds and publishes a utility container used by the [CNF Certification Suite](https://github.com/redhat-best-practices-for-k8s/certsuite) for in-cluster testing and debugging of Cloud-Native Network Functions on OpenShift/Kubernetes.

The image is published to:
- `quay.io/redhat-best-practices-for-k8s/certsuite-probe:latest`
- Legacy: `quay.io/testnetworkfunction/k8s-best-practices-debug:latest`

## Repository Structure

The entire repository consists of a multi-stage `Dockerfile` and CI workflows. There is no Go source code, Makefile, or test suite.

## Building

```bash
docker build -t certsuite-probe:latest .
```

The build has two stages:
1. **podman-builder** (UBI8): Clones and compiles Podman v4.9.5 from source. **Podman must be built from UBI8, not UBI9** (see comment in Dockerfile line 1).
2. **Final image** (UBI9): Installs networking/system tools, Go, grpcurl, and copies the Podman binary from stage 1.

Multi-architecture build (matches CI):
```bash
docker buildx build --platform linux/amd64,linux/arm64,linux/ppc64le,linux/s390x -t certsuite-probe:latest .
```

## Testing

There are no unit tests. CI validates the image by checking that key binaries exist:

```bash
docker run certsuite-probe:latest which lscpu
docker run certsuite-probe:latest which lsblk
docker run certsuite-probe:latest which lspci
docker run certsuite-probe:latest which ping
docker run certsuite-probe:latest which ip
```

Red Hat OpenShift Preflight validation also runs in CI with allowed failures: `HasLicense`, `RunAsNonRoot`, `HasNoProhibitedLabels`.

## CI/CD Workflows

| Workflow | File | Triggers | Purpose |
|----------|------|----------|---------|
| Test/push probe image | `debug-image.yaml` | Daily 5am UTC, release, manual | Build, test, push to both Quay.io registries |
| Test Incoming Changes | `pre-main.yaml` | PRs to main, manual | Build-only validation (no push) |
| Preflight Daily | `preflight.yml` | Daily midnight UTC, PRs, manual | Red Hat container compliance check |

## What Changes Typically Look Like

Most changes in this repo are:
- **Base image version bumps** (UBI8/UBI9 tags in Dockerfile) - usually via Dependabot
- **GitHub Actions version bumps** - also via Dependabot
- **Adding/removing tools** from the `dnf install` list in the Dockerfile
- **Updating Podman or grpcurl versions** in the Dockerfile

## Key Constraints

- The Podman build stage **must use UBI8** - do not upgrade it to UBI9
- Podman is pinned to v4.9.5 (built from source via `git checkout v4.9.5`)
- grpcurl is installed via `go install` at v1.9.3
- The image exposes a `/host` volume mount point used by the certsuite for host filesystem access
