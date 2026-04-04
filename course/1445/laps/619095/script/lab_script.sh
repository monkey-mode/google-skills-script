#!/bin/bash
# ============================================================
# Google Cloud: Build Multi-Agent Systems with ADK - Lab Script
# Course 1445 / Lab 619095
# Usage:
#   ./lab_script.sh
#   ./lab_script.sh --model gemini-2.0-flash
# ============================================================

set -euo pipefail

# ── Colours ────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[✓]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[✗]${RESET}    $*" >&2; exit 1; }
header()  { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${RESET}"
            echo -e "${BOLD}${CYAN}  $*${RESET}"
            echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; }

# ── Defaults ───────────────────────────────────────────────
MODEL="gemini-2.0-flash"

# ── Argument Parsing ───────────────────────────────────────
usage() {
  echo -e "
${BOLD}Usage:${RESET}
  $0 [OPTIONS]

${BOLD}Options:${RESET}
  -m, --model   MODEL   Gemini model ID (default: gemini-2.0-flash)
  -h, --help            Show this help message
"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--model) MODEL="$2"; shift 2 ;;
    -h|--help)  usage ;;
    *) error "Unknown argument: $1. Use --help for usage." ;;
  esac
done

# ── Resolve project ────────────────────────────────────────
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
[[ -z "$PROJECT_ID" ]] && error "No active GCP project. Run: gcloud config set project PROJECT_ID"

# ══════════════════════════════════════════════════════════
header "ADK Multi-Agent Lab — Lab 619095"
echo -e "  Project : ${BOLD}$PROJECT_ID${RESET}"
echo -e "  Model   : ${BOLD}$MODEL${RESET}"

# ── Enable required APIs ───────────────────────────────────
header "Enabling required APIs"

gcloud services enable \
  aiplatform.googleapis.com \
  storage.googleapis.com \
  --quiet
success "APIs enabled"

# ── Task 1: Copy files and install ADK ────────────────────
header "Task 1 — Setup: Copy files & install ADK"

cd ~
gcloud storage cp -r "gs://${PROJECT_ID}-bucket/*" .
success "Lab files copied from bucket"

ADK_PATH="/home/${USER}/.local/bin"
export PATH="$PATH:$ADK_PATH"

# Persist PATH to .bashrc so adk is available after the script exits
if ! grep -q "$ADK_PATH" ~/.bashrc 2>/dev/null; then
  echo "export PATH=\"\$PATH:$ADK_PATH\"" >> ~/.bashrc
fi

python3 -m pip install google-adk -r adk_multiagent_systems/requirements.txt -q
success "ADK and requirements installed"

# ── Task 1: Create .env files ─────────────────────────────
header "Task 1 — Create .env files"

cat > ~/adk_multiagent_systems/parent_and_subagents/.env <<EOF
GOOGLE_GENAI_USE_VERTEXAI=TRUE
GOOGLE_CLOUD_PROJECT=${PROJECT_ID}
GOOGLE_CLOUD_LOCATION=global
MODEL=${MODEL}
EOF
cp ~/adk_multiagent_systems/parent_and_subagents/.env \
   ~/adk_multiagent_systems/workflow_agents/.env
success ".env files created for both agent directories"

# ── Task 2 & 3: Patch parent_and_subagents/agent.py ───────
header "Task 2 & 3 — Patch parent_and_subagents/agent.py"

python3 - <<'PYEOF'
import re, os, sys

path = os.path.expanduser(
    '~/adk_multiagent_systems/parent_and_subagents/agent.py'
)

with open(path) as f:
    src = f.read()

# ── Task 2a: add sub_agents to root_agent ─────────────────
# Inserts sub_agents=[] as the last parameter before the closing paren
# of the root_agent = Agent(...) block.
if 'sub_agents=[travel_brainstormer' not in src:
    src = re.sub(
        r'(root_agent\s*=\s*Agent\()(.*?)(\))',
        lambda m: m.group(1) + m.group(2).rstrip()
            + ',\n    sub_agents=[travel_brainstormer, attractions_planner],\n' + m.group(3),
        src, count=1, flags=re.DOTALL
    )
    print('[✓] Added sub_agents to root_agent')
else:
    print('[~] sub_agents already present in root_agent, skipping')

# ── Task 2b: add transfer instructions to root_agent ──────
TRANSFER_INSTRUCTIONS = """
If they need help deciding, send them to
'travel_brainstormer'.
If they know what country they'd like to visit,
send them to the 'attractions_planner'.
"""
if 'travel_brainstormer' not in src or "send them to" not in src:
    # Append to the existing instruction string of root_agent
    src = re.sub(
        r"(root_agent\s*=\s*Agent\(.*?instruction\s*=\s*)(\"\"\")(.*?)(\"\"\")",
        lambda m: m.group(1) + m.group(2) + m.group(3).rstrip()
            + TRANSFER_INSTRUCTIONS + m.group(4),
        src, count=1, flags=re.DOTALL
    )
    print('[✓] Added transfer instructions to root_agent')
else:
    print('[~] Transfer instructions already present, skipping')

