---
to: <%= projectFolder %>/src/content/docs/index.mdx
---
---
title: <%= projectName %>
description: <%= projectDescription %>
template: splash
hero:
  tagline: <%= projectDescription %>
  actions:
    - text: Get Started
      link: /introduction/
      icon: right-arrow
      variant: primary<% if (githubRepo) { %>
    - text: View on GitHub
      link: <%= githubRepo %>
      icon: external<% } %>
---

import { CardGrid, Card } from '@astrojs/starlight/components';

<CardGrid>
<Card title="🚀 Getting Started" icon="rocket">
Get up and running quickly with our comprehensive setup guide and examples.
</Card>

<Card title="📚 Documentation" icon="open-book">
Detailed guides, tutorials, and reference materials to help you make the most of this project.
</Card>

<% if (enableTypedoc) { %><Card title="🔧 API Reference" icon="setting">
Complete API documentation generated from TypeScript source code.
</Card><% } %>

<Card title="💡 Examples" icon="star">
Real-world examples and use cases to inspire your implementation.
</Card>
</CardGrid>

## Quick Start

Ready to dive in? Check out our [installation guide](/installation/) to get started, or jump straight to the [quick start tutorial](/quick-start/) for a hands-on introduction.