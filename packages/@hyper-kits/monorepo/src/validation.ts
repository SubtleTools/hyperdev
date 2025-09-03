/**
 * Tool Compatibility Validation Library
 * 
 * This module provides comprehensive validation for tool combinations in monorepo setups.
 * It prevents incompatible tool selections and provides helpful error messages and warnings.
 */

import type { MonorepoConfig } from './index';
import { 
  // HypergenError,                // Not used yet
  ValidationError, 
  // ErrorCode,                    // Not used yet
  // ErrorSeverity,                // Not used yet
  // createValidationError,        // Not used yet
  // createToolCompatibilityError, // Not used yet
  validateInput
} from './errors';

/**
 * Severity levels for validation issues
 */
export type ValidationSeverity = 'error' | 'warning' | 'info';

/**
 * Validation result interface
 */
export interface ValidationResult {
  valid: boolean;
  issues: ValidationIssue[];
  suggestions?: string[];
}

/**
 * Individual validation issue
 */
export interface ValidationIssue {
  severity: ValidationSeverity;
  code: string;
  message: string;
  details?: string;
  fix?: string;
  affectedTools: string[];
}

/**
 * Tool compatibility matrix defining all known compatibility rules
 */
export interface CompatibilityMatrix {
  packageManager: {
    [key: string]: {
      compatibleWith: string[];
      incompatibleWith: string[];
      warnings: string[];
    };
  };
  linter: {
    [key: string]: {
      compatibleFormatters: string[];
      incompatibleFormatters: string[];
      preferredFormatters: string[];
      warnings: { [formatter: string]: string };
    };
  };
  testFramework: {
    [key: string]: {
      requiredPackageManager?: string[];
      incompatibleWith: { [tool: string]: string[] };
      performanceNotes: string[];
    };
  };
  combinations: Array<{
    condition: (config: MonorepoConfig) => boolean;
    severity: ValidationSeverity;
    message: string;
    fix?: string;
    code: string;
  }>;
}

/**
 * Comprehensive compatibility matrix with all known compatibility rules
 */
