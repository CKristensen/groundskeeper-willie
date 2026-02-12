# Groundskeeper Willie

> Like the primary adult presence on the school grounds, Groundskeeper Willie monitors the playground, maintains the premises, and keeps the kids (AI agents) from interfering with each other while they work.


<img width="512" height="512" alt="Gemini_Generated_Image_knzxzmknzxzmknzx" src="https://github.com/user-attachments/assets/7ca10d96-91e1-4946-8373-11bb167e3ccf" />


## What is Groundskeeper Willie?

Groundskeeper Willie is a set of shell functions that makes it easy to run multiple Claude Code agents in parallel without conflicts. It uses Git worktrees to create isolated workspaces, allowing multiple agents to work on different tasks simultaneously.

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

One line. That's all you need:

```bash
curl -fsSL https://raw.githubusercontent.com/CKristensen/groundskeeper-willie/master/install.sh | bash
```

This will:
- Detect your shell (bash, zsh, or fish)
- Download the appropriate functions file
- Update your shell config automatically
- Create a backup of your config file

After installation, restart your shell or run:
```bash
source ~/.bashrc  # or ~/.zshrc or ~/.config/fish/config.fish
```

## Quick Start

```bash
# Create a worktree and launch Claude Code
willie PCT-522

# List all active worktrees
willie --status

# Clean up when done
willie --clean PCT-522
```

## Commands

### `willie <task-id> [--from <branch>]`

Create a new worktree and launch Claude Code.

**Examples:**
```bash
willie PCT-522
willie hotfix-123 --from main
```

**What it does:**
1. Creates a worktree in `.worktrees/<task-id>/`
2. Creates a new branch named after the task ID
3. Launches Claude Code in that worktree
4. Returns you to original directory when Claude Code exits

### `willie --status`

List all active worktrees.

```bash
willie --status
```

### `willie --clean <task-id>`

Remove a worktree and optionally delete its branch.

**Examples:**
```bash
willie --clean PCT-522
willie --clean --all  # Remove all worktrees
```

### `willie --help`

Show detailed help message.

```bash
willie --help
```

## Workflow Example

```bash
# Start three parallel tasks
willie PCT-522    # Terminal 1
willie PCT-523    # Terminal 2
willie PCT-524    # Terminal 3

# Each agent works independently in:
# .worktrees/PCT-522/
# .worktrees/PCT-523/
# .worktrees/PCT-524/

# Check status of all worktrees
willie --status

# When done, clean up
willie --clean PCT-522
willie --clean PCT-523
willie --clean PCT-524

# Or clean all at once
willie --clean --all
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
- `willie PCT-522` creates branch `PCT-522`
- `willie hotfix-auth` creates branch `hotfix-auth`

## Troubleshooting

### "Worktree already exists"

Clean the existing worktree first:
```bash
willie --clean <task-id>
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
