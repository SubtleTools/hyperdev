# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a moonrepo monorepo containing multiple packages and applications, with the main package being **Hypergen** - a modern, scalable code generator built with TypeScript. The repository uses git submodules to aggregate separate repositories for each package and app.

**Key Note**: Every package and app has its own separate repository and is aggregated here using git submodules for unified development workflows.

## Essential Commands

### Package Management
- **Use `bun` for all package operations** - Never use npm
- `bun install` - Install dependencies
- `bun update` - Update dependencies

### Moon Build System Commands
```bash
# Core Development Commands
moon check --all                    # Run all tasks (build, lint, test, format, typecheck)
moon run :build                     # Build all projects  
moon run :lint                      # Lint all projects
moon run :test                      # Run tests in all projects
moon run :format                    # Format code in all projects
moon run :typecheck                 # Type check all projects

# Project-specific Commands  
moon run <project>:dev              # Start development server for applications
moon run <project>:<task>           # Run specific task for specific project
moon check <project>                # Run all tasks for specific project
```

### Hypergen Development (Main Package)
```bash
# Located at packages/hypergen/
cd packages/hypergen

# Development Commands
bun run build                       # Build TypeScript and generate changelog
bun run build:lib                   # Compile TypeScript only
bun run test                        # Run tests with coverage
bun run test:code                   # Run tests without coverage  
bun run watch                       # Run tests in watch mode
bun run hygen                       # Run hypergen locally during development
bun run hygen:build                 # Run built version

# Documentation
bun run docs:dev                    # Start docs development server
bun run docs:build                  # Build documentation site
bun run docs:api                    # Generate TypeScript API docs
```

### Git and Version Control
```bash
# Since this uses submodules, commits should follow conventional commit format
git commit -m "feat(hypergen): add new template discovery system"
git commit -m "fix(docs): correct CLI example in getting started"
git commit -m "docs: update architecture overview"
```

## Architecture Overview

### Monorepo Structure
```
hyperdev/
├── .moon/                          # Moon build system configuration
├── apps/                           # Applications (currently empty - examples in moon template)
├── packages/                       # All packages (aggregated via submodules)
│   ├── hypergen/                   # Main code generator package
│   ├── hypergen-moon/              # Moon integration
│   ├── hypergen-starlight/         # Documentation site generator
│   ├── moon-launch/                # Moon project templates
│   └── moon-templates/             # Additional templates
├── .taskmaster/                    # Task Master AI integration
└── Configuration Files.md          # Detailed config file documentation
```

### Hypergen Package Architecture

**Core Flow**: `bin.ts` → `engine.ts` → `render.ts` → `execute.ts`

**Key Components**:
- **Template Engine**: EJS-based rendering with frontmatter support (`.ejs.t` files)
- **Configuration System**: Hierarchical config loading with cosmiconfig
- **Template Discovery**: Multiple sources (local, npm, GitHub) with intelligent caching
- **Actions System**: TypeScript decorator-based actions (V8 feature)
- **Trust System**: Security model for external templates
- **Performance**: Multi-level caching, lazy loading, parallel processing

**Template Structure**:
- Single template: `template.yml` + `.ejs.t` files
- Multi-template: `templates/*/template.yml` structure  
- Configuration: `hypergen.config.js` (project) → `hypergen-package.config.js` (package) → `template.yml` (template)

### Key Systems in Detail

**Template Store** (`TemplateStore.ts`): Hash-indexed storage for fast template lookup across multiple directories

**Configuration Hierarchy**:
1. Project: `hypergen.config.js` - Full configuration with all features
2. Package: `hypergen-package.config.js` - Limited scope for template repos  
3. Template: `template.yml` - Individual template metadata and variables

**Operations** (`src/ops/`): File operations (add, inject, shell commands) that templates can perform

**Discovery** (`src/discovery/`): Multi-source template discovery (npm registry, GitHub repos, local files)

**Trust System** (`src/trust/`): Security framework for validating and trusting external template sources

## Development Workflows

### Working with Hypergen
1. Navigate to hypergen package: `cd packages/hypergen`
2. Install dependencies: `bun install`
3. Run tests: `bun test --watch`
4. Make changes to source files
5. Test locally: `bun run hygen <command>`
6. Build when ready: `bun run build`

### Working with Multiple Projects
- Use `moon run :lint` to check all projects
- Use `moon run hypergen:test` to test specific project
- Each package maintains its own repository via submodules

### Testing Strategy
- **Unit Tests**: Individual component testing in `tests/suites/`
- **Integration Tests**: End-to-end workflow testing 
- **Metaverse Tests**: Real-world template validation
- **Performance Tests**: Startup time and throughput testing
- **Coverage**: Aim for high coverage with `bun test --coverage`

## Key Files and Locations

### Hypergen Package (`packages/hypergen/`)
- `src/bin.ts` - CLI entry point
- `src/engine.ts` - Core orchestration
- `src/render.ts` - Template rendering (EJS)
- `src/execute.ts` - File operations execution
- `src/config/` - Configuration system
- `src/discovery/` - Template source discovery
- `src/trust/` - Security and trust management
- `tests/` - Test suites organized by category

### Project Root
- `.moon/` - Moon build system configuration
- `.taskmaster/` - Task Master AI project management
- `Configuration Files.md` - Complete config reference
- `packages/` - All submodule packages

### Configuration Files
- `.moon/workspace.yml` - Moon workspace configuration
- `packages/hypergen/hypergen.json` - Hypergen project config
- `packages/hypergen/package.json` - Node.js package config
- Individual `moon.yml` files in each package

## Important Development Notes

### Package Manager
- **Always use `bun`** - Never use npm per user preferences
- Yarn is configured as package manager but bun preferred for commands

### Testing
- Tests use Vitest framework
- Coverage reporting enabled by default
- Watch mode available for development
- Metaverse tests validate real-world scenarios

### Performance Considerations  
- Lazy loading for better startup performance (<100ms target)
- Hash-indexed template storage for scalability
- Multi-level caching system
- Parallel processing where possible

### Migration Context
- Hypergen forked from Hygen with enhanced features
- Maintains backward compatibility while adding new capabilities
- Focus on scalability and enterprise features

## Task Master AI Integration

This project includes Task Master AI for project management. Key files:
- `.taskmaster/tasks/tasks.json` - Main task database
- `.taskmaster/config.json` - AI model configuration  
- `.taskmaster/docs/prd.txt` - Product requirements documents

See `.taskmaster/CLAUDE.md` for complete Task Master integration details.

## Common Development Tasks

### Adding New Features to Hypergen
1. Create feature branch
2. Add implementation in appropriate `src/` directory
3. Add comprehensive tests in `tests/suites/`
4. Update documentation if needed
5. Run full test suite: `bun test`
6. Build and verify: `bun run build`
7. Test CLI functionality: `bun run hygen <command>`

### Working with Templates
- Template files use `.ejs.t` extension
- Frontmatter in YAML defines metadata
- Variables available via EJS context
- Test with real template generation

### Contributing to Documentation
- Documentation site in `packages/hypergen/docs/`
- Use `bun run docs:dev` for live development
- API docs auto-generated from TypeScript

### Debugging and Troubleshooting  
- Use `bun run hygen:build` to test built version
- Enable debug logging via environment variables
- Check test outputs for validation
- Use `moon check hypergen` for comprehensive validation