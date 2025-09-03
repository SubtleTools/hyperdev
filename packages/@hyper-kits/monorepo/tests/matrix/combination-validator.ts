/**
 * Tool Combination Validator
 * 
 * This module validates all possible tool combinations and generates
 * comprehensive test matrices for different scenarios and use cases.
 */

import { validateToolCompatibility, isToolCombinationValid, type ValidationResult } from '../../src/validation';
import { presets } from '../../src/presets';
import type { MonorepoConfig } from '../../src';

/**
 * Tool combination matrix
 */
interface ToolMatrix {
  packageManagers: string[];
  linters: string[];
  formatters: string[];
  testFrameworks: string[];
}

/**
 * Validation summary for a combination
 */
interface CombinationValidation {
  combination: Partial<MonorepoConfig>;
  isValid: boolean;
  hasWarnings: boolean;
  errors: string[];
  warnings: string[];
  recommendations: string[];
}

/**
 * Complete validation report
 */
interface ValidationReport {
  timestamp: string;
  totalCombinations: number;
  validCombinations: number;
  invalidCombinations: number;
  combinationsWithWarnings: number;
  validationResults: CombinationValidation[];
  matrix: ToolMatrix;
  presetValidation: Record<string, ValidationResult>;
  recommendations: {
    fastestCombinations: string[];
    mostCompatibleCombinations: string[];
    enterpriseRecommendations: string[];
    performanceRecommendations: string[];
  };
  statistics: {
    byPackageManager: Record<string, number>;
    byLinter: Record<string, number>;
    byFormatter: Record<string, number>;
    byTestFramework: Record<string, number>;
  };
}

/**
 * Tool Combination Validator class
 */
export class CombinationValidator {
  private readonly matrix: ToolMatrix = {
    packageManagers: ['bun', 'npm', 'yarn', 'pnpm'],
    linters: ['eslint', 'biome'],
    formatters: ['prettier', 'dprint', 'biome-integrated'],
    testFrameworks: ['vitest', 'bun-test', 'jest']
  };

  /**
   * Get all possible tool combinations (valid and invalid)
   */
  getAllCombinations(): Array<Partial<MonorepoConfig>> {
    const combinations: Array<Partial<MonorepoConfig>> = [];

    for (const packageManager of this.matrix.packageManagers) {
      for (const linter of this.matrix.linters) {
        for (const formatter of this.matrix.formatters) {
          for (const testFramework of this.matrix.testFrameworks) {
            combinations.push({
              packageManager: packageManager as any,
              linter: linter as any,
              formatter: formatter as any,
              testFramework: testFramework as any
            });
          }
        }
      }
    }

    return combinations;
  }

  /**
   * Get only valid tool combinations
   */
  getValidCombinations(): Array<Partial<MonorepoConfig>> {
    const allCombinations = this.getAllCombinations();
    return allCombinations.filter(combination => 
      isToolCombinationValid(
        combination.packageManager!,
        combination.linter!,
        combination.formatter!,
        combination.testFramework!
      )
    );
  }

  /**
   * Get invalid tool combinations with reasons
   */
  getInvalidCombinations(): CombinationValidation[] {
    const allCombinations = this.getAllCombinations();
    const invalidCombinations: CombinationValidation[] = [];

    for (const combination of allCombinations) {
      const config: MonorepoConfig = {
        name: 'validation-test',
        packageManager: combination.packageManager!,
        linter: combination.linter!,
        formatter: combination.formatter!,
        testFramework: combination.testFramework!
      };

      const validation = validateToolCompatibility(config);
      
      if (!validation.valid) {
        invalidCombinations.push({
          combination,
          isValid: false,
          hasWarnings: validation.issues.some(issue => issue.severity === 'warning'),
          errors: validation.issues
            .filter(issue => issue.severity === 'error')
            .map(issue => issue.message),
          warnings: validation.issues
            .filter(issue => issue.severity === 'warning')
            .map(issue => issue.message),
          recommendations: validation.suggestions || []
        });
      }
    }

    return invalidCombinations;
  }

