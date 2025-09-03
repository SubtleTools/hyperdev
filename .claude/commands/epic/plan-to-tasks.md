# Generate Task Master Tasks from Plan or Specification

This command creates a complete Task Master workflow from a planning document, including PRD generation, task creation, complexity analysis, and multi-agent review.

## Main Command

### Usage Formats

```bash
# Format 1: Auto-generate epic name
/epic:plan-to-tasks <DOCUMENT> [NO_STOP=0|1] [MAX_SUBAGENTS=9]

# Format 2: Specify epic name
/epic:plan-to-tasks <EPIC_NAME> <DOCUMENT> [NO_STOP=0|1] [MAX_SUBAGENTS=9]
```

### Arguments

- `EPIC_NAME` (optional): Custom epic name (e.g., "diagram-refactoring"). If not provided, will be auto-generated from document content
- `DOCUMENT` (required): Path to the input document (text file with plan/specification)
- `NO_STOP` (optional, default: 0): Whether to include "DO NOT STOP" reminder in generated tasks (0 or 1)
- `MAX_SUBAGENTS` (optional, default: 9): Maximum number of subagents for review phase (1-20)

### Examples

```bash
# Auto-generate epic name
/epic:plan-to-tasks requirements.txt

# Specify epic name
/epic:plan-to-tasks diagram-refactoring @agent/reports/08-15/20-46-diagram-refactoring-proposal.md

# With options
/epic:plan-to-tasks auth-system docs/auth-spec.md NO_STOP=1 MAX_SUBAGENTS=12
```

## Continue Command

`/project:tm/plan-to-tasks:continue [EPIC-FOLDER]`

Resume an interrupted workflow from where it left off:

- `EPIC-FOLDER` (required): Path to the epic folder (e.g., `agent/epics/user-auth-system`)
- Reads the workflow state from `workflow-state.json`
- Continues from the last successful step

## Dashboard Integration

To monitor epic progress in real-time, use the dashboard:

```bash
# Build dashboard (first time only)
cd agent/dashboard && bun install && bun run build && cd ../..

# Run dashboard in separate terminal
./agent/dashboard/epic-dashboard agent/epics/[EPIC-NAME]
```

## Epic Workflow

### 1. Argument Parsing & Document Validation

First, parse the arguments:

- Check if first argument is a file path or epic name
- If first argument doesn't exist as a file:
  - Treat it as EPIC_NAME
  - Second argument must be DOCUMENT path
- If first argument exists as a file:
  - Treat it as DOCUMENT path
  - Epic name will be auto-generated

If no valid document path found, prompt user:

```
❌ No document path provided!

Usage:
/epic:plan-to-tasks [EPIC_NAME] <DOCUMENT> [NO_STOP=0|1] [MAX_SUBAGENTS=9]

Examples:
/epic:plan-to-tasks requirements.txt
/epic:plan-to-tasks auth-system docs/auth-spec.md
```

Then EXIT the workflow - do not proceed further.

Once document path is identified, validate it:

- Verify file exists and is readable
- Check file is text-based (.txt, .md, .doc, etc.)
- Ensure minimum content length (>100 characters)
- Analyze content to determine if it contains actionable requirements
- If validation fails, provide specific error message

### 2. Epic Analysis & Setup

Determine epic name:

- If EPIC_NAME was provided as argument, use it directly
- Otherwise, analyze document to generate semantic epic name:
  - Extract primary goal and objectives
  - Identify key features and requirements
  - Generate name (e.g., "user-auth-system", "data-migration")
  - Keep names short, descriptive, and filesystem-friendly

Setup epic:

- Create epic folder: `agent/epics/[EPIC-NAME]/`
- Save original document: `agent/epics/[EPIC-NAME]/original-spec.[ext]`
- Extract technology stack if mentioned for later use

**Initialize Progress Tracking Immediately:**

Follow the standard epic progress tracking system defined in `.claude/epic/progress-tracking.md`:

