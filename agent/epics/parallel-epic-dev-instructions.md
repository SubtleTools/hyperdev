# HyperDev Parallel Development Instructions

## Overview

These instructions guide each Claude Code agent through implementing their assigned epic using git worktrees for isolated parallel development. Each epic will be developed in its own worktree with a dedicated branch.

## Pre-Implementation Setup

### Step 1: Create Git Worktree and Branch

**Create worktree outside the main repository** (recommended approach):

```bash
# Navigate to parent directory of hyperdev
cd /work/hyperdev-epics

# Create worktree directory for your epic
# Replace [EPIC-NAME] with your specific epic name:
# - hypergent-v8 (already exists - skip worktree creation)  
# - go-cli
# - hyperdev-templates
# - background-daemon
# - claude-integration
# - documentation-migration

git worktree add [EPIC-NAME] -b epic/[EPIC-NAME]
cd [EPIC-NAME]
```

**Example for Go CLI Development epic**:
```bash
cd /work/hyperdev-epics
git worktree add go-cli -b epic/go-cli
cd go-cli
```

### Step 2: Verify Project Structure

Confirm the new package structure:
```
hyperdev/packages/
├── @hypergen/          # Templates and packs
│   ├── monorepo/
│   └── starlight/
├── hypergen/           # The hypergen engine and CLI
└── moon-launch/        # Legacy templates (reference only)
```

### Step 3: Start Epic Implementation

Navigate to your epic folder and begin task generation:

```bash
# Navigate to your epic
cd agent/epics/[EPIC-NAME]

# Generate tasks from your PRD
/epic:plan-to-tasks [EPIC-NAME] prd.md

# If the plan-to-tasks process was interrupted and you need to continue:
/epic:plan-to-tasks:continue agent/epics/[EPIC-NAME]
```

## Development Workflow

### Task Execution Strategy

Use the epic execution system for maximum parallel efficiency:

```bash
# Execute all available tasks with maximum parallelization
/epic:execute agent/epics/[EPIC-NAME]

# For specific task execution:
/epic:execute agent/epics/[EPIC-NAME] [TASK_ID]

# For interactive task selection:
/epic:execute agent/epics/[EPIC-NAME] interactive
```

### Commit Guidelines

Follow **Conventional Commits** specification with small, semantic commits:

**Commit Message Format**:
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix  
- `docs`: Documentation changes
- `style`: Formatting changes
- `refactor`: Code restructuring
- `test`: Adding or modifying tests
- `chore`: Maintenance tasks
- `perf`: Performance improvements

**Examples**:
```bash
git commit -m "feat(templates): add template.yml configuration system"
git commit -m "fix(cli): handle missing hypergen installation gracefully"  
git commit -m "docs(api): add TypeScript interface documentation"
git commit -m "test(daemon): add file watching integration tests"
git commit -m "refactor(hooks): extract validation logic to shared module"
```

**Small Commit Strategy**:
- Commit frequently (every 30-60 minutes of work)
- Each commit should represent one logical change
- Keep commits focused and atomic
- Write descriptive commit messages that explain the "why"

## Epic-Specific Instructions

### Epic 1: Hypergent V8 (Already Exists)

**Epic Location**: `agent/epics/hypergent-v8/`
**Status**: Ready for execution - tasks already generated
**Agents**: `template-engine-specialist`, `typescript-expert`, `npm-package-specialist`, `architecture-reviewer`

**Special Instructions**:
- This epic already has tasks generated
- Focus on completing V8 foundation features
- Use existing analysis documents in `analysis/` folder for context
- Priority: Complete template composition system first (other epics depend on this)

**Start Command**:
```bash
# Already in main hyperdev repository - no worktree needed
/epic:execute agent/epics/hypergent-v8
```

### Epic 2: Go CLI Development

**Epic Location**: `agent/epics/go-cli/`
**Agents**: `go-systems-expert`, `cli-development-expert`, `cross-platform-testing-expert`
**Dependencies**: Basic hypergen functionality from Epic 1 (30% completion needed)

