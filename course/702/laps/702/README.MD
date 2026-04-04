# Lab 702 — Configure Service Accounts and IAM Roles for Google Cloud

**Course 702: Configure Service Accounts and IAM Roles for Google Cloud**

Automates the skill badge lab: create service accounts, assign predefined and custom IAM roles, create a VM with an attached service account, and test permissions.

## Resources created

| Resource | Details |
|----------|---------|
| `my-sa-123` | Service account with editor + custom role |
| `customComputeViewer` | Custom IAM role (compute.instances.get/list) |
| `sa-vm` | e2-micro VM using the service account |

---

## Option 1 — Bash script

```bash
cd script/
chmod +x lab_script.sh
./lab_script.sh

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
mkdir lab-702 && cd lab-702
terraform init -from-module=github.com/monkey-mode/google-skills-script//course/702/laps/702/iac
terraform apply
```

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | `us-east1` | GCP region |
| `zone` | `us-east1-c` | GCP zone |
