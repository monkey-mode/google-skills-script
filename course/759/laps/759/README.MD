# Lab 759 — Mitigate Threats and Vulnerabilities with Security Command Center

**Course 759: Mitigate Threats and Vulnerabilities with Security Command Center**

Automates the skill badge lab: enable SCC, create demo resources to generate findings, list and mute findings, and export to BigQuery.

## Resources created

| Resource | Details |
|----------|---------|
| `allow-all-demo` | Demo firewall rule (intentionally open — for SCC findings) |
| `scc-demo-vm` | e2-micro VM to trigger SCC findings |
| `scc_findings` | BigQuery dataset for findings export |
| `scc-bq-export` | SCC continuous export to BigQuery |
| `demo-mute-config` | SCC mute rule for demo firewall findings |

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
| `-r`, `--region` | `us-central1` | GCP region |
| `-z`, `--zone` | `us-central1-a` | GCP zone |

---

## Option 2 — Terraform

```bash
mkdir lab-759 && cd lab-759
terraform init -from-module=github.com/monkey-mode/google-skills-script//course/759/laps/759/iac
terraform apply
```

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | `us-central1` | GCP region |
| `zone` | `us-central1-a` | GCP zone |
