---
to: jest.config.js
condition: testFramework === 'jest'
---
module.exports = {
  preset: 'jest-preset-moon',
  testEnvironment: 'node',
  roots: ['<rootDir>/packages', '<rootDir>/apps', '<rootDir>/libs'],
  testMatch: [
    '**/__tests__/**/*.{js,ts,tsx}',
    '**/*.{test,spec}.{js,ts,tsx}',
  ],
  collectCoverageFrom: [
    'packages/**/*.{js,ts,tsx}',
<% if (preset !== 'minimal') { -%>
    'apps/**/*.{js,ts,tsx}',
    'libs/**/*.{js,ts,tsx}',
<% } -%>
    '!**/*.d.ts',
    '!**/*.config.{js,ts,mjs}',
    '!**/node_modules/**',
    '!**/dist/**',
    '!**/build/**',
    '!**/.moon/**',
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  moduleNameMapping: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '^@packages/(.*)$': '<rootDir>/packages/$1',
<% if (preset !== 'minimal') { -%>
    '^@apps/(.*)$': '<rootDir>/apps/$1',
    '^@libs/(.*)$': '<rootDir>/libs/$1',
<% } -%>
  },
  setupFilesAfterEnv: [],
  testTimeout: 10000,
  maxWorkers: '50%',
  cacheDirectory: '.moon/cache/jest',
  clearMocks: true,
  restoreMocks: true,
  verbose: true,
};