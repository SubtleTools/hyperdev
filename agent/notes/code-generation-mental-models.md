# Code Generation Mental Models: A Comparative Analysis

## Overview

This document compares the mental models and approaches of four major code generation tools: **Hygen**, **Yeoman**, **Hypergen**, and **Moon Launch**. Understanding these mental models is crucial for positioning Hypergen's evolution and template directory conventions.

## 1. Hygen: File Structure as Commands

### Mental Model
**"Command structure IS folder structure"**

### Core Concepts
```
_templates/
  component/          # Generator
    new/              # Action  
      index.ejs.t     # Template
      style.ejs.t     # Template
    update/           # Action
      patch.ejs.t     # Template
```

### User Thinking Process
1. "I want to generate a **component** with the **new** action"
2. Command maps directly to folder: `hygen component new`
3. All templates in `component/new/` are executed

### Strengths
- **Intuitive mapping**: Command structure mirrors file structure
- **Organized**: Related templates grouped by generator/action
- **Discoverable**: Easy to see what generators exist
- **Predictable**: `hygen [generator] [action]` formula

### Limitations
- **Rigid hierarchy**: Must fit generator → action → templates model
- **Template isolation**: Hard to reuse templates across generators
- **Namespace pollution**: Each generator needs unique action names
- **Directory sprawl**: Deep nested structures for complex cases

### Template Philosophy
Templates are **implementation details** of actions. The generator/action is the primary abstraction.

---

## 2. Yeoman: Generators as Programs

### Mental Model
**"Generators are Node.js programs that use templates"**

### Core Concepts
```javascript
// Generator Class (JavaScript)
class MyGenerator extends Generator {
  prompting() {
    return this.prompt([...questions])
  }
  
  writing() {
    this.fs.copyTpl(
      this.templatePath('index.html'),
      this.destinationPath('public/index.html'),
      { title: this.answers.name }
    )
  }
}
```

### User Thinking Process
1. "I need to **write a program** that generates code"
2. "Templates are **resources** my program uses"
3. "Logic controls when and how templates are used"

### Strengths
- **Programmable**: Full JavaScript for complex logic
- **Flexible**: Can do anything Node.js can do
- **Ecosystem**: npm packages, rich community
- **Mature**: Battle-tested in enterprise environments

### Limitations
- **High barrier to entry**: Must write JavaScript classes
- **Complexity**: Overkill for simple template scenarios  
- **Slow**: Heavy runtime, slower startup
- **Remote dependencies**: Templates often fetched from npm

### Template Philosophy
Templates are **resources** consumed by generator programs. The generator program is the primary abstraction.

---

## 3. Hypergen V7: Enhanced Hygen

### Mental Model
**"Generators + Actions + Templates, but faster and more capable"**

### Core Concepts
```
_templates/
  component/          # Generator (enhanced)
    new/              # Action (with rich config)
      template.yml    # Action configuration
      index.ejs.t     # Template (multiple engines)
      style.liquid.t  # Template (LiquidJS)
```

### User Thinking Process
1. "Like Hygen, but **faster** and with **better templates**"
2. "I can use **multiple template engines**"
3. "Templates can have **rich configuration**"

### Strengths
- **Performance**: Hash-indexed stores, lazy loading
- **Multiple engines**: EJS, LiquidJS, extensible
- **Rich configuration**: template.yml with variables, validation
- **Modern stack**: TypeScript, ESM, better tooling
- **Backward compatible**: Works with existing Hygen templates

### Limitations
- **Still hierarchical**: Inherits Hygen's generator/action model
- **Mental overhead**: Users must learn new concepts (template.yml, multiple engines)
- **Complex**: More powerful but more complex than Hygen

### Template Philosophy
Templates are **smart implementation details** with their own configuration and capabilities.

---

## 4. Plop.js: Configuration-Driven Generation

### Mental Model
**"Generators are configured actions that transform templates"**

