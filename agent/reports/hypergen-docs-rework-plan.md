# Hypergen Documentation Rework Plan

## Executive Summary

The current Hypergen documentation is filled with hallucinated enterprise features that don't exist and completely misrepresent what the project actually is. This plan outlines a complete restructuring to focus on Hypergen's real purpose: a practical code generator for developers tired of repetitive setup work.

## Current Problems

### 1. Hallucinated Features
- **Action Pipelines**: Complex orchestration that doesn't exist
- **Cross-Action Communication**: State sharing between actions that isn't implemented
- **Workflow Orchestration**: Enterprise-level pipeline management that makes no sense for a template generator
- **Advanced Composition Engine**: Overly complex features not matching the simple tool this actually is

### 2. Wrong Target Audience & Tone
- **Current**: Enterprise workflows, complex pipeline systems, intimidating technical jargon
- **Should Be**: Individual developers, small teams, practical OSS tool users
- **Current Tone**: Corporate, complex, overwhelming
- **Should Be**: Friendly, approachable, "by developers for developers"

### 3. Missing Real Features
- Little documentation on npm package templates (which actually work)
- Poor coverage of trust system (which is actually implemented)
- Missing GitHub integration docs (which works)
- No coverage of real CLI commands

## Target Audience & Positioning

### Primary Audience
- **Individual developers** frustrated with repetitive boilerplate setup
- **Small development teams** wanting consistent project scaffolding
- **OSS maintainers** who want to share their project templates

### Value Proposition
"Hypergen is a simple, practical code generator. You create templates for the code you write over and over, and Hypergen generates it for you. Share templates as npm packages or use ones from the community."

### Tone & Style
- **Conversational**: "You know that feeling when you're setting up the same React component structure for the 50th time?"
- **Practical**: Focus on real problems and simple solutions
- **Encouraging**: "Let's save you some typing"
- **Developer-friendly**: Code examples, real use cases, no enterprise jargon

## New Documentation Structure

```
docs/src/content/docs/
├── index.mdoc                     # New homepage - what Hypergen actually is
├── getting-started/
│   ├── index.mdoc                 # Quick 5-minute start
│   ├── installation.mdoc          # Simple install guide
│   ├── first-template.mdoc        # Create your first template
│   └── using-npm-templates.mdoc   # Use community templates
├── guides/
│   ├── creating-templates.mdoc    # Template creation guide
│   ├── sharing-templates.mdoc     # Publishing to npm
│   ├── local-templates.mdoc       # _templates/ directory
│   └── trust-system.mdoc          # Security for external templates
├── examples/
│   ├── index.mdoc                 # Example overview
│   ├── react-component.mdoc       # Simple React component generator
│   ├── api-endpoint.mdoc          # Express endpoint generator
│   ├── config-files.mdoc          # Generate config files
│   └── full-projects.mdoc         # Project scaffolding examples
├── reference/
│   ├── cli.mdoc                   # Complete CLI reference
│   ├── template-syntax.mdoc       # EJS/Liquid syntax
│   ├── frontmatter.mdoc          # YAML frontmatter options
│   └── configuration.mdoc         # hypergen.json options
├── actions/                       # NEW: Simple Actions system
│   ├── index.mdoc                 # Actions overview
│   ├── getting-started.mdoc       # First action hook
│   ├── built-in-actions.mdoc      # Available actions
│   └── custom-actions.mdoc        # Creating actions
└── community/
    ├── contributing.mdoc          # How to contribute
    ├── template-gallery.mdoc     # Community templates
    └── support.mdoc               # Getting help
```

## Content Strategy

### 1. Homepage Rewrite
**Current**: "Modern template generation engine with enhanced discovery and composition capabilities"
**New**: "Stop copying and pasting boilerplate. Create templates for the code you write repeatedly, then generate it instantly."

### 2. Getting Started Flow
1. Install Hypergen (`npm install -g hypergen`)
2. Try a community template (`hypergen starlight my-docs`)
3. Create your first local template (simple React component)
4. Share it as an npm package

### 3. Real Examples First
- Start every guide with a concrete, relatable problem
- Show the manual way vs. the Hypergen way
- Include copy-pasteable code examples
- Focus on time-saving and consistency benefits

### 4. Actions System Documentation
Based on the design document:
- Position as "simple hooks for templates"
- Focus on practical use cases (git init, npm install, format code)
- Emphasize composition with existing tools vs. reinventing

## Implementation Plan

### Phase 1: Core Content Rewrite (Week 1)
1. **New Homepage** - Clear value prop, real positioning
2. **Getting Started Guide** - 5-minute working example
3. **CLI Reference** - Document commands that actually exist
4. **Template Creation Guide** - Practical template building

### Phase 2: Example-Driven Content (Week 2)  
1. **Real Examples** - React components, API endpoints, config files
2. **NPM Templates Guide** - Using and publishing templates
3. **Trust System Guide** - Security for external templates

### Phase 3: Actions System Prep (Week 3)
1. **Actions Documentation** - Based on design document
2. **Simple Hooks Guide** - Template before/after actions
3. **Built-in Actions Reference** - Available actions

### Phase 4: Community & Polish (Week 4)
1. **Community Resources** - Template gallery, contributing
2. **Migration Guide** - For users coming from similar tools
3. **Troubleshooting** - Common issues and solutions
4. **Final review and consistency check**

## Key Messaging Changes

### Before
"Hypergen V8 is a modern template generation engine that enhances core functionality with improved discovery, multi-source template support, and foundation for advanced composition features."

### After  
"Hypergen helps you stop copying and pasting boilerplate code. Create templates for the components, configs, and project structures you build repeatedly, then generate them instantly."

### Before
"Complex workflow orchestration with action pipelines and cross-action communication"

### After
"Simple template hooks that run shell commands - install packages, format code, or set up git repos after generating files"

### Before
"Enterprise-ready with advanced composition capabilities"

### After
"Built by developers, for developers. Share your templates as npm packages or use great ones from the community."

## Success Metrics

1. **Clarity**: New users can create their first template in under 10 minutes
2. **Accuracy**: Documentation matches actual functionality 100%
3. **Approachability**: Tone is welcoming to individual developers
4. **Practical**: Every example solves a real, common problem
5. **Community**: Clear path for sharing and discovering templates

## Next Steps

1. Start with homepage rewrite to establish new tone and positioning
2. Create getting started guide with real, working example
3. Systematically replace hallucinated content with accurate documentation
4. Build example-driven content that shows real value
5. Prepare Actions system documentation for when it's implemented

This rework will transform Hypergen's documentation from confusing enterprise fantasy to practical developer tool reality.