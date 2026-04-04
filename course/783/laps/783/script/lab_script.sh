#!/bin/bash
# ============================================================
# Google Cloud: Manage Kubernetes in Google Cloud
# Course 783 / Lab 783
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

REGION="us-central1"
ZONE="us-central1-c"
CLUSTER="autopilot-cluster-1"

usage() {
  echo -e "
${BOLD}Usage:${RESET}
  $0 [OPTIONS]

${BOLD}Options:${RESET}
  -r, --region   REGION   GCP region (default: us-central1)
  -z, --zone     ZONE     GCP zone   (default: us-central1-c)
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

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
[[ -z "$PROJECT_ID" ]] && error "No active GCP project."

header "Manage Kubernetes in Google Cloud — Lab 783"
echo -e "  Project : ${BOLD}$PROJECT_ID${RESET}"
echo -e "  Region  : ${BOLD}$REGION${RESET}"

header "Enabling required APIs"
gcloud services enable \
  container.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  --quiet
success "APIs enabled"

# ── Task 1: Create Autopilot GKE cluster ─────────────────
header "Task 1 — Create GKE Autopilot cluster"

if gcloud container clusters describe "$CLUSTER" \
    --region="$REGION" --quiet 2>/dev/null; then
  warn "Cluster '$CLUSTER' already exists, skipping."
else
  gcloud container clusters create-auto "$CLUSTER" \
    --region="$REGION" \
    --quiet
  success "GKE Autopilot cluster '$CLUSTER' created"
fi

gcloud container clusters get-credentials "$CLUSTER" \
  --region="$REGION" --quiet
success "kubectl configured"

# ── Task 2: Deploy sample app ────────────────────────────
header "Task 2 — Deploy sample application"

kubectl create deployment web \
  --image=gcr.io/google-samples/hello-app:1.0 \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl expose deployment web \
  --type=LoadBalancer \
  --port=80 \
  --target-port=8080 \
  --dry-run=client -o yaml | kubectl apply -f -

success "Deployment 'web' and LoadBalancer service created"

# ── Task 3: Scale deployment ─────────────────────────────
header "Task 3 — Scale deployment"

kubectl scale deployment web --replicas=3
kubectl rollout status deployment/web
success "Deployment scaled to 3 replicas"

# ── Task 4: Set up HPA ───────────────────────────────────
header "Task 4 — Configure Horizontal Pod Autoscaler"

kubectl autoscale deployment web \
  --cpu-percent=50 \
  --min=1 \
  --max=10 \
  --dry-run=client -o yaml | kubectl apply -f -
success "HPA configured (1-10 replicas, 50% CPU)"

# ── Task 5: Rolling update ───────────────────────────────
header "Task 5 — Rolling update to v2"

kubectl set image deployment/web hello-app=gcr.io/google-samples/hello-app:2.0
kubectl rollout status deployment/web
success "Rolling update complete"

# ── Task 6: View logs and monitoring ─────────────────────
header "Task 6 — View logs"

kubectl logs -l app=web --tail=5 || warn "No logs yet — pods still starting"

# ── Summary ──────────────────────────────────────────────
header "✅  All Tasks Completed"

echo -e "\n${BOLD}Nodes:${RESET}"
kubectl get nodes

echo -e "\n${BOLD}Pods:${RESET}"
kubectl get pods

echo -e "\n${BOLD}HPA:${RESET}"
kubectl get hpa

echo -e "\n${BOLD}Next steps:${RESET}"
echo -e "  gcloud container clusters delete $CLUSTER --region=$REGION --quiet"
echo -e "\n${BOLD}Done! 🎉${RESET}\n"
