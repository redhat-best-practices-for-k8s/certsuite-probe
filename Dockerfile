# IMPORTANT: podman must be build from ubi8.x only. Do not upgrade it to ubi9.
FROM --platform=$BUILDPLATFORM registry.access.redhat.com/ubi8/ubi:8.10-1304.1751400627 as podman-builder

# hadolint ignore=DL3041
RUN \
	dnf update --assumeyes --disableplugin=subscription-manager \
	&& dnf install --assumeyes --disableplugin=subscription-manager \
		git \
		make \
		golang \
		gpgme-devel \
		libseccomp-devel \
		libassuan-devel \
		python3 \
	&& dnf clean all \
	&& git clone https://github.com/containers/podman.git
WORKDIR /podman
RUN \
	git checkout v4.9.5 \
	&& make

FROM registry.access.redhat.com/ubi10/ubi:10.0-1760519443@sha256:9bd3aebdfdf6eebb6a18541d838cac9e9a35d2f807aa8e36d9518978cc86371f
# hadolint ignore=DL3041
RUN \
	dnf update --assumeyes --disableplugin=subscription-manager \
	&& dnf install --assumeyes --disableplugin=subscription-manager \
		ethtool \
		golang \
		iproute \
		iputils \
		jq \
		libselinux-utils \
		net-tools \
		nftables \
		pciutils \
		procps-ng \
		util-linux \
	&& dnf clean all --assumeyes --disableplugin=subscription-manager \
	&& rm -fr /var/cache/yum \
	&& mkdir /root/podman
# Set the GOPATH environment variable
ENV GOPATH=/go
# Add the Go binary directory to the PATH
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH
RUN go install github.com/fullstorydev/grpcurl/cmd/grpcurl@v1.9.3
COPY --from=podman-builder /podman/bin/podman /root/podman/
VOLUME ["/host"]
