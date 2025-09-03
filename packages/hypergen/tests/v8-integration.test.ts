/**
 * V8 Integration Tests
 * 
 * End-to-end tests that prove the complete V8 implementation works:
 * - Template.yml configuration system
 * - Action discovery and registration
 * - CLI command execution
 * - Template-to-code generation pipeline
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import fs from 'fs-extra'
import path from 'path'
import { exec } from 'child_process'
import { promisify } from 'util'

const execAsync = promisify(exec)

describe('V8 Integration Tests', () => {
  const testDir = path.join(__dirname, '..', 'test-output')
  const hypergenBin = path.join(__dirname, '..', 'src', 'bin.ts')

  beforeEach(async () => {
    // Clean test output directory
    await fs.ensureDir(testDir)
    await fs.emptyDir(testDir)
  })

  afterEach(async () => {
    // Clean up test output
    await fs.remove(testDir)
  })

  describe('Template.yml Configuration System', () => {
    it('should validate template.yml files', async () => {
      const { stdout } = await execAsync(
        `cd ${path.dirname(hypergenBin)} && bun --bun ${hypergenBin} template validate _templates/my-test-generator/template.yml`
      )
      
      expect(stdout).toContain('✅ Template validation successful')
      expect(stdout).toContain('my-test-generator')
      expect(stdout).toContain('Variables: 5')
      expect(stdout).toContain('Examples: 1')
    })

    it('should show template information', async () => {
      const { stdout } = await execAsync(
        `cd ${path.dirname(hypergenBin)} && bun --bun ${hypergenBin} template info _templates/my-test-generator/template.yml`
      )
      
      expect(stdout).toContain('📋 Template: my-test-generator')
      expect(stdout).toContain('Description: Test generator for React components')
      expect(stdout).toContain('Version: 1.0.0')
      expect(stdout).toContain('Variables (5):')
      expect(stdout).toContain('• name (string) *required*')
      expect(stdout).toContain('• type (enum) [default: functional]')
    })

    it('should list templates', async () => {
      const { stdout } = await execAsync(
        `cd ${path.dirname(hypergenBin)} && bun --bun ${hypergenBin} template list _templates`
      )
      
      expect(stdout).toContain('📝 Templates found in _templates (1):')
      expect(stdout).toContain('• my-test-generator - Test generator for React components')
    })

    it('should show template examples', async () => {
      const { stdout } = await execAsync(
        `cd ${path.dirname(hypergenBin)} && bun --bun ${hypergenBin} template examples _templates/my-test-generator/template.yml`
      )
      
      expect(stdout).toContain('📝 Examples for template: my-test-generator')
      expect(stdout).toContain('1. Basic my-test-generator')
      expect(stdout).toContain('hypergen action my-test-generator')
    })
  })

  describe('Action Discovery and Registration', () => {
    it('should discover generators', async () => {
      const { stdout } = await execAsync(
        `cd ${path.dirname(hypergenBin)} && bun --bun ${hypergenBin} discover`
      )
      
      expect(stdout).toContain('🔍 Discovery complete: found 1 generators')
      expect(stdout).toContain('📦 my-test-generator (local)')
      expect(stdout).toContain('Actions: myTestGenerator')
    })

    it('should list actions after discovery', async () => {
      const { stdout } = await execAsync(
        `cd ${path.dirname(hypergenBin)} && bun --bun ${hypergenBin} list`
      )
      
      expect(stdout).toContain('📝 Available actions:')
      expect(stdout).toContain('• my-test-generator - Test generator for React components')
      expect(stdout).toContain('📂 Categories: custom')
    })

    it('should show action information', async () => {
      const { stdout } = await execAsync(
        `cd ${path.dirname(hypergenBin)} && bun --bun ${hypergenBin} info my-test-generator`
      )
      
      expect(stdout).toContain('📋 Action: my-test-generator')
      expect(stdout).toContain('Description: Test generator for React components')
      expect(stdout).toContain('Category: custom')
      expect(stdout).toContain('Parameters (5):')
      expect(stdout).toContain('• name (string) *required*')
    })

    it('should list actions by category', async () => {
      const { stdout } = await execAsync(
        `cd ${path.dirname(hypergenBin)} && bun --bun ${hypergenBin} list custom`
      )
      
      expect(stdout).toContain('📝 Actions in category \'custom\':')
      expect(stdout).toContain('• my-test-generator')
    })
  })

  describe('End-to-End Action Execution', () => {
    it('should execute action and generate files', async () => {
      // Change to test directory for file generation
      const { stdout } = await execAsync(
        `cd ${testDir} && bun --bun ${hypergenBin} action my-test-generator --name TestComponent --type functional --withProps true --withStorybook false --styling css --defaults`
      )
      
      // Verify command output
      expect(stdout).toContain('ℹ️  Creating my-test-generator: TestComponent')
      expect(stdout).toContain('✅ Created my-test-generator TestComponent with 2 files')
      expect(stdout).toContain('✅ Action \'my-test-generator\' completed successfully')
      expect(stdout).toContain('Files created:')
      
      // Verify files were created
      const mainFile = path.join(testDir, 'src', 'my-test-generators', 'TestComponent.ts')
      const testFile = path.join(testDir, 'src', 'my-test-generators', 'TestComponent.test.ts')
      
      expect(await fs.pathExists(mainFile)).toBe(true)
      expect(await fs.pathExists(testFile)).toBe(true)
      
      // Verify file contents
      const mainContent = await fs.readFile(mainFile, 'utf-8')
      expect(mainContent).toContain('// Generated my-test-generator: TestComponent')
      expect(mainContent).toContain('export const TestComponent = {')
      
      const testContent = await fs.readFile(testFile, 'utf-8')
      expect(testContent).toContain('import { TestComponent }')
      expect(testContent).toContain('describe(\'TestComponent\'')
    })

    it('should handle different parameter combinations', async () => {
      const { stdout } = await execAsync(
        `cd ${testDir} && bun --bun ${hypergenBin} action my-test-generator --name ButtonComponent --type class --withProps false --withStorybook true --styling scss --defaults`
      )
      
      expect(stdout).toContain('✅ Action \'my-test-generator\' completed successfully')
      expect(stdout).toContain('Creating my-test-generator: ButtonComponent')
      
      // Verify the file was created with the correct name
      const buttonFile = path.join(testDir, 'src', 'my-test-generators', 'ButtonComponent.ts')
      expect(await fs.pathExists(buttonFile)).toBe(true)
    })
  })

  describe('System Commands', () => {
    it('should show system help', async () => {
      const { stdout } = await execAsync(
        `cd ${path.dirname(hypergenBin)} && bun --bun ${hypergenBin} system help`
      )
      
      expect(stdout).toContain('🚀 Hypergen Commands')
      expect(stdout).toContain('Action Management:')
      expect(stdout).toContain('Generator Discovery:')
      expect(stdout).toContain('Template Management:')
    })

    it('should show system status', async () => {
      const { stdout } = await execAsync(
        `cd ${path.dirname(hypergenBin)} && bun --bun ${hypergenBin} system status`
      )
      
      expect(stdout).toContain('📊 Hypergen Status')
      expect(stdout).toContain('Generators: 1')
      expect(stdout).toContain('Actions: 1')
      expect(stdout).toContain('Categories: 1')
    })

    it('should show version information', async () => {
      const { stdout } = await execAsync(
        `cd ${path.dirname(hypergenBin)} && bun --bun ${hypergenBin} system version`
      )
      
      expect(stdout).toContain('Hypergen')
    })
  })

  describe('Error Handling', () => {
    it('should handle missing action gracefully', async () => {
      try {
        await execAsync(
          `cd ${path.dirname(hypergenBin)} && bun --bun ${hypergenBin} action non-existent-action --name test`
        )
      } catch (error: any) {
        expect(error.stdout).toContain('❌ Action \'non-existent-action\' not found')
        expect(error.stdout).toContain('💡 Suggestions:')
      }
    })

    it('should validate template files', async () => {
      try {
        await execAsync(
          `cd ${path.dirname(hypergenBin)} && bun --bun ${hypergenBin} template validate non-existent.yml`
        )
      } catch (error: any) {
        expect(error.stdout).toContain('Template file not found')
      }
    })
  })
})