# Makefile for certsuite-probe

IMAGE_NAME ?= certsuite-probe:latest
DOCKERFILE ?= Dockerfile
CONTEXT ?= .

.PHONY: build-image
build-image:
	docker build -t $(IMAGE_NAME) -f $(DOCKERFILE) $(CONTEXT)