  /**
   * Validate all combinations and generate comprehensive report
   */
  generateValidationReport(): ValidationReport {
    const allCombinations = this.getAllCombinations();
    const validationResults: CombinationValidation[] = [];

    // Validate each combination
    for (const combination of allCombinations) {
      const config: MonorepoConfig = {
        name: 'validation-test',
        packageManager: combination.packageManager!,
        linter: combination.linter!,
        formatter: combination.formatter!,
        testFramework: combination.testFramework!
      };

      const validation = validateToolCompatibility(config);
      
      validationResults.push({
        combination,
        isValid: validation.valid,
        hasWarnings: validation.issues.some(issue => issue.severity === 'warning'),
        errors: validation.issues
          .filter(issue => issue.severity === 'error')
          .map(issue => issue.message),
        warnings: validation.issues
          .filter(issue => issue.severity === 'warning')
          .map(issue => issue.message),
        recommendations: validation.suggestions || []
      });
    }

    // Validate presets
    const presetValidation: Record<string, ValidationResult> = {};
    for (const [presetName, presetConfig] of Object.entries(presets)) {
      const config: MonorepoConfig = {
        name: `preset-${presetName}`,
        packageManager: presetConfig.packageManager!,
        linter: presetConfig.linter!,
        formatter: presetConfig.formatter!,
        testFramework: presetConfig.testFramework!,
        tools: presetConfig.tools || {}
      };

      presetValidation[presetName] = validateToolCompatibility(config);
    }

    // Generate statistics
    const validResults = validationResults.filter(r => r.isValid);
    const invalidResults = validationResults.filter(r => !r.isValid);
    const warningResults = validationResults.filter(r => r.hasWarnings);

    const statistics = {
      byPackageManager: this.generateStatsByTool(validResults, 'packageManager'),
      byLinter: this.generateStatsByTool(validResults, 'linter'),
      byFormatter: this.generateStatsByTool(validResults, 'formatter'),
      byTestFramework: this.generateStatsByTool(validResults, 'testFramework')
    };

    // Generate recommendations
    const recommendations = this.generateRecommendations(validResults);

    return {
      timestamp: new Date().toISOString(),
      totalCombinations: allCombinations.length,
      validCombinations: validResults.length,
      invalidCombinations: invalidResults.length,
      combinationsWithWarnings: warningResults.length,
      validationResults,
      matrix: this.matrix,
      presetValidation,
      recommendations,
      statistics
    };
  }

  /**
   * Generate statistics by tool type
   */
  private generateStatsByTool(
    validResults: CombinationValidation[],
    toolType: keyof Partial<MonorepoConfig>
  ): Record<string, number> {
    const stats: Record<string, number> = {};

    for (const result of validResults) {
      const toolValue = result.combination[toolType] as string;
      if (toolValue) {
        stats[toolValue] = (stats[toolValue] || 0) + 1;
      }
    }

    return stats;
  }

  /**
   * Generate recommendations based on validation results
   */
  private generateRecommendations(validResults: CombinationValidation[]): {
    fastestCombinations: string[];
    mostCompatibleCombinations: string[];
    enterpriseRecommendations: string[];
    performanceRecommendations: string[];
  } {
    // Fastest combinations (based on tool performance characteristics)
    const fastestCombinations = validResults
      .filter(r => 
        r.combination.packageManager === 'bun' &&
        r.combination.testFramework === 'bun-test' &&
        r.combination.formatter === 'biome-integrated'
      )
      .map(r => this.formatCombination(r.combination))
      .slice(0, 3);

    // Most compatible combinations (fewest warnings)
    const mostCompatibleCombinations = validResults
      .filter(r => r.warnings.length === 0)
      .sort((a, b) => a.warnings.length - b.warnings.length)
      .map(r => this.formatCombination(r.combination))
      .slice(0, 5);

    // Enterprise recommendations
    const enterpriseRecommendations = validResults
      .filter(r => 
        (r.combination.packageManager === 'pnpm' || r.combination.packageManager === 'yarn') &&
        r.combination.linter === 'eslint' &&
        r.combination.formatter === 'prettier' &&
        (r.combination.testFramework === 'vitest' || r.combination.testFramework === 'jest')
      )
      .map(r => this.formatCombination(r.combination))
      .slice(0, 3);

    // Performance recommendations
    const performanceRecommendations = validResults
      .filter(r => 
        r.combination.packageManager === 'bun' &&
        r.combination.linter === 'biome' &&
        (r.combination.testFramework === 'bun-test' || r.combination.testFramework === 'vitest')
      )
      .map(r => this.formatCombination(r.combination))
      .slice(0, 3);

    return {
      fastestCombinations,
      mostCompatibleCombinations,
      enterpriseRecommendations,
      performanceRecommendations
    };
  }

  /**
   * Format combination as readable string
   */
  private formatCombination(combination: Partial<MonorepoConfig>): string {
    return `${combination.packageManager}+${combination.linter}+${combination.formatter}+${combination.testFramework}`;
  }

