---
to: packages/<%= name %>/src/index.test.ts
condition: projectType === 'library'
---
<% if (testFramework === 'vitest') { -%>
import { describe, it, expect, beforeEach, vi } from 'vitest';
<% } else if (testFramework === 'jest') { -%>
import { describe, it, expect, beforeEach, jest } from '@jest/globals';
<% } else if (testFramework === 'bun-test') { -%>
import { describe, it, expect, beforeEach } from 'bun:test';
<% } -%>
import { add, multiply, <%= h.changeCase.pascal(name) %>, VERSION } from './index';

describe('<%= name %> library', () => {
  describe('add function', () => {
    it('should add two positive numbers correctly', () => {
      expect(add(2, 3)).toBe(5);
      expect(add(10, 15)).toBe(25);
    });

    it('should handle negative numbers', () => {
      expect(add(-2, 3)).toBe(1);
      expect(add(-2, -3)).toBe(-5);
    });

    it('should handle zero', () => {
      expect(add(0, 5)).toBe(5);
      expect(add(5, 0)).toBe(5);
      expect(add(0, 0)).toBe(0);
    });

    it('should handle decimal numbers', () => {
      expect(add(1.5, 2.5)).toBe(4);
      expect(add(0.1, 0.2)).toBeCloseTo(0.3);
    });
  });

  describe('multiply function', () => {
    it('should multiply two positive numbers correctly', () => {
      expect(multiply(3, 4)).toBe(12);
      expect(multiply(7, 8)).toBe(56);
    });

    it('should handle negative numbers', () => {
      expect(multiply(-2, 3)).toBe(-6);
      expect(multiply(-2, -3)).toBe(6);
    });

    it('should handle zero', () => {
      expect(multiply(0, 5)).toBe(0);
      expect(multiply(5, 0)).toBe(0);
      expect(multiply(0, 0)).toBe(0);
    });

    it('should handle decimal numbers', () => {
      expect(multiply(2.5, 4)).toBe(10);
      expect(multiply(0.5, 0.5)).toBe(0.25);
    });
  });

  describe('<%= h.changeCase.pascal(name) %> class', () => {
    let instance: <%= h.changeCase.pascal(name) %>;

    beforeEach(() => {
      instance = new <%= h.changeCase.pascal(name) %>();
    });

    describe('constructor', () => {
      it('should create instance with default config', () => {
        const config = instance.getConfig();
        expect(config.debug).toBe(false);
        expect(config.prefix).toBe('<%= name %>');
      });

      it('should accept custom configuration', () => {
        const customInstance = new <%= h.changeCase.pascal(name) %>({
          debug: true,
          prefix: 'custom'
        });
        
        const config = customInstance.getConfig();
        expect(config.debug).toBe(true);
        expect(config.prefix).toBe('custom');
      });

      it('should merge with defaults', () => {
        const customInstance = new <%= h.changeCase.pascal(name) %>({
          debug: true
          // prefix should use default
        });
        
        const config = customInstance.getConfig();
        expect(config.debug).toBe(true);
        expect(config.prefix).toBe('<%= name %>');
      });
    });

    describe('calculate method', () => {
      it('should perform calculation correctly', () => {
        expect(instance.calculate(5, 3)).toBe(8);
        expect(instance.calculate(10, -5)).toBe(5);
      });

      it('should not log when debug is false', () => {
<% if (testFramework === 'vitest') { -%>
        const consoleSpy = vi.spyOn(console, 'log').mockImplementation(() => {});
<% } else if (testFramework === 'jest') { -%>
        const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
<% } else if (testFramework === 'bun-test') { -%>
        const consoleSpy = spyOn(console, 'log').mockImplementation(() => {});
<% } -%>
        
        instance.calculate(5, 3);
        expect(consoleSpy).not.toHaveBeenCalled();
        
        consoleSpy.mockRestore();
      });

      it('should log when debug is true', () => {
        const debugInstance = new <%= h.changeCase.pascal(name) %>({ debug: true });
<% if (testFramework === 'vitest') { -%>
        const consoleSpy = vi.spyOn(console, 'log').mockImplementation(() => {});
<% } else if (testFramework === 'jest') { -%>
        const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
<% } else if (testFramework === 'bun-test') { -%>
        const consoleSpy = spyOn(console, 'log').mockImplementation(() => {});
<% } -%>
        
        debugInstance.calculate(5, 3);
        expect(consoleSpy).toHaveBeenCalledWith('<%= name %>: 5 + 3 = 8');
        
        consoleSpy.mockRestore();
      });

      it('should use custom prefix in debug logs', () => {
        const customInstance = new <%= h.changeCase.pascal(name) %>({ 
          debug: true, 
          prefix: 'test-lib' 
        });
<% if (testFramework === 'vitest') { -%>
        const consoleSpy = vi.spyOn(console, 'log').mockImplementation(() => {});
<% } else if (testFramework === 'jest') { -%>
        const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
<% } else if (testFramework === 'bun-test') { -%>
        const consoleSpy = spyOn(console, 'log').mockImplementation(() => {});
<% } -%>
        
        customInstance.calculate(2, 7);
        expect(consoleSpy).toHaveBeenCalledWith('test-lib: 2 + 7 = 9');
        
        consoleSpy.mockRestore();
      });
    });

    describe('getConfig method', () => {
      it('should return a copy of the configuration', () => {
        const config1 = instance.getConfig();
        const config2 = instance.getConfig();
        
        expect(config1).toEqual(config2);
        expect(config1).not.toBe(config2); // Should be different objects
      });

      it('should not allow external modification of internal config', () => {
        const config = instance.getConfig();
        config.debug = true;
        
        // Original instance config should remain unchanged
        expect(instance.getConfig().debug).toBe(false);
      });
    });
  });

  describe('VERSION constant', () => {
    it('should export version string', () => {
      expect(typeof VERSION).toBe('string');
      expect(VERSION).toBe('0.1.0');
    });
  });

  describe('module exports', () => {
    it('should export all expected functions and classes', () => {
      expect(typeof add).toBe('function');
      expect(typeof multiply).toBe('function');
      expect(typeof <%= h.changeCase.pascal(name) %>).toBe('function'); // Constructor
      expect(typeof VERSION).toBe('string');
    });

    it('should have default export', async () => {
      const defaultExport = await import('./index');
      expect(defaultExport.default).toBe(<%= h.changeCase.pascal(name) %>);
    });
  });
});