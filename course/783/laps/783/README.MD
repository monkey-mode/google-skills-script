# Lab 783 — Manage Kubernetes in Google Cloud

**Course 783: Manage Kubernetes in Google Cloud**

Automates the skill badge lab: create a GKE Autopilot cluster, deploy and scale applications, configure HPA, and perform rolling updates.

## Resources created

| Resource | Details |
|----------|---------|
| `autopilot-cluster-1` | GKE Autopilot cluster |
| `web` | Kubernetes Deployment (hello-app) |
| `web` service | LoadBalancer Service |
| `web` HPA | Horizontal Pod Autoscaler (1–10 replicas, 50% CPU) |

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
| `-z`, `--zone` | `us-central1-c` | GCP zone |

---

## Option 2 — Terraform

```bash
mkdir lab-783 && cd lab-783
terraform init -from-module=github.com/monkey-mode/google-skills-script//course/783/laps/783/iac
terraform apply
```

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | `us-central1` | GCP region |
| `cluster_name` | `autopilot-cluster-1` | GKE cluster name |
