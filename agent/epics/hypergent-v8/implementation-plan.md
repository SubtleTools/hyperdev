# Hypergen V8 Launch - Implementation Plan

## Recovery Implementation Strategy

**Context**: All V8 launch work was completed but lost. This plan rebuilds with new Recipe/Tool/CodeMod taxonomy and strict mission alignment, filtering out scope creep that led to previous issues.

**Mission Filter Applied**: Every feature validated against hypergen MISSION.md to prevent complex enterprise workflows, marketplace functionality, and cognitive burden increases. New taxonomy clarifies mental model.

## Phase 1: Core Foundation Recovery (Months 1-2)

### 1.1 Recipe.yml Configuration System

**Goal**: Implement new Recipe.yml system with rich configuration, replacing the template/generator confusion with clear Recipe/Tool architecture

**Technical Implementation**:
- Create new `src/config/recipe-parser.ts` with YAML parsing
- Implement variable type system (string, boolean, number, enum, array, object)
- Add validation patterns, constraints, and ranges
- Create recipe composition inheritance engine
- Build lifecycle hooks with step-based execution model
- Implement Tool coordination (Template/Action/CodeMod)

**Key Components**:
```typescript
// New RecipeConfig interface
interface RecipeConfig {
  name: string;
  description: string;
  version: string;
  variables: Record<string, VariableDefinition>;
  steps: StepDefinition[];
  composition?: CompositionConfig;
  hooks?: LifecycleHooks;
}

interface StepDefinition {
  name: string;
  tool: 'template' | 'action' | 'codemod';
  template?: string;    // for Template Tool
  action?: string;      // for Action Tool
  codemod?: string;     // for CodeMod Tool
  when?: string;        // conditional execution
  variables?: Record<string, any>;
}

interface VariableDefinition {
  type: 'string' | 'boolean' | 'number' | 'enum' | 'array' | 'object';
  required?: boolean;
  default?: any;
  pattern?: string;
  values?: any[];
  validation?: ValidationRule[];
}
```

**Success Criteria**:
- Recipe.yml parser handles all variable types with validation
- Step-based execution coordinates Template/Action/CodeMod tools
- Composition system supports inheritance and conditional inclusion
- Clear separation: Recipe.yml for process definition, template files as assets
- Tool system provides consistent interface for all operations
- Performance: <100ms recipe parsing

### 1.2 Recipe Composition Engine ([Detailed Architecture](./analysis/template-composability-architecture.md))

**Goal**: Enable recipe reuse and hierarchical inheritance through URL-based composition with cookbook organization

**Technical Implementation**:
- Build composition resolver that processes URL-based recipe includes
- Implement cookbook-based recipe organization with remote recipe inclusion
- Support GitHub gists, repositories, and npm packages as cookbook sources
- Add variable mapping and passing between parent and included recipes
- Create recipe resolver with caching for remote cookbooks

**Architecture**:
```typescript
class RecipeCompositionEngine {
  async resolveComposition(
    recipeConfig: RecipeConfig,
    context: GenerationContext
  ): Promise<ComposedRecipe>
  
  private resolveInheritance(recipes: RecipeConfig[]): RecipeConfig
  private evaluateConditions(includes: ConditionalInclude[], vars: Variables): RecipeConfig[]
  private mergeVariables(recipes: RecipeConfig[]): Variables
  private mergeSteps(recipes: RecipeConfig[]): StepDefinition[]
}
```

**Success Criteria**:
- Recipes can inherit from base recipes with override capabilities
- Conditional inclusion works based on variable evaluation
- Circular dependency detection prevents infinite loops
- Composition performance: <200ms for complex hierarchies
- Clear error messages for composition conflicts
- Step merging maintains execution order

### 1.3 Cookbook Discovery Integration

**Goal**: Implement conventions from cookbook discovery epic

**Technical Implementation**:
- NPM cookbook identification: `@hyper-kits/*`, `hypergen-*`, `@user/hypergen-*`
- GitHub repository discovery via `hypergen-cookbook` topic
- Repository structure validation (kit.yml with nested recipe structure)
- Creator trust system with per-user/organization scope
- Secure cookbook resolution with explicit consent

**Components**:
```typescript
class CookbookDiscovery {
  async discoverNpmCookbooks(searchTerm?: string): Promise<NpmCookbook[]>
  async discoverGitHubCookbooks(searchTerm?: string): Promise<GitHubCookbook[]>
  async validateRepositoryStructure(repo: Repository): Promise<boolean>
  async validateKitStructure(kit: Kit): Promise<boolean>
}

class CreatorTrustSystem {
  async trustCreator(creator: string): Promise<void>
  async isTrusted(creator: string): Promise<boolean>
  async promptForTrust(creator: string, cookbook: string): Promise<boolean>
}
```

**Success Criteria**:
- Discovery finds cookbooks across NPM and GitHub using conventions
- Trust system prevents unauthorized execution while remaining frictionless
- Repository structure validation ensures consistent cookbook/kit format
- Search performance: <2s for uncached, <500ms for cached
- Clear prompts for trust decisions

### 1.4 Three-Tool System Implementation

