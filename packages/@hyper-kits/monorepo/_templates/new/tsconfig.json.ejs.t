---
to: tsconfig.json
---
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "extends": "tsconfig-moon/tsconfig.json",
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022"],
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "isolatedModules": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "resolveJsonModule": true,
    "allowImportingTsExtensions": false,
<% if (packageManager === 'bun') { -%>
    "types": ["bun-types"],
<% } else { -%>
    "types": ["node"],
<% } -%>
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@packages/*": ["./packages/*"],
<% if (preset !== 'minimal') { -%>
      "@apps/*": ["./apps/*"],
      "@libs/*": ["./libs/*"]
<% } -%>
    }
  },
  "include": [
    "**/*.ts",
    "**/*.tsx", 
    "**/*.js",
    "**/*.jsx",
    "**/*.mts",
    "**/*.cts",
<% if (testFramework === 'vitest') { -%>
    "**/*.test.*",
    "**/*.spec.*"
<% } -%>
  ],
  "exclude": [
    "**/node_modules",
    "**/dist",
    "**/build",
    "**/.moon/cache",
<% if (testFramework === 'jest') { -%>
    "**/coverage"
<% } -%>
  ],
  "references": [
<% if (preset !== 'minimal') { -%>
    { "path": "./apps" },
    { "path": "./libs" },
<% } -%>
    { "path": "./packages" }
  ]
}