import { execSync } from 'child_process';
import { existsSync } from 'fs';
import path from 'path';

interface TemplateContext {
  name: string;
  packageManager: string;
  initializeGit: boolean;
  setupGitHooks: boolean;
  // Project template context
  projectType?: 'library' | 'cli';
  projectName?: string;
  cliName?: string;
  packageScope?: string;
  description?: string;
  author?: string;
  license?: string;
  homepage?: string;
  repository?: string;
  bugs?: string;
  keywords?: string;
  // Tool selections
  linter?: string;
  formatter?: string;
  testFramework?: string;
}

export default function(context: TemplateContext) {
  const { name, packageManager, initializeGit, setupGitHooks, projectType, projectName } = context;
  
  if (projectType && projectName) {
    console.log(`📦 Adding ${projectType} project: ${projectName} to monorepo`);
  } else {
    console.log(`🌚 Setting up Moon monorepo: ${name}`);
  }
  
  // Initialize git repository if requested
  if (initializeGit && !existsSync('.git')) {
    console.log('📦 Initializing Git repository...');
    try {
      execSync('git init', { stdio: 'inherit' });
      execSync('git add .', { stdio: 'inherit' });
      execSync('git commit -m "feat: initial Moon monorepo setup"', { stdio: 'inherit' });
      console.log('✅ Git repository initialized');
    } catch (error) {
      console.warn('⚠️  Could not initialize Git repository:', error);
    }
  }
  
  // Install dependencies
  console.log(`📦 Installing dependencies with ${packageManager}...`);
  try {
    const installCmd = packageManager === 'bun' ? 'bun install' :
                      packageManager === 'pnpm' ? 'pnpm install' :
                      packageManager === 'yarn' ? 'yarn install' : 'npm install';
    
    execSync(installCmd, { stdio: 'inherit' });
    console.log('✅ Dependencies installed');
  } catch (error) {
    console.warn('⚠️  Could not install dependencies:', error);
    console.log(`Please run '${packageManager === 'bun' ? 'bun install' : packageManager + ' install'}' manually`);
  }
  
  // Setup Git hooks if requested
  if (setupGitHooks && existsSync('.git')) {
    console.log('🪝 Setting up Git hooks...');
    try {
      const huskyInstall = packageManager === 'bun' ? 'bunx husky install' :
                          packageManager === 'pnpm' ? 'pnpm exec husky install' :
                          packageManager === 'yarn' ? 'yarn dlx husky install' : 'npx husky install';
      
      execSync(huskyInstall, { stdio: 'inherit' });
      console.log('✅ Git hooks setup complete');
    } catch (error) {
      console.warn('⚠️  Could not setup Git hooks:', error);
    }
  }
  
  // Initialize Moon workspace
  console.log('🌚 Initializing Moon workspace...');
  try {
    execSync('moon sync', { stdio: 'inherit' });
    console.log('✅ Moon workspace synchronized');
  } catch (error) {
    console.warn('⚠️  Could not sync Moon workspace:', error);
    console.log('Please run "moon sync" manually after installation');
  }
  
  if (projectType && projectName) {
    console.log(`\n🎉 ${projectType} project '${projectName}' added successfully!`);
    console.log('\n📖 Next steps:');
    const projectPath = projectType === 'library' ? `packages/${projectName}` : `apps/${projectName}`;
    console.log(`   cd ${projectPath}`);
    console.log('   moon run build      # Build the project');
    console.log('   moon run test       # Run tests');
    if (projectType === 'cli') {
      console.log('   moon run dev:start  # Run in development mode');
      console.log('   moon run install    # Link CLI globally');
    } else {
      console.log('   moon run dev        # Build in watch mode');
    }
  } else {
    console.log('\n🎉 Moon monorepo setup complete!');
    console.log('\n📖 Quick start:');
    console.log(`   cd ${name}`);
    console.log('   moon run :build     # Build all packages');
    console.log('   moon run :test      # Run all tests');
    console.log('   moon run :dev       # Start development mode');
  }
  console.log('\n📚 Learn more: https://moonrepo.dev/docs');
}