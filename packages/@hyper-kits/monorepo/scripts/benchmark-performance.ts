#!/usr/bin/env bun
/**
 * Performance Benchmark Script
 * 
 * Runs comprehensive performance tests to validate that template generation
 * meets the <30 second target and measures optimization effectiveness.
 */

import * as fs from 'fs/promises';
import * as path from 'path';
import * as os from 'os';
import { 
  performanceOptimizer, 
  performanceMonitor, 
  PerformanceBenchmark 
} from '../src/performance';
import { generateTemplate } from '../src/actions';
import type { MonorepoConfig, TemplateContext } from '../src';

interface BenchmarkConfig {
  outputDir: string;
  testCases: Array<{
    name: string;
    context: TemplateContext;
    expectedMaxDuration: number;
  }>;
  concurrencyTests: boolean;
  memoryTests: boolean;
  cacheTests: boolean;
}

/**
 * Main benchmark runner
 */
async function runPerformanceBenchmark(config: BenchmarkConfig): Promise<void> {
  console.log('🚀 Starting Hypergen Monorepo Performance Benchmark');
  console.log(`📊 System: ${os.platform()} ${os.arch()}, Node ${process.version}`);
  console.log(`💾 Memory: ${Math.round(os.totalmem() / 1024 / 1024 / 1024)}GB total`);
  console.log(`🧮 CPUs: ${os.cpus().length}\n`);

  const benchmark = new PerformanceBenchmark();
  benchmark.startGlobal();

  try {
    // Initialize performance systems
    await performanceOptimizer.initialize();

    // Test individual cases
    console.log('📋 Running individual test cases...');
    for (const testCase of config.testCases) {
      await runSingleBenchmark(benchmark, testCase);
    }

    // Concurrency tests
    if (config.concurrencyTests) {
      console.log('\n🔄 Running concurrency tests...');
      await runConcurrencyBenchmark(benchmark, config.testCases);
    }

    // Memory tests
    if (config.memoryTests) {
      console.log('\n💾 Running memory tests...');
      await runMemoryBenchmark(benchmark, config.testCases);
    }

    // Cache effectiveness tests
    if (config.cacheTests) {
      console.log('\n🎯 Running cache tests...');
      await runCacheBenchmark(benchmark, config.testCases);
    }

  } finally {
    benchmark.endGlobal();
    await performanceOptimizer.cleanup();
  }

  // Generate report
  console.log('\n📊 Generating benchmark report...');
  await generateBenchmarkReport(benchmark, config.outputDir);
  
  // Performance analysis
  const analysis = performanceMonitor.analyzePerformance();
  displayPerformanceAnalysis(analysis);
}

/**
 * Run benchmark for a single test case
 */
async function runSingleBenchmark(
  benchmark: PerformanceBenchmark, 
  testCase: { name: string; context: TemplateContext; expectedMaxDuration: number }
): Promise<void> {
  console.log(`  🧪 Testing: ${testCase.name}`);
  
  const { result, benchmark: benchmarkResult } = await benchmark.benchmarkOperation(
    testCase.context,
    testCase.name,
    async () => {
      return await performanceOptimizer.composeOptimized(testCase.context);
    }
  );

  const duration = benchmarkResult.durationMs;
  const meetsTarget = duration <= testCase.expectedMaxDuration;
  const memoryMB = Math.round(benchmarkResult.memoryUsage.heapUsed / 1024 / 1024);
  
  console.log(`    ⏱️  Duration: ${duration}ms (target: <${testCase.expectedMaxDuration}ms) ${meetsTarget ? '✅' : '❌'}`);
  console.log(`    💾 Memory: ${memoryMB}MB`);
  
  if (result) {
    console.log(`    🎯 Cache: ${(result.cacheStats.hitRate * 100).toFixed(1)}% hit rate`);
    console.log(`    📄 Files: ${result.metrics.filesProcessed} processed`);
    
    if (result.metrics.parallelOperations > 0) {
      console.log(`    ⚡ Parallel: ${result.metrics.parallelOperations} operations`);
    }
  }
  
  performanceMonitor.addMetrics(benchmarkResult);
  console.log();
}

/**
 * Run concurrency benchmark
 */
async function runConcurrencyBenchmark(
  benchmark: PerformanceBenchmark,
  testCases: Array<{ name: string; context: TemplateContext; expectedMaxDuration: number }>
): Promise<void> {
  const concurrentCount = Math.min(3, testCases.length);
  const selectedCases = testCases.slice(0, concurrentCount);
  
  console.log(`  🔄 Running ${concurrentCount} concurrent operations...`);
  
  const startTime = Date.now();
  
  const promises = selectedCases.map((testCase, index) =>
    benchmark.benchmarkOperation(
      testCase.context,
      `concurrent-${index}`,
      async () => {
        return await performanceOptimizer.composeOptimized({
          ...testCase.context,
          name: `${testCase.context.name}-concurrent-${index}`
        });
      }
    )
  );

  const results = await Promise.all(promises);
  const totalDuration = Date.now() - startTime;
  
  console.log(`    ⏱️  Total Duration: ${totalDuration}ms`);
  console.log(`    📊 Average: ${Math.round(totalDuration / concurrentCount)}ms per operation`);
  
  const successCount = results.filter(r => r.result?.success).length;
  console.log(`    ✅ Success Rate: ${successCount}/${concurrentCount} (${((successCount / concurrentCount) * 100).toFixed(1)}%)`);
  
  results.forEach(({ benchmark: b }, index) => {
    performanceMonitor.addMetrics(b);
  });
  
  console.log();
}

