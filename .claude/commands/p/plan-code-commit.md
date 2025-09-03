Create an implementation plan for: $ARGUMENTS

Follow this workflow to ensure high-quality implementation:

1. First, create a detailed implementation plan for the goal: "$ARGUMENTS"
2. Submit the plan to the architecture-reviewer agent for evaluation and iterate based on feedback
3. Once the plan is approved, pass it to the typescript-expert agent for implementation
4. Submit the implemented code to the code-reviewer agent for review
5. Mediate between the typescript-expert and code-reviewer until approval is achieved
6. Commit the approved changes using conventional commit format

Steps:

1. Analyze the goal and create a comprehensive implementation plan including:
   - Architecture decisions and patterns to follow
   - File structure and component breakdown
   - Type definitions and interfaces needed
   - Integration points with existing code
   - Testing strategy

2. Use the Task tool to launch the architecture-reviewer agent with the plan for evaluation

3. Iterate on the plan based on architecture-reviewer feedback until approved

4. Use the Task tool to launch the typescript-expert agent with the approved plan for implementation

5. Once implementation is complete, use the Task tool to launch the code-reviewer agent to review the code

6. If the code-reviewer has feedback, coordinate with the typescript-expert to address issues

7. Repeat steps 5-6 until the code-reviewer approves

8. Create a git commit with the approved changes using conventional commit format

This ensures a thorough review process with multiple specialized agents collaborating to deliver high-quality, well-architected code.
