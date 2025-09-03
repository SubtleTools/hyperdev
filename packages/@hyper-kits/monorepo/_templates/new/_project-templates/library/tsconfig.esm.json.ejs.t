---
to: packages/<%= name %>/tsconfig.esm.json
condition: projectType === 'library'
---
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "module": "ESNext",
    "outDir": "./esm",
    "declaration": false,
    "declarationMap": false,
    "tsBuildInfoFile": "./esm/.tsbuildinfo"
  }
}