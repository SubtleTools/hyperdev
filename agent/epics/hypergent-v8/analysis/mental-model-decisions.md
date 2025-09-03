# Mental Model Decisions: New Recipe/Tool/CodeMod Taxonomy

> **Source**: V8 implementation mental model clarification based on user feedback and practical usage patterns

## The Fundamental Problem

**Previous confusion**: Both single files and generators were called "Templates", creating mental model confusion between processes and assets.

## New Clarified Taxonomy

### Templates
**Template files** (EJS, Liquid, etc.) that the Template Tool processes to generate code files. These are assets used in steps, not tools themselves.

Examples:
- `component.tsx.liquid`
- `package.json.ejs`  
- `README.md.liquid`

### Actions  
Actions are either commands or function calls. Both require user authorization for execution, either before or during the generation process. Functions executed by actions must be part of the cookbook.

Examples:
- Shell command: `npm install`
- Function call: `installDependencies()`
- Custom function: `updatePackageJson()`

### CodeMods
A `CodeMod` is a function that takes an AST and returns an AST. CodeMods allow existing code to be transformed. They will be used for migrations and automated code refactoring.

Examples:
- Add import statement
- Rename function
- Update configuration object

### Recipes
A `Recipe` defines a process that modifies a codebase, including from non-existence to existing. Each `Recipe` achieves a **specific goal**. Recipes execute their steps sequentially to move the codebase from one state to another.

Examples:
- Create new React component
- Add microservice to monorepo
- Setup CI/CD pipeline

### Tools
Tools provide capabilities to Hypergen. Every `Step` in `Recipe` makes use of one specific tool. Built-in tools:

- **Template Tool:** Processes template files using template engines
- **Action Tool:** Executes a function or shell command  
- **CodeMod Tool:** Runs an AST-transforming function to transform an existing file

### Cookbooks
A cookbook is composed of one or more "recipes". Each cookbook should be focused on a specific tool (e.g. Starlight, Astro, ESLint), or a specific scenario (e.g. Monorepo, Security).

### Kits
A kit is a shareable bundle containing one or more cookbooks and, in the future, tools, plugins, assets, etc. Kits can be shared via NPM or via a git repository.

## Mental Model Benefits

### Clear Separation of Concerns
- **Templates**: Files that get processed (data/assets)
- **Actions**: Operations that get executed (functions/commands)  
- **CodeMods**: Code transformations (AST functions)
- **Recipes**: Processes that coordinate tools (workflows)
- **Tools**: Built-in capabilities (Template/Action/CodeMod)
- **Cookbooks**: Collections of related recipes (organization)

### No More Confusion
- **Before**: "Templates" meant both files and generators
- **After**: Clear distinction between assets (templates) and processes (recipes)

### Natural Composition
- **Recipes** can include other recipes
- **Cookbooks** organize related recipes
- **Kits** bundle cookbooks for distribution
- **Tools** provide consistent execution interface

## Recipe Structure Example

```yaml
# recipe.yml
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

steps:
  - name: Generate component file
    tool: template
    template: component.tsx.liquid
    
  - name: Generate test file
    tool: template
    template: component.test.tsx.liquid
    when: "{{ typescript }}"
    
  - name: Update index file
    tool: codemod
    codemod: add-export
    
  - name: Install dependencies
    tool: action
    action: install-deps
```

## Cookbook Organization Example

```
@hyper-kits/starlight/
├── kit.yml
├── create/
│   ├── recipe.yml
│   ├── templates/
│   │   ├── starlight.config.js.liquid
│   │   └── package.json.liquid
│   ├── actions/
│   │   └── install-deps.js
│   └── codemods/
└── add/
    ├── page/
    │   ├── recipe.yml
    │   ├── templates/
    │   │   └── page.mdx.liquid
    │   └── actions/
    │       └── update-sidebar.js
    └── plugin/
        ├── recipe.yml
        └── codemods/
            └── register-plugin.js
```

## CLI Usage Examples

```bash
# Execute recipe from cookbook
hypergen starlight create

# Execute nested recipe  
hypergen starlight add page --name="Getting Started"

# List available cookbooks
hypergen cookbook list

# Validate recipe configuration
hypergen recipe validate starlight/create
```

## Migration Impact

### From Old Mental Model:
- ❌ Generator/Action/Template hierarchy
- ❌ Confusing "template" terminology
- ❌ Complex organizational structure

### To New Mental Model:
- ✅ Recipe/Tool/Asset separation
- ✅ Clear terminology for each concept
- ✅ Natural composition patterns
- ✅ Intuitive organizational structure

## Implementation Requirements

This taxonomy affects:

1. **CLI Commands**: Recipe/cookbook-centric interface
2. **Documentation**: Consistent terminology throughout
3. **Discovery System**: Cookbook-based discovery
4. **Composition Engine**: Recipe-to-recipe inclusion  
5. **File Organization**: Kit/cookbook/recipe structure
6. **Migration Tools**: Convert old templates to new recipes

## Key Success Factors

- **Consistency**: Use new terminology throughout all documentation and code
- **Clarity**: Each concept has a single, clear purpose
- **Composability**: Natural ways to combine and reuse components
- **Discoverability**: Easy to find and understand available recipes
- **Migration Path**: Smooth transition from old mental model

This new taxonomy eliminates confusion while providing powerful composition capabilities and clear organizational patterns.