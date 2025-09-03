# Interactive Epic Planning Assistant

Build comprehensive PRDs through systematic analysis, validation, and guided questioning.

## Usage

```bash
# Interactive planning session
/epic:plan [EPIC-NAME]

# Examples
/epic:plan                           # Auto-generate epic name
/epic:plan user-authentication       # Specify epic name
/epic:plan api-redesign              # Technical epic
```

## Process Overview

This command conducts a structured planning session to produce a comprehensive PRD optimized for Claude's task generation capabilities.

---

## Phase 1: Project Assessment & Setup

### 1.1 Epic Initialization

**Parse Arguments:**

- If EPIC_NAME provided, use as working name
- Otherwise, generate working name from initial user input (e.g., "auth-system-validation")
- Create temporary workspace: `agent/tmp/[EPIC-WORKING-NAME]/`
- Initialize manifest: `agent/tmp/[EPIC-WORKING-NAME]/manifest.json`

**Initial Workspace Structure:**

```
agent/tmp/[EPIC-WORKING-NAME]/
├── manifest.json           # Artifact tracking and metadata
├── plan/                  # Planning documents
├── research/              # Research reports and findings
├── decisions/             # Important Technical Decisions (ITDs)
└── artifacts/             # Other generated content
```

**Manifest Structure (compatible with standard progress tracking):**

```json
{
  "epic": {
    "workingName": "[EPIC-WORKING-NAME]",
    "finalName": null,
    "status": "validation",
    "createdAt": "2025-01-16T14:30:00Z",
    "lastUpdated": "2025-01-16T14:30:00Z"
  },
  "artifacts": [
    {
      "id": "project-assessment",
      "path": "plan/project-assessment.md",
      "type": "analysis",
      "description": "Current project state and technical assessment",
      "phase": "assessment",
      "essential": true,
      "createdAt": "2025-01-16T14:30:00Z"
    }
  ],
  "phases": {
    "assessment": {
      "status": "in-progress",
      "startedAt": "2025-01-16T14:30:00Z"
    },
    "validation": { "status": "pending" },
    "requirements": { "status": "pending" },
    "generation": { "status": "pending" },
    "finalization": { "status": "pending" }
  },
  "decisions": [],
  "risks": [],
  "nextSteps": ["Complete project assessment", "Validate epic idea"]
}
```

### 1.2 Current Project Analysis

**Systematic Project Assessment:**

Execute comprehensive codebase analysis and save to `agent/tmp/[EPIC-WORKING-NAME]/plan/project-assessment.md`:

```markdown
# Project Assessment for [EPIC-WORKING-NAME]

## Codebase Analysis

- **Architecture**: [Current patterns, frameworks, structure]
- **Technology Stack**: [Languages, frameworks, tools, versions]
- **Database Design**: [Schema patterns, ORM, constraints]
- **API Patterns**: [REST structure, validation, error handling]
- **Frontend Architecture**: [Component patterns, state management, routing]
- **Testing Strategy**: [Coverage, frameworks, patterns]
- **Build & Deploy**: [CI/CD, environments, infrastructure]

## Recent Changes

- **Last 10 commits**: [Impact on proposed epic]
- **Active branches**: [Conflicting work, dependencies]
- **Open PRs**: [Related changes, integration points]

## Technical Debt & Constraints

- **Performance bottlenecks**: [Current issues]
- **Security considerations**: [Existing patterns, requirements]
- **Scalability limits**: [Current constraints]
- **Legacy code**: [Technical debt affecting epic]

## Resource Analysis

- **Existing libraries**: [What's already available]
- **Reusable components**: [What can be leveraged]
- **Integration points**: [External services, APIs]
- **Development patterns**: [Conventions to follow]
```

**Key Questions to Answer:**

1. What architectural patterns are already established?
2. What would conflict with or complement existing code?
3. What technical debt would this epic address or create?
4. What resources can be leveraged vs. built new?

---

## Phase 2: Idea Validation & Challenge

### 2.1 Devil's Advocate Analysis

**Critical Assessment Framework:**