```bash
# Create epic folder
mkdir -p agent/epics/[EPIC-NAME]

# Initialize workflow state using standard schema
echo '{
  "epic_name": "[EPIC-NAME]",
  "current_step": 2,
  "completed_steps": [1],
  "workflow_config": {
    "no_stop": '$NO_STOP',
    "max_subagents": '$MAX_SUBAGENTS',
    "use_research": null
  },
  "tag_name": null,
  "artifacts": {},
  "agents": {
    "required": [],
    "created": [],
    "available": []
  },
  "execution": {
    "tasks_in_progress": [],
    "tasks_completed": [],
    "parallel_agents_active": 0,
    "last_task_completion": null
  },
  "timestamp": "'$(date -Iseconds)'",
  "last_updated": "'$(date -Iseconds)'"
}' > agent/epics/[EPIC-NAME]/workflow-state.json

# Start workflow log using standard format
echo "[$(date -Iseconds)] [info] Epic workflow started for [EPIC-NAME]" > agent/epics/[EPIC-NAME]/workflow.log
echo "[$(date -Iseconds)] [success] Document validation completed" >> agent/epics/[EPIC-NAME]/workflow.log
echo "[$(date -Iseconds)] [info] Epic folder created: agent/epics/[EPIC-NAME]" >> agent/epics/[EPIC-NAME]/workflow.log
```

**Notify User About Dashboard:**

Use the standard dashboard notification from `.claude/epic/progress-tracking.md`:

```
╔════════════════════════════════════════════════════════════════╗
║                 EPIC DASHBOARD AVAILABLE                       ║
╠════════════════════════════════════════════════════════════════╣
║ To monitor progress in real-time, open a new terminal and run: ║
║                                                                 ║
║   ./agent/dashboard/epic-dashboard agent/epics/[EPIC-NAME]     ║
║                                                                 ║
║ Or if dashboard not built yet:                                 ║
║   cd agent/dashboard                                           ║
║   bun install && bun run build && cd ../..                    ║
║   ./agent/dashboard/epic-dashboard agent/epics/[EPIC-NAME]     ║
║                                                                 ║
║ Dashboard will show live progress for all workflow steps       ║
╚════════════════════════════════════════════════════════════════╝
```

### 3. Tag Creation & Switching

Create dedicated Task Master tag for the epic:

```bash
task-master add-tag --name="[EPIC-NAME]" --description="Tasks for [EPIC-NAME] epic"
task-master use-tag --name="[EPIC-NAME]"

# Update workflow state and log using standard progress tracking
echo "[$(date -Iseconds)] [info] Creating Task Master tag: [EPIC-NAME]" >> agent/epics/[EPIC-NAME]/workflow.log
echo "[$(date -Iseconds)] [success] Tag created and activated" >> agent/epics/[EPIC-NAME]/workflow.log

# Update state to step 3 using standard format
jq --arg timestamp "$(date -Iseconds)" '
  .current_step = 3 | 
  .completed_steps += [2] | 
  .tag_name = "[EPIC-NAME]" |
  .last_updated = $timestamp' \
  agent/epics/[EPIC-NAME]/workflow-state.json > tmp.json && \
  mv tmp.json agent/epics/[EPIC-NAME]/workflow-state.json
```

### 4. PRD Generation

Generate comprehensive PRD based on original document:

```bash
echo "[$(date -Iseconds)] [info] Starting PRD generation" >> agent/epics/[EPIC-NAME]/workflow.log

# Update state to step 4 using standard format
jq --arg timestamp "$(date -Iseconds)" '
  .current_step = 4 | 
  .completed_steps += [3] |
  .last_updated = $timestamp' \
  agent/epics/[EPIC-NAME]/workflow-state.json > tmp.json && \
  mv tmp.json agent/epics/[EPIC-NAME]/workflow-state.json
```

- Use `.taskmaster/templates/example_prd.txt` as structure guide
- Preserve ALL information from original document
- Enrich with:
  - Technical architecture details
  - Development roadmap with phases
  - Logical dependency chain
  - Risk analysis and mitigations
  - User experience considerations
  - Core features breakdown
- Save as: `agent/epics/[EPIC-NAME]/prd.md`

```bash
echo "[$(date -Iseconds)] [success] PRD generated and saved" >> agent/epics/[EPIC-NAME]/workflow.log

# Update artifacts in state using standard format
jq --arg timestamp "$(date -Iseconds)" '
  .artifacts.prd = "prd.md" |
  .last_updated = $timestamp' \
  agent/epics/[EPIC-NAME]/workflow-state.json > tmp.json && \
  mv tmp.json agent/epics/[EPIC-NAME]/workflow-state.json
```

### 5. Agent Analysis & Creation

Analyze PRD to determine specialized agents needed:

**Step 1: Identify Required Agents**

- Scan for technology keywords (Angular, Elysia, React, TypeScript, etc.)
- Identify domain areas (API, UI, database, testing, etc.)
- Determine task types (architecture, implementation, review, etc.)
- Create list of required agent specializations

**Step 2: Check Agent Availability**

- Compare required agents with existing in `.claude/agents/`
- Identify missing agent types
- List available vs needed agents

**Step 3: Create Missing Agents (if needed)**

If agents are missing:

