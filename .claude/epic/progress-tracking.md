# Epic Progress Tracking System

Standardized progress reporting for all epic workflow commands.

## Workflow State Schema

All epic workflows must maintain a `workflow-state.json` file with this structure:

```json
{
  "epic_name": "string",
  "current_step": "number",
  "completed_steps": ["array of numbers"],
  "workflow_config": {
    "no_stop": "boolean",
    "max_subagents": "number",
    "use_research": "boolean|null"
  },
  "tag_name": "string|null",
  "artifacts": {
    "original_doc": "string|null",
    "prd": "string|null",
    "tasks_file": "string|null",
    "complexity_report": "string|null"
  },
  "agents": {
    "required": ["array of strings"],
    "created": ["array of strings"],
    "available": ["array of strings"]
  },
  "execution": {
    "tasks_in_progress": ["array of task IDs"],
    "tasks_completed": ["array of task IDs"],
    "parallel_agents_active": "number",
    "last_task_completion": "ISO timestamp|null"
  },
  "timestamp": "ISO timestamp",
  "last_updated": "ISO timestamp"
}
```

## Logging Format

All workflows must write structured logs to `workflow.log`:

**Format:** `[timestamp] [level] message`

**Levels:**

- `info`: General progress updates, step transitions
- `success`: Step completed successfully, milestones reached
- `warning`: Non-critical issues, retries, fallbacks
- `error`: Failures requiring intervention or retry
- `agent`: Agent deployment, completion, or status updates

**Examples:**

```
[2025-01-16T14:30:00Z] [info] Epic workflow started for user-auth-system
[2025-01-16T14:32:15Z] [success] Document validation completed
[2025-01-16T14:35:20Z] [warning] PRD generation retry attempt 2/3
[2025-01-16T14:40:45Z] [agent] Deployed task-executor agent for task 3.2
[2025-01-16T14:42:10Z] [success] Task 3.2 completed by agent
[2025-01-16T14:45:00Z] [error] Task 5.1 failed - dependency conflict detected
```

## State Management Functions

### Initialize Progress Tracking

```bash
# Create epic folder and initialize tracking
mkdir -p agent/epics/[EPIC-NAME]

# Initialize workflow state
echo '{
  "epic_name": "'$EPIC_NAME'",
  "current_step": 1,
  "completed_steps": [],
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

# Start workflow log
echo "[$(date -Iseconds)] [info] Epic workflow started for $EPIC_NAME" > agent/epics/[EPIC-NAME]/workflow.log
```

### Update Progress State

```bash
# Update current step and completed steps
jq --arg step "$STEP_NUMBER" --arg timestamp "$(date -Iseconds)" '
  .current_step = ($step | tonumber) | 
  .completed_steps += [($step | tonumber) - 1] | 
  .last_updated = $timestamp' \
  agent/epics/[EPIC-NAME]/workflow-state.json > tmp.json && \
  mv tmp.json agent/epics/[EPIC-NAME]/workflow-state.json

# Log progress update
echo "[$(date -Iseconds)] [success] Step $((STEP_NUMBER-1)) completed" >> agent/epics/[EPIC-NAME]/workflow.log
echo "[$(date -Iseconds)] [info] Starting step $STEP_NUMBER" >> agent/epics/[EPIC-NAME]/workflow.log
```

### Update Artifact Tracking

```bash
# Add artifact to state
jq --arg key "$ARTIFACT_KEY" --arg path "$ARTIFACT_PATH" --arg timestamp "$(date -Iseconds)" '
  .artifacts[$key] = $path | 
  .last_updated = $timestamp' \
  agent/epics/[EPIC-NAME]/workflow-state.json > tmp.json && \
  mv tmp.json agent/epics/[EPIC-NAME]/workflow-state.json

# Log artifact creation
echo "[$(date -Iseconds)] [success] Artifact created: $ARTIFACT_KEY -> $ARTIFACT_PATH" >> agent/epics/[EPIC-NAME]/workflow.log
```

### Track Agent Activity

