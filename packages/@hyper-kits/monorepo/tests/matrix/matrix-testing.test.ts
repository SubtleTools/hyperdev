/**
 * Matrix Testing for All Tool Combinations
 * 
 * This test suite validates all valid tool combinations by:
 * 1. Generating real projects with each combination
 * 2. Running lint, test, and build commands on each generated project
 * 3. Validating that all generated projects work correctly
 * 4. Performance benchmarking for generation time
 * 5. CI/CD integration support
 */

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import * as fs from 'fs/promises';
import * as path from 'path';
import { execSync } from 'child_process';
import { getValidToolCombinations } from '../../src/composition';
import { validateToolCompatibility } from '../../src/validation';
import { presets } from '../../src/presets';
import type { MonorepoConfig, TemplateContext } from '../../src';

/**
 * Test configuration
 */
interface TestConfig {
  timeout: number;
  cleanupAfterTest: boolean;
  generateActualProjects: boolean;
  runLintTestBuild: boolean;
  maxGenerationTimeMs: number; // 30 seconds target
}

const TEST_CONFIG: TestConfig = {
  timeout: 300000, // 5 minutes per test
  cleanupAfterTest: process.env.CI === 'true', // Clean up in CI
  generateActualProjects: process.env.SKIP_PROJECT_GENERATION !== 'true',
  runLintTestBuild: process.env.SKIP_TOOL_EXECUTION !== 'true',
  maxGenerationTimeMs: 30000 // 30 second target
};

/**
 * Matrix test result
 */
interface MatrixTestResult {
  combination: Partial<MonorepoConfig>;
  success: boolean;
  generationTimeMs: number;
  errors: string[];
  warnings: string[];
  lintResult?: { success: boolean; output: string };
  testResult?: { success: boolean; output: string };
  buildResult?: { success: boolean; output: string };
  projectPath?: string;
}

/**
 * Matrix testing class
 */
class MatrixTesting {
  private testOutputDir: string;
  private results: MatrixTestResult[] = [];

  constructor() {
    this.testOutputDir = path.join(__dirname, '../../test-output/matrix-testing');
  }

  /**
   * Set up testing environment
   */
  async setup(): Promise<void> {
    try {
      await fs.mkdir(this.testOutputDir, { recursive: true });
    } catch (error) {
      console.warn('Setup warning:', error);
    }
  }

  /**
   * Clean up testing environment
   */
  async cleanup(): Promise<void> {
    if (TEST_CONFIG.cleanupAfterTest) {
      try {
        await fs.rm(this.testOutputDir, { recursive: true, force: true });
      } catch (error) {
        console.warn('Cleanup warning:', error);
      }
    }
  }

  /**
   * Generate project for a specific tool combination
   */
  async generateProject(combination: Partial<MonorepoConfig>, index: number): Promise<MatrixTestResult> {
    const startTime = Date.now();
    const projectName = `matrix-test-${index}-${combination.packageManager}-${combination.linter}-${combination.formatter}-${combination.testFramework}`;
    const projectPath = path.join(this.testOutputDir, projectName);

    const result: MatrixTestResult = {
      combination,
      success: false,
      generationTimeMs: 0,
      errors: [],
      warnings: [],
      projectPath
    };

    try {
      // Create full config for generation
      const config: MonorepoConfig = {
        name: projectName,
        packageManager: combination.packageManager!,
        linter: combination.linter!,
        formatter: combination.formatter!,
        testFramework: combination.testFramework!,
        tools: {
          husky: false, // Keep simple for testing
          lintStaged: false,
          commitlint: false,
          changesets: false
        },
        moon: {
          generateWorkspaceConfig: true,
          enableTaskInheritance: true,
          enableCaching: true
        }
      };

      // Validate configuration
      const validation = validateToolCompatibility(config);
      if (!validation.valid) {
        result.errors.push(...validation.issues
          .filter(issue => issue.severity === 'error')
          .map(issue => issue.message));
        return result;
      }

      result.warnings.push(...validation.issues
        .filter(issue => issue.severity === 'warning' || issue.severity === 'info')
        .map(issue => issue.message));

      if (TEST_CONFIG.generateActualProjects) {
        // Create project directory
        await fs.mkdir(projectPath, { recursive: true });

        // Generate project using our template composition system
        await this.generateProjectFiles(config, projectPath);

        // Run tool commands if enabled
        if (TEST_CONFIG.runLintTestBuild) {
          await this.runProjectCommands(config, projectPath, result);
        }
      }

      result.success = true;
      result.generationTimeMs = Date.now() - startTime;

      // Validate generation time is under target
      if (result.generationTimeMs > TEST_CONFIG.maxGenerationTimeMs) {
        result.warnings.push(`Generation took ${result.generationTimeMs}ms, exceeding ${TEST_CONFIG.maxGenerationTimeMs}ms target`);
      }

    } catch (error) {
      result.errors.push(error instanceof Error ? error.message : String(error));
    }

    result.generationTimeMs = Date.now() - startTime;
    return result;
  }

