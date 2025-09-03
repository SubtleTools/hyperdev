---
to: .prettierrc.js
condition: formatter === 'prettier'
---
module.exports = {
  // Base configuration optimized for TypeScript monorepos
  printWidth: <%= preset === 'minimal' ? '80' : '100' %>,
  tabWidth: 2,
  useTabs: false,
  semi: true,
  singleQuote: true,
  quoteProps: 'as-needed',
  trailingComma: 'es5',
  bracketSpacing: true,
  bracketSameLine: false,
  arrowParens: 'avoid',
  endOfLine: 'lf',
  proseWrap: 'preserve',
  
  // Plugin configurations for monorepo support
  plugins: [
<% if (packageManager === 'bun') { -%>
    // Bun-specific formatting support if available
<% } -%>
  ],
  
  overrides: [
    // JSON configuration files
    {
      files: ['*.json', '**/*.json'],
      options: {
        tabWidth: 2,
        parser: 'json',
      },
    },
    
    // Package.json files in monorepo packages
    {
      files: ['**/package.json'],
      options: {
        tabWidth: 2,
        parser: 'json-stringify',
      },
    },
    
    // Markdown documentation
    {
      files: ['*.md', '**/*.md'],
      options: {
        printWidth: 80,
        proseWrap: 'preserve',
        parser: 'markdown',
      },
    },
    
    // YAML configuration files
    {
      files: ['*.yml', '*.yaml', '**/*.yml', '**/*.yaml'],
      options: {
        tabWidth: 2,
        singleQuote: false,
        parser: 'yaml',
      },
    },
    
    // TypeScript configuration files
    {
      files: ['tsconfig*.json'],
      options: {
        tabWidth: 2,
        parser: 'jsonc',
      },
    },
    
<% if (testFramework === 'jest') { -%>
    // Jest snapshot files
    {
      files: ['**/*.snap'],
      options: {
        printWidth: 120,
      },
    },
    
<% } -%>
    // Scripts and configuration files
    {
      files: ['**/*.config.{js,mjs,ts}', '**/scripts/**/*.{js,ts}'],
      options: {
        printWidth: <%= preset === 'minimal' ? '80' : '100' %>,
        semi: true,
      },
    },
    
<% if (preset !== 'minimal') { -%>
    // Application-specific overrides
    {
      files: ['apps/**/*.{js,ts,tsx,jsx}'],
      options: {
        printWidth: 100,
        singleQuote: true,
      },
    },
    
    // Library-specific overrides
    {
      files: ['packages/**/*.{js,ts,tsx,jsx}', 'libs/**/*.{js,ts,tsx,jsx}'],
      options: {
        printWidth: 100,
        singleQuote: true,
      },
    },
    
<% } -%>
  ],
};