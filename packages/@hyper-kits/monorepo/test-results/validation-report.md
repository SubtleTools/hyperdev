# Tool Combination Validation Report

**Generated:** 2025-08-31T09:26:53.611Z
**Total Combinations:** 72
**Valid Combinations:** 45
**Invalid Combinations:** 27
**Success Rate:** 62.5%

## Tool Matrix
- **Package Managers:** bun, npm, yarn, pnpm
- **Linters:** eslint, biome
- **Formatters:** prettier, dprint, biome-integrated
- **Test Frameworks:** vitest, bun-test, jest

## Statistics
### Valid Combinations by Tool
#### Package Managers
- **bun:** 15 combinations
- **npm:** 10 combinations
- **yarn:** 10 combinations
- **pnpm:** 10 combinations

#### Linters
- **eslint:** 18 combinations
- **biome:** 27 combinations

#### Formatters
- **prettier:** 18 combinations
- **dprint:** 18 combinations
- **biome-integrated:** 9 combinations

#### Test Frameworks
- **vitest:** 20 combinations
- **bun-test:** 5 combinations
- **jest:** 20 combinations

## Preset Validation
- **modern-bun:** ✅ Valid
- **traditional-node:** ✅ Valid
- **performance:** ✅ Valid
  - Warning: Using Biome linter with dprint formatter may have configuration overlaps
  - Warning: Using Biome linter with dprint formatter - consider Biome integrated formatter for unified toolchain
- **enterprise:** ✅ Valid
- **minimal:** ✅ Valid

## Recommendations
### Fastest Combinations
- `bun+biome+biome-integrated+bun-test`

### Most Compatible Combinations
- `bun+eslint+prettier+vitest`
- `bun+eslint+prettier+bun-test`
- `bun+eslint+prettier+jest`
- `bun+biome+biome-integrated+vitest`
- `bun+biome+biome-integrated+bun-test`

### Enterprise Recommendations
- `yarn+eslint+prettier+vitest`
- `yarn+eslint+prettier+jest`
- `pnpm+eslint+prettier+vitest`

### Performance Recommendations
- `bun+biome+prettier+vitest`
- `bun+biome+prettier+bun-test`
- `bun+biome+dprint+vitest`

