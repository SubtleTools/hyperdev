/**
 * Tests for template composition logic
 */

import { describe, it, expect, beforeEach } from 'vitest';
import { TemplateComposition, composeTemplate, getValidToolCombinations } from '../src/composition';
import type { MonorepoConfig, TemplateContext } from '../src/index';

describe('TemplateComposition', () => {
  let composer: TemplateComposition;
  
  beforeEach(() => {
    composer = new TemplateComposition();
  });

  describe('compose', () => {
    it('should compose template with valid configuration', async () => {
      const config: MonorepoConfig = {
        name: 'test-monorepo',
        packageManager: 'bun',
        linter: 'biome',
        formatter: 'biome-integrated',
        testFramework: 'bun-test'
      };

      const result = await composer.compose(config);

      expect(result.errors).toHaveLength(0);
      expect(result.context.name).toBe('test-monorepo');
      expect(result.context.packageManager).toBe('bun');
      expect(result.context.computed).toBeDefined();
      expect(result.context.computed.packageManagerInstallCommand).toBe('bun install');
      expect(result.actions.length).toBeGreaterThan(0);
    });

    it('should handle preset application', async () => {
      const config: MonorepoConfig & { preset: string } = {
        name: 'preset-test',
        packageManager: 'npm', // Will be overridden by preset
        linter: 'eslint',
        formatter: 'prettier',
        testFramework: 'vitest',
        preset: 'modern-bun'
      };

      const result = await composer.compose(config);

      expect(result.errors).toHaveLength(0);
      // Preset should override the tool selections
      expect(result.context.packageManager).toBe('bun');
      expect(result.context.linter).toBe('biome');
      expect(result.context.formatter).toBe('biome-integrated');
      expect(result.context.testFramework).toBe('bun-test');
    });

    it('should detect incompatible tool combinations', async () => {
      const config: MonorepoConfig = {
        name: 'invalid-config',
        packageManager: 'npm',
        linter: 'eslint',
        formatter: 'biome-integrated', // Invalid: biome-integrated requires biome linter
        testFramework: 'vitest'
      };

      const result = await composer.compose(config);

      expect(result.errors.length).toBeGreaterThan(0);
      expect(result.errors[0]).toContain('Biome integrated formatter');
    });

    it('should generate warnings for suboptimal combinations', async () => {
      const config: MonorepoConfig = {
        name: 'warning-config',
        packageManager: 'bun',
        linter: 'biome',
        formatter: 'prettier', // Works but not optimal
        testFramework: 'bun-test'
      };

      const result = await composer.compose(config);

      expect(result.errors).toHaveLength(0);
      expect(result.warnings.length).toBeGreaterThan(0);
      expect(result.warnings.some(w => w.includes('Biome linter with Prettier'))).toBe(true);
    });
  });

  describe('file inclusion logic', () => {
    it('should include correct files for bun + biome + bun-test', async () => {
      const config: MonorepoConfig = {
        name: 'bun-config',
        packageManager: 'bun',
        linter: 'biome',
        formatter: 'biome-integrated',
        testFramework: 'bun-test'
      };

      const result = await composer.compose(config);

      // Should include bun-specific files
      expect(result.includedFiles.some(f => f.includes('bunfig.toml'))).toBe(true);
      expect(result.includedFiles.some(f => f.includes('biome.json'))).toBe(true);
      expect(result.includedFiles.some(f => f.includes('bun.test.ts'))).toBe(true);

      // Should exclude other package manager files
      expect(result.excludedFiles.some(f => f.includes('package-lock.json'))).toBe(true);
      expect(result.excludedFiles.some(f => f.includes('yarn.lock'))).toBe(true);
      expect(result.excludedFiles.some(f => f.includes('pnpm-lock.yaml'))).toBe(true);

      // Should exclude other linter files
      expect(result.excludedFiles.some(f => f.includes('.eslintrc'))).toBe(true);

      // Should exclude other formatter files
      expect(result.excludedFiles.some(f => f.includes('.prettierrc'))).toBe(true);
      expect(result.excludedFiles.some(f => f.includes('dprint.json'))).toBe(true);

      // Should exclude other test framework files
      expect(result.excludedFiles.some(f => f.includes('vitest.config'))).toBe(true);
      expect(result.excludedFiles.some(f => f.includes('jest.config'))).toBe(true);
    });

    it('should include correct files for npm + eslint + prettier + jest', async () => {
      const config: MonorepoConfig = {
        name: 'traditional-config',
        packageManager: 'npm',
        linter: 'eslint',
        formatter: 'prettier',
        testFramework: 'jest'
      };

      const result = await composer.compose(config);

      // Should include appropriate files
      expect(result.includedFiles.some(f => f.includes('package-lock.json'))).toBe(true);
      expect(result.includedFiles.some(f => f.includes('.eslintrc'))).toBe(true);
      expect(result.includedFiles.some(f => f.includes('.prettierrc'))).toBe(true);
      expect(result.includedFiles.some(f => f.includes('jest.config'))).toBe(true);

      // Should exclude bun-specific files
      expect(result.excludedFiles.some(f => f.includes('bunfig.toml'))).toBe(true);
      expect(result.excludedFiles.some(f => f.includes('biome.json'))).toBe(true);
      expect(result.excludedFiles.some(f => f.includes('bun.test.ts'))).toBe(true);
    });
  });

  describe('preset handling', () => {
    it('should apply modern-bun preset correctly', async () => {
      const config: MonorepoConfig & { preset: string } = {
        name: 'modern-test',
        packageManager: 'npm', // Will be overridden
        linter: 'eslint',      // Will be overridden
        formatter: 'prettier', // Will be overridden
        testFramework: 'vitest', // Will be overridden
        preset: 'modern-bun'
      };

      const result = await composer.compose(config);

      expect(result.context.packageManager).toBe('bun');
      expect(result.context.linter).toBe('biome');
      expect(result.context.formatter).toBe('biome-integrated');
      expect(result.context.testFramework).toBe('bun-test');
    });

    it('should apply enterprise preset correctly', async () => {
      const config: MonorepoConfig & { preset: string } = {
        name: 'enterprise-test',
        packageManager: 'bun',
        linter: 'biome',
        formatter: 'biome-integrated',
        testFramework: 'bun-test',
        preset: 'enterprise'
      };

      const result = await composer.compose(config);

      expect(result.context.packageManager).toBe('pnpm'); // From enterprise preset
      expect(result.context.linter).toBe('eslint');
      expect(result.context.formatter).toBe('prettier');
      expect(result.context.testFramework).toBe('vitest');
    });

    it('should not apply preset when preset is "custom"', async () => {
      const config: MonorepoConfig & { preset: string } = {
        name: 'custom-test',
        packageManager: 'yarn',
        linter: 'eslint',
        formatter: 'dprint',
        testFramework: 'vitest',
        preset: 'custom'
      };

      const result = await composer.compose(config);

      // Should keep original selections
      expect(result.context.packageManager).toBe('yarn');
      expect(result.context.linter).toBe('eslint');
      expect(result.context.formatter).toBe('dprint');
      expect(result.context.testFramework).toBe('vitest');
    });
  });

  describe('action generation', () => {
    it('should generate pre and post actions', async () => {
      const config: MonorepoConfig = {
        name: 'action-test',
        packageManager: 'bun',
        linter: 'biome',
        formatter: 'biome-integrated',
        testFramework: 'bun-test'
      };

      const result = await composer.compose(config);

      expect(result.actions.length).toBeGreaterThan(0);
      
      const preActions = result.actions.filter(a => a.timing === 'pre');
      const postActions = result.actions.filter(a => a.timing === 'post');
      
      expect(preActions.length).toBeGreaterThan(0);
      expect(postActions.length).toBeGreaterThan(0);
      
      // Check for essential actions
      expect(result.actions.some(a => a.name === 'validateConfiguration')).toBe(true);
      expect(result.actions.some(a => a.name === 'prepareContext')).toBe(true);
    });

    it('should execute actions without errors', async () => {
      const config: MonorepoConfig = {
        name: 'execution-test',
        packageManager: 'bun',
        linter: 'biome',
        formatter: 'biome-integrated',
        testFramework: 'bun-test'
      };

      const result = await composer.compose(config);

      // Test action execution - should not throw in test environment
      for (const action of result.actions) {
        try {
          await action.execute(result.context);
          expect(true).toBe(true); // Action executed successfully
        } catch (error) {
          console.error(`Action "${action.name}" failed:`, error);
          expect(error).toBeUndefined(); // This will fail and show the error
        }
      }
    });
  });

  describe('error handling', () => {
    it('should handle missing required fields', async () => {
      const config: Partial<MonorepoConfig> = {
        // Missing name
        packageManager: 'bun',
        linter: 'biome',
        formatter: 'biome-integrated',
        testFramework: 'bun-test'
      } as MonorepoConfig;

      const result = await composer.compose(config);

      expect(result.errors.length).toBeGreaterThan(0);
      expect(result.errors.some(e => e.includes('name'))).toBe(true);
    });

    it('should handle unknown preset', async () => {
      const config: MonorepoConfig & { preset: string } = {
        name: 'unknown-preset-test',
        packageManager: 'bun',
        linter: 'biome',
        formatter: 'biome-integrated',
        testFramework: 'bun-test',
        preset: 'unknown-preset'
      };

      const result = await composer.compose(config);

      expect(result.errors.length).toBeGreaterThan(0);
      expect(result.errors.some(e => e.includes('Unknown preset'))).toBe(true);
    });
  });
});

