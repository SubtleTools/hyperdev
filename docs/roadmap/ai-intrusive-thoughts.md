# AI Intrusive Thoughts: Peripheral Awareness for Code Generation

## Concept Overview

Human developers have "intrusive thoughts" - spontaneous recall of relevant information without actively searching for it. AI agents lack this peripheral awareness, leading to duplication and inconsistency because they only know what's explicitly in context.

## The Problem

**Human Coding Experience**:
- Writing a function → brain automatically recalls "wait, didn't we implement something similar?"
- About to add a dependency → subconscious thought: "we already have lodash, do we need ramda?"
- Naming a component → pattern recognition: "we use `UserCard` not `User_Card`"

**AI Experience**: 
- Only knows what's explicitly in context
- No "passive memory" scanning for similar patterns
- Makes decisions in isolation, leading to duplication/inconsistency

## Solution: Context-Aware Intrusive Thoughts

Use background daemon + Claude Hooks to inject relevant "thoughts" when AI is about to make decisions.

### Implementation Concept

**PreToolUse Hook Flow**:
1. Claude about to create `calculateUserAge(birthDate)`
2. Hook detects function creation, queries daemon similarity index
3. Daemon finds existing `getAge(date)` with 85% similarity
4. Hook injects "intrusive thought": *"Similar function `getAge` exists in utils/date.ts"*
5. Claude can choose: reuse, explain difference, or proceed

## High-Value Use Cases

### Utility Function Duplication
- **Detection**: AST analysis + semantic embeddings
- **Example**: New `formatCurrency()` vs existing `formatMoney()`
- **Impact**: High - very common problem, easy to detect

### API Endpoint Patterns  
- **Detection**: Route pattern analysis + HTTP method consistency
- **Example**: New `POST /user-profile` vs existing `POST /users/profile`
- **Impact**: Medium - improves API consistency

### Component Naming Consistency
- **Detection**: Edit distance + project convention learning  
- **Example**: New `user_card.tsx` in project using `UserCard.tsx` pattern
- **Impact**: High - maintains design system consistency

### Dependency Management
- **Detection**: Functionality category matching
- **Example**: Adding `moment` when `date-fns` already exists
- **Impact**: Medium - prevents bundle bloat

## Implementation Strategy

### Similarity Detection Methods
- **Function signatures**: AST analysis + purpose embeddings
- **Naming patterns**: Edit distance + convention learning
- **Dependencies**: Functionality overlap analysis
- **Architecture patterns**: Structure similarity matching

### Threshold Management
- Start conservative (high similarity threshold)
- Learn from developer feedback (accept/dismiss)
- Different thresholds for different code types
- Configurable per project/team

### Integration Points
```json
{
  "PreToolUse": [
    {
      "matcher": "Write.*function|class|component",
      "command": "./scripts/intrusive-thoughts.sh"
    }
  ]
}
```

## Roadmap Position

**Phase 3 Enhancement**: Advanced AI assistance features

**Prerequisites**: 
- Background daemon infrastructure (Phase 2)
- Similarity analysis system
- Learning/feedback mechanisms

**Success Metrics**:
- Reduction in duplicate utility functions
- Improved naming consistency scores  
- Developer satisfaction with suggestions
- Low false positive rate (<10%)

## Future Enhancements

### ML Pattern Recognition
- Learn project-specific patterns over time
- Identify team coding preferences
- Suggest architectural improvements

### Team Knowledge Sharing
- "Sarah implemented something similar last week"
- Cross-project similarity detection
- Knowledge preservation when developers leave

### Predictive Assistance
- "You usually add error handling to network calls"
- "This pattern typically needs unit tests"
- "Similar components usually have loading states"

## Open Questions

1. **Noise Management**: How to avoid overwhelming developers with suggestions?
2. **Context Sensitivity**: When is similarity meaningful vs coincidental?
3. **Performance Impact**: Can we keep suggestions under 100ms?
4. **Learning Accuracy**: How quickly can we learn project-specific patterns?
5. **Team Dynamics**: How do suggestions affect code review discussions?

## Decision Points

- **Include in MVP**: No - too complex, unproven value
- **Phase 2 Research**: Begin similarity analysis experiments
- **Phase 3 Implementation**: Full intrusive thoughts system
- **Success Criteria**: 50% reduction in obvious duplications, <10% false positives