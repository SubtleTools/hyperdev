---
to: biome.json
condition: linter === 'biome'
---
{
  "$schema": "https://biomejs.dev/schemas/1.5.3/schema.json",
  "vcs": {
    "enabled": true,
    "clientKind": "git",
    "useIgnoreFile": true
  },
  "organizeImports": {
    "enabled": true
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "complexity": {
        "noExtraBooleanCast": "error",
        "noMultipleSpacesInRegularExpressionLiterals": "error",
        "noUselessCatch": "error",
        "noUselessTypeConstraint": "error"
      },
      "correctness": {
        "noConstAssign": "error",
        "noConstantCondition": "error",
        "noEmptyCharacterClassInRegex": "error",
        "noEmptyPattern": "error",
        "noGlobalObjectCalls": "error",
        "noInvalidConstructorSuper": "error",
        "noInvalidNewBuiltin": "error",
        "noNonoctalDecimalEscape": "error",
        "noPrecisionLoss": "error",
        "noSelfAssign": "error",
        "noSetterReturn": "error",
        "noSwitchDeclarations": "error",
        "noUndeclaredVariables": "error",
        "noUnreachable": "error",
        "noUnreachableSuper": "error",
        "useIsNan": "error"
      },
      "style": {
        "useTemplate": "error",
        "useConst": "error",
        "noVar": "error",
        "useBlockStatements": "error",
        "useShorthandFunctionType": "error"
      },
      "suspicious": {
        "noExplicitAny": "warn",
        "noFunctionAssign": "error",
        "noImportAssign": "error",
        "noRedundantUseStrict": "error",
        "noShadowRestrictedNames": "error"
      },
      "nursery": {
        "noConsole": "off"
      }
    },
    "ignore": [
      "node_modules/",
      "dist/",
      "build/",
      ".moon/",
<% if (testFramework === 'jest') { -%>
      "coverage/",
<% } -%>
<% if (testFramework === 'vitest') { -%>
      "coverage/",
<% } -%>
      "*.config.js",
      "*.config.mjs",
      "*.d.ts",
      ".next/",
      ".cache/",
      "public/",
      "static/"
    ]
  },
<% if (formatter === 'biome-integrated') { -%>
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100,
    "lineEnding": "lf",
    "formatWithErrors": false,
    "ignore": [
      "node_modules/",
      "dist/",
      "build/",
      ".moon/",
      "*.min.js",
      "*.min.css",
      "CHANGELOG.md",
      "LICENSE*"
    ]
  },
<% } -%>
  "javascript": {
    "formatter": {
<% if (formatter === 'biome-integrated') { -%>
      "enabled": true,
      "quoteStyle": "single",
      "jsxQuoteStyle": "single",
      "quoteProperties": "asNeeded",
      "trailingComma": "es5",
      "semicolons": "always",
      "arrowParentheses": "asNeeded",
      "bracketSpacing": true,
      "bracketSameLine": false,
      "attributePosition": "auto"
<% } else { -%>
      "enabled": false
<% } -%>
    },
    "parser": {
      "unsafeParameterDecoratorsEnabled": true
    },
    "globals": [
<% if (testFramework === 'jest') { -%>
      "jest",
      "describe",
      "it",
      "expect",
      "beforeAll",
      "afterAll",
      "beforeEach",
      "afterEach"
<% } else if (testFramework === 'vitest') { -%>
      "vi",
      "describe",
      "it",
      "expect",
      "beforeAll",
      "afterAll",
      "beforeEach",
      "afterEach",
      "test"
<% } else if (testFramework === 'bun-test') { -%>
      "Bun",
      "describe",
      "it",
      "expect",
      "beforeAll",
      "afterAll",
      "beforeEach",
      "afterEach",
      "test"
<% } -%>
    ]
  },
  "typescript": {
    "formatter": {
<% if (formatter === 'biome-integrated') { -%>
      "enabled": true,
      "quoteStyle": "single",
      "jsxQuoteStyle": "single",
      "quoteProperties": "asNeeded",
      "trailingComma": "es5",
      "semicolons": "always",
      "arrowParentheses": "asNeeded",
      "bracketSpacing": true,
      "bracketSameLine": false
<% } else { -%>
      "enabled": false
<% } -%>
    }
  },
  "json": {
    "formatter": {
<% if (formatter === 'biome-integrated') { -%>
      "enabled": true,
      "indentStyle": "space",
      "indentWidth": 2,
      "lineWidth": 100,
      "trailingCommas": "none"
<% } else { -%>
      "enabled": false
<% } -%>
    }
  },
  "css": {
    "formatter": {
<% if (formatter === 'biome-integrated') { -%>
      "enabled": true,
      "indentStyle": "space",
      "indentWidth": 2,
      "lineWidth": 100
<% } else { -%>
      "enabled": false
<% } -%>
    }
  },
  "files": {
    "include": [
      "**/*.js",
      "**/*.jsx", 
      "**/*.ts",
      "**/*.tsx",
      "**/*.json",
      "**/*.jsonc",
      "**/*.vue",
      "**/*.astro",
      "**/*.svelte"
    ],
    "ignore": [
      "node_modules/",
      "dist/",
      "build/",
      ".moon/",
      ".next/",
      ".cache/",
      ".turbo/",
      "*.log",
      "*.min.*",
      "public/**/*",
      "static/**/*"
    ],
    "ignoreUnknown": true
  }
}