describe('composeTemplate utility', () => {
  it('should work as convenience function', async () => {
    const config: MonorepoConfig = {
      name: 'utility-test',
      packageManager: 'bun',
      linter: 'biome',
      formatter: 'biome-integrated',
      testFramework: 'bun-test'
    };

    const result = await composeTemplate(config);

    expect(result.context.name).toBe('utility-test');
    expect(result.errors).toHaveLength(0);
  });
});

describe('getValidToolCombinations', () => {
  it('should return only valid tool combinations', async () => {
    const combinations = getValidToolCombinations();

    expect(combinations.length).toBeGreaterThan(0);
    
    // Each combination should have all required fields
    combinations.forEach(combo => {
      expect(combo.packageManager).toBeDefined();
      expect(combo.linter).toBeDefined();
      expect(combo.formatter).toBeDefined();
      expect(combo.testFramework).toBeDefined();
    });

    // Should not include invalid combinations like biome-integrated without biome linter
    const invalidCombo = combinations.find(c => 
      c.linter === 'eslint' && c.formatter === 'biome-integrated'
    );
    expect(invalidCombo).toBeUndefined();

    // Should not include bun-test with non-bun package managers
    const invalidBunTest = combinations.find(c =>
      c.testFramework === 'bun-test' && c.packageManager !== 'bun'
    );
    expect(invalidBunTest).toBeUndefined();
  });

  it('should include expected valid combinations', async () => {
    const combinations = getValidToolCombinations();

    // Modern Bun stack should be valid
    const modernBun = combinations.find(c =>
      c.packageManager === 'bun' &&
      c.linter === 'biome' &&
      c.formatter === 'biome-integrated' &&
      c.testFramework === 'bun-test'
    );
    expect(modernBun).toBeDefined();

    // Traditional Node stack should be valid
    const traditional = combinations.find(c =>
      c.packageManager === 'npm' &&
      c.linter === 'eslint' &&
      c.formatter === 'prettier' &&
      c.testFramework === 'vitest'
    );
    expect(traditional).toBeDefined();

    // ESLint + Prettier + Vitest should be valid with any package manager
    ['bun', 'npm', 'yarn', 'pnpm'].forEach(pm => {
      const combo = combinations.find(c =>
        c.packageManager === pm &&
        c.linter === 'eslint' &&
        c.formatter === 'prettier' &&
        c.testFramework === 'vitest'
      );
      expect(combo).toBeDefined();
    });
  });
});

