# Template.yml + Frontmatter Hybrid Design

## Design Philosophy

The V8 implementation uses a **hybrid approach** that combines the strengths of both template.yml and frontmatter configurations, rather than replacing one with the other.

## Separation of Concerns

### template.yml - Generator Metadata
**Purpose**: Generator-level configuration and variable definitions

**Responsibilities**:
- Generator name, description, version, author
- Variable type definitions with validation
- Parameter schemas (required, defaults, patterns, enums)
- Examples and usage documentation
- Template composition and inheritance
- Lifecycle hooks

**Example**:
```yaml
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
```

### Frontmatter - Template-Specific Configuration
**Purpose**: Individual template file behavior and output configuration

**Responsibilities**:
- Output file path (`to:`)
- Injection behavior (`inject:`)
- File processing options (`skip_if:`, `force:`)
- Template-specific conditionals
- Per-file customization

**Example**:
```yaml
---
to: src/components/<%= name %>.tsx
skip_if: <%= !typescript %>
---
```

## Why This Design is Superior

### 1. **Clean Separation**
- **Generator metadata** stays at the generator level (template.yml)
- **File-specific config** stays at the file level (frontmatter)
- No overlap or confusion about where configuration belongs

### 2. **Scalability**
- template.yml doesn't get bloated with per-file configurations
- Frontmatter remains simple and focused
- Easy to add new template files without modifying central config

### 3. **Flexibility**
- Each template file can have unique output behavior
- Generator-level variables apply to all templates
- Template-specific overrides possible via frontmatter

### 4. **Backward Compatibility**
- Existing templates with frontmatter continue to work
- No breaking changes to current template structure
- Gradual adoption of template.yml features

### 5. **Developer Experience**
- Clear mental model: "Where does this configuration belong?"
- IDE support for both YAML schemas
- Validation at the appropriate level

## Implementation Benefits

### Current Implementation ✅
```
_templates/my-generator/
├── template.yml          # Generator metadata, variables, validation
├── component.ejs.t       # Template with frontmatter for output path
└── actions.ts           # TypeScript actions with decorators
```

### What We Avoided ❌
```
_templates/my-generator/
├── template.yml          # BLOATED with per-file configs
│   ├── variables: {...}
│   ├── files:           # This would be messy!
│   │   ├── component:
│   │   │   ├── to: "src/..."
│   │   │   ├── inject: true
│   │   └── test:
│   │       ├── to: "test/..."
└── component.ejs         # No frontmatter = less flexible
```

## Real-World Example

### Generator Structure
```
react-component/
├── template.yml          # Variables: name, typescript, styling
├── component.ejs.t       # → src/components/Name.tsx
├── test.ejs.t           # → src/components/Name.test.tsx
├── story.ejs.t          # → src/stories/Name.stories.tsx
└── actions.ts           # TypeScript action implementation
```

### template.yml (Generator Level)
```yaml
name: react-component
variables:
  name: { type: string, required: true }
  typescript: { type: boolean, default: true }
  withStorybook: { type: boolean, default: false }
```

### component.ejs.t (File Level)
```yaml
---
to: src/components/<%= name %><%= typescript ? '.tsx' : '.jsx' %>
---
```

### story.ejs.t (Conditional File)
```yaml
---
to: src/stories/<%= name %>.stories.tsx
skip_if: <%= !withStorybook %>
---
```

## Conclusion

The hybrid approach gives us:
- **Best of both worlds**: Rich metadata + flexible file configuration
- **Clean architecture**: Right config in the right place
- **No breaking changes**: Existing templates work unchanged
- **Scalable design**: Easy to extend without bloat

This design aligns perfectly with the hypergen mission of simplicity and developer experience.