const COMPATIBILITY_MATRIX: CompatibilityMatrix = {
  packageManager: {
    bun: {
      compatibleWith: ['biome', 'eslint', 'prettier', 'dprint', 'vitest', 'bun-test'],
      incompatibleWith: [],
      warnings: []
    },
    npm: {
      compatibleWith: ['biome', 'eslint', 'prettier', 'dprint', 'vitest', 'jest'],
      incompatibleWith: [],
      warnings: ['bun-test requires Bun package manager']
    },
    yarn: {
      compatibleWith: ['biome', 'eslint', 'prettier', 'dprint', 'vitest', 'jest'],
      incompatibleWith: [],
      warnings: ['bun-test requires Bun package manager']
    },
    pnpm: {
      compatibleWith: ['biome', 'eslint', 'prettier', 'dprint', 'vitest', 'jest'],
      incompatibleWith: [],
      warnings: ['bun-test requires Bun package manager']
    }
  },
  linter: {
    eslint: {
      compatibleFormatters: ['prettier', 'dprint'],
      incompatibleFormatters: ['biome-integrated'],
      preferredFormatters: ['prettier'],
      warnings: {
        'dprint': 'dprint + ESLint combination may have overlapping rules - consider configuration review'
      }
    },
    biome: {
      compatibleFormatters: ['prettier', 'dprint', 'biome-integrated'],
      incompatibleFormatters: [],
      preferredFormatters: ['biome-integrated'],
      warnings: {
        'prettier': 'Using Biome linter with Prettier formatter - consider Biome integrated formatter for better performance',
        'dprint': 'Using Biome linter with dprint formatter - consider Biome integrated formatter for unified toolchain'
      }
    }
  },
  testFramework: {
    vitest: {
      incompatibleWith: {},
      performanceNotes: ['Vitest works well with all package managers', 'Consider Vite for build tooling alignment']
    },
    'bun-test': {
      requiredPackageManager: ['bun'],
      incompatibleWith: {},
      performanceNotes: ['Bun Test offers fastest test execution', 'Requires Bun as package manager']
    },
    jest: {
      incompatibleWith: {},
      performanceNotes: ['Jest has extensive ecosystem support', 'Consider Vitest for better TypeScript integration']
    }
  },
  combinations: [
    {
      condition: (config) => config.testFramework === 'bun-test' && config.packageManager !== 'bun',
      severity: 'error',
      message: 'Bun Test requires Bun as the package manager',
      fix: 'Change package manager to "bun" or select a different test framework',
      code: 'BUN_TEST_REQUIRES_BUN_PACKAGE_MANAGER'
    },
    {
      condition: (config) => config.linter === 'eslint' && config.formatter === 'biome-integrated',
      severity: 'error',
      message: 'Biome integrated formatter can only be used with Biome linter',
      fix: 'Change linter to "biome" or select "prettier" or "dprint" as formatter',
      code: 'BIOME_INTEGRATED_REQUIRES_BIOME_LINTER'
    },
    {
      condition: (config) => config.linter === 'biome' && config.formatter === 'prettier',
      severity: 'warning',
      message: 'Using Biome linter with Prettier formatter reduces performance benefits',
      fix: 'Consider using "biome-integrated" formatter for unified toolchain and better performance',
      code: 'BIOME_PRETTIER_SUBOPTIMAL'
    },
    {
      condition: (config) => config.linter === 'biome' && config.formatter === 'dprint',
      severity: 'warning',
      message: 'Using Biome linter with dprint formatter may have configuration overlaps',
      fix: 'Consider using "biome-integrated" formatter for unified configuration',
      code: 'BIOME_DPRINT_OVERLAP'
    },
    {
      condition: (config) => config.packageManager === 'npm' && config.testFramework === 'bun-test',
      severity: 'error',
      message: 'Bun Test framework requires Bun package manager',
      fix: 'Change package manager to "bun" or select "vitest" or "jest" as test framework',
      code: 'BUN_TEST_NPM_INCOMPATIBLE'
    },
    {
      condition: (config) => config.packageManager === 'yarn' && config.testFramework === 'bun-test',
      severity: 'error',
      message: 'Bun Test framework requires Bun package manager',
      fix: 'Change package manager to "bun" or select "vitest" or "jest" as test framework',
      code: 'BUN_TEST_YARN_INCOMPATIBLE'
    },
    {
      condition: (config) => config.packageManager === 'pnpm' && config.testFramework === 'bun-test',
      severity: 'error',
      message: 'Bun Test framework requires Bun package manager',
      fix: 'Change package manager to "bun" or select "vitest" or "jest" as test framework',
      code: 'BUN_TEST_PNPM_INCOMPATIBLE'
    },
    {
      condition: (config) => config.linter === 'eslint' && config.formatter === 'dprint',
      severity: 'info',
      message: 'ESLint and dprint combination works well but requires careful configuration to avoid conflicts',
      fix: 'Review ESLint and dprint configurations to ensure formatting rules don\'t conflict',
      code: 'ESLINT_DPRINT_CONFIG_REVIEW'
    },
    {
      condition: (config) => config.packageManager === 'bun' && config.testFramework === 'jest',
      severity: 'info',
      message: 'Using Jest with Bun package manager works but consider Bun Test or Vitest for better integration',
      fix: 'Consider switching to "bun-test" for full Bun ecosystem benefits or "vitest" for modern features',
      code: 'BUN_JEST_SUBOPTIMAL'
    }
  ]
};

/**
 * Validates a monorepo configuration against the compatibility matrix
 */
