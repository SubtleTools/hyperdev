# Hypergen V8 Launch PRD

## Executive Summary

**Problem**: Hypergen V8 launch work was completed but ALL implementation was lost (not recoverable). Need to rebuild V8 foundation with new simplified taxonomy and mental model to support both standalone hypergen users and HyperDev integration.

**Solution**: Complete hypergen V8 foundation with new Recipe/Tool/CodeMod architecture: Recipe.yml system, cookbook composition, template discovery conventions, creator trust system, and HyperDev integration support.

**Value**: Establish hypergen as the foundation for both standalone code generation through Recipes and the HyperDev Hyper Coding methodology with a simplified, clear mental model.

## Requirements Analysis

### Mission Alignment Filter

Based on Hypergen Mission analysis, this recovery focuses ONLY on features that align with core mission:

**Core Mission**: Create tools for code generation that accelerate and standardize development for both developers and AI agents.

**Values**: Convention over Configuration, Keep Cognitive Burden Low

**Goals**: Make Recipes (code generation processes) easy to create, use, share, discover, and maintain with clear Tool-based architecture.

### Functional Requirements

#### Phase 1: Core Foundation (Months 1-2)

**1. Recipe.yml Configuration System**
- Rich variable type system (string, boolean, number, enum, array, object)
- Variable validation with patterns, ranges, and constraints  
- Recipe composition and inheritance
- Lifecycle hooks (pre/post generation)
- Step-based execution model with Tool integration

```yaml
# recipe.yml example
name: react-component
description: Create React components with TypeScript
version: 1.0.0

variables:
  name:
    type: string
    required: true
    pattern: ^[A-Z][a-zA-Z0-9]*$
  typescript:
    type: boolean
    default: true
  styling:
    type: enum
    values: [css-modules, styled-components]
    default: css-modules

steps:
  - name: Generate component file
    tool: template
    template: component.tsx.liquid
  - name: Add to index
    tool: codemod
    codemod: add-export
    when: "{{ typescript }}"
```

**2. Recipe Composition Engine** ([Architecture Analysis](./analysis/template-composability-architecture.md))
- Hierarchical recipe inheritance
- Conditional recipe inclusion via URL includes
- Cookbook-based recipe organization with remote recipe support
- Variable inheritance and mapping between recipes
- Support for GitHub gists, repositories, and npm packages as cookbook sources

**3. Three-Tool Architecture System**
- **Template Tool**: Process template files (EJS, Liquid, etc.) to generate code files
- **Action Tool**: Execute functions or shell commands with user authorization
- **CodeMod Tool**: Run AST-transforming functions to modify existing code
- Parameter validation and resolution for all tools
- Category-based organization and help system integration

**4. Cookbook Discovery Conventions** (from template discovery epic)
- NPM naming: `@hyper-kits/*`, `hypergen-*`, `@user/hypergen-*`
- GitHub topic: `hypergen-cookbook`
- Repository structure: `kit.yml` with nested recipe structure
- Recipe organization: folder nesting converts to CLI positional arguments

**5. Creator Trust System**
- Trust per creator/organization (not per template)
- `hypergen trust <creator>` command
- Explicit consent prompts for untrusted creators
- Transparent security model

**6. Enhanced CLI Commands**
```bash
hypergen recipe validate <recipe>         # Validate recipe configuration
hypergen cookbook list                     # List available cookbooks
hypergen discover                          # Find cookbooks from all sources
hypergen trust <creator>                   # Trust a cookbook creator
hypergen url resolve <url>                 # Resolve URL cookbooks
hypergen <cookbook> <recipe>               # Execute recipe from cookbook
```

**7. Taxonomy Refactoring & Migration**
- Complete refactoring of existing codebase to use new taxonomy consistently
- Migration tools to convert existing templates to new recipe format
- Backward compatibility layer during transition period (6 months minimum)
- Comprehensive documentation updates reflecting new mental model
- Community education materials and migration guides
- Consistent terminology enforcement across all interfaces

#### Phase 2: HyperDev Integration (Month 3)

**8. HyperDev Cookbook Creation**
- Complete Hyper Coding methodology recipes
- Moon monorepo setup with MVP tool stack recipes
- Claude Code hooks and validation script recipes
- Background daemon configuration recipes

**9. Go CLI Subprocess Integration**
- Consistent command interface for Go wrapper
- Predictable exit codes and error messages
- JSON output modes for programmatic use
- npm package distribution optimization

### Non-Functional Requirements

**Performance**: 
- Startup time <100ms for common operations
- Handle 1000+ recipes without degradation  
- Intelligent caching for remote cookbooks and recipes

**Security**: 
- Explicit trust mechanisms (no automatic execution)
- Secure recipe execution environment
- Transparent network requests with logging

**Usability**: 
- Convention over configuration (minimal required config)
- Progressive discovery (learn as you go)
- Clear error messages with actionable suggestions

**Compatibility**:
- Cross-platform (Windows, macOS, Linux)
- Backward compatibility during transition
- NPM ecosystem integration

## Out of Scope (Mission Misaligned)