Save analysis to `agent/tmp/[EPIC-WORKING-NAME]/plan/validation-analysis.md` and update manifest:

```markdown
# Epic Validation: [EPIC-WORKING-NAME]

## Idea Summary

[User's proposed epic in 2-3 sentences]

## Critical Analysis

### ❌ Potential Problems

1. **Technical Risks**: [Implementation challenges, complexity]
2. **Business Risks**: [ROI concerns, user adoption]
3. **Resource Risks**: [Time, complexity, dependencies]
4. **Integration Risks**: [Conflicts with existing systems]

### 🔄 Superior Alternatives

1. **Simpler Approach**: [Minimal viable solution]
2. **Different Technology**: [Better suited tools/patterns]
3. **Phased Implementation**: [Incremental delivery strategy]
4. **Buy vs. Build**: [Existing solutions to consider]

### ⚠️ Show-Stoppers

[Critical issues that should halt the project]

### ✅ Validation Result

- **Recommendation**: [Proceed/Modify/Stop]
- **Reasoning**: [Key factors in decision]
- **Required Changes**: [Modifications needed]
```

**Challenge Strategy:**

1. **Question assumptions**: Is this the right problem to solve?
2. **Identify simpler alternatives**: What's the minimal solution?
3. **Assess technical fit**: Does this align with current architecture?
4. **Evaluate ROI**: Is the complexity justified?
5. **Check timing**: Is this the right priority now?

**Escalation Protocol:**

- **Minor concerns**: Suggest modifications and continue
- **Major concerns**: Present alternatives, require user confirmation
- **Critical issues**: Strongly recommend stopping, require explicit override

---

## Phase 3: Systematic Requirements Gathering

### 3.1 Gap Analysis & Questioning

**Structured Question Framework:**

Execute systematic questioning and save to `agent/tmp/[EPIC-WORKING-NAME]/plan/requirements-session.md`:

```markdown
# Requirements Session: [EPIC-WORKING-NAME]

## User Problem Definition

**Q1**: What specific problem does this solve?
**A1**: [User response]

**Q2**: Who experiences this problem and how often?
**A2**: [User response]

**Q3**: What's the cost of not solving this?
**A3**: [User response]

## Solution Scope

**Q4**: What's the minimal viable solution?
**A4**: [User response]

**Q5**: What would "done" look like for users?
**A5**: [User response]

**Q6**: What's explicitly out of scope?
**A6**: [User response]

## Technical Requirements

**Q7**: What are the performance requirements?
**A7**: [User response]

**Q8**: What are the security/compliance needs?
**A8**: [User response]

**Q9**: What external integrations are required?
**A9**: [User response]

## Implementation Constraints

**Q10**: What's the timeline/deadline pressure?
**A10**: [User response]

**Q11**: What resources are available?
**A11**: [User response]

**Q12**: What can't change in existing systems?
**A12**: [User response]
```

**Dynamic Questioning Strategy:**

- **Follow unclear answers**: Ask for specific examples
- **Challenge vague requirements**: Demand measurable criteria
- **Probe assumptions**: Question "standard" or "usual" responses
- **Identify conflicts**: Highlight contradictory requirements
- **Test edge cases**: Ask about failure scenarios

### 3.2 Missing Information Detection

**Information Gap Analysis:**

1. **Functional gaps**: Unclear user workflows
2. **Technical gaps**: Undefined performance/security requirements
3. **Integration gaps**: Undefined external dependencies
4. **Business gaps**: Unclear success metrics

**Targeted Follow-up Questions:**

- When responses are vague: "Give me a specific example"
- When requirements conflict: "How do we prioritize X vs Y?"
- When scope is unclear: "What happens if we only build 50% of this?"
- When risks are ignored: "What's the worst case scenario?"

---

## Phase 4: PRD Construction

### 4.1 Adaptive PRD Generation

**PRD Structure (optimized for Claude task generation):**

**CRITICAL**: Once requirements are gathered, immediately proceed to PRD generation without further user interaction.

Generate `agent/tmp/[EPIC-WORKING-NAME]/plan/prd.md`:

