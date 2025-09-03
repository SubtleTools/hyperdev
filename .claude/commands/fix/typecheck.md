Fix TypeScript errors in parallel using typescript-error-resolver agents.

Arguments: $FOLDER

## TypeScript Error Resolution

Systematically fix TypeScript errors in your project $FOLDER.

### 0. Argument Check

If the user did not specify a folder, ask them in which project they want to run the command showing a numbered list of projects that includes All as an option.

### 1. **Error Detection**

I'll run TypeScript compiler to identify all errors:

- If the user selected a specific project, cd into that project folder
- Execute `bun tsc --noEmit` in target $FOLDER
- Parse and categorize error types
- Filter files within specified directory
- Group errors by file and type

### 2. **Intelligent Grouping**

Files are grouped for optimal parallel processing:

- **Group by module**: Related files together
- **Group by error type**: Similar errors fixed consistently
- **Avoid conflicts**: Separate interdependent files
- **Balance workload**: Even distribution across agents

### 3. **Parallel Resolution**

For each group you create, launch one typescript-error-resolver agent.
Make it explicit to them that they must only modify the files specified in their group.
If their files have errors that require fixes in other files, they must report that back to you.

This is PARAMOUNT for success: you MUST launch agents in PARALLEL

### 4. **Resolution Strategy**

Each agent follows systematic approach:

- Fix infrastructure errors first (types, imports)
- Address cascading errors next
- Handle isolated errors last
- Verify fixes don't introduce new errors

### 5. **Progress Tracking**

Real-time updates on resolution:

- Files being processed
- Errors fixed per group
- Remaining error count
- Estimated completion time

### 6. **Verification**

After all agents complete:

- Re-run `bun tsc --noEmit` to verify
- If there are errors that were not resolved due to cross-group dependencies, go back to step 2
- Report any remaining errors
- Suggest manual intervention if needed
- Generate fix summary report

Result: Clean TypeScript compilation across entire folder.
