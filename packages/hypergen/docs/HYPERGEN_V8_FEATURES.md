# Hypergen V8 Feature Summary

**Documentation Refactoring Guide**: This document provides a comprehensive overview of all Hypergen V8 features for updating the official documentation.

## Core Template System
- **Template.yml Configuration**: Rich variable types (string, boolean, number, enum, array, object) with validation, patterns, and defaults
- **Frontmatter Integration**: Hybrid approach - template.yml for generator metadata, frontmatter for file-specific config
- **Template Composition**: Inheritance and conditional inclusion from remote sources (GitHub, npm)
- **Multi-Template Support**: Both single template and multi-template generator structures

## Template Engines
- **LiquidJS (Default)**: Primary engine with `.liquid`, `.liquid.t`, `.liq`, `.liq.t` extensions
- **Rich Filters**: camelCase, snakeCase, kebabCase, pluralize, singularize, humanize, etc.
- **EJS Compatibility**: Backward compatibility with existing `.ejs`, `.ejs.t`, `.t` templates
- **Auto-detection**: Engine selection based on file extension or syntax patterns

## Action System
- **TypeScript Decorators**: Modern `@action` decorator pattern with metadata
- **Parameter Validation**: Type checking and validation before execution
- **Auto-discovery**: CLI commands automatically discover and register actions
- **Rich Metadata**: Categories, descriptions, parameter schemas for help generation

## Template Discovery & Distribution
- **NPM Conventions**: `hypergen-*`, `@user/hypergen-*`, `@hypergen/template-*` patterns
- **GitHub Discovery**: Templates identified via `hypergen-template` topic
- **URL Resolution**: Direct template loading from GitHub repos, gists, npm packages
- **Repository Validation**: Automatic structure validation for discovered templates

## Security & Trust
- **Creator Trust System**: Per-user/organization trust scope with explicit consent
- **Secure Execution**: Safe template execution environment
- **Transparent Operations**: Clear logging of remote template access
- **Validation Pipeline**: Comprehensive template validation before execution

## CLI Interface
```bash
# Template Operations
hypergen <generator> [options]          # Generate using template
hypergen template validate <path>       # Validate template configuration  
hypergen template list [directory]      # List available templates

# Action System
hypergen action list                     # List all available actions
hypergen action info <action>           # Show action details and parameters
hypergen <action> [options]            # Execute specific action

# Discovery & Trust
hypergen discover [search-term]         # Find templates from all sources
hypergen trust <creator>               # Trust template creator
hypergen url resolve <url>             # Resolve and cache URL templates

# System
hypergen system status                  # Show configuration and status
hypergen help [command]               # Comprehensive help system
```

## File Operations
- **Add**: Create files with template processing and variable substitution
- **Inject**: Insert content into existing files at specific locations
- **Shell**: Execute shell commands as part of generation workflow
- **Conditional Operations**: Skip/force file operations based on conditions

## Performance Features
- **Fast Startup**: <100ms for common operations
- **Template Caching**: Multi-level caching for remote templates
- **Lazy Loading**: Components loaded only when needed
- **Parallel Processing**: Concurrent template processing where possible

## Developer Experience
- **Rich Validation**: Clear error messages with context and suggestions
- **Auto-completion**: Metadata-driven help and parameter suggestions
- **Progressive Discovery**: Easy to start, powerful when needed
- **IDE Support**: TypeScript types and schema validation

## Integration Capabilities
- **Subprocess Optimized**: JSON output modes for programmatic consumption
- **Exit Code Standards**: Consistent success/failure indicators
- **HyperDev Ready**: Complete Hyper Coding methodology template support
- **Moon Integration**: Native moonrepo build system support

## Backward Compatibility
- **Existing Templates**: All current templates work without modification
- **Migration Path**: Gradual adoption of new features
- **Legacy Support**: EJS and existing frontmatter patterns maintained
- **Zero Breaking Changes**: Seamless upgrade experience

---

*Use this feature summary as the foundation for updating all documentation to reflect the complete V8 implementation.*