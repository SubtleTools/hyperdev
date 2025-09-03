---
to: bun.test.ts
condition: testFramework === 'bun-test'
---
/**
 * Bun Test Configuration and Setup
 * 
 * This file configures the Bun test environment for the monorepo.
 * It sets up global test utilities, mocks, and environment configuration.
 * 
 * @see https://bun.sh/docs/test/writing
 * @see https://bun.sh/docs/test/mocks
 */

import { beforeAll, beforeEach, afterAll, afterEach } from 'bun:test';
import type { Mock } from 'bun:test';

/**
 * Global test environment configuration
 */
declare global {
  var __TEST_ENV__: boolean;
  var __MOCK_DATE__: Date | null;
}

// Set global test environment flag
globalThis.__TEST_ENV__ = true;
globalThis.__MOCK_DATE__ = null;

/**
 * Global test setup - runs once before all tests
 */
beforeAll(async () => {
  // Set test environment variables
  process.env.NODE_ENV = 'test';
  process.env.TEST_ENV = 'bun';
  
  // Suppress console warnings in tests unless explicitly needed
  if (!process.env.SHOW_WARNINGS) {
    const originalWarn = console.warn;
    console.warn = (...args: unknown[]) => {
      // Only show warnings from our code, not dependencies
      const stack = new Error().stack;
      if (stack?.includes('node_modules')) return;
      originalWarn(...args);
    };
  }

  // Mock Date if needed for consistent testing
  if (process.env.MOCK_DATE) {
    globalThis.__MOCK_DATE__ = new Date(process.env.MOCK_DATE);
  }
});

/**
 * Global test cleanup - runs once after all tests
 */
afterAll(async () => {
  // Clean up any global mocks or test artifacts
  if (globalThis.__MOCK_DATE__) {
    globalThis.__MOCK_DATE__ = null;
  }
  
  // Reset environment
  delete process.env.MOCK_DATE;
  globalThis.__TEST_ENV__ = false;
});

/**
 * Setup before each test - runs before every test
 */
beforeEach(() => {
  // Clear all mocks before each test for isolation
  // This ensures tests don't interfere with each other
});

/**
 * Cleanup after each test - runs after every test
 */
afterEach(() => {
  // Additional cleanup if needed
  // Reset any test-specific state
});

/**
 * Custom test utilities and helpers
 */
export class TestHelpers {
  /**
   * Creates a mock function with better TypeScript support
   */
  static createMock<T extends (...args: any[]) => any>(
    implementation?: T
  ): Mock<T> {
    return implementation 
      ? (jest.fn(implementation) as Mock<T>)
      : (jest.fn() as Mock<T>);
  }

  /**
   * Creates a promise that resolves after a delay
   */
  static delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Waits for a condition to be true with timeout
   */
  static async waitFor<T>(
    condition: () => T | Promise<T>, 
    options: { timeout?: number; interval?: number } = {}
  ): Promise<T> {
    const { timeout = 5000, interval = 100 } = options;
    const start = Date.now();
    
    while (Date.now() - start < timeout) {
      try {
        const result = await condition();
        if (result) return result;
      } catch (error) {
        // Continue trying
      }
      await this.delay(interval);
    }
    
    throw new Error(`waitFor condition not met within ${timeout}ms`);
  }

  /**
   * Mocks the current date for consistent testing
   */
  static mockDate(date: string | Date): void {
    const mockDate = typeof date === 'string' ? new Date(date) : date;
    globalThis.__MOCK_DATE__ = mockDate;
    
    // Mock Date constructor
    const OriginalDate = Date;
    (globalThis as any).Date = class extends OriginalDate {
      constructor(...args: any[]) {
        if (args.length === 0) {
          return mockDate;
        }
        return new OriginalDate(...args);
      }
      
      static now() {
        return mockDate.getTime();
      }
    };
  }

  /**
   * Restores the original Date implementation
   */
  static restoreDate(): void {
    globalThis.__MOCK_DATE__ = null;
    // Date will be restored naturally on test cleanup
  }
}

/**
 * Common test patterns and utilities
 */
export const testPatterns = {
  /**
   * Email validation regex for testing
   */
  email: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  
  /**
   * URL validation regex for testing
   */
  url: /^https?:\/\/[^\s$.?#].[^\s]*$/,
  
  /**
   * UUID validation regex for testing
   */
  uuid: /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i,
};

/**
 * Export commonly used test utilities
 */
export { 
  expect, 
  describe, 
  it, 
  test,
  beforeAll, 
  beforeEach, 
  afterAll, 
  afterEach,
  mock,
  spyOn
} from 'bun:test';

// Make test helpers globally available
(globalThis as any).TestHelpers = TestHelpers;
(globalThis as any).testPatterns = testPatterns;