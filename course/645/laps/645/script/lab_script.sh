#!/bin/bash
# ============================================================
# Google Cloud: Implement Cloud Security Fundamentals
# Course 645 / Lab 645
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
ZONE="us-east1-b"

usage() {
  echo -e "
${BOLD}Usage:${RESET}
  $0 [OPTIONS]

${BOLD}Options:${RESET}
  -r, --region   REGION   GCP region (default: us-east1)
  -z, --zone     ZONE     GCP zone   (default: us-east1-b)
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
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')

CUSTOM_ROLE_ID="customSecurityRole"
SA_NAME="security-lab-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEYRING_NAME="security-lab-keyring"
KEY_NAME="security-lab-key"
VPC_NAME="security-lab-vpc"
SUBNET_NAME="security-lab-subnet"
SUBNET_RANGE="10.10.0.0/24"
FW_ALLOW_SSH="security-lab-allow-ssh"
FW_ALLOW_INTERNAL="security-lab-allow-internal"

header "Implement Cloud Security Fundamentals — Lab 645"
echo -e "  Project : ${BOLD}$PROJECT_ID${RESET}"
echo -e "  Region  : ${BOLD}$REGION${RESET}"
echo -e "  Zone    : ${BOLD}$ZONE${RESET}"

header "Enabling required APIs"
gcloud services enable \
  iam.googleapis.com \
  cloudkms.googleapis.com \
  compute.googleapis.com \
  --quiet
success "APIs enabled"

# ── Task 1: Create a custom IAM role ─────────────────────
header "Task 1 — Create custom IAM role"

if gcloud iam roles describe "$CUSTOM_ROLE_ID" --project="$PROJECT_ID" &>/dev/null; then
  warn "Custom role '$CUSTOM_ROLE_ID' already exists"
else
  gcloud iam roles create "$CUSTOM_ROLE_ID" \
    --project="$PROJECT_ID" \
    --title="Custom Security Role" \
    --description="Custom role for Cloud Security Fundamentals lab" \
    --permissions="storage.buckets.get,storage.buckets.list,storage.objects.get,storage.objects.list,compute.instances.get,compute.instances.list" \
    --stage="GA"
  success "Custom role '$CUSTOM_ROLE_ID' created"
fi

# ── Task 2: Create a service account ─────────────────────
header "Task 2 — Create service account"

if gcloud iam service-accounts describe "$SA_EMAIL" &>/dev/null; then
  warn "Service account '$SA_NAME' already exists"
else
  gcloud iam service-accounts create "$SA_NAME" \
    --display-name="Security Lab Service Account" \
    --description="Service account for Cloud Security Fundamentals lab"
  success "Service account '$SA_NAME' created"
fi

# ── Task 3: Bind custom role to service account ───────────
header "Task 3 — Bind custom role to service account"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="projects/${PROJECT_ID}/roles/${CUSTOM_ROLE_ID}" \
  --condition=None \
  --quiet
success "Custom role bound to '$SA_EMAIL'"

# Also bind viewer for basic read access
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/viewer" \
  --condition=None \
  --quiet
success "Viewer role bound to '$SA_EMAIL'"

# ── Task 4: Create Cloud KMS key ring and key ─────────────
header "Task 4 — Create Cloud KMS key ring and symmetric key"

if gcloud kms keyrings describe "$KEYRING_NAME" --location="$REGION" &>/dev/null; then
  warn "Key ring '$KEYRING_NAME' already exists"
else
  gcloud kms keyrings create "$KEYRING_NAME" --location="$REGION"
  success "Key ring '$KEYRING_NAME' created in $REGION"
fi

if gcloud kms keys describe "$KEY_NAME" \
    --keyring="$KEYRING_NAME" --location="$REGION" &>/dev/null; then
  warn "Key '$KEY_NAME' already exists"
else
  gcloud kms keys create "$KEY_NAME" \
    --keyring="$KEYRING_NAME" \
    --location="$REGION" \
    --purpose="encryption"
  success "Symmetric key '$KEY_NAME' created"
fi

# ── Task 5: Encrypt and decrypt data with KMS ─────────────
header "Task 5 — Encrypt and decrypt data with KMS"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Sensitive data for Cloud Security Fundamentals lab" > "$WORK_DIR/plaintext.txt"

gcloud kms encrypt \
  --key="$KEY_NAME" \
  --keyring="$KEYRING_NAME" \
  --location="$REGION" \
  --plaintext-file="$WORK_DIR/plaintext.txt" \
  --ciphertext-file="$WORK_DIR/ciphertext.enc"
success "Data encrypted with KMS key"

gcloud kms decrypt \
  --key="$KEY_NAME" \
  --keyring="$KEYRING_NAME" \
  --location="$REGION" \
  --ciphertext-file="$WORK_DIR/ciphertext.enc" \
  --plaintext-file="$WORK_DIR/decrypted.txt"

DECRYPTED=$(cat "$WORK_DIR/decrypted.txt")
echo "  Decrypted: $DECRYPTED"
success "Data decrypted successfully"

# ── Task 6: Create a custom VPC network ──────────────────
header "Task 6 — Create custom VPC network and subnet"

if gcloud compute networks describe "$VPC_NAME" &>/dev/null; then
  warn "VPC '$VPC_NAME' already exists"
else
  gcloud compute networks create "$VPC_NAME" \
    --subnet-mode=custom
  success "VPC '$VPC_NAME' created"
fi

if gcloud compute networks subnets describe "$SUBNET_NAME" \
    --region="$REGION" &>/dev/null; then
  warn "Subnet '$SUBNET_NAME' already exists"
else
  gcloud compute networks subnets create "$SUBNET_NAME" \
    --network="$VPC_NAME" \
    --region="$REGION" \
    --range="$SUBNET_RANGE" \
    --enable-private-ip-google-access
  success "Subnet '$SUBNET_NAME' created ($SUBNET_RANGE)"
fi

# ── Task 7: Configure firewall rules ─────────────────────
header "Task 7 — Configure firewall rules"

if gcloud compute firewall-rules describe "$FW_ALLOW_SSH" &>/dev/null; then
  warn "Firewall rule '$FW_ALLOW_SSH' already exists"
else
  gcloud compute firewall-rules create "$FW_ALLOW_SSH" \
    --network="$VPC_NAME" \
    --allow=tcp:22 \
    --source-ranges="0.0.0.0/0" \
    --target-service-accounts="$SA_EMAIL" \
    --description="Allow SSH for security lab service account"
  success "Firewall rule '$FW_ALLOW_SSH' created"
fi

if gcloud compute firewall-rules describe "$FW_ALLOW_INTERNAL" &>/dev/null; then
  warn "Firewall rule '$FW_ALLOW_INTERNAL' already exists"
else
  gcloud compute firewall-rules create "$FW_ALLOW_INTERNAL" \
    --network="$VPC_NAME" \
    --allow=tcp,udp,icmp \
    --source-ranges="$SUBNET_RANGE" \
    --description="Allow internal traffic within subnet"
  success "Firewall rule '$FW_ALLOW_INTERNAL' created"
fi

# ── Summary ──────────────────────────────────────────────
header "✅  All Tasks Completed"

echo -e "\n${BOLD}Resources created:${RESET}"
echo -e "  Custom Role  : projects/${PROJECT_ID}/roles/${CUSTOM_ROLE_ID}"
echo -e "  Service Acct : ${SA_EMAIL}"
echo -e "  KMS Key Ring : ${KEYRING_NAME} (${REGION})"
echo -e "  KMS Key      : ${KEY_NAME}"
echo -e "  VPC Network  : ${VPC_NAME}"
echo -e "  Subnet       : ${SUBNET_NAME} (${SUBNET_RANGE})"
echo -e "  Firewall     : ${FW_ALLOW_SSH}, ${FW_ALLOW_INTERNAL}"

echo -e "\n${BOLD}Next steps:${RESET}"
echo -e "  gcloud iam roles delete $CUSTOM_ROLE_ID --project=$PROJECT_ID"
echo -e "  gcloud iam service-accounts delete $SA_EMAIL"
echo -e "  gcloud compute networks delete $VPC_NAME --quiet"

echo -e "\n${BOLD}Done! 🎉${RESET}\n"
