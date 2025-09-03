---
to: README.md
condition: includeDocumentation === true
---
# <%= name %>

<%= description %>

## Quick Start

### Prerequisites

<% if (packageManager === 'bun') { -%>
- [Bun](https://bun.sh/) (latest version)
<% } else if (packageManager === 'pnpm') { -%>
- [Node.js](https://nodejs.org/) (v20 or higher)
- [pnpm](https://pnpm.io/) (latest version)
<% } else if (packageManager === 'yarn') { -%>
- [Node.js](https://nodejs.org/) (v20 or higher)
- [Yarn](https://yarnpkg.com/) (v4 or higher)
<% } else { -%>
- [Node.js](https://nodejs.org/) (v20 or higher)
<% } -%>
- [Moon](https://moonrepo.dev/) (latest version)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd <%= name %>
   ```

2. Install dependencies:
   ```bash
<% if (packageManager === 'bun') { -%>
   bun install
<% } else if (packageManager === 'pnpm') { -%>
   pnpm install
<% } else if (packageManager === 'yarn') { -%>
   yarn install
<% } else { -%>
   npm install
<% } -%>
   ```

3. Run initial setup:
   ```bash
   moon sync
   ```

### Development Commands

| Command | Description |
|---------|-------------|
| `moon run :build` | Build all packages |
| `moon run :dev` | Start development mode |
| `moon run :test` | Run all tests |
<% if (linter === 'eslint' || linter === 'biome') { -%>
| `moon run :lint` | Lint all code |
<% } -%>
<% if (formatter === 'prettier' || formatter === 'dprint' || formatter === 'biome-integrated') { -%>
| `moon run :format` | Format all code |
<% } -%>
| `moon run :typecheck` | Type check all code |
| `moon run :clean` | Clean build artifacts |

### Project Structure

```
<%= name %>/
├── .moon/                  # Moon configuration
│   ├── workspace.yml      # Workspace settings
│   └── toolchain.yml      # Tool versions
├── packages/              # Shared packages/libraries
<% if (preset !== 'minimal') { -%>
├── apps/                  # Applications
├── libs/                  # Internal libraries
<% } -%>
├── docs/                  # Documentation
<% if (includeVSCodeSettings) { -%>
├── .vscode/               # VS Code settings
<% } -%>
<% if (includeGitHubActions) { -%>
├── .github/               # GitHub Actions
<% } -%>
└── package.json           # Root package configuration
```

## Technology Stack

<% if (packageManager === 'bun') { -%>
- **Runtime**: Bun
<% } else { -%>
- **Runtime**: Node.js v20+
<% } -%>
- **Build System**: [Moon](https://moonrepo.dev/)
- **Language**: TypeScript
<% if (packageManager !== 'npm') { -%>
- **Package Manager**: <%= packageManager %>
<% } -%>
<% if (linter === 'eslint') { -%>
- **Linter**: ESLint
<% } else if (linter === 'biome') { -%>
- **Linter**: Biome
<% } -%>
<% if (formatter === 'prettier') { -%>
- **Formatter**: Prettier
<% } else if (formatter === 'dprint') { -%>
- **Formatter**: dprint
<% } else if (formatter === 'biome-integrated') { -%>
- **Formatter**: Biome (integrated)
<% } -%>
<% if (testFramework === 'vitest') { -%>
- **Testing**: Vitest
<% } else if (testFramework === 'jest') { -%>
- **Testing**: Jest
<% } else if (testFramework === 'bun-test') { -%>
- **Testing**: Bun Test
<% } -%>

## Development

### Adding a New Package

1. Create a new directory in the appropriate folder (`packages/`, `apps/`, or `libs/`)
2. Add a `package.json` and `moon.yml` configuration
3. Run `moon sync` to register the new project

### Running Tasks

Moon provides powerful task running capabilities:

```bash
# Run a specific task for all projects
moon run :build

# Run a task for a specific project
moon run my-package:build

# Run tasks only for affected projects
moon run :test --affected

# Run with concurrency control
moon run :lint --concurrency 4
```

### Pre-commit Hooks

<% if (setupGitHooks) { -%>
This project uses Husky for Git hooks. The pre-commit hook will automatically:

- Run linting on affected files
- Run formatting on affected files  
- Run type checking on affected files

To skip hooks during development:
```bash
git commit --no-verify
```
<% } else { -%>
Consider enabling Git hooks by setting `setupGitHooks: true` in your configuration.
<% } -%>

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Ensure all checks pass: `moon run :check`
5. Commit your changes: `git commit -m 'feat: add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Resources

- [Moon Documentation](https://moonrepo.dev/docs)
- [TypeScript Documentation](https://www.typescriptlang.org/docs/)
<% if (linter === 'eslint') { -%>
- [ESLint Documentation](https://eslint.org/docs/)
<% } else if (linter === 'biome') { -%>
- [Biome Documentation](https://biomejs.dev/guides/getting-started/)
<% } -%>
<% if (testFramework === 'vitest') { -%>
- [Vitest Documentation](https://vitest.dev/guide/)
<% } else if (testFramework === 'jest') { -%>
- [Jest Documentation](https://jestjs.io/docs/getting-started)
<% } -%>