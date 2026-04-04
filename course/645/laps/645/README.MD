# Lab 645 — Implement Cloud Security Fundamentals on Google Cloud

**Course 645: Implement Cloud Security Fundamentals on Google Cloud**

Automates the skill badge lab: create a custom IAM role, service account with role bindings, Cloud KMS key ring and symmetric key (with encrypt/decrypt), a custom VPC with subnet, and firewall rules.

## Resources created

| Resource | Details |
|----------|---------|
| `customSecurityRole` | Custom IAM role (project-level) |
| `security-lab-sa` | Service account with custom + viewer roles |
| `security-lab-keyring` | Cloud KMS key ring |
| `security-lab-key` | Symmetric encryption key (ENCRYPT_DECRYPT) |
| `security-lab-vpc` | Custom VPC network |
| `security-lab-subnet` | Subnet `10.10.0.0/24` with Private Google Access |
| `security-lab-allow-ssh` | Firewall: SSH to SA-tagged instances |
| `security-lab-allow-internal` | Firewall: internal subnet traffic |

---

## Option 1 — Bash script

```bash
cd script/
chmod +x lab_script.sh
./lab_script.sh

./lab_script.sh --region us-east1 --zone us-east1-b
```

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `-r`, `--region` | `us-east1` | GCP region |
| `-z`, `--zone` | `us-east1-b` | GCP zone |

---

## Option 2 — Terraform

```bash
mkdir lab-645 && cd lab-645
terraform init -from-module=github.com/monkey-mode/google-skills-script//course/645/laps/645/iac
terraform apply
```

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | `us-east1` | GCP region |
| `zone` | `us-east1-b` | GCP zone |
