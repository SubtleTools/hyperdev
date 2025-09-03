---
to: bunfig.toml
condition: testFramework === 'bun-test' && packageManager === 'bun'
---
# Bun configuration file
# https://bun.sh/docs/runtime/bunfig

[install]
# Configure package installation behavior
<% if (preset === 'minimal') { -%>
frozenLockfile = true
<% } else { -%>
frozenLockfile = false
<% } -%>
production = false
optional = true
dev = true
peer = true
exact = false
globalBinDir = "~/.bun/bin"
globalDir = "~/.bun/install/global"
registry = "https://registry.npmjs.org/"
scopes = {}
cache = "~/.bun/install/cache"

[install.lockfile]
# Lockfile behavior
save = true
print = "yarn"

[test]
# Test runner configuration
# https://bun.sh/docs/test/writing
root = "."
preload = []
coverage = true
coverageThreshold = 50
coverageReporter = ["text", "json", "html"]
coverageDir = "./coverage"

# Test file patterns
testFilePatterns = [
  "**/*.test.{js,jsx,ts,tsx}",
  "**/*.spec.{js,jsx,ts,tsx}",
  "**/test/**/*.{js,jsx,ts,tsx}",
  "**/__tests__/**/*.{js,jsx,ts,tsx}"
]

# Files to ignore during testing
testPathIgnorePatterns = [
  "node_modules/",
  "dist/",
  "build/", 
  ".moon/",
  ".next/",
  ".cache/",
  ".turbo/",
  "coverage/",
  "*.config.{js,ts,mjs,cjs}",
  "*.d.ts"
]

# Test timeout (milliseconds)
timeout = 5000

# Bail on first test failure
bail = false

# Test environment setup
setupFilesAfterEnv = []

[dev]
# Development server configuration (if using Bun as dev server)
port = 3000
hostname = "localhost"
origin = "http://localhost:3000"

[run]
# Script runner behavior
bun = true
silent = false
shell = "/bin/bash"

# Environment variables for scripts
env = "development"

[macros]
# Custom macros (advanced usage)

[loader]
# Custom file loaders
".env" = "text"
".md" = "text"
".txt" = "text"

[define]
# Compile-time constants
NODE_ENV = "development"
<% if (testFramework === 'bun-test') { -%>
TEST_ENV = "test"
<% } -%>

[external]
# External dependencies to exclude from bundling
"@moonrepo/cli" = true