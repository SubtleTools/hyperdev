---
to: packages/README.md
---
# Packages

This directory contains shared packages and libraries that can be consumed by applications and other packages.

## Structure

Each package should have:

- `package.json` - Package configuration
- `moon.yml` - Moon project configuration  
- `src/` - Source code
- `tsconfig.json` - TypeScript configuration
- `README.md` - Package documentation

## Creating a New Package

1. Create a new directory: `mkdir packages/my-package`
2. Initialize with package.json and moon.yml
3. Add source code in `src/`
4. Run `moon sync` to register the project

## Best Practices

- Use semantic versioning
- Write comprehensive tests
- Document public APIs
- Follow consistent naming conventions
- Minimize external dependencies