# @hypergen/monorepo-pack

> 🚀 **High-Performance Monorepo Generator** - Create production-ready TypeScript monorepos in under 30 seconds

A powerful Hypergen V8 template package for generating Moon-based TypeScript monorepos with intelligent tooling composition, comprehensive validation, and performance optimizations.

## ✨ Features

- **🎯 16 Validated Tool Combinations**: Mix and match ESLint/Biome, Prettier/dprint/Biome-integrated, Vitest/Jest/Bun Test
- **🚀 Performance Optimized**: Template generation in <30 seconds with parallel processing and smart caching
- **🌙 Moon Integration**: Full Moon workspace configuration with optimized build tasks and toolchains
- **⚡ TypeScript Ready**: Composite project setup with path mapping for lightning-fast builds
- **📦 Universal Package Manager**: Intelligent support for bun, npm, yarn, and pnpm with automatic detection
- **🎨 Smart Presets**: Quick setup for common scenarios with automatic tool compatibility validation
- **🔧 Error Recovery**: Comprehensive error handling with actionable suggestions and graceful fallbacks
- **🎯 Zero Configuration**: Works out of the box with sensible defaults, fully customizable when needed

## 🛠️ Supported Tool Combinations

All combinations are validated for compatibility and performance. Invalid combinations are automatically detected with suggested alternatives.

### 📋 Linting
- **ESLint**: Industry-standard linting with extensive plugin ecosystem
- **Biome**: Rust-powered fast linting and formatting in one tool

### ✨ Formatting  
- **Prettier**: Popular, highly configurable code formatter
- **dprint**: Incremental, multi-language formatter with excellent performance
- **Biome Integrated**: Built-in Biome formatter for unified toolchain

### 🧪 Testing
- **Vitest**: Vite-powered testing with excellent TypeScript and ESM support
- **Jest**: Battle-tested framework with extensive ecosystem
- **Bun Test**: Native Bun testing with exceptional speed

### 📦 Package Managers
- **Bun**: Ultra-fast JavaScript runtime and package manager (recommended)
- **npm**: Node.js default package manager
- **yarn**: Classic and Berry versions supported
- **pnpm**: Efficient disk space usage with content-addressable storage

## 🚀 Quick Start

### Installation & Usage

```bash
# Using Hypergen CLI (recommended)
hypergen monorepo new my-awesome-project

# Using npx
npx @hypergen/monorepo-pack my-awesome-project

# With specific preset
hypergen monorepo new my-project --preset modern-bun

# Interactive mode with validation
hypergen monorepo new my-project --interactive
```

### One-Line Examples

```bash
# Modern Bun stack (fastest)
hypergen monorepo new fast-app --preset modern-bun

# Traditional Node.js stack (most compatible)  
hypergen monorepo new stable-app --preset traditional-node

# High-performance stack for large codebases
hypergen monorepo new big-app --preset performance

# Enterprise stack with full tooling
hypergen monorepo new enterprise-app --preset enterprise
```

## 🎨 Presets

### `modern-bun` (Recommended)
> **Best for:** New projects, maximum performance, cutting-edge tooling

- **Package Manager:** Bun (fastest install & runtime)
- **Linter:** Biome (fastest linting) 
- **Formatter:** Biome Integrated (unified toolchain)
- **Testing:** Bun Test (fastest test execution)
- **Build Time:** ~15-20 seconds
- **Best For:** Modern apps, startups, performance-critical projects

```bash
hypergen monorepo new my-app --preset modern-bun
```

### `traditional-node` 
> **Best for:** Enterprise environments, maximum ecosystem compatibility

- **Package Manager:** npm (universal compatibility)
- **Linter:** ESLint (extensive plugin ecosystem)
- **Formatter:** Prettier (mature, widely adopted)
- **Testing:** Vitest (excellent TypeScript support)
- **Build Time:** ~25-30 seconds  
- **Best For:** Enterprise, teams with existing ESLint configs