```markdown
# [EPIC-WORKING-NAME] Product Requirements Document

## Executive Summary

**Problem**: [Clear problem statement]
**Solution**: [Proposed solution approach]
**Value**: [Expected business/user value]

## Requirements Analysis

### Functional Requirements

**Core Features**:

1. [Feature 1] - [User value] - [Acceptance criteria]
2. [Feature 2] - [User value] - [Acceptance criteria]
3. [Feature 3] - [User value] - [Acceptance criteria]

**User Workflows**:

1. [Primary workflow] - [Step-by-step process]
2. [Secondary workflow] - [Step-by-step process]

### Technical Requirements

**Performance**: [Specific measurable targets]
**Security**: [Authentication, authorization, data protection]
**Scalability**: [Load expectations, growth planning]
**Integration**: [External systems, APIs, data flows]

### Non-Functional Requirements

**Usability**: [User experience standards]
**Reliability**: [Uptime, error handling]
**Maintainability**: [Code quality, documentation]
**Compliance**: [Regulatory, legal requirements]

## Implementation Strategy

### Technical Architecture

**Components**: [System components and responsibilities]
**Data Model**: [Key entities and relationships]
**API Design**: [Endpoints, authentication, validation]
**Frontend**: [UI patterns, state management]

### Development Phases

**Phase 1 - Foundation**: [Core infrastructure, basic functionality]
**Phase 2 - Features**: [Primary features implementation]
**Phase 3 - Polish**: [Edge cases, optimization, testing]

### Dependencies & Risks

**Technical Dependencies**: [External libraries, services, infrastructure]
**Business Dependencies**: [Stakeholder decisions, approvals]
**Risk Mitigation**: [Identified risks and mitigation strategies]

## Success Criteria

**Measurable Outcomes**: [Specific metrics for success]
**Acceptance Criteria**: [Definition of done]
**Testing Strategy**: [How success will be validated]

## Implementation Notes

### For Task Generation

- Each phase should generate 5-8 concrete tasks
- Tasks should be implementation-focused, not planning
- Include testing and integration tasks for each feature
- Consider infrastructure and deployment tasks

### Technical Guidance

- Leverage existing [technology stack] patterns
- Follow established [architectural patterns]
- Integrate with [existing systems/services]
- Maintain [coding standards/conventions]
```

### 4.2 PRD Optimization for Task Generation

**Claude-Specific Optimizations:**

1. **Clear Implementation Phases**: Logical progression for task breakdown
2. **Concrete Acceptance Criteria**: Measurable outcomes for each feature
3. **Technical Context**: Sufficient detail for informed task generation
4. **Dependency Mapping**: Clear relationships between components
5. **Risk Awareness**: Known challenges to address in tasks

**Task Generation Hints:**

```markdown
## Task Generation Guidelines

### Recommended Task Categories

1. **Infrastructure Tasks**: [Database setup, API foundation, deployment]
2. **Core Feature Tasks**: [Primary functionality implementation]
3. **Integration Tasks**: [External systems, data flows]
4. **Testing Tasks**: [Unit, integration, E2E testing]
5. **Polish Tasks**: [Error handling, validation, optimization]

### Task Complexity Targets

- **Simple Tasks**: 1-2 days implementation
- **Medium Tasks**: 3-5 days implementation
- **Complex Tasks**: Should be broken into subtasks

### Critical Success Factors

- Each task should have clear acceptance criteria
- Tasks should build upon each other logically
- Include rollback/error scenarios
- Consider performance and security at each step
```

---

## Phase 5: Finalization & Handoff

### 5.1 Epic Name Confirmation

**Finalize Epic Name:**

- Review working name with user
- Confirm final epic name for production use
- Update manifest with final name
- Validate name doesn't conflict with existing epics

### 5.2 Artifact Organization & Research Integration

**Note**: When artifacts are moved to permanent location, ensure workflow state is also created following the standard format from `.claude/epic/progress-tracking.md` for seamless handoff to `plan-to-tasks` command.

**Additional Research & Decision Artifacts:**

During validation, create additional artifacts as needed:

