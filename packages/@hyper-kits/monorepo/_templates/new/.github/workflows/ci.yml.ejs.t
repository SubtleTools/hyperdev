---
to: .github/workflows/ci.yml
condition: includeGitHubActions === true
---
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint-and-typecheck:
    name: Lint and Typecheck
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

<% if (packageManager === 'bun') { -%>
      - name: Setup Bun
        uses: oven-sh/setup-bun@v1
        with:
          bun-version: latest

      - name: Install dependencies
        run: bun install --frozen-lockfile

<% } else if (packageManager === 'pnpm') { -%>
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Setup pnpm
        uses: pnpm/action-setup@v2
        with:
          version: latest
          run_install: false

      - name: Get pnpm store directory
        shell: bash
        run: echo "STORE_PATH=$(pnpm store path --silent)" >> $GITHUB_ENV

      - name: Setup pnpm cache
        uses: actions/cache@v3
        with:
          path: ${{ env.STORE_PATH }}
          key: ${{ runner.os }}-pnpm-store-${{ hashFiles('**/pnpm-lock.yaml') }}
          restore-keys: |
            ${{ runner.os }}-pnpm-store-

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

<% } else if (packageManager === 'yarn') { -%>
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'yarn'

      - name: Install dependencies
        run: yarn install --immutable

<% } else { -%>
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

<% } -%>
      - name: Setup Moon
        uses: moonrepo/setup-moon-action@v1
        with:
          auto-install: true

<% if (linter === 'eslint' || linter === 'biome') { -%>
      - name: Run linting
        run: moon run :lint

<% } -%>
      - name: Run type checking
        run: moon run :typecheck

  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

<% if (packageManager === 'bun') { -%>
      - name: Setup Bun
        uses: oven-sh/setup-bun@v1
        with:
          bun-version: latest

      - name: Install dependencies
        run: bun install --frozen-lockfile

<% } else if (packageManager === 'pnpm') { -%>
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Setup pnpm
        uses: pnpm/action-setup@v2
        with:
          version: latest
          run_install: false

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

<% } else if (packageManager === 'yarn') { -%>
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'yarn'

      - name: Install dependencies
        run: yarn install --immutable

<% } else { -%>
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

<% } -%>
      - name: Setup Moon
        uses: moonrepo/setup-moon-action@v1
        with:
          auto-install: true

<% if (testFramework === 'vitest') { -%>
      - name: Run tests
        run: moon run :test

<% } else if (testFramework === 'jest') { -%>
      - name: Run tests
        run: moon run :test --coverage

      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/lcov.info
          fail_ci_if_error: false

<% } else if (testFramework === 'bun-test') { -%>
      - name: Run tests
        run: bun test

<% } -%>
  build:
    name: Build
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

<% if (packageManager === 'bun') { -%>
      - name: Setup Bun
        uses: oven-sh/setup-bun@v1
        with:
          bun-version: latest

      - name: Install dependencies
        run: bun install --frozen-lockfile

<% } else if (packageManager === 'pnpm') { -%>
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Setup pnpm
        uses: pnpm/action-setup@v2
        with:
          version: latest
          run_install: false

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

<% } else if (packageManager === 'yarn') { -%>
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'yarn'

      - name: Install dependencies
        run: yarn install --immutable

<% } else { -%>
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

<% } -%>
      - name: Setup Moon
        uses: moonrepo/setup-moon-action@v1
        with:
          auto-install: true

      - name: Build packages
        run: moon run :build

      - name: Cache build artifacts
        uses: actions/cache/save@v3
        with:
          path: |
            **/dist/
            **/build/
            **/.moon/cache/
          key: ${{ runner.os }}-build-${{ github.sha }}