### Core Concepts
```javascript
// plopfile.js
export default function (plop) {
  plop.setGenerator('component', {
    description: 'Create a React component',
    prompts: [
      {
        type: 'input',
        name: 'name',
        message: 'Component name?'
      },
      {
        type: 'confirm', 
        name: 'wantStories',
        message: 'Include Storybook stories?'
      }
    ],
    actions: [
      {
        type: 'add',
        path: 'src/components/{{pascalCase name}}/{{pascalCase name}}.tsx',
        templateFile: 'plop-templates/component.hbs'
      },
      {
        type: 'add', 
        path: 'src/components/{{pascalCase name}}/{{pascalCase name}}.stories.tsx',
        templateFile: 'plop-templates/stories.hbs',
        skip: '{{#unless wantStories}}skip{{/unless}}'
      }
    ]
  })
}

### User Thinking Process  
1. "I configure **generators** in a central plopfile"
2. "Generators have **prompts** and **actions**"  
3. "Actions transform **template files** into target files"

### Strengths
- **Centralized configuration**: All generators in one plopfile
- **Action-oriented**: Clear actions (add, modify, append)
- **Built-in helpers**: Case transformation, conditionals
- **Lightweight**: Minimal setup, fast execution
- **Handlebars**: Familiar template syntax

### Limitations
- **Single file config**: Can become unwieldy with many generators
- **Limited composition**: Hard to reuse across projects
- **Template coupling**: Templates tightly coupled to generators
- **No discovery**: Must know generator names

### Template Philosophy
Templates are **passive assets** transformed by configured actions. The generator configuration is the primary abstraction.

---

## 5. Hypergen V8: Evolved Mental Model

### Mental Model (Current Direction)
**"Templates with Actions: Programmable + Declarative"**

### Core Concepts
```typescript
// Declarative template.yml
title: "React Component" 
variables:
  name: { type: string, required: true }
  withStories: { type: boolean, default: false }

includes:
  - url: "github:hyperdev/templates/react-base.liquid"
  - url: "github:hyperdev/templates/storybook.liquid"
    condition: "{{ withStories }}"

