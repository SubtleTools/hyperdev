---
to: .moon/workspace.yml
---
# https://moonrepo.dev/docs/config/workspace
$schema: 'https://moonrepo.dev/schemas/workspace.json'

# Workspace metadata
workspace:
  name: '<%= name %>'
  description: '<%= description %>'

# Project discovery and organization
projects:
  globs:
<% if (preset === 'minimal') { -%>
    - 'packages/*'
<% } else { -%>
    - 'apps/*'
    - 'packages/*' 
    - 'libs/*'
<% } -%>
  sources:
    - './'

# Task runner configuration
runner:
  archivableTargets:
    - 'build'
    - 'pack'
    - 'lint'
    - 'typecheck'
  inheritColorsForPipedTasks: true
  logRunningCommand: true

# Development tools and settings
actionRunner:
  implicitDeps: []
  implicitInputs: []

# Git integration
vcs:
  manager: 'git'
  defaultBranch: 'main'
  remoteCandidates: ['origin', 'upstream']

# Caching and performance
hasher:
  optimization: 'accuracy'

# Extensions and integrations
<% if (includeGitHubActions) { -%>
extensions:
  - 'moon-extension-github-actions'
<% } -%>

# Version control hooks
<% if (setupGitHooks) { -%>
hooks:
  preCommit:
    - 'moon run :lint --affected'
    - 'moon run :typecheck --affected'
<% if (testFramework !== 'none') { -%>
    - 'moon run :test --affected'
<% } -%>
<% } -%>

# Workspace-level constraints
constraints:
  enforceProjectTypeRelationships: true
  taggedProjects: []