# ── Task 3: add save_attractions_to_state tool ────────────
TOOL_CODE = '''
def save_attractions_to_state(
    tool_context: ToolContext,
    attractions: List[str]
) -> dict[str, str]:
    """Saves the list of attractions to state["attractions"].

    Args:
        attractions [str]: a list of strings to add to the list of attractions

    Returns:
        None
    """
    existing_attractions = tool_context.state.get("attractions", [])
    tool_context.state["attractions"] = existing_attractions + attractions
    return {"status": "success"}
'''
if 'save_attractions_to_state' not in src:
    # Insert after the # Tools header comment
    if '# Tools' in src:
        src = src.replace('# Tools', '# Tools\n' + TOOL_CODE, 1)
    else:
        # Fallback: insert before the first Agent() definition
        src = re.sub(r'(\w+ = Agent\()', TOOL_CODE + r'\n\1', src, count=1)
    print('[✓] Added save_attractions_to_state tool')
else:
    print('[~] save_attractions_to_state already present, skipping')

# ── Task 3: add tool to attractions_planner ───────────────
if 'tools=[save_attractions_to_state]' not in src:
    src = re.sub(
        r'(attractions_planner\s*=\s*Agent\()(.*?)(\))',
        lambda m: m.group(1) + m.group(2).rstrip()
            + ',\n    tools=[save_attractions_to_state],\n' + m.group(3),
        src, count=1, flags=re.DOTALL
    )
    print('[✓] Added tools=[save_attractions_to_state] to attractions_planner')
else:
    print('[~] Tool already on attractions_planner, skipping')

# ── Task 3: add state-reading bullet points to attractions_planner ──
STATE_INSTRUCTIONS = """
- When they reply, use your tool to save their selected attraction
and then provide more possible attractions.
- If they ask to view the list, provide a bulleted list of
{ attractions? } and then suggest some more.
"""
if '{ attractions? }' not in src:
    src = re.sub(
        r'(attractions_planner\s*=\s*Agent\(.*?instruction\s*=\s*)(\"\"\")(.*?)(\"\"\")',
        lambda m: m.group(1) + m.group(2) + m.group(3).rstrip()
            + STATE_INSTRUCTIONS + m.group(4),
        src, count=1, flags=re.DOTALL
    )
    print('[✓] Added state-reading instructions to attractions_planner')
else:
    print('[~] State instructions already present, skipping')

with open(path, 'w') as f:
    f.write(src)
PYEOF

success "parent_and_subagents/agent.py patched"

# ── Task 5: Patch workflow_agents/agent.py (LoopAgent) ────
header "Task 5 — Patch workflow_agents/agent.py (LoopAgent)"

python3 - <<'PYEOF'
import re, os

path = os.path.expanduser('~/adk_multiagent_systems/workflow_agents/agent.py')

with open(path) as f:
    src = f.read()

# ── Add imports ───────────────────────────────────────────
if 'exit_loop' not in src:
    src = src.replace(
        'from google.adk.tools import',
        'from google.adk.tools import exit_loop,\nfrom google.adk.tools import',
        1
    )
    # Fallback if pattern above didn't match
    if 'exit_loop' not in src:
        src = 'from google.adk.tools import exit_loop\nfrom google.adk.models import Gemini\n' + src
    print('[✓] Added exit_loop import')
else:
    print('[~] exit_loop import already present, skipping')

# ── Add critic agent ──────────────────────────────────────
CRITIC_AGENT = '''
critic = Agent(
    name="critic",
    model=Gemini(model=model_name, retry_options=RETRY_OPTIONS),
    description="Reviews the outline so that it can be improved.",
    instruction="""
    INSTRUCTIONS:
    Consider these questions about the PLOT_OUTLINE:
    - Does it meet a satisfying three-act cinematic structure?
    - Do the characters' struggles seem engaging?
    - Does it feel grounded in a real time period in history?
    - Does it sufficiently incorporate historical details from the RESEARCH?

    If the PLOT_OUTLINE does a good job with these questions, exit the writing loop with your 'exit_loop' tool.
    If significant improvements can be made, use the 'append_to_state' tool to add your feedback to the field 'CRITICAL_FEEDBACK'.
    Explain your decision and briefly summarize the feedback you have provided.

    PLOT_OUTLINE:
    { PLOT_OUTLINE? }

    RESEARCH:
    { research? }
    """,
    before_model_callback=log_query_to_model,
    after_model_callback=log_model_response,
    tools=[append_to_state, exit_loop]
)
'''

if 'critic = Agent(' not in src:
    # Insert before film_concept_team or screenwriter definition
    insert_before = 'film_concept_team'
    if insert_before in src:
        src = src.replace(
            'film_concept_team',
            CRITIC_AGENT + '\nfilm_concept_team',
            1
        )
    print('[✓] Added critic agent')
else:
    print('[~] critic agent already present, skipping')

# ── Add writers_room LoopAgent ────────────────────────────
WRITERS_ROOM = '''
writers_room = LoopAgent(
    name="writers_room",
    description="Iterates through research and writing to improve a movie plot outline.",
    sub_agents=[
        researcher,
        screenwriter,
        critic
    ],
    max_iterations=5,
)
'''

