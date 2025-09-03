---
to: <%= projectFolder %>/README.md
---
# <%= projectName %> Documentation

This is the documentation site for <%= projectName %>, built with [Astro](https://astro.build/) and [Starlight](https://starlight.astro.build/).

## Development

```bash
# Install dependencies
bun install

# Start development server
bun run dev

# Build for production
bun run build

# Preview production build
bun run preview
```

## Features

- 📝 **Markdown Support**: Write content in Markdown with MDX support
- 🎨 **Beautiful UI**: Clean, modern design with dark mode support
- 🔍 **Search**: Built-in search functionality
- 📱 **Mobile Friendly**: Responsive design that works on all devices
- 🚀 **Fast**: Built on Astro for optimal performance
<% if (enableTypedoc) { %>- 📖 **API Docs**: Automatic API documentation generation from TypeScript<% } %>
<% if (enableOpenAPI) { %>- 📋 **OpenAPI Docs**: Interactive API documentation from OpenAPI/Swagger specs<% } %>
<% if (enableKeyboardShortcuts) { %>- ⌨️ **Keyboard Shortcuts**: Document and display keyboard shortcuts elegantly<% } %>
<% if (enableScrollToTop) { %>- ⬆️ **Scroll to Top**: Convenient scroll-to-top button for long pages<% } %>
<% if (enableAutoSidebar) { %>- 🗂️ **Auto Sidebar**: Automatically generated sidebar from your content structure<% } %>
<% if (enableChangelogs) { %>- 📅 **Changelog**: Built-in changelog documentation support<% } %>
<% if (enableObsidian) { %>- 🪨 **Obsidian Integration**: Publish your Obsidian vault as documentation<% } %>
- 🤖 **AI Ready**: Generates llms.txt for AI consumption
- 🔗 **Link Validation**: Automatic internal link validation
- 🖼️ **Image Zoom**: Click to zoom functionality for images

## Structure

```
src/
├── content/
│   ├── config.ts          # Content collection configuration
│   └── docs/              # Documentation pages
│       ├── index.mdx      # Homepage
│       ├── introduction.mdx
│       ├── installation.mdx
│       ├── quick-start.mdx
│       └── features/
│           └── core.mdx
public/                    # Static assets
```

## Customization

- Edit `astro.config.mjs` to modify site configuration
<% if (!enableAutoSidebar) { %>- Customize the sidebar in the `starlightSidebarTopics` plugin configuration<% } %>
- Add new pages by creating `.mdx` files in `src/content/docs/`
- Modify styling by editing `tailwind.config.mjs`
<% if (enableOpenAPI) { %>- Update `openapi.yaml` with your API specification<% } %>

## Deployment

This site can be deployed to any static hosting service:

### GitHub Pages
```bash
# Build the site
bun run build

# Deploy dist-docs/ directory to GitHub Pages
```

### Netlify/Vercel
- Connect your repository
- Set build command: `bun run build`
- Set publish directory: `dist-docs`

### Other Platforms
The built site in `dist-docs/` directory can be deployed anywhere that serves static files.

## Adding Content

### Documentation Pages
Create new `.mdx` files in `src/content/docs/` to add pages to your documentation.

### API Documentation
<% if (enableTypedoc) { %>API documentation is automatically generated from your TypeScript source code in `<%= entryPoint %>`.
<% } else { %>To add API documentation, enable TypeDoc in your `astro.config.mjs` configuration.<% } %>

<% if (enableOpenAPI) { %>### OpenAPI Documentation  
Update the `openapi.yaml` file with your API specification to generate interactive API documentation.<% } %>