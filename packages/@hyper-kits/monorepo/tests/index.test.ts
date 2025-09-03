/**
 * Tests for hypergen-monorepo package
 */

import { describe, test, expect } from 'bun:test';
import { validateMonorepoConfig, generatePackageName, generateMoonToolchains } from '../src/utils';
import { presets, validateAllPresets } from '../src/presets';
import { validateToolCompatibility } from '../src/validation';

describe('hypergen-monorepo', () => {
  describe('validateMonorepoConfig', () => {
    test('should validate a complete config', () => {
      const config = {
        name: 'test-monorepo',
        packageManager: 'bun' as const,
        linter: 'eslint' as const,
        formatter: 'prettier' as const,
        testFramework: 'vitest' as const
      };
      
      const result = validateMonorepoConfig(config);
      expect(result.name).toBe('test-monorepo');
      expect(result.packageManager).toBe('bun');
    });
    
    test('should apply defaults for missing fields', () => {
      const config = { name: 'test-monorepo' };
      const result = validateMonorepoConfig(config);
      
      expect(result.packageManager).toBe('bun');
      expect(result.linter).toBe('eslint');
      expect(result.formatter).toBe('prettier');
      expect(result.testFramework).toBe('vitest');
    });
    
    test('should throw error for missing name', () => {
      expect(() => validateMonorepoConfig({})).toThrow('name is required');
    });

    test('should throw error for invalid tool combination', () => {
      const config = {
        name: 'test-monorepo',
        packageManager: 'npm' as const,
        testFramework: 'bun-test' as const
      };
      
      expect(() => validateMonorepoConfig(config)).toThrow('Invalid tool combination');
    });

    test('should accept valid tool combinations', () => {
      const config = {
        name: 'test-monorepo',
        packageManager: 'bun' as const,
        linter: 'biome' as const,
        formatter: 'biome-integrated' as const,
        testFramework: 'bun-test' as const
      };
      
      const result = validateMonorepoConfig(config);
      expect(result.name).toBe('test-monorepo');
      expect(result.packageManager).toBe('bun');
      expect(result.testFramework).toBe('bun-test');
    });
  });
  
  describe('generatePackageName', () => {
    test('should generate clean package names', () => {
      expect(generatePackageName('My Awesome Project')).toBe('my-awesome-project');
      expect(generatePackageName('test@project!')).toBe('test-project-');
    });
    
    test('should handle scoped packages', () => {
      expect(generatePackageName('My Project', 'myorg')).toBe('@myorg/my-project');
    });
  });
  
  describe('generateMoonToolchains', () => {
    test('should generate basic Node toolchain', () => {
      const config = validateMonorepoConfig({ name: 'test' });
      const toolchains = generateMoonToolchains(config);
      
      expect(toolchains.node).toBeDefined();
      expect(toolchains.node.packageManager).toBe('bun');
    });
    
    test('should include Bun toolchain for bun-test', () => {
      const config = validateMonorepoConfig({ 
        name: 'test', 
        testFramework: 'bun-test' 
      });
      const toolchains = generateMoonToolchains(config);
      
      expect(toolchains.bun).toBeDefined();
    });
  });
  
  describe('presets', () => {
    test('should have all expected presets', () => {
      expect(presets['modern-bun']).toBeDefined();
      expect(presets['traditional-node']).toBeDefined();
      expect(presets['performance']).toBeDefined();
      expect(presets['enterprise']).toBeDefined();
      expect(presets['minimal']).toBeDefined();
    });
    
    test('modern-bun preset should use bun tools', () => {
      const preset = presets['modern-bun'];
      expect(preset.packageManager).toBe('bun');
      expect(preset.testFramework).toBe('bun-test');
      expect(preset.formatter).toBe('biome-integrated');
    });

    test('all presets should be valid', () => {
      const results = validateAllPresets();
      Object.entries(results).forEach(([name, isValid]) => {
        expect(isValid).toBe(true);
      });
    });

    test('presets should pass tool compatibility validation', () => {
      Object.entries(presets).forEach(([name, preset]) => {
        const config = {
          name: 'test',
          packageManager: preset.packageManager || 'bun',
          linter: preset.linter || 'eslint',
          formatter: preset.formatter || 'prettier',
          testFramework: preset.testFramework || 'vitest'
        } as any;

        const validation = validateToolCompatibility(config);
        const errors = validation.issues.filter(issue => issue.severity === 'error');
        expect(errors).toHaveLength(0);
      });
    });
  });
});