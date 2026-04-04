# Lab 755 — Use APIs to Work with Cloud Storage

**Course 755: Use APIs to Work with Cloud Storage**

Automates the skill badge lab: use the Cloud Storage JSON API directly (via curl) to create a bucket, upload, list, download, and update objects, and create an HMAC key.

## Resources created

| Resource | Details |
|----------|---------|
| `<project-id>-api-demo` | Cloud Storage bucket |
| `demo.txt` | Uploaded via JSON API |
| `metadata.json` | Uploaded via JSON API |
| HMAC key | Created for Compute Engine SA |

---

## Option 1 — Bash script

```bash
cd script/
chmod +x lab_script.sh
./lab_script.sh

./lab_script.sh --region us-central1
```

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `-r`, `--region` | `us-east1` | GCP region |

---

## Option 2 — Terraform

```bash
mkdir lab-755 && cd lab-755
terraform init -from-module=github.com/monkey-mode/google-skills-script//course/755/laps/755/iac
terraform apply
```

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | `us-east1` | GCP region |
