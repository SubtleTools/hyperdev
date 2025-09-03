---
to: .moon/toolchain.yml
---
# https://moonrepo.dev/docs/config/toolchain
$schema: 'https://moonrepo.dev/schemas/toolchain.json'

<% if (packageManager === 'bun') { -%>
# Bun toolchain configuration
bun:
  version: '1.0.25'
  packageManager:
    install:
      - 'bun'
      - 'install'
    dedupe: 
      - 'bun'
      - 'pm'
      - 'cache'
      - 'rm'

<% } else if (packageManager === 'pnpm') { -%>
# Node.js with pnpm configuration
node:
  version: '20.11.0'
  packageManager: 'pnpm'
  pnpm:
    version: '8.15.0'

<% } else if (packageManager === 'yarn') { -%>
# Node.js with Yarn configuration
node:
  version: '20.11.0'
  packageManager: 'yarn'
  yarn:
    version: '4.0.2'

<% } else { -%>
# Node.js with npm configuration
node:
  version: '20.11.0'
  packageManager: 'npm'
  npm:
    version: '10.4.0'

<% } -%>
# TypeScript toolchain
typescript:
  version: '5.4.0'
  createMissingConfig: true
  routeOutDirToCache: true
  syncProjectReferences: true
  syncProjectReferencesToPaths: true

# Development tools integration
<% if (linter === 'eslint') { -%>
eslint:
  version: '8.57.0'

<% } -%>
<% if (formatter === 'prettier') { -%>
prettier:
  version: '3.2.4'

<% } -%>
<% if (testFramework === 'jest') { -%>
jest:
  version: '29.7.0'

<% } else if (testFramework === 'vitest') { -%>
vitest:
  version: '1.2.0'

<% } -%>
# Environment variables
env:
  NODE_ENV: 'development'
<% if (packageManager === 'bun') { -%>
  BUN_ENV: 'development'
<% } -%>