package main

import (
	"log"
	"net/http"

	"github.com/nailabx/k8s-api-query/internal/handlers"
)

func main() {
	mux := http.NewServeMux()

	// Native Go path parameter
	mux.HandleFunc("GET /k8s-api-query/pods/{namespace}", handlers.PodsHandler)

	log.Println("Starting server on :8080")
	log.Fatal(http.ListenAndServe(":8080", mux))
}
