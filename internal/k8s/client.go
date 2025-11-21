package k8s

import (
	"context"
	"fmt"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

type K8sClient struct {
	Clientset *kubernetes.Clientset
}

func NewK8sClient() (*K8sClient, error) {
	config, err := rest.InClusterConfig()
	if err != nil {
		return nil, fmt.Errorf("in cluster config failed: %w", err)
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		return nil, fmt.Errorf("k8s client failed: %w", err)
	}

	return &K8sClient{Clientset: clientset}, nil
}

func (c *K8sClient) ListPods(namespace string) ([]string, error) {
	ns := namespace
	if ns == "all" {
		ns = ""
	}

	list, err := c.Clientset.CoreV1().Pods(ns).List(context.Background(), metav1.ListOptions{})
	if err != nil {
		return nil, err
	}

	out := []string{}
	for _, p := range list.Items {
		out = append(out, fmt.Sprintf("%s/%s", p.Namespace, p.Name))
	}

	return out, nil
}
