#!/bin/bash
# ============================================================
# Google Cloud: Creating VMs & Installing NGINX - Cleanup
# Deletes all resources created by lab_script.sh
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

export REGION ZONE

# ── Parallel helpers ───────────────────────────────────────
BG_PIDS=()
BG_LABELS=()

bg_track() {
  local label="$1"
  local pid="$2"
  BG_PIDS+=("$pid")
  BG_LABELS+=("$label")
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
  [[ $failed -eq 0 ]] || error "One or more cleanup tasks failed."
}

# ══════════════════════════════════════════════════════════
header "GCE Lab Cleanup"
echo -e "  Region : ${BOLD}$REGION${RESET}"
echo -e "  Zone   : ${BOLD}$ZONE${RESET}"

# ── Delete VMs in parallel ─────────────────────────────────
header "Deleting VMs (parallel)"

(
  if gcloud compute instances describe gcelab --zone="$ZONE" --quiet 2>/dev/null; then
    gcloud compute instances delete gcelab --zone="$ZONE" --quiet
  else
    warn "VM 'gcelab' not found, skipping."
  fi
) &
bg_track "VM 'gcelab' deleted" $!

(
  if gcloud compute instances describe gcelab2 --zone="$ZONE" --quiet 2>/dev/null; then
    gcloud compute instances delete gcelab2 --zone="$ZONE" --quiet
  else
    warn "VM 'gcelab2' not found, skipping."
  fi
) &
bg_track "VM 'gcelab2' deleted" $!

wait_all

# ── Delete firewall rule ───────────────────────────────────
header "Deleting Firewall Rule"

if gcloud compute firewall-rules describe allow-http --quiet 2>/dev/null; then
  gcloud compute firewall-rules delete allow-http --quiet
  success "Firewall rule 'allow-http' deleted"
else
  warn "Firewall rule 'allow-http' not found, skipping."
fi

# ── Summary ───────────────────────────────────────────────
header "✅  Cleanup Complete"
echo -e "\n${BOLD}Done! All lab resources removed.${RESET}\n"