**Explicitly NOT Including**:
- ❌ Action Pipelines & Complex Workflows (contradicts "not enterprise workflows")
- ❌ Cross-Action Communication (adds complexity)
- ❌ Plugin System (cognitive burden for core users)
- ❌ Template Registry/Marketplace (explicit non-goal)
- ❌ Template Ecosystem Scoring (marketplace functionality)
- ❌ Enterprise Features (explicit non-goal)
- ❌ VS Code Extension (contradicts "not an IDE")

## Implementation Strategy

### Mental Model Foundation
The V8 implementation adopts a simplified taxonomy:
- **Templates**: Template files (EJS, Liquid, etc.) processed by the Template Tool
- **Actions**: Commands or function calls executed by the Action Tool (require user authorization)
- **CodeMods**: AST-transforming functions executed by the CodeMod Tool
- **Recipes**: Process definitions that achieve specific goals through sequential steps
- **Tools**: Built-in capabilities (Template, Action, CodeMod) that execute recipe steps
- **Cookbooks**: Collections of related recipes focused on specific tools or scenarios
- **Kits**: Shareable bundles containing cookbooks, distributed via NPM or Git

This clear taxonomy ([Analysis](./analysis/mental-model-decisions.md)) eliminates confusion between files and processes while maintaining powerful composition capabilities.

### Technical Architecture

**Core Components**:
- Enhanced `RecipeParser` with recipe.yml support
- `RecipeComposition` engine for inheritance/inclusion
- `CreatorTrust` system for security
- `DiscoveryConventions` for NPM/GitHub cookbook identification
- `ToolSystem` with Template/Action/CodeMod tools
- `CLI` commands for all functionality

**Integration Points**:
- Recipe composition leverages URL resolution
- Discovery uses existing caching systems
- Trust system integrates with recipe execution
- All tools use enhanced variable validation
- Step execution coordinates between multiple tools

### Development Phases

**Phase 1: Foundation Recovery (Months 1-2)**
1. Recipe.yml configuration system
2. Variable validation and typing  
3. Recipe composition engine
4. Three-tool system (Template/Action/CodeMod)
5. Discovery conventions implementation
6. Creator trust system
7. Enhanced CLI commands

**Phase 2: HyperDev Integration (Month 3)**
1. HyperDev methodology cookbook creation
2. Go CLI subprocess interface optimization
3. JSON output modes
4. npm distribution finalization

### Dependencies & Risks

**Technical Dependencies**:
- Existing hypergen codebase foundation
- NPM Registry API for discovery
- GitHub API for repository discovery
- Cookbook discovery epic conventions

**Risk Mitigation**:
- Focus on mission-aligned features only (avoid scope creep)
- Maintain backward compatibility where possible
- Comprehensive testing of all new functionality
- Clear migration path from current system

## Success Criteria

### Measurable Outcomes

**Functionality**:
- Recipe.yml configuration system fully operational
- Recipe composition working with inheritance/inclusion
- All planned CLI commands functional
- Creator trust system preventing unauthorized execution
- Discovery working for both NPM and GitHub cookbooks

**Performance**:
- Startup time maintained <100ms
- Recipe resolution <500ms cached, <2s uncached
- Memory usage optimized for large cookbook sets

**Integration**:
- HyperDev cookbook creates complete Hyper Coding setup
- Go CLI can successfully call hypergen as subprocess
- npm distribution works seamlessly

### Acceptance Criteria

**Developer Experience**:
- Recipe creators can define rich variable types with validation
- Recipe composition eliminates code duplication
- Discovery finds cookbooks without manual configuration
- Trust system provides security without friction
- Error messages guide users to solutions

**HyperDev Support**:
- Single command creates complete Hyper Coding project
- Recipe composition supports tool stack assembly
- Integration with Go CLI is transparent to users

### Testing Strategy

**Coverage Requirements**:
- 95%+ test coverage for all new features
- Integration tests with real NPM packages and GitHub repositories
- Security testing for trust system and recipe execution
- Performance benchmarking for all operations
- Cross-platform compatibility testing

## Implementation Notes

### Task Categories

1. **Recipe.yml System**: Configuration parser, variable validation, composition
2. **Discovery Integration**: NPM conventions, GitHub topic search, trust system
3. **Tool System**: Template/Action/CodeMod implementation, parameter validation, CLI integration
4. **HyperDev Cookbooks**: Methodology cookbook creation, tool stack composition
5. **CLI Enhancement**: Command implementation, help system, error handling
6. **Testing & Documentation**: Comprehensive test coverage, migration guides
7. **Taxonomy Migration**: Comprehensive refactoring from Template→Recipe mental model
   - Rename core classes: TemplateParser → RecipeParser, TemplateStore → CookbookStore
   - Update all internal interfaces and type definitions
   - Refactor CLI commands and help text
   - Create migration tools for existing templates
   - Update error messages and logging
   - Comprehensive documentation updates

### Critical Success Factors

- **Mission Alignment**: Every feature must pass hypergen mission filter
- **Simplicity**: Convention over configuration, minimal cognitive burden
- **Trust & Security**: Explicit consent, transparent operations
- **HyperDev Integration**: Support both standalone and methodology use
- **Clear Taxonomy**: Maintain consistent Recipe/Tool/CodeMod terminology throughout
- **Quality**: Comprehensive testing, clear documentation

This PRD focuses exclusively on mission-aligned features with the new simplified taxonomy that serves both standalone hypergen users and HyperDev methodology integration, avoiding the complexity that led to previous scope creep.