**Goal**: Implement Template/Action/CodeMod tools with unified interface

**Technical Implementation**:
- Implement Template Tool for processing template files (EJS, Liquid)
- Implement Action Tool for executing functions/commands with user authorization
- Implement CodeMod Tool for AST transformations of existing code
- Create unified Tool interface with parameter validation
- Add category-based tool organization
- Integrate with help system and CLI commands

**Tool System**:
```typescript
interface Tool {
  execute(step: StepDefinition, context: ExecutionContext): Promise<ToolResult>;
  validate(step: StepDefinition): ValidationResult;
  getDescription(): ToolDescription;
}

class TemplateTool implements Tool {
  async execute(step: StepDefinition, context: ExecutionContext): Promise<ToolResult> {
    // Process template file using template engine
  }
}

class ActionTool implements Tool {
  async execute(step: StepDefinition, context: ExecutionContext): Promise<ToolResult> {
    // Execute function or command with user authorization
  }
}

class CodeModTool implements Tool {
  async execute(step: StepDefinition, context: ExecutionContext): Promise<ToolResult> {
    // Apply AST transformation to existing file
  }
}
```

**Success Criteria**:
- All tools use consistent interface pattern
- Parameter validation prevents runtime errors
- Help system auto-generates from tool metadata
- Category organization improves discoverability
- Tool performance: <50ms per tool execution
- Clear separation: Templates are assets, Tools are capabilities

### 1.5 LiquidJS Template Engine Integration ([Implementation Strategy](./analysis/liquidjs-implementation-strategy.md))

**Goal**: Integrate LiquidJS as primary template engine with plugin architecture

**Technical Implementation**:
- Create template engine abstraction with plugin system
- Implement LiquidJS engine with custom filters and helpers
- Maintain EJS backward compatibility
- Add automatic engine detection based on file extensions
- Build plugin discovery system for community extensions

**Key Benefits**:
- 4x performance improvement through streaming rendering
- Enhanced security with no eval() usage
- Rich filter system with case transformations and inflection
- Template inheritance and includes support
- Better error handling with line numbers and context

**Success Criteria**:
- LiquidJS templates render with 4x performance improvement
- EJS templates continue working without modification
- Plugin system discovers and loads template engine extensions
- Custom filters provide all existing hypergen helper functionality
- Error messages include line numbers and helpful context

### 1.6 Enhanced CLI Commands

**Goal**: Complete planned CLI command structure with Recipe/Cookbook terminology

**Technical Implementation**:
- Implement all planned commands with comprehensive help
- Add template validation and listing commands
- Create system status and URL resolution commands
- Build error handling with actionable suggestions
- Integrate with composition and discovery systems

**Command Structure**:
```bash
hypergen recipe validate <recipe>         # Validate recipe configuration
hypergen cookbook list [directory]        # List available cookbooks
hypergen discover [search-term]           # Find cookbooks from all sources
hypergen trust <creator>                  # Trust cookbook creator
hypergen url resolve <url>                # Resolve and cache URL cookbooks
hypergen system status                     # Show system configuration
hypergen <cookbook> <recipe>              # Execute recipe from cookbook
```

**Success Criteria**:
- All commands functional with comprehensive help text
- Error messages provide clear guidance for resolution
- Command performance: <100ms for status operations
- Integration with recipe validation system
- Consistent output formatting
- Clear Recipe/Cookbook terminology throughout

## Phase 2: HyperDev Integration (Month 3)

### 2.1 HyperDev Cookbook Creation

**Goal**: Create comprehensive Hyper Coding methodology cookbook

**Technical Implementation**:
- Design recipe.yml for complete tool stack setup
- Implement Moon monorepo configuration recipes with quality gates
- Add Claude Code hooks and validation script recipes
- Create background daemon configuration recipes
- Build tool composition system using multiple recipes (ESLint + Prettier + TypeScript)

**Cookbook Structure**:
```yaml
# hyperdev-methodology recipe.yml
name: hyperdev-methodology
description: Complete Hyper Coding methodology setup
version: 1.0.0

variables:
  projectName:
    type: string
    required: true
    pattern: ^[a-z][a-z0-9-]*$
  toolStack:
    type: enum
    values: [typescript-react, typescript-node, javascript-react]
    default: typescript-react

steps:
  - name: Setup monorepo structure
    tool: template
    template: monorepo-structure.liquid
  - name: Configure Moon build system
    tool: template
    template: moon-config.liquid
  - name: Setup ESLint configuration
    tool: template
    template: eslint-config.liquid
    when: "{{ toolStack !== 'biome-only' }}"
  - name: Install dependencies
    tool: action
    action: install-deps
  - name: Setup Claude hooks
    tool: template
    template: claude-hooks.liquid
```

**Success Criteria**:
- Single command creates complete Hyper Coding project setup
- Recipe steps coordinate Tools to assemble tool stacks based on choices
- Generated projects pass all quality gates immediately
- Integration with existing Moon build system
- Clear documentation for methodology usage

### 2.2 Go CLI Subprocess Integration

**Goal**: Optimize hypergen for subprocess execution by Go CLI

