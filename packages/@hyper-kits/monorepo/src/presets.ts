/**
 * Configuration presets for common monorepo setups
 */

import type { MonorepoConfig } from './index';
import { validatePreset } from './validation';

/**
 * Modern JavaScript/TypeScript stack with Bun
 */
export const modernBunPreset: Partial<MonorepoConfig> = {
  packageManager: 'bun',
  linter: 'biome',
  formatter: 'biome-integrated', // Use integrated formatter for best performance
  testFramework: 'bun-test',
  tools: {
    husky: true,
    lintStaged: true,
    commitlint: true,
    changesets: true
  }
};

/**
 * Traditional Node.js stack with established tools
 */
export const traditionalNodePreset: Partial<MonorepoConfig> = {
  packageManager: 'npm',
  linter: 'eslint',
  formatter: 'prettier',
  testFramework: 'vitest',
  tools: {
    husky: true,
    lintStaged: true,
    commitlint: true,
    changesets: true
  }
};

/**
 * Performance-focused setup for large codebases
 */
export const performancePreset: Partial<MonorepoConfig> = {
  packageManager: 'bun',
  linter: 'biome',
  formatter: 'dprint',
  testFramework: 'bun-test',
  tools: {
    husky: false,
    lintStaged: false,
    commitlint: false,
    changesets: true
  }
};

/**
 * Enterprise-ready setup with comprehensive tooling
 */
export const enterprisePreset: Partial<MonorepoConfig> = {
  packageManager: 'pnpm',
  linter: 'eslint',
  formatter: 'prettier',
  testFramework: 'vitest',
  tools: {
    husky: true,
    lintStaged: true,
    commitlint: true,
    changesets: true
  }
};

/**
 * Minimal setup with unified tooling
 */
export const minimalPreset: Partial<MonorepoConfig> = {
  packageManager: 'bun',
  linter: 'biome',
  formatter: 'biome-integrated',
  testFramework: 'bun-test',
  tools: {
    husky: false,
    lintStaged: false,
    commitlint: false,
    changesets: false
  }
};

/**
 * All available presets
 */
export const presets = {
  'modern-bun': modernBunPreset,
  'traditional-node': traditionalNodePreset,
  'performance': performancePreset,
  'enterprise': enterprisePreset,
  'minimal': minimalPreset
} as const;

/**
 * Validates all presets to ensure they have valid tool combinations
 */
export function validateAllPresets(): Record<string, boolean> {
  const results: Record<string, boolean> = {};
  
  for (const [name, preset] of Object.entries(presets)) {
    try {
      const validation = validatePreset(preset);
      results[name] = validation.valid;
      
      if (!validation.valid) {
        console.warn(`Preset "${name}" has validation issues:`, validation.issues);
      }
    } catch (error) {
      results[name] = false;
      console.error(`Error validating preset "${name}":`, error);
    }
  }
  
  return results;
}

export type PresetName = keyof typeof presets;