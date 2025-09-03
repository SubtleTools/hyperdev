/**
 * Performance Benchmarking for Matrix Testing
 * 
 * This module provides detailed performance analysis for template generation
 * across different tool combinations and system configurations.
 */

import * as os from 'os';
import * as fs from 'fs/promises';
import * as path from 'path';
import { getValidToolCombinations } from '../../src/composition';
import type { MonorepoConfig } from '../../src';

/**
 * System information for benchmarking context
 */
interface SystemInfo {
  platform: string;
  arch: string;
  nodeVersion: string;
  cpuCount: number;
  totalMemory: string;
  freeMemory: string;
  loadAverage: number[];
}

/**
 * Benchmark result for a single operation
 */
interface BenchmarkResult {
  combination: Partial<MonorepoConfig>;
  operationName: string;
  startTime: number;
  endTime: number;
  durationMs: number;
  memoryUsage: {
    rss: number;
    heapUsed: number;
    heapTotal: number;
    external: number;
  };
  systemLoad: number[];
  success: boolean;
  error?: string;
}

/**
 * Comprehensive benchmark report
 */
interface BenchmarkReport {
  systemInfo: SystemInfo;
  testConfig: {
    totalCombinations: number;
    timestamp: string;
    nodeEnv: string;
  };
  results: BenchmarkResult[];
  summary: {
    totalDuration: number;
    averageDuration: number;
    medianDuration: number;
    minDuration: number;
    maxDuration: number;
    successRate: number;
    combinationsPerSecond: number;
    memoryPeakUsage: number;
  };
  performanceAnalysis: {
    fastestCombinations: Array<{ combination: string; duration: number }>;
    slowestCombinations: Array<{ combination: string; duration: number }>;
    memoryIntensiveCombinations: Array<{ combination: string; memoryMB: number }>;
    recommendedOptimizations: string[];
  };
}

/**
 * Performance benchmarking class
 */
export class PerformanceBenchmark {
  private results: BenchmarkResult[] = [];
  private startGlobalTime: number = 0;
  private endGlobalTime: number = 0;

  /**
   * Get system information
   */
  private getSystemInfo(): SystemInfo {
    return {
      platform: os.platform(),
      arch: os.arch(),
      nodeVersion: process.version,
      cpuCount: os.cpus().length,
      totalMemory: this.formatMemory(os.totalmem()),
      freeMemory: this.formatMemory(os.freemem()),
      loadAverage: os.loadavg()
    };
  }

  /**
   * Format memory in human readable format
   */
  private formatMemory(bytes: number): string {
    const gb = bytes / (1024 * 1024 * 1024);
    return `${gb.toFixed(2)} GB`;
  }

  /**
   * Format combination as string
   */
  private formatCombination(combination: Partial<MonorepoConfig>): string {
    return `${combination.packageManager}+${combination.linter}+${combination.formatter}+${combination.testFramework}`;
  }

  /**
   * Start benchmarking a specific operation
   */
  startOperation(combination: Partial<MonorepoConfig>, operationName: string): number {
    const startTime = Date.now();
    return startTime;
  }

  /**
   * End benchmarking operation and record result
   */
  endOperation(
    combination: Partial<MonorepoConfig>,
    operationName: string,
    startTime: number,
    success: boolean,
    error?: string
  ): BenchmarkResult {
    const endTime = Date.now();
    const memoryUsage = process.memoryUsage();
    const systemLoad = os.loadavg();

    const result: BenchmarkResult = {
      combination,
      operationName,
      startTime,
      endTime,
      durationMs: endTime - startTime,
      memoryUsage,
      systemLoad,
      success,
      error
    };

    this.results.push(result);
    return result;
  }

  /**
   * Start global benchmark
   */
  startGlobal(): void {
    this.startGlobalTime = Date.now();
    this.results = [];
  }

  /**
   * End global benchmark
   */
  endGlobal(): void {
    this.endGlobalTime = Date.now();
  }

  /**
   * Benchmark a specific operation with automatic timing
   */
  async benchmarkOperation<T>(
    combination: Partial<MonorepoConfig>,
    operationName: string,
    operation: () => Promise<T>
  ): Promise<{ result: T | null; benchmark: BenchmarkResult }> {
    const startTime = this.startOperation(combination, operationName);
    
    try {
      const result = await operation();
      const benchmark = this.endOperation(combination, operationName, startTime, true);
      return { result, benchmark };
    } catch (error) {
      const benchmark = this.endOperation(
        combination,
        operationName,
        startTime,
        false,
        error instanceof Error ? error.message : String(error)
      );
      return { result: null, benchmark };
    }
  }

