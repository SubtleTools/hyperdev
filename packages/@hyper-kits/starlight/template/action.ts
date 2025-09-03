import { action } from '../../../src/actions/index.js'
import type { ActionContext, ActionResult } from '../../../src/actions/index.js'
import path from 'path'

export default action({
  name: 'starlight',
  description: 'Create Astro/Starlight documentation site',
  
  async execute(context: ActionContext): Promise<ActionResult> {
    const { parameters, outputDir } = context
    
    // Default values for parameters
    const vars = {
      docsFolder: parameters.docsFolder || 'docs',
      projectName: parameters.projectName || 'My Project', 
      projectDescription: parameters.projectDescription || 'A documentation site',
      siteUrl: parameters.siteUrl || 'https://localhost:4321',
      githubRepo: parameters.githubRepo || '',
      enableTypedoc: parameters.enableTypedoc !== false,
      entryPoint: parameters.entryPoint || 'src/index.ts',
      enableOpenAPI: parameters.enableOpenAPI === true,
      enableKeyboardShortcuts: parameters.enableKeyboardShortcuts === true,
      enableAutoSidebar: parameters.enableAutoSidebar === true,
      enableScrollToTop: parameters.enableScrollToTop !== false,
      enableChangelogs: parameters.enableChangelogs === true,
      enableObsidian: parameters.enableObsidian === true,
    }
    
    return {
      success: true,
      files: [
        {
          path: path.join(outputDir, 'package.json'),
          content: generatePackageJson(vars)
        },
        {
          path: path.join(outputDir, 'README.md'),
          content: generateReadme(vars)
        }
      ],
      message: `Generated Starlight documentation site: ${vars.projectName}`
    }
  }
})

function generatePackageJson(vars: any): string {
  const deps: string[] = [
    '"astro-d2": "^0.8.0"',
    '"starlight-llms-txt": "^0.6.0"'
  ]
  
  if (!vars.enableAutoSidebar) {
    deps.push('"starlight-sidebar-topics": "^0.6.0"')
  }
  
  if (vars.enableTypedoc) {
    deps.push('"starlight-typedoc": "^0.21.3"')
  }
  
  // Add more conditional dependencies...
  
  return `{
  "name": "${vars.projectName}-docs",
  "version": "1.0.0",  
  "description": "Documentation site for ${vars.projectName}",
  "type": "module",
  "scripts": {
    "build": "astro build",
    "dev": "astro dev", 
    "preview": "astro preview",
    "astro": "astro"
  },
  "dependencies": {
    ${deps.join(',\n    ')}
  },
  "devDependencies": {
    "@astrojs/starlight": "^0.35.2",
    "@astrojs/tailwind": "^6.0.2", 
    "astro": "^5.13.3",
    "starlight-image-zoom": "^0.13.0",
    "starlight-links-validator": "^0.17.1",
    "tailwindcss": "^4.1.12"${vars.enableTypedoc ? ',\n    "typedoc": "^0.28.11",\n    "typedoc-plugin-markdown": "^4.8.1"' : ''}
  }
}`
}

function generateReadme(vars: any): string {
  return `# ${vars.projectName} Documentation

This is the documentation site for ${vars.projectName}, built with [Astro](https://astro.build/) and [Starlight](https://starlight.astro.build/).

## Development

\`\`\`bash
# Install dependencies  
bun install

# Start development server
bun run dev

# Build for production
bun run build
\`\`\`

## Features

- 📝 **Markdown Support**: Write content in Markdown with MDX support
- 🎨 **Beautiful UI**: Clean, modern design with dark mode support  
- 🔍 **Search**: Built-in search functionality
- 📱 **Mobile Friendly**: Responsive design that works on all devices
- 🚀 **Fast**: Built on Astro for optimal performance${vars.enableTypedoc ? '\n- 📖 **API Docs**: Automatic API documentation generation from TypeScript' : ''}${vars.enableOpenAPI ? '\n- 📋 **OpenAPI Docs**: Interactive API documentation from OpenAPI/Swagger specs' : ''}
`
}