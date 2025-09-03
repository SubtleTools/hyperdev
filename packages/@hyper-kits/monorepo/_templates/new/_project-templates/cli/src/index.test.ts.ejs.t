---
to: apps/<%= name %>/src/index.test.ts
condition: projectType === 'cli'
---
<% if (testFramework === 'vitest') { -%>
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
<% } else if (testFramework === 'jest') { -%>
import { describe, it, expect, beforeEach, afterEach, jest } from '@jest/globals';
<% } else if (testFramework === 'bun-test') { -%>
import { describe, it, expect, beforeEach, afterEach } from 'bun:test';
<% } -%>
import fs from 'fs-extra';
import path from 'path';
import os from 'os';
import { CLI } from './index';

// Mock dependencies
<% if (testFramework === 'vitest') { -%>
vi.mock('inquirer');
vi.mock('ora');
vi.mock('fs-extra');
<% } else if (testFramework === 'jest') { -%>
jest.mock('inquirer');
jest.mock('ora');
jest.mock('fs-extra');
<% } else if (testFramework === 'bun-test') { -%>
// Note: Bun test mocking might need different approach
<% } -%>

const mockFs = fs as any;
<% if (testFramework === 'vitest') { -%>
const mockInquirer = vi.mocked(await import('inquirer'));
const mockOra = vi.mocked(await import('ora'));
<% } else if (testFramework === 'jest') { -%>
const mockInquirer = jest.mocked(await import('inquirer'));
const mockOra = jest.mocked(await import('ora'));
<% } -%>