## Invalid Combinations
| Combination | Errors |
|-------------|--------|
| `bun+eslint+biome-integrated+vitest` | Biome integrated formatter can only be used with Biome linter, eslint linter is incompatible with biome-integrated formatter |
| `bun+eslint+biome-integrated+bun-test` | Biome integrated formatter can only be used with Biome linter, eslint linter is incompatible with biome-integrated formatter |
| `bun+eslint+biome-integrated+jest` | Biome integrated formatter can only be used with Biome linter, eslint linter is incompatible with biome-integrated formatter |
| `npm+eslint+prettier+bun-test` | Bun Test requires Bun as the package manager, Bun Test framework requires Bun package manager, bun-test requires one of these package managers: bun |
| `npm+eslint+dprint+bun-test` | Bun Test requires Bun as the package manager, Bun Test framework requires Bun package manager, bun-test requires one of these package managers: bun |
| `npm+eslint+biome-integrated+vitest` | Biome integrated formatter can only be used with Biome linter, eslint linter is incompatible with biome-integrated formatter |
| `npm+eslint+biome-integrated+bun-test` | Bun Test requires Bun as the package manager, Biome integrated formatter can only be used with Biome linter, Bun Test framework requires Bun package manager, eslint linter is incompatible with biome-integrated formatter, bun-test requires one of these package managers: bun |
| `npm+eslint+biome-integrated+jest` | Biome integrated formatter can only be used with Biome linter, eslint linter is incompatible with biome-integrated formatter |
| `npm+biome+prettier+bun-test` | Bun Test requires Bun as the package manager, Bun Test framework requires Bun package manager, bun-test requires one of these package managers: bun |
| `npm+biome+dprint+bun-test` | Bun Test requires Bun as the package manager, Bun Test framework requires Bun package manager, bun-test requires one of these package managers: bun |
| `npm+biome+biome-integrated+bun-test` | Bun Test requires Bun as the package manager, Bun Test framework requires Bun package manager, bun-test requires one of these package managers: bun |
| `yarn+eslint+prettier+bun-test` | Bun Test requires Bun as the package manager, Bun Test framework requires Bun package manager, bun-test requires one of these package managers: bun |
| `yarn+eslint+dprint+bun-test` | Bun Test requires Bun as the package manager, Bun Test framework requires Bun package manager, bun-test requires one of these package managers: bun |
| `yarn+eslint+biome-integrated+vitest` | Biome integrated formatter can only be used with Biome linter, eslint linter is incompatible with biome-integrated formatter |
| `yarn+eslint+biome-integrated+bun-test` | Bun Test requires Bun as the package manager, Biome integrated formatter can only be used with Biome linter, Bun Test framework requires Bun package manager, eslint linter is incompatible with biome-integrated formatter, bun-test requires one of these package managers: bun |
| `yarn+eslint+biome-integrated+jest` | Biome integrated formatter can only be used with Biome linter, eslint linter is incompatible with biome-integrated formatter |
| `yarn+biome+prettier+bun-test` | Bun Test requires Bun as the package manager, Bun Test framework requires Bun package manager, bun-test requires one of these package managers: bun |
| `yarn+biome+dprint+bun-test` | Bun Test requires Bun as the package manager, Bun Test framework requires Bun package manager, bun-test requires one of these package managers: bun |
| `yarn+biome+biome-integrated+bun-test` | Bun Test requires Bun as the package manager, Bun Test framework requires Bun package manager, bun-test requires one of these package managers: bun |
| `pnpm+eslint+prettier+bun-test` | Bun Test requires Bun as the package manager, Bun Test framework requires Bun package manager, bun-test requires one of these package managers: bun |
| `pnpm+eslint+dprint+bun-test` | Bun Test requires Bun as the package manager, Bun Test framework requires Bun package manager, bun-test requires one of these package managers: bun |
| `pnpm+eslint+biome-integrated+vitest` | Biome integrated formatter can only be used with Biome linter, eslint linter is incompatible with biome-integrated formatter |
| `pnpm+eslint+biome-integrated+bun-test` | Bun Test requires Bun as the package manager, Biome integrated formatter can only be used with Biome linter, Bun Test framework requires Bun package manager, eslint linter is incompatible with biome-integrated formatter, bun-test requires one of these package managers: bun |
| `pnpm+eslint+biome-integrated+jest` | Biome integrated formatter can only be used with Biome linter, eslint linter is incompatible with biome-integrated formatter |
| `pnpm+biome+prettier+bun-test` | Bun Test requires Bun as the package manager, Bun Test framework requires Bun package manager, bun-test requires one of these package managers: bun |
| `pnpm+biome+dprint+bun-test` | Bun Test requires Bun as the package manager, Bun Test framework requires Bun package manager, bun-test requires one of these package managers: bun |
| `pnpm+biome+biome-integrated+bun-test` | Bun Test requires Bun as the package manager, Bun Test framework requires Bun package manager, bun-test requires one of these package managers: bun |

