/**
 * Hypergen Package Configuration
 * 
 * This configuration enables the monorepo template pack to be discovered
 * and used by the Hypergen CLI system.
 */

module.exports = {
  // Package identification
  name: '@hypergen/monorepo-pack',
  version: require('./package.json').version,
  description: 'Hypergen template package for creating Moon-based TypeScript monorepos with configurable tooling',
  
  // Template discovery configuration
  templates: {
    // Template directories to scan
    directories: ['_templates'],
    
    // Base template configuration
    defaults: {
      engine: 'ejs',
      targetFormat: 'ejs.t'
    }
  },
  
  // CLI integration
  cli: {
    // Main command integration
    commands: {
      // Primary command: hypergen monorepo new <name>
      'monorepo': {
        description: 'Generate Moon-based TypeScript monorepos',
        defaultAction: 'new',
        template: 'hypergen-monorepo',
        examples: [
          {
            title: 'Create modern Bun monorepo',
            command: 'hypergen monorepo new my-project --preset=modern-bun'
          },
          {
            title: 'Create enterprise monorepo',
            command: 'hypergen monorepo new enterprise-app --preset=enterprise --includeGitHubActions=true'
          },
          {
            title: 'Create custom monorepo',
            command: 'hypergen monorepo new custom-project --packageManager=yarn --testFramework=vitest'
          }
        ]
      }
    },
    
    // Action mappings for direct usage
    actions: {
      'monorepo-new': {
        template: 'hypergen-monorepo',
        action: 'new',
        description: 'Generate a new Moon-based TypeScript monorepo'
      }
    },
    
    // Parameter mappings and validation
    parameters: {
      // Global parameter defaults
      defaults: {
        packageManager: 'bun',
        testFramework: 'vitest',
        linter: 'eslint',
        formatter: 'prettier',
        initializeGit: true,
        setupGitHooks: true,
        includeVSCodeSettings: true,
        includeDocumentation: true
      },
      
      // Parameter aliases for compatibility
      aliases: {
        'pm': 'packageManager',
        'pkg-manager': 'packageManager',
        'test': 'testFramework',
        'tests': 'testFramework',
        'git': 'initializeGit',
        'hooks': 'setupGitHooks',
        'vscode': 'includeVSCodeSettings',
        'docs': 'includeDocumentation'
      },
      
      // Parameter validation rules
      validation: {
        name: {
          required: true,
          pattern: '^[a-zA-Z][a-zA-Z0-9-_]*$',
          message: 'Project name must be alphanumeric with hyphens and underscores, starting with a letter'
        },
        packageManager: {
          enum: ['bun', 'npm', 'yarn', 'pnpm'],
          message: 'Package manager must be one of: bun, npm, yarn, pnpm'
        },
        preset: {
          enum: ['custom', 'modern-bun', 'traditional-node', 'performance', 'enterprise', 'minimal'],
          message: 'Preset must be one of: custom, modern-bun, traditional-node, performance, enterprise, minimal'
        }
      }
    }
  },
  
  // Trust and security configuration
  trust: {
    // Package is published and signed
    verified: true,
    publisher: '@hypergen',
    signature: process.env.HYPERGEN_PACKAGE_SIGNATURE || 'trusted-package'
  },
  
  // Discovery metadata
  discovery: {
    // Keywords for template discovery
    keywords: [
      'monorepo', 'moon', 'typescript', 'build-system', 
      'workspace', 'tooling', 'multi-package', 'modern'
    ],
    
    // Category classification
    category: 'project-structure',
    
    // Template maturity level
    maturity: 'stable',
    
    // Compatibility information
    compatibility: {
      hypergen: '>=8.0.0',
      node: '>=16.0.0',
      moon: '>=1.0.0'
    }
  },
  
  // Integration hooks
  hooks: {
    // Pre-generation validation
    preGenerate: async (context) => {
      // Validate Moon CLI availability
      try {
        const { execSync } = require('child_process');
        execSync('moon --version', { stdio: 'ignore' });
        return { success: true };
      } catch (error) {
        return {
          success: false,
          message: 'Moon CLI is required but not installed. Please install: npm install -g @moonrepo/cli'
        };
      }
    },
    
    // Post-generation setup
    postGenerate: async (context, result) => {
      if (result.success) {
        console.log(`\n🎉 ${context.name} monorepo created successfully!`);
        console.log('\n📖 Quick Start:');
        console.log(`   cd ${context.name}`);
        console.log('   moon sync           # Sync workspace');
        console.log('   moon run :build     # Build all packages');
        console.log('   moon run :test      # Run all tests');
        console.log('\n📚 Documentation: https://moonrepo.dev/docs');
        
        return { success: true };
      }
      return result;
    }
  },
  
  // Performance optimization
  performance: {
    // Enable caching for template resolution
    cache: true,
    
    // Parallel processing for file operations
    parallelFiles: true,
    
    // Template compilation caching
    compileCache: true
  },
  
  // Development and testing
  development: {
    // Enable debug mode
    debug: process.env.NODE_ENV === 'development',
    
    // Test configuration
    testing: {
      // Test matrices for validation
      matrices: ['preset-combinations', 'tool-compatibility'],
      
      // Performance benchmarks
      benchmarks: ['generation-time', 'file-count', 'template-resolution']
    }
  }
};