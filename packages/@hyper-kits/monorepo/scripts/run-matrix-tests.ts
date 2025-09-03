#!/usr/bin/env bun

/**
 * Matrix Testing Runner Script
 * 
 * Comprehensive test runner for all tool combinations with multiple execution modes.
 * This script can be used locally, in CI/CD, or for performance analysis.
 */

import { parseArgs } from 'node:util';
import * as fs from 'fs/promises';
import * as path from 'path';
import { execSync } from 'child_process';
import { CombinationValidator } from '../tests/matrix/combination-validator';
import { PerformanceBenchmark, StandaloneBenchmarkRunner } from '../tests/matrix/performance-benchmark';
import { CIMatrixRunner } from '../tests/matrix/ci-integration';

/**
 * Script configuration
 */
interface ScriptConfig {
  mode: 'validation' | 'quick' | 'full' | 'benchmark' | 'ci';
  outputDir: string;
  parallel: number;
  timeout: number;
  verbose: boolean;
  skipGeneration: boolean;
  skipExecution: boolean;
  generateReports: boolean;
  platforms: string[];
  combinations?: string[];
}

/**
 * Command line options
 */
const options = {
  mode: {
    type: 'string' as const,
    short: 'm',
    default: 'quick'
  },
  'output-dir': {
    type: 'string' as const,
    short: 'o',
    default: './test-results'
  },
  parallel: {
    type: 'string' as const,
    short: 'p',
    default: '1'
  },
  timeout: {
    type: 'string' as const,
    short: 't',
    default: '300000'
  },
  verbose: {
    type: 'boolean' as const,
    short: 'v',
    default: false
  },
  'skip-generation': {
    type: 'boolean' as const,
    default: false
  },
  'skip-execution': {
    type: 'boolean' as const,
    default: false
  },
  'generate-reports': {
    type: 'boolean' as const,
    default: true
  },
  combinations: {
    type: 'string' as const,
    short: 'c'
  },
  help: {
    type: 'boolean' as const,
    short: 'h',
    default: false
  }
};

/**
 * Print help text
 */
function printHelp() {
  console.log(`
Matrix Testing Runner - Hypergen Monorepo Template Pack

USAGE:
  bun run scripts/run-matrix-tests.ts [OPTIONS]

OPTIONS:
  -m, --mode <mode>           Test mode: validation|quick|full|benchmark|ci (default: quick)
  -o, --output-dir <dir>      Output directory for results (default: ./test-results)
  -p, --parallel <num>        Number of parallel tests (default: 1)
  -t, --timeout <ms>          Test timeout in milliseconds (default: 300000)
  -v, --verbose               Enable verbose logging
  -c, --combinations <list>   Comma-separated list of specific combinations to test
      --skip-generation       Skip actual project generation (validation only)
      --skip-execution        Skip running lint/test/build commands
      --generate-reports      Generate comprehensive reports (default: true)
  -h, --help                  Show this help message

MODES:
  validation    Validate all tool combinations without generation
  quick         Run validation + basic matrix tests (no project generation)
  full          Complete matrix testing with project generation and tool execution
  benchmark     Performance benchmarking with detailed metrics
  ci            CI/CD optimized testing with proper reporting

EXAMPLES:
  # Quick validation of all combinations
  bun run scripts/run-matrix-tests.ts --mode validation

  # Run specific combinations with project generation
  bun run scripts/run-matrix-tests.ts --mode full --combinations "bun+biome+biome-integrated+bun-test,npm+eslint+prettier+vitest"

  # Performance benchmark
  bun run scripts/run-matrix-tests.ts --mode benchmark --parallel 2

  # CI mode with custom output directory
  bun run scripts/run-matrix-tests.ts --mode ci --output-dir /tmp/ci-results

  # Full matrix testing with verbose output
  bun run scripts/run-matrix-tests.ts --mode full --verbose --parallel 4
`);
}

/**
 * Parse and validate command line arguments
 */
function parseCliArgs(): ScriptConfig {
  const { values } = parseArgs({ options });

  if (values.help) {
    printHelp();
    process.exit(0);
  }

  const mode = values.mode as ScriptConfig['mode'];
  if (!['validation', 'quick', 'full', 'benchmark', 'ci'].includes(mode)) {
    console.error(`❌ Invalid mode: ${mode}`);
    process.exit(1);
  }

  const parallel = parseInt(values.parallel || '1');
  if (isNaN(parallel) || parallel < 1 || parallel > 16) {
    console.error(`❌ Invalid parallel value: ${values.parallel}. Must be between 1 and 16.`);
    process.exit(1);
  }

  const timeout = parseInt(values.timeout || '300000');
  if (isNaN(timeout) || timeout < 10000) {
    console.error(`❌ Invalid timeout value: ${values.timeout}. Must be at least 10000ms.`);
    process.exit(1);
  }

  // Parse specific combinations if provided
  let combinations: string[] | undefined;
  if (values.combinations) {
    combinations = values.combinations.split(',').map(c => c.trim());
  }

  return {
    mode,
    outputDir: values['output-dir'] || './test-results',
    parallel,
    timeout,
    verbose: values.verbose || false,
    skipGeneration: values['skip-generation'] || false,
    skipExecution: values['skip-execution'] || false,
    generateReports: values['generate-reports'] !== false,
    platforms: [process.platform],
    combinations
  };
}

