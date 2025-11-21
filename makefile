# ---- CONFIG ----
APP_NAME := k8s-api-query
REGISTRY := quay.io/nailabx
IMAGE := $(REGISTRY)/$(APP_NAME)

# Git SHA for tagging
GIT_SHA := $(shell git rev-parse --short HEAD)

# Default version (override with: make build VERSION=1.2.3)
VERSION ?= $(GIT_SHA)

# ---- GO BUILD ----
build:
	@echo ">> Building Go binary..."
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o bin/$(APP_NAME) main.go

test:
	@echo ">> Running unit tests..."
	go test ./... -v

# ---- DOCKER ----
docker-build: build
	@echo ">> Building Docker image: $(IMAGE):$(VERSION)"
	docker build -t $(IMAGE):$(VERSION) .

docker-push:
	@echo ">> Pushing Docker image to registry..."
	docker push $(IMAGE):$(VERSION)

# Combine build + push
docker-release: docker-build docker-push
	@echo ">> Image published: $(IMAGE):$(VERSION)"

# ---- UTIL ----
clean:
	rm -rf bin/

# ---- FULL PIPELINE ----
all: test docker-release

.PHONY: build test docker-build docker-push docker-release clean all
