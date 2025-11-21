FROM golang:1.25.4 AS builder

WORKDIR /app
COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o k8s-api-query main.go

FROM gcr.io/distroless/base-debian12
COPY --from=builder /app/k8s-api-query /bin/k8s-api-query

ENTRYPOINT ["/bin/k8s-api-query"]