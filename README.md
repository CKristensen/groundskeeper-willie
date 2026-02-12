# Groundskeeper Willie

> Like the primary adult presence on the school grounds, Groundskeeper Willie monitors the playground, maintains the premises, and keeps the kids (AI agents) from interfering with each other while they work.


<img width="512" height="512" alt="Gemini_Generated_Image_knzxzmknzxzmknzx" src="https://github.com/user-attachments/assets/7ca10d96-91e1-4946-8373-11bb167e3ccf" />


## What is Groundskeeper Willie?

Groundskeeper Willie is a set of shell functions that makes it easy to run multiple AI coding agents (Claude Code, Codex, etc.) in parallel without conflicts. It uses Git worktrees to create isolated workspaces, allowing multiple agents to work on different tasks simultaneously.

## Why Git Worktrees?

Traditional workflow problems:
- Can't run multiple agents on different branches simultaneously
- Switching branches disrupts ongoing work
- Risk of agents interfering with each other's changes

Groundskeeper Willie solution:
- Each task gets its own worktree (isolated directory)
- Each worktree has its own branch
- Multiple agents work in parallel without conflicts
- Main workspace remains untouched

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/CKristensen/groundskeeper-willie.git
cd groundskeeper-willie
```

### 2. Source the functions in your shell

#### For Bash/Zsh

```bash
# Add to ~/.bashrc or ~/.zshrc
echo "source $PWD/worktree-agent-functions.sh" >> ~/.bashrc
source ~/.bashrc
```

#### For Fish Shell

```fish
# Add to ~/.config/fish/config.fish
echo "source $PWD/worktree-agent-functions.fish" >> ~/.config/fish/config.fish
source ~/.config/fish/config.fish
```

**Note:** The `$PWD` variable will expand to the current directory, making the installation portable. If you move the repository later, update the path in your shell config file.

## Quick Start

```bash
# Create a worktree and launch Claude Code
agent-worktree PCT-522

# Create a worktree with Codex
agent-worktree PCT-523 --codex

# List all active worktrees
agent-worktree-list

# Clean up when done
agent-worktree-clean PCT-522
```

## Commands

### `agent-worktree <task-id> [options]`

Create a new worktree and launch an agent.

**Options:**
- `--claude` - Use Claude Code (default)
- `--codex` - Use Codex CLI
- `--from <branch>` - Create branch from specified base branch

**Examples:**
```bash
agent-worktree PCT-522
agent-worktree PCT-523 --codex
agent-worktree hotfix-123 --from main
```

**What it does:**
1. Creates a worktree in `.worktrees/<task-id>/`
2. Creates a new branch named after the task ID
3. Launches the specified agent in that worktree
4. Returns you to original directory when agent exits

### `agent-worktree-list`

List all active worktrees.

```bash
agent-worktree-list
```

### `agent-worktree-clean <task-id>`

Remove a worktree and optionally delete its branch.

**Options:**
- `<task-id>` - Clean specific worktree
- `--all` - Clean all worktrees in `.worktrees/`

**Examples:**
```bash
agent-worktree-clean PCT-522
agent-worktree-clean --all
```

### `agent-worktree-help`

Show detailed help message.

```bash
agent-worktree-help
```

## Workflow Example

```bash
# Start three parallel tasks
agent-worktree PCT-522 --claude    # Terminal 1
agent-worktree PCT-523 --codex     # Terminal 2
agent-worktree PCT-524 --claude    # Terminal 3

# Each agent works independently in:
# .worktrees/PCT-522/
# .worktrees/PCT-523/
# .worktrees/PCT-524/

# When done, clean up
agent-worktree-clean PCT-522
agent-worktree-clean PCT-523
agent-worktree-clean PCT-524

# Or clean all at once
agent-worktree-clean --all
```

## How It Works

1. **Worktrees**: Git worktrees create separate working directories that share the same repository
2. **Isolation**: Each worktree has its own branch and working files
3. **Parallel Work**: Multiple agents can work simultaneously without conflicts
4. **Easy Cleanup**: Remove worktrees without affecting main workspace

## Configuration

### Worktree Location

Worktrees are stored in `.worktrees/` inside your repository root. Make sure to add this to your `.gitignore`:

```gitignore
# git worktrees
.worktrees
```

### Branch Naming

Branches are automatically named after the task ID you provide. For example:
- `agent-worktree PCT-522` creates branch `PCT-522`
- `agent-worktree hotfix-auth` creates branch `hotfix-auth`

## Troubleshooting

### "Worktree already exists"

Clean the existing worktree first:
```bash
agent-worktree-clean <task-id>
```

### "Branch already exists"

Either use a different task ID or delete the existing branch:
```bash
git branch -D <branch-name>
```

### Worktree stuck/corrupted

Force remove with git:
```bash
git worktree remove .worktrees/<task-id> --force
```

## Simpsons Reference

**Groundskeeper Willie** is the Scottish custodian and groundskeeper at Springfield Elementary School. He is the primary adult presence on the school grounds, frequently seen monitoring the playground, breaking up fights (or getting into them), and keeping the kids away from his tractor.

Just as Willie maintains the school grounds and manages the chaos of the playground, this tool helps you maintain your repository and manage multiple AI agents working in parallel without letting them interfere with each other.

## License

MIT

## Contributing

See [CLAUDE.md](CLAUDE.md) for instructions on contributing with Claude Code.
