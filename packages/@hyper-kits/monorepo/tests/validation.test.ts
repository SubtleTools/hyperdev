/**
 * Comprehensive tests for tool compatibility validation system
 */

import { describe, test, expect } from 'bun:test';
import {
  validateToolCompatibility,
  isToolCombinationValid,
  getCompatibleFormatters,
  getCompatibleTestFrameworks,
  getPerformanceNotes,
  validatePreset,
  getValidationErrors,
  getValidationWarnings,
  hasCompatibilityIssues,
  COMPATIBILITY_MATRIX,
  type ValidationResult,
  type ValidationIssue
} from '../src/validation';
import type { MonorepoConfig } from '../src/index';

describe('Tool Compatibility Validation', () => {
  
  describe('validateToolCompatibility', () => {
    test('should validate compatible configurations without errors', () => {
      const validConfigs: MonorepoConfig[] = [
        {
          name: 'test',
          packageManager: 'bun',
          linter: 'eslint',
          formatter: 'prettier',
          testFramework: 'vitest'
        },
        {
          name: 'test',
          packageManager: 'bun',
          linter: 'biome',
          formatter: 'biome-integrated',
          testFramework: 'bun-test'
        },
        {
          name: 'test',
          packageManager: 'npm',
          linter: 'eslint',
          formatter: 'dprint',
          testFramework: 'jest'
        }
      ];

      validConfigs.forEach(config => {
        const result = validateToolCompatibility(config);
        const errors = result.issues.filter(issue => issue.severity === 'error');
        expect(errors).toHaveLength(0);
      });
    });

    test('should detect Bun Test + non-Bun package manager errors', () => {
      const invalidConfigs = [
        { packageManager: 'npm', testFramework: 'bun-test' },
        { packageManager: 'yarn', testFramework: 'bun-test' },
        { packageManager: 'pnpm', testFramework: 'bun-test' }
      ];

      invalidConfigs.forEach(partial => {
        const config: MonorepoConfig = {
          name: 'test',
          packageManager: partial.packageManager as any,
          linter: 'eslint',
          formatter: 'prettier',
          testFramework: partial.testFramework as any
        };

        const result = validateToolCompatibility(config);
        expect(result.valid).toBe(false);
        
        const errors = result.issues.filter(issue => issue.severity === 'error');
        expect(errors.length).toBeGreaterThan(0);
        expect(errors[0].message).toContain('Bun Test');
      });
    });

    test('should detect Biome integrated formatter + ESLint linter error', () => {
      const config: MonorepoConfig = {
        name: 'test',
        packageManager: 'bun',
        linter: 'eslint',
        formatter: 'biome-integrated',
        testFramework: 'vitest'
      };

      const result = validateToolCompatibility(config);
      expect(result.valid).toBe(false);
      
      const errors = result.issues.filter(issue => issue.severity === 'error');
      expect(errors.length).toBeGreaterThan(0);
      expect(errors[0].message).toContain('Biome integrated formatter');
    });

    test('should generate warnings for suboptimal combinations', () => {
      const config: MonorepoConfig = {
        name: 'test',
        packageManager: 'bun',
        linter: 'biome',
        formatter: 'prettier',
        testFramework: 'vitest'
      };

      const result = validateToolCompatibility(config);
      const warnings = result.issues.filter(issue => issue.severity === 'warning');
      expect(warnings.length).toBeGreaterThan(0);
      expect(warnings[0].message).toContain('performance benefits');
    });

    test('should provide suggestions for invalid configurations', () => {
      const config: MonorepoConfig = {
        name: 'test',
        packageManager: 'npm',
        linter: 'eslint',
        formatter: 'biome-integrated',
        testFramework: 'bun-test'
      };

      const result = validateToolCompatibility(config);
      expect(result.valid).toBe(false);
      expect(result.suggestions).toBeDefined();
      expect(result.suggestions!.length).toBeGreaterThan(0);
    });
  });

  describe('isToolCombinationValid', () => {
    test('should return true for valid combinations', () => {
      expect(isToolCombinationValid('bun', 'biome', 'biome-integrated', 'bun-test')).toBe(true);
      expect(isToolCombinationValid('npm', 'eslint', 'prettier', 'jest')).toBe(true);
      expect(isToolCombinationValid('pnpm', 'biome', 'dprint', 'vitest')).toBe(true);
    });

    test('should return false for invalid combinations', () => {
      expect(isToolCombinationValid('npm', 'eslint', 'prettier', 'bun-test')).toBe(false);
      expect(isToolCombinationValid('bun', 'eslint', 'biome-integrated', 'vitest')).toBe(false);
    });
  });

  describe('getCompatibleFormatters', () => {
    test('should return correct formatters for ESLint', () => {
      const formatters = getCompatibleFormatters('eslint');
      expect(formatters).toContain('prettier');
      expect(formatters).toContain('dprint');
      expect(formatters).not.toContain('biome-integrated');
    });

    test('should return correct formatters for Biome', () => {
      const formatters = getCompatibleFormatters('biome');
      expect(formatters).toContain('prettier');
      expect(formatters).toContain('dprint');
      expect(formatters).toContain('biome-integrated');
    });

    test('should handle unknown linter', () => {
      const formatters = getCompatibleFormatters('unknown');
      expect(formatters).toEqual([]);
    });
  });

  describe('getCompatibleTestFrameworks', () => {
    test('should return all frameworks for Bun', () => {
      const frameworks = getCompatibleTestFrameworks('bun');
      expect(frameworks).toContain('vitest');
      expect(frameworks).toContain('bun-test');
      expect(frameworks).toContain('jest');
    });

    test('should exclude bun-test for other package managers', () => {
      const frameworks = getCompatibleTestFrameworks('npm');
      expect(frameworks).toContain('vitest');
      expect(frameworks).toContain('jest');
      expect(frameworks).not.toContain('bun-test');
    });
  });

  describe('getPerformanceNotes', () => {
    test('should return performance notes for test frameworks', () => {
      const vitestNotes = getPerformanceNotes('vitest');
      expect(vitestNotes.length).toBeGreaterThan(0);
      expect(vitestNotes[0]).toContain('Vitest');

      const bunTestNotes = getPerformanceNotes('bun-test');
      expect(bunTestNotes.length).toBeGreaterThan(0);
      expect(bunTestNotes[0]).toContain('Bun Test');
    });

    test('should handle unknown test framework', () => {
      const notes = getPerformanceNotes('unknown');
      expect(notes).toEqual([]);
    });
  });

  describe('validatePreset', () => {
    test('should validate modern-bun preset', () => {
      const preset = {
        packageManager: 'bun' as const,
        linter: 'biome' as const,
        formatter: 'biome-integrated' as const,
        testFramework: 'bun-test' as const
      };

      const result = validatePreset(preset);
      expect(result.valid).toBe(true);
      const errors = result.issues.filter(issue => issue.severity === 'error');
      expect(errors).toHaveLength(0);
    });

    test('should detect errors in invalid presets', () => {
      const invalidPreset = {
        packageManager: 'npm' as const,
        linter: 'eslint' as const,
        formatter: 'prettier' as const,
        testFramework: 'bun-test' as const
      };

      const result = validatePreset(invalidPreset);
      expect(result.valid).toBe(false);
      const errors = result.issues.filter(issue => issue.severity === 'error');
      expect(errors.length).toBeGreaterThan(0);
    });
  });

  describe('validation utility functions', () => {
    const validConfig: MonorepoConfig = {
      name: 'test',
      packageManager: 'bun',
      linter: 'biome',
      formatter: 'biome-integrated',
      testFramework: 'bun-test'
    };

    const invalidConfig: MonorepoConfig = {
      name: 'test',
      packageManager: 'npm',
      linter: 'eslint',
      formatter: 'prettier',
      testFramework: 'bun-test'
    };

    const warningConfig: MonorepoConfig = {
      name: 'test',
      packageManager: 'bun',
      linter: 'biome',
      formatter: 'prettier',
      testFramework: 'vitest'
    };

    test('getValidationErrors should return only error issues', () => {
      const errors = getValidationErrors(invalidConfig);
      expect(errors.length).toBeGreaterThan(0);
      expect(errors.every(issue => issue.severity === 'error')).toBe(true);

      const validErrors = getValidationErrors(validConfig);
      expect(validErrors).toHaveLength(0);
    });

    test('getValidationWarnings should return only warning issues', () => {
      const warnings = getValidationWarnings(warningConfig);
      expect(warnings.length).toBeGreaterThan(0);
      expect(warnings.every(issue => issue.severity === 'warning')).toBe(true);

      const validWarnings = getValidationWarnings(validConfig);
      // Valid config might still have warnings
      expect(validWarnings.every(issue => issue.severity === 'warning')).toBe(true);
    });

    test('hasCompatibilityIssues should detect any validation issues', () => {
      expect(hasCompatibilityIssues(invalidConfig)).toBe(true);
      expect(hasCompatibilityIssues(warningConfig)).toBe(true);
      
      // Valid config might have info messages
      const hasIssues = hasCompatibilityIssues(validConfig);
      if (hasIssues) {
        // If it has issues, they should be info level only
        const result = validateToolCompatibility(validConfig);
        const nonInfoIssues = result.issues.filter(issue => issue.severity !== 'info');
        expect(nonInfoIssues).toHaveLength(0);
      }
    });
  });

  describe('compatibility matrix completeness', () => {
    test('should have entries for all package managers', () => {
      const packageManagers = ['bun', 'npm', 'yarn', 'pnpm'];
      packageManagers.forEach(pm => {
        expect(COMPATIBILITY_MATRIX.packageManager[pm]).toBeDefined();
      });
    });

    test('should have entries for all linters', () => {
      const linters = ['eslint', 'biome'];
      linters.forEach(linter => {
        expect(COMPATIBILITY_MATRIX.linter[linter]).toBeDefined();
      });
    });

    test('should have entries for all test frameworks', () => {
      const frameworks = ['vitest', 'bun-test', 'jest'];
      frameworks.forEach(framework => {
        expect(COMPATIBILITY_MATRIX.testFramework[framework]).toBeDefined();
      });
    });

    test('should have combination rules covering critical incompatibilities', () => {
      const rules = COMPATIBILITY_MATRIX.combinations;
      
      // Check for bun-test + non-bun package manager rules
      const bunTestRules = rules.filter(rule => 
        rule.code.includes('BUN_TEST') && rule.severity === 'error'
      );
      expect(bunTestRules.length).toBeGreaterThan(0);

      // Check for biome-integrated + eslint rule
      const biomeIntegratedRules = rules.filter(rule => 
        rule.code.includes('BIOME_INTEGRATED') && rule.severity === 'error'
      );
      expect(biomeIntegratedRules.length).toBeGreaterThan(0);
    });
  });

  describe('error messages and fixes', () => {
    test('should provide helpful error messages', () => {
      const config: MonorepoConfig = {
        name: 'test',
        packageManager: 'npm',
        linter: 'eslint',
        formatter: 'prettier',
        testFramework: 'bun-test'
      };

      const result = validateToolCompatibility(config);
      const errors = result.issues.filter(issue => issue.severity === 'error');
      
      expect(errors.length).toBeGreaterThan(0);
      expect(errors[0].message).toBeTruthy();
      expect(errors[0].message.length).toBeGreaterThan(10);
    });

    test('should provide actionable fix suggestions', () => {
      const config: MonorepoConfig = {
        name: 'test',
        packageManager: 'bun',
        linter: 'eslint',
        formatter: 'biome-integrated',
        testFramework: 'vitest'
      };

      const result = validateToolCompatibility(config);
      const errors = result.issues.filter(issue => issue.severity === 'error');
      
      expect(errors.length).toBeGreaterThan(0);
      expect(errors[0].fix).toBeTruthy();
      expect(errors[0].fix!.length).toBeGreaterThan(10);
    });

    test('should identify affected tools correctly', () => {
      const config: MonorepoConfig = {
        name: 'test',
        packageManager: 'npm',
        linter: 'eslint',
        formatter: 'prettier',
        testFramework: 'bun-test'
      };

      const result = validateToolCompatibility(config);
      const errors = result.issues.filter(issue => issue.severity === 'error');
      
      expect(errors.length).toBeGreaterThan(0);
      expect(errors[0].affectedTools).toContain('bun-test');
      expect(errors[0].affectedTools).toContain('npm');
    });
  });
});