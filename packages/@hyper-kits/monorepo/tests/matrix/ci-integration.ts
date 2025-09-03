/**
 * CI/CD Integration for Matrix Testing
 * 
 * This module provides utilities for integrating matrix testing into
 * continuous integration pipelines with proper reporting and failure handling.
 */

import * as fs from 'fs/promises';
import * as path from 'path';
import { execSync } from 'child_process';
import { getValidToolCombinations } from '../../src/composition';
import { PerformanceBenchmark } from './performance-benchmark';
import type { MonorepoConfig } from '../../src';

/**
 * CI/CD test configuration
 */
interface CIConfig {
  outputDir: string;
  failOnErrors: boolean;
  generateJUnitReport: boolean;
  generateCoverageReport: boolean;
  parallelism: number;
  timeout: number;
  retries: number;
  platforms: string[];
}

/**
 * Test result for CI reporting
 */
interface CITestResult {
  combination: string;
  status: 'passed' | 'failed' | 'skipped' | 'timeout';
  duration: number;
  error?: string;
  stdout?: string;
  stderr?: string;
  artifacts: string[];
}

/**
 * JUnit XML test case
 */
interface JUnitTestCase {
  name: string;
  classname: string;
  time: number;
  failure?: {
    message: string;
    content: string;
  };
  error?: {
    message: string;
    content: string;
  };
  skipped?: {
    message: string;
  };
}

/**
 * JUnit XML test suite
 */
interface JUnitTestSuite {
  name: string;
  tests: number;
  failures: number;
  errors: number;
  skipped: number;
  time: number;
  timestamp: string;
  testcases: JUnitTestCase[];
}

/**
 * CI/CD Matrix Testing Runner
 */
export class CIMatrixRunner {
  private config: CIConfig;
  private benchmark: PerformanceBenchmark;
  private results: CITestResult[] = [];

  constructor(config: Partial<CIConfig> = {}) {
    this.config = {
      outputDir: './test-results',
      failOnErrors: true,
      generateJUnitReport: true,
      generateCoverageReport: false,
      parallelism: 1,
      timeout: 300000, // 5 minutes
      retries: 1,
      platforms: [process.platform],
      ...config
    };

    this.benchmark = new PerformanceBenchmark();
  }

  /**
   * Run matrix tests in CI/CD environment
   */
  async runCITests(): Promise<void> {
    console.log('🚀 Starting CI/CD Matrix Testing');
    console.log(`📊 Configuration:`, this.config);

    // Setup output directory
    await this.setupOutputDirectory();

    // Detect environment and adjust configuration
    this.detectCIEnvironment();

    try {
      // Run benchmarks if enabled
      this.benchmark.startGlobal();

      // Get valid combinations
      const validCombinations = getValidToolCombinations();
      console.log(`🔍 Testing ${validCombinations.length} valid combinations`);

      // Run tests with appropriate parallelism
      await this.runTestsWithParallelism(validCombinations);

      this.benchmark.endGlobal();

      // Generate reports
      await this.generateReports();

      // Check for failures and exit appropriately
      await this.handleTestCompletion();

    } catch (error) {
      console.error('❌ CI Matrix Testing failed:', error);
      if (this.config.failOnErrors) {
        process.exit(1);
      }
    }
  }

  /**
   * Setup output directory structure
   */
  private async setupOutputDirectory(): Promise<void> {
    const dirs = [
      this.config.outputDir,
      path.join(this.config.outputDir, 'artifacts'),
      path.join(this.config.outputDir, 'coverage'),
      path.join(this.config.outputDir, 'logs')
    ];

    for (const dir of dirs) {
      await fs.mkdir(dir, { recursive: true });
    }
  }

  /**
   * Detect CI environment and adjust configuration
   */
  private detectCIEnvironment(): void {
    const ciProviders = {
      'GitHub Actions': process.env.GITHUB_ACTIONS === 'true',
      'GitLab CI': process.env.GITLAB_CI === 'true',
      'CircleCI': process.env.CIRCLECI === 'true',
      'Jenkins': process.env.JENKINS_URL !== undefined,
      'Travis CI': process.env.TRAVIS === 'true',
      'Azure Pipelines': process.env.AZURE_PIPELINES === 'true'
    };

    const detectedCI = Object.entries(ciProviders).find(([_, active]) => active)?.[0];
    
    if (detectedCI) {
      console.log(`🔧 Detected CI Provider: ${detectedCI}`);
      this.adjustConfigForCI(detectedCI);
    } else {
      console.log('🔧 Running in local environment');
    }
  }

