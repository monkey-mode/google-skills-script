#!/bin/bash
# ============================================================
# Google Cloud: Configure Service Accounts and IAM Roles
# Course 702 / Lab 702
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

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
[[ -z "$PROJECT_ID" ]] && error "No active GCP project."
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='get(projectNumber)')

header "Configure Service Accounts and IAM Roles — Lab 702"
echo -e "  Project : ${BOLD}$PROJECT_ID${RESET}"
echo -e "  Region  : ${BOLD}$REGION${RESET}"

header "Enabling required APIs"
gcloud services enable \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  compute.googleapis.com \
  --quiet
success "APIs enabled"

# ── Task 1: Create service account ────────────────────────
header "Task 1 — Create service account 'my-sa-123'"

SA_EMAIL="my-sa-123@${PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe "$SA_EMAIL" --quiet 2>/dev/null; then
  warn "Service account 'my-sa-123' already exists, skipping."
else
  gcloud iam service-accounts create my-sa-123 \
    --display-name="My Service Account" \
    --description="Lab service account for IAM exercises" \
    --quiet
  success "Service account 'my-sa-123' created"
fi

# ── Task 2: Grant roles to service account ────────────────
header "Task 2 — Grant IAM roles"

for ROLE in roles/editor roles/viewer; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="$ROLE" \
    --condition=None \
    --quiet > /dev/null
  success "Granted $ROLE to my-sa-123"
done

# ── Task 3: Create VM with service account ────────────────
header "Task 3 — Create VM using service account"

if gcloud compute instances create sa-vm \
    --machine-type=e2-micro \
    --zone="$ZONE" \
    --service-account="$SA_EMAIL" \
    --scopes=cloud-platform \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --quiet 2>&1; then
  success "VM 'sa-vm' created with service account"
elif gcloud compute instances describe sa-vm --zone="$ZONE" --quiet 2>/dev/null; then
  warn "VM 'sa-vm' already exists, skipping."
else
  error "Failed to create VM 'sa-vm'."
fi

# ── Task 4: Create custom IAM role ────────────────────────
header "Task 4 — Create custom IAM role"

ROLE_ID="customComputeViewer"

if gcloud iam roles describe "$ROLE_ID" --project="$PROJECT_ID" --quiet 2>/dev/null; then
  warn "Custom role '$ROLE_ID' already exists, skipping."
else
  gcloud iam roles create "$ROLE_ID" \
    --project="$PROJECT_ID" \
    --title="Custom Compute Viewer" \
    --description="Read-only access to Compute Engine instances" \
    --permissions="compute.instances.get,compute.instances.list" \
    --stage=GA \
    --quiet
  success "Custom role '$ROLE_ID' created"
fi

# Bind custom role to service account
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="projects/${PROJECT_ID}/roles/${ROLE_ID}" \
  --condition=None \
  --quiet > /dev/null
success "Custom role bound to my-sa-123"

# ── Task 5: Create and test a key ────────────────────────
header "Task 5 — Create service account key"

KEY_FILE="/tmp/sa-key-${PROJECT_ID}.json"
gcloud iam service-accounts keys create "$KEY_FILE" \
  --iam-account="$SA_EMAIL" \
  --quiet
success "Key created: $KEY_FILE"

info "Testing authentication with service account key..."
gcloud auth activate-service-account "$SA_EMAIL" \
  --key-file="$KEY_FILE" \
  --quiet
gcloud compute instances list --zone="$ZONE" \
  --impersonate-service-account="$SA_EMAIL" \
  --quiet 2>/dev/null || warn "impersonate test — expected if SA lacks listing rights"

# Re-authenticate as user
gcloud config set account "$(gcloud config get-value core/account 2>/dev/null || echo '')" --quiet 2>/dev/null || true

# ── Summary ──────────────────────────────────────────────
header "✅  All Tasks Completed"

echo -e "\n${BOLD}Service Accounts:${RESET}"
gcloud iam service-accounts list --filter="email:my-sa-123"

echo -e "\n${BOLD}Custom Roles:${RESET}"
gcloud iam roles list --project="$PROJECT_ID" --filter="name:customComputeViewer"

echo -e "\n${BOLD}Key file:${RESET} $KEY_FILE"
echo -e "  rm $KEY_FILE  ← delete when done"

echo -e "\n${BOLD}Next steps:${RESET}"
echo -e "  gcloud compute instances delete sa-vm --zone=$ZONE --quiet"
echo -e "\n${BOLD}Done! 🎉${RESET}\n"