  /**
   * Get combinations by specific criteria
   */
  getCombinationsByPackageManager(packageManager: string): Array<Partial<MonorepoConfig>> {
    return this.getValidCombinations().filter(c => c.packageManager === packageManager);
  }

  getCombinationsByLinter(linter: string): Array<Partial<MonorepoConfig>> {
    return this.getValidCombinations().filter(c => c.linter === linter);
  }

  getCombinationsByFormatter(formatter: string): Array<Partial<MonorepoConfig>> {
    return this.getValidCombinations().filter(c => c.formatter === formatter);
  }

  getCombinationsByTestFramework(testFramework: string): Array<Partial<MonorepoConfig>> {
    return this.getValidCombinations().filter(c => c.testFramework === testFramework);
  }

  /**
   * Get fast combinations (optimized for performance)
   */
  getFastCombinations(): Array<Partial<MonorepoConfig>> {
    return this.getValidCombinations().filter(combination => {
      // Prioritize fast tools
      return combination.packageManager === 'bun' ||
             combination.linter === 'biome' ||
             combination.testFramework === 'bun-test';
    });
  }

  /**
   * Get enterprise-ready combinations (stable, mature tools)
   */
  getEnterpriseCombinations(): Array<Partial<MonorepoConfig>> {
    return this.getValidCombinations().filter(combination => {
      // Prioritize mature, stable tools
      return (combination.packageManager === 'npm' || 
              combination.packageManager === 'yarn' || 
              combination.packageManager === 'pnpm') &&
             combination.linter === 'eslint' &&
             combination.formatter === 'prettier' &&
             (combination.testFramework === 'jest' || combination.testFramework === 'vitest');
    });
  }

  /**
   * Get minimal combinations (fewer dependencies)
   */
  getMinimalCombinations(): Array<Partial<MonorepoConfig>> {
    return this.getValidCombinations().filter(combination => {
      // Prioritize tools that provide multiple capabilities
      return combination.linter === 'biome' &&
             combination.formatter === 'biome-integrated';
    });
  }

  /**
   * Export validation report as JSON
   */
  async exportValidationReport(outputPath: string): Promise<void> {
    const fs = await import('fs/promises');
    const path = await import('path');
    
    const report = this.generateValidationReport();
    
    // Create output directory if it doesn't exist
    await fs.mkdir(path.dirname(outputPath), { recursive: true });
    
    // Write JSON report
    await fs.writeFile(
      outputPath,
      JSON.stringify(report, null, 2),
      'utf-8'
    );

    // Write human-readable markdown report
    const mdReport = this.formatMarkdownReport(report);
    const mdPath = outputPath.replace(/\.json$/, '.md');
    await fs.writeFile(mdPath, mdReport, 'utf-8');
  }

