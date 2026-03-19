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
| [1445 — GENAI106](course/1445/laps/619095/) | [619095 — Build Multi-Agent Systems with ADK](course/1445/laps/619095/) | Orchestrate multi-agent systems with Google ADK |

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