## Valid Combinations with Warnings
| Combination | Warnings |
|-------------|----------|
| `bun+eslint+dprint+vitest` | dprint + ESLint combination may have overlapping rules - consider configuration review |
| `bun+eslint+dprint+bun-test` | dprint + ESLint combination may have overlapping rules - consider configuration review |
| `bun+eslint+dprint+jest` | dprint + ESLint combination may have overlapping rules - consider configuration review |
| `bun+biome+prettier+vitest` | Using Biome linter with Prettier formatter reduces performance benefits, Using Biome linter with Prettier formatter - consider Biome integrated formatter for better performance |
| `bun+biome+prettier+bun-test` | Using Biome linter with Prettier formatter reduces performance benefits, Using Biome linter with Prettier formatter - consider Biome integrated formatter for better performance |
| `bun+biome+prettier+jest` | Using Biome linter with Prettier formatter reduces performance benefits, Using Biome linter with Prettier formatter - consider Biome integrated formatter for better performance |
| `bun+biome+dprint+vitest` | Using Biome linter with dprint formatter may have configuration overlaps, Using Biome linter with dprint formatter - consider Biome integrated formatter for unified toolchain |
| `bun+biome+dprint+bun-test` | Using Biome linter with dprint formatter may have configuration overlaps, Using Biome linter with dprint formatter - consider Biome integrated formatter for unified toolchain |
| `bun+biome+dprint+jest` | Using Biome linter with dprint formatter may have configuration overlaps, Using Biome linter with dprint formatter - consider Biome integrated formatter for unified toolchain |
| `npm+eslint+dprint+vitest` | dprint + ESLint combination may have overlapping rules - consider configuration review |
| `npm+eslint+dprint+jest` | dprint + ESLint combination may have overlapping rules - consider configuration review |
| `npm+biome+prettier+vitest` | Using Biome linter with Prettier formatter reduces performance benefits, Using Biome linter with Prettier formatter - consider Biome integrated formatter for better performance |
| `npm+biome+prettier+jest` | Using Biome linter with Prettier formatter reduces performance benefits, Using Biome linter with Prettier formatter - consider Biome integrated formatter for better performance |
| `npm+biome+dprint+vitest` | Using Biome linter with dprint formatter may have configuration overlaps, Using Biome linter with dprint formatter - consider Biome integrated formatter for unified toolchain |
| `npm+biome+dprint+jest` | Using Biome linter with dprint formatter may have configuration overlaps, Using Biome linter with dprint formatter - consider Biome integrated formatter for unified toolchain |
| `yarn+eslint+dprint+vitest` | dprint + ESLint combination may have overlapping rules - consider configuration review |
| `yarn+eslint+dprint+jest` | dprint + ESLint combination may have overlapping rules - consider configuration review |
| `yarn+biome+prettier+vitest` | Using Biome linter with Prettier formatter reduces performance benefits, Using Biome linter with Prettier formatter - consider Biome integrated formatter for better performance |
| `yarn+biome+prettier+jest` | Using Biome linter with Prettier formatter reduces performance benefits, Using Biome linter with Prettier formatter - consider Biome integrated formatter for better performance |
| `yarn+biome+dprint+vitest` | Using Biome linter with dprint formatter may have configuration overlaps, Using Biome linter with dprint formatter - consider Biome integrated formatter for unified toolchain |
| `yarn+biome+dprint+jest` | Using Biome linter with dprint formatter may have configuration overlaps, Using Biome linter with dprint formatter - consider Biome integrated formatter for unified toolchain |
| `pnpm+eslint+dprint+vitest` | dprint + ESLint combination may have overlapping rules - consider configuration review |
| `pnpm+eslint+dprint+jest` | dprint + ESLint combination may have overlapping rules - consider configuration review |
| `pnpm+biome+prettier+vitest` | Using Biome linter with Prettier formatter reduces performance benefits, Using Biome linter with Prettier formatter - consider Biome integrated formatter for better performance |
| `pnpm+biome+prettier+jest` | Using Biome linter with Prettier formatter reduces performance benefits, Using Biome linter with Prettier formatter - consider Biome integrated formatter for better performance |
| `pnpm+biome+dprint+vitest` | Using Biome linter with dprint formatter may have configuration overlaps, Using Biome linter with dprint formatter - consider Biome integrated formatter for unified toolchain |
| `pnpm+biome+dprint+jest` | Using Biome linter with dprint formatter may have configuration overlaps, Using Biome linter with dprint formatter - consider Biome integrated formatter for unified toolchain |