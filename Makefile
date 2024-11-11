IMAGE_NAME := b0ch3nski/samba-insecure
IMAGE_VERSION ?= $(or $(shell git describe --tags --always),latest)
IMAGE_PLATFORMS ?= linux/amd64,linux/386,linux/arm64,linux/arm/v7

ALPINE_VERSION ?= 3.20

build:
	docker buildx build \
	--pull \
	--push \
	--platform="$(IMAGE_PLATFORMS)" \
	--build-arg ALPINE_VERSION="$(ALPINE_VERSION)" \
	--label="org.opencontainers.image.title=$(IMAGE_NAME)" \
	--label="org.opencontainers.image.version=$(IMAGE_VERSION)" \
	--label="org.opencontainers.image.url=https://github.com/$(IMAGE_NAME)" \
	--label="org.opencontainers.image.revision=$(shell git log -1 --format=%H)" \
	--label="org.opencontainers.image.created=$(shell date --iso-8601=seconds)" \
	--tag="$(IMAGE_NAME):$(IMAGE_VERSION)" \
	--tag="$(IMAGE_NAME):latest" \
	.
