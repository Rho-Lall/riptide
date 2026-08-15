# Requirements Document

## Introduction

Riptide is a lean orchestration framework for one human directing 6-30 concurrent Claude Code agents through structured waves.  

Claude Code terminals handle execution. 

Linear is the coordination bus.

## Glossary

- **Tide**: A collection of independent waves that run in parallel, delivering a milestone. Tides are sequential checkpoints.
- **Wave**: A serial chain of dependent tasks processed by one Claude Code terminal. Tasks within a wave execute in sequence.
- **Task**: A single Linear issue; the atomic unit of work assigned to one wave
- **Agent**: A Claude Code persona (Planner, Builder, Tester, Debugger) that processes tasks sequentially within a wave
- **Module_Map**: A document defining file ownership per wave, ensuring no two waves touch the same file
- **Kill_Switch**: A safety mechanism that freezes agent execution after repeated failures or prolonged stalls
- **Knowledge_Compound**: A pattern or gotcha document captured after a wave merges, stored in docs/solutions/
- **Bootstrap_Script**: A shell script that deploys the Riptide template into a target project
- **Teardown_Script**: A shell script that removes Riptide artifacts from a target project
- **Worktree**: A git worktree providing isolated file system space for each wave
- **Sprint_Command**: A Claude Code command that batch-processes Linear issues in dependency order within a wave
- **Planner_Agent**: The agent persona that reads context and produces a structured plan without writing code
- **Builder_Agent**: The agent persona that implements code from a plan
- **Tester_Agent**: The agent persona that reviews code, runs tests, and flags issues
- **Debugger_Agent**: The agent persona that finds and fixes root causes when something breaks
- **CLAUDE_MD**: The shared rules file loaded by every agent invocation

## Requirements

### Requirement 1: Bootstrap Deployment

**User Story:** As a developer, I want to deploy Riptide into any target project with a single command, so that I can quickly set up the orchestration framework without manual file copying.

#### Acceptance Criteria

1. WHEN the Bootstrap_Script is executed with a target project path, THE Bootstrap_Script SHALL copy all template contents into the target project directory structure
2. WHEN the Bootstrap_Script is executed, THE Bootstrap_Script SHALL create the docs/solutions/ directory in the target project
3. WHEN the Bootstrap_Script is executed on a project that already contains Riptide files, THE Bootstrap_Script SHALL complete without error (idempotent behavior)
4. THE Bootstrap_Script SHALL NOT use symlinks when deploying files into the target project
5. WHEN the Bootstrap_Script completes, THE deployed template SHALL have a total size of less than 15KB

### Requirement 2: Teardown Removal

**User Story:** As a developer, I want to cleanly remove Riptide from a target project, so that I can restore the project to its pre-Riptide state without leftover artifacts.

#### Acceptance Criteria

1. WHEN the Teardown_Script is executed with a target project path, THE Teardown_Script SHALL remove the .claude/ directory from the target project
2. WHEN the Teardown_Script is executed, THE Teardown_Script SHALL remove CLAUDE_MD from the target project root
3. WHEN the Teardown_Script is executed, THE Teardown_Script SHALL remove docs/TECH_SPEC.md, docs/MODULE_MAP.md, and docs/solutions/ from the target project
4. WHEN the Teardown_Script is executed, THE Teardown_Script SHALL leave all project source code untouched

### Requirement 3: Module Map and Wave Isolation

**User Story:** As a developer, I want each wave to have clearly defined file ownership with no cross-wave dependencies, so that concurrent waves never produce file conflicts and can run fully independently.

#### Acceptance Criteria

1. THE Module_Map SHALL assign each file path to exactly one wave within a tide
2. WHEN a wave's task needs to modify a file outside its ownership, THE Agent SHALL freeze execution and report the conflict to Linear
3. THE Module_Map SHALL specify the worktree path, branch name, owned file globs, and serial task list for each wave
4. THE Module_Map SHALL NOT contain dependency declarations between waves (dependencies exist only within a wave as task ordering)

### Requirement 4: Planner Agent Behavior

**User Story:** As a developer, I want the Planner to produce a structured, actionable plan from a Linear issue, so that the Builder can implement without making architecture decisions.

#### Acceptance Criteria

1. WHEN the Planner_Agent receives a Linear issue, THE Planner_Agent SHALL load CLAUDE_MD, TECH_SPEC.md, MODULE_MAP.md, and docs/solutions/ as context
2. WHEN the Planner_Agent produces a plan, THE plan SHALL include explicit file paths to create or modify
3. WHEN the Planner_Agent produces a plan, THE plan SHALL include service function signatures with argument types and return types
4. WHEN the Planner_Agent produces a plan, THE plan SHALL include plain English test cases (one per acceptance criterion)
5. WHEN the Planner_Agent produces a plan, THE plan SHALL include exact verification commands
6. THE Planner_Agent SHALL NOT write or modify any source code files

### Requirement 5: Builder Agent Behavior

**User Story:** As a developer, I want the Builder to implement code strictly from the plan, so that execution is predictable and architecture decisions remain with the Planner.

#### Acceptance Criteria

1. WHEN the Builder_Agent starts work on a task, THE Builder_Agent SHALL read the plan from the corresponding Linear issue before writing any code
2. WHEN the Builder_Agent implements logic code (services, calculations), THE Builder_Agent SHALL write the test first, then the implementation
3. WHEN the Builder_Agent implements declarative code (XML views, manifests, config), THE Builder_Agent SHALL write the code directly without a preceding test
4. THE Builder_Agent SHALL produce atomic commits with one concern per commit
5. THE Builder_Agent SHALL NOT make architecture decisions that deviate from the plan
6. WHEN the Builder_Agent encounters 3 consecutive test failures on the same test, THE Kill_Switch SHALL freeze execution

