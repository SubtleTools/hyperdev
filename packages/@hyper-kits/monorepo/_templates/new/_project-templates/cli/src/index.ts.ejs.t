---
to: apps/<%= name %>/src/index.ts
condition: projectType === 'cli'
---
import chalk from 'chalk';
import fs from 'fs-extra';
import inquirer from 'inquirer';
import ora from 'ora';
import path from 'path';
import os from 'os';

/**
 * Configuration interface for the CLI
 */
export interface <%= h.changeCase.pascal(name) %>Config {
  /** Default output format */
  defaultFormat?: 'json' | 'yaml' | 'text';
  /** Verbose output by default */
  verbose?: boolean;
  /** Default template */
  defaultTemplate?: string;
  /** User preferences */
  preferences?: {
    theme?: 'light' | 'dark' | 'auto';
    editor?: string;
  };
}

/**
 * Options for the hello command
 */
export interface HelloOptions {
  uppercase?: boolean;
  color?: string;
}

/**
 * Options for the init command
 */
export interface InitOptions {
  template?: string;
  force?: boolean;
  dryRun?: boolean;
}

/**
 * Options for the process command
 */
export interface ProcessOptions {
  output?: string;
  format?: string;
  verbose?: boolean;
}

/**
 * Main CLI class for <%= name %>
 */
export class CLI {
  private configPath: string;
  private config: <%= h.changeCase.pascal(name) %>Config;

  constructor() {
    this.configPath = path.join(os.homedir(), '.<%= name %>rc.json');
    this.config = this.loadConfig();
  }

  /**
   * Load configuration from file
   */
  private loadConfig(): <%= h.changeCase.pascal(name) %>Config {
    try {
      if (fs.existsSync(this.configPath)) {
        return fs.readJsonSync(this.configPath);
      }
    } catch (error) {
      // Ignore errors and use defaults
    }

    return {
      defaultFormat: 'json',
      verbose: false,
      defaultTemplate: 'basic',
      preferences: {
        theme: 'auto'
      }
    };
  }

