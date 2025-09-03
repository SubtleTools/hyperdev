# Hypergen V8 Launch - Original Specification

## Context & Recovery Situation

**Critical Issue**: The v8-launch epic was previously completed but ALL implementation work was lost and is not recoverable. This represents a complete rebuild focused on mission-aligned features only.

**Previous Scope Creep Issue**: Original v8 implementation included features that violate hypergen's explicit mission constraints:
- Complex enterprise workflows (explicit non-goal)
- Plugin systems adding cognitive burden
- Marketplace functionality (contradicts "leverage existing ecosystems")

**Recovery Strategy**: Rebuild with strict mission alignment filter based on hypergen MISSION.md analysis.

## Mission Alignment Analysis

### Hypergen Core Mission
"Create tools for code generation that accelerate and standardize development for both developers and AI agents."

### Key Values
- **Convention over Configuration**: Lots of options, require almost none
- **Keep Cognitive Burden Low**: Progressive discovery, "easy to use" > "does everything"

### Five Goals Framework
1. **Creating templates must be easy**
2. **Using templates must be easy**
3. **Sharing templates must be easy** 
4. **Discovering templates must be easy**
5. **Maintaining templates must be easy**

### Explicit Non-Goals (What NOT to build)
- Complex enterprise workflows
- Visual/GUI template editors  
- Template marketplace (leverage npm/GitHub instead)
- Language-specific features
- AI code generation

## Recovery Requirements

### Must Include (Mission-Aligned)

**Template.yml Configuration System** ✅
- Supports Goal 1 (easy creation) and Goal 5 (easy maintenance)
- Convention over configuration approach
- Rich variable types reduce manual work

**Template Composition Engine** ✅
- Supports Goal 3 (easy sharing) and Goal 5 (easy maintenance)
- Enables code reuse without duplication
- Hierarchical inheritance with conflict resolution

**Template Discovery Conventions** ✅ (from discovery epic)
- Supports Goal 4 (easy discovery)
- NPM naming: `hypergen-*`, `@user/hypergen-*`
- GitHub topic: `hypergen-template`
- Eliminates confusion from 4+ current methods

**Creator Trust System** ✅
- Supports mission constraint: "explicit trust mechanisms"
- Transparent security without friction
- Per-creator trust (not per-template) reduces cognitive burden

**Action System with Decorators** ✅
- Supports Goal 1 (easy creation)
- Modern TypeScript approach
- Self-documenting with metadata

**Enhanced CLI Commands** ✅
- Supports Goal 2 (easy to use)
- REST-like command structure
- Comprehensive help system

### Must Exclude (Mission-Violating)

**Action Pipelines & Complex Workflows** ❌
- Violates "not complex enterprise workflows" 
- Adds cognitive burden
- Contradicts "easy to use > does everything"

**Cross-Action Communication** ❌
- Unnecessary complexity for core use cases
- Violates cognitive burden principle
- Enterprise workflow territory

**Plugin System** ❌
- While extensible, adds cognitive burden
- Core users shouldn't need plugin concepts
- Violates progressive discovery

**Template Registry/Marketplace** ❌
- Explicit non-goal: "not template marketplace"
- Mission states: "leverage existing ecosystems (npm, GitHub)"
- Would require marketplace maintenance

**Enterprise Features** ❌
- Explicit non-goal: "not complex enterprise workflows"
- Keep focus on "individual developers and small teams"

### HyperDev Integration Requirements

**New Context**: hypergen must now support HyperDev Hyper Coding methodology

**Required Capabilities**:
- **Template Composition**: Assemble tool stacks (ESLint + Prettier + TypeScript + etc.)
- **Go CLI Integration**: Clean subprocess interface for `hyper gen` command
- **NPM Distribution**: Optimize for `@hyperdev/hypergen` distribution model
- **HyperDev Templates**: Complete Hyper Coding methodology template

## Technical Approach

### Recovery Architecture

**Foundation Components**:
1. **TemplateParser**: Enhanced template.yml configuration
2. **TemplateComposition**: Inheritance and conditional inclusion  
3. **DiscoveryConventions**: NPM/GitHub standardized identification
4. **CreatorTrust**: Security without complexity
5. **ActionSystem**: Decorator-based modern approach
6. **CLI**: Complete command structure

**Integration Strategy**:
- Build on existing hypergen codebase where possible
- Leverage template discovery epic conventions
- Support both standalone and HyperDev use cases
- Maintain <100ms startup time

### Development Phases

**Phase 1: Core Foundation Recovery** (Months 1-2)
- Template.yml configuration system
- Template composition with inheritance
- Discovery conventions (NPM + GitHub)
- Creator trust system
- Action decorators
- Enhanced CLI commands

**Phase 2: HyperDev Integration** (Month 3)  
- HyperDev methodology template
- Go CLI subprocess optimization
- JSON output modes
- npm distribution finalization

## Success Criteria

**Must Demonstrate**:
- All 5 mission goals supported by implemented features
- No features violating explicit non-goals
- HyperDev template creates complete Hyper Coding setup
- Template composition enables tool stack assembly
- Discovery works seamlessly for NPM and GitHub
- Creator trust prevents unauthorized execution
- Performance maintained (<100ms startup, <500ms cached resolution)

**Quality Gates**:
- 95%+ test coverage for all features
- Cross-platform compatibility (Windows, macOS, Linux)
- Backward compatibility during transition
- Comprehensive documentation
- Clear migration path from current system

## Risk Mitigation

**Scope Creep Prevention**:
- Every feature must pass explicit mission alignment check
- Regular review against hypergen MISSION.md
- Reject features that add cognitive burden
- Focus on "easy to use" over "does everything"

**Technical Risks**:
- Lost implementation knowledge: Comprehensive documentation required
- Integration complexity: Start with simple HyperDev integration
- Performance regression: Continuous benchmarking
- Breaking changes: Maintain backward compatibility where possible

**Business Risks**:
- Community confusion: Clear communication about recovery
- Template ecosystem fragmentation: Smooth migration path
- HyperDev dependency: Ensure standalone value remains

This recovery specification ensures hypergen V8 serves its core mission while supporting the HyperDev ecosystem without scope creep that led to previous issues.