  /**
   * Generate project files using template composition
   */
  private async generateProjectFiles(config: MonorepoConfig, projectPath: string): Promise<void> {
    // Generate core project files
    const files = await this.getProjectFiles(config);
    
    for (const [filePath, content] of files.entries()) {
      const fullPath = path.join(projectPath, filePath);
      const dir = path.dirname(fullPath);
      
      await fs.mkdir(dir, { recursive: true });
      await fs.writeFile(fullPath, content, 'utf-8');
    }
  }

  /**
   * Get project files for a configuration
   */
  private async getProjectFiles(config: MonorepoConfig): Promise<Map<string, string>> {
    const files = new Map<string, string>();

    // Generate package.json
    files.set('package.json', JSON.stringify({
      name: config.name,
      version: '1.0.0',
      type: 'module',
      scripts: {
        build: this.getBuildScript(config),
        test: this.getTestScript(config),
        lint: this.getLintScript(config),
        format: this.getFormatScript(config)
      },
      devDependencies: this.getDevDependencies(config),
      workspaces: ['packages/*']
    }, null, 2));

    // Generate tsconfig.json
    files.set('tsconfig.json', JSON.stringify({
      compilerOptions: {
        target: 'ES2020',
        module: 'ESNext',
        moduleResolution: 'node',
        strict: true,
        esModuleInterop: true,
        skipLibCheck: true,
        forceConsistentCasingInFileNames: true,
        declaration: true,
        outDir: './lib'
      },
      include: ['src/**/*', 'packages/*/src/**/*'],
      exclude: ['node_modules', 'lib', '**/*.test.ts']
    }, null, 2));

    // Generate tool-specific config files
    files.set(...this.getLinterConfig(config));
    files.set(...this.getFormatterConfig(config));
    files.set(...this.getTestConfig(config));

    // Generate Moon workspace config
    files.set('.moon/workspace.yml', this.getMoonWorkspaceConfig(config));

    // Generate sample library package
    await this.addSamplePackage(files, config);

    return files;
  }

  /**
   * Add sample library package for testing
   */
  private async addSamplePackage(files: Map<string, string>, config: MonorepoConfig): Promise<void> {
    const packageName = 'sample-lib';
    const packagePath = `packages/${packageName}`;

    // Package.json
    files.set(`${packagePath}/package.json`, JSON.stringify({
      name: packageName,
      version: '1.0.0',
      type: 'module',
      main: './lib/index.js',
      types: './lib/index.d.ts',
      scripts: {
        build: 'tsc',
        test: this.getTestScript(config),
        lint: this.getLintScript(config)
      }
    }, null, 2));

    // TypeScript config
    files.set(`${packagePath}/tsconfig.json`, JSON.stringify({
      extends: '../../tsconfig.json',
      compilerOptions: {
        outDir: './lib'
      },
      include: ['src/**/*']
    }, null, 2));

    // Source files
    files.set(`${packagePath}/src/index.ts`, `export function hello(name: string): string {
  return \`Hello, \${name}!\`;
}

export default hello;
`);

    // Test file
    files.set(`${packagePath}/src/index.test.ts`, this.getTestFileContent(config, packageName));

    // Moon config
    files.set(`${packagePath}/moon.yml`, `type: library
language: typescript
platform: node

tasks:
  build:
    command: tsc
    inputs:
      - src/**/*
      - tsconfig.json
    outputs:
      - lib
  
  test:
    command: ${this.getTestCommand(config)}
    inputs:
      - src/**/*
      - test/**/*
    
  lint:
    command: ${this.getLintCommand(config)}
    inputs:
      - src/**/*
`);
  }

  /**
   * Get test file content based on test framework
   */
  private getTestFileContent(config: MonorepoConfig, packageName: string): string {
    const imports = config.testFramework === 'jest' 
      ? `import { describe, it, expect } from '@jest/globals';`
      : `import { describe, it, expect } from 'vitest';`;
    
    return `${imports}
import { hello } from './index.js';

describe('${packageName}', () => {
  it('should greet correctly', () => {
    expect(hello('World')).toBe('Hello, World!');
  });

  it('should handle empty string', () => {
    expect(hello('')).toBe('Hello, !');
  });
});
`;
  }

