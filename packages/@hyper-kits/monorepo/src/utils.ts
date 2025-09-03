/**
 * Utility functions for monorepo template generation and file management
 */

import type { MonorepoConfig, TemplateContext } from './index';
import { validateToolCompatibility } from './validation';
import type { FileCondition, TemplateFile } from './composition';
import * as path from 'path';

/**
 * Validates a monorepo configuration object with compatibility checking
 */
export function normalizeMonorepoConfig(config: Partial<MonorepoConfig>): MonorepoConfig {
  if (!config.name || typeof config.name !== 'string') {
    throw new Error('name is required and must be a string');
  }
  
  const validPackageManagers = ['bun', 'npm', 'yarn', 'pnpm'];
  const validLinters = ['eslint', 'biome'];
  const validFormatters = ['prettier', 'dprint', 'biome-integrated'];
  const validTestFrameworks = ['vitest', 'bun-test', 'jest'];
  
  const validatedConfig: MonorepoConfig = {
    name: config.name,
    packageManager: config.packageManager && validPackageManagers.includes(config.packageManager) 
      ? config.packageManager as any 
      : 'bun',
    linter: config.linter && validLinters.includes(config.linter) 
      ? config.linter as any 
      : 'eslint',
    formatter: config.formatter && validFormatters.includes(config.formatter) 
      ? config.formatter as any 
      : 'prettier',
    testFramework: config.testFramework && validTestFrameworks.includes(config.testFramework) 
      ? config.testFramework as any 
      : 'vitest',
    tools: config.tools || {},
    moon: config.moon || {}
  };
  
  // Run compatibility validation
  const validationResult = validateToolCompatibility(validatedConfig);
  if (!validationResult.valid) {
    const errorMessages = validationResult.issues
      .filter(issue => issue.severity === 'error')
      .map(error => error.message);
    throw new Error(`Invalid tool combination: ${errorMessages.join(', ')}`);
  }
  
  return validatedConfig;
}

/**
 * Generates a package name for the monorepo based on the project name
 */
export function generatePackageName(projectName: string, scope?: string): string {
  const cleanName = projectName.toLowerCase().replace(/[^a-z0-9-]/g, '-');
  return scope ? `@${scope}/${cleanName}` : cleanName;
}

/**
 * Determines the appropriate Moon toolchain configuration based on the selected tools
 */
export function generateMoonToolchains(config: MonorepoConfig) {
  const toolchains: Record<string, any> = {
    node: {
      packageManager: config.packageManager,
      version: '20.0.0'
    }
  };
  
  if (config.testFramework === 'bun-test') {
    toolchains.bun = {
      version: '1.0.0'
    };
  }
  
  return toolchains;
}

/**
 * Generates Moon tasks configuration based on selected tools
 */
export function generateMoonTasks(config: MonorepoConfig) {
  const tasks: Record<string, any> = {
    build: {
      command: 'tsc --build',
      inputs: ['src/**/*', 'tsconfig.json'],
      outputs: ['lib']
    }
  };
  
  if (config.linter === 'eslint') {
    tasks.lint = {
      command: 'eslint src --ext .ts,.js',
      inputs: ['src/**/*', '.eslintrc.js']
    };
  } else if (config.linter === 'biome') {
    tasks.lint = {
      command: 'biome lint src',
      inputs: ['src/**/*', 'biome.json']
    };
  }
  
  if (config.formatter === 'prettier') {
    tasks.format = {
      command: 'prettier --write src',
      inputs: ['src/**/*', '.prettierrc']
    };
  } else if (config.formatter === 'dprint') {
    tasks.format = {
      command: 'dprint fmt',
      inputs: ['src/**/*', 'dprint.json']
    };
  }
  
  if (config.testFramework === 'vitest') {
    tasks.test = {
      command: 'vitest run',
      inputs: ['src/**/*', 'tests/**/*', 'vitest.config.ts']
    };
  } else if (config.testFramework === 'bun-test') {
    tasks.test = {
      command: 'bun test',
      inputs: ['src/**/*', 'tests/**/*']
    };
  }
  
  return tasks;
}

