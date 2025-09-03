---
to: .eslintrc.js
condition: linter === 'eslint'
---
module.exports = {
  root: true,
  extends: [
    '@typescript-eslint/recommended',
    '@typescript-eslint/recommended-requiring-type-checking',
<% if (formatter === 'prettier') { -%>
    'prettier',
<% } -%>
  ],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 2022,
    sourceType: 'module',
    tsconfigRootDir: __dirname,
    project: [
      './tsconfig.json',
      './packages/*/tsconfig.json',
<% if (preset !== 'minimal') { -%>
      './apps/*/tsconfig.json',
      './libs/*/tsconfig.json',
<% } -%>
    ],
  },
  plugins: ['@typescript-eslint', 'import'],
  env: {
    node: true,
    es2022: true,
  },
  ignorePatterns: [
    'node_modules/',
    'dist/',
    'build/',
    '.moon/',
    'coverage/',
    '*.config.js',
    '*.config.mjs',
    '*.d.ts',
<% if (packageManager === 'bun') { -%>
    'bun.lockb',
<% } else if (packageManager === 'npm') { -%>
    'package-lock.json',
<% } else if (packageManager === 'yarn') { -%>
    'yarn.lock',
<% } else if (packageManager === 'pnpm') { -%>
    'pnpm-lock.yaml',
<% } -%>
  ],
  settings: {
    'import/resolver': {
      typescript: {
        alwaysTryTypes: true,
        project: [
          './tsconfig.json',
          './packages/*/tsconfig.json',
<% if (preset !== 'minimal') { -%>
          './apps/*/tsconfig.json',
          './libs/*/tsconfig.json',
<% } -%>
        ],
      },
    },
  },
  rules: {
    // TypeScript-specific rules for monorepo
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/no-explicit-any': 'warn',
    '@typescript-eslint/prefer-nullish-coalescing': 'error',
    '@typescript-eslint/prefer-optional-chain': 'error',
    '@typescript-eslint/no-floating-promises': 'error',
    '@typescript-eslint/await-thenable': 'error',
    
    // Import/Export rules for monorepo structure
    'import/order': [
      'error',
      {
        groups: [
          'builtin',
          'external',
          'internal',
          'parent',
          'sibling',
          'index',
        ],
        'newlines-between': 'always',
        alphabetize: {
          order: 'asc',
          caseInsensitive: true,
        },
      },
    ],
    'import/no-default-export': 'off',
    'import/prefer-default-export': 'off',
    
    // General code quality rules
    'prefer-template': 'error',
    'no-console': 'warn',
    'no-debugger': 'error',
    'prefer-const': 'error',
    'object-shorthand': 'error',
  },
  overrides: [
<% if (testFramework === 'jest') { -%>
    {
      files: ['**/*.test.{js,ts,tsx}', '**/*.spec.{js,ts,tsx}'],
      extends: ['plugin:jest/recommended'],
      env: {
        jest: true,
      },
      rules: {
        '@typescript-eslint/no-explicit-any': 'off',
        'no-console': 'off',
      },
    },
<% } else if (testFramework === 'vitest') { -%>
    {
      files: ['**/*.test.{js,ts,tsx}', '**/*.spec.{js,ts,tsx}'],
      env: {
        node: true,
      },
      globals: {
        describe: 'readonly',
        it: 'readonly',
        expect: 'readonly',
        beforeEach: 'readonly',
        afterEach: 'readonly',
        beforeAll: 'readonly',
        afterAll: 'readonly',
        vi: 'readonly',
      },
      rules: {
        '@typescript-eslint/no-explicit-any': 'off',
        'no-console': 'off',
      },
    },
<% } else if (testFramework === 'bun-test') { -%>
    {
      files: ['**/*.test.{js,ts,tsx}', '**/*.spec.{js,ts,tsx}'],
      env: {
        node: true,
      },
      globals: {
        describe: 'readonly',
        it: 'readonly',
        expect: 'readonly',
        beforeEach: 'readonly',
        afterEach: 'readonly',
        beforeAll: 'readonly',
        afterAll: 'readonly',
        test: 'readonly',
      },
      rules: {
        '@typescript-eslint/no-explicit-any': 'off',
        'no-console': 'off',
      },
    },
<% } -%>
    {
      files: ['**/*.config.{js,mjs,ts}', '**/scripts/**'],
      rules: {
        'import/no-default-export': 'off',
        '@typescript-eslint/no-var-requires': 'off',
      },
    },
    {
      files: ['**/bin/**', '**/cli.{js,ts}'],
      rules: {
        'no-console': 'off',
      },
    },
<% if (preset !== 'minimal') { -%>
    {
      files: ['apps/**/*.{js,ts,tsx}'],
      rules: {
        // Relax rules for application code
        '@typescript-eslint/no-explicit-any': 'off',
      },
    },
<% } -%>
  ],
};