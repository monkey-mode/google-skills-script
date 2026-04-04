#!/bin/bash
# ============================================================
# Google Cloud: Use APIs to Work with Cloud Storage
# Course 755 / Lab 755
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

usage() {
  echo -e "
${BOLD}Usage:${RESET}
  $0 [OPTIONS]

${BOLD}Options:${RESET}
  -r, --region   REGION   GCP region (default: us-east1)
  -h, --help              Show this help message
"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--region) REGION="$2"; shift 2 ;;
    -h|--help)   usage ;;
    *) error "Unknown argument: $1. Use --help for usage." ;;
  esac
done

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
[[ -z "$PROJECT_ID" ]] && error "No active GCP project."

BUCKET="${PROJECT_ID}-api-demo"
ACCESS_TOKEN=$(gcloud auth print-access-token)

header "Use APIs to Work with Cloud Storage — Lab 755"
echo -e "  Project : ${BOLD}$PROJECT_ID${RESET}"
echo -e "  Bucket  : ${BOLD}$BUCKET${RESET}"

header "Enabling required APIs"
gcloud services enable storage.googleapis.com --quiet
success "API enabled"

# ── Task 1: Create bucket via JSON API ────────────────────
header "Task 1 — Create bucket via Storage JSON API"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://storage.googleapis.com/storage/v1/b?project=${PROJECT_ID}" \
  -d "{\"name\":\"${BUCKET}\",\"location\":\"${REGION}\",\"storageClass\":\"STANDARD\"}")

if [[ "$HTTP_STATUS" == "200" ]]; then
  success "Bucket '$BUCKET' created via JSON API"
elif [[ "$HTTP_STATUS" == "409" ]]; then
  warn "Bucket '$BUCKET' already exists"
else
  error "Failed to create bucket (HTTP $HTTP_STATUS)"
fi

# ── Task 2: Upload object via JSON API ────────────────────
header "Task 2 — Upload object via JSON API"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Hello from Cloud Storage API! Project: $PROJECT_ID" > "$WORK_DIR/demo.txt"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: text/plain" \
  --data-binary @"$WORK_DIR/demo.txt" \
  "https://storage.googleapis.com/upload/storage/v1/b/${BUCKET}/o?uploadType=media&name=demo.txt")

[[ "$HTTP_STATUS" == "200" ]] && success "Uploaded demo.txt" || warn "Upload returned HTTP $HTTP_STATUS"

# Upload a JSON file
echo '{"lab":"Use APIs to Work with Cloud Storage","course":"755"}' > "$WORK_DIR/metadata.json"
curl -s -o /dev/null \
  -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-binary @"$WORK_DIR/metadata.json" \
  "https://storage.googleapis.com/upload/storage/v1/b/${BUCKET}/o?uploadType=media&name=metadata.json"
success "Uploaded metadata.json"

# ── Task 3: List objects via JSON API ─────────────────────
header "Task 3 — List objects via JSON API"

OBJECTS=$(curl -s \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://storage.googleapis.com/storage/v1/b/${BUCKET}/o" | \
  python3 -c "import json,sys; items=json.load(sys.stdin).get('items',[]); [print(i['name']) for i in items]")

echo "$OBJECTS"
success "Objects listed"

# ── Task 4: Download object via JSON API ──────────────────
header "Task 4 — Download object via JSON API"

curl -s \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://storage.googleapis.com/storage/v1/b/${BUCKET}/o/demo.txt?alt=media" \
  -o "$WORK_DIR/downloaded.txt"

echo "  Downloaded content: $(cat "$WORK_DIR/downloaded.txt")"
success "Object downloaded"

# ── Task 5: Update object metadata / ACL ──────────────────
header "Task 5 — Update object metadata"

curl -s -o /dev/null \
  -X PATCH \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://storage.googleapis.com/storage/v1/b/${BUCKET}/o/demo.txt" \
  -d '{"metadata":{"lab":"755","updated":"true"}}'
success "Object metadata updated"

# ── Task 6: HMAC key for service account ──────────────────
header "Task 6 — Create HMAC key for service account"

SA_EMAIL="$(gcloud iam service-accounts list \
  --filter="displayName:Compute Engine default" \
  --format='value(email)' | head -1)"

if [[ -n "$SA_EMAIL" ]]; then
  HMAC=$(gcloud storage hmac create "$SA_EMAIL" --format=json 2>/dev/null || echo '{}')
  echo "  HMAC key created for: $SA_EMAIL"
  success "HMAC key created"
else
  warn "No default Compute Engine service account found, skipping HMAC"
fi

# ── Summary ──────────────────────────────────────────────
header "✅  All Tasks Completed"

echo -e "\n${BOLD}Bucket contents:${RESET}"
gcloud storage ls "gs://${BUCKET}/"

echo -e "\n${BOLD}Next steps:${RESET}"
echo -e "  gcloud storage rm -r gs://${BUCKET}/"
echo -e "\n${BOLD}Done! 🎉${RESET}\n"
