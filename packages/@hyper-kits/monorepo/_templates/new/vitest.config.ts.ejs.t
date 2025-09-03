---
to: vitest.config.ts
condition: testFramework === 'vitest'
---
import { defineConfig } from 'vitest/config';
import { resolve } from 'path';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    
    // Comprehensive test file patterns for monorepo
    include: [
      '**/*.test.{js,ts,tsx}',
      '**/*.spec.{js,ts,tsx}',
      'packages/**/__tests__/**/*.{js,ts,tsx}',
<% if (preset !== 'minimal') { -%>
      'apps/**/__tests__/**/*.{js,ts,tsx}',
      'libs/**/__tests__/**/*.{js,ts,tsx}',
<% } -%>
    ],
    
    exclude: [
      'node_modules/',
      'dist/',
      'build/',
      '.moon/',
      'coverage/',
<% if (packageManager === 'bun') { -%>
      'bun.lockb',
<% } else if (packageManager === 'npm') { -%>
      'package-lock.json',
<% } else if (packageManager === 'yarn') { -%>
      'yarn.lock',
<% } else if (packageManager === 'pnpm') { -%>
      'pnpm-lock.yaml',
<% } -%>
      '**/*.d.ts',
      '**/*.config.{js,ts,mjs}',
    ],
    
    // Coverage configuration optimized for monorepo
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      reportsDirectory: './coverage',
      
      include: [
        'packages/*/src/**/*.{js,ts,tsx}',
<% if (preset !== 'minimal') { -%>
        'apps/*/src/**/*.{js,ts,tsx}',
        'libs/*/src/**/*.{js,ts,tsx}',
<% } -%>
      ],
      
      exclude: [
        'node_modules/',
        'dist/',
        'build/',
        '.moon/',
        'coverage/',
        '**/*.config.{js,ts,mjs}',
        '**/*.test.{js,ts,tsx}',
        '**/*.spec.{js,ts,tsx}',
        '**/__tests__/**',
        '**/*.d.ts',
        '**/types.ts',
        '**/constants.ts',
      ],
      
      // Coverage thresholds for monorepo quality
      thresholds: {
        global: {
          branches: <%= preset === 'enterprise' ? '90' : '80' %>,
          functions: <%= preset === 'enterprise' ? '90' : '80' %>,
          lines: <%= preset === 'enterprise' ? '90' : '80' %>,
          statements: <%= preset === 'enterprise' ? '90' : '80' %>,
        },
      },
    },
    
    // Performance configuration for monorepo
    pool: 'threads',
    poolOptions: {
      threads: {
        singleThread: false,
        minThreads: 1,
        maxThreads: process.env.CI ? 2 : undefined,
      },
    },
    
    // Timeouts optimized for monorepo complexity
    testTimeout: <%= preset === 'enterprise' ? '15000' : '10000' %>,
    hookTimeout: <%= preset === 'enterprise' ? '15000' : '10000' %>,
    
    // Watch configuration for development
    watchExclude: [
      'node_modules/',
      'dist/',
      'build/',
      '.moon/',
      'coverage/',
    ],
    
    // Reporter configuration
    reporter: process.env.CI ? ['verbose', 'junit'] : ['verbose'],
    outputFile: process.env.CI ? {
      junit: './test-results.xml',
    } : undefined,
  },
  
  // Path resolution for monorepo
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
      '@packages': resolve(__dirname, './packages'),
<% if (preset !== 'minimal') { -%>
      '@apps': resolve(__dirname, './apps'),
      '@libs': resolve(__dirname, './libs'),
      '@shared': resolve(__dirname, './packages/shared'),
      '@utils': resolve(__dirname, './packages/utils'),
<% } -%>
    },
  },
  
  // Vitest workspace configuration
  esbuild: {
    target: 'node18',
  },
});