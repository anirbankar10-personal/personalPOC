name: transcript-to-pr
description: Interactive end-to-end workflow that prompts for a meeting transcript, creates a Linear issue, implements the code changes, creates a matching Git branch, and opens a matching Pull Request.
user_invocable: true
command: /transcript-to-pr
triggers:

"/transcript-to-pr"

"implement from transcript"

"process meeting transcript"

"transcript to PR"
requires:

linear-mcp-or-cli

git-cli

github-cli

Skill: Meeting Transcript to Pull Request (transcript-to-pr)

Overview

You are an interactive, autonomous software engineering agent operating inside VS Code. This skill is user-invocable (via /transcript-to-pr or natural language triggers). Your objective is to prompt the user for a meeting transcript, extract actionable requirements, create a Linear issue, implement the code changes, create a branch, and open a Pull Request—ensuring that the Linear issue name, Git branch name, and PR title all match.

Prerequisites & Tooling Assumptions

Before starting, verify you have access to the following tools (via MCP servers, VS Code extensions, or terminal CLI):

Linear Integration: Linear MCP server, Linear API, or Linear CLI (linear) to create issues and fetch team/project IDs.

Git: Local git CLI for branch management and commits.

GitHub CLI (gh) or GitHub MCP: For creating the Pull Request at the end of the workflow.

Execution Workflow

Follow these steps strictly in order. Do not skip ahead.

Step 1: Prompt for Transcript Upload (Upon Invocation)

When the user invokes this skill, check if a meeting transcript file is already attached or provided in the current message.

If no transcript is attached: Immediately pause and prompt the user:

"Please upload or attach the meeting transcript file (or provide its file path in the workspace) so we can get started."

Wait for the user to upload/attach the file before proceeding to Step 2.

Step 2: Read Transcript & Create Linear Issue

Read & Analyze: Read the uploaded meeting transcript thoroughly and extract:

Problem Statement / Context: Why is this change needed based on the discussion?

Actionable Requirements: Specific features, bug fixes, or refactoring tasks agreed upon.

Acceptance Criteria: Explicit or implied conditions that must be met for completion.

Technical Constraints: Any files, architectures, APIs, or edge cases mentioned.

(Self-Check: If the transcript is critically ambiguous, ask the user for clarification before creating the issue.)

Create the Linear Issue:

Identify the target Linear Team (ask the user if multiple teams exist and no default is configured).

Define a clean, concise Issue Title (e.g., Add rate limiting to user authentication endpoint). Save this exact title, as it must match the branch and PR later.

Create the issue in Linear with the following description template:

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


Capture Identifiers:

Record the returned Linear Issue ID (e.g., ENG-123), the Exact Issue Title, and the Linear Issue URL.

Inform the user that the Linear issue has been created and you are now starting the code implementation.

Step 3: Implement the Code Changes

Workspace Preparation:

Ensure your base working state is up to date with the default branch (main or master) before modifying files.

Code Implementation:

Search the workspace to locate relevant files, components, and tests.

Implement the required code changes directly in the workspace according to the requirements and acceptance criteria from the Linear issue.

Adhere strictly to existing code styles, linting rules, and architectural patterns.

Verification:

Run relevant unit/integration tests, type checks, and linters via the terminal to verify that your changes work as expected and do not introduce regressions.

Add or update tests covering the new changes if applicable.

Step 4: Create a Matching Git Branch

Once the code changes are implemented and verified in the working tree, create and switch to a new Git branch.

Strict Naming Convention: The branch name must match the Linear Issue ID and the slugified (kebab-case) Linear Issue Title:

Format: <linear-issue-id>-<kebab-case-linear-issue-title> (or if Linear provides a gitBranchName property, use that exact string).

Example: If the Linear issue is ENG-123 and the title is Add rate limiting to user authentication endpoint, the branch name must be:

git checkout -b eng-123-add-rate-limiting-to-user-authentication-endpoint


Verify that all your modified and newly created files are carried over cleanly onto this new branch (git status).

Step 5: Commit, Push & Create a Matching Pull Request

Stage & Commit:

Stage all relevant modified/created files (git add <files>).

Commit the changes using the exact Linear Issue ID and Linear Issue Title:

git commit -m "ENG-123: Add rate limiting to user authentication endpoint"


Push Branch:

Push the newly created branch to the remote repository:

git push -u origin <branch-name>


Create the Pull Request:

Use the GitHub CLI (gh pr create) or GitHub MCP tool to open a Pull Request against the base branch (main/master).

Strict Naming Alignment: The PR Title must match the Linear Issue ID + Linear Issue Title (and correspond directly to the branch name):

PR Title Format: [<Linear-Issue-ID>] <Exact Linear Issue Title>

Example: [ENG-123] Add rate limiting to user authentication endpoint

PR Body Template:

## Summary
Implements the requirements discussed in the uploaded meeting transcript.

**Linear Issue:** Fixes ENG-123 ([ENG-123: Add rate limiting to user authentication endpoint](<Linear-Issue-URL>))
**Branch:** `<branch-name>`

## Changes Made
- [Bullet list of key code changes]

## How to Test
- [Steps to verify the changes locally or via automated tests]


Final Summary Output:

Present a clear completion summary to the user showing the aligned names and links:

Linear Issue: [ENG-123] <Linear Issue Title> ([Link])

Git Branch: <branch-name>

Pull Request: [ENG-123] <Linear Issue Title> ([Link])

Modified Files: Brief list of changed files.

Guardrails & Best Practices

Strict Name Matching: Double-check that the Linear Issue Title, the Git Branch slug, and the Pull Request Title all use the exact same naming so Linear's GitHub automation links them automatically.

Never force push (git push --force) or push commits directly to main/master.

Secrets & Credentials: Never hardcode API keys, tokens, or sensitive data mentioned in a transcript into the codebase.