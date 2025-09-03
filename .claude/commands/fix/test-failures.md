Fix test failures systematically using critical analysis and specialized agents.

Arguments: $FOLDER

## Test Failure Resolution

Systematically analyze and fix test failures in your project $FOLDER using critical thinking and test engineering best practices.

### 0. Argument Check

If the user did not specify a folder, ask them in which project they want to run the command showing a numbered list of projects that includes All as an option.

### 1. **Failure Detection & Analysis**

I'll run the test suite to identify all failures:

- If the user selected a specific project, cd into that project folder
- Execute test command (e.g., `bun test`, `npm test`, `yarn test`) in target $FOLDER
- Parse test output to extract failure information
- Categorize failures by type, file, and test suite
- Calculate failure rate and impact metrics

### 2. **Critical Test Analysis Framework**

Before fixing any test, apply these critical thinking principles:

#### **Test Value Assessment**
For each failing test, evaluate:
- **Purpose Clarity**: Does the test have a clear, single responsibility?
- **Business Value**: Does it protect against real regressions that matter to users?
- **Code Coverage**: Does it test meaningful execution paths vs. implementation details?
- **Maintenance Burden**: Is the test brittle and frequently breaking for trivial changes?

#### **Root Cause Classification**
Determine the nature of each failure:

**A. Test Implementation Issues** (Fix the test):
- Flaky tests with timing/async issues
- Tests testing implementation details instead of behavior
- Over-mocked tests that don't reflect real usage
- Tests with incorrect assertions or expectations
- Tests that assume specific environment conditions

**B. Code Quality Issues** (Fix the code):
- Actual bugs exposed by valid test scenarios
- Missing edge case handling
- Incorrect business logic implementation
- API contract violations
- Performance regressions

**C. Design Problems** (Refactor both):
- Tests revealing poor code design/coupling
- Missing abstractions making code hard to test
- Violation of SOLID principles
- Architecture misalignment

#### **Behavioral Contract Analysis**
For each test, identify:
- **What behavior** should be tested (not how it's implemented)
- **What invariants** must be maintained
- **What edge cases** are critical for robustness
- **What failure modes** users actually encounter

### 3. **Intelligent Grouping Strategy**

Group tests for optimal parallel processing:

- **By Feature Domain**: Related functionality together
- **By Failure Type**: Similar root causes grouped
- **By Dependency Chain**: Upstream failures before downstream
- **By Test Suite**: Unit, integration, e2e separated
- **By Risk Level**: Critical path tests prioritized

### 4. **Parallel Resolution**

For each group, launch specialized agents based on failure type:

- **root-cause-debugger**: For complex bugs and system issues
- **react-expert**: For React component and UI test failures
- **typescript-expert**: For type-related test compilation issues
- **general-purpose**: For business logic and integration tests

**CRITICAL**: Launch agents in PARALLEL for maximum efficiency.

Each agent must:
- Only modify files in their assigned group
- Report cross-group dependencies back to coordinator
- Apply the critical analysis framework before making changes
- Prioritize test value and behavioral contracts

### 5. **Test Engineering Best Practices**

Guide agents to follow these principles:

#### **Test Pyramid Compliance**
- **Unit Tests (70%)**: Fast, isolated, testing single units
- **Integration Tests (20%)**: Component interactions
- **E2E Tests (10%)**: Critical user journeys only

#### **Test Quality Standards**
- **AAA Pattern**: Arrange, Act, Assert clearly separated
- **One Concept Per Test**: Single, clear assertion
- **Descriptive Names**: Test name explains the scenario and expected outcome
- **Independence**: Tests can run in any order
- **Deterministic**: Same input always produces same result

#### **Mock Strategy**
- Mock external dependencies, not your own code
- Use real objects for value objects and simple entities
- Prefer stubs/fakes over complex mocks
- Test the interaction, not the mock configuration

#### **Assertion Quality**
- Assert on behavior/outcomes, not implementation
- Use meaningful assertion messages
- Prefer specific assertions over generic ones
- Test both happy path and error conditions

### 6. **Resolution Strategy Priority**

Each agent follows this systematic approach:

1. **Triage Phase**:
   - Classify failure as test issue vs. code issue vs. design problem
   - Assess test value using the framework above
   - Identify behavioral contracts being tested

2. **Quick Wins** (Address first):
   - Fix obvious test implementation bugs (timeouts, race conditions)
   - Update outdated expectations after intentional API changes
   - Remove or improve flaky tests

3. **Infrastructure Errors**:
   - Fix test setup/teardown issues
   - Resolve import/dependency problems
   - Address test environment configuration

4. **Logic Errors**:
   - Fix actual bugs revealed by valid tests
   - Implement missing edge case handling
   - Correct business logic errors

5. **Design Issues**:
   - Refactor tightly coupled code
   - Improve testability through better design
   - Add missing abstractions

### 7. **Progress Tracking & Validation**

Real-time monitoring of resolution:

- Track test files being processed
- Monitor pass/fail rate improvements
- Measure test execution time changes
- Report test coverage impact
- Document test value assessments

### 8. **Verification & Quality Gates**

After all agents complete:

- Re-run full test suite to verify fixes
- Check for new test failures introduced
- Validate test coverage hasn't degraded
- Ensure test execution time is reasonable
- Review test quality improvements

### 9. **Test Debt Management**

Generate actionable recommendations:

- **Tests to Remove**: Low-value, high-maintenance tests
- **Tests to Improve**: High-value tests with quality issues
- **Missing Tests**: Critical scenarios lacking coverage
- **Architecture Improvements**: Design changes to improve testability

### 10. **Documentation & Reporting**

Provide comprehensive summary:

- Failures fixed by category and root cause
- Test value assessment results
- Code quality improvements made
- Test coverage and performance impact
- Recommendations for preventing similar issues

## Critical Decision Framework

When in doubt, ask these questions:

1. **"Does this test prevent a real problem that users would experience?"**
   - If no → Consider removing or simplifying
   - If yes → Ensure it tests the right behavior

2. **"If this code changed tomorrow, should this test fail?"**
   - If testing implementation details → Refactor test
   - If testing behavior contract → Fix the code

3. **"Can a new developer understand what this test validates just by reading it?"**
   - If no → Improve test clarity and naming
   - If yes → Focus on fixing the failure

4. **"Would this test catch regressions in production scenarios?"**
   - If no → Evaluate test value
   - If yes → Ensure test reflects real usage

Remember: **Good tests are investments in code quality. Bad tests are technical debt.**

Result: Robust, valuable test suite with clear behavioral contracts and minimal maintenance burden.