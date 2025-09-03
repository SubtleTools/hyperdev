---
to: apps/<%= name %>/src/test-setup.ts
condition: projectType === 'cli' && testFramework === 'jest'
---
/**
 * Test setup file for <%= name %> CLI
 * This file is loaded before all tests run
 */

import { jest } from '@jest/globals';

// Mock console methods to reduce noise in tests
const originalConsole = { ...console };

beforeEach(() => {
  // You can add global setup here
});

afterEach(() => {
  // Reset mocks after each test
  jest.clearAllMocks();
});

// Export utilities that might be useful across tests
export { originalConsole };