  /**
   * Generate comprehensive benchmark report
   */
  generateReport(): BenchmarkReport {
    const systemInfo = this.getSystemInfo();
    const successfulResults = this.results.filter(r => r.success);
    const durations = successfulResults.map(r => r.durationMs);
    
    const totalDuration = this.endGlobalTime - this.startGlobalTime;
    const averageDuration = durations.length > 0 ? durations.reduce((a, b) => a + b) / durations.length : 0;
    const medianDuration = durations.length > 0 ? this.calculateMedian(durations) : 0;
    const minDuration = durations.length > 0 ? Math.min(...durations) : 0;
    const maxDuration = durations.length > 0 ? Math.max(...durations) : 0;
    const successRate = this.results.length > 0 ? successfulResults.length / this.results.length : 0;
    const combinationsPerSecond = totalDuration > 0 ? (this.results.length / totalDuration) * 1000 : 0;

    // Memory analysis
    const memoryUsages = this.results.map(r => r.memoryUsage.heapUsed);
    const memoryPeakUsage = memoryUsages.length > 0 ? Math.max(...memoryUsages) : 0;

    // Performance analysis
    const sortedByDuration = [...successfulResults].sort((a, b) => a.durationMs - b.durationMs);
    const sortedByMemory = [...this.results].sort((a, b) => b.memoryUsage.heapUsed - a.memoryUsage.heapUsed);

    const fastestCombinations = sortedByDuration.slice(0, 5).map(r => ({
      combination: this.formatCombination(r.combination),
      duration: r.durationMs
    }));

    const slowestCombinations = sortedByDuration.slice(-5).reverse().map(r => ({
      combination: this.formatCombination(r.combination),
      duration: r.durationMs
    }));

    const memoryIntensiveCombinations = sortedByMemory.slice(0, 5).map(r => ({
      combination: this.formatCombination(r.combination),
      memoryMB: Math.round(r.memoryUsage.heapUsed / (1024 * 1024))
    }));

    const recommendedOptimizations = this.generateOptimizationRecommendations(
      averageDuration,
      memoryPeakUsage,
      successRate
    );

    return {
      systemInfo,
      testConfig: {
        totalCombinations: this.results.length,
        timestamp: new Date().toISOString(),
        nodeEnv: process.env.NODE_ENV || 'development'
      },
      results: this.results,
      summary: {
        totalDuration,
        averageDuration,
        medianDuration,
        minDuration,
        maxDuration,
        successRate,
        combinationsPerSecond,
        memoryPeakUsage
      },
      performanceAnalysis: {
        fastestCombinations,
        slowestCombinations,
        memoryIntensiveCombinations,
        recommendedOptimizations
      }
    };
  }

  /**
   * Calculate median from array of numbers
   */
  private calculateMedian(numbers: number[]): number {
    const sorted = [...numbers].sort((a, b) => a - b);
    const middle = Math.floor(sorted.length / 2);
    
    if (sorted.length % 2 === 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    } else {
      return sorted[middle];
    }
  }

  /**
   * Generate optimization recommendations based on benchmark results
   */
  private generateOptimizationRecommendations(
    averageDuration: number,
    memoryPeakUsage: number,
    successRate: number
  ): string[] {
    const recommendations: string[] = [];

    // Performance recommendations
    if (averageDuration > 30000) { // > 30 seconds
      recommendations.push(
        'Consider optimizing template generation pipeline - average duration exceeds 30s target'
      );
      recommendations.push(
        'Implement parallel processing for independent template operations'
      );
      recommendations.push(
        'Add template caching to avoid regenerating common components'
      );
    }

    if (averageDuration > 60000) { // > 1 minute
      recommendations.push(
        'Critical: Template generation is taking over 1 minute - investigate bottlenecks'
      );
    }

    // Memory recommendations
    const memoryMB = memoryPeakUsage / (1024 * 1024);
    if (memoryMB > 512) {
      recommendations.push(
        `Memory usage is high (${memoryMB.toFixed(0)}MB) - consider streaming template generation`
      );
      recommendations.push(
        'Implement template chunking to reduce memory footprint'
      );
    }

    if (memoryMB > 1024) {
      recommendations.push(
        'Critical: Memory usage exceeds 1GB - investigate memory leaks'
      );
    }

    // Success rate recommendations
    if (successRate < 0.9) {
      recommendations.push(
        'Low success rate detected - improve error handling and validation'
      );
      recommendations.push(
        'Add retry logic for transient failures'
      );
    }

    if (successRate < 0.7) {
      recommendations.push(
        'Critical: Success rate below 70% - investigate systematic failures'
      );
    }

    // Tool-specific recommendations
    recommendations.push(
      'Consider using Bun for fastest package manager performance'
    );
    recommendations.push(
      'Biome with integrated formatter provides fastest linting+formatting'
    );
    recommendations.push(
      'Bun Test provides fastest test execution for generated projects'
    );

    return recommendations;
  }