### Requirement 6: Tester Agent Behavior

**User Story:** As a developer, I want automated code review that checks plan conformance, security, performance, and module isolation, so that issues are caught before merge.

#### Acceptance Criteria

1. WHEN the Tester_Agent reviews code, THE Tester_Agent SHALL verify the implementation matches the plan
2. WHEN the Tester_Agent reviews code, THE Tester_Agent SHALL check for security issues including injection, auth bypass, and data leakage
3. WHEN the Tester_Agent reviews code, THE Tester_Agent SHALL check for performance issues including N+1 queries and unbounded operations
4. WHEN the Tester_Agent reviews code, THE Tester_Agent SHALL check for module isolation violations (cross-boundary imports)
5. WHEN the Tester_Agent finds issues, THE Tester_Agent SHALL post findings to Linear categorized as Critical, High, Medium, or Low severity
6. WHEN a Critical finding is posted, THE Tester_Agent SHALL block the merge

### Requirement 7: Debugger Agent Behavior

**User Story:** As a developer, I want a focused debugging protocol that finds root causes and prevents regressions, so that issues are resolved efficiently.

#### Acceptance Criteria

1. WHEN the Debugger_Agent is invoked, THE Debugger_Agent SHALL follow the protocol: Reproduce, Hypothesize, Test, Fix, Prevent
2. WHEN the Debugger_Agent fixes a non-obvious issue, THE Debugger_Agent SHALL create a gotcha document in docs/solutions/

### Requirement 8: Kill Switch Safety Mechanism

**User Story:** As a developer, I want automatic execution freezing when agents are stuck or failing repeatedly, so that I don't burn tokens on unproductive loops.

#### Acceptance Criteria

1. WHEN an agent encounters 3 consecutive test failures on the same test, THE Kill_Switch SHALL freeze all work in that wave
2. WHEN an agent is stuck without progress for more than 10 minutes, THE Kill_Switch SHALL freeze all work in that wave
3. WHEN the Kill_Switch triggers a freeze, THE Agent SHALL stop all work immediately
4. WHEN the Kill_Switch triggers a freeze, THE Agent SHALL post to Linear: "FROZEN: {reason}. Tried: {list}."
5. WHEN the Kill_Switch triggers a freeze, THE Agent SHALL wait for human intervention before resuming

### Requirement 9: Sprint Command Execution

**User Story:** As a developer, I want a single command that processes all tasks in a wave serially, so that I can launch a wave and let it run autonomously through its dependency chain.

#### Acceptance Criteria

1. WHEN the Sprint_Command is invoked with a list of issue IDs, THE Sprint_Command SHALL process each issue in the order provided (serial — each task depends on the previous)
2. WHEN the Sprint_Command processes an issue, THE Sprint_Command SHALL execute the sequence: plan, build, review, compound
3. WHEN all issues in a wave are complete, THE Sprint_Command SHALL create a pull request for the wave

### Requirement 10: Knowledge Compounding

**User Story:** As a developer, I want patterns and gotchas captured after each wave, so that future agents benefit from prior learnings without excessive documentation overhead.

#### Acceptance Criteria

1. WHEN a new pattern is established during a wave, THE Agent SHALL create a pattern document in docs/solutions/ with fewer than 15 lines
2. WHEN something surprising happens during a wave, THE Agent SHALL create a gotcha document in docs/solutions/ with fewer than 15 lines
3. WHEN the Planner_Agent loads context, THE Planner_Agent SHALL read all documents in docs/solutions/

### Requirement 11: Context Size Constraints

**User Story:** As a developer, I want agent context kept minimal, so that agents operate efficiently without context window bloat.

#### Acceptance Criteria

1. THE CLAUDE_MD file SHALL be less than 3KB in size
2. THE total deployed template SHALL be less than 15KB in size
3. WHEN an agent is invoked, THE total context loaded SHALL be less than 5KB (excluding source files and Linear issue content)

### Requirement 12: Commit and Branch Conventions

**User Story:** As a developer, I want consistent commit messages and branch naming, so that the git history is navigable and traceable to Linear issues.

#### Acceptance Criteria

1. THE Builder_Agent SHALL format commits as: {type}: {description} [{ISSUE-ID}] where type is one of feat, fix, test, refactor, docs, chore
2. WHEN a wave worktree is created, THE branch SHALL be named feature/wave-{N}-{name}
3. THE Builder_Agent SHALL produce one concern per commit

### Requirement 13: CLAUDE.md Shared Rules

**User Story:** As a developer, I want a single concise rules file loaded by every agent, so that all agents share consistent behavioral constraints.

#### Acceptance Criteria

1. THE CLAUDE_MD SHALL instruct agents to read the plan from Linear before starting work
2. THE CLAUDE_MD SHALL instruct agents to stay within their module boundary as defined in Module_Map
3. THE CLAUDE_MD SHALL define the context loading order: CLAUDE_MD, TECH_SPEC.md, MODULE_MAP.md, docs/solutions/, Linear issue
4. THE CLAUDE_MD SHALL define the kill switch rules (3 failures or 10 minutes stuck)
5. THE CLAUDE_MD SHALL instruct agents to check docs/solutions/ for relevant patterns before implementing
6. THE CLAUDE_MD SHALL instruct agents to capture new patterns or gotchas in docs/solutions/ after completing a task