/**
 * File management utilities for template composition
 */

/**
 * Check if a template file should be included based on context
 */
export function shouldIncludeFile(filePath: string, context: TemplateContext): boolean {
  // Package manager specific files
  if (filePath.includes('bunfig.toml') || filePath.includes('bun.lock')) {
    return context.packageManager === 'bun';
  }
  
  if (filePath.includes('package-lock.json')) {
    return context.packageManager === 'npm';
  }
  
  if (filePath.includes('yarn.lock')) {
    return context.packageManager === 'yarn';
  }
  
  if (filePath.includes('pnpm-lock.yaml')) {
    return context.packageManager === 'pnpm';
  }

  // Linter configuration files
  if (filePath.includes('eslint') && !filePath.includes('ignore')) {
    return context.linter === 'eslint';
  }
  
  if (filePath.includes('biome.json')) {
    return context.linter === 'biome';
  }

  // Formatter configuration files  
  if (filePath.includes('prettier') && !filePath.includes('ignore')) {
    return context.formatter === 'prettier';
  }
  
  if (filePath.includes('dprint.json')) {
    return context.formatter === 'dprint';
  }

  // Test framework configuration files
  if (filePath.includes('vitest')) {
    return context.testFramework === 'vitest';
  }
  
  if (filePath.includes('jest')) {
    return context.testFramework === 'jest';
  }
  
  if (filePath.includes('bun.test.ts')) {
    return context.testFramework === 'bun-test';
  }

  // Optional feature files
  if (filePath.includes('.vscode')) {
    return Boolean((context as any).includeVSCodeSettings);
  }
  
  if (filePath.includes('.github')) {
    return Boolean((context as any).includeGitHubActions);
  }
  
  // Default to include if no specific conditions
  return true;
}

/**
 * Get template file category based on file path
 */
export function getTemplateFileCategory(filePath: string): 'core' | 'tool-specific' | 'optional' | 'preset' {
  const coreFiles = [
    'package.json',
    'tsconfig.json', 
    'tsconfig.lib.json',
    '.moon/workspace.yml',
    'moon.yml',
    'README.md'
  ];

  const toolSpecificPatterns = [
    'eslint', 'biome', 'prettier', 'dprint', 'vitest', 'jest', 'bunfig'
  ];

  const optionalPatterns = [
    '.vscode', '.github', '.gitignore', '.gitattributes', 'CONTRIBUTING'
  ];

  const fileName = path.basename(filePath, '.ejs.t');
  
  // Check core files
  if (coreFiles.some(core => fileName.includes(core))) {
    return 'core';
  }
  
  // Check tool-specific files
  if (toolSpecificPatterns.some(pattern => filePath.includes(pattern))) {
    return 'tool-specific';
  }
  
  // Check optional files
  if (optionalPatterns.some(pattern => filePath.includes(pattern))) {
    return 'optional';
  }
  
  return 'preset';
}

/**
 * Generate template file metadata
 */
export function createTemplateFile(filePath: string, templateRoot: string = '_templates'): TemplateFile {
  const relativePath = path.relative(templateRoot, filePath);
  const conditions = getFileConditionsFromPath(relativePath);
  
  return {
    path: filePath,
    relativePath,
    conditions,
    isConditional: conditions.length > 0,
    category: getTemplateFileCategory(relativePath)
  };
}

/**
 * Extract file conditions from file path patterns
 */