describe('context computation', () => {
  it('should compute template context properties correctly', async () => {
    const config: MonorepoConfig = {
      name: 'context-test',
      packageManager: 'yarn',
      linter: 'eslint',
      formatter: 'dprint',
      testFramework: 'jest'
    };

    const result = await composeTemplate(config);

    expect(result.context.computed).toBeDefined();
    expect(result.context.computed.hasLinting).toBe(true);
    expect(result.context.computed.hasFormatting).toBe(true);
    expect(result.context.computed.hasTesting).toBe(true);
    expect(result.context.computed.packageManagerInstallCommand).toBe('yarn install');
    expect(result.context.computed.packageManagerRunCommand).toBe('yarn');
  });

  it('should handle minimal configuration', async () => {
    const config: MonorepoConfig = {
      name: 'minimal-test',
      packageManager: 'bun',
      linter: 'biome',
      formatter: 'biome-integrated',
      testFramework: 'bun-test'
    };

    const result = await composeTemplate(config);

    expect(result.context.computed.hasLinting).toBe(true);
    expect(result.context.computed.hasFormatting).toBe(true);
    expect(result.context.computed.hasTesting).toBe(true);
    expect(result.context.computed.packageManagerInstallCommand).toBe('bun install');
    expect(result.context.computed.packageManagerRunCommand).toBe('bun run');
  });
});