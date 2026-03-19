# Lab 619095 — Build Multi-Agent Systems with ADK

**Course 1445: GENAI106**

Automates the Google Cloud Skills Boost lab: sets up the ADK environment, patches `agent.py` files for all tasks (parent/sub-agents, session state, LoopAgent, ParallelAgent).

> **Note:** This lab runs entirely in Cloud Shell. The `iac/` folder only enables the required GCP APIs — there is no infrastructure to provision.

## What the script does

| Task | Actions |
|------|---------|
| **1** | Copy lab files from GCS bucket, install `google-adk` and requirements, create `.env` files |
| **2** | Patch `parent_and_subagents/agent.py` — add `sub_agents` and transfer instructions to `root_agent` |
| **3** | Patch `parent_and_subagents/agent.py` — add `save_attractions_to_state` tool and state-reading instructions |
| **5** | Patch `workflow_agents/agent.py` — add `critic` agent and `writers_room` `LoopAgent` |
| **6** | Patch `workflow_agents/agent.py` — add `box_office_researcher`, `casting_agent`, `preproduction_team` `ParallelAgent` |

> Task 4 requires no changes — the `workflow_agents/agent.py` file is provided by the bucket as-is.

## Prerequisites

- Cloud Shell (the lab environment)
- `gcloud` authenticated with your Qwiklabs project set

## Option 1 — Bash script

```bash
# Run directly from GitHub
bash <(curl -s https://raw.githubusercontent.com/monkey-mode/google-skills-script/main/course/1445/laps/619095/script/lab_script.sh)

# Custom model
bash <(curl -s https://raw.githubusercontent.com/monkey-mode/google-skills-script/main/course/1445/laps/619095/script/lab_script.sh) --model gemini-2.0-flash-001
```

```bash
# Or clone and run locally
cd script/
chmod +x lab_script.sh
./lab_script.sh
```

After the script completes, run the agents:

```bash
cd ~/adk_multiagent_systems

# Tasks 2 & 3 — CLI
adk run parent_and_subagents

# Tasks 4–6 — Web UI
adk web --reload_agents
# Open http://localhost:8000 → select workflow_agents
```

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `-m`, `--model` | `gemini-2.0-flash` | Gemini model ID |

## Option 2 — Terraform (API enablement only)

```bash
cd iac/
terraform init
terraform apply -var="project_id=YOUR_PROJECT_ID"
```

Or from GitHub:

```bash
mkdir lab-619095 && cd lab-619095
terraform init -from-module=github.com/monkey-mode/google-skills-script//course/1445/laps/619095/iac
terraform apply -var="project_id=YOUR_PROJECT_ID"
```
