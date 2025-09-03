---
to: packages/<%= name %>/README.md
condition: projectType === 'library'
---
# <%= h.changeCase.title(name.replace(/-/g, ' ')) %>

<%= description || `A TypeScript library package for ${name}` %>

## Installation

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

### Basic Usage

```typescript
import { add, multiply, <%= h.changeCase.pascal(name) %> } from '<%= packageScope ? `@${packageScope}/` : '' %><%= name %>';

// Using utility functions
const sum = add(2, 3); // 5
const product = multiply(4, 5); // 20

// Using the main class
const lib = new <%= h.changeCase.pascal(name) %>({
  debug: true,
  prefix: 'my-app'
});

const result = lib.calculate(10, 5); // 15 (with debug logging)
```

### Configuration

The `<%= h.changeCase.pascal(name) %>` class accepts an optional configuration object:

```typescript
interface <%= h.changeCase.pascal(name) %>Config {
  /** Enable debug mode for logging */
  debug?: boolean;
  /** Custom prefix for operations */
  prefix?: string;
}
```

### API Reference

#### Functions

##### `add(a: number, b: number): number`

Adds two numbers and returns the result.

**Parameters:**
- `a` - First number to add
- `b` - Second number to add

**Returns:** The sum of `a` and `b`

##### `multiply(a: number, b: number): number`

Multiplies two numbers and returns the result.

**Parameters:**
- `a` - First number to multiply
- `b` - Second number to multiply

**Returns:** The product of `a` and `b`

#### Classes

##### `<%= h.changeCase.pascal(name) %>`

Main class providing enhanced calculation functionality with optional logging.

**Constructor:**
```typescript
new <%= h.changeCase.pascal(name) %>(config?: <%= h.changeCase.pascal(name) %>Config)
```

**Methods:**

###### `calculate(a: number, b: number): number`

Performs addition with optional debug logging.

**Parameters:**
- `a` - First operand
- `b` - Second operand

**Returns:** The sum of `a` and `b`

###### `getConfig(): <%= h.changeCase.pascal(name) %>Config`

Returns a copy of the current configuration.

**Returns:** The current configuration object

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