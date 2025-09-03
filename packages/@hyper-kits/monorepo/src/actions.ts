/**
 * Hypergen V8 Actions for monorepo template generation
 * 
 * Integrates with the template composition system to provide
 * comprehensive template generation with conditional logic.
 */

import type { TemplateContext, MonorepoConfig } from './index';
import { 
  validateToolCompatibility, 
  ValidationIssue, 
  validateMonorepoConfigComplete,
  validateSystemRequirements,
  // validateProjectDirectory, // Not used yet
  validatePackageManager
} from './validation';
import { composeTemplate, type CompositionResult } from './composition';
import { presets, type PresetName } from './presets';
import { 
  errorHandler, 
  HypergenError, 
  ErrorCode, 
  ErrorSeverity,
  createValidationError,
  createToolCompatibilityError,
  // createFileSystemError, // Not used yet
  createDependencyError,
  withErrorHandling
} from './errors';
import { 
  performanceOptimizer, 
  performanceMonitor, 
  // type PerformanceMetrics  // Not used in this file
} from './performance';

/**
 * Global composition result for sharing between actions
 */
let globalCompositionResult: CompositionResult | null = null;

/**
 * Main template generation action with performance optimization
 * Orchestrates the entire template composition process with <30s target
 */
export async function generateTemplate(context: TemplateContext): Promise<CompositionResult> {
  return await withErrorHandling(async () => {
    console.log(`🚀 Starting optimized template generation for: ${context.name}`);
    const startTime = Date.now();

    try {
      // Initialize performance optimizer
      await performanceOptimizer.initialize();

      // Use optimized composition
      const optimizedResult = await performanceOptimizer.composeOptimized(context);
      
      if (!optimizedResult.success) {
        throw new HypergenError(
          ErrorCode.COMPOSITION_FAILED,
          'Optimized template composition failed',
          {
            severity: ErrorSeverity.ERROR,
            recoverable: true
          }
        );
      }

      // Track performance metrics
      performanceMonitor.addMetrics(optimizedResult.metrics);

      // Fallback to standard composition if needed
      const compositionResult = globalCompositionResult || await composeTemplate(context);
      globalCompositionResult = compositionResult;

      const duration = Date.now() - startTime;
      const meetsTarget = duration < 30000; // 30 seconds

      // Log performance results
      console.log(`📦 Template composition complete in ${duration}ms:`);
      console.log(`   • ${compositionResult.includedFiles.length} files will be generated`);
      console.log(`   • ${compositionResult.excludedFiles.length} files will be skipped`);
      console.log(`   ⚡ Performance: ${meetsTarget ? '✅ Meets <30s target' : '⚠️  Exceeds target'}`);
      
      // Log cache performance
      const cacheStats = optimizedResult.cacheStats;
      if (cacheStats.hits > 0 || cacheStats.misses > 0) {
        console.log(`   🎯 Cache hit rate: ${(cacheStats.hitRate * 100).toFixed(1)}%`);
        console.log(`   💾 Cache memory: ${cacheStats.memoryUsageMB}MB / ${cacheStats.maxMemoryMB}MB`);
      }

      // Performance recommendations if target not met
      if (!meetsTarget) {
        const analysis = performanceMonitor.analyzePerformance();
        if (analysis.recommendations.length > 0) {
          console.warn('\n💡 Performance recommendations:');
          analysis.recommendations.forEach(rec => console.warn(`   • ${rec}`));
        }
      }
      
      if (compositionResult.warnings.length > 0) {
        console.warn(`\n⚠️  ${compositionResult.warnings.length} composition warnings:`);
        compositionResult.warnings.forEach(warning => console.warn(`   • ${warning}`));
      }

      if (compositionResult.errors.length > 0) {
        console.error(`\n❌ ${compositionResult.errors.length} composition errors:`);
        compositionResult.errors.forEach(error => console.error(`   • ${error}`));
        throw new HypergenError(
          ErrorCode.COMPOSITION_FAILED,
          'Template composition failed with errors',
          {
            severity: ErrorSeverity.ERROR,
            context: { errors: compositionResult.errors }
          }
        );
      }

      return compositionResult;
      
    } finally {
      // Cleanup performance systems
      await performanceOptimizer.cleanup();
    }
  }, 'template_generation');
}

