# Matrix Testing System

This comprehensive matrix testing system validates all tool combinations for the Hypergen Monorepo Template Pack. It ensures that every valid combination of package managers, linters, formatters, and test frameworks generates working projects that can lint, test, and build successfully.

## Overview

The matrix testing system consists of several components:

- **Combination Validator**: Validates all possible tool combinations based on compatibility rules
- **Matrix Testing**: Generates real projects and validates they work correctly
- **Performance Benchmarking**: Measures generation time and system resource usage
- **CI Integration**: Provides CI/CD optimized testing with proper reporting
- **Test Runner**: Unified CLI for running different test modes

## Quick Start

```bash
# Install dependencies
bun install

# Build the package
bun run build

# Run quick validation (recommended for development)
bun run test:matrix:validation

# Run comprehensive matrix testing
bun run test:matrix:full

# Run performance benchmarks
bun run test:matrix:benchmark
```

## Tool Combinations

The system tests all valid combinations of:

- **Package Managers**: bun, npm, yarn, pnpm
- **Linters**: ESLint, Biome
- **Formatters**: Prettier, dprint, Biome (integrated)
- **Test Frameworks**: Vitest, Jest, Bun Test

### Total Combinations

- **Theoretical Maximum**: 48 combinations (4 × 2 × 3 × 3)
- **Valid Combinations**: ~32 combinations (after compatibility validation)
- **Invalid Combinations**: ~16 combinations (incompatible tool pairings)

### Example Valid Combinations

```
✅ bun + biome + biome-integrated + bun-test    (fastest)
✅ npm + eslint + prettier + vitest             (traditional)
✅ pnpm + eslint + prettier + jest              (enterprise)
✅ yarn + biome + dprint + vitest               (modern)
```

### Example Invalid Combinations

```
❌ npm + biome + biome-integrated + bun-test    (bun-test requires bun package manager)
❌ any + eslint + biome-integrated + any        (biome-integrated requires biome linter)
❌ yarn + any + any + bun-test                  (bun-test requires bun package manager)
```

## Testing Modes

### 1. Validation Mode (`validation`)

**Purpose**: Validate all tool combinations without generating projects.

```bash
bun run test:matrix:validation
```

**What it does**:
- ✅ Validates all 48 theoretical combinations
- ✅ Reports valid vs invalid combinations
- ✅ Shows compatibility errors and warnings
- ✅ Generates validation report
- ⚡ Fast execution (~5 seconds)

**Use when**: Development, CI checks, quick validation

### 2. Quick Mode (`quick`)

**Purpose**: Basic matrix testing without project generation.

```bash
bun run test:matrix:quick
```

**What it does**:
- ✅ Runs validation mode
- ✅ Tests template composition logic
- ✅ Validates file inclusion/exclusion
- ❌ No actual project generation
- ❌ No tool execution
- ⚡ Medium execution (~30 seconds)

**Use when**: Development, PR checks, faster feedback

### 3. Full Mode (`full`)

**Purpose**: Complete matrix testing with project generation and validation.

```bash
bun run test:matrix:full
```

**What it does**:
- ✅ Runs validation mode
- ✅ Generates real projects for each valid combination
- ✅ Creates package.json, tsconfig.json, tool configs
- ✅ Runs lint, test, and build commands
- ✅ Validates all generated projects work correctly
- 🐌 Slow execution (~10-30 minutes)

**Use when**: Release preparation, comprehensive validation, CI main branch

### 4. Benchmark Mode (`benchmark`)

**Purpose**: Performance analysis and optimization insights.

```bash
bun run test:matrix:benchmark
```

**What it does**:
- ✅ Measures generation time for each combination
- ✅ Tracks memory usage and system resources
- ✅ Identifies fastest and slowest combinations
- ✅ Provides optimization recommendations
- ✅ Generates performance reports
- 📊 Medium execution with detailed metrics (~5-15 minutes)

**Use when**: Performance optimization, regression testing, capacity planning

### 5. CI Mode (`ci`)

**Purpose**: CI/CD optimized testing with proper reporting.

```bash
bun run test:matrix:ci
```

