# Running multiple AI agents at once with Groundskeeper Willie

## The serial development bottleneck

You're working on a project. You need to add authentication, fix a login bug, refactor the API, and update docs. You have Claude Code or another AI assistant.

But here's the problem: you can only work on one thing at a time.

While the agent implements authentication, the bug fix waits. While fixing the bug, the refactoring sits idle. One agent, one task, one branch. Everything happens in sequence.

This is kind of ridiculous when you think about it.

## What Groundskeeper Willie does

Groundskeeper Willie is named after the Scottish custodian from The Simpsons who maintains the school grounds and keeps the kids from interfering with each other. Like Willie monitoring the playground, this tool helps you manage multiple AI agents working in parallel without conflicts.

### Quick Git worktrees primer

Git worktrees let you check out multiple branches simultaneously in different directories. Instead of switching branches and stashing changes, you just have multiple working copies of your repo.

```
Your Repository
├── .worktrees/
│   ├── feature-auth/      (branch: feature-auth)
│   ├── bugfix-login/      (branch: bugfix-login)
│   ├── refactor-api/      (branch: refactor-api)
│   └── docs-update/       (branch: docs-update)
└── main/                  (branch: main)
```

Groundskeeper Willie adds agent lifecycle management on top of this. Create a worktree, launch an agent, clean up when done.

## How it works

### Starting parallel work

```bash
# Terminal 1: Start agent on authentication feature
agent-worktree feature-auth --claude

# Terminal 2: Fix that critical bug
agent-worktree bugfix-login --claude

# Terminal 3: Refactor the API
agent-worktree refactor-api --claude

# Terminal 4: Update documentation
agent-worktree docs-update --codex
```

Each command creates a worktree, creates a branch with the same name, and launches your agent. When the agent exits, you're back in your original directory. The worktree and branch stick around for you to review.

### Working in isolation

Each agent has its own filesystem and branch. Changes in one worktree don't affect the others. No merge conflicts during development. Actual concurrent work.

You can even use different agents for different tasks—Claude for one feature, Codex for another.

### Review and merge

```bash
# Check what's been done
agent-worktree-list

# Review each worktree
cd .worktrees/feature-auth
git diff main
git log

# Merge when ready
git checkout main
git merge feature-auth

# Clean up
agent-worktree-clean feature-auth --delete-branch
```

## Combining this with Ralph loops

