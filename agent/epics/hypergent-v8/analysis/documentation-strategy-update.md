# Documentation Strategy Update for New Taxonomy

## Overview
With the new Recipe/Tool/CodeMod taxonomy, all documentation must be updated to reflect the clearer mental model and eliminate confusion between processes and assets.

## Key Documentation Changes Required

### 1. Terminology Consistency
**Replace throughout all docs:**
- "Generator" → "Recipe" (when referring to processes)
- "Template" → "Template" (when referring to files) OR "Recipe" (when referring to processes)
- "Action" → "Action" (unchanged, but clarified as Tool capability)
- "Hygen" → "Hypergen" (existing migration continues)

### 2. Mental Model Explanation
All user-facing documentation must include:
- Clear taxonomy definitions
- Examples showing the difference between templates (files) and recipes (processes)
- Visual diagrams showing the relationship between Recipes → Tools → Assets
- Migration path from old mental model

### 3. CLI Documentation Updates
```bash
# OLD (confusing)
hypergen template:validate <template>

# NEW (clear)
hypergen recipe validate <recipe>
hypergen cookbook list
```

### 4. Cookbook Structure Documentation
Clear documentation of:
- Kit structure with cookbook organization
- Recipe.yml format and capabilities
- Tool coordination (Template/Action/CodeMod)
- Asset organization (templates/, actions/, codemods/)

### 5. Migration Guide
Comprehensive guide covering:
- Why the taxonomy changed (mental model benefits)
- How to convert existing templates to recipes
- Backward compatibility timeline
- Community support resources

### 6. Examples and Tutorials
All examples must:
- Use consistent new terminology
- Show clear separation between assets and processes
- Demonstrate composition capabilities
- Provide real-world cookbook examples

## Implementation Priority
1. **Critical**: CLI help text and error messages
2. **High**: Getting started guides and tutorials
3. **Medium**: API documentation and technical guides  
4. **Low**: Historical documentation and blog posts

This documentation strategy ensures users understand the clearer mental model while providing smooth migration from the old template-centric approach.