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

GIT_SHA := $(shell git rev-parse --short HEAD)
VERSION ?= $(GIT_SHA)

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
# Docker steps
###############################################
docker-login:
	@echo ">> Logging in to $(QUAY_REGISTRY)..."
	echo "$(QUAY_PASSWORD)" | docker login $(QUAY_REGISTRY) -u "$(QUAY_USERNAME)" --password-stdin

docker-build: build
	@echo ">> Building Docker image $(IMAGE):$(VERSION)"
	docker build -t $(IMAGE):$(VERSION) .

docker-push: docker-login
	@echo ">> Pushing $(IMAGE):$(VERSION)"
	docker push $(IMAGE):$(VERSION)

docker-release: docker-build docker-push
	@echo ">> Image published: $(IMAGE):$(VERSION)"

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
