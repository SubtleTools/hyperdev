---
to: dprint.json
condition: formatter === 'dprint'
---
{
  "$schema": "https://dprint.dev/schemas/v0.json",
  "projectType": "openSource",
  "incremental": true,
  "lineWidth": 100,
  "indentWidth": 2,
  "useTabs": false,
  "newLineKind": "lf",
  "typescript": {
    "useBraces": "whenNotSingleLine",
    "bracePosition": "sameLineUnlessHanging",
    "singleBodyPosition": "maintain", 
    "nextControlFlowPosition": "sameLine",
    "trailingCommas": "onlyMultiLine",
    "operatorPosition": "nextLine",
    "semiColons": "always",
    "quoteStyle": "alwaysSingle",
    "jsx.quoteStyle": "alwaysSingle",
    "jsx.multiLineParens": "prefer",
    "jsx.bracketPosition": "nextLine",
    "functionExpression.spaceAfterFunctionKeyword": false,
    "functionDeclaration.spaceAfterFunctionKeyword": false,
    "constructor.spaceAfterConstructorKeyword": false,
    "getAccessor.spaceAfterGetKeyword": true,
    "setAccessor.spaceAfterSetKeyword": true,
    "method.spaceBeforeParentheses": false,
    "ignoreNodeCommentText": "dprint-ignore",
    "ignoreFileCommentText": "dprint-ignore-file"
  },
  "json": {
    "indentWidth": 2,
    "lineWidth": 100,
    "useTabs": false,
    "newLineKind": "lf",
    "trailingCommas": "never",
    "ignoreNodeCommentText": "dprint-ignore"
  },
  "markdown": {
    "lineWidth": 80,
    "proseWrap": "preserve",
    "emphasisKind": "asterisks",
    "strongKind": "asterisks",
    "textWrap": "maintain",
    "ignoreDirective": "dprint-ignore",
    "ignoreStartDirective": "dprint-ignore-start",
    "ignoreEndDirective": "dprint-ignore-end"
  },
<% if (packageManager === 'bun') { -%>
  "toml": {
    "indentWidth": 2,
    "lineWidth": 100,
    "useTabs": false,
    "newLineKind": "lf"
  },
<% } -%>
  "dockerfile": {
    "lineWidth": 100,
    "newLineKind": "lf"
  },
  "includes": [
    "**/*.{ts,tsx,js,jsx,mts,mjs,cts,cjs}",
    "**/*.{json,jsonc}",
    "**/*.{md,mdx}",
<% if (packageManager === 'bun') { -%>
    "**/bunfig.toml",
<% } -%>
    "**/Dockerfile*",
    "**/.dockerignore",
    "**/docker-compose*.{yml,yaml}"
  ],
  "excludes": [
    "node_modules/",
    "dist/", 
    "build/",
    ".moon/",
    ".next/",
    ".cache/",
    ".turbo/",
<% if (testFramework === 'jest') { -%>
    "coverage/",
<% } -%>
<% if (testFramework === 'vitest') { -%>
    "coverage/",
<% } -%>
    "*.log",
    "*.min.*",
    "public/**/*",
    "static/**/*",
    "CHANGELOG.md",
    "LICENSE*",
    ".git/",
    ".DS_Store",
    "Thumbs.db"
  ],
  "plugins": [
    "https://plugins.dprint.dev/typescript-0.91.0.wasm",
    "https://plugins.dprint.dev/json-0.19.3.wasm", 
    "https://plugins.dprint.dev/markdown-0.17.2.wasm",
<% if (packageManager === 'bun') { -%>
    "https://plugins.dprint.dev/toml-0.6.2.wasm",
<% } -%>
    "https://plugins.dprint.dev/dockerfile-0.3.2.wasm"
  ]
}