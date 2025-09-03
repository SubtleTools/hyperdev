---
to: <%= projectFolder %>/src/content/docs/features/core.mdx
---
---
title: Core Features
description: Core functionality of <%= projectName %>
---

# Core Features

<%= projectName %> provides several core features that make it powerful and easy to use.

## Feature 1: Core Functionality

Description of the main feature...

```typescript
import { <%= projectName %> } from '<%= projectName %>';

// Example usage
const instance = new <%= projectName %>({
  // Configuration options
});
```

## Feature 2: Advanced Configuration

You can configure <%= projectName %> with various options:

```typescript
const config = {
  option1: 'value1',
  option2: {
    nested: 'value'
  }
};
```

## Feature 3: Integration Support

<%= projectName %> integrates well with other tools and frameworks:

- ✅ TypeScript support out of the box
- ✅ Works with modern build tools
- ✅ Compatible with popular frameworks

## Best Practices

Here are some best practices when using <%= projectName %>:

1. Always validate your configuration
2. Use TypeScript for better type safety
3. Follow the recommended project structure
4. Keep your dependencies up to date

## Examples

### Basic Example

```typescript
// Basic usage example
const result = await instance.process();
```

### Advanced Example

```typescript
// Advanced usage with custom configuration
const advanced = new <%= projectName %>({
  advanced: true,
  customOptions: {
    // Custom configuration
  }
});

const result = await advanced.processAdvanced();
```

## Related

- [Installation Guide](/installation/)
- [Quick Start](/quick-start/)
<% if (enableTypedoc) { %>- [API Reference](/api/readme/)<% } %>