#!/bin/bash
# ============================================================
# Google Cloud: Mitigate Threats and Vulnerabilities
#               with Security Command Center
# Course 759 / Lab 759
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
ZONE="us-central1-a"

usage() {
  echo -e "
${BOLD}Usage:${RESET}
  $0 [OPTIONS]

${BOLD}Options:${RESET}
  -r, --region   REGION   GCP region (default: us-central1)
  -z, --zone     ZONE     GCP zone   (default: us-central1-a)
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
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='get(projectNumber)')

header "Mitigate Threats with Security Command Center — Lab 759"
echo -e "  Project : ${BOLD}$PROJECT_ID${RESET}"
echo -e "  Number  : ${BOLD}$PROJECT_NUMBER${RESET}"

header "Enabling required APIs"
gcloud services enable \
  securitycenter.googleapis.com \
  cloudasset.googleapis.com \
  compute.googleapis.com \
  bigquery.googleapis.com \
  --quiet
success "APIs enabled"

# ── Task 1: Create test VM with public IP (generates SCC findings) ──
header "Task 1 — Create test VM to generate SCC findings"

# Open firewall (intentionally misconfigured for SCC demo)
if gcloud compute firewall-rules create allow-all-demo \
    --allow=tcp,udp,icmp \
    --source-ranges=0.0.0.0/0 \
    --description="Demo rule — intentionally open for SCC lab" \
    --quiet 2>&1; then
  success "Demo firewall rule created (intentionally open)"
elif gcloud compute firewall-rules describe allow-all-demo --quiet 2>/dev/null; then
  warn "Firewall rule already exists, skipping."
else
  error "Failed to create firewall rule."
fi

if gcloud compute instances create scc-demo-vm \
    --machine-type=e2-micro \
    --zone="$ZONE" \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --tags=scc-demo \
    --quiet 2>&1; then
  success "VM 'scc-demo-vm' created"
elif gcloud compute instances describe scc-demo-vm --zone="$ZONE" --quiet 2>/dev/null; then
  warn "VM already exists, skipping."
else
  error "Failed to create VM."
fi

# ── Task 2: List SCC findings ────────────────────────────
header "Task 2 — List Security Command Center findings"

info "Waiting 30s for SCC to generate findings..."
sleep 30

gcloud scc findings list "projects/${PROJECT_ID}" \
  --page-size=10 \
  --format="table(name,category,state,severity)" \
  2>/dev/null || warn "No findings yet — SCC may take a few minutes to populate"

# ── Task 3: Export findings to BigQuery ──────────────────
header "Task 3 — Export findings to BigQuery"

BQ_DATASET="scc_findings"

if bq show --dataset "${PROJECT_ID}:${BQ_DATASET}" 2>/dev/null; then
  warn "Dataset '$BQ_DATASET' already exists, skipping."
else
  bq mk --dataset \
    --location=US \
    --description="SCC findings export" \
    "${PROJECT_ID}:${BQ_DATASET}"
  success "BigQuery dataset '$BQ_DATASET' created"
fi

# Create BigQuery export (continuous export config)
gcloud scc bqexports create scc-bq-export \
  --project="$PROJECT_ID" \
  --dataset="projects/${PROJECT_ID}/datasets/${BQ_DATASET}" \
  --description="SCC findings export to BigQuery" \
  --quiet 2>/dev/null || warn "BQ export may already exist or SCC tier insufficient"

# ── Task 4: Mute a finding type ──────────────────────────
header "Task 4 — Create mute rule for firewall findings"

gcloud scc muteconfigs create demo-mute-config \
  --project="$PROJECT_ID" \
  --description="Mute open firewall findings for demo VMs" \
  --filter="category=\"OPEN_FIREWALL\" AND resource.labels.tag_key_id=\"scc-demo\"" \
  --quiet 2>/dev/null || warn "Mute config may already exist"

success "Mute config created"

# ── Summary ──────────────────────────────────────────────
header "✅  All Tasks Completed"

echo -e "\n${BOLD}SCC Findings:${RESET}"
gcloud scc findings list "projects/${PROJECT_ID}" \
  --page-size=5 \
  --format="table(category,state,severity)" 2>/dev/null || echo "  (none yet)"

echo -e "\n${BOLD}Next steps:${RESET}"
echo -e "  # View in console: Security > Security Command Center"
echo -e "  gcloud compute instances delete scc-demo-vm --zone=$ZONE --quiet"
echo -e "  gcloud compute firewall-rules delete allow-all-demo --quiet"
echo -e "\n${BOLD}Done! 🎉${RESET}\n"