[Ralph](https://github.com/anthropics/ralph) is an autonomous agent system that executes multi-step tasks. You give it a Product Requirements Document, it breaks down the work, and executes systematically.

Running Ralph loops in parallel is where things get interesting.

### Parallel Ralph pattern

Say you're building an e-commerce platform. You have three features to implement: user authentication, product catalog, and shopping cart.

**Standard approach:** Run Ralph three times sequentially. 30 minutes per feature = 90 minutes total.

**Parallel approach:**

```bash
# Terminal 1
agent-worktree user-auth --claude
# Inside: Use /prd to generate authentication PRD
# Ralph creates prd.json and starts working

# Terminal 2
agent-worktree product-catalog --claude
# Inside: Use /prd to generate catalog PRD
# Ralph creates prd.json and starts working

# Terminal 3
agent-worktree shopping-cart --claude
# Inside: Use /prd to generate cart PRD
# Ralph creates prd.json and starts working
```

Each Ralph instance reads its `prd.json`, breaks down requirements, implements features, and creates commits. All three run at the same time. 30 minutes total (plus some integration time at the end).

The math is simple but the implications are weird. You're basically parallelizing AI work the same way you'd parallelize any other computation.

### Real example walkthrough

```bash
# Feature 1: User Authentication (independent)
agent-worktree user-auth --claude
> /prd
> "Implement user authentication with email/password, OAuth, and JWT tokens"
# Ralph loop starts, implements auth

# Feature 2: Product Catalog (independent)
agent-worktree product-catalog --claude
> /prd
> "Create product catalog with categories, search, and filtering"
# Ralph loop starts, implements catalog

# Feature 3: Shopping Cart (depends on auth + catalog)
agent-worktree shopping-cart --claude
> /prd
> "Implement shopping cart with add/remove, quantity updates, and checkout"
# Ralph loop starts, might reference other branches
```

When they finish, review each worktree, run tests, merge in dependency order, clean up.

## Why this matters

**Time compression.** Three 30-minute tasks take 30 minutes instead of 90.

**Better resource usage.** While one agent waits for an API response, the others are working. You're maximizing throughput.

**Mental clarity.** Each worktree is focused on one problem. No context switching, no stashing, no mental overhead. Want to see what's being worked on? Run `agent-worktree-list`.

**Risk isolation.** Experiments in one worktree don't touch the others. If an approach doesn't work, abandon the worktree. No `git stash` gymnastics.

**Agent specialization.** Use Claude for complex reasoning, Codex for boilerplate, other agents for specific domains. Match the tool to the task.

## When to use this (and when not to)

**Good candidates for parallel work:**

- Independent features with minimal shared code
- Bug fixes in different parts of the codebase
- Documentation updates happening alongside feature work
- Refactoring separate modules
- Trying multiple approaches to the same problem

**Bad candidates:**

- Features with heavy interdependencies
- Changes to the same files
- Database schema migrations (need coordination)
- API contract changes that ripple through the system

If your tasks need to talk to each other constantly, parallelism creates more problems than it solves.

## Coordination strategies

Some things I've found useful:

**Start independent.** Begin with tasks that don't overlap. Get those merged first.

**Plan integration points.** Before spinning up agents, sketch out how the pieces fit together. You don't need a detailed design doc, just a mental model.

**Check in periodically.** Every 30 minutes or so, glance at what each agent has done. Catch issues early.

**Merge strategically.** Foundation work before dependent features. Auth before shopping cart.

**Be explicit about dependencies.** If an agent needs to reference another branch, tell it which one.

### Ralph-specific tips

**Clear PRDs.** Each PRD should be self-contained. Don't rely on implicit context.

**Define boundaries.** Specify what each agent implements. Overlap creates merge conflicts.

**Shared interfaces.** If features interact, define the interface upfront. Let each agent implement its side independently.

**Independent tests.** Each feature should have tests that run in isolation.

**Integration tests last.** Merge everything, then test how it works together.

## Getting started

### Installation

```bash
# Clone the repo
git clone https://github.com/CKristensen/groundskeeper-willie.git
cd groundskeeper-willie

# Bash/Zsh
echo "source $PWD/worktree-agent-functions.sh" >> ~/.bashrc
source ~/.bashrc

# Fish
echo "source $PWD/worktree-agent-functions.fish" >> ~/.config/fish/config.fish
source ~/.config/fish/config.fish
```

### First parallel workflow

```bash
# Go to your project
cd my-project

# Start agent on feature A
agent-worktree feature-a --claude
# Work on feature A
# Exit when done

# Start agent on feature B
agent-worktree feature-b --claude
# Work on feature B
# Exit when done

# Review what was created
agent-worktree-list

# Merge
git checkout main
git merge feature-a
git merge feature-b

# Clean up
agent-worktree-clean --all
```

## What I think this means

I keep coming back to this: AI development doesn't have to be sequential.

We treat AI agents like assistants who need constant supervision, so we work with one at a time. But nothing about the technology requires that. You can run multiple agents the same way you run multiple processes.

Groundskeeper Willie is just Git worktrees plus some shell functions. The interesting part is the mental shift—decomposing projects into parallel workstreams instead of sequential tasks.

Combined with autonomous systems like Ralph, you start to see a different development model. Break a project into independent pieces. Launch agents on each piece. Let them work concurrently. Integrate at the end.

Like Willie keeping order on the school grounds, this tool maintains your repository while letting multiple agents work independently. They each get their own space, and Willie makes sure they don't interfere with each other.

---

**Links:**
- [Groundskeeper Willie GitHub Repository](https://github.com/CKristensen/groundskeeper-willie)
- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [Ralph Agent System](https://github.com/anthropics/ralph)
- [Getting Started Guide](./README.md)
- [Agent Workflow Patterns](./AGENTS.md)

Got questions? Open an issue or submit a PR.