```bash
# Deploy agent for task execution
jq --arg task_id "$TASK_ID" --arg timestamp "$(date -Iseconds)" '
  .execution.tasks_in_progress += [$task_id] |
  .execution.parallel_agents_active += 1 |
  .last_updated = $timestamp' \
  agent/epics/[EPIC-NAME]/workflow-state.json > tmp.json && \
  mv tmp.json agent/epics/[EPIC-NAME]/workflow-state.json

echo "[$(date -Iseconds)] [agent] Deployed agent for task $TASK_ID" >> agent/epics/[EPIC-NAME]/workflow.log

# Complete task execution
jq --arg task_id "$TASK_ID" --arg timestamp "$(date -Iseconds)" '
  .execution.tasks_in_progress -= [$task_id] |
  .execution.tasks_completed += [$task_id] |
  .execution.parallel_agents_active -= 1 |
  .execution.last_task_completion = $timestamp |
  .last_updated = $timestamp' \
  agent/epics/[EPIC-NAME]/workflow-state.json > tmp.json && \
  mv tmp.json agent/epics/[EPIC-NAME]/workflow-state.json

echo "[$(date -Iseconds)] [success] Task $TASK_ID completed" >> agent/epics/[EPIC-NAME]/workflow.log
```

## Dashboard Integration

### Dashboard Notification

Display this notification after initializing progress tracking:

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

### State File Contract

The dashboard expects these fields in `workflow-state.json`:

- `current_step`: Current workflow step (1-based)
- `completed_steps`: Array of completed step numbers
- `execution.parallel_agents_active`: Number of agents currently running
- `execution.tasks_completed`: Array of completed task IDs
- `last_updated`: ISO timestamp of last state update

The dashboard reads `workflow.log` for real-time activity display.

## Error Handling

### Retry Logic with State Persistence

```bash
# Save retry state
jq --arg attempt "$ATTEMPT" --arg error "$ERROR_MSG" --arg timestamp "$(date -Iseconds)" '
  .retry_state = {
    "step": .current_step,
    "attempt": ($attempt | tonumber),
    "last_error": $error,
    "timestamp": $timestamp
  } |
  .last_updated = $timestamp' \
  agent/epics/[EPIC-NAME]/workflow-state.json > tmp.json && \
  mv tmp.json agent/epics/[EPIC-NAME]/workflow-state.json

echo "[$(date -Iseconds)] [warning] Step $CURRENT_STEP retry attempt $ATTEMPT: $ERROR_MSG" >> agent/epics/[EPIC-NAME]/workflow.log
```

### Workflow Completion

```bash
# Mark workflow complete
jq --arg timestamp "$(date -Iseconds)" '
  .status = "completed" |
  .completed_at = $timestamp |
  .last_updated = $timestamp' \
  agent/epics/[EPIC-NAME]/workflow-state.json > tmp.json && \
  mv tmp.json agent/epics/[EPIC-NAME]/workflow-state.json

# Archive state for history
cp agent/epics/[EPIC-NAME]/workflow-state.json agent/epics/[EPIC-NAME]/workflow-state.completed.json

echo "[$(date -Iseconds)] [success] Epic workflow completed successfully" >> agent/epics/[EPIC-NAME]/workflow.log
```

## Usage in Commands

### Planning Commands (plan.md, plan-to-tasks.md)

**Workflow Steps:**

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

### Execution Commands (execute.md, continue.md)

**Workflow Steps:**

1. Load Epic Configuration
2. Validate Task Dependencies
3. Deploy Task Orchestrator
4. Execute Tasks in Parallel
5. Monitor Agent Progress
6. Handle Task Completions
7. Deploy New Agents for Available Tasks
8. Validate Task Results
9. Update Task Status
10. Generate Execution Report

### Implementation Notes

1. **State Updates**: Update state immediately after each significant operation
2. **Atomic Operations**: Use temporary files and atomic moves for state updates
3. **Error Recovery**: Always log errors with sufficient context for debugging
4. **Progress Granularity**: Update progress for user-visible milestones
5. **Dashboard Compatibility**: Ensure state format matches dashboard expectations
6. **Continuation Support**: State must contain enough information to resume workflow

This standardized system ensures consistent progress reporting across all epic commands while providing rich integration with monitoring dashboards.
