---
name: transcript-to-pr
description: End-to-end workflow that parses a meeting transcript, creates a Linear issue, implements the code changes on a new branch, and opens a Pull Request.
triggers:
  - "implement from transcript"
  - "process meeting transcript"
  - "transcript to PR"
requires:
  - linear-mcp-or-cli
  - git-cli
  - github-cli

user-invocable: true 
---

# Skill: Meeting Transcript to Pull Request (`transcript-to-pr`)

## Overview

You are an autonomous software engineering agent operating inside VS Code. Your objective is to take an attached meeting transcript, extract the actionable engineering requirements, log a tracking issue in Linear, implement the solution in the codebase on a dedicated branch, and submit a Pull Request.

## Prerequisites & Tooling Assumptions

Before starting, verify you have access to the following tools (via MCP servers, VS Code extensions, or terminal CLI):

1. **Linear Integration:** Linear MCP server, Linear API, or Linear CLI (`linear`) to create issues and fetch team/project IDs.
2. **Git:** Local git CLI for branch management and commits.
3. **GitHub CLI (`gh`) or GitHub MCP:** For creating the Pull Request at the end of the workflow.

## Execution Workflow

### Step 1: Analyze the Meeting Transcript

1. Read the attached meeting transcript thoroughly.
2. Extract the following key details:
   * **Problem Statement / Context:** Why is this change needed based on the discussion?
   * **Actionable Requirements:** Specific features, bug fixes, or refactoring tasks agreed upon.
   * **Acceptance Criteria:** Explicit or implied conditions that must be met for the task to be considered complete.
   * **Technical Constraints:** Any files, architectures, APIs, or edge cases mentioned during the call.
3. *Self-Check:* If the transcript contains multiple unrelated epics or is critically ambiguous about what needs to be built, pause and ask the user to clarify which specific task to tackle first before proceeding.

### Step 2: Create a Linear Issue

1. Using your Linear tool (MCP or CLI), identify the target **Team** (and optionally **Project** or **Assignee**). If multiple teams exist and none is specified in workspace rules, ask the user or default to the primary engineering team.
2. Draft and create the Linear issue with the following structure:
   * **Title:** Concise, action-oriented summary (e.g., `feat: Add rate limiting to user authentication endpoint`).
   * **Description:**
     ```markdown
     ## Context (From Meeting Transcript)
     [Brief summary of the discussion and motivation]
     
     ## Requirements
     - [Requirement 1]
     - [Requirement 2]
     
     ## Acceptance Criteria
     - [ ] [Criterion 1]
     - [ ] [Criterion 2]
     
     ## Technical Notes
     [Any specific pointers, architectural notes, or edge cases mentioned in the transcript]
     ```
3. Capture the returned **Issue Identifier** (e.g., `ENG-123`) and **Issue URL**. Display this to the user before moving to Step 3.

### Step 3: Create a New Branch & Implement Changes

1. **Sync Repository:**
   * Ensure the working directory is clean (`git status`). If there are uncommitted changes, ask the user whether to stash them.
   * Checkout the default base branch (usually `main` or `master`) and pull the latest changes (`git pull origin main`).
2. **Create Feature Branch:**
   * Create and checkout a new branch named using the Linear Issue ID:
     ```bash
     git checkout -b <type>/<linear-issue-id>-<short-kebab-description>
     # Example: git checkout -b feat/eng-123-auth-rate-limiting
     ```
3. **Code Implementation:**
   * Search the workspace to locate relevant files, components, and tests.
   * Implement the changes systematically according to the requirements and acceptance criteria extracted in Step 1.
   * Follow the existing code style, linting rules, and architectural patterns of the repository.
4. **Verification:**
   * Run relevant unit/integration tests, type checks, and linters via the terminal to ensure your changes do not break existing functionality.
   * Add or update tests covering the new changes if applicable.

### Step 4: Commit & Create a Pull Request

1. **Stage & Commit:**
   * Stage only the files relevant to the task (`git add <files>`).
   * Commit the changes using Conventional Commits format, referencing the Linear issue:
     ```bash
     git commit -m "feat(scope): short description [ENG-123]"
     ```
2. **Push Branch:**
   * Push the branch to the remote repository:
     ```bash
     git push -u origin <branch-name>
     ```
3. **Open Pull Request:**
   * Use the GitHub CLI (`gh pr create`) or GitHub MCP tool to open a Pull Request against the base branch:
     * **PR Title:** `[ENG-123] <Title of the change>`
     * **PR Body:**
       ```markdown
       ## Summary
       Implements the requirements discussed in the attached meeting transcript.
       
       **Linear Issue:** Fixes ENG-123 ([Link to Linear Issue])
       
       ## Changes Made
       - [Bullet list of key code changes]
       
       ## How to Test
       - [Steps to verify the changes locally or via automated tests]
       ```
4. **Final Output:**
   * Present a concise summary to the user containing:
     * The **Linear Issue Link**
     * The **Branch Name**
     * A summary of **Modified Files**
     * The **Pull Request Link**

## Guardrails & Best Practices

* **Never force push (`git push --force`)** or push directly to `main`/`master`.
* **Secrets & Credentials:** Never hardcode API keys, tokens, or sensitive data mentioned in a transcript into the codebase.
* **Ambiguity Handling:** If a transcript discusses a tentative idea without a clear decision (e.g., *"Maybe we should use Redis, let's check tomorrow"*), note it as an open question in the Linear issue and confirm with the user before writing the code.