/**
 * Main test runner class
 */
class MatrixTestRunner {
  private config: ScriptConfig;
  private validator: CombinationValidator;
  private startTime: number = 0;

  constructor(config: ScriptConfig) {
    this.config = config;
    this.validator = new CombinationValidator();
  }

  /**
   * Run matrix tests based on configuration
   */
  async run(): Promise<void> {
    this.startTime = Date.now();
    
    this.log(`🚀 Starting Matrix Testing Runner`);
    this.log(`📝 Mode: ${this.config.mode}`);
    this.log(`📁 Output: ${this.config.outputDir}`);
    this.log(`⚡ Parallelism: ${this.config.parallel}`);
    this.log(`⏱️  Timeout: ${this.config.timeout}ms`);
    this.log('');

    // Ensure output directory exists
    await fs.mkdir(this.config.outputDir, { recursive: true });

    try {
      switch (this.config.mode) {
        case 'validation':
          await this.runValidationMode();
          break;
        case 'quick':
          await this.runQuickMode();
          break;
        case 'full':
          await this.runFullMode();
          break;
        case 'benchmark':
          await this.runBenchmarkMode();
          break;
        case 'ci':
          await this.runCIMode();
          break;
        default:
          throw new Error(`Unknown mode: ${this.config.mode}`);
      }

      const totalTime = Date.now() - this.startTime;
      this.log(`\n🎉 Matrix testing completed successfully in ${totalTime}ms`);
      
    } catch (error) {
      const totalTime = Date.now() - this.startTime;
      this.error(`❌ Matrix testing failed after ${totalTime}ms:`, error);
      process.exit(1);
    }
  }

  /**
   * Validation mode - validate all combinations without generation
   */
  private async runValidationMode(): Promise<void> {
    this.log('🔍 Running validation mode...');
    
    const report = this.validator.generateValidationReport();
    
    this.log(`📊 Total combinations: ${report.totalCombinations}`);
    this.log(`✅ Valid combinations: ${report.validCombinations}`);
    this.log(`❌ Invalid combinations: ${report.invalidCombinations}`);
    this.log(`📈 Success rate: ${((report.validCombinations / report.totalCombinations) * 100).toFixed(1)}%`);

    if (this.config.generateReports) {
      const reportPath = path.join(this.config.outputDir, 'validation-report.json');
      await this.validator.exportValidationReport(reportPath);
      this.log(`📋 Validation report exported to: ${reportPath}`);
    }

    // Show invalid combinations if any
    const invalidCombinations = this.validator.getInvalidCombinations();
    if (invalidCombinations.length > 0) {
      this.log('\n❌ Invalid combinations:');
      invalidCombinations.forEach(invalid => {
        const combo = `${invalid.combination.packageManager}+${invalid.combination.linter}+${invalid.combination.formatter}+${invalid.combination.testFramework}`;
        this.log(`  - ${combo}: ${invalid.errors.join(', ')}`);
      });
    }
  }

  /**
   * Quick mode - validation + basic matrix tests (no project generation)
   */
  private async runQuickMode(): Promise<void> {
    this.log('⚡ Running quick mode...');
    
    // First run validation
    await this.runValidationMode();
    
    // Then run basic matrix tests
    this.log('\n🧪 Running basic matrix tests...');
    
    const testEnv = {
      ...process.env,
      SKIP_PROJECT_GENERATION: 'true',
      SKIP_TOOL_EXECUTION: 'true',
      TEST_PARALLELISM: this.config.parallel.toString(),
      TEST_TIMEOUT: this.config.timeout.toString(),
      TEST_OUTPUT_DIR: this.config.outputDir
    };

    await this.runVitest('tests/matrix/matrix-testing.test.ts', testEnv);
  }

  /**
   * Full mode - complete matrix testing with project generation
   */
  private async runFullMode(): Promise<void> {
    this.log('🔥 Running full mode...');
    
    // Run validation first
    await this.runValidationMode();
    
    // Run complete matrix tests
    this.log('\n🧪 Running complete matrix tests...');
    
    const testEnv = {
      ...process.env,
      SKIP_PROJECT_GENERATION: this.config.skipGeneration ? 'true' : 'false',
      SKIP_TOOL_EXECUTION: this.config.skipExecution ? 'true' : 'false',
      TEST_PARALLELISM: this.config.parallel.toString(),
      TEST_TIMEOUT: this.config.timeout.toString(),
      TEST_OUTPUT_DIR: this.config.outputDir
    };

    await this.runVitest('tests/matrix/matrix-testing.test.ts', testEnv);
  }