```
agent/tmp/[EPIC-WORKING-NAME]/
├── research/
│   ├── technology-comparison.md    # Tech stack research
│   ├── competitor-analysis.md      # Market research
│   ├── performance-benchmarks.md  # Performance research
│   └── best-practices-study.md     # Industry standards
├── decisions/
│   ├── itd-001-architecture.md     # Important Technical Decision
│   ├── itd-002-database.md        # Database choice reasoning
│   └── itd-003-integration.md     # Integration approach
└── artifacts/
    ├── mockups/                    # UI mockups or sketches
    ├── diagrams/                   # Architecture diagrams
    └── prototypes/                 # Code prototypes
```

**Update Manifest for Each Artifact:**

```json
{
  "id": "tech-comparison",
  "path": "research/technology-comparison.md",
  "type": "research",
  "description": "Comparison of React vs Vue for frontend implementation",
  "phase": "validation",
  "essential": false,
  "tags": ["frontend", "technology-decision"],
  "createdAt": "2025-01-16T15:45:00Z",
  "relatedDecisions": ["itd-001-architecture"]
}
```

### 5.3 Move to Permanent Location

**Epic Creation Process:**

1. **Create permanent epic folder**: `agent/epics/[FINAL-EPIC-NAME]/`
2. **Copy essential artifacts** from temporary workspace
3. **Update all file references** to use final epic name
4. **Generate final manifest** for permanent location
5. **Clean up temporary workspace**: `rm -rf agent/tmp/[EPIC-WORKING-NAME]/`

**CRITICAL**: This move must happen immediately after PRD generation is complete - do not wait for user input.

**Progress Tracking Integration**: When moving to permanent location, create a workflow-state.json file using the standard schema from `.claude/epic/progress-tracking.md` to enable seamless handoff to the `plan-to-tasks` command:

```bash
# Create initial workflow state for plan-to-tasks handoff
echo '{
  "epic_name": "'$FINAL_EPIC_NAME'",
  "current_step": 0,
  "completed_steps": [],
  "workflow_config": {
    "no_stop": false,
    "max_subagents": 9,
    "use_research": null
  },
  "tag_name": null,
  "artifacts": {
    "original_doc": "original-spec.md",
    "prd": "prd.md"
  },
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
  "last_updated": "'$(date -Iseconds)'",
  "status": "ready-for-plan-to-tasks"
}' > agent/epics/$FINAL_EPIC_NAME/workflow-state.json
```

**Permanent Epic Structure:**

```
agent/epics/[FINAL-EPIC-NAME]/
├── manifest.json               # Final artifact manifest
├── original-spec.md           # Original user input/idea
├── prd.md                     # Final PRD for task generation
├── project-assessment.md      # Technical assessment
├── validation-analysis.md     # Validation and alternatives
├── requirements-session.md    # Requirements Q&A
├── research/                  # Research reports (if any)
│   └── *.md
├── decisions/                 # Important Technical Decisions
│   └── itd-*.md
└── artifacts/                 # Supporting materials
    ├── diagrams/
    ├── mockups/
    └── prototypes/
```

**Essential vs. Optional Artifacts:**

- **Essential** (always copy): PRD, assessments, validation, requirements
- **Optional** (copy if created): Research reports, ITDs, diagrams, prototypes
- **Temporary** (discard): Draft documents, working notes, intermediate files

### 5.4 Final Manifest Generation

**Permanent Manifest Structure:**

```json
{
  "epic": {
    "name": "[FINAL-EPIC-NAME]",
    "originalWorkingName": "[EPIC-WORKING-NAME]",
    "status": "ready-for-tasks",
    "createdAt": "2025-01-16T14:30:00Z",
    "finalizedAt": "2025-01-16T16:20:00Z",
    "planningSummary": {
      "problemStatement": "Brief problem description",
      "solutionApproach": "Brief solution summary",
      "keyDecisions": ["decision1", "decision2"],
      "risksMitigated": ["risk1", "risk2"]
    }
  },
  "artifacts": [
    {
      "id": "prd",
      "path": "prd.md",
      "type": "requirements",
      "description": "Final Product Requirements Document optimized for task generation",
      "essential": true,
      "readyForTaskGeneration": true,
      "createdAt": "2025-01-16T16:15:00Z"
    }
  ],
  "validation": {
    "criticalConcerns": "none",
    "alternativesConsidered": ["alternative1", "alternative2"],
    "userConfirmation": "explicit-approval",
    "risksAccepted": ["manageable-risk1"]
  },
  "nextSteps": {
    "command": "/epic:plan-to-tasks",
    "arguments": "[FINAL-EPIC-NAME] agent/epics/[FINAL-EPIC-NAME]/prd.md",
    "expectedOutcome": "18-25 tasks generated with proper dependencies"
  }
}
```

