# certsuite-probe

[![Test/push the probe image](https://github.com/redhat-best-practices-for-k8s/certsuite-probe/actions/workflows/debug-image.yaml/badge.svg)](https://github.com/redhat-best-practices-for-k8s/certsuite-probe/actions/workflows/debug-image.yaml)
[![Test Incoming Changes](https://github.com/redhat-best-practices-for-k8s/certsuite-probe/actions/workflows/pre-main.yaml/badge.svg)](https://github.com/redhat-best-practices-for-k8s/certsuite-probe/actions/workflows/pre-main.yaml)
[![Preflight Daily](https://github.com/redhat-best-practices-for-k8s/certsuite-probe/actions/workflows/preflight.yml/badge.svg)](https://github.com/redhat-best-practices-for-k8s/certsuite-probe/actions/workflows/preflight.yml)

A repository that builds and publishes the certsuite-probe container image used by the [CNF Certification Suite](https://github.com/redhat-best-practices-for-k8s/certsuite).

## What is the Probe?

The certsuite-probe is a utility container image that serves as a testing and debugging tool deployed into Kubernetes clusters during CNF certification testing. It provides a comprehensive set of networking, debugging, and system inspection tools needed to validate Cloud-Native Network Functions (CNFs) against Red Hat's best practices.

### Key Components

The probe image includes:

- **Networking Tools**: `ethtool`, `iproute`, `iptables`, `nftables`, `net-tools`, `iputils` - for network configuration inspection and testing
- **System Utilities**: `pciutils`, `procps-ng`, `util-linux` - for hardware and process inspection  
- **Container Runtime**: [Podman v4.9.5](https://github.com/containers/podman) - for container operations within the test environment
- **API Testing**: `grpcurl` - for gRPC API validation
- **Additional Tools**: `jq`, `libselinux-utils`, `golang` - for JSON processing, SELinux inspection, and Go-based tooling

### Why It's Used in the Certsuite

The certsuite needs to perform in-cluster validation of CNFs, which requires:

1. **Network Testing**: Verifying connectivity, DNS resolution, and network policy enforcement
2. **Resource Inspection**: Checking CPU, memory, PCI devices, and block storage configurations
3. **Security Validation**: Inspecting SELinux contexts, capabilities, and container security settings
4. **Container Operations**: Testing container lifecycle, image pulling, and pod-to-pod communication

Rather than requiring test subjects to have these tools pre-installed, the certsuite deploys the probe as a DaemonSet or Pod to perform tests from within the cluster. This approach:

- Maintains a consistent testing environment across different CNF deployments
- Avoids modifying the CNF containers themselves
- Provides a controlled, verified toolset for certification testing
- Enables parallel testing across multiple nodes

## Image Distribution

The probe image is published to Quay.io at:
- `quay.io/redhat-best-practices-for-k8s/certsuite-probe:latest`
- Legacy location: `quay.io/testnetworkfunction/k8s-best-practices-debug:latest`

Images are built and pushed:
- Daily (nightly builds with latest security patches)
- On every release
- Multi-architecture support: `linux/amd64`, `linux/arm64`, `linux/ppc64le`, `linux/s390x`

## License

See [LICENSE](LICENSE) for details.