1. Generate agent definitions for missing specializations
2. Save new agents to `.claude/agents/[name]-expert.md`
3. Add agent list to PRD metadata section
4. Save workflow state to `workflow-state.json`
5. Display message:
   ```
   ⚠️ New Agents Created:
   - [agent-1-name]
   - [agent-2-name]

   These agents have been saved to .claude/agents/

   Please restart Claude Code to load the new agents, then run:
   /project:tm/plan-to-tasks:continue agent/epics/[EPIC-NAME]
   ```
6. Exit gracefully with state preserved

**Step 4: Add Agents to PRD**

- List all agents (existing + created) in PRD metadata
- Include agent selection rationale
- Document which agents handle which task types

### 6. Research Decision

Determine if research is needed based on:

- Novel technologies mentioned
- Complex integrations required
- Regulatory/compliance requirements
- Performance/scalability concerns
- Unknown implementation approaches

Decision criteria:

- If 2+ research indicators: Use research mode
- If familiar tech stack: Skip research
- If uncertain: Default to research for better coverage

### 7. Parse PRD to Tasks

Execute appropriate parsing command with retry logic:

**Attempt Strategy** (up to 3 attempts):

1. First attempt with selected mode (research or standard)
2. If fails, retry with adjusted parameters
3. If still fails, try alternative approach
4. After 3 failures, switch to manual task creation

**With Research** (if determined necessary):

```bash
task-master parse-prd --input="agent/epics/[EPIC-NAME]/prd.md" --research
```

**Without Research** (for familiar domains):

```bash
task-master parse-prd --input="agent/epics/[EPIC-NAME]/prd.md"
```

**Error Handling**:

- Temporary errors (network, timeout): Retry after 5 seconds
- Parse errors: Adjust PRD format and retry
- No tasks generated: Try with `--num-tasks=15` parameter
- Complete failure: Prompt for manual task creation with template

### 8. Complexity Analysis

Analyze generated tasks for expansion needs:

```bash
task-master analyze-complexity --threshold=5
```

Save report: `agent/epics/[EPIC-NAME]/complexity-report.json`

### 9. Multi-Agent Review

Launch comprehensive task review with agent coordination:

Build review command with arguments:

```bash
# Base command
REVIEW_CMD="/project:tm/review-all-tasks"

# Add MAX_SUBAGENTS if provided (note: parameter name matches review-all-tasks.md)
if [ "$MAX_SUBAGENTS" != "" ]; then
  REVIEW_CMD="$REVIEW_CMD MAX_SUBAGENTS=$MAX_SUBAGENTS"
fi

# Add NO_STOP if requested (converts 0/1 to boolean for review command)
if [ "$NO_STOP" == "1" ]; then
  REVIEW_CMD="$REVIEW_CMD NO_STOP=true"
fi

# Execute review with progressive updates and smart agent selection
$REVIEW_CMD
```

### 10. Final Verification

After workflow completion:

- Verify tasks created in current tag
- Confirm complexity analysis complete
- Check review updates applied
- Generate summary report
- Save workflow log: `agent/epics/[EPIC-NAME]/workflow.log`

## Error Handling

Handle failures gracefully:

- **Invalid document**: Clear error with suggestions
- **PRD generation failure**: Save partial and request manual completion
- **Parse failure**: Retry with different parameters
- **No tasks generated**: Analyze why and suggest fixes
- **Tag conflicts**: Suggest alternative names
- **Agent failures**: Continue with remaining workflow

## Output Structure

```
agent/epics/[EPIC-NAME]/
├── original-spec.[ext]     # Original input document
├── prd.md                   # Generated PRD with agent metadata
├── complexity-report.json   # Complexity analysis
├── workflow.log            # Detailed execution log
├── workflow-state.json     # Workflow state for continuation
├── agents-created.txt      # List of newly created agents (if any)
└── review/                 # Agent review artifacts
    ├── assessments/
    ├── consolidations/
    └── final-report.md
```

## Progress Tracking System

This command follows the standardized epic progress tracking system defined in `.claude/epic/progress-tracking.md`.

**Workflow Steps (1-10):**

1. Document Analysis & Validation
2. Epic Setup & Folder Creation
3. Tag Creation & Switching
4. PRD Generation
5. Agent Analysis & Creation
6. Research Decision
7. Parse PRD to Tasks
8. Complexity Analysis
9. Multi-Agent Review
10. Final Verification

All progress updates, state management, and logging follow the standard format to ensure consistent dashboard integration and continuation support.

## Workflow State Management

The `workflow-state.json` file tracks progress:

