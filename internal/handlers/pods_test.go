package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

// ---- Fake client with only ListPods ----
type FakeClient struct {
	Pods []string
	Err  error
}

func (f *FakeClient) ListPods(namespace string) ([]string, error) {
	return f.Pods, f.Err
}

func TestPodsHandler_Success(t *testing.T) {
	orig := NewK8sClientFunc
	defer func() { NewK8sClientFunc = orig }()

	// override factory
	NewK8sClientFunc = func() (PodLister, error) {
		return &FakeClient{
			Pods: []string{"default/podA", "default/podB"},
			Err:  nil,
		}, nil
	}

	req := httptest.NewRequest("GET", "/k8s-api-query/pods/default", nil)
	req.SetPathValue("namespace", "default")

	rr := httptest.NewRecorder()

	PodsHandler(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200 OK, got %d", rr.Code)
	}

	var resp PodsResponse
	if err := json.Unmarshal(rr.Body.Bytes(), &resp); err != nil {
		t.Fatalf("invalid JSON: %v", err)
	}

	if resp.Namespace != "default" {
		t.Errorf("expected namespace 'default', got '%s'", resp.Namespace)
	}

	if len(resp.Pods) != 2 {
		t.Errorf("expected 2 pods, got %d", len(resp.Pods))
	}
}
