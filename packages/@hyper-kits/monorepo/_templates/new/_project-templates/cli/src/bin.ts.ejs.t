---
to: apps/<%= name %>/src/bin.ts
condition: projectType === 'cli'
---
#!/usr/bin/env node

import { Command } from 'commander';
import chalk from 'chalk';
import { createReadStream, readFileSync } from 'fs';
import { createRequire } from 'module';
import path from 'path';
import { fileURLToPath } from 'url';
import { CLI } from './index.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Get package.json for version info
const require = createRequire(import.meta.url);
let packageJson: any;

try {
  // Try to load from built dist directory
  packageJson = require('../package.json');
} catch {
  try {
    // Fallback to src directory during development
    packageJson = JSON.parse(
      readFileSync(path.join(__dirname, '../../package.json'), 'utf-8')
    );
  } catch {
    packageJson = { version: '0.1.0', description: '<%= description || `CLI tool for ${name}` %>' };
  }
}

const program = new Command();
const cli = new CLI();

program
  .name('<%= cliName || name %>')
  .description(packageJson.description || '<%= description || `CLI tool for ${name}` %>')
  .version(packageJson.version || '0.1.0');

// Hello command - basic example
program
  .command('hello [name]')
  .description('Say hello to someone')
  .option('-u, --uppercase', 'Output in uppercase')
  .option('-c, --color <color>', 'Output color', 'blue')
  .action(async (name: string | undefined, options) => {
    try {
      await cli.hello(name, options);
    } catch (error) {
      console.error(chalk.red('Error:'), error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

// Init command - project initialization example
program
  .command('init [directory]')
  .description('Initialize a new project')
  .option('-t, --template <template>', 'Project template to use', 'basic')
  .option('-f, --force', 'Overwrite existing files')
  .option('--dry-run', 'Show what would be created without actually creating files')
  .action(async (directory: string | undefined, options) => {
    try {
      await cli.init(directory, options);
    } catch (error) {
      console.error(chalk.red('Error:'), error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

// Config commands
const configCommand = program
  .command('config')
  .description('Manage configuration');

configCommand
  .command('get [key]')
  .description('Get configuration value(s)')
  .action(async (key: string | undefined) => {
    try {
      await cli.getConfig(key);
    } catch (error) {
      console.error(chalk.red('Error:'), error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

configCommand
  .command('set <key> <value>')
  .description('Set configuration value')
  .action(async (key: string, value: string) => {
    try {
      await cli.setConfig(key, value);
    } catch (error) {
      console.error(chalk.red('Error:'), error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

configCommand
  .command('list')
  .alias('ls')
  .description('List all configuration values')
  .action(async () => {
    try {
      await cli.listConfig();
    } catch (error) {
      console.error(chalk.red('Error:'), error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

// Process command - file processing example
program
  .command('process <input>')
  .description('Process a file or directory')
  .option('-o, --output <output>', 'Output file or directory')
  .option('--format <format>', 'Output format', 'json')
  .option('-v, --verbose', 'Verbose output')
  .action(async (input: string, options) => {
    try {
      await cli.processFile(input, options);
    } catch (error) {
      console.error(chalk.red('Error:'), error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

// Global error handling
process.on('unhandledRejection', (reason, promise) => {
  console.error(chalk.red('Unhandled Rejection at:'), promise, chalk.red('reason:'), reason);
  process.exit(1);
});

process.on('uncaughtException', (error) => {
  console.error(chalk.red('Uncaught Exception:'), error);
  process.exit(1);
});

// Parse command line arguments
program.parse();

// Show help if no command provided
if (!process.argv.slice(2).length) {
  program.outputHelp();
}