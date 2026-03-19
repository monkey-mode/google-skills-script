# Lab 597887 — Create a Virtual Machine

**Course 754: The Basics of Google Cloud Compute**

Automates the Google Cloud Skills Boost lab: provision two Compute Engine VMs, open HTTP traffic via a firewall rule, and install NGINX.

## Resources created

| Resource | Details |
|----------|---------|
| `gcelab` | Debian 12, 10 GB pd-balanced, tag: `http-server`, NGINX installed |
| `gcelab2` | Debian 12 |
| `allow-http` | Firewall rule — tcp:80, target-tag: `http-server` |

---

## Option 1 — Terraform

### Prerequisites

- `terraform` CLI
- `gcloud` CLI authenticated (`gcloud auth application-default login`)

### Usage

```bash
# Run directly from GitHub
mkdir lab-597887 && cd lab-597887

terraform init -from-module=github.com/monkey-mode/google-skills-script//course/754/laps/597887/iac
terraform apply
```

```bash
# Or clone and run locally
cd iac/

terraform init

# Use defaults (us-east1 / us-east1-c / e2-medium)
terraform apply

# Custom values
terraform apply -var="region=asia-south1" -var="zone=asia-south1-c" -auto-approve  -var="machine_type=e2-standard-2"

# Destroy all resources
terraform destroy
```

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | `us-east1` | GCP region |
| `zone` | `us-east1-c` | GCP zone |
| `machine_type` | `e2-medium` | VM machine type |

---

## Option 2 — Bash script

### Prerequisites

- `gcloud` CLI authenticated and pointing at your lab project
- Bash 4+

### Usage

```bash
cd script/

chmod +x lab_script.sh cleanup.sh

# Use defaults (us-east1 / us-east1-c / e2-medium)
./lab_script.sh

# Custom flags
./lab_script.sh --region us-central1 --zone us-central1-a --machine-type e2-standard-2
./lab_script.sh -r europe-west1 -z europe-west1-b -m n2-standard-4

# Help
./lab_script.sh --help

# Cleanup
./cleanup.sh
```

### What the script does

| Phase | Actions |
|-------|---------|
| **1** | Set `gcloud` region/zone config; create `allow-http` firewall rule (tcp:80) |
| **2** | Create `gcelab` (http-server tag) and `gcelab2` in parallel |
| **3** | Install & start NGINX on `gcelab`; verify SSH on `gcelab2` (parallel) |
