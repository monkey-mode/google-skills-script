# Lab 597887 — Create a Virtual Machine

**Course 754: The Basics of Google Cloud Compute**

Automates the Google Cloud Skills Boost lab: provision two Compute Engine VMs, open HTTP traffic via a firewall rule, and install NGINX — all in parallel.

## What the script does

| Phase | Actions |
|-------|---------|
| **1** | Set `gcloud` region/zone config; create `allow-http` firewall rule (tcp:80) |
| **2** | Create `gcelab` (http-server tag) and `gcelab2` in parallel |
| **3** | Install & start NGINX on `gcelab`; verify SSH on `gcelab2` (parallel) |

## Prerequisites

- `gcloud` CLI authenticated and pointing at your lab project
- Bash 4+

## Usage

```bash
chmod +x lab_script.sh

# Use defaults (us-east1 / us-east1-c)
./lab_script.sh

# Custom region & zone — long flags
./lab_script.sh --region us-central1 --zone us-central1-a

# Custom region & zone — short flags
./lab_script.sh -r europe-west1 -z europe-west1-b

# Help
./lab_script.sh --help
```

## Resources created

| Resource | Details |
|----------|---------|
| `gcelab` | e2-medium, Debian 12, 10 GB pd-balanced, tag: `http-server` |
| `gcelab2` | e2-medium, Debian 12, 10 GB pd-balanced |
| `allow-http` | Firewall rule — tcp:80, target-tag: `http-server` |

After completion the script prints the external IP of `gcelab` and the NGINX URL.
