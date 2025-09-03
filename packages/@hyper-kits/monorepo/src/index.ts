/**
 * @hypergen/monorepo-pack
 * 
 * Hypergen template package for generating Moon-based TypeScript monorepos
 * with configurable tooling combinations.
 * 
 * Supports 16 different tool combinations:
 * - Linting: ESLint or Biome
 * - Formatting: Prettier or dprint  
 * - Testing: Vitest or Bun Test
 * - Various configuration presets
 */

export interface MonorepoConfig {
  /** Project name for the monorepo */
  name: string;
  
  /** Package manager to use (bun, npm, yarn, pnpm) */
  packageManager: 'bun' | 'npm' | 'yarn' | 'pnpm';
  
  /** Linting tool configuration */
  linter: 'eslint' | 'biome';
  
  /** Code formatting tool */
  formatter: 'prettier' | 'dprint' | 'biome-integrated';
  
  /** Testing framework */
  testFramework: 'vitest' | 'bun-test' | 'jest';
  
  /** Additional tools to include */
  tools?: {
    husky?: boolean;
    lintStaged?: boolean;
    commitlint?: boolean;
    changesets?: boolean;
  };
  
  /** Moon workspace configuration */
  moon?: {
    version?: string;
    tasks?: Record<string, any>;
    toolchains?: Record<string, any>;
  };
}

export interface TemplateContext extends MonorepoConfig {
  /** Computed properties for template rendering */
  computed: {
    hasLinting: boolean;
    hasFormatting: boolean;
    hasTesting: boolean;
    packageManagerInstallCommand: string;
    packageManagerRunCommand: string;
  };
}

/**
 * Template action exports for Hypergen V8 action system
 */
export * from './actions';

/**
 * Template composition logic and orchestration
 */
export * from './composition';

/**
 * Utility functions for template generation
 */
export * from './utils';

/**
 * Configuration presets for common setups
 */
export * from './presets';

/**
 * Tool compatibility validation system
 */
export * from './validation';