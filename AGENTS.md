# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

The certsuite-probe is a utility container image that serves as a testing and debugging tool deployed into Kubernetes clusters during CNF (Cloud-Native Network Functions) certification testing. It is used by the [CNF Certification Suite](https://github.com/redhat-best-practices-for-k8s/certsuite) to perform in-cluster validation of CNFs against Red Hat's best practices.

### Purpose

The probe image provides a controlled, verified toolset for certification testing without modifying the CNF containers themselves. It enables:

- **Network Testing**: Verifying connectivity, DNS resolution, and network policy enforcement
- **Resource Inspection**: Checking CPU, memory, PCI devices, and block storage configurations
- **Security Validation**: Inspecting SELinux contexts, capabilities, and container security settings
- **Container Operations**: Testing container lifecycle, image pulling, and pod-to-pod communication

### Included Tools

The probe image includes:

- **Networking Tools**: `ethtool`, `iproute`, `iptables`, `nftables`, `net-tools`, `iputils`
- **System Utilities**: `pciutils` (lspci), `procps-ng`, `util-linux` (lscpu, lsblk)
- **Container Runtime**: Podman v4.9.5 (built from source on UBI8)
- **API Testing**: `grpcurl` v1.9.3 (for gRPC API validation)
- **Additional Tools**: `jq`, `libselinux-utils`, `golang`

## Image Distribution

The probe image is published to Quay.io:
- **Primary**: `quay.io/redhat-best-practices-for-k8s/certsuite-probe:latest`
- **Legacy**: `quay.io/testnetworkfunction/k8s-best-practices-debug:latest`

### Multi-Architecture Support

Images are built for:
- `linux/amd64`
- `linux/arm64`
- `linux/ppc64le`
- `linux/s390x`

### Build Schedule

- **Daily**: Nightly builds at 5 AM UTC with latest security patches
- **On Release**: When a new version is published
- **Manual**: Via workflow dispatch

## Build Commands

This repository does not have a Makefile. The image is built using Docker/Podman directly.

### Build the Image Locally

```bash
docker build -t certsuite-probe:latest .
```

### Build with Specific Platform

```bash
docker build --platform linux/amd64 -t certsuite-probe:latest .
```

### Build Without Cache

```bash
docker build --no-cache -t certsuite-probe:latest .
```

## Testing

### Manual Testing

After building the image, verify the required tools are installed:

```bash
# Check system utilities
docker run certsuite-probe:latest which lscpu
docker run certsuite-probe:latest which lsblk
docker run certsuite-probe:latest which lspci

# Check networking tools
docker run certsuite-probe:latest which ping
docker run certsuite-probe:latest which ip

# Check Podman
docker run certsuite-probe:latest /root/podman/podman --version

# Check grpcurl
docker run certsuite-probe:latest grpcurl --version
```

### Preflight Certification Check

The repository includes a preflight workflow that validates the image against Red Hat container certification requirements:

```bash
# Clone and build preflight
git clone https://github.com/redhat-openshift-ecosystem/openshift-preflight
cd openshift-preflight
make build

# Run preflight check
./preflight check container quay.io/redhat-best-practices-for-k8s/certsuite-probe:latest
```

**Known Allowed Failures**: The preflight check allows the following failures as expected:
- `HasLicense`
- `RunAsNonRoot`
- `HasNoProhibitedLabels`

## Code Organization

```
certsuite-probe/
├── .github/
│   ├── actions/
│   │   └── slack-webhook-sender/   # Slack notification action
│   ├── workflows/
│   │   ├── debug-image.yaml        # Main build/push workflow (daily + release)
│   │   ├── pre-main.yaml           # PR validation workflow
│   │   └── preflight.yml           # Daily preflight certification check
│   └── dependabot.yaml             # Automated dependency updates
├── Dockerfile                       # Multi-stage build definition
├── README.md                        # Project documentation
├── LICENSE                          # Apache 2.0 license
└── rebase_all.sh                   # Utility script for rebasing branches
```

## Dockerfile Structure

The Dockerfile uses a multi-stage build:

1. **Stage 1 (podman-builder)**: Builds Podman v4.9.5 from source using UBI8
   - Uses UBI 8.10 (required for Podman compatibility)
   - Installs build dependencies: git, make, golang, gpgme-devel, etc.
   - Clones and builds Podman

2. **Stage 2 (final image)**: Creates the probe image using UBI9
   - Uses UBI 9.7 as the base
   - Installs networking and system tools
   - Installs grpcurl via `go install`
   - Copies the built Podman binary from stage 1
   - Exposes `/host` as a volume mount point

**Important Note**: Podman must be built from UBI8 only. Do not upgrade it to UBI9 due to compatibility requirements.

## Key Dependencies

### Base Images
- **Build Stage**: `registry.access.redhat.com/ubi8/ubi:8.10` (for Podman build)
- **Final Stage**: `registry.access.redhat.com/ubi9/ubi:9.7`

### External Tools
- **Podman**: v4.9.5 (built from source)
- **grpcurl**: v1.9.3 (installed via `go install`)
- **Go**: Installed from UBI9 repos (for grpcurl installation)

### System Packages (from UBI9)
- `ethtool`, `iproute`, `iptables`, `iputils`
- `jq`, `libselinux-utils`
- `net-tools`, `nftables`
- `pciutils`, `procps-ng`, `util-linux`

## Development Guidelines

### Updating Base Images

Base image versions are pinned in the Dockerfile. Dependabot is configured to create PRs for Docker base image updates daily. When updating:

1. Test the new base image builds correctly
2. Verify all required tools are still available
3. Run the preflight certification check
4. Ensure multi-architecture builds succeed

### Adding New Tools

When adding new tools to the probe image:

1. Add the package to the `dnf install` command in the Dockerfile
2. Add a verification step in the CI workflow (`.github/workflows/debug-image.yaml`)
3. Document the tool and its purpose in README.md

### Go Version

The CI workflows use Go 1.25 for building and testing.

### Linting

The Dockerfile should pass `hadolint` validation. Some rules are intentionally ignored:
- `DL3041`: Allowed because we use `--assumeyes` with dnf

## CI/CD Workflows

### debug-image.yaml

Main workflow that builds and pushes images:
- **Trigger**: Daily schedule (5 AM UTC), releases, manual dispatch
- **Actions**:
  - Builds the image
  - Tests tool availability (lscpu, lsblk, lspci, ping, ip)
  - Pushes to both legacy and new Quay.io locations
  - Sends Slack alert on failure

### pre-main.yaml

PR validation workflow:
- **Trigger**: Pull requests to main branch
- **Actions**: Builds the image to verify it compiles correctly

### preflight.yml

Red Hat container certification validation:
- **Trigger**: Daily schedule (midnight UTC), PRs to main, manual dispatch
- **Actions**: Runs preflight certification checks against the image

## Volume Mounts

The probe image exposes `/host` as a volume mount point. When deployed in Kubernetes, this is typically used to mount the host filesystem for inspection purposes:

```yaml
volumeMounts:
  - name: host
    mountPath: /host
volumes:
  - name: host
    hostPath:
      path: /
```

## Integration with Certsuite

The certsuite deploys the probe as a DaemonSet or Pod to perform tests from within the cluster. This provides:

- Consistent testing environment across different CNF deployments
- Parallel testing across multiple nodes
- Access to host resources for inspection
- Network testing capabilities between pods