if 'writers_room' not in src:
    src = src.replace(
        'film_concept_team',
        WRITERS_ROOM + '\nfilm_concept_team',
        1
    )
    print('[✓] Added writers_room LoopAgent')
else:
    print('[~] writers_room already present, skipping')

# ── Update film_concept_team sub_agents ───────────────────
if 'writers_room' in src and 'researcher' in src:
    src = re.sub(
        r'(film_concept_team\s*=\s*SequentialAgent\(.*?sub_agents\s*=\s*\[)(.*?)(\])',
        r'\1\n        writers_room,\n        file_writer\n    \3',
        src, count=1, flags=re.DOTALL
    )
    print('[✓] Updated film_concept_team to use writers_room')

# ── Task 6: ParallelAgent additions (same file, same pass) ─
# ── Add box_office_researcher + casting_agent + ParallelAgent ──
PARALLEL_AGENTS = '''
box_office_researcher = Agent(
    name="box_office_researcher",
    model=Gemini(model=model_name, retry_options=RETRY_OPTIONS),
    description="Considers the box office potential of this film",
    instruction="""
    PLOT_OUTLINE:
    { PLOT_OUTLINE? }

    INSTRUCTIONS:
    Write a report on the box office potential of a movie like that described in PLOT_OUTLINE based on the reported box office performance of other recent films.
    """,
    output_key="box_office_report"
)

casting_agent = Agent(
    name="casting_agent",
    model=Gemini(model=model_name, retry_options=RETRY_OPTIONS),
    description="Generates casting ideas for this film",
    instruction="""
    PLOT_OUTLINE:
    { PLOT_OUTLINE? }

    INSTRUCTIONS:
    Generate ideas for casting for the characters described in PLOT_OUTLINE
    by suggesting actors who have received positive feedback from critics and/or
    fans when they have played similar roles.
    """,
    output_key="casting_report"
)

preproduction_team = ParallelAgent(
    name="preproduction_team",
    sub_agents=[
        box_office_researcher,
        casting_agent
    ]
)
'''

if 'box_office_researcher' not in src:
    src = src.replace(
        'film_concept_team',
        PARALLEL_AGENTS + '\nfilm_concept_team',
        1
    )
    print('[✓] Added box_office_researcher, casting_agent, preproduction_team')
else:
    print('[~] Parallel agents already present, skipping')

# ── Update film_concept_team to include preproduction_team ─
if 'preproduction_team' not in src:
    src = re.sub(
        r'(film_concept_team\s*=\s*SequentialAgent\(.*?sub_agents\s*=\s*\[)(.*?)(\])',
        r'\1\n        writers_room,\n        preproduction_team,\n        file_writer\n    \3',
        src, count=1, flags=re.DOTALL
    )
    print('[✓] Updated film_concept_team to include preproduction_team')

# ── Update file_writer instruction to include reports ──────
FILE_WRITER_INSTRUCTION = '''    instruction="""
    INSTRUCTIONS:
    - Create a marketable, contemporary movie title suggestion for the movie described in the PLOT_OUTLINE. If a title has been suggested in PLOT_OUTLINE, you can use it, or replace it with a better one.
    - Use your \'write_file\' tool to create a new txt file with the following arguments:
        - for a filename, use the movie title
        - Write to the \'movie_pitches\' directory.
        - For the \'content\' to write, include:
            - The PLOT_OUTLINE
            - The BOX_OFFICE_REPORT
            - The CASTING_REPORT

    PLOT_OUTLINE:
    { PLOT_OUTLINE? }

    BOX_OFFICE_REPORT:
    { box_office_report? }

    CASTING_REPORT:
    { casting_report? }
    """,'''

if '{ box_office_report? }' not in src:
    src = re.sub(
        r'(file_writer\s*=\s*Agent\(.*?)(instruction\s*=\s*""".*?""")',
        lambda m: m.group(1) + FILE_WRITER_INSTRUCTION,
        src, count=1, flags=re.DOTALL
    )
    print('[✓] Updated file_writer instruction to include reports')
else:
    print('[~] file_writer instruction already updated, skipping')

with open(path, 'w') as f:
    f.write(src)
PYEOF

success "workflow_agents/agent.py patched (Tasks 5 & 6)"

# ── Done ───────────────────────────────────────────────────
header "✅  All Tasks Completed"

echo -e "\n${BOLD}Next steps:${RESET}"
echo -e "  source ~/.bashrc   ${CYAN}# reload PATH so 'adk' is available${RESET}"
echo -e "  cd ~/adk_multiagent_systems"
echo -e ""
echo -e "  # Run parent_and_subagents (Task 2 & 3):"
echo -e "  adk run parent_and_subagents"
echo -e ""
echo -e "  # Run workflow_agents with web UI (Task 4-6):"
echo -e "  adk web --reload_agents"
echo -e "  # Then open http://localhost:8000 and select workflow_agents"
echo -e "\n${BOLD}Done! 🎉${RESET}\n"
