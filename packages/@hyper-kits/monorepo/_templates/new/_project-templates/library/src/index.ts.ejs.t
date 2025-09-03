---
to: packages/<%= name %>/src/index.ts
condition: projectType === 'library'
---
/**
 * <%= name %> - <%= description || `A library package for ${name}` %>
 * 
 * @packageDocumentation
 */

/**
 * A sample function that adds two numbers
 * 
 * @param a - First number to add
 * @param b - Second number to add
 * @returns The sum of a and b
 * 
 * @example
 * ```typescript
 * import { add } from '<%= packageScope ? `@${packageScope}/` : '' %><%= name %>';
 * 
 * const result = add(2, 3);
 * console.log(result); // 5
 * ```
 */
export function add(a: number, b: number): number {
  return a + b;
}

/**
 * A sample function that multiplies two numbers
 * 
 * @param a - First number to multiply
 * @param b - Second number to multiply
 * @returns The product of a and b
 * 
 * @example
 * ```typescript
 * import { multiply } from '<%= packageScope ? `@${packageScope}/` : '' %><%= name %>';
 * 
 * const result = multiply(4, 5);
 * console.log(result); // 20
 * ```
 */
export function multiply(a: number, b: number): number {
  return a * b;
}

/**
 * Configuration interface for the library
 */
export interface <%= h.changeCase.pascal(name) %>Config {
  /** Enable debug mode */
  debug?: boolean;
  /** Custom prefix for operations */
  prefix?: string;
}

/**
 * Main class for <%= name %> functionality
 * 
 * @example
 * ```typescript
 * import { <%= h.changeCase.pascal(name) %> } from '<%= packageScope ? `@${packageScope}/` : '' %><%= name %>';
 * 
 * const lib = new <%= h.changeCase.pascal(name) %>({ debug: true });
 * const result = lib.calculate(10, 5);
 * ```
 */
export class <%= h.changeCase.pascal(name) %> {
  private config: <%= h.changeCase.pascal(name) %>Config;

  constructor(config: <%= h.changeCase.pascal(name) %>Config = {}) {
    this.config = {
      debug: false,
      prefix: '<%= name %>',
      ...config
    };
  }

  /**
   * Performs a calculation with logging
   * 
   * @param a - First operand
   * @param b - Second operand
   * @returns The result of the calculation
   */
  calculate(a: number, b: number): number {
    const result = add(a, b);
    
    if (this.config.debug) {
      console.log(`${this.config.prefix}: ${a} + ${b} = ${result}`);
    }
    
    return result;
  }

  /**
   * Gets the current configuration
   * 
   * @returns The current configuration object
   */
  getConfig(): <%= h.changeCase.pascal(name) %>Config {
    return { ...this.config };
  }
}

// Export everything for convenience
export default <%= h.changeCase.pascal(name) %>;

/**
 * Version constant
 */
export const VERSION = '0.1.0';