**Technical Implementation**:
- Add JSON output modes for programmatic consumption
- Standardize exit codes and error handling
- Create subprocess-optimized command interface
- Implement npm package distribution optimization
- Build comprehensive error reporting

**Integration Interface**:
```typescript
// CLI output modes for Go integration
interface SubprocessOutput {
  success: boolean;
  data?: any;
  error?: {
    code: string;
    message: string;
    context?: Record<string, any>;
  };
  metadata: {
    duration: number;
    templatesUsed: string[];
    filesGenerated: string[];
  };
}
```

**Success Criteria**:
- Go CLI can reliably call hypergen as subprocess
- JSON output mode provides structured data for parsing
- Exit codes consistently indicate success/failure states
- Error reporting includes actionable context
- Performance optimized for subprocess calls: <500ms

## Phase 3: Testing and Documentation (Month 4)

### 3.1 Comprehensive Testing Strategy

**Goal**: Achieve 95%+ test coverage for all V8 features

**Testing Categories**:
- **Unit Tests**: Individual component functionality
- **Integration Tests**: Recipe composition and cookbook discovery workflows
- **End-to-End Tests**: Complete generation workflows with real recipes
- **Performance Tests**: Startup time and throughput validation
- **Security Tests**: Trust system and recipe execution validation

**Success Criteria**:
- 95%+ test coverage across all new functionality
- Performance benchmarks validate <100ms startup time
- Security tests validate trust system effectiveness
- Cross-platform compatibility (Windows, macOS, Linux)
- Regression tests prevent feature degradation

### 3.2 Migration and Compatibility

**Goal**: Smooth transition from current Template system to new Recipe/Tool V8 architecture

**Implementation**:
- Create Template→Recipe migration tool (frontmatter + generators to recipe.yml)
- Build compatibility layer for existing templates during transition
- Develop comprehensive migration documentation
- Implement gradual rollout strategy
- Create fallback mechanisms for legacy templates
- Document new mental model clearly

**Success Criteria**:
- Migration tool successfully converts existing templates to recipes
- Zero-downtime transition for existing users
- Clear migration path documentation with taxonomy explanation
- Backward compatibility maintained for 6 months minimum
- Community templates supported during transition
- Mental model change communicated clearly

## Technical Architecture

### Core Components Integration

**Enhanced Components**:
- `RecipeParser` → New with recipe.yml and composition
- `CookbookStore` → Integrated with discovery conventions
- `CLI` → Complete command implementation with new terminology
- `ToolSystem` → Template/Action/CodeMod with validation
- `DiscoveryService` → NPM and GitHub cookbook convention support
- `TrustSystem` → Creator-based trust management

**Data Flow**:
1. Cookbook Discovery → Trust Validation → Recipe Composition Resolution → Variable Validation → Step Execution (Tools) → Code Generation

### Performance Requirements

- **Startup Time**: <100ms for common operations
- **Recipe Resolution**: <500ms cached, <2s uncached
- **Composition Processing**: <200ms for complex hierarchies  
- **Tool Execution**: <50ms per tool step
- **Memory Usage**: Optimized for 1000+ recipe handling

### Security Model

- **Creator Trust**: Per-user/organization trust scope
- **Recipe Validation**: Comprehensive validation before execution
- **Execution Environment**: Secure recipe execution context
- **Network Transparency**: Clear logging of all remote requests
- **Consent Model**: Explicit user consent for all untrusted operations

## Risk Mitigation

### Technical Risks

**Lost Implementation Knowledge**: 
- Comprehensive documentation of all architectural decisions
- Clear implementation patterns and examples
- Extensive code comments and inline documentation

**Integration Complexity**:
- Start with simple HyperDev integration
- Build incrementally with continuous testing
- Maintain clear separation of concerns

**Performance Regression**:
- Continuous benchmarking throughout development
- Performance tests in CI/CD pipeline
- Regular profiling and optimization

### Process Risks

**Scope Creep Prevention**:
- Every feature validated against hypergen mission
- Regular review against MISSION.md constraints
- Explicit rejection of enterprise workflow features
- Focus on "easy to use" over "does everything"

**Community Impact**:
- Clear communication about V8 recovery
- Migration support for existing templates
- Backward compatibility during transition
- Community feedback integration

## Success Metrics

### Functional Success
- All recipe.yml features operational with validation
- Recipe composition working with inheritance and conditional inclusion
- Discovery system finding cookbooks via NPM and GitHub conventions
- Creator trust system preventing unauthorized execution
- CLI commands providing comprehensive functionality with clear taxonomy

### Performance Success
- Startup time maintained <100ms
- Recipe resolution performance targets met
- Memory usage optimized for large cookbook collections
- Benchmark tests passing in CI

### Integration Success
- HyperDev cookbook creates complete methodology setup
- Go CLI subprocess integration transparent to users
- npm distribution working seamlessly
- JSON output modes support programmatic use

This implementation plan rebuilds the lost V8 work with new Recipe/Tool/CodeMod taxonomy and strict mission alignment, ensuring hypergen serves its core purpose with clear mental model while supporting the HyperDev ecosystem without scope creep.