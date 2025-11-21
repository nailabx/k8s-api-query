# k8s-api-query

k8s-api-query is a small Go service that runs inside a Kubernetes cluster and exposes a simple HTTP API to list Pods in a namespace.  
It uses the in-cluster service account token for authentication and respects Kubernetes RBAC rules.

---

## API

GET /k8s-api-query/pods/{namespace}

Example:
curl http://localhost:8080/k8s-api-query/pods/default

Success response:
{ "namespace": "default", "pods": ["pod-1", "pod-2"] }

Forbidden response (RBAC):
{ "error": "forbidden" }

---

## How it works

1. The service authenticates using the Kubernetes in-cluster configuration.
2. It attempts to list Pods in the requested namespace.
3. RBAC controls what the service account is allowed to read.
4. If permissions are missing, the service returns HTTP 403 with a JSON error.

---

## Deployment requirements

You need:
- A ServiceAccount for the app
- A Role that allows: get, list pods
- A RoleBinding connecting the two
- A Deployment that runs the container image
- A Service exposing port 8080

The repository already contains a working set of manifests (`manifest/`) that provision all of the above. Apply them directly to your cluster:

```bash
kubectl apply -f manifest/
```

The deployment pulls `quay.io/nailabx/k8s-api-query:<version>` by default, so ensure the desired version tag exists in the registry before applying.

---

## Local Testing with Kind

Build the image:
make docker-build VERSION=dev

Load into Kind:
kind load docker-image quay.io/nailabx/k8s-api-query:dev

Deploy Kubernetes manifests, then port-forward:
kubectl port-forward svc/k8s-api-query 8080:8080

Test:
curl http://localhost:8080/k8s-api-query/pods/default

---

## Development

Build:
make build

Test:
make test

Build container:
make docker-build VERSION=1.0.0

Push to Quay:
make docker-release VERSION=1.0.0

---

## Container Registry

Public image:
https://quay.io/repository/nailabx/k8s-api-query
