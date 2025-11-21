package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/nailabx/k8s-api-query/internal/k8s"
	k8serrors "k8s.io/apimachinery/pkg/api/errors"
)

type PodLister interface {
	ListPods(namespace string) ([]string, error)
}

type ErrorResponse struct {
	Error            string `json:"error"`
	Message          string `json:"message"`
	NamespaceQueried string `json:"namespaceQueried"`
}

type PodsResponse struct {
	Namespace string   `json:"namespace"`
	Pods      []string `json:"pods"`
}

var NewK8sClientFunc = func() (PodLister, error) {
	return k8s.NewK8sClient()
}

func PodsHandler(w http.ResponseWriter, r *http.Request) {
	start := time.Now()

	// Clean built-in Go path value
	namespace := r.PathValue("namespace")

	log.Printf("[REQUEST] GET %s — namespace='%s' remote='%s'",
		r.URL.Path, namespace, r.RemoteAddr)

	client, err := NewK8sClientFunc()
	if err != nil {
		http.Error(w, "failed to init k8s client: "+err.Error(), http.StatusInternalServerError)
		return
	}

	pods, err := client.ListPods(namespace)
	if err != nil {

		// RBAC error ⇒ return 403 JSON
		if k8serrors.IsForbidden(err) {
			w.WriteHeader(http.StatusForbidden)
			json.NewEncoder(w).Encode(ErrorResponse{
				Error:            "forbidden",
				Message:          "service account does not have enough permission",
				NamespaceQueried: namespace,
			})
			return
		}

		http.Error(w, "internal error: "+err.Error(), http.StatusInternalServerError)
		return
	}

	resp := PodsResponse{
		Namespace: namespace,
		Pods:      pods,
	}

	log.Printf("[RESPONSE] namespace='%s' pods=%d duration=%s",
		namespace, len(pods), time.Since(start))

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
