# CLAUDE.md — google-skills-script

## Project goal

Automate Google Cloud Skills Boost labs for **Google Cloud AI Study Jam: #ChaiyoGCP Season 6**
Event page: https://rsvp.withgoogle.com/events/chaiyogcp-s6

Each lab in the event has a corresponding automation script and/or Terraform IaC so participants can complete the labs faster and focus on understanding concepts rather than clicking through the console.

---

## Repository layout

```
course/
└── <course-id>/
    └── laps/
        └── <lab-id>/
            ├── README.MD          # Lab overview, usage, variables
            ├── iac/               # Terraform (infrastructure labs)
            │   ├── main.tf
            │   ├── variables.tf
            │   └── outputs.tf
            └── script/            # Bash automation
                ├── lab_script.sh
                └── cleanup.sh     # (where applicable)
```

- **course-id** = Google Cloud Skills Boost `course_templates/` number
- **lab-id** = individual lab ID from Skills Boost

---

## Existing labs

| Course ID | Lab ID | Name |
|-----------|--------|------|
| 754 | 597887 | Create a Virtual Machine (The Basics of Google Cloud Compute) |
| 696 | 598830 | Cloud Run Functions: Qwik Start - Console |
| 1445 | 619095 | Build Multi-Agent Systems with ADK (Deploy Multi-Agent Architectures) |

---

## Script conventions

### Bash scripts (`lab_script.sh`, `cleanup.sh`)

- `set -euo pipefail` at the top
- Colour helpers: `info`, `success`, `warn`, `error`, `header`
- Default region/zone as variables at the top, overridable with `-r/--region`, `-z/--zone` flags
- Parallel tasks use `bg_track "label" $!` + `wait_all` pattern — **never** pass `$!` to `bg_run` as a command
- Idempotency: always check resource existence before creating (try-create then verify pattern for gcloud)
- Enable required APIs via `gcloud services enable` at the start
- Persist PATH changes to `~/.bashrc` so tools like `adk` survive after the script exits
- End with a `Next steps` summary block

### bg_track pattern (critical)

```bash
# CORRECT — background the subshell first, then track its PID
( some-commands ) &
bg_track "label" $!

# WRONG — do NOT do this (tries to execute the PID as a command)
bg_run "label" $!
```

### Terraform IaC (`iac/`)

- Provider: `hashicorp/google ~> 5.0`
- No `project` in the provider block — inherits from `gcloud` config
- `variables.tf`: always include `region` with the lab's required default
- Firewall rules must include `source_ranges = ["0.0.0.0/0"]` for public ingress
- `google_cloudfunctions2_function` = Cloud Run Functions 2nd gen (no extra field needed)
- Source code for functions lives in `iac/source/` and is zipped via `data "archive_file"`
- IAM public access via `google_cloud_run_service_iam_member` with `member = "allUsers"`

### From-module usage

```bash
mkdir lab-<id> && cd lab-<id>
terraform init -from-module=github.com/monkey-mode/google-skills-script//course/<course-id>/laps/<lab-id>/iac
terraform apply
```

---

## Adding a new lab

1. Get the lab content (task instructions) from the user
2. Create directory: `course/<course-id>/laps/<lab-id>/`
3. Create `script/lab_script.sh` following the bash conventions above
4. Create `iac/` with `main.tf`, `variables.tf`, `outputs.tf` (skip if no infrastructure)
5. Create `README.MD` with: overview, resources created, script usage, IaC usage, variables table, from-module command
6. Update root `README.MD` Labs table
7. Suggest a commit message in the format: `feat(<lab-id>): <short description>`

---

## Commit message format

```
feat(<lab-id>): add <lab name> lab script and IaC
fix(<lab-id>): <what was fixed>
docs(<lab-id>): <what was updated>
```

---

## ChaiyoGCP Season 6 — Badge reference

### Skill Badges (labs covered or to be covered)

| Category | Badge | Course ID |
|----------|-------|-----------|
| Gen AI & Agents | Deploy Multi-Agent Architectures | 1445 |
| Gen AI & Agents | Develop Gen AI Apps with Gemini and Streamlit | 978 |
| Gen AI & Agents | Enhance Gemini Model Capabilities | 1241 |
| Gen AI & Agents | Kickstarting Application Development with Gemini Code Assist | 1399 |
| Gen AI & Agents | Prompt Design in Vertex AI | 976 |
| Data & ML | Automate Data Capture at Scale with Document AI | 674 |
| Data & ML | Create ML Models with BigQuery ML | 626 |
| Data & ML | Engineer Data for Predictive Modeling with BigQuery ML | 627 |
| Data & ML | Implement Multimodal Vector Search with BigQuery | 1232 |
| Data & ML | Perform Predictive Data Analysis in BigQuery | 656 |
| Security | Configure Service Accounts and IAM Roles for Google Cloud | 702 |
| Security | Implement Cloud Security Fundamentals on Google Cloud | 645 |
| Security | Mitigate Threats and Vulnerabilities with Security Command Center | 759 |
| Security | Monitor and Log with Google Cloud Observability | 749 |
| Security | Monitoring in Google Cloud | 747 |
| Security | Use APIs to Work with Cloud Storage | 755 |
| Infrastructure | Cloud Run Functions: 3 Ways | 696 |
| Infrastructure | Deploy Kubernetes Applications on Google Cloud | 663 |
| Infrastructure | Develop Serverless Applications on Cloud Run | 741 |
| Infrastructure | Manage Kubernetes in Google Cloud | 783 |
| Infrastructure | The Basics of Google Cloud Compute | 754 |

### Regular Badges

| Category | Badge | Course ID |
|----------|-------|-----------|
| AI Agent Dev | Build AI Agents with Enterprise Databases | 1436 |
| AI Agent Dev | Build Generative AI Agents with Vertex AI and Flutter | 1162 |
| AI Agent Dev | Build intelligent agents with Agent Development Kit (ADK) | 1382 |
| AI Agent Dev | Create Embeddings, Vector Search, and RAG with BigQuery | 1210 |
| AI Agent Dev | Deploy Multi-Agent Systems with ADK and Agent Engine | 1340 |
| AI Agent Dev | Vector Search and Embeddings | 939 |
| Gemini | Gemini for Application Developers | 881 |
| Gemini | Gemini for Cloud Architects | 878 |
| Gemini | Gemini for DevOps Engineers | 882 |
| Gemini | Gemini for Network Engineers | 884 |
| Gemini | Gemini for Security Engineers | 886 |
| Applied AI | Agent Assist and its Gen AI Capabilities | 1159 |
| Applied AI | Create Agents with Generative Playbooks | 1122 |
| Applied AI | Vertex AI Search for Commerce | 391 |
| App Dev | AI Boost Bites: Automate tasks with Gemini and Apps Script | 1371 |
| App Dev | Google Cloud Computing Foundations: Cloud Computing Fundamentals | 153 |
| App Dev | Streamline App Development with Gemini Code Assist | 1166 |
| AI Security | Introduction to Security in the World of AI | 1146 |
| AI Security | Model Armor: Securing AI Deployments | 1385 |
