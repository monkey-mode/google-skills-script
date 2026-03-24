# Lab 598830 — Cloud Run Functions: Qwik Start - Console

**Course 696: Cloud Run Functions: 3 Ways**

Automates the Google Cloud Skills Boost lab: create, deploy, and test an HTTP-triggered Cloud Run Function (2nd gen).

## What it does

| Task | Actions |
|------|---------|
| **1 & 2** | Enable APIs; deploy `gcfunction` (Node.js 20, HTTP trigger, public access, max 5 instances) |
| **3** | Test the function with `{"message":"Hello World!"}` and verify the response |

## Resources created

| Resource | Details |
|----------|---------|
| `gcfunction` | Cloud Run Function 2nd gen, Node.js 20, HTTP trigger, public |

---

## Option 1 — Bash script

```bash
# Run directly from GitHub
bash <(curl -s https://raw.githubusercontent.com/monkey-mode/google-skills-script/main/course/696/laps/598830/script/lab_script.sh)

# Custom region
bash <(curl -s https://raw.githubusercontent.com/monkey-mode/google-skills-script/main/course/696/laps/598830/script/lab_script.sh) --region us-central1
```

```bash
# Or clone and run locally
cd script/
chmod +x lab_script.sh
./lab_script.sh
```

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `-r`, `--region` | `us-east4` | GCP region |

---

## Option 2 — Terraform

```bash
# Run directly from GitHub
mkdir lab-598830 && cd lab-598830
terraform init -from-module=github.com/monkey-mode/google-skills-script//course/696/laps/598830/iac
terraform apply -var="project_id=qwiklabs-gcp-02-a042588907c1" -var="region=us-east4"
```

```bash
# Or run locally
cd iac/
terraform init
terraform apply -var="project_id=YOUR_PROJECT_ID"

# Custom region
terraform apply -var="project_id=YOUR_PROJECT_ID" -var="region=us-central1"

# Destroy
terraform destroy -var="project_id=YOUR_PROJECT_ID"
```

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `project_id` | — | GCP project ID (required) |
| `region` | `us-east4` | GCP region |
| `memory` | `256M` | Function memory allocation |

### Outputs

| Output | Description |
|--------|-------------|
| `function_url` | Deployed function URL |

After deploying, test with:

```bash
curl -X POST "$(terraform output -raw function_url)" \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello World!"}'
```