function getFileConditionsFromPath(filePath: string): FileCondition[] {
  const conditions: FileCondition[] = [];
  
  // Package manager conditions
  if (filePath.includes('bunfig') || filePath.includes('bun.lock')) {
    conditions.push({
      pattern: filePath,
      condition: 'packageManager === "bun"',
      description: 'Bun package manager specific files'
    });
  }
  
  if (filePath.includes('package-lock.json')) {
    conditions.push({
      pattern: filePath,
      condition: 'packageManager === "npm"',
      description: 'npm package manager specific files'
    });
  }
  
  // Linter conditions
  if (filePath.includes('eslint')) {
    conditions.push({
      pattern: filePath,
      condition: 'linter === "eslint"',
      required: true,
      description: 'ESLint configuration files'
    });
  }
  
  if (filePath.includes('biome.json')) {
    conditions.push({
      pattern: filePath,
      condition: 'linter === "biome"',
      required: true,
      description: 'Biome configuration files'
    });
  }
  
  // Formatter conditions
  if (filePath.includes('prettier')) {
    conditions.push({
      pattern: filePath,
      condition: 'formatter === "prettier"',
      required: true,
      description: 'Prettier configuration files'
    });
  }
  
  if (filePath.includes('dprint')) {
    conditions.push({
      pattern: filePath,
      condition: 'formatter === "dprint"',
      required: true,
      description: 'dprint configuration files'
    });
  }
  
  // Test framework conditions
  if (filePath.includes('vitest')) {
    conditions.push({
      pattern: filePath,
      condition: 'testFramework === "vitest"',
      required: true,
      description: 'Vitest configuration files'
    });
  }
  
  if (filePath.includes('jest')) {
    conditions.push({
      pattern: filePath,
      condition: 'testFramework === "jest"',
      required: true,
      description: 'Jest configuration files'
    });
  }
  
  if (filePath.includes('bun.test')) {
    conditions.push({
      pattern: filePath,
      condition: 'testFramework === "bun-test"',
      required: true,
      description: 'Bun test configuration files'
    });
  }
  
  return conditions;
}

/**
 * Normalize project name for use in package.json and file paths
 */
export function normalizeProjectName(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9-_]/g, '-')
    .replace(/^-+|-+$/g, '')
    .replace(/-+/g, '-');
}

/**
 * Generate package.json dependencies based on tool selection
 */
export function generatePackageJsonDependencies(config: MonorepoConfig): {
  devDependencies: Record<string, string>;
  dependencies: Record<string, string>;
} {
  const devDependencies: Record<string, string> = {
    'typescript': '^5.0.0',
    '@moonrepo/cli': '^1.0.0'
  };
  
  const dependencies: Record<string, string> = {};

  // Add linter dependencies
  if (config.linter === 'eslint') {
    devDependencies['eslint'] = '^8.0.0';
    devDependencies['@typescript-eslint/eslint-plugin'] = '^6.0.0';
    devDependencies['@typescript-eslint/parser'] = '^6.0.0';
  } else if (config.linter === 'biome') {
    devDependencies['@biomejs/biome'] = '^1.0.0';
  }

  // Add formatter dependencies
  if (config.formatter === 'prettier') {
    devDependencies['prettier'] = '^3.0.0';
  } else if (config.formatter === 'dprint') {
    devDependencies['dprint'] = '^0.45.0';
  }

  // Add test framework dependencies
  if (config.testFramework === 'vitest') {
    devDependencies['vitest'] = '^1.0.0';
    devDependencies['@vitest/ui'] = '^1.0.0';
  } else if (config.testFramework === 'jest') {
    devDependencies['jest'] = '^29.0.0';
    devDependencies['@types/jest'] = '^29.0.0';
    devDependencies['ts-jest'] = '^29.0.0';
  }
  // Bun test doesn't need additional dependencies

  // Add tool-specific dependencies
  if (config.tools?.husky) {
    devDependencies['husky'] = '^8.0.0';
  }
  
  if (config.tools?.lintStaged) {
    devDependencies['lint-staged'] = '^14.0.0';
  }
  
  if (config.tools?.commitlint) {
    devDependencies['@commitlint/cli'] = '^17.0.0';
    devDependencies['@commitlint/config-conventional'] = '^17.0.0';
  }
  
  if (config.tools?.changesets) {
    devDependencies['@changesets/cli'] = '^2.26.0';
  }

  return { devDependencies, dependencies };
}

/**
 * Get appropriate file extensions for template files based on configuration
 */
export function getConfigFileExtensions(config: MonorepoConfig): Record<string, string> {
  return {
    eslint: config.linter === 'eslint' ? '.js' : '',
    prettier: config.formatter === 'prettier' ? '.json' : '',
    jest: config.testFramework === 'jest' ? '.js' : '',
    vitest: config.testFramework === 'vitest' ? '.ts' : ''
  };
}