**Key Focus Areas**:
- Beautiful terminal UX with Charmbracelet libraries
- Seamless npm integration and auto-installation  
- Robust subprocess communication with hypergen
- Cross-platform compatibility (Windows, macOS, Linux)

**Success Criteria**:
- `hyper gen <template>` works seamlessly
- Auto-installation prompts are clear and non-intrusive
- Error handling provides actionable feedback
- Performance <100ms startup, <200ms subprocess overhead

### Epic 3: HyperDev Templates & Methodology

**Epic Location**: `agent/epics/hyperdev-templates/`
**Agents**: `template-engine-specialist`, `dx-optimizer`, `typescript-expert`
**Dependencies**: Hypergen V8 template composition (50%), Go CLI (30%)

**Key Focus Areas**:
- Complete MVP tool stack integration (ESLint, TypeScript, Vitest, security tools)
- Moon monorepo configuration and task orchestration
- Claude Code hooks and validation scripts
- Template variants for different project types

**Success Criteria**:
- Single command creates working Hyper Coding project
- All quality gates function immediately after generation
- Templates support multiple project types
- Generated projects pass all validations without setup

### Epic 4: Background Daemon

**Epic Location**: `agent/epics/background-daemon/`  
**Agents**: `go-systems-expert`, `architecture-reviewer`, `cross-platform-testing-expert`
**Dependencies**: Hypergen V8 (80%), Go CLI (50%)

**Key Focus Areas**:
- Efficient file watching with incremental analysis
- HTTP API for <100ms hook responses
- Pre-computed validation cache management
- Robust process lifecycle management

**Success Criteria**:
- Daemon startup <5 seconds for typical projects
- Hook responses consistently <100ms
- Memory usage stable <100MB
- Graceful handling of all error scenarios

### Epic 5: Claude Code Integration & Hooks

**Epic Location**: `agent/epics/claude-integration/`
**Agents**: `prompt-engineer`, `dx-optimizer`, `template-engine-specialist`  
**Dependencies**: HyperDev Templates (60%), Background Daemon (optional)

**Key Focus Areas**:
- Comprehensive hook script library
- Custom Claude commands for methodology management
- Enhanced CLAUDE.md template generation
- Cross-platform shell script compatibility

**Success Criteria**:
- Hooks provide instant feedback without interrupting development
- Custom commands enhance workflow efficiency
- Cross-platform compatibility without configuration
- Clear, actionable error messages

### Epic 6: Documentation & Migration

**Epic Location**: `agent/epics/documentation-migration/`
**Agents**: `technical-documentation-specialist`, `dx-optimizer`, `npm-package-specialist`
**Dependencies**: All other epics (80% completion for comprehensive documentation)

**Key Focus Areas**:
- Complete API documentation with interactive examples
- Migration tooling for frontmatter → template.yml conversion
- Comprehensive user guides and troubleshooting
- Documentation site with search and navigation

**Success Criteria**:
- 100% API documentation coverage
- Migration tools handle all edge cases
- New user onboarding <15 minutes
- Zero unresolved documentation gaps

## Integration & Communication

### Cross-Epic Dependencies

**Critical Coordination Points**:

1. **Epic 1 → All Others**: Core hypergen functionality needed by everyone
2. **Epic 2 + Epic 3 → Epic 5**: CLI and templates needed for hook development  
3. **Epic 4 → Epic 5**: Daemon enhances hook performance (optional)
4. **All → Epic 6**: Stable features needed for accurate documentation

**Communication Protocol**:
- Use descriptive commit messages to communicate progress
- Tag integration points in commit messages: `feat(api): add JSON mode for cli integration`
- Create integration branch when ready: `integration/epic-[NAME]-ready`

### Testing Integration Points

Test integration between epics:

```bash
# Test Go CLI with hypergen
./hyper gen test-template

# Test templates with quality gates  
moon run :lint :test :security

# Test hooks with daemon integration
curl localhost:8080/api/v1/validation/typescript

# Test documentation with actual APIs
npm run docs:dev
```

## Final Steps: Pull Request Creation

### Before Creating PR

1. **Run Full Validation**:
```bash
# Run all quality checks
moon check --all

# Verify integration tests pass
moon run :test:integration

# Check commit message compliance
git log --oneline -10
```

2. **Verify Epic Completion**:
```bash
# Check all tasks completed
/epic:execute agent/epics/[EPIC-NAME] 

# Verify success criteria met (see epic-specific sections above)
```

### Create Pull Request

```bash
# Push your branch
git push origin epic/[EPIC-NAME]

# Create PR using GitHub CLI
gh pr create \
  --title "feat: implement [EPIC-NAME] - [brief description]" \
  --body "$(cat <<'EOF'
## Epic: [EPIC-NAME]

### Summary
- [bullet point summary of key features]
- [integration points completed]
- [success criteria achieved]

### Changes
- [major changes overview]
- [new files/packages added]
- [configuration changes]

### Testing
- [x] All epic tasks completed successfully
- [x] Integration tests passing
- [x] Cross-platform compatibility verified
- [x] Success criteria validated

### Dependencies
- Depends on: [other epic names if applicable]
- Enables: [which epics can now proceed]

### Integration Notes
- [any special integration considerations]
- [breaking changes if any]
- [migration notes if applicable]
EOF
)"
```

### Post-PR Actions

1. **Clean Up Worktree** (after PR merged):
```bash
cd /work/hyperdev
git worktree remove /work/hyperdev-epics/[EPIC-NAME]
git branch -d epic/[EPIC-NAME]
```

2. **Update Documentation**:
- Update relevant CLAUDE.md sections
- Update MISSION.md success metrics if achieved
- Update any architectural documentation

## Troubleshooting

### Common Issues

**Worktree Creation Fails**:
```bash
# If branch already exists
git worktree add hyperdev-epics/[EPIC-NAME] epic/[EPIC-NAME]

# If you need to reset
git worktree remove hyperdev-epics/[EPIC-NAME]  
git branch -D epic/[EPIC-NAME]
```

**Epic Commands Not Working**:
- Verify you're in the correct directory
- Check epic folder exists: `ls agent/epics/[EPIC-NAME]/`
- Verify PRD exists: `ls agent/epics/[EPIC-NAME]/prd.md`

**Task Generation Failures**:
- Ensure all required agents exist in `.claude/agents/`
- Check PRD format follows template structure
- Try continuation command: `/epic:plan-to-tasks:continue agent/epics/[EPIC-NAME]`

**Integration Issues**:
- Check dependency completion status in other epics
- Verify API contracts match between dependent epics
- Test integration points after major changes

## Success Metrics

Track these metrics throughout development:

**Individual Epic Success**:
- All tasks completed successfully
- Success criteria achieved (see epic-specific sections)
- Integration tests passing
- Documentation complete

**Cross-Epic Success**:  
- API contracts maintained
- Integration points working
- No blocking dependencies remain
- Quality gates passing across all epics

**Overall Project Success**:
- Mission goals advanced (see MISSION.md)
- Quality metrics improved
- Development methodology proven
- Community adoption enabled

---

## Quick Reference

**Your Epic**: [Insert your specific epic name here]
**Your Worktree**: `/work/hyperdev-epics/[EPIC-NAME]`
**Your Branch**: `epic/[EPIC-NAME]`
**Your Agents**: [Insert specific agents for your epic]
**Your PRD**: `agent/epics/[EPIC-NAME]/prd.md`

**Start Command**: `/epic:plan-to-tasks [EPIC-NAME] agent/epics/[EPIC-NAME]/prd.md`
**Execute Command**: `/epic:execute agent/epics/[EPIC-NAME]`

Remember: Small commits, clear messages, focus on your epic's success criteria, and communicate integration needs through descriptive commit messages!