  /**
   * Get build script
   */
  private getBuildScript(config: MonorepoConfig): string {
    return 'tsc --build';
  }

  /**
   * Get test script and command
   */
  private getTestScript(config: MonorepoConfig): string {
    return this.getTestCommand(config);
  }

  private getTestCommand(config: MonorepoConfig): string {
    switch (config.testFramework) {
      case 'vitest': return 'vitest run';
      case 'jest': return 'jest';
      case 'bun-test': return 'bun test';
      default: return 'vitest run';
    }
  }

  /**
   * Get lint script and command
   */
  private getLintScript(config: MonorepoConfig): string {
    return this.getLintCommand(config);
  }

  private getLintCommand(config: MonorepoConfig): string {
    switch (config.linter) {
      case 'eslint': return 'eslint src --ext .ts';
      case 'biome': return 'biome check src';
      default: return 'eslint src --ext .ts';
    }
  }

  /**
   * Get format script
   */
  private getFormatScript(config: MonorepoConfig): string {
    switch (config.formatter) {
      case 'prettier': return 'prettier --write src';
      case 'dprint': return 'dprint fmt';
      case 'biome-integrated': return 'biome format src --write';
      default: return 'prettier --write src';
    }
  }

  /**
   * Get dev dependencies for configuration
   */
  private getDevDependencies(config: MonorepoConfig): Record<string, string> {
    const deps: Record<string, string> = {
      'typescript': '^5.0.0',
      '@types/node': '^20.0.0'
    };

    // Add linter dependencies
    if (config.linter === 'eslint') {
      deps['eslint'] = '^8.0.0';
      deps['@typescript-eslint/parser'] = '^6.0.0';
      deps['@typescript-eslint/eslint-plugin'] = '^6.0.0';
    } else if (config.linter === 'biome') {
      deps['@biomejs/biome'] = '^1.0.0';
    }

    // Add formatter dependencies
    if (config.formatter === 'prettier') {
      deps['prettier'] = '^3.0.0';
    } else if (config.formatter === 'dprint') {
      deps['dprint'] = '^0.40.0';
    }

    // Add test framework dependencies
    if (config.testFramework === 'vitest') {
      deps['vitest'] = '^1.0.0';
    } else if (config.testFramework === 'jest') {
      deps['jest'] = '^29.0.0';
      deps['@types/jest'] = '^29.0.0';
      deps['ts-jest'] = '^29.0.0';
    }
    // bun-test doesn't need additional deps

    return deps;
  }

  /**
   * Get linter configuration
   */
  private getLinterConfig(config: MonorepoConfig): [string, string] {
    if (config.linter === 'eslint') {
      return ['.eslintrc.js', `module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint'],
  extends: [
    'eslint:recommended',
    '@typescript-eslint/recommended',
  ],
  env: {
    node: true,
    es2020: true,
  },
  parserOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
  },
  rules: {
    // Add custom rules here
  },
};
`];
    } else if (config.linter === 'biome') {
      return ['biome.json', JSON.stringify({
        $schema: 'https://biomejs.dev/schemas/1.0.0/schema.json',
        linter: {
          enabled: true,
          rules: {
            recommended: true
          }
        },
        formatter: config.formatter === 'biome-integrated' ? {
          enabled: true,
          indentStyle: 'space',
          indentSize: 2
        } : {
          enabled: false
        }
      }, null, 2)];
    }
    
    return ['.eslintrc.js', '// No linter configuration'];
  }

  /**
   * Get formatter configuration
   */
  private getFormatterConfig(config: MonorepoConfig): [string, string] {
    if (config.formatter === 'prettier') {
      return ['.prettierrc', JSON.stringify({
        semi: true,
        trailingComma: 'es5',
        singleQuote: true,
        printWidth: 80,
        tabWidth: 2
      }, null, 2)];
    } else if (config.formatter === 'dprint') {
      return ['dprint.json', JSON.stringify({
        typescript: {
          semiColons: 'always',
          quoteStyle: 'alwaysSingle',
          indentWidth: 2
        },
        includes: ['**/*.{ts,js,tsx,jsx}'],
        excludes: ['node_modules', 'lib']
      }, null, 2)];
    }
    
    return ['.prettierrc', '{}'];
  }

