# Recipe Composability Architecture

> **Source**: V8 implementation analysis updated with new Recipe/Tool/CodeMod taxonomy - critical architectural decisions for recipe composition system

## Core Design Philosophy

### Key Insight: Composable Recipe System
The fundamental breakthrough is treating recipes as **composable units** that can include other recipes, with cookbooks organizing related recipes and clear Tool coordination.

### Author-Focused Workflow
- **Recipe AUTHORS benefit from reuse** - not end users composing on-the-fly
- **Cookbook organization** with clear recipe hierarchy, referenceable from URLs/Git repos
- **End users get the composed result** without complexity
- **Clear separation** between assets (templates) and processes (recipes)

## Recipe Structure Format

### Basic Structure (New Recipe.yml Format)
```yaml
# recipe.yml
name: "react-component"
description: "Creates React components with TypeScript and tests"
version: "1.0.0"

variables:
  name:
    type: string
    required: true
    prompt: "Component name?"
    pattern: ^[A-Z][a-zA-Z0-9]*$
  typescript:
    type: boolean
    default: true
    prompt: "Use TypeScript?"
  testing:
    type: boolean
    default: true
    prompt: "Include tests?"

# Recipe composition extensions
composition:
  includes:
    - recipe: "github:hyper-kits/react/base-component"
      variables:
        name: "{{ name }}"
        typescript: "{{ typescript }}"
    
    - recipe: "github:hyper-kits/testing/jest-setup"
      condition: "{{ testing }}"
      variables:
        componentName: "{{ name }}"

# Step execution using Tools
steps:
  - name: Generate component file
    tool: template
    template: "component.{{ typescript ? 'tsx' : 'jsx' }}.liquid"
    
  - name: Generate test file
    tool: template
    template: "component.test.{{ typescript ? 'tsx' : 'jsx' }}.liquid"
    when: "{{ testing }}"
    
  - name: Update index exports
    tool: codemod
    codemod: add-export
    target: "index.{{ typescript ? 'ts' : 'js' }}"
    
  - name: Install dev dependencies
    tool: action
    action: install-dev-deps
    when: "{{ testing }}"
```

## URL Reference System for Recipes

### Supported URL Formats
```yaml
composition:
  includes:
    # Direct Git URLs (cookbooks)
    - recipe: "https://github.com/hyper-kits/react/tree/main/base-component"
    
    # GitHub shorthand for cookbooks
    - recipe: "github:hyper-kits/react/base-component"
    
    # GitHub with version/tag
    - recipe: "github:hyper-kits/react/base-component@v1.2.3"
    
    # NPM packages (kits)
    - recipe: "npm:@hyper-kits/react/base-component"
    
    # Local recipes (for development)
    - recipe: "file:../shared-recipes/base-component"
```

### Variable Passing and Mapping
```yaml
composition:
  includes:
    - recipe: "github:hyper-kits/testing/jest-setup"
      variables:
        componentName: "{{ name }}"
        typescript: "{{ typescript }}"
        testFramework: "jest"
      
      # Optional: rename variables for included recipe
      map:
        name: componentName
        ts: typescript
```

## Recipe Resolution Engine

### Core Interface
```typescript
interface RecipeInclude {
  recipe: string           // URL to recipe
  variables?: Record<string, any>
  condition?: string       // when to include
  map?: Record<string, string>  // variable name mapping
}

interface RecipeComposition {
  includes: RecipeInclude[]
}

interface StepDefinition {
  name: string
  tool: 'template' | 'action' | 'codemod'
  template?: string        // for Template Tool
  action?: string          // for Action Tool  
  codemod?: string         // for CodeMod Tool
  when?: string           // conditional execution
  variables?: Record<string, any>
}

class RecipeResolver {
  async resolveComposition(recipe: ParsedRecipe): Promise<ComposedRecipe> {
    const composedSteps: StepDefinition[] = [...recipe.steps]
    
    for (const include of recipe.composition?.includes || []) {
      // 1. Fetch remote recipe
      const remoteRecipe = await this.fetchRecipe(include.recipe)
      
      // 2. Parse and validate
      const parsed = await this.parseRecipe(remoteRecipe)
      
      // 3. Apply variable mapping
      const variables = this.mapVariables(include.variables, include.map)
      
      // 4. Merge steps with proper ordering
      const mappedSteps = this.mapStepVariables(parsed.steps, variables)
      composedSteps.push(...mappedSteps)
      
      // 5. Merge cookbook assets (templates, actions, codemods)
      await this.mergeCookbookAssets(parsed.cookbook)
    }
    
    return { ...recipe, steps: composedSteps }
  }
  
  private async fetchRecipe(url: string): Promise<RawRecipe> {
    // Handle different URL formats
    if (url.startsWith('github:')) {
      return this.fetchGitHubRecipe(url)
    } else if (url.startsWith('npm:')) {
      return this.fetchNpmRecipe(url)
    } else if (url.startsWith('file:')) {
      return this.fetchLocalRecipe(url)
    } else {
      return this.fetchDirectUrl(url)
    }
  }
}
```