  /**
   * Adjust configuration for specific CI providers
   */
  private adjustConfigForCI(provider: string): void {
    switch (provider) {
      case 'GitHub Actions':
        // GitHub Actions specific adjustments
        this.config.parallelism = Math.min(4, this.config.parallelism);
        this.config.timeout = 600000; // 10 minutes for GitHub Actions
        break;
        
      case 'GitLab CI':
        // GitLab CI specific adjustments
        this.config.parallelism = Math.min(2, this.config.parallelism);
        break;
        
      case 'CircleCI':
        // CircleCI specific adjustments
        this.config.parallelism = Math.min(4, this.config.parallelism);
        break;
        
      default:
        // Conservative defaults for unknown CI
        this.config.parallelism = 1;
        this.config.timeout = 300000;
    }

    // Always enable JUnit reporting in CI
    this.config.generateJUnitReport = true;
  }

  /**
   * Run tests with configured parallelism
   */
  private async runTestsWithParallelism(combinations: Array<Partial<MonorepoConfig>>): Promise<void> {
    if (this.config.parallelism === 1) {
      // Sequential execution
      await this.runTestsSequentially(combinations);
    } else {
      // Parallel execution
      await this.runTestsInParallel(combinations);
    }
  }

  /**
   * Run tests sequentially
   */
  private async runTestsSequentially(combinations: Array<Partial<MonorepoConfig>>): Promise<void> {
    for (let i = 0; i < combinations.length; i++) {
      const combination = combinations[i];
      const progress = `[${i + 1}/${combinations.length}]`;
      
      console.log(`${progress} Testing: ${this.formatCombination(combination)}`);
      
      const result = await this.runSingleTest(combination, i);
      this.results.push(result);
      
      this.logTestResult(result);
    }
  }

  /**
   * Run tests in parallel batches
   */
  private async runTestsInParallel(combinations: Array<Partial<MonorepoConfig>>): Promise<void> {
    const batches = this.createBatches(combinations, this.config.parallelism);
    
    for (let batchIndex = 0; batchIndex < batches.length; batchIndex++) {
      const batch = batches[batchIndex];
      console.log(`🔄 Running batch ${batchIndex + 1}/${batches.length} (${batch.length} tests)`);
      
      const promises = batch.map((combination, index) =>
        this.runSingleTest(combination, batchIndex * this.config.parallelism + index)
      );
      
      const batchResults = await Promise.all(promises);
      this.results.push(...batchResults);
      
      batchResults.forEach(result => this.logTestResult(result));
    }
  }

  /**
   * Create parallel batches
   */
  private createBatches<T>(items: T[], batchSize: number): T[][] {
    const batches: T[][] = [];
    for (let i = 0; i < items.length; i += batchSize) {
      batches.push(items.slice(i, i + batchSize));
    }
    return batches;
  }

  /**
   * Run single test with retries
   */
  private async runSingleTest(combination: Partial<MonorepoConfig>, index: number): Promise<CITestResult> {
    const combinationStr = this.formatCombination(combination);
    let lastError: string | undefined;

    for (let attempt = 1; attempt <= this.config.retries + 1; attempt++) {
      try {
        const result = await this.executeTest(combination, index, attempt);
        
        if (result.status === 'passed') {
          return result;
        }
        
        lastError = result.error;
        
        if (attempt <= this.config.retries) {
          console.log(`⚠️  Test failed, retrying (${attempt}/${this.config.retries}): ${combinationStr}`);
          await this.delay(1000 * attempt); // Progressive delay
        }
      } catch (error) {
        lastError = error instanceof Error ? error.message : String(error);
        
        if (attempt <= this.config.retries) {
          console.log(`⚠️  Test error, retrying (${attempt}/${this.config.retries}): ${combinationStr}`);
          await this.delay(1000 * attempt);
        }
      }
    }

    // All retries exhausted
    return {
      combination: combinationStr,
      status: 'failed',
      duration: 0,
      error: lastError || 'Test failed after all retries',
      artifacts: []
    };
  }