```json
{
  "epic_name": "user-auth-system",
  "current_step": 5,
  "completed_steps": [1, 2, 3, 4],
  "workflow_config": {
    "no_stop": false,
    "max_subagents": 9,
    "use_research": true
  },
  "agents": {
    "required": ["angular-expert", "elysia-expert", "auth-specialist"],
    "created": ["auth-specialist"],
    "available": ["angular-expert", "elysia-expert"]
  },
  "artifacts": {
    "original_doc": "original-spec.txt",
    "prd": "prd.md",
    "tasks_file": ".taskmaster/tasks/tasks.json",
    "complexity_report": "complexity-report.json"
  },
  "tag_name": "user-auth-system",
  "timestamp": "2025-01-16T10:30:00Z"
}
```

## Success Indicators

The command succeeds when:

1. ✅ Valid document processed
2. ✅ Epic folder created
3. ✅ TM tag created and active
4. ✅ PRD generated with all requirements
5. ✅ Tasks created from PRD
6. ✅ Complexity analyzed
7. ✅ Tasks reviewed by agents
8. ✅ All artifacts saved

## Usage Examples

```bash
# Auto-generate epic name from document
/epic:plan-to-tasks requirements.txt

# Specify custom epic name
/epic:plan-to-tasks auth-system docs/auth-requirements.txt

# Complex example with report
/epic:plan-to-tasks diagram-refactoring @agent/reports/08-15/20-46-diagram-refactoring-proposal.md

# With continuous execution
/epic:plan-to-tasks payment-gateway spec.md NO_STOP=1

# Limited parallelism
/epic:plan-to-tasks user-dashboard design.txt MAX_SUBAGENTS=6

# Full options
/epic:plan-to-tasks data-migration prd.txt NO_STOP=1 MAX_SUBAGENTS=12
```

## Implementation Notes

When executing this command:

1. **Document Analysis**: Use AI to extract semantic meaning, not just keywords
2. **Epic Naming**: Keep names short, descriptive, and filesystem-friendly
3. **PRD Quality**: Ensure PRD is comprehensive enough for task generation
4. **Agent Selection**: Match agents to actual technology needs, not assumptions
5. **Research Mode**: Err on side of using research for unfamiliar domains
6. **Progress Updates**: Provide clear status messages throughout workflow
7. **Artifact Preservation**: Save all intermediate outputs for debugging
8. **Tag Isolation**: Ensure all work happens in the new tag, not default

## Continuation Workflow

When resuming with `/project:tm/plan-to-tasks:continue [EPIC-FOLDER]`:

### 1. Load State

- Read `workflow-state.json` from epic folder
- Verify all artifacts still exist
- Check current TM tag matches epic

### 2. Resume from Last Step

Based on `current_step` in state:

- **Step 1-4**: Should not happen (pre-agent creation)
- **Step 5**: Agent creation interrupted - verify agents exist
- **Step 6**: Research decision - continue to parse-prd
- **Step 7**: Parse PRD - retry or continue to complexity
- **Step 8**: Complexity analysis - run or continue to review
- **Step 9**: Multi-agent review - resume or complete

### 3. Agent Verification

If continuation after agent creation:

- Verify all created agents exist in `.claude/agents/`
- Check agents are loaded (may require Claude Code restart)
- Continue with step 6 (Research Decision)

### 4. Completion

- Update workflow state after each step
- Mark workflow complete when all steps done
- Archive state file to `workflow-state.completed.json`

## Post-Execution

After successful completion, user can:

- Review generated tasks: `task-master list`
- Start implementation: `/project:tm/execute-all`
- Expand complex tasks: `task-master expand [ID]`
- Adjust task details: `task-master update [ID]`
- Switch between epics: `task-master use-tag [EPIC-NAME]`
- View epic artifacts: `ls agent/epics/[EPIC-NAME]/`

## Troubleshooting

### Common Issues

1. **"Agents not found" after creation**
   - Ensure Claude Code was restarted
   - Verify agents exist in `.claude/agents/`
   - Run continuation command

2. **Parse PRD fails repeatedly**
   - Check PRD format in epic folder
   - Try manual task creation
   - Adjust PRD and retry

3. **Continuation fails to resume**
   - Check `workflow-state.json` integrity
   - Verify tag is still active
   - Manually set tag: `task-master use-tag [EPIC-NAME]`

4. **Complexity analysis missing**
   - May have been skipped if no tasks
   - Run manually: `task-master analyze-complexity`

5. **Review agents not running**
   - Check MAX_SUBAGENTS setting
   - Verify required agents exist
   - Try with fewer parallel agents