export function validateToolCompatibility(config: MonorepoConfig): ValidationResult {
  const issues: ValidationIssue[] = [];

  // Check combination rules
  for (const rule of COMPATIBILITY_MATRIX.combinations) {
    if (rule.condition(config)) {
      issues.push({
        severity: rule.severity,
        code: rule.code,
        message: rule.message,
        fix: rule.fix,
        affectedTools: getAffectedTools(config, rule.code)
      });
    }
  }

  // Check linter-formatter compatibility
  const linterConfig = COMPATIBILITY_MATRIX.linter[config.linter];
  if (linterConfig) {
    if (linterConfig.incompatibleFormatters.includes(config.formatter)) {
      issues.push({
        severity: 'error',
        code: 'LINTER_FORMATTER_INCOMPATIBLE',
        message: `${config.linter} linter is incompatible with ${config.formatter} formatter`,
        fix: `Use one of these compatible formatters: ${linterConfig.compatibleFormatters.join(', ')}`,
        affectedTools: [config.linter, config.formatter]
      });
    }

    // Add specific warnings
    const warningMessage = linterConfig.warnings[config.formatter];
    if (warningMessage) {
      issues.push({
        severity: 'warning',
        code: 'LINTER_FORMATTER_WARNING',
        message: warningMessage,
        affectedTools: [config.linter, config.formatter]
      });
    }
  }

  // Check test framework requirements
  const testConfig = COMPATIBILITY_MATRIX.testFramework[config.testFramework];
  if (testConfig && testConfig.requiredPackageManager) {
    if (!testConfig.requiredPackageManager.includes(config.packageManager)) {
      issues.push({
        severity: 'error',
        code: 'TEST_FRAMEWORK_PACKAGE_MANAGER_MISMATCH',
        message: `${config.testFramework} requires one of these package managers: ${testConfig.requiredPackageManager.join(', ')}`,
        fix: `Change package manager to: ${testConfig.requiredPackageManager.join(' or ')}`,
        affectedTools: [config.testFramework, config.packageManager]
      });
    }
  }

  const hasErrors = issues.some(issue => issue.severity === 'error');
  const suggestions = generateSuggestions(config, issues);

  return {
    valid: !hasErrors,
    issues,
    suggestions: suggestions.length > 0 ? suggestions : undefined
  };
}

/**
 * Validates if a specific tool combination is compatible
 */
export function isToolCombinationValid(
  packageManager: string,
  linter: string,
  formatter: string,
  testFramework: string
): boolean {
  const config: MonorepoConfig = {
    name: 'temp',
    packageManager: packageManager as any,
    linter: linter as any,
    formatter: formatter as any,
    testFramework: testFramework as any
  };

  return validateToolCompatibility(config).valid;
}

/**
 * Gets all compatible formatters for a given linter
 */
export function getCompatibleFormatters(linter: string): string[] {
  const linterConfig = COMPATIBILITY_MATRIX.linter[linter];
  return linterConfig ? linterConfig.compatibleFormatters : [];
}

/**
 * Gets all compatible test frameworks for a given package manager
 */
export function getCompatibleTestFrameworks(packageManager: string): string[] {
  const compatible: string[] = [];
  
  for (const [framework, config] of Object.entries(COMPATIBILITY_MATRIX.testFramework)) {
    if (!config.requiredPackageManager || config.requiredPackageManager.includes(packageManager)) {
      compatible.push(framework);
    }
  }
  
  return compatible;
}

/**
 * Gets performance notes for a specific tool
 */
export function getPerformanceNotes(testFramework: string): string[] {
  const testConfig = COMPATIBILITY_MATRIX.testFramework[testFramework];
  return testConfig ? testConfig.performanceNotes : [];
}

/**
 * Validates if a preset configuration is valid
 */
export function validatePreset(preset: Partial<MonorepoConfig>): ValidationResult {
  // Create a temporary config with defaults for validation
  const config: MonorepoConfig = {
    name: 'preset-validation',
    packageManager: preset.packageManager || 'bun',
    linter: preset.linter || 'eslint',
    formatter: preset.formatter || 'prettier',
    testFramework: preset.testFramework || 'vitest',
    tools: preset.tools || {},
    moon: preset.moon || {}
  };

  return validateToolCompatibility(config);
}

/**
 * Gets all validation errors for a configuration
 */
export function getValidationErrors(config: MonorepoConfig): ValidationIssue[] {
  const result = validateToolCompatibility(config);
  return result.issues.filter(issue => issue.severity === 'error');
}

/**
 * Gets all validation warnings for a configuration
 */
export function getValidationWarnings(config: MonorepoConfig): ValidationIssue[] {
  const result = validateToolCompatibility(config);
  return result.issues.filter(issue => issue.severity === 'warning');
}

