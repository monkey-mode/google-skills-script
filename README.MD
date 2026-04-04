# Google Skills Script

Bash automation scripts for Google Cloud Skills Boost labs.
Each script automates the manual steps of a lab so you can focus on learning the concepts rather than clicking through the console.

## Repository layout

```
course/
└── <course-id>/
    └── laps/
        └── <lab-id>/
            ├── README.MD
            ├── iac/        # Terraform
            └── script/     # Bash automation
```

## Labs

| Course | Lab | Description |
|--------|-----|-------------|
| [754 — The Basics of Google Cloud Compute](course/754/laps/597887/) | [597887 — Create a Virtual Machine](course/754/laps/597887/) | Create GCE VMs and install NGINX |
| [696 — Cloud Run Functions: 3 Ways](course/696/laps/598830/) | [598830 — Cloud Run Functions: Qwik Start - Console](course/696/laps/598830/) | Deploy and test an HTTP-triggered Cloud Run Function |
| [1445 — Deploy Multi-Agent Architectures](course/1445/laps/619095/) | [619095 — Build Multi-Agent Systems with ADK](course/1445/laps/619095/) | Orchestrate multi-agent systems with Google ADK |
| [663 — Deploy Kubernetes Applications on Google Cloud](course/663/laps/663/) | [663 — Deploy Kubernetes Applications](course/663/laps/663/) | GKE cluster, Artifact Registry, Docker build/push, rolling updates |
| [741 — Develop Serverless Applications on Cloud Run](course/741/laps/741/) | [741 — Develop Serverless Applications](course/741/laps/741/) | Flask services on Cloud Run, Pub/Sub push subscription |
| [783 — Manage Kubernetes in Google Cloud](course/783/laps/783/) | [783 — Manage Kubernetes in Google Cloud](course/783/laps/783/) | GKE Autopilot, HPA, rolling updates, cluster maintenance |
| [702 — Configure Service Accounts and IAM Roles](course/702/laps/702/) | [702 — Configure Service Accounts and IAM Roles](course/702/laps/702/) | Service accounts, custom roles, VM with SA, key management |
| [645 — Implement Cloud Security Fundamentals](course/645/laps/645/) | [645 — Implement Cloud Security Fundamentals](course/645/laps/645/) | Custom IAM role, KMS encrypt/decrypt, custom VPC, firewall rules |
| [759 — Mitigate Threats and Vulnerabilities with SCC](course/759/laps/759/) | [759 — Mitigate Threats with SCC](course/759/laps/759/) | SCC findings, BigQuery export, mute rules, notification config |
| [755 — Use APIs to Work with Cloud Storage](course/755/laps/755/) | [755 — Use APIs to Work with Cloud Storage](course/755/laps/755/) | Cloud Storage JSON API: create bucket, upload, list, download, HMAC |

---

## Chaiyo GCP Season 6 — Badge Catalog

> ✅ = script/IaC ready &nbsp;|&nbsp; ⏳ = coming soon

### Skill Badges

