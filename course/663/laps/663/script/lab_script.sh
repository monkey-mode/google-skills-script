#!/bin/bash
# ============================================================
# Google Cloud: Deploy Kubernetes Applications on Google Cloud
# Course 663 / Lab 663
# Usage:
#   ./lab_script.sh
#   ./lab_script.sh --region us-east1 --zone us-east1-c
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[✓]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[✗]${RESET}    $*" >&2; exit 1; }
header()  { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${RESET}"
            echo -e "${BOLD}${CYAN}  $*${RESET}"
            echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; }

REGION="us-east1"
ZONE="us-east1-c"
CLUSTER="hello-cluster"

usage() {
  echo -e "
${BOLD}Usage:${RESET}
  $0 [OPTIONS]

${BOLD}Options:${RESET}
  -r, --region   REGION   GCP region (default: us-east1)
  -z, --zone     ZONE     GCP zone   (default: us-east1-c)
  -h, --help              Show this help message
"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--region) REGION="$2"; shift 2 ;;
    -z|--zone)   ZONE="$2";   shift 2 ;;
    -h|--help)   usage ;;
    *) error "Unknown argument: $1. Use --help for usage." ;;
  esac
done

[[ "$ZONE" != "$REGION"* ]] && error "Zone '$ZONE' does not belong to region '$REGION'."

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
[[ -z "$PROJECT_ID" ]] && error "No active GCP project. Run: gcloud config set project PROJECT_ID"

header "Deploy Kubernetes Applications — Lab 663"
echo -e "  Project : ${BOLD}$PROJECT_ID${RESET}"
echo -e "  Region  : ${BOLD}$REGION${RESET}"
echo -e "  Zone    : ${BOLD}$ZONE${RESET}"

header "Enabling required APIs"
gcloud services enable \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  --quiet
success "APIs enabled"

# ── Task 1: Create Artifact Registry repo ─────────────────
header "Task 1 — Create Artifact Registry repository"

if gcloud artifacts repositories describe hello-repo \
    --location="$REGION" --quiet 2>/dev/null; then
  warn "Repository 'hello-repo' already exists, skipping."
else
  gcloud artifacts repositories create hello-repo \
    --repository-format=docker \
    --location="$REGION" \
    --description="Docker repository for hello app" \
    --quiet
  success "Artifact Registry repository 'hello-repo' created"
fi

# ── Task 2: Build and push sample app image ────────────────
header "Task 2 — Build & push sample Docker image"

REPO="${REGION}-docker.pkg.dev/${PROJECT_ID}/hello-repo"
IMAGE="${REPO}/hello-app:v1"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

cat > "$WORK_DIR/main.go" <<'EOF'
package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, World! Version 1\n")
	})
	log.Printf("Listening on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
EOF

cat > "$WORK_DIR/Dockerfile" <<'EOF'
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY main.go .
RUN go build -o hello-app .

FROM alpine:3.18
WORKDIR /app
COPY --from=builder /app/hello-app .
CMD ["./hello-app"]
EOF

gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

docker build -t "$IMAGE" "$WORK_DIR"
docker push "$IMAGE"
success "Image pushed: $IMAGE"

# ── Task 3: Create GKE cluster ────────────────────────────
header "Task 3 — Create GKE cluster"

if gcloud container clusters describe "$CLUSTER" --zone="$ZONE" --quiet 2>/dev/null; then
  warn "Cluster '$CLUSTER' already exists, skipping."
else
  gcloud container clusters create "$CLUSTER" \
    --num-nodes=3 \
    --machine-type=e2-medium \
    --zone="$ZONE" \
    --quiet
  success "GKE cluster '$CLUSTER' created"
fi

gcloud container clusters get-credentials "$CLUSTER" --zone="$ZONE" --quiet
success "kubectl configured for '$CLUSTER'"

# ── Task 4: Deploy app to Kubernetes ─────────────────────
header "Task 4 — Deploy application"

kubectl create deployment hello-app \
  --image="$IMAGE" \
  --replicas=3 \
  --dry-run=client -o yaml | kubectl apply -f -
success "Deployment 'hello-app' applied"

# ── Task 5: Expose with LoadBalancer ─────────────────────
header "Task 5 — Expose via LoadBalancer"

kubectl expose deployment hello-app \
  --type=LoadBalancer \
  --port=80 \
  --target-port=8080 \
  --dry-run=client -o yaml | kubectl apply -f -
success "Service 'hello-app' created"

info "Waiting for external IP (this may take ~2 minutes)..."
for i in $(seq 1 24); do
  EXTERNAL_IP=$(kubectl get service hello-app \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  [[ -n "$EXTERNAL_IP" && "$EXTERNAL_IP" != "null" ]] && break
  sleep 5
done

# ── Task 6: Rolling update to v2 ──────────────────────────
header "Task 6 — Rolling update to v2"

cat > "$WORK_DIR/main.go" <<'EOF'
package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, World! Version 2\n")
	})
	log.Printf("Listening on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
EOF

IMAGE_V2="${REPO}/hello-app:v2"
docker build -t "$IMAGE_V2" "$WORK_DIR"
docker push "$IMAGE_V2"

kubectl set image deployment/hello-app hello-app="$IMAGE_V2"
kubectl rollout status deployment/hello-app
success "Rolling update to v2 complete"

# ── Summary ───────────────────────────────────────────────
header "✅  All Tasks Completed"

echo -e "\n${BOLD}Cluster:${RESET}"
kubectl get nodes

echo -e "\n${BOLD}Deployments:${RESET}"
kubectl get deployments

echo -e "\n${BOLD}Services:${RESET}"
kubectl get services

[[ -n "${EXTERNAL_IP:-}" ]] && \
  echo -e "\n  App URL: ${GREEN}http://${EXTERNAL_IP}${RESET}"

echo -e "\n${BOLD}Next steps:${RESET}"
echo -e "  gcloud container clusters delete $CLUSTER --zone=$ZONE --quiet"
echo -e "\n${BOLD}Done! 🎉${RESET}\n"
