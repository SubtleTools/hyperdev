---
to: vitest.workspace.ts
condition: testFramework === 'vitest' && preset !== 'minimal'
---
import { defineWorkspace } from 'vitest/config';

export default defineWorkspace([
  // Root workspace configuration
  './vitest.config.ts',
  
  // Package-level configurations
  {
    test: {
      name: 'packages',
      root: './packages',
      include: ['**/*.test.{js,ts,tsx}', '**/*.spec.{js,ts,tsx}'],
      environment: 'node',
    },
  },
  
  // App-level configurations
  {
    test: {
      name: 'apps',
      root: './apps',
      include: ['**/*.test.{js,ts,tsx}', '**/*.spec.{js,ts,tsx}'],
      environment: 'node',
    },
  },
  
  // Library-level configurations
  {
    test: {
      name: 'libs',
      root: './libs',
      include: ['**/*.test.{js,ts,tsx}', '**/*.spec.{js,ts,tsx}'],
      environment: 'node',
    },
  },
  
  // Integration tests
  {
    test: {
      name: 'integration',
      include: ['**/integration/**/*.test.{js,ts,tsx}'],
      testTimeout: 30000,
      hookTimeout: 30000,
    },
  },
  
  // E2E tests configuration
  {
    test: {
      name: 'e2e',
      include: ['**/e2e/**/*.test.{js,ts,tsx}'],
      testTimeout: 60000,
      hookTimeout: 60000,
      pool: 'threads',
      poolOptions: {
        threads: {
          singleThread: true, // E2E tests should run sequentially
        },
      },
    },
  },
]);