describe('<%= name %> CLI', () => {
  let cli: CLI;
  let mockSpinner: any;
  let originalConsoleLog: typeof console.log;
  let originalConsoleError: typeof console.error;
  let consoleLogs: string[];
  let consoleErrors: string[];

  beforeEach(() => {
    // Reset mocks
<% if (testFramework === 'vitest') { -%>
    vi.clearAllMocks();
<% } else if (testFramework === 'jest') { -%>
    jest.clearAllMocks();
<% } -%>

    // Mock spinner
    mockSpinner = {
      start: <% if (testFramework === 'vitest') { %>vi.fn().mockReturnThis()<% } else if (testFramework === 'jest') { %>jest.fn().mockReturnThis()<% } else { %>() => mockSpinner<% } %>,
      succeed: <% if (testFramework === 'vitest') { %>vi.fn()<% } else if (testFramework === 'jest') { %>jest.fn()<% } else { %>() => {}<% } %>,
      fail: <% if (testFramework === 'vitest') { %>vi.fn()<% } else if (testFramework === 'jest') { %>jest.fn()<% } else { %>() => {}<% } %>,
      stop: <% if (testFramework === 'vitest') { %>vi.fn()<% } else if (testFramework === 'jest') { %>jest.fn()<% } else { %>() => {}<% } %>
    };

<% if (testFramework !== 'bun-test') { -%>
    mockOra.default = <% if (testFramework === 'vitest') { %>vi.fn()<% } else { %>jest.fn()<% } %>.mockReturnValue(mockSpinner);
<% } -%>

    // Mock fs-extra
    mockFs.existsSync = <% if (testFramework === 'vitest') { %>vi.fn()<% } else if (testFramework === 'jest') { %>jest.fn()<% } else { %>() => false<% } %>.mockReturnValue(false);
    mockFs.readJsonSync = <% if (testFramework === 'vitest') { %>vi.fn()<% } else if (testFramework === 'jest') { %>jest.fn()<% } else { %>() => ({})<% } %>.mockReturnValue({});
    mockFs.ensureDir = <% if (testFramework === 'vitest') { %>vi.fn()<% } else if (testFramework === 'jest') { %>jest.fn()<% } else { %>async () => {}<% } %>.mockResolvedValue(undefined);
    mockFs.writeJson = <% if (testFramework === 'vitest') { %>vi.fn()<% } else if (testFramework === 'jest') { %>jest.fn()<% } else { %>async () => {}<% } %>.mockResolvedValue(undefined);
    mockFs.pathExists = <% if (testFramework === 'vitest') { %>vi.fn()<% } else if (testFramework === 'jest') { %>jest.fn()<% } else { %>async () => true<% } %>.mockResolvedValue(true);
    mockFs.readdir = <% if (testFramework === 'vitest') { %>vi.fn()<% } else if (testFramework === 'jest') { %>jest.fn()<% } else { %>async () => []<% } %>.mockResolvedValue([]);
    mockFs.stat = <% if (testFramework === 'vitest') { %>vi.fn()<% } else if (testFramework === 'jest') { %>jest.fn()<% } else { %>async () => ({ isDirectory: () => false, size: 1024 })<% } %>.mockResolvedValue({
      isDirectory: <% if (testFramework === 'vitest') { %>vi.fn()<% } else if (testFramework === 'jest') { %>jest.fn()<% } else { %>() => false<% } %>.mockReturnValue(false),
      size: 1024
    });
    mockFs.readFile = <% if (testFramework === 'vitest') { %>vi.fn()<% } else if (testFramework === 'jest') { %>jest.fn()<% } else { %>async () => 'test content'<% } %>.mockResolvedValue('test content');
    mockFs.writeFile = <% if (testFramework === 'vitest') { %>vi.fn()<% } else if (testFramework === 'jest') { %>jest.fn()<% } else { %>async () => {}<% } %>.mockResolvedValue(undefined);

    // Capture console output
    consoleLogs = [];
    consoleErrors = [];
    originalConsoleLog = console.log;
    originalConsoleError = console.error;
    console.log = (...args) => consoleLogs.push(args.join(' '));
    console.error = (...args) => consoleErrors.push(args.join(' '));

    cli = new CLI();
  });

  afterEach(() => {
    // Restore console
    console.log = originalConsoleLog;
    console.error = originalConsoleError;
  });

  describe('constructor', () => {
    it('should initialize with default configuration', () => {
      expect(cli).toBeInstanceOf(CLI);
    });

    it('should set config path to user home directory', () => {
      const expectedPath = path.join(os.homedir(), '.<%= name %>rc.json');
      // We can't directly test the private property, but we can test the behavior
      expect(mockFs.existsSync).toHaveBeenCalledWith(expectedPath);
    });
  });

  describe('hello command', () => {
    it('should greet with provided name', async () => {
      await cli.hello('Alice');
      
      expect(consoleLogs.some(log => log.includes('Hello, Alice!'))).toBe(true);
    });

    it('should prompt for name when not provided', async () => {
<% if (testFramework !== 'bun-test') { -%>
      mockInquirer.prompt = <% if (testFramework === 'vitest') { %>vi.fn()<% } else { %>jest.fn()<% } %>.mockResolvedValue({ name: 'Bob' });
<% } -%>

      await cli.hello();

<% if (testFramework !== 'bun-test') { -%>
      expect(mockInquirer.prompt).toHaveBeenCalledWith([
        expect.objectContaining({
          type: 'input',
          name: 'name',
          message: 'What is your name?',
          default: 'World'
        })
      ]);
<% } -%>
      expect(consoleLogs.some(log => log.includes('Hello, Bob!'))).toBe(true);
    });

    it('should apply uppercase option', async () => {
      await cli.hello('Charlie', { uppercase: true });
      
      expect(consoleLogs.some(log => log.includes('HELLO, CHARLIE!'))).toBe(true);
    });

    it('should handle color option', async () => {
      await cli.hello('Dave', { color: 'red' });
      
      // Since we're testing with mocked chalk, we just verify the greeting exists
      expect(consoleLogs.some(log => log.includes('Hello, Dave!'))).toBe(true);
    });
  });

  describe('init command', () => {
    beforeEach(() => {
<% if (testFramework !== 'bun-test') { -%>
      mockInquirer.prompt = <% if (testFramework === 'vitest') { %>vi.fn()<% } else { %>jest.fn()<% } %>.mockResolvedValue({
        directory: 'test-project',
        template: 'basic'
      });
<% } -%>
    });

    it('should initialize project with provided directory', async () => {
      await cli.init('my-project', { template: 'basic' });

      expect(mockFs.ensureDir).toHaveBeenCalled();
      expect(mockSpinner.succeed).toHaveBeenCalled();
    });

    it('should prompt for directory when not provided', async () => {
      await cli.init(undefined, { template: 'basic' });

<% if (testFramework !== 'bun-test') { -%>
      expect(mockInquirer.prompt).toHaveBeenCalledWith([
        expect.objectContaining({
          type: 'input',
          name: 'directory',
          message: 'Project directory:',
          default: 'my-project'
        })
      ]);
<% } -%>
    });

    it('should handle dry run mode', async () => {
      await cli.init('test-project', { template: 'basic', dryRun: true });

      expect(consoleLogs.some(log => log.includes('Dry run mode'))).toBe(true);
      expect(mockFs.ensureDir).not.toHaveBeenCalled();
    });

    it('should handle force option for existing directory', async () => {
      mockFs.readdir.mockResolvedValue(['existing-file.txt']);
      
      await cli.init('existing-project', { template: 'basic', force: true });

      expect(mockFs.ensureDir).toHaveBeenCalled();
      expect(mockSpinner.succeed).toHaveBeenCalled();
    });
  });

  describe('config commands', () => {
    describe('getConfig', () => {
      it('should display all config when no key provided', async () => {
        await cli.getConfig();

        expect(consoleLogs.some(log => log.includes('Current configuration'))).toBe(true);
      });

      it('should display specific config value', async () => {
        await cli.getConfig('defaultFormat');

        expect(consoleLogs.some(log => log.includes('defaultFormat'))).toBe(true);
      });

      it('should handle non-existent config key', async () => {
        await cli.getConfig('nonExistentKey');

        expect(consoleLogs.some(log => log.includes('not found'))).toBe(true);
      });
    });

    describe('setConfig', () => {
      it('should set string configuration value', async () => {
        await cli.setConfig('defaultTemplate', 'advanced');

        expect(mockFs.writeJson).toHaveBeenCalled();
        expect(consoleLogs.some(log => log.includes('Configuration updated'))).toBe(true);
      });

      it('should parse boolean values', async () => {
        await cli.setConfig('verbose', 'true');

        expect(consoleLogs.some(log => log.includes('verbose = true'))).toBe(true);
      });

      it('should parse numeric values', async () => {
        await cli.setConfig('maxFiles', '100');

        expect(consoleLogs.some(log => log.includes('maxFiles = 100'))).toBe(true);
      });
    });

    describe('listConfig', () => {
      it('should list all configuration values', async () => {
        await cli.listConfig();

        expect(consoleLogs.some(log => log.includes('All configuration values'))).toBe(true);
      });
    });
  });

  describe('processFile command', () => {
    it('should process a file successfully', async () => {
      await cli.processFile('test.txt');

      expect(mockFs.pathExists).toHaveBeenCalled();
      expect(mockFs.stat).toHaveBeenCalled();
      expect(mockFs.readFile).toHaveBeenCalled();
      expect(mockSpinner.succeed).toHaveBeenCalled();
    });

    it('should handle directory processing', async () => {
      mockFs.stat.mockResolvedValue({
        isDirectory: <% if (testFramework === 'vitest') { %>vi.fn()<% } else if (testFramework === 'jest') { %>jest.fn()<% } else { %>() => true<% } %>.mockReturnValue(true),
        size: 0
      });
      mockFs.readdir.mockResolvedValue(['file1.txt', 'file2.txt']);

      await cli.processFile('test-dir');

      expect(mockFs.readdir).toHaveBeenCalled();
      expect(mockSpinner.succeed).toHaveBeenCalled();
    });

    it('should handle non-existent input', async () => {
      mockFs.pathExists.mockResolvedValue(false);

      await expect(cli.processFile('non-existent.txt')).rejects.toThrow('does not exist');
    });

    it('should write output to file when specified', async () => {
      await cli.processFile('test.txt', { output: 'output.json' });

      expect(mockFs.writeFile).toHaveBeenCalledWith('output.json', expect.any(String));
    });

    it('should respect verbose option', async () => {
      await cli.processFile('test.txt', { verbose: true });

      expect(consoleLogs.some(log => log.includes('Processing:'))).toBe(true);
    });
  });

  describe('error handling', () => {
    it('should handle file system errors gracefully', async () => {
      mockFs.pathExists.mockRejectedValue(new Error('File system error'));

      await expect(cli.processFile('test.txt')).rejects.toThrow();
      expect(mockSpinner.fail).toHaveBeenCalled();
    });

    it('should handle config save errors', async () => {
      mockFs.writeJson.mockRejectedValue(new Error('Permission denied'));

      await expect(cli.setConfig('test', 'value')).rejects.toThrow('Failed to save configuration');
    });
  });

  describe('helper methods', () => {
    it('should handle nested configuration paths', async () => {
      await cli.setConfig('preferences.theme', 'dark');

      expect(consoleLogs.some(log => log.includes('preferences.theme = dark'))).toBe(true);
    });

    it('should format output correctly', async () => {
      mockFs.stat.mockResolvedValue({
        isDirectory: () => false,
        size: 1024
      });

      await cli.processFile('test.txt', { format: 'json' });

      // Verify JSON output was generated (mocked writeFile or console output)
      const hasJsonOutput = consoleLogs.some(log => {
        try {
          JSON.parse(log);
          return true;
        } catch {
          return false;
        }
      });
      expect(hasJsonOutput || mockFs.writeFile.mock.calls.length > 0).toBe(true);
    });
  });
});