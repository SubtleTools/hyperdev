---
to: apps/<%= name %>/README.md
condition: projectType === 'cli'
---
# <%= h.changeCase.title(name.replace(/-/g, ' ')) %>

<%= description || `A command-line interface tool for ${name}` %>

## Installation

### Global Installation

```bash
<% if (packageManager === 'bun') { -%>
bun install -g <%= packageScope ? `@${packageScope}/` : '' %><%= name %>
<% } else if (packageManager === 'yarn') { -%>
yarn global add <%= packageScope ? `@${packageScope}/` : '' %><%= name %>
<% } else if (packageManager === 'pnpm') { -%>
pnpm install -g <%= packageScope ? `@${packageScope}/` : '' %><%= name %>
<% } else { -%>
npm install -g <%= packageScope ? `@${packageScope}/` : '' %><%= name %>
<% } -%>
```

### Local Installation

```bash
<% if (packageManager === 'bun') { -%>
bun add <%= packageScope ? `@${packageScope}/` : '' %><%= name %>
<% } else if (packageManager === 'yarn') { -%>
yarn add <%= packageScope ? `@${packageScope}/` : '' %><%= name %>
<% } else if (packageManager === 'pnpm') { -%>
pnpm add <%= packageScope ? `@${packageScope}/` : '' %><%= name %>
<% } else { -%>
npm install <%= packageScope ? `@${packageScope}/` : '' %><%= name %>
<% } -%>
```

## Usage

Once installed, you can use the `<%= cliName || name %>` command:

```bash
<%= cliName || name %> --help
```

### Commands

#### `hello [name]`

Say hello to someone.

```bash
<%= cliName || name %> hello Alice
<%= cliName || name %> hello --uppercase --color red Bob
```

Options:
- `-u, --uppercase` - Output in uppercase
- `-c, --color <color>` - Output color (default: blue)

#### `init [directory]`

Initialize a new project in the specified directory.

```bash
<%= cliName || name %> init my-project
<%= cliName || name %> init --template advanced --force
```

Options:
- `-t, --template <template>` - Project template to use (basic, advanced, minimal)
- `-f, --force` - Overwrite existing files
- `--dry-run` - Show what would be created without actually creating files

#### `config`

Manage configuration settings.

##### Get Configuration

```bash
<%= cliName || name %> config get
<%= cliName || name %> config get defaultFormat
<%= cliName || name %> config get preferences.theme
```

##### Set Configuration

```bash
<%= cliName || name %> config set defaultFormat yaml
<%= cliName || name %> config set verbose true
<%= cliName || name %> config set preferences.theme dark
```

##### List All Configuration

```bash
<%= cliName || name %> config list
```

#### `process <input>`

Process a file or directory and analyze its contents.

```bash
<%= cliName || name %> process file.txt
<%= cliName || name %> process directory/ --output analysis.json
<%= cliName || name %> process data.txt --format yaml --verbose
```

Options:
- `-o, --output <output>` - Output file or directory
- `--format <format>` - Output format (json, yaml, text)
- `-v, --verbose` - Verbose output

## Configuration

The CLI stores configuration in `~/.<%= name %>rc.json`. You can modify this file directly or use the `config` commands.

### Configuration Options

```json
{
  "defaultFormat": "json",
  "verbose": false,
  "defaultTemplate": "basic",
  "preferences": {
    "theme": "auto",
    "editor": "code"
  }
}
```

- `defaultFormat` - Default output format for commands
- `verbose` - Enable verbose output by default
- `defaultTemplate` - Default template for initialization
- `preferences.theme` - UI theme preference
- `preferences.editor` - Default editor for opening files

## Development

### Building

```bash
<% if (packageManager === 'bun') { -%>
bun run build
<% } else { -%>
npm run build
<% } -%>
```

### Testing

```bash
<% if (packageManager === 'bun') { -%>
<% if (testFramework === 'bun-test') { -%>
bun test
<% } else if (testFramework === 'vitest') { -%>
bun run test
<% } else if (testFramework === 'jest') { -%>
bun run test
<% } -%>
<% } else { -%>
npm test
<% } -%>
```

### Development Mode

Run the CLI in development mode without building:

```bash
<% if (packageManager === 'bun') { -%>
bun run dev:start
<% } else { -%>
npm run dev:start
<% } -%>
```

### Linting

```bash
<% if (packageManager === 'bun') { -%>
bun run lint
<% } else { -%>
npm run lint
<% } -%>
```

### Formatting

```bash
<% if (packageManager === 'bun') { -%>
bun run format
<% } else { -%>
npm run format
<% } -%>
```

## API

The CLI functionality is also available as a library:

```typescript
import { CLI } from '<%= packageScope ? `@${packageScope}/` : '' %><%= name %>';

const cli = new CLI();

// Use programmatically
await cli.hello('World', { uppercase: true });
await cli.init('./my-project', { template: 'advanced' });
await cli.processFile('./data.txt', { format: 'json', verbose: true });
```

### CLI Class Methods

#### `hello(name?: string, options?: HelloOptions): Promise<void>`

Say hello with optional formatting options.

#### `init(directory?: string, options?: InitOptions): Promise<void>`

Initialize a new project with template support.

#### `getConfig(key?: string): Promise<void>`

Get configuration values.

#### `setConfig(key: string, value: string): Promise<void>`

Set configuration values.

#### `listConfig(): Promise<void>`

List all configuration values.

#### `processFile(input: string, options?: ProcessOptions): Promise<void>`

Process files or directories with analysis output.

## Examples

### Basic Project Initialization

```bash
# Initialize with default settings
<%= cliName || name %> init my-app

# Use advanced template with force overwrite
<%= cliName || name %> init my-advanced-app --template advanced --force

# Preview what would be created
<%= cliName || name %> init test-project --dry-run
```

### File Processing

```bash
# Analyze a single file
<%= cliName || name %> process README.md

# Process directory with JSON output
<%= cliName || name %> process src/ --format json --output analysis.json

# Verbose processing with YAML output
<%= cliName || name %> process package.json --format yaml --verbose
```

### Configuration Management

```bash
# Set up preferences
<%= cliName || name %> config set defaultFormat yaml
<%= cliName || name %> config set verbose true
<%= cliName || name %> config set preferences.theme dark

# Check current settings
<%= cliName || name %> config list
```

## License

<%= license || 'MIT' %>

<% if (author) { -%>
## Author

<%= author %>
<% } -%>

<% if (homepage || repository) { -%>
## Links

<% if (homepage) { -%>
- [Homepage](<%= homepage %>)
<% } -%>
<% if (repository) { -%>
- [Repository](<%= repository %>)
<% } -%>
<% } -%>