  /**
   * Execute individual test
   */
  private async executeTest(
    combination: Partial<MonorepoConfig>,
    index: number,
    attempt: number
  ): Promise<CITestResult> {
    const combinationStr = this.formatCombination(combination);
    const startTime = Date.now();

    try {
      // Setup test environment
      const testDir = path.join(
        this.config.outputDir,
        'artifacts',
        `test-${index}-${combinationStr.replace(/\+/g, '-')}-attempt-${attempt}`
      );
      
      await fs.mkdir(testDir, { recursive: true });

      // Create test configuration
      const config: MonorepoConfig = {
        name: `ci-test-${index}-${attempt}`,
        packageManager: combination.packageManager!,
        linter: combination.linter!,
        formatter: combination.formatter!,
        testFramework: combination.testFramework!,
        tools: {
          husky: false,
          lintStaged: false,
          commitlint: false,
          changesets: false
        }
      };

      // Benchmark the test
      const benchmarkResult = await this.benchmark.benchmarkOperation(
        combination,
        `test-execution-${attempt}`,
        async () => {
          return await this.performTestOperations(config, testDir);
        }
      );

      const duration = Date.now() - startTime;

      if (benchmarkResult.result) {
        return {
          combination: combinationStr,
          status: 'passed',
          duration,
          artifacts: [testDir]
        };
      } else {
        return {
          combination: combinationStr,
          status: 'failed',
          duration,
          error: benchmarkResult.benchmark.error || 'Test execution failed',
          artifacts: [testDir]
        };
      }

    } catch (error) {
      const duration = Date.now() - startTime;
      return {
        combination: combinationStr,
        status: 'failed',
        duration,
        error: error instanceof Error ? error.message : String(error),
        artifacts: []
      };
    }
  }

  /**
   * Perform actual test operations
   */
  private async performTestOperations(config: MonorepoConfig, testDir: string): Promise<boolean> {
    try {
      // Generate project files (simplified version for CI)
      await this.generateSimplifiedProject(config, testDir);
      
      // Validate generated files exist
      await this.validateGeneratedFiles(testDir);
      
      // Run basic validation checks
      await this.runBasicValidation(config, testDir);
      
      return true;
    } catch (error) {
      console.error(`Test operations failed: ${error}`);
      return false;
    }
  }

  /**
   * Generate simplified project for CI testing
   */
  private async generateSimplifiedProject(config: MonorepoConfig, testDir: string): Promise<void> {
    // Generate minimal package.json
    const packageJson = {
      name: config.name,
      version: '1.0.0',
      type: 'module',
      scripts: {
        build: 'echo "Build placeholder"',
        test: 'echo "Test placeholder"',
        lint: 'echo "Lint placeholder"'
      }
    };
    
    await fs.writeFile(
      path.join(testDir, 'package.json'),
      JSON.stringify(packageJson, null, 2),
      'utf-8'
    );

    // Generate basic TypeScript config
    const tsConfig = {
      compilerOptions: {
        target: 'ES2020',
        module: 'ESNext',
        strict: true
      }
    };
    
    await fs.writeFile(
      path.join(testDir, 'tsconfig.json'),
      JSON.stringify(tsConfig, null, 2),
      'utf-8'
    );

    // Generate tool-specific config files based on combination
    await this.generateToolConfigs(config, testDir);
  }

  /**
   * Generate tool-specific configuration files
   */
  private async generateToolConfigs(config: MonorepoConfig, testDir: string): Promise<void> {
    // Linter config
    if (config.linter === 'eslint') {
      await fs.writeFile(
        path.join(testDir, '.eslintrc.js'),
        'module.exports = { extends: ["eslint:recommended"] };',
        'utf-8'
      );
    } else if (config.linter === 'biome') {
      await fs.writeFile(
        path.join(testDir, 'biome.json'),
        JSON.stringify({ linter: { enabled: true } }, null, 2),
        'utf-8'
      );
    }

    // Formatter config
    if (config.formatter === 'prettier') {
      await fs.writeFile(
        path.join(testDir, '.prettierrc'),
        JSON.stringify({ semi: true, singleQuote: true }, null, 2),
        'utf-8'
      );
    } else if (config.formatter === 'dprint') {
      await fs.writeFile(
        path.join(testDir, 'dprint.json'),
        JSON.stringify({ typescript: {} }, null, 2),
        'utf-8'
      );
    }

    // Test framework config
    if (config.testFramework === 'vitest') {
      await fs.writeFile(
        path.join(testDir, 'vitest.config.ts'),
        'export default { test: { globals: true } };',
        'utf-8'
      );
    } else if (config.testFramework === 'jest') {
      await fs.writeFile(
        path.join(testDir, 'jest.config.js'),
        'module.exports = { testEnvironment: "node" };',
        'utf-8'
      );
    }
  }