#### Generative AI & Agents
| Status | Badge | Link |
|--------|-------|------|
| ⏳ | Deploy Multi-Agent Architectures | [course_templates/1445](https://www.cloudskillsboost.google/course_templates/1445) |
| ⏳ | Develop Gen AI Apps with Gemini and Streamlit | [course_templates/978](https://www.cloudskillsboost.google/course_templates/978) |
| ⏳ | Enhance Gemini Model Capabilities | [course_templates/1241](https://www.cloudskillsboost.google/course_templates/1241) |
| ⏳ | Kickstarting Application Development with Gemini Code Assist | [course_templates/1399](https://www.cloudskillsboost.google/course_templates/1399) |
| ⏳ | Prompt Design in Vertex AI | [course_templates/976](https://www.cloudskillsboost.google/course_templates/976) |

#### Data Engineering & Machine Learning
| Status | Badge | Link |
|--------|-------|------|
| ⏳ | Automate Data Capture at Scale with Document AI | [course_templates/674](https://www.cloudskillsboost.google/course_templates/674) |
| ⏳ | Create ML Models with BigQuery ML | [course_templates/626](https://www.cloudskillsboost.google/course_templates/626) |
| ⏳ | Engineer Data for Predictive Modeling with BigQuery ML | [course_templates/627](https://www.cloudskillsboost.google/course_templates/627) |
| ⏳ | Implement Multimodal Vector Search with BigQuery | [course_templates/1232](https://www.cloudskillsboost.google/course_templates/1232) |
| ⏳ | Perform Predictive Data Analysis in BigQuery | [course_templates/656](https://www.cloudskillsboost.google/course_templates/656) |

#### Security & Governance
| Status | Badge | Link |
|--------|-------|------|
| ✅ | [Configure Service Accounts and IAM Roles for Google Cloud](course/702/laps/702/) | [course_templates/702](https://www.cloudskillsboost.google/course_templates/702) |
| ✅ | [Implement Cloud Security Fundamentals on Google Cloud](course/645/laps/645/) | [course_templates/645](https://www.cloudskillsboost.google/course_templates/645) |
| ✅ | [Mitigate Threats and Vulnerabilities with Security Command Center](course/759/laps/759/) | [course_templates/759](https://www.cloudskillsboost.google/course_templates/759) |
| ⏳ | Monitor and Log with Google Cloud Observability | [course_templates/749](https://www.cloudskillsboost.google/course_templates/749) |
| ⏳ | Monitoring in Google Cloud | [course_templates/747](https://www.cloudskillsboost.google/course_templates/747) |
| ✅ | [Use APIs to Work with Cloud Storage](course/755/laps/755/) | [course_templates/755](https://www.cloudskillsboost.google/course_templates/755) |

#### Cloud Infrastructure & Applications
| Status | Badge | Link |
|--------|-------|------|
| ✅ | [Cloud Run Functions: 3 Ways](course/696/laps/598830/) | [course_templates/696](https://www.cloudskillsboost.google/course_templates/696) |
| ✅ | [Deploy Kubernetes Applications on Google Cloud](course/663/laps/663/) | [course_templates/663](https://www.cloudskillsboost.google/course_templates/663) |
| ✅ | [Develop Serverless Applications on Cloud Run](course/741/laps/741/) | [course_templates/741](https://www.cloudskillsboost.google/course_templates/741) |
| ✅ | [Manage Kubernetes in Google Cloud](course/783/laps/783/) | [course_templates/783](https://www.cloudskillsboost.google/course_templates/783) |
| ✅ | [The Basics of Google Cloud Compute](course/754/laps/597887/) | [course_templates/754](https://www.cloudskillsboost.google/course_templates/754) |

---

### Regular Badges

#### AI Agent Development
| Status | Badge | Link |
|--------|-------|------|
| ✅ | [Deploy Multi-Agent Architectures (ADK)](course/1445/laps/619095/) | [course_templates/1445](https://www.cloudskillsboost.google/course_templates/1445) |
| ⏳ | Build AI Agents with Enterprise Databases | [course_templates/1436](https://www.cloudskillsboost.google/course_templates/1436) |
| ⏳ | Build Generative AI Agents with Vertex AI and Flutter | [course_templates/1162](https://www.cloudskillsboost.google/course_templates/1162) |
| ⏳ | Build intelligent agents with Agent Development Kit (ADK) | [course_templates/1382](https://www.cloudskillsboost.google/course_templates/1382) |
| ⏳ | Create Embeddings, Vector Search, and RAG with BigQuery | [course_templates/1210](https://www.cloudskillsboost.google/course_templates/1210) |
| ⏳ | Deploy Multi-Agent Systems with ADK and Agent Engine | [course_templates/1340](https://www.cloudskillsboost.google/course_templates/1340) |
| ⏳ | Vector Search and Embeddings | [course_templates/939](https://www.cloudskillsboost.google/course_templates/939) |

#### Gemini
| Status | Badge | Link |
|--------|-------|------|
| ⏳ | Gemini for Application Developers | [course_templates/881](https://www.cloudskillsboost.google/course_templates/881) |
| ⏳ | Gemini for Cloud Architects | [course_templates/878](https://www.cloudskillsboost.google/course_templates/878) |
| ⏳ | Gemini for DevOps Engineers | [course_templates/882](https://www.cloudskillsboost.google/course_templates/882) |
| ⏳ | Gemini for Network Engineers | [course_templates/884](https://www.cloudskillsboost.google/course_templates/884) |
| ⏳ | Gemini for Security Engineers | [course_templates/886](https://www.cloudskillsboost.google/course_templates/886) |

#### Applied AI
| Status | Badge | Link |
|--------|-------|------|
| ⏳ | Agent Assist and its Gen AI Capabilities | [course_templates/1159](https://www.cloudskillsboost.google/course_templates/1159) |
| ⏳ | Create Agents with Generative Playbooks | [course_templates/1122](https://www.cloudskillsboost.google/course_templates/1122) |
| ⏳ | Vertex AI Search for Commerce | [course_templates/391](https://www.cloudskillsboost.google/course_templates/391) |

#### Application Development
| Status | Badge | Link |
|--------|-------|------|
| ⏳ | AI Boost Bites: Automate tasks with Gemini and Apps Script | [course_templates/1371](https://www.cloudskillsboost.google/course_templates/1371) |
| ⏳ | Google Cloud Computing Foundations: Cloud Computing Fundamentals | [course_templates/153](https://www.cloudskillsboost.google/course_templates/153) |
| ⏳ | Streamline App Development with Gemini Code Assist | [course_templates/1166](https://www.cloudskillsboost.google/course_templates/1166) |

#### AI Security and Governance
| Status | Badge | Link |
|--------|-------|------|
| ⏳ | Introduction to Security in the World of AI | [course_templates/1146](https://www.cloudskillsboost.google/course_templates/1146) |
| ⏳ | Model Armor: Securing AI Deployments | [course_templates/1385](https://www.cloudskillsboost.google/course_templates/1385) |

## General usage

1. Open a Cloud Shell or a terminal with `gcloud` authenticated to your lab project.
2. Navigate to the lab directory.
3. Make the script executable and run it:

```bash
chmod +x lab_script.sh
./lab_script.sh
```

Each script supports `--help` for available flags.

## Requirements

- `gcloud` CLI — authenticated (`gcloud auth login`) and project set
- Bash 4+
