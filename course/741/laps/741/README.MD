# Lab 741 — Develop Serverless Applications on Cloud Run

**Course 741: Develop Serverless Applications on Cloud Run**

Automates the skill badge lab: deploy Cloud Run services, integrate with Pub/Sub via push subscriptions, and build event-driven serverless architectures.

## Resources created

| Resource | Details |
|----------|---------|
| `serverless-repo` | Artifact Registry Docker repository |
| `hello-service` | Public Cloud Run service (Flask) |
| `subscriber-service` | Private Cloud Run service (Pub/Sub receiver) |
| `hello-topic` | Pub/Sub topic |
| `hello-sub` | Push subscription → subscriber-service |
| `cloud-run-pubsub-invoker` | Service account for Pub/Sub auth |

---

## Option 1 — Bash script

```bash
cd script/
chmod +x lab_script.sh
./lab_script.sh

# Custom region
./lab_script.sh --region us-east1
```

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `-r`, `--region` | `us-central1` | GCP region |

---

## Option 2 — Terraform (infrastructure prerequisites)

```bash
mkdir lab-741 && cd lab-741
terraform init -from-module=github.com/monkey-mode/google-skills-script//course/741/laps/741/iac
terraform apply
```

> The Terraform IaC provisions the supporting infrastructure (APIs, Artifact Registry, Pub/Sub topic, service account). Use the Bash script to build, push, and deploy the actual Cloud Run services.

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | `us-central1` | GCP region |
