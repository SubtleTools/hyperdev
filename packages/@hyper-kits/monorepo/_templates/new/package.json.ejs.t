---
to: package.json
---
{
  "private": true,
  "name": "<%= name %>",
  "description": "<%= description %>",
  "version": "0.1.0",
  "type": "module",
  "workspaces": [
<% if (preset === 'minimal') { -%>
    "packages/*"
<% } else { -%>
    "apps/*",
    "packages/*",
    "libs/*"
<% } -%>
  ],
  "scripts": {
<% if (packageManager === 'bun') { -%>
    "install": "bun install",
    "update": "bun update",
<% } else if (packageManager === 'pnpm') { -%>
    "install": "pnpm install",
    "update": "pnpm update -i --latest -r",
<% } else if (packageManager === 'yarn') { -%>
    "install": "yarn install",
    "update": "yarn upgrade-interactive --latest",
<% } else { -%>
    "install": "npm install",
    "update": "npm update",
<% } -%>
    "build": "moon run :build",
    "clean": "moon run :clean",
    "dev": "moon run :dev",
<% if (testFramework === 'vitest') { -%>
    "test": "moon run :test",
    "test:watch": "moon run :test:watch",
<% } else if (testFramework === 'jest') { -%>
    "test": "moon run :test",
    "test:watch": "moon run :test --watch",
<% } else if (testFramework === 'bun-test') { -%>
    "test": "bun test",
    "test:watch": "bun test --watch",
<% } -%>
<% if (linter === 'eslint') { -%>
    "lint": "moon run :lint",
    "lint:fix": "moon run :lint --fix",
<% } else if (linter === 'biome') { -%>
    "lint": "moon run :lint",
    "lint:fix": "moon run :lint --fix",
<% } -%>
<% if (formatter === 'prettier') { -%>
    "format": "moon run :format",
    "format:check": "moon run :format --check",
<% } else if (formatter === 'dprint') { -%>
    "format": "dprint fmt",
    "format:check": "dprint check",
<% } else if (formatter === 'biome-integrated') { -%>
    "format": "biome format --write .",
    "format:check": "biome format .",
<% } -%>
    "typecheck": "moon run :typecheck",
    "check": "moon run :typecheck :test :lint",
    "release": "echo 'Configure your release process here'"
  },
<% if (packageManager === 'bun') { -%>
  "packageManager": "bun@latest",
<% } else if (packageManager === 'pnpm') { -%>
  "packageManager": "pnpm@latest",
<% } else if (packageManager === 'yarn') { -%>
  "packageManager": "yarn@stable",
<% } -%>
  "devDependencies": {
    "@moonrepo/cli": "^1.20.1",
<% if (linter === 'eslint') { -%>
    "eslint": "^8.57.0",
    "eslint-config-moon": "^2.0.15",
<% if (packageManager === 'bun') { -%>
    "@types/bun": "latest",
<% } else { -%>
    "@types/node": "^20.11.16",
<% } -%>
<% } else if (linter === 'biome') { -%>
    "@biomejs/biome": "^1.5.0",
<% } -%>
<% if (formatter === 'prettier') { -%>
    "prettier": "^3.2.4",
    "prettier-config-moon": "^1.1.2",
<% } else if (formatter === 'dprint') { -%>
    "dprint": "^0.45.0",
<% } -%>
<% if (testFramework === 'jest') { -%>
    "@types/jest": "^29.5.12",
    "jest": "^29.7.0",
    "jest-preset-moon": "^2.0.7",
<% } else if (testFramework === 'vitest') { -%>
    "vitest": "^1.2.0",
<% } else if (testFramework === 'bun-test' && packageManager === 'bun') { -%>
    "@types/bun": "latest",
<% } -%>
    "typescript": "^5.4.0",
    "tsconfig-moon": "^1.3.0"
  },
<% if (packageManager === 'bun') { -%>
  "trustedDependencies": [
    "@moonrepo/cli"
  ],
<% } -%>
  "engines": {
<% if (packageManager === 'bun') { -%>
    "bun": ">=1.0.0"
<% } else { -%>
    "node": ">=20.0.0"
<% } -%>
  }
}