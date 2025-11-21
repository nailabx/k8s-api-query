###############################################
# Load .env variables if present
###############################################
ifneq (,$(wildcard .env))
    include .env
    export $(shell sed 's/=.*//' .env)
endif

###############################################
# Project configuration
###############################################
APP_NAME := k8s-api-query
REGISTRY := quay.io/nailabx
IMAGE := $(REGISTRY)/$(APP_NAME)

# Versioning
GIT_SHA := $(shell git rev-parse --short HEAD)
VERSION ?= 0.0.0  # override with: make docker-release VERSION=1.3.0

###############################################
# Go Build
###############################################
build:
	@echo ">> Building Go binary..."
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o bin/$(APP_NAME) main.go

test:
	@echo ">> Running tests..."
	go test ./... -v

###############################################
# Docker
###############################################
docker-login:
	@echo ">> Logging in to $(QUAY_REGISTRY)..."
	echo "$(QUAY_PASSWORD)" | docker login $(QUAY_REGISTRY) -u "$(QUAY_USERNAME)" --password-stdin

docker-build: build
	@echo ">> Building Docker image $(IMAGE)"
	@echo "   - Tagging: $(VERSION)"
	@echo "   - Tagging: $(GIT_SHA)"
	@echo "   - Tagging: latest"
	docker build -t $(IMAGE):$(VERSION) \
	             -t $(IMAGE):$(GIT_SHA) \
	             -t $(IMAGE):latest .

docker-push: docker-login
	@echo ">> Pushing Docker images..."
	docker push $(IMAGE):$(VERSION)
	docker push $(IMAGE):$(GIT_SHA)
	docker push $(IMAGE):latest

docker-release: docker-build docker-push
	@echo ">> Published tags:"
	@echo "   ✔ $(VERSION)"
	@echo "   ✔ $(GIT_SHA)"
	@echo "   ✔ latest"

###############################################
# Utility
###############################################
clean:
	rm -rf bin/

###############################################
# Full pipeline
###############################################
all: test docker-release

###############################################
# PHONY
###############################################
.PHONY: build test docker-build docker-push docker-release clean all docker-login
