# Continue Plan-to-Tasks Workflow

Resume an interrupted plan-to-tasks workflow from where it left off.

Arguments: `EPIC_FOLDER` (required) - Path to the epic folder (e.g., `agent/epics/user-auth-system`)

## Progress Tracking

This command follows the standard epic progress tracking system defined in `.claude/epic/progress-tracking.md` for continuation and state management.

## Continuation Process

### 1. State Validation

Load and validate workflow state:

```bash
# Read workflow-state.json
STATE_FILE="$EPIC_FOLDER/workflow-state.json"

# Verify state file exists
if [ ! -f "$STATE_FILE" ]; then
  echo "❌ No workflow state found. Cannot continue."
  exit 1
fi

# Load state and validate structure
```

### 2. Environment Setup

Restore workflow environment:

- Switch to saved TM tag
- Set workflow configuration (NO_STOP, MAX_SUBAGENTS)
- Verify artifacts exist

### 3. Agent Verification

If agents were created:

```bash
# Check for agents-created.txt
if [ -f "$EPIC_FOLDER/agents-created.txt" ]; then
  # Verify each agent exists in .claude/agents/
  # If missing, prompt to restart Claude Code
fi
```

### 4. Resume Execution

Continue from last successful step:

**Step Mapping:**

- Step 1-4: Pre-agent phase (shouldn't need continuation)
- Step 5: Agent creation - verify and continue
- Step 6: Research decision - make decision and continue
- Step 7: Parse PRD - execute with retry logic
- Step 8: Complexity analysis - run analysis
- Step 9: Multi-agent review - launch review

### 5. Progress Updates

Show clear status:

```
📍 Resuming Epic: [EPIC_NAME]
✅ Completed Steps: 1, 2, 3, 4
▶️  Continuing from: Step 5 - Agent Analysis
```

### 6. State Updates

After each step, follow standard progress tracking from `.claude/epic/progress-tracking.md`:

```bash
# Update progress state using standard format
jq --arg step "$STEP_NUMBER" --arg timestamp "$(date -Iseconds)" '
  .current_step = ($step | tonumber) | 
  .completed_steps += [($step | tonumber) - 1] | 
  .last_updated = $timestamp' \
  agent/epics/[EPIC-NAME]/workflow-state.json > tmp.json && \
  mv tmp.json agent/epics/[EPIC-NAME]/workflow-state.json

# Log progress update using standard format
echo "[$(date -Iseconds)] [success] Step $((STEP_NUMBER-1)) completed" >> agent/epics/[EPIC-NAME]/workflow.log
echo "[$(date -Iseconds)] [info] Continuing with step $STEP_NUMBER" >> agent/epics/[EPIC-NAME]/workflow.log
```

### 7. Completion

When all steps complete, follow standard completion process:

```bash
# Mark workflow complete using standard format
jq --arg timestamp "$(date -Iseconds)" '
  .status = "completed" |
  .completed_at = $timestamp |
  .last_updated = $timestamp' \
  agent/epics/[EPIC-NAME]/workflow-state.json > tmp.json && \
  mv tmp.json agent/epics/[EPIC-NAME]/workflow-state.json

# Archive state for history  
cp agent/epics/[EPIC-NAME]/workflow-state.json agent/epics/[EPIC-NAME]/workflow-state.completed.json

echo "[$(date -Iseconds)] [success] Plan-to-tasks workflow completed successfully" >> agent/epics/[EPIC-NAME]/workflow.log
```

- Generate final summary
- Display next steps for user

## Error Recovery

Handle continuation failures:

- **Missing artifacts**: Attempt to regenerate from available data
- **Tag conflicts**: Prompt to resolve or create new tag
- **Agent issues**: Guide through agent creation/restart
- **State corruption**: Offer to restart workflow

## Usage Example

```bash
# After creating agents and restarting Claude Code:
/project:tm/plan-to-tasks:continue agent/epics/user-auth-system

# Output:
📍 Resuming Epic: user-auth-system
✅ Completed: Document validation, Epic setup, Tag creation, PRD generation, Agent creation
▶️  Continuing from: Research Decision
🔍 Analyzing PRD for research requirements...
```

## Implementation Notes

1. **Idempotent Operations**: Steps should be safe to retry
2. **State Persistence**: Save after each major operation
3. **Clear Messaging**: User should understand what's happening
4. **Graceful Degradation**: Continue what's possible even with partial state
5. **Artifact Preservation**: Never overwrite existing artifacts without confirmation
