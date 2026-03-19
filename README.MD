# Google Skills Script

Bash automation scripts for Google Cloud Skills Boost labs.
Each script automates the manual steps of a lab so you can focus on learning the concepts rather than clicking through the console.

## Repository layout

```
course/
└── <course-id>/
    └── laps/
        └── <lab-id>/
            ├── lab_script.sh   # automation script
            └── README.MD       # lab-specific usage & notes
```

## Labs

| Course | Lab | Description |
|--------|-----|-------------|
| [754 — The Basics of Google Cloud Compute](course/754/laps/597887/) | [597887 — Create a Virtual Machine](course/754/laps/597887/) | Creating VMs & Installing NGINX on GCE |

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