```bash
hypergen monorepo new my-app --preset traditional-node
```

### `performance`
> **Best for:** Large codebases, CI/CD optimization

- **Package Manager:** pnpm (efficient disk usage)
- **Linter:** Biome (fastest linting)
- **Formatter:** Biome Integrated (unified pipeline)
- **Testing:** Vitest (fast, efficient)
- **Build Time:** ~20-25 seconds
- **Best For:** Large teams, extensive monorepos, CI optimization

```bash
hypergen monorepo new my-app --preset performance  
```

### `enterprise`
> **Best for:** Enterprise environments with strict requirements

- **Package Manager:** yarn (enterprise-grade features)
- **Linter:** ESLint (comprehensive rules, audit compliance)
- **Formatter:** Prettier (consistent formatting standards)
- **Testing:** Jest (battle-tested, extensive reporting)
- **Build Time:** ~25-30 seconds
- **Best For:** Banks, large corporations, regulated industries

```bash
hypergen monorepo new my-app --preset enterprise
```

## 🎛️ Custom Configuration

### Interactive Mode

```bash
hypergen monorepo new my-project --interactive
```

Provides step-by-step guidance with:
- Real-time compatibility validation
- Performance impact warnings  
- Tool combination suggestions
- Preset recommendations based on answers

### Manual Configuration

```bash
hypergen monorepo new my-project \
  --package-manager bun \
  --linter eslint \
  --formatter prettier \
  --test-framework vitest
```

### Configuration File

Create `hypergen.config.js` in your workspace:

```javascript
export default {
  templateDefaults: {
    packageManager: 'bun',
    linter: 'biome', 
    formatter: 'biome-integrated',
    testFramework: 'vitest',
    tools: {
      typescript: true,
      storybook: false,
      docker: false
    },
    moon: {
      toolchain: 'bun',
      projects: ['api', 'web', 'shared']
    }
  }
};
```

## 📁 Generated Project Structure

Your generated monorepo includes everything needed for modern development:

```
my-awesome-project/
├── apps/                          # Application packages
│   └── README.md                  # Apps documentation
├── packages/                      # Shared library packages  
│   └── README.md                  # Packages documentation
├── .moon/                         # Moon workspace configuration
│   ├── workspace.yml              # Workspace settings
│   └── toolchain.yml              # Tool configurations
├── .github/                       # CI/CD workflows
│   └── workflows/                 # Automated testing & deployment
├── package.json                   # Workspace root configuration
├── tsconfig.json                  # TypeScript composite setup
├── biome.json                     # Biome configuration (if selected)
├── eslint.config.js               # ESLint configuration (if selected)
├── prettier.config.js             # Prettier configuration (if selected)
├── vitest.config.ts               # Vitest configuration (if selected)  
├── vitest.workspace.ts            # Multi-project test setup
└── README.md                      # Project documentation
```

## 🔧 Tool Compatibility Matrix

| Package Manager | Linter | Formatter | Test Framework | Status | Performance |
|----------------|--------|-----------|----------------|---------|-------------|
| **bun** | biome | biome-integrated | bun-test | ✅ Recommended | ⚡ Fastest |
| **bun** | eslint | prettier | vitest | ✅ Excellent | 🚀 Fast |
| **npm** | eslint | prettier | vitest | ✅ Stable | 🐌 Standard |
| **pnpm** | biome | biome-integrated | vitest | ✅ Efficient | 🚀 Fast |
| **yarn** | eslint | prettier | jest | ✅ Enterprise | 🐌 Standard |
| **bun** | eslint | biome-integrated | - | ❌ Invalid | - |
| **npm** | - | - | bun-test | ❌ Invalid | - |

> ⚠️ Invalid combinations are automatically detected with suggested alternatives.

## 🚀 Performance Features

### Template Generation Speed
- **Target:** <30 seconds for all configurations
- **Actual:** 15-30 seconds depending on complexity
- **Optimizations:** Parallel processing, smart caching, efficient I/O