/**
 * Checks if a configuration has any compatibility issues
 */
export function hasCompatibilityIssues(config: MonorepoConfig): boolean {
  const result = validateToolCompatibility(config);
  return result.issues.length > 0;
}

/**
 * Generates suggested fixes based on validation issues
 */
function generateSuggestions(config: MonorepoConfig, issues: ValidationIssue[]): string[] {
  const suggestions: string[] = [];
  const errorIssues = issues.filter(issue => issue.severity === 'error');

  if (errorIssues.length === 0) {
    return suggestions;
  }

  // Suggest preset alternatives
  suggestions.push('Consider using a pre-configured preset:');
  suggestions.push('• "modern-bun" - Bun + Biome + Bun Test (fastest setup)');
  suggestions.push('• "traditional-node" - npm + ESLint + Prettier + Jest (most compatible)');
  suggestions.push('• "performance" - pnpm + Biome + Vitest (optimized for speed)');
  suggestions.push('• "enterprise" - yarn + ESLint + Prettier + Jest (stable, mature tools)');

  // Specific tool combination suggestions
  if (config.testFramework === 'bun-test' && config.packageManager !== 'bun') {
    suggestions.push('For Bun Test: Use packageManager: "bun"');
  }

  if (config.linter === 'eslint' && config.formatter === 'biome-integrated') {
    suggestions.push('For Biome integrated formatter: Use linter: "biome"');
    suggestions.push('Alternatively: Use formatter: "prettier" with ESLint');
  }

  return suggestions;
}

/**
 * Gets the tools affected by a specific validation rule
 */
function getAffectedTools(config: MonorepoConfig, code: string): string[] {
  switch (code) {
    case 'BUN_TEST_REQUIRES_BUN_PACKAGE_MANAGER':
    case 'BUN_TEST_NPM_INCOMPATIBLE':
    case 'BUN_TEST_YARN_INCOMPATIBLE':
    case 'BUN_TEST_PNPM_INCOMPATIBLE':
      return [config.testFramework, config.packageManager];
    
    case 'BIOME_INTEGRATED_REQUIRES_BIOME_LINTER':
      return [config.linter, config.formatter];
    
    case 'BIOME_PRETTIER_SUBOPTIMAL':
    case 'BIOME_DPRINT_OVERLAP':
      return [config.linter, config.formatter];
    
    case 'ESLINT_DPRINT_CONFIG_REVIEW':
      return [config.linter, config.formatter];
    
    case 'BUN_JEST_SUBOPTIMAL':
      return [config.packageManager, config.testFramework];
    
    default:
      return [];
  }
}

/**
 * Enhanced input validation with comprehensive error handling
 */
export function validateMonorepoConfig(config: Partial<MonorepoConfig>): {
  valid: boolean;
  errors: ValidationError[];
  sanitizedConfig: MonorepoConfig;
} {
  const errors: ValidationError[] = [];
  const sanitizedConfig: Partial<MonorepoConfig> = {};

  // Validate project name
  const nameValidation = validateInput(config.name, 'name', {
    required: true,
    type: 'string',
    minLength: 1,
    maxLength: 50,
    pattern: /^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$/
  });
  
  if (!nameValidation.valid && nameValidation.error) {
    errors.push(nameValidation.error);
  } else {
    sanitizedConfig.name = nameValidation.sanitized;
  }

  // Validate package manager
  const pmValidation = validateInput(config.packageManager, 'packageManager', {
    required: true,
    type: 'string',
    allowedValues: ['bun', 'npm', 'yarn', 'pnpm']
  });
  
  if (!pmValidation.valid && pmValidation.error) {
    errors.push(pmValidation.error);
  } else {
    sanitizedConfig.packageManager = pmValidation.sanitized || 'bun';
  }

  // Validate linter
  const linterValidation = validateInput(config.linter, 'linter', {
    required: true,
    type: 'string',
    allowedValues: ['eslint', 'biome']
  });
  
  if (!linterValidation.valid && linterValidation.error) {
    errors.push(linterValidation.error);
  } else {
    sanitizedConfig.linter = linterValidation.sanitized || 'eslint';
  }

  // Validate formatter
  const formatterValidation = validateInput(config.formatter, 'formatter', {
    required: true,
    type: 'string',
    allowedValues: ['prettier', 'dprint', 'biome-integrated']
  });
  
  if (!formatterValidation.valid && formatterValidation.error) {
    errors.push(formatterValidation.error);
  } else {
    sanitizedConfig.formatter = formatterValidation.sanitized || 'prettier';
  }

  // Validate test framework
  const testValidation = validateInput(config.testFramework, 'testFramework', {
    required: true,
    type: 'string',
    allowedValues: ['vitest', 'bun-test', 'jest']
  });
  
  if (!testValidation.valid && testValidation.error) {
    errors.push(testValidation.error);
  } else {
    sanitizedConfig.testFramework = testValidation.sanitized || 'vitest';
  }

  // Validate tools configuration if present
  if (config.tools && typeof config.tools === 'object') {
    sanitizedConfig.tools = validateToolsConfig(config.tools);
  } else {
    sanitizedConfig.tools = {};
  }

  // Validate moon configuration if present
  if (config.moon && typeof config.moon === 'object') {
    sanitizedConfig.moon = validateMoonConfig(config.moon);
  } else {
    sanitizedConfig.moon = {};
  }

  return {
    valid: errors.length === 0,
    errors,
    sanitizedConfig: sanitizedConfig as MonorepoConfig
  };
}