/**
 * Run memory benchmark
 */
async function runMemoryBenchmark(
  benchmark: PerformanceBenchmark,
  testCases: Array<{ name: string; context: TemplateContext; expectedMaxDuration: number }>
): Promise<void> {
  console.log('  💾 Memory usage analysis...');
  
  const initialMemory = process.memoryUsage();
  const memoryReadings: Array<{ operation: string; memoryMB: number }> = [];
  
  for (let i = 0; i < Math.min(5, testCases.length); i++) {
    const testCase = testCases[i];
    
    await performanceOptimizer.composeOptimized({
      ...testCase.context,
      name: `${testCase.context.name}-memory-${i}`
    });
    
    const currentMemory = process.memoryUsage();
    const memoryMB = Math.round(currentMemory.heapUsed / 1024 / 1024);
    memoryReadings.push({ operation: `operation-${i}`, memoryMB });
  }
  
  const finalMemory = process.memoryUsage();
  const totalIncrease = Math.round((finalMemory.heapUsed - initialMemory.heapUsed) / 1024 / 1024);
  
  console.log(`    📈 Memory Increase: ${totalIncrease}MB for ${memoryReadings.length} operations`);
  console.log(`    📊 Average per Operation: ${Math.round(totalIncrease / memoryReadings.length)}MB`);
  console.log(`    💾 Peak Usage: ${Math.max(...memoryReadings.map(r => r.memoryMB))}MB`);
  
  // Check for memory leaks
  if (totalIncrease > 100) {
    console.warn(`    ⚠️  High memory usage detected - potential memory leak`);
  }
  
  console.log();
}

/**
 * Run cache effectiveness benchmark
 */
async function runCacheBenchmark(
  benchmark: PerformanceBenchmark,
  testCases: Array<{ name: string; context: TemplateContext; expectedMaxDuration: number }>
): Promise<void> {
  console.log('  🎯 Cache effectiveness analysis...');
  
  const testCase = testCases[0]; // Use first test case
  if (!testCase) return;
  
  // First run (cache miss)
  const firstRun = await benchmark.benchmarkOperation(
    testCase.context,
    'cache-first-run',
    async () => performanceOptimizer.composeOptimized(testCase.context)
  );
  
  // Second run (potential cache hit)
  const secondRun = await benchmark.benchmarkOperation(
    testCase.context,
    'cache-second-run',
    async () => performanceOptimizer.composeOptimized(testCase.context)
  );
  
  // Third run with slight variation (partial cache hit)
  const thirdRun = await benchmark.benchmarkOperation(
    { ...testCase.context, name: `${testCase.context.name}-variant` },
    'cache-third-run',
    async () => performanceOptimizer.composeOptimized({
      ...testCase.context,
      name: `${testCase.context.name}-variant`
    })
  );
  
  console.log(`    1️⃣  First Run: ${firstRun.benchmark.durationMs}ms (cache miss expected)`);
  console.log(`    2️⃣  Second Run: ${secondRun.benchmark.durationMs}ms (cache hit expected)`);
  console.log(`    3️⃣  Variant Run: ${thirdRun.benchmark.durationMs}ms (partial cache hit expected)`);
  
  if (firstRun.result && secondRun.result) {
    const improvement = ((firstRun.benchmark.durationMs - secondRun.benchmark.durationMs) / firstRun.benchmark.durationMs) * 100;
    console.log(`    📈 Cache Improvement: ${improvement.toFixed(1)}% faster on second run`);
    
    const avgHitRate = (firstRun.result.cacheStats.hitRate + secondRun.result.cacheStats.hitRate + (thirdRun.result?.cacheStats.hitRate || 0)) / 3;
    console.log(`    🎯 Average Hit Rate: ${(avgHitRate * 100).toFixed(1)}%`);
  }
  
  console.log();
}

/**
 * Generate comprehensive benchmark report
 */
