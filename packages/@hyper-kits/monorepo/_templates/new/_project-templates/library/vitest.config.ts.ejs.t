---
to: packages/<%= name %>/vitest.config.ts
condition: projectType === 'library' && testFramework === 'vitest'
---
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['src/**/*.{test,spec}.{js,ts,tsx}'],
    exclude: ['node_modules', 'dist', 'esm'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['src/**/*'],
      exclude: ['src/**/*.{test,spec}.{js,ts,tsx}']
    },
    typecheck: {
      enabled: true
    }
  }
});