### Runtime Performance
- **Bun Test:** Up to 3x faster than Jest
- **Biome:** Up to 10x faster than ESLint for large codebases  
- **TypeScript:** Composite projects for incremental builds
- **Moon:** Intelligent task caching and parallelization

### Memory Efficiency
- **Template Cache:** 100MB LRU cache with automatic cleanup
- **Streaming I/O:** Memory-efficient file processing
- **Worker Threads:** CPU core utilization for parallel operations

## 🛠️ Advanced Usage

### Environment-Specific Presets

```bash
# Development preset (fast feedback loops)
hypergen monorepo new dev-project --preset modern-bun

# CI/CD optimized preset (reliable, efficient)
hypergen monorepo new ci-project --preset performance

# Production preset (stable, battle-tested)
hypergen monorepo new prod-project --preset enterprise
```

### Multi-Package Setup

```bash
# Generate with multiple packages pre-configured
hypergen monorepo new full-stack \
  --preset modern-bun \
  --packages api,web,mobile,shared \
  --apps admin,dashboard
```

### Tool-Specific Configurations

```bash
# TypeScript strict mode
hypergen monorepo new strict-ts --preset modern-bun --typescript-strict

# With Storybook for component development  
hypergen monorepo new design-system --preset traditional-node --storybook

# Docker-ready for containerization
hypergen monorepo new containerized --preset enterprise --docker
```

## 📊 Troubleshooting

### Common Issues

#### ❌ "Package manager not found"
```bash
# Install the required package manager
curl -fsSL https://bun.sh/install | bash  # For Bun
npm install -g pnpm                       # For pnpm
npm install -g yarn                       # For Yarn
```

#### ❌ "Tool combination invalid"  
The system will suggest valid alternatives:
```bash
✅ Suggested fix: Change formatter to "prettier" or linter to "biome"
✅ Alternative: Use preset "modern-bun" for optimal Biome setup
```

#### ❌ "Generation timeout (>30s)"
```bash
# Clear template cache and retry
hypergen cache clear
hypergen monorepo new my-project --preset modern-bun

# Or use performance preset
hypergen monorepo new my-project --preset performance
```

#### ❌ "Memory issues during generation"
```bash
# Increase Node.js memory limit
NODE_OPTIONS="--max-old-space-size=4096" hypergen monorepo new large-project
```

### Performance Debugging

```bash
# Enable performance monitoring
HYPERGEN_PERF=true hypergen monorepo new my-project --preset modern-bun

# Benchmark specific configurations
hypergen benchmark --preset modern-bun --iterations 5

# Memory profiling
HYPERGEN_MEMORY_PROFILE=true hypergen monorepo new memory-test
```

### Validation Issues

```bash
# Validate configuration before generation
hypergen monorepo validate --package-manager bun --linter biome

# Interactive troubleshooting
hypergen monorepo doctor
```

## 🔄 Migration Guide

### From `moon-launch` CLI

```bash
# Old way
moon-launch create my-project --template typescript

# New way  
hypergen monorepo new my-project --preset modern-bun
```

**Key differences:**
- ✅ Automatic tool compatibility validation
- ✅ Performance optimizations (15-30s vs 60-120s)
- ✅ Error recovery and suggestions  
- ✅ 16 validated tool combinations vs basic setup
- ✅ Smart caching and parallel processing

### From Other Monorepo Tools

#### From `create-turbo`
```bash
# Turbo equivalent
hypergen monorepo new my-turborepo \
  --preset performance \
  --packages ui,utils,config
```

#### From `nx create`
```bash  
# Nx equivalent
hypergen monorepo new my-nx-style \
  --preset enterprise \
  --packages libs,apps \
  --typescript-strict
```

## 🧪 Examples & Workflows

### Frontend-Focused Monorepo
```bash
hypergen monorepo new frontend-mono \
  --preset modern-bun \
  --packages ui,components,utils \
  --apps web,mobile \
  --storybook
```

