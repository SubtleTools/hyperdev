---
to: apps/<%= name %>/moon.yml
condition: projectType === 'cli'
---
# https://moonrepo.dev/docs/config/project
$schema: 'https://moonrepo.dev/schemas/project.json'

type: 'application'
language: 'typescript'

dependsOn:
  - '^:build'

tasks:
  build:
    command: 'tsc --build'
    inputs:
      - 'src/**/*'
      - 'tsconfig.json'
      - 'package.json'
    outputs:
      - 'dist'
    options:
      cache: true
      persistent: false

  clean:
    command: 'rm -rf dist'
    options:
      cache: false

  dev:
    command: 'tsc --build --watch'
    options:
      cache: false
      persistent: true
      runInCI: false

  start:
    command: 'node dist/bin.js'
    deps:
      - 'build'
    inputs:
      - 'dist/**/*'
    options:
      cache: false

  dev:start:
    command: 'tsx src/bin.ts'
    inputs:
      - 'src/**/*'
    options:
      cache: false
      persistent: true
      runInCI: false

<% if (testFramework === 'vitest') { -%>
  test:
    command: 'vitest run'
    inputs:
      - 'src/**/*'
      - '**/*.test.{js,ts,tsx}'
      - '**/*.spec.{js,ts,tsx}'
      - 'vitest.config.ts'
      - 'package.json'
    options:
      cache: true
      
  test:watch:
    command: 'vitest'
    options:
      cache: false
      persistent: true
      runInCI: false

<% } else if (testFramework === 'jest') { -%>
  test:
    command: 'jest'
    inputs:
      - 'src/**/*'
      - '**/*.test.{js,ts,tsx}'
      - '**/*.spec.{js,ts,tsx}'
      - 'jest.config.js'
      - 'package.json'
    options:
      cache: true
      
<% } else if (testFramework === 'bun-test') { -%>
  test:
    command: 'bun test'
    inputs:
      - 'src/**/*'
      - '**/*.test.{js,ts,tsx}'
      - '**/*.spec.{js,ts,tsx}'
      - 'package.json'
    options:
      cache: true

<% } -%>
<% if (linter === 'eslint') { -%>
  lint:
    command: 'eslint --cache --ext .ts,.tsx,.js,.jsx src'
    inputs:
      - 'src/**/*'
      - '.eslintrc.js'
      - 'package.json'
    options:
      cache: true

<% } else if (linter === 'biome') { -%>
  lint:
    command: 'biome check src'
    inputs:
      - 'src/**/*'
      - 'biome.json'
      - 'package.json'
    options:
      cache: true

<% } -%>
<% if (formatter === 'prettier') { -%>
  format:
    command: 'prettier --write src'
    inputs:
      - 'src/**/*'
      - '.prettierrc.js'
      - 'package.json'
    options:
      cache: true

<% } else if (formatter === 'dprint') { -%>
  format:
    command: 'dprint fmt src'
    inputs:
      - 'src/**/*'
      - 'dprint.json'
      - 'package.json'
    options:
      cache: true

<% } else if (formatter === 'biome-integrated') { -%>
  format:
    command: 'biome format --write src'
    inputs:
      - 'src/**/*'
      - 'biome.json'
      - 'package.json'
    options:
      cache: true

<% } -%>
  typecheck:
    command: 'tsc --noEmit'
    inputs:
      - 'src/**/*'
      - 'tsconfig.json'
      - 'package.json'
    options:
      cache: true

  install:
    command: 'npm link'
    deps:
      - 'build'
    options:
      cache: false
      runInCI: false