/**
 * Validate tools configuration object
 */
function validateToolsConfig(tools: any): Record<string, any> {
  const sanitized: Record<string, any> = {};
  
  // Validate common tool configurations
  if (tools.typescript !== undefined) {
    const tsValidation = validateInput(tools.typescript, 'tools.typescript', {
      type: 'boolean'
    });
    if (tsValidation.valid) {
      sanitized.typescript = tsValidation.sanitized;
    }
  }

  if (tools.storybook !== undefined) {
    const sbValidation = validateInput(tools.storybook, 'tools.storybook', {
      type: 'boolean'
    });
    if (sbValidation.valid) {
      sanitized.storybook = sbValidation.sanitized;
    }
  }

  if (tools.docker !== undefined) {
    const dockerValidation = validateInput(tools.docker, 'tools.docker', {
      type: 'boolean'
    });
    if (dockerValidation.valid) {
      sanitized.docker = dockerValidation.sanitized;
    }
  }

  return sanitized;
}

/**
 * Validate moon configuration object
 */
function validateMoonConfig(moon: any): Record<string, any> {
  const sanitized: Record<string, any> = {};
  
  if (moon.toolchain !== undefined) {
    const toolchainValidation = validateInput(moon.toolchain, 'moon.toolchain', {
      type: 'string',
      allowedValues: ['node', 'bun', 'deno']
    });
    if (toolchainValidation.valid) {
      sanitized.toolchain = toolchainValidation.sanitized;
    }
  }

  if (moon.projects !== undefined && Array.isArray(moon.projects)) {
    sanitized.projects = moon.projects.filter((project: any) => 
      typeof project === 'string' && project.length > 0
    );
  }

  return sanitized;
}

/**
 * Comprehensive validation that combines input validation and compatibility checking
 */
export function validateMonorepoConfigComplete(config: Partial<MonorepoConfig>): ValidationResult {
  // First validate inputs
  const inputValidation = validateMonorepoConfig(config);
  
  if (!inputValidation.valid) {
    return {
      valid: false,
      issues: inputValidation.errors.map(error => ({
        severity: 'error' as ValidationSeverity,
        code: error.code,
        message: error.userMessage,
        details: error.context.field ? `Field: ${error.context.field}` : undefined,
        fix: error.suggestions[0]?.description,
        affectedTools: [error.context.field || 'unknown']
      }))
    };
  }

  // Then validate compatibility
  return validateToolCompatibility(inputValidation.sanitizedConfig);
}

/**
 * Validate environment and system requirements
 */