Generated structure:
```
frontend-mono/
├── apps/
│   ├── web/           # Next.js/React app
│   └── mobile/        # React Native app  
├── packages/
│   ├── ui/            # Design system
│   ├── components/    # Shared components
│   └── utils/         # Shared utilities
└── .storybook/        # Component documentation
```

### Backend API Monorepo
```bash
hypergen monorepo new backend-mono \
  --preset performance \
  --packages auth,database,utils \
  --apps api,admin \
  --docker
```

### Full-Stack Application
```bash
hypergen monorepo new fullstack-app \
  --preset modern-bun \
  --packages shared,ui,api-types \
  --apps web,api,admin
```

## 🏗️ Development & Contributing

### Local Development

```bash
# Clone the repository
git clone https://github.com/hypergen/hypergen.git
cd hypergen/packages/hypergen-monorepo

# Install dependencies (use Bun for best performance)
bun install

# Run development mode
bun run dev

# Run tests with coverage
bun test --coverage

# Build for production
bun run build

# Performance benchmarking
bun run benchmark
```

### Testing Changes

```bash
# Test template generation locally
bun run test:template

# Performance validation
bun run test:performance

# Test all tool combinations
bun run test:matrix

# Memory leak detection
bun run test:memory
```

### Performance Monitoring

```bash
# Generate performance report
bun run scripts/benchmark-performance.ts

# Profile specific preset
HYPERGEN_PROFILE=true bun run hypergen monorepo new test-perf --preset modern-bun

# Memory usage analysis
HYPERGEN_MEMORY_ANALYSIS=true bun test tests/performance-optimization.test.ts
```

## 📚 API Reference

### Configuration Types

```typescript
interface MonorepoConfig {
  name: string;
  packageManager: 'bun' | 'npm' | 'yarn' | 'pnpm';
  linter: 'eslint' | 'biome';
  formatter: 'prettier' | 'dprint' | 'biome-integrated';
  testFramework: 'vitest' | 'jest' | 'bun-test';
  tools?: {
    typescript?: boolean;
    storybook?: boolean;
    docker?: boolean;
  };
  moon?: {
    toolchain?: 'node' | 'bun' | 'deno';
    projects?: string[];
  };
}
```

### Preset Definitions

```typescript
type PresetName = 'modern-bun' | 'traditional-node' | 'performance' | 'enterprise';

interface PresetConfig extends Omit<MonorepoConfig, 'name'> {
  description: string;
  bestFor: string[];
  buildTimeMs: number;
}
```

### Validation API

```typescript
function validateToolCompatibility(config: MonorepoConfig): ValidationResult;
function isToolCombinationValid(pm: string, linter: string, formatter: string, test: string): boolean;
function getCompatibleFormatters(linter: string): string[];
```

## 🌟 Why Choose Hypergen Monorepo Pack?

### vs Manual Setup
- ✅ **30s** setup vs **hours** of configuration
- ✅ **Validated** tool combinations vs **trial-and-error**
- ✅ **Performance optimized** vs **default configurations**
- ✅ **Error recovery** vs **cryptic failures**

### vs Other Generators  
- ✅ **16 validated** combinations vs **limited options**
- ✅ **<30s generation** vs **1-5 minute** setup times
- ✅ **Moon integration** for **enterprise-grade** build orchestration
- ✅ **Smart caching** and **parallel processing**

### vs Boilerplates
- ✅ **Always up-to-date** vs **stale dependencies**
- ✅ **Customizable** vs **one-size-fits-all**
- ✅ **Tool validation** vs **broken combinations**
- ✅ **Performance monitoring** vs **no optimization**

## 📄 License

MIT - see [LICENSE](../../LICENSE) for details.

---

<div align="center">

**[🚀 Get Started](#-quick-start)** • **[📖 Documentation](#-presets)** • **[🛠️ Examples](#-examples--workflows)** • **[❓ Troubleshooting](#-troubleshooting)**

Made with ❤️ by the [Hypergen Team](https://github.com/hypergen/hypergen)

</div>