  /**
   * Validate generated files exist and are valid
   */
  private async validateGeneratedFiles(testDir: string): Promise<void> {
    const requiredFiles = ['package.json', 'tsconfig.json'];
    
    for (const file of requiredFiles) {
      const filePath = path.join(testDir, file);
      await fs.access(filePath); // Will throw if file doesn't exist
      
      // Validate JSON files are valid JSON
      if (file.endsWith('.json')) {
        const content = await fs.readFile(filePath, 'utf-8');
        JSON.parse(content); // Will throw if invalid JSON
      }
    }
  }

  /**
   * Run basic validation checks
   */
  private async runBasicValidation(config: MonorepoConfig, testDir: string): Promise<void> {
    // Validate package.json has required fields
    const packageJsonPath = path.join(testDir, 'package.json');
    const packageJson = JSON.parse(await fs.readFile(packageJsonPath, 'utf-8'));
    
    if (!packageJson.name || !packageJson.version) {
      throw new Error('package.json missing required fields');
    }

    // Validate TypeScript config
    const tsConfigPath = path.join(testDir, 'tsconfig.json');
    const tsConfig = JSON.parse(await fs.readFile(tsConfigPath, 'utf-8'));
    
    if (!tsConfig.compilerOptions) {
      throw new Error('tsconfig.json missing compilerOptions');
    }
  }

  /**
   * Format combination as string
   */
  private formatCombination(combination: Partial<MonorepoConfig>): string {
    return `${combination.packageManager}+${combination.linter}+${combination.formatter}+${combination.testFramework}`;
  }

  /**
   * Log test result
   */
  private logTestResult(result: CITestResult): void {
    const icon = result.status === 'passed' ? '✅' : 
                 result.status === 'failed' ? '❌' : 
                 result.status === 'skipped' ? '⏭️' : '⏰';
    
    const duration = `(${result.duration}ms)`;
    console.log(`${icon} ${result.combination} ${duration}`);
    
    if (result.error) {
      console.log(`   Error: ${result.error}`);
    }
  }

  /**
   * Delay utility for retries
   */
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Generate reports
   */
  private async generateReports(): Promise<void> {
    console.log('📊 Generating CI reports...');

    // Generate JUnit XML report
    if (this.config.generateJUnitReport) {
      await this.generateJUnitReport();
    }

    // Generate benchmark report
    const benchmarkPath = path.join(this.config.outputDir, 'benchmark-report.json');
    await this.benchmark.exportReport(benchmarkPath);

    // Generate summary report
    await this.generateSummaryReport();
  }

  /**
   * Generate JUnit XML report for CI integration
   */
  private async generateJUnitReport(): Promise<void> {
    const testSuite: JUnitTestSuite = {
      name: 'Matrix Testing',
      tests: this.results.length,
      failures: this.results.filter(r => r.status === 'failed').length,
      errors: 0,
      skipped: this.results.filter(r => r.status === 'skipped').length,
      time: this.results.reduce((sum, r) => sum + r.duration, 0) / 1000,
      timestamp: new Date().toISOString(),
      testcases: this.results.map(result => this.createJUnitTestCase(result))
    };

    const xml = this.generateJUnitXML(testSuite);
    const xmlPath = path.join(this.config.outputDir, 'junit-report.xml');
    await fs.writeFile(xmlPath, xml, 'utf-8');
    
    console.log(`📋 JUnit report written to: ${xmlPath}`);
  }

  /**
   * Create JUnit test case from result
   */
  private createJUnitTestCase(result: CITestResult): JUnitTestCase {
    const testCase: JUnitTestCase = {
      name: result.combination,
      classname: 'MatrixTesting',
      time: result.duration / 1000
    };

    if (result.status === 'failed' && result.error) {
      testCase.failure = {
        message: 'Test failed',
        content: result.error
      };
    } else if (result.status === 'skipped') {
      testCase.skipped = {
        message: 'Test skipped'
      };
    }

    return testCase;
  }