/**
 * Pre-generation validation action
 * Validates configuration and applies presets with comprehensive error handling
 */
export async function preValidation(context: TemplateContext): Promise<void> {
  return await withErrorHandling(async () => {
    console.log('🔍 Validating template configuration...');
    
    // Step 1: Validate system requirements
    const systemValidation = validateSystemRequirements();
    if (!systemValidation.valid) {
      throw new HypergenError(
        ErrorCode.DEPENDENCY_RESOLUTION_ERROR,
        `Missing system requirements: ${systemValidation.missing.join(', ')}`,
        {
          severity: ErrorSeverity.ERROR,
          suggestions: [
            {
              action: 'install_requirements',
              description: 'Install missing system dependencies',
              command: systemValidation.missing.includes('git') ? 'Install git from https://git-scm.com/' : 'Install Node.js from https://nodejs.org/'
            }
          ],
          recoverable: false
        }
      );
    }

    // Log system warnings
    if (systemValidation.warnings.length > 0) {
      console.warn('⚠️  System warnings:');
      systemValidation.warnings.forEach(warning => console.warn(`   • ${warning}`));
    }

    // Step 2: Comprehensive input validation
    const configValidation = validateMonorepoConfigComplete(context as Partial<MonorepoConfig>);
    if (!configValidation.valid) {
      const errors = configValidation.issues
        .filter(issue => issue.severity === 'error')
        .map(issue => createValidationError(issue.message, issue.affectedTools[0], context[issue.affectedTools[0] as keyof TemplateContext]));
      
      errorHandler.handleValidationErrors(errors);
      return; // This will exit the process
    }

    // Step 3: Apply default package manager if not specified
    if (!context.packageManager) {
      console.log('📦 No package manager specified, defaulting to bun');
      context.packageManager = 'bun'; // Default to bun per user preference
    }

    // Step 4: Validate package manager availability
    const pmValidation = await validatePackageManager(context.packageManager);
    if (!pmValidation.available) {
      const fallbackError = createDependencyError(context.packageManager, 'template generation');
      const fallbackPM = await errorHandler.handleError(fallbackError, 'package_manager_validation');
      if (fallbackPM) {
        context.packageManager = fallbackPM as 'bun' | 'npm' | 'yarn' | 'pnpm';
        console.log(`✅ Using fallback package manager: ${context.packageManager}`);
      } else {
        // Critical error - cannot proceed without package manager
        throw new HypergenError(
          ErrorCode.PACKAGE_MANAGER_NOT_FOUND,
          `No suitable package manager found`,
          {
            severity: ErrorSeverity.FATAL,
            suggestions: [
              {
                action: 'install_bun',
                description: 'Install Bun (recommended)',
                command: 'curl -fsSL https://bun.sh/install | bash'
              },
              {
                action: 'install_node',
                description: 'Install Node.js and npm',
                url: 'https://nodejs.org/'
              }
            ]
          }
        );
      }
    } else if (pmValidation.issues.length > 0) {
      console.warn('⚠️  Package manager warnings:');
      pmValidation.issues.forEach(issue => console.warn(`   • ${issue}`));
    }

    // Step 5: Apply preset if specified
    const config = context as MonorepoConfig;
    const presetName = (config as any).preset as PresetName | 'custom';
    
    if (presetName && presetName !== 'custom') {
      console.log(`🎯 Applying preset: ${presetName}`);
      try {
        await applyPreset(context, presetName);
      } catch (error) {
        throw new HypergenError(
          ErrorCode.PRESET_NOT_FOUND,
          `Failed to apply preset: ${presetName}`,
          {
            severity: ErrorSeverity.ERROR,
            cause: error as Error,
            suggestions: [
              {
                action: 'use_default',
                description: 'Use default configuration instead',
                automated: true
              },
              {
                action: 'list_presets',
                description: `Available presets: ${Object.keys(presets).join(', ')}`
              }
            ],
            recoverable: true
          }
        );
      }
    }
    
    // Step 6: Final validation of complete configuration
    const finalValidation = validateToolCompatibility(context);
    
    // Handle validation errors with enhanced error messages
    const errors = finalValidation.issues.filter(issue => issue.severity === 'error');
    if (errors.length > 0) {
      const validationErrors = errors.map(error => 
        createToolCompatibilityError(
          error.affectedTools,
          // Suggest a valid combination
          {
            packageManager: 'bun',
            linter: 'eslint',
            formatter: 'prettier', 
            testFramework: 'vitest'
          }
        )
      );
      
      errorHandler.handleValidationErrors(validationErrors);
      return; // This will exit the process
    }
    
    // Log warnings and info with enhanced formatting
    logValidationIssues(finalValidation.issues);
    
    // Step 7: Set computed properties
    setComputedProperties(context);
    
    console.log('✅ Configuration validation complete');

  }, 'pre_validation');
}