  /**
   * Format validation report as markdown
   */
  private formatMarkdownReport(report: ValidationReport): string {
    const lines = [];
    
    lines.push('# Tool Combination Validation Report');
    lines.push('');
    lines.push(`**Generated:** ${report.timestamp}`);
    lines.push(`**Total Combinations:** ${report.totalCombinations}`);
    lines.push(`**Valid Combinations:** ${report.validCombinations}`);
    lines.push(`**Invalid Combinations:** ${report.invalidCombinations}`);
    lines.push(`**Success Rate:** ${((report.validCombinations / report.totalCombinations) * 100).toFixed(1)}%`);
    lines.push('');

    // Tool Matrix
    lines.push('## Tool Matrix');
    lines.push(`- **Package Managers:** ${report.matrix.packageManagers.join(', ')}`);
    lines.push(`- **Linters:** ${report.matrix.linters.join(', ')}`);
    lines.push(`- **Formatters:** ${report.matrix.formatters.join(', ')}`);
    lines.push(`- **Test Frameworks:** ${report.matrix.testFrameworks.join(', ')}`);
    lines.push('');

    // Statistics
    lines.push('## Statistics');
    lines.push('### Valid Combinations by Tool');
    
    lines.push('#### Package Managers');
    Object.entries(report.statistics.byPackageManager).forEach(([tool, count]) => {
      lines.push(`- **${tool}:** ${count} combinations`);
    });
    lines.push('');

    lines.push('#### Linters');
    Object.entries(report.statistics.byLinter).forEach(([tool, count]) => {
      lines.push(`- **${tool}:** ${count} combinations`);
    });
    lines.push('');

    lines.push('#### Formatters');
    Object.entries(report.statistics.byFormatter).forEach(([tool, count]) => {
      lines.push(`- **${tool}:** ${count} combinations`);
    });
    lines.push('');

    lines.push('#### Test Frameworks');
    Object.entries(report.statistics.byTestFramework).forEach(([tool, count]) => {
      lines.push(`- **${tool}:** ${count} combinations`);
    });
    lines.push('');

    // Preset Validation
    lines.push('## Preset Validation');
    Object.entries(report.presetValidation).forEach(([preset, validation]) => {
      const status = validation.valid ? '✅ Valid' : '❌ Invalid';
      lines.push(`- **${preset}:** ${status}`);
      
      if (!validation.valid) {
        validation.issues
          .filter(issue => issue.severity === 'error')
          .forEach(issue => lines.push(`  - Error: ${issue.message}`));
      }
      
      if (validation.issues.some(issue => issue.severity === 'warning')) {
        validation.issues
          .filter(issue => issue.severity === 'warning')
          .forEach(issue => lines.push(`  - Warning: ${issue.message}`));
      }
    });
    lines.push('');

    // Recommendations
    lines.push('## Recommendations');
    
    if (report.recommendations.fastestCombinations.length > 0) {
      lines.push('### Fastest Combinations');
      report.recommendations.fastestCombinations.forEach(combo => {
        lines.push(`- \`${combo}\``);
      });
      lines.push('');
    }

    if (report.recommendations.mostCompatibleCombinations.length > 0) {
      lines.push('### Most Compatible Combinations');
      report.recommendations.mostCompatibleCombinations.forEach(combo => {
        lines.push(`- \`${combo}\``);
      });
      lines.push('');
    }

    if (report.recommendations.enterpriseRecommendations.length > 0) {
      lines.push('### Enterprise Recommendations');
      report.recommendations.enterpriseRecommendations.forEach(combo => {
        lines.push(`- \`${combo}\``);
      });
      lines.push('');
    }

    if (report.recommendations.performanceRecommendations.length > 0) {
      lines.push('### Performance Recommendations');
      report.recommendations.performanceRecommendations.forEach(combo => {
        lines.push(`- \`${combo}\``);
      });
      lines.push('');
    }

    // Invalid Combinations
    const invalidResults = report.validationResults.filter(r => !r.isValid);
    if (invalidResults.length > 0) {
      lines.push('## Invalid Combinations');
      lines.push('| Combination | Errors |');
      lines.push('|-------------|--------|');
      
      invalidResults.forEach(result => {
        const combo = this.formatCombination(result.combination);
        const errors = result.errors.join(', ');
        lines.push(`| \`${combo}\` | ${errors} |`);
      });
      lines.push('');
    }

    // Valid Combinations with Warnings
    const warningResults = report.validationResults.filter(r => r.isValid && r.hasWarnings);
    if (warningResults.length > 0) {
      lines.push('## Valid Combinations with Warnings');
      lines.push('| Combination | Warnings |');
      lines.push('|-------------|----------|');
      
      warningResults.forEach(result => {
        const combo = this.formatCombination(result.combination);
        const warnings = result.warnings.join(', ');
        lines.push(`| \`${combo}\` | ${warnings} |`);
      });
    }

    return lines.join('\n');
  }
}

// Export standalone functions for easy use
export function getAllToolCombinations(): Array<Partial<MonorepoConfig>> {
  const validator = new CombinationValidator();
  return validator.getAllCombinations();
}

export function getValidToolCombinations(): Array<Partial<MonorepoConfig>> {
  const validator = new CombinationValidator();
  return validator.getValidCombinations();
}

export function getInvalidToolCombinations(): CombinationValidation[] {
  const validator = new CombinationValidator();
  return validator.getInvalidCombinations();
}

export function generateToolValidationReport(): ValidationReport {
  const validator = new CombinationValidator();
  return validator.generateValidationReport();
}

// CLI support for standalone validation
if (require.main === module) {
  const validator = new CombinationValidator();
  const report = validator.generateValidationReport();
  
  console.log('🔍 Tool Combination Validation Report');
  console.log(`📊 Total combinations: ${report.totalCombinations}`);
  console.log(`✅ Valid combinations: ${report.validCombinations}`);
  console.log(`❌ Invalid combinations: ${report.invalidCombinations}`);
  console.log(`⚠️  Combinations with warnings: ${report.combinationsWithWarnings}`);
  console.log(`📈 Success rate: ${((report.validCombinations / report.totalCombinations) * 100).toFixed(1)}%`);

  // Export report if output path provided
  const outputPath = process.argv[2];
  if (outputPath) {
    validator.exportValidationReport(outputPath).then(() => {
      console.log(`📋 Report exported to: ${outputPath}`);
    }).catch(error => {
      console.error('❌ Failed to export report:', error);
      process.exit(1);
    });
  }
}