#!/bin/bash
# ============================================================
# Google Cloud: Creating VMs & Installing NGINX - Lab Script
# Usage:
#   ./lab_script.sh                              # defaults
#   ./lab_script.sh --region us-east1 --zone us-east1-c
#   ./lab_script.sh -r us-west1 -z us-west1-a
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
REGION="us-east1"
ZONE="us-east1-c"

# ── Argument Parsing ───────────────────────────────────────
usage() {
  echo -e "
${BOLD}Usage:${RESET}
  $0 [OPTIONS]

${BOLD}Options:${RESET}
  -r, --region   REGION   GCP region  (default: us-east1)
  -z, --zone     ZONE     GCP zone    (default: us-east1-c)
  -h, --help              Show this help message

${BOLD}Examples:${RESET}
  $0
  $0 --region us-central1 --zone us-central1-a
  $0 -r europe-west1 -z europe-west1-b
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

# ── Validate zone belongs to region ────────────────────────
if [[ "$ZONE" != "$REGION"* ]]; then
  error "Zone '$ZONE' does not belong to region '$REGION'."
fi

export REGION ZONE

# ── Parallel helpers ───────────────────────────────────────
BG_PIDS=()
BG_LABELS=()

bg_run() {
  # bg_run "label" cmd [args...]
  local label="$1"; shift
  "$@" &
  local pid=$!
  BG_PIDS+=("$pid")
  BG_LABELS+=("$label")   # same index as BG_PIDS
}

wait_all() {
  local failed=0
  for i in "${!BG_PIDS[@]}"; do
    local pid="${BG_PIDS[$i]}"
    local label="${BG_LABELS[$i]}"
    if wait "$pid"; then
      success "$label"
    else
      echo -e "${RED}[✗]${RESET}    $label FAILED" >&2
      failed=1
    fi
  done
  BG_PIDS=()
  BG_LABELS=()
  [[ $failed -eq 0 ]] || error "One or more parallel tasks failed."
}

# ── SSH readiness probe ────────────────────────────────────
wait_for_ssh() {
  local vm="$1"
  info "Waiting for SSH on '$vm'..."
  local max=12 i=0
  until gcloud compute ssh "$vm" --zone="$ZONE" --quiet \
        --command="echo ok" -- -o StrictHostKeyChecking=no \
        -o ConnectTimeout=5 &>/dev/null; do
    i=$((i+1))
    [[ $i -ge $max ]] && error "Timed out waiting for SSH on '$vm'"
    sleep 8
  done
}

# ══════════════════════════════════════════════════════════
header "GCE Lab Automation Script"
echo -e "  Region : ${BOLD}$REGION${RESET}"
echo -e "  Zone   : ${BOLD}$ZONE${RESET}"

# ── Phase 1: gcloud config + firewall in parallel ─────────
header "Phase 1 — Config & Firewall (parallel)"

(
  gcloud config set compute/region "$REGION" --quiet
  gcloud config set compute/zone   "$ZONE"   --quiet
) &
bg_run "gcloud config → region=$REGION zone=$ZONE" $!

(
  if gcloud compute firewall-rules describe allow-http --quiet 2>/dev/null; then
    warn "Firewall rule 'allow-http' already exists, skipping."
  else
    gcloud compute firewall-rules create allow-http \
      --allow=tcp:80 \
      --target-tags=http-server \
      --description="Allow HTTP traffic on port 80" \
      --quiet
  fi
) &
bg_run "Firewall rule allow-http (tcp:80)" $!

wait_all

# ── Phase 2: Create both VMs in parallel ──────────────────
header "Phase 2 — Create VMs in parallel"

gcloud compute instances create gcelab \
  --machine-type=e2-medium \
  --zone="$ZONE" \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --boot-disk-size=10GB \
  --boot-disk-type=pd-balanced \
  --tags=http-server \
  --quiet &
bg_run "VM 'gcelab' created  (e2-medium, Debian 12, http-server tag)" $!

gcloud compute instances create gcelab2 \
  --machine-type=e2-medium \
  --zone="$ZONE" \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --quiet &
bg_run "VM 'gcelab2' created (e2-medium, Debian 12)" $!

wait_all

# ── Phase 3: NGINX install + gcelab2 SSH verify in parallel
header "Phase 3 — Post-boot tasks (parallel)"

(
  wait_for_ssh gcelab
  gcloud compute ssh gcelab --zone="$ZONE" --quiet \
    --command="sudo apt-get update -y -qq && \
               sudo apt-get install -y -qq nginx && \
               sudo systemctl enable nginx && \
               sudo systemctl start nginx" \
    -- -o StrictHostKeyChecking=no
) &
bg_run "NGINX installed & started on 'gcelab'" $!

(
  wait_for_ssh gcelab2
  gcloud compute ssh gcelab2 --zone="$ZONE" --quiet \
    --command="echo 'gcelab2 SSH ok'" \
    -- -o StrictHostKeyChecking=no
) &
bg_run "SSH verified on 'gcelab2'" $!

wait_all

# ── Summary ────────────────────────────────────────────────
header "✅  All Tasks Completed"

echo -e "\n${BOLD}VM Instances:${RESET}"
gcloud compute instances list \
  --filter="zone:($ZONE)" \
  --format="table(name,zone,machineType.basename(),status,networkInterfaces[0].accessConfigs[0].natIP:label=EXTERNAL_IP)"

EXTERNAL_IP=$(gcloud compute instances describe gcelab \
  --zone="$ZONE" \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo -e "\n${BOLD}NGINX Web Server:${RESET}"
echo -e "  ${GREEN}http://${EXTERNAL_IP}${RESET}  ← open in your browser"
echo -e "\n${BOLD}Done! 🎉${RESET}\n"