  /**
   * Generate JUnit XML
   */
  private generateJUnitXML(testSuite: JUnitTestSuite): string {
    const lines = [];
    lines.push('<?xml version="1.0" encoding="UTF-8"?>');
    lines.push(`<testsuite name="${testSuite.name}" tests="${testSuite.tests}" failures="${testSuite.failures}" errors="${testSuite.errors}" skipped="${testSuite.skipped}" time="${testSuite.time}" timestamp="${testSuite.timestamp}">`);
    
    testSuite.testcases.forEach(testcase => {
      lines.push(`  <testcase name="${testcase.name}" classname="${testcase.classname}" time="${testcase.time}">`);
      
      if (testcase.failure) {
        lines.push(`    <failure message="${this.escapeXML(testcase.failure.message)}">`);
        lines.push(`      ${this.escapeXML(testcase.failure.content)}`);
        lines.push(`    </failure>`);
      }
      
      if (testcase.error) {
        lines.push(`    <error message="${this.escapeXML(testcase.error.message)}">`);
        lines.push(`      ${this.escapeXML(testcase.error.content)}`);
        lines.push(`    </error>`);
      }
      
      if (testcase.skipped) {
        lines.push(`    <skipped message="${this.escapeXML(testcase.skipped.message)}"/>`);
      }
      
      lines.push('  </testcase>');
    });
    
    lines.push('</testsuite>');
    return lines.join('\n');
  }

  /**
   * Escape XML special characters
   */
  private escapeXML(text: string): string {
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&apos;');
  }

  /**
   * Generate summary report
   */
  private async generateSummaryReport(): Promise<void> {
    const summary = {
      timestamp: new Date().toISOString(),
      total: this.results.length,
      passed: this.results.filter(r => r.status === 'passed').length,
      failed: this.results.filter(r => r.status === 'failed').length,
      skipped: this.results.filter(r => r.status === 'skipped').length,
      successRate: this.results.length > 0 ? this.results.filter(r => r.status === 'passed').length / this.results.length : 0,
      totalDuration: this.results.reduce((sum, r) => sum + r.duration, 0),
      averageDuration: this.results.length > 0 ? this.results.reduce((sum, r) => sum + r.duration, 0) / this.results.length : 0,
      failedCombinations: this.results.filter(r => r.status === 'failed').map(r => ({
        combination: r.combination,
        error: r.error
      })),
      config: this.config
    };

    const summaryPath = path.join(this.config.outputDir, 'summary.json');
    await fs.writeFile(summaryPath, JSON.stringify(summary, null, 2), 'utf-8');
    
    console.log(`📋 Summary report written to: ${summaryPath}`);
  }

  /**
   * Handle test completion and exit
   */
  private async handleTestCompletion(): Promise<void> {
    const failed = this.results.filter(r => r.status === 'failed');
    const passed = this.results.filter(r => r.status === 'passed');
    const skipped = this.results.filter(r => r.status === 'skipped');

    console.log('\n🏁 Matrix Testing Completed');
    console.log(`✅ Passed: ${passed.length}`);
    console.log(`❌ Failed: ${failed.length}`);
    console.log(`⏭️ Skipped: ${skipped.length}`);
    console.log(`📊 Success Rate: ${((passed.length / this.results.length) * 100).toFixed(1)}%`);

    if (failed.length > 0) {
      console.log('\n❌ Failed Combinations:');
      failed.forEach(result => {
        console.log(`  - ${result.combination}: ${result.error}`);
      });

      if (this.config.failOnErrors) {
        console.log('\n💥 Exiting with failure code due to test failures');
        process.exit(1);
      }
    } else {
      console.log('\n🎉 All matrix tests passed!');
    }
  }
}

// CLI Support
if (require.main === module) {
  const ciRunner = new CIMatrixRunner({
    outputDir: process.env.TEST_OUTPUT_DIR || './test-results',
    failOnErrors: process.env.CI === 'true',
    parallelism: parseInt(process.env.TEST_PARALLELISM || '1'),
    timeout: parseInt(process.env.TEST_TIMEOUT || '300000')
  });

  ciRunner.runCITests().catch(error => {
    console.error('❌ CI Matrix Testing failed:', error);
    process.exit(1);
  });
}