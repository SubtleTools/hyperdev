Review Task Master tasks using multiple specialized agents for comprehensive analysis.

Arguments: $ARGUMENTS

## Multi-Agent Task Review

Orchestrate 6 specialized agents to review both task descriptions and existing code.

### 1. **Setup Phase**

Create temporary folder for agent assessments:

- Location: `.claude/temp/task-review/`
- Purpose: Store individual agent assessments
- Cleanup: After consolidation

### 2. **Task Distribution**

Split tasks between agent pairs:

- First half: Tasks 1 through N/2
- Second half: Tasks N/2+1 through N
- Each agent pair reviews the same tasks from their perspective

### 3. **Agent Deployment**

Launch 6 specialized agents in parallel:

**Architecture Reviewers (2 agents)**

- Agent 1: Review first half of tasks
- Agent 2: Review second half of tasks
- Focus: System design, patterns, architectural integrity

**Code Reviewers (2 agents)**

- Agent 1: Review first half of tasks
- Agent 2: Review second half of tasks
- Focus: Code quality, security, best practices

**API Architects (2 agents)**

- Agent 1: Review first half of tasks
- Agent 2: Review second half of tasks
- Focus: API design, endpoints, developer experience

### 4. **Assessment Storage**

Each agent saves assessment to:

```
.claude/temp/task-review/
├── architecture-reviewer-1.md
├── architecture-reviewer-2.md
├── code-reviewer-1.md
├── code-reviewer-2.md
├── api-architect-1.md
└── api-architect-2.md
```

### 5. **Consolidation Phase**

Multi-agent coordinator consolidates all assessments:

- Merge insights from all 6 agents
- Identify common concerns
- Prioritize recommendations
- Create unified report

### 6. **Task Updates**

Based on consolidated feedback:

- Update Task Master tasks 3 through last
- Incorporate architectural insights
- Apply security recommendations
- Refine API design considerations

### 7. **Execution Flow**

```yaml
Review Process:
──────────────
1. Create temp folder
2. Get all TM tasks
3. Split task list
4. Launch 6 agents (parallel)
5. Wait for assessments
6. Launch coordinator
7. Review & update tasks
8. Clean up temp folder
```

Result: Comprehensive multi-perspective task review and refinement.