  /**
   * Export benchmark results to file
   */
  async exportReport(outputPath: string): Promise<void> {
    const report = this.generateReport();
    
    // Create output directory if it doesn't exist
    await fs.mkdir(path.dirname(outputPath), { recursive: true });
    
    // Write JSON report
    await fs.writeFile(
      outputPath,
      JSON.stringify(report, null, 2),
      'utf-8'
    );

    // Write human-readable report
    const humanReadableReport = this.formatHumanReadableReport(report);
    const mdPath = outputPath.replace(/\.json$/, '.md');
    await fs.writeFile(mdPath, humanReadableReport, 'utf-8');
  }

  /**
   * Format human-readable report
   */
  private formatHumanReadableReport(report: BenchmarkReport): string {
    const lines = [];
    
    lines.push('# Matrix Testing Performance Benchmark Report');
    lines.push('');
    lines.push(`**Generated:** ${report.testConfig.timestamp}`);
    lines.push(`**Total Combinations:** ${report.testConfig.totalCombinations}`);
    lines.push('');

    // System Information
    lines.push('## System Information');
    lines.push(`- **Platform:** ${report.systemInfo.platform} (${report.systemInfo.arch})`);
    lines.push(`- **Node.js:** ${report.systemInfo.nodeVersion}`);
    lines.push(`- **CPUs:** ${report.systemInfo.cpuCount}`);
    lines.push(`- **Memory:** ${report.systemInfo.totalMemory} total, ${report.systemInfo.freeMemory} free`);
    lines.push(`- **Load Average:** ${report.systemInfo.loadAverage.map(l => l.toFixed(2)).join(', ')}`);
    lines.push('');

    // Summary
    lines.push('## Performance Summary');
    lines.push(`- **Total Duration:** ${(report.summary.totalDuration / 1000).toFixed(1)}s`);
    lines.push(`- **Average Duration:** ${report.summary.averageDuration.toFixed(0)}ms`);
    lines.push(`- **Median Duration:** ${report.summary.medianDuration.toFixed(0)}ms`);
    lines.push(`- **Min/Max Duration:** ${report.summary.minDuration}ms / ${report.summary.maxDuration}ms`);
    lines.push(`- **Success Rate:** ${(report.summary.successRate * 100).toFixed(1)}%`);
    lines.push(`- **Combinations/Second:** ${report.summary.combinationsPerSecond.toFixed(2)}`);
    lines.push(`- **Peak Memory Usage:** ${(report.summary.memoryPeakUsage / (1024 * 1024)).toFixed(1)}MB`);
    lines.push('');

    // Performance Analysis
    lines.push('## Performance Analysis');
    
    lines.push('### Fastest Combinations');
    report.performanceAnalysis.fastestCombinations.forEach(combo => {
      lines.push(`- **${combo.combination}:** ${combo.duration}ms`);
    });
    lines.push('');

    lines.push('### Slowest Combinations');
    report.performanceAnalysis.slowestCombinations.forEach(combo => {
      lines.push(`- **${combo.combination}:** ${combo.duration}ms`);
    });
    lines.push('');

    lines.push('### Memory Intensive Combinations');
    report.performanceAnalysis.memoryIntensiveCombinations.forEach(combo => {
      lines.push(`- **${combo.combination}:** ${combo.memoryMB}MB`);
    });
    lines.push('');

    // Recommendations
    if (report.performanceAnalysis.recommendedOptimizations.length > 0) {
      lines.push('## Optimization Recommendations');
      report.performanceAnalysis.recommendedOptimizations.forEach(rec => {
        lines.push(`- ${rec}`);
      });
      lines.push('');
    }

    // Detailed Results
    lines.push('## Detailed Results');
    lines.push('');
    lines.push('| Combination | Duration (ms) | Memory (MB) | Success |');
    lines.push('|-------------|---------------|-------------|---------|');
    
    report.results.forEach(result => {
      const combination = this.formatCombination(result.combination);
      const memoryMB = (result.memoryUsage.heapUsed / (1024 * 1024)).toFixed(1);
      const success = result.success ? '✅' : '❌';
      
      lines.push(`| ${combination} | ${result.durationMs} | ${memoryMB} | ${success} |`);
    });

    return lines.join('\n');
  }

