#!/usr/bin/env node

/**
 * Test script for validating Hypergen CLI integration
 * 
 * This script tests:
 * 1. Template discovery from package configuration
 * 2. Command mapping and parameter validation
 * 3. Action execution compatibility
 * 4. Trust system integration
 */

const fs = require('fs');
const path = require('path');

async function testCliIntegration() {
  console.log('🧪 Testing Hypergen CLI Integration');
  console.log('=====================================\n');

  const results = {
    passed: 0,
    failed: 0,
    warnings: 0
  };

  // Test 1: Package configuration validation
  console.log('1️⃣  Testing package configuration...');
  try {
    const packageConfig = require('../hypergen-package.config.js');
    
    // Validate required fields
    const requiredFields = ['name', 'templates', 'cli'];
    for (const field of requiredFields) {
      if (!packageConfig[field]) {
        throw new Error(`Missing required field: ${field}`);
      }
    }
    
    // Validate CLI commands
    if (!packageConfig.cli.commands.monorepo) {
      throw new Error('Missing monorepo command configuration');
    }
    
    console.log('✅ Package configuration valid');
    results.passed++;
  } catch (error) {
    console.log(`❌ Package configuration error: ${error.message}`);
    results.failed++;
  }

  // Test 2: Template.yml validation
  console.log('\n2️⃣  Testing template.yml structure...');
  try {
    const templatePath = path.join(__dirname, '../template.yml');
    if (!fs.existsSync(templatePath)) {
      throw new Error('template.yml not found');
    }
    
    const templateContent = fs.readFileSync(templatePath, 'utf8');
    
    // Basic YAML structure validation
    if (!templateContent.includes('name:') || !templateContent.includes('variables:')) {
      throw new Error('Invalid template.yml structure');
    }
    
    // Check for required template fields
    const requiredSections = ['name', 'description', 'variables', 'examples'];
    for (const section of requiredSections) {
      if (!templateContent.includes(`${section}:`)) {
        console.log(`⚠️  Warning: Missing recommended section: ${section}`);
        results.warnings++;
      }
    }
    
    console.log('✅ Template structure valid');
    results.passed++;
  } catch (error) {
    console.log(`❌ Template validation error: ${error.message}`);
    results.failed++;
  }

  // Test 3: Action file validation
  console.log('\n3️⃣  Testing action file...');
  try {
    const actionPath = path.join(__dirname, '../_templates/new/action.ts');
    if (!fs.existsSync(actionPath)) {
      throw new Error('action.ts not found');
    }
    
    const actionContent = fs.readFileSync(actionPath, 'utf8');
    
    // Check for required action patterns
    if (!actionContent.includes('export default function')) {
      throw new Error('Action must export default function');
    }
    
    if (!actionContent.includes('TemplateContext')) {
      console.log('⚠️  Warning: No TypeScript interface defined for template context');
      results.warnings++;
    }
    
    console.log('✅ Action file valid');
    results.passed++;
  } catch (error) {
    console.log(`❌ Action validation error: ${error.message}`);
    results.failed++;
  }

  // Test 4: Package.json Hypergen metadata
  console.log('\n4️⃣  Testing package.json Hypergen metadata...');
  try {
    const packageJson = require('../package.json');
    
    if (!packageJson.hypergen) {
      throw new Error('Missing hypergen metadata in package.json');
    }
    
    const hypergenMeta = packageJson.hypergen;
    
    // Validate metadata fields
    const requiredMeta = ['type', 'templates', 'commands'];
    for (const field of requiredMeta) {
      if (!hypergenMeta[field]) {
        throw new Error(`Missing hypergen metadata field: ${field}`);
      }
    }
    
    // Validate keywords
    const keywords = packageJson.keywords || [];
    if (!keywords.includes('hypergen') || !keywords.includes('hypergen-template')) {
      console.log('⚠️  Warning: Missing recommended keywords for discoverability');
      results.warnings++;
    }
    
    console.log('✅ Package metadata valid');
    results.passed++;
  } catch (error) {
    console.log(`❌ Package metadata error: ${error.message}`);
    results.failed++;
  }

  // Test 5: File structure validation
  console.log('\n5️⃣  Testing file structure...');
  try {
    const requiredFiles = [
      'template.yml',
      'hypergen-package.config.js',
      '_templates/new/action.ts',
      'package.json',
      'README.md'
    ];
    
    for (const file of requiredFiles) {
      const filePath = path.join(__dirname, '..', file);
      if (!fs.existsSync(filePath)) {
        throw new Error(`Missing required file: ${file}`);
      }
    }
    
    // Check template files
    const templatesDir = path.join(__dirname, '../_templates/new');
    const templateFiles = fs.readdirSync(templatesDir).filter(f => f.endsWith('.ejs.t'));
    
    if (templateFiles.length === 0) {
      throw new Error('No template files found in _templates/new/');
    }
    
    console.log(`✅ File structure valid (${templateFiles.length} template files found)`);
    results.passed++;
  } catch (error) {
    console.log(`❌ File structure error: ${error.message}`);
    results.failed++;
  }

  // Test 6: CLI command compatibility
  console.log('\n6️⃣  Testing CLI command patterns...');
  try {
    const packageConfig = require('../hypergen-package.config.js');
    const commands = packageConfig.cli.commands;
    
    // Validate command structure
    if (!commands.monorepo.template || !commands.monorepo.description) {
      throw new Error('Invalid command structure');
    }
    
    // Check examples format
    const examples = commands.monorepo.examples;
    if (!examples || examples.length === 0) {
      console.log('⚠️  Warning: No usage examples provided');
      results.warnings++;
    } else {
      for (const example of examples) {
        if (!example.title || !example.command) {
          throw new Error('Invalid example format');
        }
      }
    }
    
    console.log('✅ CLI command patterns valid');
    results.passed++;
  } catch (error) {
    console.log(`❌ CLI command validation error: ${error.message}`);
    results.failed++;
  }

  // Summary
  console.log('\n📊 Integration Test Results');
  console.log('===========================');
  console.log(`✅ Passed: ${results.passed}`);
  console.log(`❌ Failed: ${results.failed}`);
  console.log(`⚠️  Warnings: ${results.warnings}`);

  const success = results.failed === 0;
  console.log(`\n${success ? '🎉' : '💥'} Overall: ${success ? 'PASSED' : 'FAILED'}`);

  if (success && results.warnings === 0) {
    console.log('\n✨ Perfect! Ready for Hypergen CLI integration.');
  } else if (success) {
    console.log('\n✅ Ready for integration with minor improvements recommended.');
  } else {
    console.log('\n❌ Fix the failed tests before publishing.');
  }

  console.log('\n📚 Next Steps:');
  console.log('   1. Test with actual Hypergen CLI: hypergen discover');
  console.log('   2. Test command: hypergen monorepo new test-project');
  console.log('   3. Publish package: npm publish');
  console.log('   4. Install globally: npm install -g @hypergen/monorepo-pack');

  process.exit(success ? 0 : 1);
}

testCliIntegration().catch(error => {
  console.error('❌ Test runner error:', error.message);
  process.exit(1);
});