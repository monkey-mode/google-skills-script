#!/bin/bash
# ============================================================
# Google Cloud: Cloud Run Functions Qwik Start - Lab Script
# Course 696 / Lab 598830
# Usage:
#   ./lab_script.sh
#   ./lab_script.sh --region us-central1
# ============================================================

set -euo pipefail

# ── Colours ────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[✓]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[✗]${RESET}    $*" >&2; exit 1; }
header()  { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${RESET}"
            echo -e "${BOLD}${CYAN}  $*${RESET}"
            echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; }

# ── Defaults ───────────────────────────────────────────────
REGION="us-central1"

# ── Argument Parsing ───────────────────────────────────────
usage() {
  echo -e "
${BOLD}Usage:${RESET}
  $0 [OPTIONS]

${BOLD}Options:${RESET}
  -r, --region   REGION   GCP region (default: us-east1)
  -h, --help              Show this help message

${BOLD}Examples:${RESET}
  $0
  $0 --region us-central1
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

# ── Resolve project ────────────────────────────────────────
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
[[ -z "$PROJECT_ID" ]] && error "No active GCP project. Run: gcloud config set project PROJECT_ID"

# ══════════════════════════════════════════════════════════
header "Cloud Run Functions Qwik Start — Lab 598830"
echo -e "  Project : ${BOLD}$PROJECT_ID${RESET}"
echo -e "  Region  : ${BOLD}$REGION${RESET}"

# ── Enable APIs ────────────────────────────────────────────
header "Enabling required APIs"

gcloud services enable \
  run.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  --quiet
success "APIs enabled"

# ── Task 1 & 2: Create and deploy the function ────────────
header "Task 1 & 2 — Create & deploy gcfunction"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

# Write function source
cat > "$WORK_DIR/index.js" <<'EOF'
const functions = require('@google-cloud/functions-framework');

functions.http('helloHttp', (req, res) => {
  res.send(`Hello ${req.query.message || req.body.message || 'World'}!`);
});
EOF

cat > "$WORK_DIR/package.json" <<'EOF'
{
  "name": "hellohttp",
  "version": "1.0.0",
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0"
  }
}
EOF

if gcloud functions describe gcfunction --gen2 --region="$REGION" --quiet 2>/dev/null; then
  warn "Function 'gcfunction' already exists, skipping creation."
else
  gcloud functions deploy gcfunction \
    --gen2 \
    --region="$REGION" \
    --runtime=nodejs20 \
    --trigger-http \
    --allow-unauthenticated \
    --max-instances=5 \
    --entry-point=helloHttp \
    --source="$WORK_DIR" \
    --quiet
  success "Function 'gcfunction' deployed"
fi

# ── Task 3: Test the function ──────────────────────────────
header "Task 3 — Test gcfunction"

FUNCTION_URL=$(gcloud functions describe gcfunction \
  --gen2 \
  --region="$REGION" \
  --format='get(serviceConfig.uri)')

info "Function URL: $FUNCTION_URL"

RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello World!"}')

echo -e "  Response: ${BOLD}${GREEN}$RESPONSE${RESET}"

if echo "$RESPONSE" | grep -q "Hello World"; then
  success "Function test passed"
else
  error "Function test failed — unexpected response: $RESPONSE"
fi

# ── Summary ────────────────────────────────────────────────
header "✅  All Tasks Completed"

echo -e "\n${BOLD}Function:${RESET}"
echo -e "  Name : gcfunction"
echo -e "  URL  : ${GREEN}$FUNCTION_URL${RESET}"
echo -e "\n${BOLD}View logs:${RESET}"
echo -e "  gcloud functions logs read gcfunction --gen2 --region=$REGION"
echo -e "\n${BOLD}Done! 🎉${RESET}\n"