/**
 * Apply preset configuration to context
 */
export async function applyPreset(context: TemplateContext, presetName: PresetName): Promise<void> {
  if (!presets[presetName]) {
    throw new Error(`Unknown preset: ${presetName}. Available presets: ${Object.keys(presets).join(', ')}`);
  }

  const preset = presets[presetName];
  
  // Apply preset values to context
  Object.assign(context, preset);
  
  console.log(`🎯 Applied preset "${presetName}":`, {
    packageManager: context.packageManager,
    linter: context.linter,
    formatter: context.formatter,
    testFramework: context.testFramework
  });
}

/**
 * File filtering action
 * Determines which template files should be included
 */
export async function filterTemplateFiles(context: TemplateContext): Promise<string[]> {
  console.log('📂 Filtering template files...');
  
  if (!globalCompositionResult) {
    // Fallback composition if not already done
    globalCompositionResult = await composeTemplate(context);
  }

  console.log(`📂 File filtering complete: ${globalCompositionResult.includedFiles.length} files selected`);
  
  // Return list of files to include
  return globalCompositionResult.includedFiles;
}

/**
 * Context preparation action
 * Prepares template context with all computed properties
 */
export async function prepareContext(context: TemplateContext): Promise<void> {
  console.log('⚙️  Preparing template context...');
  
  // Ensure computed properties are set
  setComputedProperties(context);
  
  // Add additional computed properties for template rendering
  const extendedContext = context as any;
  
  // Tool-specific configurations
  extendedContext.eslintConfig = context.linter === 'eslint';
  extendedContext.biomeConfig = context.linter === 'biome';
  extendedContext.prettierConfig = context.formatter === 'prettier';
  extendedContext.dprintConfig = context.formatter === 'dprint';
  extendedContext.biomeFormatter = context.formatter === 'biome-integrated';
  extendedContext.vitestConfig = context.testFramework === 'vitest';
  extendedContext.jestConfig = context.testFramework === 'jest';
  extendedContext.bunTestConfig = context.testFramework === 'bun-test';
  
  // Package manager specific properties
  extendedContext.useBun = context.packageManager === 'bun';
  extendedContext.useNpm = context.packageManager === 'npm';
  extendedContext.useYarn = context.packageManager === 'yarn';
  extendedContext.usePnpm = context.packageManager === 'pnpm';
  
  // Tool combination properties for complex conditions
  extendedContext.bunWithBunTest = context.packageManager === 'bun' && context.testFramework === 'bun-test';
  extendedContext.biomeIntegrated = context.linter === 'biome' && context.formatter === 'biome-integrated';
  extendedContext.eslintPrettier = context.linter === 'eslint' && context.formatter === 'prettier';
  
  console.log('✅ Template context prepared');
}

/**
 * Post-generation setup action
 * Handles post-generation setup and installation
 */
export async function postGeneration(context: TemplateContext): Promise<void> {
  console.log('🔧 Running post-generation setup...');
  
  if (!globalCompositionResult) {
    console.warn('No composition result available for post-generation actions');
    return;
  }

  // Execute post-generation actions from composition
  const postActions = globalCompositionResult.actions.filter(action => action.timing === 'post');
  
  for (const action of postActions) {
    console.log(`🔧 Executing: ${action.description}`);
    try {
      await action.execute(context);
    } catch (error) {
      console.warn(`⚠️  Action "${action.name}" failed:`, error instanceof Error ? error.message : error);
    }
  }

  // Log generation summary
  logGenerationSummary(context, globalCompositionResult);
  
  console.log('✅ Post-generation setup complete');
}

