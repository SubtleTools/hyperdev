---
to: apps/<%= name %>/jest.config.js
condition: projectType === 'cli' && testFramework === 'jest'
---
/** @type {import('jest').Config} */
export default {
  preset: 'ts-jest/presets/default-esm',
  extensionsToTreatAsEsm: ['.ts'],
  moduleNameMapping: {
    '^(\\.{1,2}/.*)\\.js$': '$1',
  },
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: [
    '**/__tests__/**/*.{js,ts,tsx}',
    '**/?(*.)+(spec|test).{js,ts,tsx}'
  ],
  transform: {
    '^.+\\.tsx?$': ['ts-jest', {
      useESM: true,
      tsconfig: {
        module: 'ESNext'
      }
    }]
  },
  collectCoverageFrom: [
    'src/**/*.{js,ts,tsx}',
    '!src/**/*.{test,spec}.{js,ts,tsx}',
    '!src/**/__tests__/**'
  ],
  coverageDirectory: 'coverage',
  coverageReporters: [
    'text',
    'lcov',
    'html'
  ],
  clearMocks: true,
  restoreMocks: true,
  verbose: true,
  // Additional setup for CLI testing
  setupFilesAfterEnv: ['<rootDir>/src/test-setup.ts']
};