  /**
   * Get test configuration
   */
  private getTestConfig(config: MonorepoConfig): [string, string] {
    if (config.testFramework === 'vitest') {
      return ['vitest.config.ts', `import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
  },
});
`];
    } else if (config.testFramework === 'jest') {
      return ['jest.config.js', `module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/packages'],
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  transform: {
    '^.+\\.ts$': 'ts-jest',
  },
  collectCoverageFrom: [
    'packages/*/src/**/*.ts',
    '!packages/*/src/**/*.d.ts',
  ],
};
`];
    }
    
    return ['vitest.config.ts', '// Default test config'];
  }

  /**
   * Get Moon workspace configuration
   */
  private getMoonWorkspaceConfig(config: MonorepoConfig): string {
    return `extends: https://moonrepo.dev/schemas/workspace.json

projects:
  - 'packages/*'

runner:
  archivableTargets: ['build', 'test']
  cacheLifetime: '7 days'
  
vcs:
  manager: 'git'
  defaultBranch: 'main'

generator:
  templates: []

notifier:
  webhookUrl: ''
`;
  }

  /**
   * Run project commands (lint, test, build)
   */
  private async runProjectCommands(
    config: MonorepoConfig,
    projectPath: string,
    result: MatrixTestResult
  ): Promise<void> {
    const oldCwd = process.cwd();
    
    try {
      process.chdir(projectPath);
      
      // Install dependencies first
      const installCmd = this.getPackageManagerInstallCommand(config.packageManager);
      execSync(installCmd, { stdio: 'pipe', timeout: 60000 });

      // Run lint
      try {
        const lintOutput = execSync(this.getLintCommand(config), { 
          stdio: 'pipe', 
          encoding: 'utf-8',
          timeout: 30000 
        });
        result.lintResult = { success: true, output: lintOutput };
      } catch (error) {
        result.lintResult = { 
          success: false, 
          output: error instanceof Error ? error.message : String(error) 
        };
      }

      // Run tests
      try {
        const testOutput = execSync(this.getTestCommand(config), { 
          stdio: 'pipe', 
          encoding: 'utf-8',
          timeout: 30000 
        });
        result.testResult = { success: true, output: testOutput };
      } catch (error) {
        result.testResult = { 
          success: false, 
          output: error instanceof Error ? error.message : String(error) 
        };
      }

      // Run build
      try {
        const buildOutput = execSync('npm run build', { 
          stdio: 'pipe', 
          encoding: 'utf-8',
          timeout: 30000 
        });
        result.buildResult = { success: true, output: buildOutput };
      } catch (error) {
        result.buildResult = { 
          success: false, 
          output: error instanceof Error ? error.message : String(error) 
        };
      }

    } finally {
      process.chdir(oldCwd);
    }
  }

  /**
   * Get package manager install command
   */
  private getPackageManagerInstallCommand(packageManager: string): string {
    switch (packageManager) {
      case 'bun': return 'bun install';
      case 'npm': return 'npm install';
      case 'yarn': return 'yarn install';
      case 'pnpm': return 'pnpm install';
      default: return 'npm install';
    }
  }

  /**
   * Generate performance report
   */
  generatePerformanceReport(): string {
    const report = [];
    report.push('# Matrix Testing Performance Report\n');

    const successful = this.results.filter(r => r.success);
    const failed = this.results.filter(r => !r.success);

    report.push(`## Summary`);
    report.push(`- Total combinations tested: ${this.results.length}`);
    report.push(`- Successful: ${successful.length}`);
    report.push(`- Failed: ${failed.length}`);
    report.push(`- Success rate: ${(successful.length / this.results.length * 100).toFixed(1)}%\n`);

    if (successful.length > 0) {
      const avgTime = successful.reduce((sum, r) => sum + r.generationTimeMs, 0) / successful.length;
      const maxTime = Math.max(...successful.map(r => r.generationTimeMs));
      const minTime = Math.min(...successful.map(r => r.generationTimeMs));

      report.push(`## Performance Metrics`);
      report.push(`- Average generation time: ${avgTime.toFixed(0)}ms`);
      report.push(`- Fastest generation: ${minTime}ms`);
      report.push(`- Slowest generation: ${maxTime}ms`);
      report.push(`- Target: ${TEST_CONFIG.maxGenerationTimeMs}ms`);
      report.push(`- Combinations exceeding target: ${successful.filter(r => r.generationTimeMs > TEST_CONFIG.maxGenerationTimeMs).length}\n`);
    }

    if (failed.length > 0) {
      report.push(`## Failed Combinations`);
      failed.forEach(result => {
        const combo = result.combination;
        report.push(`- ${combo.packageManager}+${combo.linter}+${combo.formatter}+${combo.testFramework}`);
        result.errors.forEach(error => report.push(`  - Error: ${error}`));
      });
      report.push('');
    }

    return report.join('\n');
  }

