---
to: apps/README.md
condition: preset !== 'minimal'
---
# Applications

This directory contains end-user applications built with packages from the monorepo.

## Structure

Each application should have:

- `package.json` - Application configuration
- `moon.yml` - Moon project configuration
- `src/` - Application source code
- Build and deployment configurations

## Application Types

Common application types in this monorepo:
- Web applications (React, Vue, etc.)
- CLI tools and utilities
- Desktop applications (Electron, Tauri)
- Server applications (Express, Fastify)

## Best Practices

- Keep applications thin - extract business logic to packages
- Use workspace dependencies efficiently
- Configure proper build targets
- Include environment-specific configurations