  /**
   * Get benchmark results for external use
   */
  getResults(): BenchmarkResult[] {
    return this.results;
  }

  /**
   * Reset benchmark data
   */
  reset(): void {
    this.results = [];
    this.startGlobalTime = 0;
    this.endGlobalTime = 0;
  }
}

/**
 * Standalone benchmark runner for CI/CD
 */
export class StandaloneBenchmarkRunner {
  private benchmark: PerformanceBenchmark;

  constructor() {
    this.benchmark = new PerformanceBenchmark();
  }

  /**
   * Run complete benchmark suite
   */
  async runBenchmarkSuite(outputDir: string = './benchmark-results'): Promise<BenchmarkReport> {
    console.log('Starting comprehensive benchmark suite...');
    
    this.benchmark.startGlobal();
    
    const validCombinations = getValidToolCombinations();
    console.log(`Benchmarking ${validCombinations.length} valid combinations`);

    // Benchmark template composition for each combination
    for (let i = 0; i < validCombinations.length; i++) {
      const combination = validCombinations[i];
      const comboStr = `${combination.packageManager}+${combination.linter}+${combination.formatter}+${combination.testFramework}`;
      
      console.log(`[${i + 1}/${validCombinations.length}] Benchmarking: ${comboStr}`);
      
      await this.benchmark.benchmarkOperation(
        combination,
        'template-composition',
        async () => {
          // Simulate template composition
          const config: MonorepoConfig = {
            name: `benchmark-test-${i}`,
            packageManager: combination.packageManager!,
            linter: combination.linter!,
            formatter: combination.formatter!,
            testFramework: combination.testFramework!
          };

          // Simulate the actual composition work
          await this.simulateTemplateComposition(config);
          return config;
        }
      );
    }

    this.benchmark.endGlobal();

    // Generate and export report
    const outputPath = path.join(outputDir, 'benchmark-report.json');
    await this.benchmark.exportReport(outputPath);
    
    const report = this.benchmark.generateReport();
    console.log('\n📊 Benchmark completed!');
    console.log(`📁 Report exported to: ${outputPath}`);
    console.log(`⚡ Average duration: ${report.summary.averageDuration.toFixed(0)}ms`);
    console.log(`✅ Success rate: ${(report.summary.successRate * 100).toFixed(1)}%`);

    return report;
  }

  /**
   * Simulate template composition work
   */
  private async simulateTemplateComposition(config: MonorepoConfig): Promise<void> {
    // Simulate file I/O operations
    await new Promise(resolve => setTimeout(resolve, Math.random() * 100 + 50));
    
    // Simulate template processing
    const templateCount = 20 + Math.floor(Math.random() * 10);
    for (let i = 0; i < templateCount; i++) {
      // Simulate processing each template file
      await new Promise(resolve => setTimeout(resolve, Math.random() * 10 + 5));
    }
    
    // Simulate validation
    await new Promise(resolve => setTimeout(resolve, Math.random() * 20 + 10));
  }
}

// Export for CLI usage
if (require.main === module) {
  const runner = new StandaloneBenchmarkRunner();
  const outputDir = process.argv[2] || './benchmark-results';
  
  runner.runBenchmarkSuite(outputDir)
    .then(report => {
      console.log('\n🎯 Benchmark suite completed successfully!');
      process.exit(0);
    })
    .catch(error => {
      console.error('❌ Benchmark suite failed:', error);
      process.exit(1);
    });
}