export function validateSystemRequirements(): {
  valid: boolean;
  missing: string[];
  warnings: string[];
} {
  const missing: string[] = [];
  const warnings: string[] = [];

  // Check for Node.js
  try {
    const nodeVersion = process.version;
    const majorVersion = parseInt(nodeVersion.slice(1).split('.')[0]);
    if (majorVersion < 16) {
      warnings.push(`Node.js ${nodeVersion} detected. Recommended: v16 or higher`);
    }
  } catch {
    missing.push('Node.js');
  }

  // Check for git
  try {
    require('child_process').execSync('git --version', { stdio: 'ignore' });
  } catch {
    missing.push('git');
  }

  return {
    valid: missing.length === 0,
    missing,
    warnings
  };
}

/**
 * Validate project directory structure and permissions
 */
export async function validateProjectDirectory(targetPath: string): Promise<{
  valid: boolean;
  issues: string[];
  canWrite: boolean;
  isEmpty: boolean;
}> {
  const issues: string[] = [];
  let canWrite = false;
  let isEmpty = true;

  try {
    const fs = require('fs').promises;
    const path = require('path');

    // Check if directory exists
    try {
      const stats = await fs.stat(targetPath);
      if (!stats.isDirectory()) {
        issues.push(`Target path exists but is not a directory: ${targetPath}`);
        return { valid: false, issues, canWrite: false, isEmpty: false };
      }
    } catch (error: any) {
      if (error.code === 'ENOENT') {
        // Directory doesn't exist, try to create it
        try {
          await fs.mkdir(targetPath, { recursive: true });
        } catch (createError: any) {
          issues.push(`Cannot create directory: ${createError.message}`);
          return { valid: false, issues, canWrite: false, isEmpty: false };
        }
      } else {
        issues.push(`Cannot access target directory: ${error.message}`);
        return { valid: false, issues, canWrite: false, isEmpty: false };
      }
    }

    // Check write permissions
    try {
      const testFile = path.join(targetPath, '.write-test');
      await fs.writeFile(testFile, 'test');
      await fs.unlink(testFile);
      canWrite = true;
    } catch (error: any) {
      issues.push(`No write permission to target directory: ${error.message}`);
      canWrite = false;
    }

    // Check if directory is empty
    try {
      const files = await fs.readdir(targetPath);
      isEmpty = files.length === 0;
      if (!isEmpty) {
        issues.push(`Target directory is not empty (${files.length} items found)`);
      }
    } catch (error: any) {
      issues.push(`Cannot read target directory: ${error.message}`);
    }

  } catch (error: any) {
    issues.push(`Unexpected error validating directory: ${error.message}`);
  }

  return {
    valid: issues.length === 0,
    issues,
    canWrite,
    isEmpty
  };
}

/**
 * Validate package manager availability and version
 */
export async function validatePackageManager(packageManager: string): Promise<{
  available: boolean;
  version?: string;
  issues: string[];
}> {
  const issues: string[] = [];
  let version: string | undefined;
  let available = false;

  try {
    const { execSync } = require('child_process');
    const versionCommand = `${packageManager} --version`;
    
    const output = execSync(versionCommand, { 
      encoding: 'utf8', 
      timeout: 5000,
      stdio: 'pipe'
    });
    
    version = output.trim();
    available = true;

    // Check for minimum versions
    const minVersions: Record<string, string> = {
      'node': '16.0.0',
      'bun': '0.6.0',
      'npm': '7.0.0',
      'yarn': '1.22.0',
      'pnpm': '6.0.0'
    };

    const minVersion = minVersions[packageManager];
    if (minVersion && version) {
      // Basic version comparison (would need proper semver for production)
      const currentMajor = parseInt(version.split('.')[0]);
      const minMajor = parseInt(minVersion.split('.')[0]);
      
      if (currentMajor < minMajor) {
        issues.push(`${packageManager} version ${version} is below recommended minimum ${minVersion}`);
      }
    }

  } catch (error: any) {
    if (error.code === 'ENOENT') {
      issues.push(`${packageManager} is not installed or not in PATH`);
    } else {
      issues.push(`Failed to check ${packageManager} version: ${error.message}`);
    }
    available = false;
  }

  return { available, version, issues };
}

/**
 * Export the compatibility matrix for external inspection
 */
export { COMPATIBILITY_MATRIX };