## Cookbook Organization

### Kit Structure with Recipes
```
@hyper-kits/react/
├── kit.yml                     # Kit metadata
├── create/
│   ├── recipe.yml             # Create new React app
│   ├── templates/
│   │   ├── app.tsx.liquid
│   │   └── package.json.liquid
│   ├── actions/
│   │   └── install-deps.js
│   └── codemods/
├── add/
│   ├── component/
│   │   ├── recipe.yml         # Add React component
│   │   ├── templates/
│   │   │   ├── component.tsx.liquid
│   │   │   └── component.test.tsx.liquid
│   │   └── codemods/
│   │       └── add-export.js
│   └── hook/
│       ├── recipe.yml         # Add custom hook
│       └── templates/
│           └── hook.ts.liquid
└── shared/
    ├── templates/
    ├── actions/
    └── codemods/
```

### Recipe Reference Within Kit
```yaml
# In add/component/recipe.yml
composition:
  includes:
    # Reference other recipes in same kit
    - recipe: "./shared/base-component"
    
    # Reference recipes from other kits
    - recipe: "github:hyper-kits/testing/jest-setup"
```

## Tool Coordination in Composed Recipes

### Step Execution Order
When recipes are composed, steps are executed in order:
1. Parent recipe steps (pre-composition)
2. Included recipe steps (in include order)
3. Parent recipe steps (post-composition)

### Asset Resolution
- **Templates**: Resolved from cookbook's `templates/` directory
- **Actions**: Functions from cookbook's `actions/` directory
- **CodeMods**: Functions from cookbook's `codemods/` directory

### Variable Context
Variables flow through the composition:
1. User input variables
2. Recipe default variables
3. Computed variables from previous steps
4. Mapped variables for included recipes

## Recipe Author Benefits

### ✅ **Clear Organization**
- Recipes organized in logical cookbook structure
- Clear separation between assets and processes
- Intuitive CLI mapping: `hypergen <cookbook> <recipe>`

### ✅ **Powerful Composition**
- Include recipes from any cookbook/kit
- Pass variables with mapping support
- Conditional inclusion based on user choices

### ✅ **Tool Coordination**
- Template Tool processes template files
- Action Tool executes with user authorization
- CodeMod Tool transforms existing code
- All tools work together in recipe steps

### ✅ **Easy Distribution**
- Kits distributed via NPM or Git
- Recipes reference other recipes by URL
- No complex build process required

## Implementation Requirements

### Recipe.yml Parser Enhancement
Extend recipe parsing to support:
- Composition includes section with URL resolution
- Variable mapping and passing between recipes
- Conditional inclusion logic
- Step merging with proper execution order

### Recipe Resolution System
Build comprehensive URL recipe resolver with:
- GitHub/NPM kit integration
- Local file support for development
- Intelligent caching for performance
- Security validation for remote recipes

### Tool Coordination Engine  
Implement step execution engine:
- Template/Action/CodeMod tool registration
- Asset resolution from cookbook structure
- Variable context management across steps
- Error handling and rollback capabilities

### Kit Discovery Integration
Connect with discovery system:
- NPM registry search for `@hyper-kits/*` packages
- GitHub topic search for `hypergen-cookbook`
- Kit structure validation
- Recipe listing and metadata extraction

This architecture enables powerful recipe composition with clear mental model separation while maintaining simplicity for recipe authors and end users.