  /**
   * Benchmark mode - performance benchmarking
   */
  private async runBenchmarkMode(): Promise<void> {
    this.log('📊 Running benchmark mode...');
    
    const benchmarkRunner = new StandaloneBenchmarkRunner();
    const benchmarkOutputDir = path.join(this.config.outputDir, 'benchmarks');
    
    this.log(`🏃 Starting performance benchmarks...`);
    const report = await benchmarkRunner.runBenchmarkSuite(benchmarkOutputDir);
    
    this.log(`📊 Benchmark Results:`);
    this.log(`  - Total combinations: ${report.testConfig.totalCombinations}`);
    this.log(`  - Average duration: ${report.summary.averageDuration.toFixed(0)}ms`);
    this.log(`  - Success rate: ${(report.summary.successRate * 100).toFixed(1)}%`);
    this.log(`  - Peak memory: ${(report.summary.memoryPeakUsage / (1024 * 1024)).toFixed(1)}MB`);
    
    if (report.performanceAnalysis.recommendedOptimizations.length > 0) {
      this.log(`\n💡 Optimization recommendations:`);
      report.performanceAnalysis.recommendedOptimizations.forEach(rec => {
        this.log(`  - ${rec}`);
      });
    }
  }

  /**
   * CI mode - CI/CD optimized testing
   */
  private async runCIMode(): Promise<void> {
    this.log('🔧 Running CI mode...');
    
    const ciRunner = new CIMatrixRunner({
      outputDir: this.config.outputDir,
      failOnErrors: true,
      generateJUnitReport: true,
      parallelism: this.config.parallel,
      timeout: this.config.timeout
    });

    await ciRunner.runCITests();
  }

  /**
   * Run Vitest with specific environment
   */
  private async runVitest(testFile: string, env: Record<string, string>): Promise<void> {
    try {
      const cmd = `bun test ${testFile} --timeout=${this.config.timeout}`;
      
      this.log(`🧪 Running: ${cmd}`);
      
      if (this.config.verbose) {
        // Run with stdout/stderr visible
        execSync(cmd, { 
          stdio: 'inherit',
          env: { ...process.env, ...env },
          cwd: process.cwd()
        });
      } else {
        // Capture output and only show on failure
        const output = execSync(cmd, { 
          stdio: 'pipe',
          encoding: 'utf-8',
          env: { ...process.env, ...env },
          cwd: process.cwd()
        });
        
        if (this.config.verbose || output.includes('FAIL')) {
          console.log(output);
        }
      }
    } catch (error) {
      if (error instanceof Error && 'stdout' in error) {
        console.error('Test output:', (error as any).stdout);
        console.error('Test errors:', (error as any).stderr);
      }
      throw error;
    }
  }

  /**
   * Log message with timestamp
   */
  private log(...args: any[]): void {
    if (this.config.verbose || args[0].includes('🚀') || args[0].includes('✅') || args[0].includes('❌')) {
      const timestamp = new Date().toLocaleTimeString();
      console.log(`[${timestamp}]`, ...args);
    }
  }

  /**
   * Log error message
   */
  private error(...args: any[]): void {
    const timestamp = new Date().toLocaleTimeString();
    console.error(`[${timestamp}]`, ...args);
  }
}

/**
 * Environment checks
 */
function checkEnvironment(): void {
  // Check if we're in the correct directory
  const packageJsonPath = path.join(process.cwd(), 'package.json');
  try {
    const packageJson = require(packageJsonPath);
    if (!packageJson.name?.includes('hypergen-monorepo')) {
      console.warn('⚠️  Warning: This script should be run from the hypergen-monorepo package directory');
    }
  } catch (error) {
    console.error('❌ Could not find package.json. Make sure you\'re in the correct directory.');
    process.exit(1);
  }

  // Check if required tools are available
  const requiredTools = ['bun', 'node'];
  for (const tool of requiredTools) {
    try {
      execSync(`which ${tool}`, { stdio: 'pipe' });
    } catch (error) {
      console.error(`❌ Required tool not found: ${tool}`);
      process.exit(1);
    }
  }
}

/**
 * Main execution
 */
async function main() {
  try {
    // Check environment
    checkEnvironment();

    // Parse arguments
    const config = parseCliArgs();

    // Create and run test runner
    const runner = new MatrixTestRunner(config);
    await runner.run();

  } catch (error) {
    console.error('❌ Matrix testing failed:', error);
    process.exit(1);
  }
}

// Handle uncaught errors
process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught Exception:', error);
  process.exit(1);
});

// Run if called directly
if (require.main === module) {
  main();
}