**What it does**:
- ✅ Auto-detects CI environment (GitHub Actions, GitLab, etc.)
- ✅ Optimizes parallelism based on CI provider
- ✅ Generates JUnit XML reports
- ✅ Creates CI-friendly artifacts
- ✅ Handles retries and failure analysis
- ✅ Proper exit codes for CI integration

**Use when**: CI/CD pipelines, automated testing, release workflows

## Command Line Interface

The test runner script provides comprehensive CLI options:

```bash
bun run scripts/run-matrix-tests.ts [OPTIONS]

OPTIONS:
  -m, --mode <mode>           Test mode: validation|quick|full|benchmark|ci
  -o, --output-dir <dir>      Output directory for results
  -p, --parallel <num>        Number of parallel tests
  -t, --timeout <ms>          Test timeout in milliseconds
  -v, --verbose               Enable verbose logging
  -c, --combinations <list>   Test specific combinations only
      --skip-generation       Skip project generation (validation only)
      --skip-execution        Skip tool execution
      --generate-reports      Generate comprehensive reports
  -h, --help                  Show help message
```

### Examples

```bash
# Test specific combinations only
bun run test:matrix --combinations "bun+biome+biome-integrated+bun-test,npm+eslint+prettier+vitest"

# Parallel execution for faster testing
bun run test:matrix:full --parallel 4

# Verbose output for debugging
bun run test:matrix --verbose --mode full

# Custom output directory
bun run test:matrix:ci --output-dir /tmp/ci-results

# Skip project generation for faster testing
bun run test:matrix:full --skip-generation
```

## Performance Targets

The matrix testing system is designed with performance in mind:

### Generation Time Targets

- **Individual Combination**: < 30 seconds
- **All Valid Combinations**: < 30 minutes (parallel)
- **Validation Only**: < 5 seconds
- **Quick Mode**: < 2 minutes

### Resource Usage Targets

- **Memory**: < 1GB peak usage
- **CPU**: Efficient parallel processing
- **Disk**: Cleanup temporary files
- **Network**: Minimal external dependencies

### Performance Optimization

The system includes several optimizations:

1. **Parallel Processing**: Run multiple combinations simultaneously
2. **Template Caching**: Reuse common template components
3. **Lazy Loading**: Load dependencies only when needed
4. **Memory Management**: Clean up resources between tests
5. **Tool Selection**: Use fastest tools for benchmarking

## CI/CD Integration

### GitHub Actions

The system includes a comprehensive GitHub Actions workflow:

```yaml
# .github/workflows/matrix-testing.yml
name: Matrix Testing - All Tool Combinations

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  workflow_dispatch:
    inputs:
      run_full_matrix:
        description: 'Run full matrix testing'
        default: 'false'
        type: boolean
```

**Features**:
- ✅ Multi-platform testing (Ubuntu, Windows, macOS)
- ✅ Multiple Node.js versions (18, 20)
- ✅ Automatic CI provider detection
- ✅ Performance analysis and reporting
- ✅ Failure analysis and debugging
- ✅ JUnit XML reports for test integration
- ✅ Artifact collection and retention

### Other CI Providers

The system auto-detects and optimizes for:

- **GitLab CI**: Optimized parallelism and caching
- **CircleCI**: Resource allocation and timing
- **Jenkins**: Environment detection and reporting
- **Azure Pipelines**: Pipeline integration
- **Travis CI**: Legacy support and configuration

## Directory Structure

```
tests/matrix/
├── README.md                     # This file
├── matrix-testing.test.ts        # Main test suite
├── combination-validator.ts      # Tool combination validation
├── performance-benchmark.ts      # Performance analysis
├── ci-integration.ts            # CI/CD integration
└── test-output/                 # Generated test results
    ├── artifacts/               # Generated project files
    ├── logs/                    # Test execution logs
    ├── reports/                 # JSON and markdown reports
    ├── benchmark-report.json    # Performance benchmarks
    ├── validation-report.json   # Combination validation
    ├── junit-report.xml         # JUnit XML for CI
    └── summary.json             # Test execution summary

scripts/
└── run-matrix-tests.ts          # Unified test runner CLI

.github/workflows/
└── matrix-testing.yml           # GitHub Actions workflow
```

