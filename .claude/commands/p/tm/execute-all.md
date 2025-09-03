# Coordinate Multiple TypeScript Expert Agents for Task Master Tasks

This command coordinates multiple TypeScript Expert agents to work on Task Master tasks in parallel, with Code Reviewer agents validating their work.

## Workflow

1. First, analyze all available Task Master tasks and their dependencies
2. Create a coordination plan that maximizes parallel agent execution
3. Launch multiple typescript-expert agents to work on independent tasks simultaneously
4. As each agent completes their work, have a code-reviewer agent verify the implementation
5. If changes are requested, assign them back to the original agent
6. Once approved, commit each agent's work separately using conventional commits

## Steps

### 1. Analyze Current Tasks

- Use `task-master list` to see all tasks
- Identify which tasks can be worked on in parallel (no blocking dependencies)
- Create a coordination todo list to track agent assignments

### 2. Launch Parallel Agents

- For each independent task, launch a typescript-expert agent with:
  - Clear task description from `task-master show <id>`
  - Specific implementation requirements
  - Instructions to mark task complete when done

### 3. Code Review Cycle

- As each typescript-expert completes their task:
  - Launch a code-reviewer agent to verify the implementation
  - If changes needed, create a revision task for the original agent
  - Iterate until approved

### 4. Commit Work

- Once approved, commit each agent's work separately:
  - Use conventional commit format
  - Reference the Task Master task ID in commit message
  - Example: `feat(auth): implement JWT authentication (task 1.2)`

## Example Coordination Todo Structure

```
1. Launch Agent A for Task 1.1 (no dependencies)
2. Launch Agent B for Task 2.1 (no dependencies) 
3. Launch Agent C for Task 3.1 (no dependencies)
4. Review Agent A's work when complete
5. Review Agent B's work when complete
6. Review Agent C's work when complete
7. Handle any revision requests
8. Commit approved work
9. Launch next wave of agents for newly unblocked tasks
```

## Implementation

$PROMPT
