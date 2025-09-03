/**
 * Performance Optimization Tests
 * 
 * Validates that template generation meets the <30 second target
 * and that performance optimizations work correctly.
 */

import { describe, test, expect, beforeAll, afterAll } from 'vitest';
import { 
  performanceOptimizer, 
  performanceMonitor, 
  PerformanceCache, 
  ParallelTemplateProcessor,
  StreamingFileProcessor,
  PerformanceMonitor
} from '../src/performance';
import { generateTemplate } from '../src/actions';
import type { MonorepoConfig, TemplateContext } from '../src';

describe('Performance Optimization', () => {
  beforeAll(async () => {
    // Initialize performance systems
    await performanceOptimizer.initialize();
  });

  afterAll(async () => {
    // Cleanup performance systems
    await performanceOptimizer.cleanup();
    performanceMonitor.clear();
  });

  describe('PerformanceCache', () => {
    test('should cache and retrieve values correctly', () => {
      const cache = new PerformanceCache(100, 10); // 100 entries, 10MB
      
      const testData = { test: 'value', nested: { data: 123 } };
      const key = 'test-key';
      
      // Should miss initially
      expect(cache.get(key)).toBeNull();
      
      // Set value
      cache.set(key, testData, 60000); // 1 minute TTL
      
      // Should hit now
      expect(cache.get(key)).toEqual(testData);
      
      // Check stats
      const stats = cache.getStats();
      expect(stats.hits).toBe(1);
      expect(stats.misses).toBe(1);
      expect(stats.hitRate).toBe(0.5);
    });

    test('should handle expiration correctly', async () => {
      const cache = new PerformanceCache();
      const key = 'expiring-key';
      
      // Set with short TTL
      cache.set(key, 'test-value', 10); // 10ms TTL
      
      // Should be available immediately
      expect(cache.get(key)).toBe('test-value');
      
      // Wait for expiration
      await new Promise(resolve => setTimeout(resolve, 20));
      
      // Should be expired
      expect(cache.get(key)).toBeNull();
    });

    test('should handle memory limits', () => {
      const cache = new PerformanceCache(10, 1); // 1MB limit
      
      // Create large data that would exceed memory
      const largeData = 'x'.repeat(500 * 1024); // 500KB
      
      // First entry should work
      cache.set('key1', largeData);
      expect(cache.get('key1')).toBe(largeData);
      
      // Second entry should work but might evict first
      cache.set('key2', largeData);
      expect(cache.get('key2')).toBe(largeData);
      
      // Third entry should cause eviction
      cache.set('key3', largeData);
      expect(cache.get('key3')).toBe(largeData);
      
      // Check that we stayed within memory limits
      const stats = cache.getStats();
      expect(stats.memoryUsageMB).toBeLessThanOrEqual(1);
    });

    test('should implement LRU eviction', () => {
      const cache = new PerformanceCache(3, 10); // 3 entries max
      
      // Fill cache
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');
      cache.set('key3', 'value3');
      
      // Access key1 to make it recently used
      cache.get('key1');
      
      // Add new entry, should evict key2 (least recently used)
      cache.set('key4', 'value4');
      
      expect(cache.get('key1')).toBe('value1'); // Still there
      expect(cache.get('key2')).toBeNull(); // Evicted
      expect(cache.get('key3')).toBe('value3'); // Still there
      expect(cache.get('key4')).toBe('value4'); // New entry
    });
  });

  describe('ParallelTemplateProcessor', () => {
    test('should initialize and cleanup correctly', async () => {
      const processor = new ParallelTemplateProcessor(2);
      
      // Should initialize without errors
      await expect(processor.initialize()).resolves.not.toThrow();
      
      // Should cleanup without errors
      await expect(processor.cleanup()).resolves.not.toThrow();
    });

    test('should process templates in parallel', async () => {
      const processor = new ParallelTemplateProcessor(2);
      await processor.initialize();
      
      const startTime = Date.now();
      
      // Create test tasks
      const tasks = Array.from({ length: 4 }, (_, i) => ({
        id: `task-${i}`,
        templatePath: `template-${i}.ejs`,
        context: { name: 'test-project' } as TemplateContext,
        outputPath: `output-${i}.js`,
        priority: i
      }));
      
      // Process in parallel
      await processor.processTemplates(tasks);
      
      const duration = Date.now() - startTime;
      
      // Parallel processing should be faster than sequential
      // (This is a rough test - in real scenario would be more pronounced)
      expect(duration).toBeLessThan(1000); // Should complete quickly
      
      await processor.cleanup();
    });
  });

  describe('StreamingFileProcessor', () => {
    test('should process files with controlled concurrency', async () => {
      const processor = new StreamingFileProcessor(3); // Max 3 concurrent
      
      const filePaths = Array.from({ length: 6 }, (_, i) => `file-${i}.txt`);
      let processedCount = 0;
      
      const startTime = Date.now();
      
      await processor.processFiles(filePaths, async (content, filePath) => {
        processedCount++;
        // Simulate processing time
        await new Promise(resolve => setTimeout(resolve, 50));
        return `processed: ${content}`;
      });
      
      const duration = Date.now() - startTime;
      
      expect(processedCount).toBe(6);
      // Should complete in reasonable time with controlled concurrency
      expect(duration).toBeLessThan(500);
    });
  });

  describe('OptimizedTemplateComposer', () => {
    test('should compose templates with caching', async () => {
      const context: TemplateContext = {
        name: 'test-project',
        packageManager: 'bun',
        linter: 'eslint',
        formatter: 'prettier',
        testFramework: 'vitest'
      };
      
      // First composition (should miss cache)
      const result1 = await performanceOptimizer.composeOptimized(context);
      expect(result1.success).toBe(true);
      expect(result1.metrics.cacheMisses).toBeGreaterThan(0);
      
      // Second composition (should hit cache for some operations)
      const result2 = await performanceOptimizer.composeOptimized(context);
      expect(result2.success).toBe(true);
      // May or may not hit cache depending on TTL and implementation
      
      // Verify metrics are collected
      expect(result1.metrics.startTime).toBeGreaterThan(0);
      expect(result1.metrics.duration).toBeGreaterThan(0);
      expect(result1.cacheStats).toBeDefined();
    });

    test('should handle different project sizes', async () => {
      const smallProject: TemplateContext = {
        name: 'small-project',
        packageManager: 'bun',
        linter: 'eslint',
        formatter: 'prettier',
        testFramework: 'vitest'
      };
      
      const largeProject: TemplateContext = {
        name: 'large-project',
        packageManager: 'bun',
        linter: 'eslint',
        formatter: 'prettier',
        testFramework: 'vitest',
        tools: {
          typescript: true,
          storybook: true,
          docker: true
        }
      };
      
      // Both should succeed regardless of size
      const smallResult = await performanceOptimizer.composeOptimized(smallProject);
      const largeResult = await performanceOptimizer.composeOptimized(largeProject);
      
      expect(smallResult.success).toBe(true);
      expect(largeResult.success).toBe(true);
      
      // Large project might use parallel processing
      expect(largeResult.metrics.filesProcessed).toBeGreaterThanOrEqual(smallResult.metrics.filesProcessed);
    });
  });

  describe('PerformanceMonitor', () => {
    test('should track and analyze performance metrics', () => {
      const monitor = new PerformanceMonitor();
      
      // Add test metrics
      const metrics = [
        {
          startTime: Date.now() - 1000,
          endTime: Date.now() - 500,
          duration: 500,
          operation: 'test-op-1',
          cacheHits: 5,
          cacheMisses: 2,
          parallelOperations: 0,
          filesProcessed: 3
        },
        {
          startTime: Date.now() - 2000,
          endTime: Date.now() - 1500,
          duration: 500,
          operation: 'test-op-2',
          cacheHits: 3,
          cacheMisses: 1,
          parallelOperations: 2,
          filesProcessed: 5
        }
      ];
      
      metrics.forEach(m => monitor.addMetrics(m));
      
      const analysis = monitor.analyzePerformance();
      expect(analysis.meetsTarget).toBe(true); // Both operations under 30s
      expect(analysis.averageDuration).toBe(500);
      expect(analysis.slowestOperations).toHaveLength(2);
      
      const summary = monitor.getSummary();
      expect(summary.totalOperations).toBe(2);
      expect(summary.cacheHitRate).toBeGreaterThan(0.7);
      expect(summary.totalFilesProcessed).toBe(8);
    });

    test('should provide recommendations for slow operations', () => {
      const monitor = new PerformanceMonitor();
      
      // Add slow operation
      monitor.addMetrics({
        startTime: Date.now() - 35000,
        endTime: Date.now(),
        duration: 35000, // 35 seconds - exceeds target
        operation: 'slow-operation',
        cacheHits: 0,
        cacheMisses: 10,
        parallelOperations: 0,
        filesProcessed: 20
      });
      
      const analysis = monitor.analyzePerformance();
      expect(analysis.meetsTarget).toBe(false);
      expect(analysis.recommendations).toContain(
        expect.stringContaining('exceeds 30s target')
      );
      expect(analysis.recommendations).toContain(
        expect.stringContaining('parallel processing')
      );
    });
  });

  describe('End-to-End Performance', () => {
    test('should meet 30-second target for typical monorepo generation', async () => {
      const context: TemplateContext = {
        name: 'performance-test-monorepo',
        packageManager: 'bun',
        linter: 'eslint',
        formatter: 'prettier',
        testFramework: 'vitest',
        tools: {
          typescript: true,
          storybook: false,
          docker: false
        },
        moon: {
          toolchain: 'bun'
        }
      };
      
      const startTime = Date.now();
      
      // This would normally call the full template generation
      // For testing, we'll use the optimized composer directly
      const result = await performanceOptimizer.composeOptimized(context);
      
      const duration = Date.now() - startTime;
      const meetsTarget = duration < 30000; // 30 seconds
      
      expect(result.success).toBe(true);
      expect(meetsTarget).toBe(true);
      expect(duration).toBeLessThan(30000);
      
      // Log performance for analysis
      console.log(`Performance test completed in ${duration}ms (target: <30000ms)`);
      console.log(`Cache hit rate: ${(result.cacheStats.hitRate * 100).toFixed(1)}%`);
      console.log(`Files processed: ${result.metrics.filesProcessed}`);
    }, 35000); // Allow up to 35 seconds for the test itself

    test('should handle multiple concurrent generations efficiently', async () => {
      const contexts: TemplateContext[] = Array.from({ length: 3 }, (_, i) => ({
        name: `concurrent-project-${i}`,
        packageManager: 'bun',
        linter: 'eslint',
        formatter: 'prettier',
        testFramework: 'vitest'
      }));
      
      const startTime = Date.now();
      
      // Process multiple projects concurrently
      const results = await Promise.all(
        contexts.map(context => performanceOptimizer.composeOptimized(context))
      );
      
      const duration = Date.now() - startTime;
      
      // All should succeed
      expect(results.every(r => r.success)).toBe(true);
      
      // Should complete faster than sequential processing would
      expect(duration).toBeLessThan(10000); // 10 seconds for 3 projects
      
      console.log(`Concurrent generation of ${contexts.length} projects completed in ${duration}ms`);
    });

    test('should scale performance based on project complexity', async () => {
      const simpleProject: TemplateContext = {
        name: 'simple-project',
        packageManager: 'bun',
        linter: 'eslint',
        formatter: 'prettier',
        testFramework: 'vitest'
      };
      
      const complexProject: TemplateContext = {
        name: 'complex-project',
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
      };
      
      const [simpleResult, complexResult] = await Promise.all([
        performanceOptimizer.composeOptimized(simpleProject),
        performanceOptimizer.composeOptimized(complexProject)
      ]);
      
      expect(simpleResult.success).toBe(true);
      expect(complexResult.success).toBe(true);
      
      // Complex project should process more files
      expect(complexResult.metrics.filesProcessed).toBeGreaterThanOrEqual(
        simpleResult.metrics.filesProcessed
      );
      
      // Both should meet performance targets
      expect(simpleResult.metrics.duration).toBeLessThan(30000);
      expect(complexResult.metrics.duration).toBeLessThan(30000);
      
      console.log('Simple project:', {
        duration: simpleResult.metrics.duration,
        files: simpleResult.metrics.filesProcessed,
        parallel: simpleResult.metrics.parallelOperations
      });
      
      console.log('Complex project:', {
        duration: complexResult.metrics.duration,
        files: complexResult.metrics.filesProcessed,
        parallel: complexResult.metrics.parallelOperations
      });
    });
  });

  describe('Memory Optimization', () => {
    test('should maintain reasonable memory usage', async () => {
      const initialMemory = process.memoryUsage();
      
      // Process several projects to test memory usage
      const contexts: TemplateContext[] = Array.from({ length: 5 }, (_, i) => ({
        name: `memory-test-${i}`,
        packageManager: 'bun',
        linter: 'eslint',
        formatter: 'prettier',
        testFramework: 'vitest',
        tools: {
          typescript: true,
          storybook: i % 2 === 0, // Vary complexity
          docker: i % 3 === 0
        }
      }));
      
      for (const context of contexts) {
        await performanceOptimizer.composeOptimized(context);
      }
      
      const finalMemory = process.memoryUsage();
      const memoryIncrease = finalMemory.heapUsed - initialMemory.heapUsed;
      const memoryIncreaseMB = memoryIncrease / (1024 * 1024);
      
      // Should not increase memory usage by more than 100MB for 5 projects
      expect(memoryIncreaseMB).toBeLessThan(100);
      
      console.log(`Memory increase: ${memoryIncreaseMB.toFixed(2)}MB for ${contexts.length} projects`);
    });

    test('should cleanup resources properly', async () => {
      const initialMemory = process.memoryUsage().heapUsed;
      
      // Create separate optimizer to test cleanup
      const testOptimizer = new (await import('../src/performance')).OptimizedTemplateComposer();
      await testOptimizer.initialize();
      
      // Process some templates
      await testOptimizer.composeOptimized({
        name: 'cleanup-test',
        packageManager: 'bun',
        linter: 'eslint',
        formatter: 'prettier',
        testFramework: 'vitest'
      });
      
      // Cleanup
      await testOptimizer.cleanup();
      
      // Force garbage collection if available
      if (global.gc) {
        global.gc();
      }
      
      const finalMemory = process.memoryUsage().heapUsed;
      const memoryDiff = finalMemory - initialMemory;
      const memoryDiffMB = memoryDiff / (1024 * 1024);
      
      // Should not leak significant memory
      expect(memoryDiffMB).toBeLessThan(50); // Less than 50MB increase
      
      console.log(`Memory after cleanup: ${memoryDiffMB.toFixed(2)}MB difference`);
    });
  });
});