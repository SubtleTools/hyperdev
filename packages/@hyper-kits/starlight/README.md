# hypergen-starlight

A Hypergen template for creating beautiful Astro/Starlight documentation sites with TypeDoc integration.

## Features

- 🚀 **Astro/Starlight**: Built on the fast and modern Astro framework with Starlight theme
- 📖 **TypeDoc Integration**: Automatic API documentation generation from TypeScript
- 📋 **OpenAPI Support**: Interactive API documentation from OpenAPI/Swagger specs
- 🎨 **Modern Design**: Clean, responsive design with dark mode support
- 🔍 **Built-in Search**: Full-text search functionality
- 📱 **Mobile Friendly**: Responsive design that works on all devices
- ⌨️ **Keyboard Shortcuts**: Optional keyboard navigation support
- 🔗 **Auto Sidebar**: Automatic sidebar generation from content structure
- 📈 **Changelog Support**: Built-in changelog documentation
- 🗂️ **Obsidian Integration**: Connect with Obsidian vaults

## Usage

### Install the template

```bash
npm install -g hypergen-starlight
```

### Generate a new documentation site

```bash
hypergen generate hypergen-starlight new
```

Or use the shorthand:

```bash
hypergen new hypergen-starlight
```

### Available options

The template will prompt you for:

- **Project folder name**: Where files will be generated
- **Project name**: Name for your documentation site
- **Project description**: Brief description of your project
- **Site URL**: Production URL for the site
- **GitHub repository**: Link to your GitHub repo (optional)
- **TypeDoc integration**: Generate API docs from TypeScript
- **TypeScript entry point**: Main file for API documentation
- **OpenAPI documentation**: Include OpenAPI/Swagger docs
- **Keyboard shortcuts**: Enable keyboard navigation
- **Auto sidebar**: Automatic sidebar generation
- **Scroll to top**: Add scroll-to-top button
- **Changelog support**: Include changelog documentation
- **Obsidian integration**: Connect with Obsidian vaults

## Template Structure

This template follows the Hypergen V8 naming conventions:

- Package name: `hypergen-starlight` (follows `hypergen-*` pattern)
- Repository: Tagged with `hypergen-template` topic
- Structure: Uses `template.yml` for single-template configuration

## Development

After generating your documentation site:

```bash
cd your-project-folder
bun install
bun run dev
```

## Requirements

- Node.js 16+
- Hypergen 8+
- Bun or npm for package management

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