  /**
   * Save configuration to file
   */
  private async saveConfig(): Promise<void> {
    try {
      await fs.ensureDir(path.dirname(this.configPath));
      await fs.writeJson(this.configPath, this.config, { spaces: 2 });
    } catch (error) {
      throw new Error(`Failed to save configuration: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * Say hello command
   */
  async hello(name?: string, options: HelloOptions = {}): Promise<void> {
    let greeting: string;

    if (!name) {
      const answer = await inquirer.prompt([
        {
          type: 'input',
          name: 'name',
          message: 'What is your name?',
          default: 'World'
        }
      ]);
      name = answer.name;
    }

    greeting = `Hello, ${name}!`;

    if (options.uppercase) {
      greeting = greeting.toUpperCase();
    }

    // Apply color
    const colorFn = chalk[options.color as keyof typeof chalk] || chalk.blue;
    if (typeof colorFn === 'function') {
      console.log(colorFn(greeting));
    } else {
      console.log(chalk.blue(greeting));
    }
  }

  /**
   * Initialize project command
   */
  async init(directory?: string, options: InitOptions = {}): Promise<void> {
    const spinner = ora('Initializing project...').start();

    try {
      // Get directory
      const targetDir = directory || await this.promptForDirectory();
      const absoluteDir = path.resolve(targetDir);

      // Check if directory exists and handle force option
      if (await fs.pathExists(absoluteDir)) {
        const files = await fs.readdir(absoluteDir);
        if (files.length > 0 && !options.force) {
          spinner.stop();
          const shouldContinue = await inquirer.prompt([
            {
              type: 'confirm',
              name: 'continue',
              message: `Directory ${targetDir} is not empty. Continue anyway?`,
              default: false
            }
          ]);

          if (!shouldContinue.continue) {
            console.log(chalk.yellow('Initialization cancelled.'));
            return;
          }
          spinner.start();
        }
      }

      // Get template
      const template = options.template || await this.promptForTemplate();

      if (options.dryRun) {
        spinner.stop();
        console.log(chalk.cyan('Dry run mode - showing what would be created:'));
        console.log(chalk.gray(`Directory: ${absoluteDir}`));
        console.log(chalk.gray(`Template: ${template}`));
        console.log(chalk.gray('Files that would be created:'));
        console.log(chalk.gray('  - package.json'));
        console.log(chalk.gray('  - README.md'));
        console.log(chalk.gray('  - src/index.ts'));
        console.log(chalk.gray('  - .gitignore'));
        return;
      }

      // Create directory
      await fs.ensureDir(absoluteDir);

      // Create basic project structure
      await this.createProjectFiles(absoluteDir, template);

      spinner.succeed(chalk.green(`Project initialized successfully in ${targetDir}`));
      
      console.log(chalk.cyan('\nNext steps:'));
      console.log(chalk.gray(`  cd ${targetDir}`));
      console.log(chalk.gray('  npm install'));
      console.log(chalk.gray('  npm run dev'));
    } catch (error) {
      spinner.fail('Failed to initialize project');
      throw error;
    }
  }

  /**
   * Get configuration command
   */
  async getConfig(key?: string): Promise<void> {
    if (key) {
      const value = this.getNestedValue(this.config, key);
      if (value !== undefined) {
        console.log(chalk.cyan(`${key}:`), value);
      } else {
        console.log(chalk.yellow(`Configuration key "${key}" not found`));
      }
    } else {
      console.log(chalk.cyan('Current configuration:'));
      console.log(JSON.stringify(this.config, null, 2));
    }
  }

  /**
   * Set configuration command
   */
  async setConfig(key: string, value: string): Promise<void> {
    // Parse value (basic type inference)
    let parsedValue: any = value;
    if (value === 'true') parsedValue = true;
    else if (value === 'false') parsedValue = false;
    else if (/^\d+$/.test(value)) parsedValue = parseInt(value, 10);
    else if (/^\d+\.\d+$/.test(value)) parsedValue = parseFloat(value);

    this.setNestedValue(this.config, key, parsedValue);
    await this.saveConfig();
    
    console.log(chalk.green(`Configuration updated: ${key} = ${parsedValue}`));
  }

  /**
   * List all configuration
   */
  async listConfig(): Promise<void> {
    console.log(chalk.cyan('All configuration values:'));
    this.printObjectFlat(this.config);
  }

  /**
   * Process file command
   */
  async processFile(input: string, options: ProcessOptions = {}): Promise<void> {
    const verbose = options.verbose || this.config.verbose;
    const format = options.format || this.config.defaultFormat || 'json';
    
    if (verbose) {
      console.log(chalk.cyan('Processing:'), input);
      console.log(chalk.cyan('Format:'), format);
    }

    const spinner = ora('Processing file...').start();

    try {
      const inputPath = path.resolve(input);
      
      // Check if input exists
      if (!await fs.pathExists(inputPath)) {
        throw new Error(`Input file or directory does not exist: ${input}`);
      }

      const stats = await fs.stat(inputPath);
      let result: any;

      if (stats.isDirectory()) {
        // Process directory
        const files = await fs.readdir(inputPath);
        result = {
          type: 'directory',
          path: inputPath,
          files: files.length,
          items: files
        };
      } else {
        // Process file
        const content = await fs.readFile(inputPath, 'utf-8');
        result = {
          type: 'file',
          path: inputPath,
          size: stats.size,
          lines: content.split('\n').length,
          // Add basic content analysis
          wordCount: content.split(/\s+/).length,
          extension: path.extname(inputPath)
        };
      }

      spinner.succeed('Processing completed');

      // Output result
      const outputPath = options.output;
      if (outputPath) {
        await fs.writeFile(outputPath, this.formatOutput(result, format));
        console.log(chalk.green(`Results written to: ${outputPath}`));
      } else {
        console.log('\n' + this.formatOutput(result, format));
      }
    } catch (error) {
      spinner.fail('Processing failed');
      throw error;
    }
  }

  /**
   * Helper methods
   */

  private async promptForDirectory(): Promise<string> {
    const answer = await inquirer.prompt([
      {
        type: 'input',
        name: 'directory',
        message: 'Project directory:',
        default: 'my-project'
      }
    ]);
    return answer.directory;
  }

  private async promptForTemplate(): Promise<string> {
    const answer = await inquirer.prompt([
      {
        type: 'list',
        name: 'template',
        message: 'Choose a template:',
        choices: [
          { name: 'Basic - Simple project structure', value: 'basic' },
          { name: 'Advanced - Full featured setup', value: 'advanced' },
          { name: 'Minimal - Bare minimum files', value: 'minimal' }
        ],
        default: this.config.defaultTemplate || 'basic'
      }
    ]);
    return answer.template;
  }

  private async createProjectFiles(dir: string, template: string): Promise<void> {
    // Create package.json
    const packageJson = {
      name: path.basename(dir),
      version: '1.0.0',
      description: `Project created with <%= name %>`,
      main: 'dist/index.js',
      scripts: {
        build: 'tsc',
        dev: 'tsx src/index.ts',
        start: 'node dist/index.js'
      },
      devDependencies: {
        typescript: '^5.0.0',
        tsx: '^4.0.0',
        '@types/node': '^20.0.0'
      }
    };

    await fs.writeJson(path.join(dir, 'package.json'), packageJson, { spaces: 2 });

    // Create basic files
    const files = {
      'README.md': this.getReadmeTemplate(template),
      'src/index.ts': this.getIndexTemplate(template),
      '.gitignore': this.getGitignoreTemplate(),
      'tsconfig.json': this.getTsConfigTemplate()
    };

    for (const [filePath, content] of Object.entries(files)) {
      const fullPath = path.join(dir, filePath);
      await fs.ensureDir(path.dirname(fullPath));
      await fs.writeFile(fullPath, content);
    }
  }

  private getReadmeTemplate(template: string): string {
    return `# My Project

Created with <%= name %> using the ${template} template.

## Getting Started

\`\`\`bash
npm install
npm run dev
\`\`\`

## Scripts

- \`npm run build\` - Build the project
- \`npm run dev\` - Run in development mode
- \`npm start\` - Run the built project
`;
  }

  private getIndexTemplate(template: string): string {
    return `console.log('Hello from ${template} template!');

export function main() {
  console.log('Welcome to your new project!');
}

if (import.meta.url === \`file://\${process.argv[1]}\`) {
  main();
}
`;
  }

  private getGitignoreTemplate(): string {
    return `node_modules/
dist/
.env
.env.local
*.log
.DS_Store
`;
  }

  private getTsConfigTemplate(): string {
    return JSON.stringify({
      compilerOptions: {
        target: 'ES2022',
        module: 'ESNext',
        moduleResolution: 'node',
        esModuleInterop: true,
        allowSyntheticDefaultImports: true,
        strict: true,
        declaration: true,
        outDir: 'dist',
        rootDir: 'src'
      },
      include: ['src/**/*'],
      exclude: ['node_modules', 'dist']
    }, null, 2);
  }

  private formatOutput(data: any, format: string): string {
    switch (format.toLowerCase()) {
      case 'yaml':
        // Simple YAML-like format
        return Object.entries(data)
          .map(([key, value]) => `${key}: ${value}`)
          .join('\n');
      
      case 'text':
        return Object.entries(data)
          .map(([key, value]) => `${key}: ${value}`)
          .join('\n');
      
      case 'json':
      default:
        return JSON.stringify(data, null, 2);
    }
  }

  private getNestedValue(obj: any, path: string): any {
    return path.split('.').reduce((current, key) => current?.[key], obj);
  }

  private setNestedValue(obj: any, path: string, value: any): void {
    const keys = path.split('.');
    const lastKey = keys.pop()!;
    const target = keys.reduce((current, key) => {
      if (!(key in current)) current[key] = {};
      return current[key];
    }, obj);
    target[lastKey] = value;
  }

  private printObjectFlat(obj: any, prefix = ''): void {
    for (const [key, value] of Object.entries(obj)) {
      const fullKey = prefix ? `${prefix}.${key}` : key;
      if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
        this.printObjectFlat(value, fullKey);
      } else {
        console.log(chalk.cyan(`${fullKey}:`), value);
      }
    }
  }
}

export default CLI;