// Programmatic actions.ts  
@action({
  name: 'react-component',
  description: 'Generate React component with TypeScript'
})
export async function createReactComponent(context: ActionContext) {
  // TypeScript logic for complex scenarios
}
```

### User Thinking Process
1. "Templates handle **common cases** declaratively"
2. "Actions handle **complex cases** programmatically"  
3. "Templates can **compose** other templates via URL"
4. "One mental model handles both simple and complex scenarios"

### Strengths
- **Hybrid approach**: Declarative simplicity + programmatic power
- **URL composition**: Templates can include remote templates
- **TypeScript actions**: Type-safe programmatic logic
- **Backward compatible**: Works with existing patterns
- **Flexible**: Can be simple templates OR complex generators

### Potential Issues
- **Dual complexity**: Two ways to do things
- **Mental overhead**: Users must understand both models
- **Discovery complexity**: Templates vs actions vs combinations

---

## Comparison Matrix

| Tool | Primary Abstraction | Structure | Composition | Learning Curve | Performance |
|------|-------------------|-----------|-------------|----------------|-------------|
| **Hygen** | Generator/Action | Hierarchical | Limited | Low | Good |
| **Yeoman** | Generator Program | Programmatic | High | High | Poor |  
| **Plop.js** | Generator Config | Centralized | Limited | Low | Good |
| **Hypergen V7** | Enhanced Generator | Hierarchical | Limited | Medium | Excellent |
| **Hypergen V8** | Template + Action | Hybrid | URL-based | High | Excellent |

---

## Concept Equivalence Table

Using **Yeoman** as the reference (most well-defined concepts), here's how core concepts map across tools:

| **Yeoman Concept** | **Hygen** | **Plop.js** | **Hypergen V7** | **Hypergen V8** |
|-------------------|-----------|--------------|-----------------|-----------------|
| **Generator** (Node.js class) | Generator (folder) | Generator (config object) | Generator (folder) | Template Pack (folder) |
| **Generator Method** (`writing()`, `prompting()`) | Action (subfolder) | Action (config array) | Action (subfolder) | Action (TypeScript function) |
| **Template** (file resource) | Template (`.ejs.t` file) | Template (`.hbs` file) | Template (`.ejs.t`/`.liquid.t` file) | Template (`.liquid` file) |
| **Prompt** (`this.prompt()`) | `prompt.js` file | `prompts` array | `template.yml` variables | `template.yml` variables + Action parameters |
| **Destination** (`this.destinationPath()`) | `to:` frontmatter | `path` in action | `to:` frontmatter | `destination` in template.yml |
| **Context Variables** (`this.answers`) | CLI args + prompts | Prompt answers | CLI args + variables | Variables + Action context |
| **Composition** (calling other generators) | ❌ Not available | ❌ Not available | ❌ Not available | ✅ `includes` URL system |
| **Configuration** (`this.config`) | `hypergen.config.js` | `plopfile.js` | `hypergen.config.js` + `template.yml` | `template.yml` (primary) |
| **Installation** (`yo install`) | Local `_templates/` | Local `plopfile.js` | Local `_templates/` | Local `templates/` or URL |
| **Discovery** (`yo --help`) | Folder scanning | `plop --help` | Folder scanning | Folder + URL scanning |

### Key Insights from Concept Mapping

#### 1. **Generator Evolution**
- **Yeoman**: Generator = JavaScript class (heavy, programmatic)
- **Hygen**: Generator = folder structure (light, declarative)  
- **Plop**: Generator = configuration object (medium, structured)
- **Hypergen V8**: Generator = Template pack (light, composable)

#### 2. **Template Philosophy Shift**
- **Yeoman**: Templates serve generators
- **Hygen**: Templates serve actions  
- **Plop**: Templates serve configured actions
- **Hypergen V8**: Templates can be autonomous or serve actions

#### 3. **Composition Capabilities**
- **Yeoman**: Can call other generators (`this.composeWith()`)
- **Others**: Limited to internal template reuse
- **Hypergen V8**: First to enable URL-based template composition

#### 4. **Configuration Complexity**
- **Yeoman**: Complex (JavaScript class hierarchy)
- **Plop**: Medium (centralized plopfile)
- **Hygen**: Simple (folder structure)
- **Hypergen V8**: Variable (simple templates to complex actions)

---

## Mental Model Evolution

### The Hygen Foundation (2017)
- **Innovation**: Command structure = folder structure
- **Success**: Intuitive, fast, local templates
- **Limitation**: Rigid hierarchy, limited reusability

### The Yeoman Legacy (2012)
- **Innovation**: Generators as programs, rich ecosystem
- **Success**: Mature, flexible, programmable
- **Limitation**: Complex, slow, high barrier to entry

### The Plop Innovation (2015)
- **Innovation**: Configuration-driven generation, centralized plopfile
- **Success**: Lightweight, action-oriented, built-in helpers
- **Limitation**: Single file config, limited composition

### The Hypergen V8 Synthesis
- **Innovation**: Hybrid declarative/programmatic approach
- **Goal**: Best of all worlds - simple yet powerful
- **Challenge**: Avoid mental model confusion

---

## Recommendations for Hypergen V8

### 1. Template Directory Conventions

**Current**: `_templates/` (Hygen legacy)

**Proposed**:
- **`templates/`** - For "packs" (multi-template collections)
- **`template/`** - For single-template repos and npm packages

**Rationale**: 
- Removes underscore (more standard)
- Distinguishes between collection vs single template
- Aligns with Moon's template-first thinking

### 2. "Packs" Concept

Based on MISSION.md analysis, "packs" should be:
- **Collections of related templates** (like current generators)
- **Shareable units** via git repos or npm packages  
- **Discoverable** via CLI commands
- **Self-contained** with their own configuration

**Implementation**:
```
templates/           # Pack directory
  react-components/  # Pack name
    template.yml     # Pack configuration
    component/       # Individual templates
    hook/
    context/
```

### 3. Mental Model Simplification

**Recommendation**: Gradually shift from "Generator/Action" to "Template/Pack"

**Migration Path**:
1. **Phase 1**: Support both `_templates/` and `templates/` 
2. **Phase 2**: Document "packs" concept clearly
3. **Phase 3**: Update CLI to use template-first language
4. **Phase 4**: Deprecate generator/action terminology

### 4. Discovery Strategy  

Templates should be discoverable via:
- **Local scanning**: `hypergen list` shows available templates
- **Pack listing**: `hypergen packs` shows template collections
- **Search**: `hypergen search react` finds relevant templates
- **Documentation**: Clear pack structure in docs

---

## Conclusion

Hypergen V8 has the opportunity to synthesize the best mental models from all major code generation tools:

- **Hygen's** intuitive command-to-folder mapping
- **Yeoman's** programmatic flexibility  
- **Moon's** template-first composability
- **Performance** that surpasses all existing tools

The key is evolving the mental model gradually while maintaining the intuitive simplicity that made Hygen successful, but with the modern capabilities that developers expect in 2024.

The shift from `_templates` to `templates/template` is part of this evolution - moving toward a more template-centric mental model while preserving organizational benefits.