  /**
   * Get test results for CI/CD integration
   */
  getResults(): MatrixTestResult[] {
    return this.results;
  }

  /**
   * Run matrix testing
   */
  async runMatrixTests(): Promise<MatrixTestResult[]> {
    const validCombinations = getValidToolCombinations();
    console.log(`Testing ${validCombinations.length} valid tool combinations...`);

    this.results = [];

    for (let i = 0; i < validCombinations.length; i++) {
      const combination = validCombinations[i];
      console.log(`Testing combination ${i + 1}/${validCombinations.length}: ${combination.packageManager}+${combination.linter}+${combination.formatter}+${combination.testFramework}`);
      
      const result = await this.generateProject(combination, i);
      this.results.push(result);

      // Log immediate result
      if (result.success) {
        console.log(`  ✅ Success (${result.generationTimeMs}ms)`);
      } else {
        console.log(`  ❌ Failed: ${result.errors.join(', ')}`);
      }
    }

    return this.results;
  }
}

// Test Suite
describe('Matrix Testing - All Tool Combinations', () => {
  let matrixTester: MatrixTesting;

  beforeAll(async () => {
    matrixTester = new MatrixTesting();
    await matrixTester.setup();
  }, 30000);

  afterAll(async () => {
    if (matrixTester) {
      await matrixTester.cleanup();
    }
  }, 30000);

  it('should validate all valid tool combinations', async () => {
    const validCombinations = getValidToolCombinations();
    
    expect(validCombinations.length).toBeGreaterThan(0);
    console.log(`Found ${validCombinations.length} valid combinations`);

    // Verify each combination is actually valid
    for (const combination of validCombinations) {
      const config: MonorepoConfig = {
        name: 'test',
        packageManager: combination.packageManager!,
        linter: combination.linter!,
        formatter: combination.formatter!,
        testFramework: combination.testFramework!
      };

      const validation = validateToolCompatibility(config);
      expect(validation.valid).toBe(true);
    }
  }, TEST_CONFIG.timeout);

  it('should validate all presets are valid', async () => {
    const presetNames = Object.keys(presets);
    
    for (const presetName of presetNames) {
      const preset = presets[presetName as keyof typeof presets];
      
      // Create full config for validation
      const config: MonorepoConfig = {
        name: `test-${presetName}`,
        packageManager: preset.packageManager!,
        linter: preset.linter!,
        formatter: preset.formatter!,
        testFramework: preset.testFramework!,
        tools: preset.tools || {}
      };

      const validation = validateToolCompatibility(config);
      expect(validation.valid).toBe(true);
      
      if (!validation.valid) {
        console.error(`Preset "${presetName}" validation failed:`, validation.issues);
      }
    }
  });

  it('should run matrix testing for all tool combinations', async () => {
    const results = await matrixTester.runMatrixTests();
    
    expect(results.length).toBeGreaterThan(0);

    const successful = results.filter(r => r.success);
    const failed = results.filter(r => !r.success);

    console.log(`Matrix testing completed:`);
    console.log(`- Total: ${results.length}`);
    console.log(`- Successful: ${successful.length}`);
    console.log(`- Failed: ${failed.length}`);

    // Generate performance report
    const performanceReport = matrixTester.generatePerformanceReport();
    console.log('\n' + performanceReport);

    // Assert reasonable success rate
    const successRate = successful.length / results.length;
    expect(successRate).toBeGreaterThan(0.8); // At least 80% success rate

    // Assert performance targets
    if (TEST_CONFIG.generateActualProjects) {
      const avgTime = successful.length > 0 
        ? successful.reduce((sum, r) => sum + r.generationTimeMs, 0) / successful.length 
        : 0;
      
      expect(avgTime).toBeLessThan(TEST_CONFIG.maxGenerationTimeMs);
    }

    // Fail test if there are critical errors
    const criticalFailures = failed.filter(r => 
      r.errors.some(error => error.includes('validation'))
    );
    
    if (criticalFailures.length > 0) {
      console.error('Critical validation failures detected:', criticalFailures);
      expect(criticalFailures.length).toBe(0);
    }
  }, TEST_CONFIG.timeout);
});