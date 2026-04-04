# Lab 663 — Deploy Kubernetes Applications on Google Cloud

**Course 663: Deploy Kubernetes Applications on Google Cloud**

Automates the Google Cloud Skills Boost skill badge lab: create a GKE cluster, build and push a Docker image to Artifact Registry, deploy the app, expose it via a LoadBalancer, and perform a rolling update.

## Resources created

| Resource | Details |
|----------|---------|
| `hello-cluster` | GKE cluster, 3 × e2-medium nodes |
| `hello-repo` | Artifact Registry Docker repository |
| `hello-app` | Kubernetes Deployment (3 replicas) |
| `hello-app` service | LoadBalancer Service, port 80 |

---

## Option 1 — Bash script

```bash
cd script/
chmod +x lab_script.sh

# Use defaults (us-east1 / us-east1-c)
./lab_script.sh

# Custom region & zone
./lab_script.sh --region us-central1 --zone us-central1-a
```

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `-r`, `--region` | `us-east1` | GCP region |
| `-z`, `--zone` | `us-east1-c` | GCP zone |

---

## Option 2 — Terraform

```bash
# Run directly from GitHub
mkdir lab-663 && cd lab-663
terraform init -from-module=github.com/monkey-mode/google-skills-script//course/663/laps/663/iac
terraform apply
```

```bash
# Or run locally
cd iac/
terraform init
terraform apply

# Destroy
terraform destroy
```

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | `us-east1` | GCP region |
| `zone` | `us-east1-c` | GCP zone |
| `cluster_name` | `hello-cluster` | GKE cluster name |
| `node_count` | `3` | Nodes per zone |
| `machine_type` | `e2-medium` | Node machine type |
