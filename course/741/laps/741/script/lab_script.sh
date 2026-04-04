#!/bin/bash
# ============================================================
# Google Cloud: Develop Serverless Applications on Cloud Run
# Course 741 / Lab 741
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

usage() {
  echo -e "
${BOLD}Usage:${RESET}
  $0 [OPTIONS]

${BOLD}Options:${RESET}
  -r, --region   REGION   GCP region (default: us-central1)
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
[[ -z "$PROJECT_ID" ]] && error "No active GCP project. Run: gcloud config set project PROJECT_ID"

header "Develop Serverless Applications on Cloud Run — Lab 741"
echo -e "  Project : ${BOLD}$PROJECT_ID${RESET}"
echo -e "  Region  : ${BOLD}$REGION${RESET}"

header "Enabling required APIs"
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  pubsub.googleapis.com \
  eventarc.googleapis.com \
  --quiet
success "APIs enabled"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

REPO="${REGION}-docker.pkg.dev/${PROJECT_ID}/serverless-repo"

# ── Artifact Registry ─────────────────────────────────────
header "Create Artifact Registry repository"

if gcloud artifacts repositories describe serverless-repo \
    --location="$REGION" --quiet 2>/dev/null; then
  warn "Repository 'serverless-repo' already exists, skipping."
else
  gcloud artifacts repositories create serverless-repo \
    --repository-format=docker \
    --location="$REGION" \
    --quiet
  success "Repository 'serverless-repo' created"
fi

gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

# ── Task 1: Deploy hello service ─────────────────────────
header "Task 1 — Deploy hello Cloud Run service"

cat > "$WORK_DIR/app.py" <<'EOF'
import os
from flask import Flask, request

app = Flask(__name__)

@app.route('/', methods=['GET', 'POST'])
def hello():
    name = request.args.get('name', 'World')
    return f'Hello {name}!\n'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
EOF

cat > "$WORK_DIR/requirements.txt" <<'EOF'
flask>=3.0.0
gunicorn>=21.0.0
EOF

cat > "$WORK_DIR/Dockerfile" <<'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 app:app
EOF

IMAGE_HELLO="${REPO}/hello-service:v1"
docker build -t "$IMAGE_HELLO" "$WORK_DIR"
docker push "$IMAGE_HELLO"

gcloud run deploy hello-service \
  --image="$IMAGE_HELLO" \
  --region="$REGION" \
  --allow-unauthenticated \
  --max-instances=5 \
  --quiet

HELLO_URL=$(gcloud run services describe hello-service \
  --region="$REGION" --format='get(status.url)')
success "hello-service deployed: $HELLO_URL"

curl -s "$HELLO_URL?name=Cloud+Run" && echo

# ── Task 2: Pub/Sub topic + push subscription ─────────────
header "Task 2 — Pub/Sub topic and push subscription"

if gcloud pubsub topics describe hello-topic --quiet 2>/dev/null; then
  warn "Topic 'hello-topic' already exists, skipping."
else
  gcloud pubsub topics create hello-topic --quiet
  success "Pub/Sub topic 'hello-topic' created"
fi

# ── Task 3: Event-driven service (Pub/Sub subscriber) ─────
header "Task 3 — Deploy event-driven Cloud Run service"

cat > "$WORK_DIR/subscriber.py" <<'EOF'
import base64, json, os
from flask import Flask, request

app = Flask(__name__)

@app.route('/', methods=['POST'])
def receive():
    envelope = request.get_json()
    if not envelope or 'message' not in envelope:
        return 'Bad Request', 400
    data = base64.b64decode(envelope['message'].get('data', '')).decode()
    print(f'Received: {data}')
    return 'OK', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
EOF

cat > "$WORK_DIR/sub_requirements.txt" <<'EOF'
flask>=3.0.0
gunicorn>=21.0.0
EOF

cat > "$WORK_DIR/Dockerfile.sub" <<'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY sub_requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY subscriber.py app.py
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 app:app
EOF

IMAGE_SUB="${REPO}/subscriber-service:v1"
docker build -t "$IMAGE_SUB" -f "$WORK_DIR/Dockerfile.sub" "$WORK_DIR"
docker push "$IMAGE_SUB"

gcloud run deploy subscriber-service \
  --image="$IMAGE_SUB" \
  --region="$REGION" \
  --no-allow-unauthenticated \
  --quiet

SUB_URL=$(gcloud run services describe subscriber-service \
  --region="$REGION" --format='get(status.url)')

# Create Pub/Sub service account and binding
SA_EMAIL="cloud-run-pubsub-invoker@${PROJECT_ID}.iam.gserviceaccount.com"

if ! gcloud iam service-accounts describe "$SA_EMAIL" --quiet 2>/dev/null; then
  gcloud iam service-accounts create cloud-run-pubsub-invoker \
    --display-name="Cloud Run Pub/Sub Invoker" --quiet
fi

gcloud run services add-iam-policy-binding subscriber-service \
  --region="$REGION" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/run.invoker" \
  --quiet

if gcloud pubsub subscriptions describe hello-sub --quiet 2>/dev/null; then
  warn "Subscription 'hello-sub' already exists, skipping."
else
  gcloud pubsub subscriptions create hello-sub \
    --topic=hello-topic \
    --push-endpoint="$SUB_URL" \
    --push-auth-service-account="$SA_EMAIL" \
    --quiet
  success "Push subscription 'hello-sub' created → $SUB_URL"
fi

# ── Test ──────────────────────────────────────────────────
header "Test — Publish a message"
gcloud pubsub topics publish hello-topic --message="Hello from ChaiyoGCP!" --quiet
success "Message published"

# ── Summary ──────────────────────────────────────────────
header "✅  All Tasks Completed"

echo -e "\n${BOLD}Cloud Run Services:${RESET}"
gcloud run services list --region="$REGION" \
  --format="table(name,status.url,status.conditions[0].status)"

echo -e "\n${BOLD}Next steps:${RESET}"
echo -e "  gcloud run services delete hello-service --region=$REGION --quiet"
echo -e "  gcloud run services delete subscriber-service --region=$REGION --quiet"
echo -e "\n${BOLD}Done! 🎉${RESET}\n"