## Reports and Artifacts

### Validation Report

```json
{
  "timestamp": "2025-08-31T12:00:00.000Z",
  "totalCombinations": 48,
  "validCombinations": 32,
  "invalidCombinations": 16,
  "validationResults": [...],
  "recommendations": {
    "fastestCombinations": ["bun+biome+biome-integrated+bun-test"],
    "enterpriseRecommendations": ["pnpm+eslint+prettier+vitest"]
  }
}
```

### Performance Report

```json
{
  "summary": {
    "totalDuration": 1800000,
    "averageDuration": 25000,
    "successRate": 0.95,
    "memoryPeakUsage": 512000000
  },
  "performanceAnalysis": {
    "fastestCombinations": [...],
    "slowestCombinations": [...],
    "recommendedOptimizations": [...]
  }
}
```

### JUnit XML Report

```xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="Matrix Testing" tests="32" failures="1" errors="0" time="1800">
  <testcase name="bun+biome+biome-integrated+bun-test" classname="MatrixTesting" time="15.5"/>
  <testcase name="npm+eslint+prettier+vitest" classname="MatrixTesting" time="28.2"/>
  <!-- ... more test cases ... -->
</testsuite>
```

## Troubleshooting

### Common Issues

#### Tool Installation Failures

```bash
# Issue: Package manager not found
Error: Required tool not found: pnpm

# Solution: Install missing tools
npm install -g pnpm
brew install bun  # macOS
```

#### Generation Timeout

```bash
# Issue: Test exceeds timeout
Test timeout: Generation took longer than 300000ms

# Solution: Increase timeout or reduce complexity
bun run test:matrix:full --timeout 600000
```

#### Memory Issues

```bash
# Issue: Out of memory during testing
FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory

# Solution: Reduce parallelism or skip generation
bun run test:matrix:full --parallel 1 --skip-generation
```

#### Permission Errors

```bash
# Issue: Cannot create test files
Error: EACCES: permission denied, mkdir '/test-results'

# Solution: Use writable directory
bun run test:matrix:full --output-dir ./my-test-results
```

### Debugging Tips

1. **Use Verbose Mode**: Add `--verbose` to see detailed execution logs
2. **Test Specific Combinations**: Use `--combinations` to isolate issues
3. **Skip Generation**: Use `--skip-generation` for faster debugging
4. **Check Tool Versions**: Ensure all tools are properly installed
5. **Review Logs**: Check generated log files in the output directory

### Getting Help

1. **Check Documentation**: Review this README and inline comments
2. **Run Validation**: Start with `bun run test:matrix:validation`
3. **Check Issues**: Search existing GitHub issues
4. **Create Issue**: Report bugs with full error logs and system information

## Development

### Adding New Tool Combinations

1. **Update Validation**: Add new tools to `src/validation.ts`
2. **Update Composition**: Add template logic to `src/composition.ts`
3. **Add Templates**: Create EJS templates for new tools
4. **Test Validation**: Run validation mode to check compatibility
5. **Test Generation**: Run full mode to verify project generation

### Extending Test Coverage

1. **Add Test Cases**: Extend `matrix-testing.test.ts`
2. **Add Validation Rules**: Update `combination-validator.ts`
3. **Add Performance Metrics**: Extend `performance-benchmark.ts`
4. **Update CI Workflow**: Modify `.github/workflows/matrix-testing.yml`

### Performance Optimization

1. **Profile Generation**: Use benchmark mode to identify bottlenecks
2. **Optimize Templates**: Reduce template complexity and I/O operations
3. **Improve Caching**: Add caching for repeated operations
4. **Parallel Processing**: Increase parallelism where safe
5. **Memory Management**: Optimize memory usage and cleanup

## Contributing

1. **Fork and Clone**: Fork the repository and create a feature branch
2. **Run Tests**: Ensure all existing tests pass
3. **Add Tests**: Add tests for new functionality
4. **Update Documentation**: Update this README and inline documentation
5. **Submit PR**: Create a pull request with clear description

## License

This matrix testing system is part of the Hypergen project and is licensed under the MIT License.