/**
 * Validate specific tool combination
 */
export async function validateToolCombination(
  packageManager: string,
  linter: string, 
  formatter: string,
  testFramework: string
): Promise<boolean> {
  const tempConfig: MonorepoConfig = {
    name: 'validation-test',
    packageManager: packageManager as any,
    linter: linter as any,
    formatter: formatter as any,
    testFramework: testFramework as any
  };

  const validation = validateToolCompatibility(tempConfig);
  return validation.valid;
}

/**
 * Get available tool combinations
 */
export async function getCompatibleCombinations(): Promise<Array<Partial<MonorepoConfig>>> {
  const packageManagers = ['bun', 'npm', 'yarn', 'pnpm'];
  const linters = ['eslint', 'biome'];
  const formatters = ['prettier', 'dprint', 'biome-integrated'];
  const testFrameworks = ['vitest', 'bun-test', 'jest'];

  const validCombinations: Array<Partial<MonorepoConfig>> = [];

  for (const packageManager of packageManagers) {
    for (const linter of linters) {
      for (const formatter of formatters) {
        for (const testFramework of testFrameworks) {
          const isValid = await validateToolCombination(packageManager, linter, formatter, testFramework);
          if (isValid) {
            validCombinations.push({
              packageManager: packageManager as any,
              linter: linter as any,
              formatter: formatter as any,
              testFramework: testFramework as any
            });
          }
        }
      }
    }
  }

  return validCombinations;
}

/**
 * Legacy validation function for backward compatibility
 */
export async function validateConfig(context: TemplateContext): Promise<void> {
  return preValidation(context);
}

// Helper functions

function setComputedProperties(context: TemplateContext): void {
  context.computed = {
    hasLinting: Boolean(context.linter),
    hasFormatting: Boolean(context.formatter),
    hasTesting: Boolean(context.testFramework),
    packageManagerInstallCommand: getInstallCommand(context.packageManager),
    packageManagerRunCommand: getRunCommand(context.packageManager),
  };
}

function logValidationIssues(issues: ValidationIssue[]): void {
  const warnings = issues.filter(issue => issue.severity === 'warning');
  const info = issues.filter(issue => issue.severity === 'info');
  
  if (warnings.length > 0) {
    console.warn('⚠️  Tool compatibility warnings:');
    warnings.forEach(warning => {
      console.warn(`   • ${warning.message}${warning.fix ? ` - ${warning.fix}` : ''}`);
    });
  }
  
  if (info.length > 0) {
    console.info('ℹ️  Tool compatibility notes:');
    info.forEach(note => {
      console.info(`   • ${note.message}${note.fix ? ` - ${note.fix}` : ''}`);
    });
  }
}

function logGenerationSummary(context: TemplateContext, result: CompositionResult): void {
  console.log('\n🎉 Template generation summary:');
  console.log(`   📁 Project: ${context.name}`);
  console.log(`   📦 Package Manager: ${context.packageManager}`);
  console.log(`   🔍 Linter: ${context.linter}`);
  console.log(`   ✨ Formatter: ${context.formatter}`);
  console.log(`   🧪 Test Framework: ${context.testFramework}`);
  console.log(`   📄 Files Generated: ${result.includedFiles.length}`);
  console.log(`   📄 Files Skipped: ${result.excludedFiles.length}`);
  
  if (result.actions.length > 0) {
    console.log(`   🔧 Actions Executed: ${result.actions.length}`);
  }
  
  console.log('\n📋 Next steps:');
  console.log(`   1. cd ${context.name}`);
  console.log(`   2. ${context.computed.packageManagerInstallCommand}`);
  console.log(`   3. ${context.computed.packageManagerRunCommand} dev`);
}

function getInstallCommand(packageManager: string): string {
  switch (packageManager) {
    case 'bun': return 'bun install';
    case 'npm': return 'npm install';
    case 'yarn': return 'yarn install';
    case 'pnpm': return 'pnpm install';
    default: return 'bun install';
  }
}

function getRunCommand(packageManager: string): string {
  switch (packageManager) {
    case 'bun': return 'bun run';
    case 'npm': return 'npm run';
    case 'yarn': return 'yarn';
    case 'pnpm': return 'pnpm run';
    default: return 'bun run';
  }
}