### 5.5 Handoff Instructions

**Ready for Task Generation:**

**CRITICAL**: Always end the planning session with these exact instructions:

````markdown
## ✅ Epic Planning Complete: [FINAL-EPIC-NAME]

### ⚠️ Context Management

**Check your context usage before proceeding**. Epic planning can consume significant context.

- If you have less than 30% context remaining, run `/clear` before the next command
- If unsure about context level, run `/clear` to be safe

### Next Command

```bash
/epic:plan-to-tasks [FINAL-EPIC-NAME] agent/epics/[FINAL-EPIC-NAME]/prd.md
```
````

### Planning Artifacts Created

- **📋 PRD**: Comprehensive requirements for task generation
- **🔍 Assessment**: Current project state and constraints
- **⚔️ Validation**: Critical analysis and alternatives considered
- **❓ Requirements**: Complete Q&A session with gap analysis
- **📚 Research**: [X research reports] on key technical decisions (if any)
- **⚡ ITDs**: [X decisions] documented with rationale

### Quality Gates Passed

✅ Problem clearly defined with measurable outcomes
✅ Technical approach validated against current architecture\
✅ Critical concerns addressed or explicitly accepted
✅ Requirements gaps identified and filled
✅ Implementation phases logically structured
✅ Risk mitigation strategies defined

### Epic Location

📁 `agent/epics/[FINAL-EPIC-NAME]/`

🎯 **The epic is ready for task generation with comprehensive planning context.**

**INTERNAL NOTE FOR AGENT**: Epic planning is now COMPLETE. Do not continue with task generation - that's handled by the separate `/epic:plan-to-tasks` command above. This message is for the agent's guidance only and should not be shown to the user.

```
**Planning Session Ends Here**: The agent must stop after providing these instructions and not proceed to task generation.

---

## Command Execution Strategy

### Interaction Pattern

**1. Assessment Phase (Non-interactive)**
- Analyze codebase automatically
- Generate project assessment
- Present findings to user

**2. Validation Phase (Interactive)**
- Present critical analysis
- Challenge user's approach
- Discuss alternatives
- Get user confirmation to proceed

**3. Requirements Phase (Interactive)**
- Ask systematic questions
- Follow up on vague answers
- Challenge assumptions
- Fill identified gaps

**4. Generation Phase (Fully Automated)**
- Build comprehensive PRD using all gathered information
- Finalize epic name
- Move artifacts to permanent location
- Clean up temporary workspace
- Provide handoff instructions

**5. STOP - Epic Planning Complete**
- Do not proceed to task generation
- Do not ask for additional input
- The planning workflow is complete

### Error Handling

**User Resistance to Questions:**
- Explain why information is critical
- Provide examples of poor outcomes without clarity
- Offer to proceed with noted risks

**Incomplete Information:**
- Document assumptions clearly
- Flag areas needing future clarification
- Provide fallback approaches

**Scope Creep During Session:**
- Acknowledge new requirements
- Assess impact on timeline/complexity
- Recommend separate epic if needed

### Quality Gates

**Before Proceeding to Each Phase:**
1. **Assessment**: Codebase analysis complete and threats identified
2. **Validation**: Critical concerns addressed or explicitly accepted
3. **Requirements**: Core questions answered with sufficient detail
4. **Generation**: All major gaps filled and conflicts resolved

This command optimizes for Claude's analytical strengths while ensuring comprehensive, actionable PRDs that generate high-quality tasks.
```