async function generateBenchmarkReport(benchmark: PerformanceBenchmark, outputDir: string): Promise<void> {
  const reportPath = path.join(outputDir, 'performance-benchmark.json');
  const mdReportPath = path.join(outputDir, 'performance-benchmark.md');
  
  await fs.mkdir(outputDir, { recursive: true });
  await benchmark.exportReport(reportPath);
  
  const report = benchmark.generateReport();
  
  // Generate additional analysis
  const analysisReport = {
    ...report,
    hypergenAnalysis: {
      targetCompliance: {
        targetDurationMs: 30000,
        averageMeetsTarget: report.summary.averageDuration < 30000,
        allMeetTarget: report.results.every(r => r.durationMs < 30000),
        worstCaseCompliance: report.summary.maxDuration < 30000
      },
      optimizations: {
        cacheEffectiveness: report.results.filter(r => r.success).length > 0 ? 'Active' : 'Disabled',
        parallelProcessing: report.results.some(r => r.operationName.includes('concurrent')) ? 'Active' : 'Not Used',
        memoryOptimization: report.summary.memoryPeakUsage < 512 * 1024 * 1024 ? 'Effective' : 'Needs Attention'
      },
      recommendations: generateOptimizationRecommendations(report)
    }
  };
  
  // Write enhanced JSON report
  await fs.writeFile(reportPath, JSON.stringify(analysisReport, null, 2));
  
  console.log(`📄 Detailed report: ${reportPath}`);
  console.log(`📖 Human-readable: ${mdReportPath}`);
}

/**
 * Generate optimization recommendations
 */
function generateOptimizationRecommendations(report: any): string[] {
  const recommendations: string[] = [];
  
  if (report.summary.averageDuration > 30000) {
    recommendations.push('Average duration exceeds 30s target - implement additional optimizations');
  }
  
  if (report.summary.memoryPeakUsage > 256 * 1024 * 1024) {
    recommendations.push('High memory usage detected - consider streaming optimizations');
  }
  
  if (report.summary.successRate < 0.95) {
    recommendations.push('Success rate below 95% - investigate reliability issues');
  }
  
  const fastestCombo = report.performanceAnalysis.fastestCombinations[0];
  if (fastestCombo) {
    recommendations.push(`Fastest configuration: ${fastestCombo.combination} (${fastestCombo.duration}ms)`);
  }
  
  return recommendations;
}

/**
 * Display performance analysis
 */
function displayPerformanceAnalysis(analysis: any): void {
  console.log('\n📊 Performance Analysis Summary');
  console.log('===============================');
  
  console.log(`🎯 Target Compliance: ${analysis.meetsTarget ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`⏱️  Average Duration: ${analysis.averageDuration}ms (target: <30000ms)`);
  
  if (analysis.slowestOperations.length > 0) {
    console.log('\n🐌 Slowest Operations:');
    analysis.slowestOperations.slice(0, 3).forEach((op: any, i: number) => {
      console.log(`   ${i + 1}. ${op.operation}: ${op.duration}ms`);
    });
  }
  
  if (analysis.recommendations.length > 0) {
    console.log('\n💡 Optimization Recommendations:');
    analysis.recommendations.forEach((rec: string) => {
      console.log(`   • ${rec}`);
    });
  }
  
  const summary = performanceMonitor.getSummary();
  console.log(`\n📈 Cache Performance: ${(summary.cacheHitRate * 100).toFixed(1)}% hit rate`);
  console.log(`📄 Total Files Processed: ${summary.totalFilesProcessed}`);
  
  console.log('\n✅ Benchmark Complete!');
}

/**
 * Default benchmark configuration
 */
const defaultConfig: BenchmarkConfig = {
  outputDir: './benchmark-results',
  testCases: [
    {
      name: 'Simple Monorepo',
      context: {
        name: 'simple-monorepo',
        packageManager: 'bun',
        linter: 'eslint',
        formatter: 'prettier',
        testFramework: 'vitest'
      },
      expectedMaxDuration: 15000 // 15 seconds
    },
    {
      name: 'Standard Monorepo',
      context: {
        name: 'standard-monorepo',
        packageManager: 'bun',
        linter: 'eslint',
        formatter: 'prettier',
        testFramework: 'vitest',
        tools: {
          typescript: true,
          storybook: false,
          docker: false
        }
      },
      expectedMaxDuration: 25000 // 25 seconds
    },
    {
      name: 'Complex Monorepo',
      context: {
        name: 'complex-monorepo',
        packageManager: 'bun',
        linter: 'biome',
        formatter: 'biome-integrated',
        testFramework: 'bun-test',
        tools: {
          typescript: true,
          storybook: true,
          docker: true
        },
        moon: {
          toolchain: 'bun',
          projects: ['api', 'web', 'mobile', 'shared']
        }
      },
      expectedMaxDuration: 30000 // 30 seconds
    }
  ],
  concurrencyTests: true,
  memoryTests: true,
  cacheTests: true
};

// Run benchmark if called directly
if (import.meta.main) {
  const outputDir = process.argv[2] || defaultConfig.outputDir;
  const config = { ...defaultConfig, outputDir };
  
  runPerformanceBenchmark(config)
    .then(() => {
      console.log('\n🎉 Performance benchmark completed successfully!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ Performance benchmark failed:', error);
      process.exit(1);
    });
}

export { runPerformanceBenchmark, defaultConfig };