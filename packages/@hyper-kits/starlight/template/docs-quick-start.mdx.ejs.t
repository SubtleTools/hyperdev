---
to: <%= projectFolder %>/src/content/docs/quick-start.mdx
---
---
title: Quick Start
description: Get started with <%= projectName %> in minutes
---

# Quick Start

This guide will help you get up and running with <%= projectName %> in just a few minutes.

## Step 1: Installation

First, install <%= projectName %> in your project:

```bash
bun install <%= projectName %>
```

## Step 2: Basic Setup

Create a basic configuration:

```typescript
import { <%= projectName %> } from '<%= projectName %>';

const config = {
  // Add your configuration here
};

const instance = new <%= projectName %>(config);
```

## Step 3: Your First Example

Here's a simple example to get you started:

```typescript
// Your first example with <%= projectName %>
await instance.initialize();

// Use the instance
const result = await instance.someMethod();
console.log(result);
```

## What's Next?

Now that you have <%= projectName %> running, you can:

- [Learn about the core features](/features/core/)
- [Read the full documentation](/introduction/)
<% if (enableTypedoc) { %>- [Explore the API reference](/api/readme/)<% } %>

## Getting Help

If you need help or have questions:

<% if (githubRepo) { %>- [Open an issue on GitHub](<%= githubRepo %>/issues)<% } %>
- Check out the [Introduction](/introduction/) for more details
- Browse the documentation sections in the sidebar