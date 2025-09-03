---
to: packages/<%= name %>/package.json
condition: projectType === 'library'
---
{
  "name": "<%= packageScope ? `@${packageScope}/` : '' %><%= name %>",
  "version": "0.1.0",
  "description": "<%= description || `A library package for ${name}` %>",
  "type": "module",
  "main": "./dist/index.js",
  "module": "./esm/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "import": "./esm/index.js",
      "require": "./dist/index.js",
      "types": "./dist/index.d.ts"
    }
  },
  "files": [
    "dist",
    "esm",
    "README.md",
    "LICENSE"
  ],
  "scripts": {
    "build": "tsc --build && tsc --build tsconfig.esm.json",
    "clean": "rm -rf dist esm",
    "dev": "tsc --build --watch",
<% if (testFramework === 'vitest') { -%>
    "test": "vitest run",
    "test:watch": "vitest",
    "test:ui": "vitest --ui",
    "coverage": "vitest run --coverage",
<% } else if (testFramework === 'jest') { -%>
    "test": "jest",
    "test:watch": "jest --watch",
    "coverage": "jest --coverage",
<% } else if (testFramework === 'bun-test') { -%>
    "test": "bun test",
    "test:watch": "bun test --watch",
<% } -%>
<% if (linter === 'eslint') { -%>
    "lint": "eslint --cache --ext .ts,.tsx,.js,.jsx src",
    "lint:fix": "eslint --cache --ext .ts,.tsx,.js,.jsx src --fix",
<% } else if (linter === 'biome') { -%>
    "lint": "biome check src",
    "lint:fix": "biome check --apply src",
<% } -%>
<% if (formatter === 'prettier') { -%>
    "format": "prettier --write src",
    "format:check": "prettier --check src",
<% } else if (formatter === 'dprint') { -%>
    "format": "dprint fmt src",
    "format:check": "dprint check src",
<% } else if (formatter === 'biome-integrated') { -%>
    "format": "biome format --write src",
    "format:check": "biome format src",
<% } -%>
    "typecheck": "tsc --noEmit",
    "prepare": "npm run build"
  },
  "keywords": [
    "typescript",
    "library"<% if (keywords) { %>,
    <%= keywords.split(',').map(k => `"${k.trim()}"`).join(',\n    ') %>
<% } %>
  ],
  "author": "<%= author || '' %>",
  "license": "<%= license || 'MIT' %>",
<% if (homepage) { -%>
  "homepage": "<%= homepage %>",
<% } -%>
<% if (repository) { -%>
  "repository": {
    "type": "git",
    "url": "<%= repository %>"
  },
<% } -%>
<% if (bugs) { -%>
  "bugs": {
    "url": "<%= bugs %>"
  },
<% } -%>
  "devDependencies": {
    "typescript": "^5.0.0",
<% if (testFramework === 'vitest') { -%>
    "vitest": "^2.0.0",
    "@vitest/ui": "^2.0.0",
    "@vitest/coverage-v8": "^2.0.0",
<% } else if (testFramework === 'jest') { -%>
    "jest": "^29.0.0",
    "@types/jest": "^29.0.0",
    "ts-jest": "^29.0.0",
<% } else if (testFramework === 'bun-test') { -%>
    "@types/bun": "latest",
<% } -%>
<% if (linter === 'eslint') { -%>
    "eslint": "^8.0.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
<% } else if (linter === 'biome') { -%>
    "@biomejs/biome": "^1.8.0",
<% } -%>
<% if (formatter === 'prettier') { -%>
    "prettier": "^3.0.0",
<% } else if (formatter === 'dprint') { -%>
    "dprint": "^0.47.0",
<% } -%>
    "@types/node": "^20.0.0"
  },
  "engines": {
<% if (packageManager === 'bun') { -%>
    "bun": ">=1.0.0",
<% } -%>
    "node": ">=18.0.0"
  },
<% if (packageManager !== 'npm') { -%>
  "packageManager": "<%= packageManager %>@<%= packageManager === 'bun' ? '1.0.0' : packageManager === 'yarn' ? '4.0.0' : '9.0.0' %>",
<% } -%>
  "publishConfig": {
    "access": "public"
  }
}