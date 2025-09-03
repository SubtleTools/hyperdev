# API Reference

> Complete API documentation for @hypergen/monorepo-pack

## Table of Contents

- [Configuration Types](#configuration-types)
- [Validation API](#validation-api)
- [Performance API](#performance-api)
- [Composition API](#composition-api)
- [Error Handling](#error-handling)
- [Utilities](#utilities)

## Configuration Types

### MonorepoConfig

Main configuration interface for monorepo generation.

```typescript
interface MonorepoConfig {
  name: string;
  packageManager: PackageManager;
  linter: Linter;
  formatter: Formatter;
  testFramework: TestFramework;
  tools?: ToolsConfig;
  moon?: MoonConfig;
  computed?: ComputedProperties;
}
```

**Properties:**

- `name` - Project name (must be valid npm package name)
- `packageManager` - Package manager choice
- `linter` - Linting tool selection  
- `formatter` - Code formatting tool
- `testFramework` - Testing framework
- `tools` - Optional additional tools configuration
- `moon` - Moon workspace specific settings
- `computed` - Auto-generated computed properties

### PackageManager

```typescript
type PackageManager = 'bun' | 'npm' | 'yarn' | 'pnpm';
```

**Values:**
- `'bun'` - Ultra-fast JavaScript runtime and package manager
- `'npm'` - Node.js default package manager
- `'yarn'` - Yarn package manager (v1 and v2+ supported)
- `'pnpm'` - Performant npm with efficient disk usage

### Linter

```typescript
type Linter = 'eslint' | 'biome';
```

**Values:**
- `'eslint'` - Industry-standard JavaScript linter
- `'biome'` - Fast Rust-based linter and formatter

### Formatter

```typescript
type Formatter = 'prettier' | 'dprint' | 'biome-integrated';
```

**Values:**
- `'prettier'` - Popular, highly configurable code formatter
- `'dprint'` - Fast, incremental code formatter
- `'biome-integrated'` - Biome's built-in formatter (requires biome linter)

### TestFramework

```typescript
type TestFramework = 'vitest' | 'jest' | 'bun-test';
```

**Values:**
- `'vitest'` - Vite-powered testing framework
- `'jest'` - Battle-tested JavaScript testing framework
- `'bun-test'` - Bun's native testing framework (requires bun package manager)

### ToolsConfig

```typescript
interface ToolsConfig {
  typescript?: boolean;
  storybook?: boolean;
  docker?: boolean;
  [key: string]: any;
}
```

**Properties:**
- `typescript` - Enable TypeScript configuration
- `storybook` - Include Storybook setup for component development
- `docker` - Add Docker configuration files

### MoonConfig

```typescript
interface MoonConfig {
  toolchain?: 'node' | 'bun' | 'deno';
  projects?: string[];
  [key: string]: any;
}
```

**Properties:**
- `toolchain` - Moon toolchain selection
- `projects` - List of pre-configured project names

### ComputedProperties

Auto-generated properties for template rendering.

```typescript
interface ComputedProperties {
  hasLinting: boolean;
  hasFormatting: boolean;
  hasTesting: boolean;
  packageManagerInstallCommand: string;
  packageManagerRunCommand: string;
}
```

## Validation API

### validateToolCompatibility()

Validates a complete monorepo configuration for tool compatibility.

```typescript
function validateToolCompatibility(config: MonorepoConfig): ValidationResult;
```

**Parameters:**
- `config` - Complete monorepo configuration

**Returns:** `ValidationResult`

**Example:**
```typescript
const config: MonorepoConfig = {
  name: 'my-project',
  packageManager: 'bun',
  linter: 'biome',
  formatter: 'biome-integrated',
  testFramework: 'bun-test'
};

const result = validateToolCompatibility(config);
if (!result.valid) {
  console.error('Validation errors:', result.issues);
}
```

### validateMonorepoConfig()

Validates and sanitizes input configuration.

```typescript
function validateMonorepoConfig(config: Partial<MonorepoConfig>): {
  valid: boolean;
  errors: ValidationError[];
  sanitizedConfig: MonorepoConfig;
};
```

**Parameters:**
- `config` - Partial configuration to validate

**Returns:** Validation result with sanitized config

### isToolCombinationValid()

Quick validation for specific tool combination.

```typescript
function isToolCombinationValid(
  packageManager: string,
  linter: string,
  formatter: string,
  testFramework: string
): boolean;
```

**Parameters:**
- `packageManager` - Package manager name
- `linter` - Linter name
- `formatter` - Formatter name  
- `testFramework` - Test framework name

**Returns:** `true` if combination is valid

### getCompatibleFormatters()

Get compatible formatters for a linter.

```typescript
function getCompatibleFormatters(linter: string): string[];
```

**Parameters:**
- `linter` - Linter name

**Returns:** Array of compatible formatter names

### ValidationResult

```typescript
interface ValidationResult {
  valid: boolean;
  issues: ValidationIssue[];
  suggestions?: string[];
}

interface ValidationIssue {
  severity: 'error' | 'warning' | 'info';
  code: string;
  message: string;
  details?: string;
  fix?: string;
  affectedTools: string[];
}
```

## Performance API

### performanceOptimizer

Global performance optimization instance.

```typescript
class OptimizedTemplateComposer {
  async initialize(): Promise<void>;
  async composeOptimized(context: TemplateContext): Promise<{
    success: boolean;
    metrics: PerformanceMetrics;
    cacheStats: any;
  }>;
  async cleanup(): Promise<void>;
  getMetrics(): PerformanceMetrics;
  getCacheStats(): any;
}
```

### PerformanceMetrics

```typescript
interface PerformanceMetrics {
  startTime: number;
  endTime?: number;
  duration?: number;
  operation: string;
  memoryUsage?: NodeJS.MemoryUsage;
  cacheHits: number;
  cacheMisses: number;
  parallelOperations: number;
  filesProcessed: number;
}
```

### PerformanceBenchmark

Benchmarking utilities for performance testing.

```typescript
class PerformanceBenchmark {
  startGlobal(): void;
  endGlobal(): void;
  
  async benchmarkOperation<T>(
    combination: Partial<MonorepoConfig>,
    operationName: string,
    operation: () => Promise<T>
  ): Promise<{ result: T | null; benchmark: BenchmarkResult }>;
  
  generateReport(): BenchmarkReport;
  async exportReport(outputPath: string): Promise<void>;
}
```

## Composition API

### composeTemplate()

Main template composition function.

```typescript
async function composeTemplate(context: TemplateContext): Promise<CompositionResult>;
```

**Parameters:**
- `context` - Template generation context

**Returns:** `CompositionResult`

### CompositionResult

```typescript
interface CompositionResult {
  context: TemplateContext;
  includedFiles: string[];
  excludedFiles: string[];
  warnings: string[];
  errors: string[];
  actions: CompositionAction[];
}
```

### TemplateContext

```typescript
interface TemplateContext extends MonorepoConfig {
  // Additional context properties for template rendering
  [key: string]: any;
}
```

## Error Handling

### HypergenError

Base error class for all Hypergen-specific errors.

```typescript
class HypergenError extends Error {
  readonly code: ErrorCode;
  readonly severity: ErrorSeverity;
  readonly suggestions: ErrorSuggestion[];
  readonly context: ErrorContext;
  readonly userMessage: string;
  readonly recoverable: boolean;
  
  getDisplayMessage(): string;
  getErrorData(): Record<string, any>;
}
```

### ErrorCode

```typescript
enum ErrorCode {
  // Validation Errors
  INVALID_PROJECT_NAME = 'INVALID_PROJECT_NAME',
  INVALID_TOOL_COMBINATION = 'INVALID_TOOL_COMBINATION',
  MISSING_REQUIRED_FIELD = 'MISSING_REQUIRED_FIELD',
  PRESET_NOT_FOUND = 'PRESET_NOT_FOUND',
  
  // Template Errors
  TEMPLATE_FILE_NOT_FOUND = 'TEMPLATE_FILE_NOT_FOUND',
  TEMPLATE_PARSING_ERROR = 'TEMPLATE_PARSING_ERROR',
  TEMPLATE_RENDER_ERROR = 'TEMPLATE_RENDER_ERROR',
  COMPOSITION_FAILED = 'COMPOSITION_FAILED',
  
  // File System Errors
  DIRECTORY_ACCESS_ERROR = 'DIRECTORY_ACCESS_ERROR',
  FILE_WRITE_ERROR = 'FILE_WRITE_ERROR',
  FILE_READ_ERROR = 'FILE_READ_ERROR',
  PERMISSION_DENIED = 'PERMISSION_DENIED',
  
  // Dependencies/Network
  PACKAGE_MANAGER_NOT_FOUND = 'PACKAGE_MANAGER_NOT_FOUND',
  DEPENDENCY_RESOLUTION_ERROR = 'DEPENDENCY_RESOLUTION_ERROR',
  NETWORK_ERROR = 'NETWORK_ERROR',
  TIMEOUT_ERROR = 'TIMEOUT_ERROR',
  
  // Runtime Errors  
  UNEXPECTED_ERROR = 'UNEXPECTED_ERROR',
  ACTION_EXECUTION_FAILED = 'ACTION_EXECUTION_FAILED'
}
```

### ErrorSeverity

```typescript
enum ErrorSeverity {
  FATAL = 'fatal',
  ERROR = 'error',
  WARNING = 'warning', 
  INFO = 'info'
}
```

### ErrorSuggestion

```typescript
interface ErrorSuggestion {
  action: string;
  description: string;
  command?: string;
  url?: string;
  automated?: boolean;
}
```

### Error Creation Helpers

```typescript
function createValidationError(
  message: string, 
  field?: string, 
  value?: any
): ValidationError;

function createToolCompatibilityError(
  incompatibleTools: string[],
  validCombination?: Record<string, string>
): HypergenError;

function createFileSystemError(
  operation: string,
  filePath: string, 
  cause?: Error
): FileSystemError;
```

## Utilities

### withErrorHandling()

Utility for wrapping async operations with error handling.

```typescript
async function withErrorHandling<T>(
  operation: () => Promise<T>,
  context: string
): Promise<T>;
```

**Parameters:**
- `operation` - Async function to wrap
- `context` - Context description for errors

**Returns:** Result of operation or throws handled error

### validateInput()

Input validation utility with comprehensive rules.

```typescript
function validateInput(
  value: any,
  field: string,
  requirements: {
    required?: boolean;
    type?: 'string' | 'number' | 'boolean' | 'object';
    pattern?: RegExp;
    minLength?: number;
    maxLength?: number;
    allowedValues?: any[];
  }
): { valid: boolean; error?: ValidationError; sanitized?: any };
```

### Preset Utilities

```typescript
// Get all available presets
function getAvailablePresets(): PresetName[];

// Get preset configuration
function getPresetConfig(name: PresetName): PresetConfig;

// Apply preset to context
async function applyPreset(
  context: TemplateContext, 
  presetName: PresetName
): Promise<void>;
```

## Action Functions

### generateTemplate()

Main template generation orchestrator.

```typescript
async function generateTemplate(context: TemplateContext): Promise<CompositionResult>;
```

### preValidation()

Pre-generation validation with system checks.

```typescript
async function preValidation(context: TemplateContext): Promise<void>;
```

### filterTemplateFiles()

Determine which template files to include.

```typescript
async function filterTemplateFiles(context: TemplateContext): Promise<string[]>;
```

### prepareContext()

Prepare template context with computed properties.

```typescript
async function prepareContext(context: TemplateContext): Promise<void>;
```

### postGeneration()

Post-generation setup and cleanup.

```typescript
async function postGeneration(context: TemplateContext): Promise<void>;
```

## Environment Variables

Configuration through environment variables:

```bash
# Performance monitoring
HYPERGEN_PERF=true

# Memory profiling  
HYPERGEN_MEMORY_PROFILE=true

# Debug mode
HYPERGEN_DEBUG=true

# Cache configuration
HYPERGEN_CACHE_SIZE=100     # MB
HYPERGEN_CACHE_TTL=1800     # seconds

# Worker threads
HYPERGEN_MAX_WORKERS=4      # CPU cores to use
```

## TypeScript Integration

For TypeScript projects, import types directly:

```typescript
import type { 
  MonorepoConfig,
  ValidationResult,
  PerformanceMetrics,
  CompositionResult 
} from '@hypergen/monorepo-pack';
```

## Error Codes Reference

| Code | Description | Severity | Recoverable |
|------|-------------|----------|-------------|
| `INVALID_PROJECT_NAME` | Project name format invalid | ERROR | ✅ |
| `INVALID_TOOL_COMBINATION` | Tool combination not supported | ERROR | ✅ |
| `MISSING_REQUIRED_FIELD` | Required configuration missing | ERROR | ✅ |
| `PRESET_NOT_FOUND` | Preset name not recognized | ERROR | ✅ |
| `TEMPLATE_FILE_NOT_FOUND` | Template file missing | ERROR | ❌ |
| `COMPOSITION_FAILED` | Template composition error | ERROR | ❌ |
| `PACKAGE_MANAGER_NOT_FOUND` | Package manager not installed | WARNING | ✅ |
| `PERMISSION_DENIED` | File system permission error | ERROR | ❌ |
| `NETWORK_ERROR` | Network connectivity issue | WARNING | ✅ |
| `TIMEOUT_ERROR` | Operation timed out | WARNING | ✅ |

## Performance Benchmarks

Typical performance metrics by preset:

| Preset | Avg Generation Time | Memory Usage | Cache Hit Rate |
|--------|-------------------|--------------|----------------|
| `modern-bun` | 15-20s | 45-60MB | 75-85% |
| `traditional-node` | 25-30s | 60-80MB | 65-75% |  
| `performance` | 20-25s | 50-70MB | 80-90% |
| `enterprise` | 25-30s | 70-90MB | 70-80% |

## Advanced Configuration Examples

### Custom Validation Rules

```typescript
import { validateToolCompatibility } from '@hypergen/monorepo-pack';

const customConfig: MonorepoConfig = {
  name: 'my-custom-project',
  packageManager: 'bun',
  linter: 'biome',
  formatter: 'biome-integrated',
  testFramework: 'bun-test',
  tools: {
    typescript: true,
    storybook: true
  }
};

const validation = validateToolCompatibility(customConfig);
console.log('Is valid:', validation.valid);
```

### Performance Monitoring

```typescript
import { performanceMonitor, performanceOptimizer } from '@hypergen/monorepo-pack';

// Initialize performance systems
await performanceOptimizer.initialize();

// Generate with monitoring
const result = await performanceOptimizer.composeOptimized(context);
performanceMonitor.addMetrics(result.metrics);

// Analyze performance
const analysis = performanceMonitor.analyzePerformance();
console.log('Performance analysis:', analysis);

// Cleanup
await performanceOptimizer.cleanup();
```

### Error Handling

```typescript
import { errorHandler, withErrorHandling } from '@hypergen/monorepo-pack';

try {
  await withErrorHandling(async () => {
    // Your template generation logic
    return await generateTemplate(context);
  }, 'custom_generation');
} catch (error) {
  const handled = await errorHandler.handleError(error, 'template_generation');
  if (handled) {
    console.log('Error recovered:', handled);
  }
}
```