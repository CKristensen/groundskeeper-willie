# Ratatoskr

> Like the squirrel messenger of Yggdrasil, Ratatoskr helps you coordinate multiple AI agents working in parallel across different branches of your repository tree.

## What is Ratatoskr?

Ratatoskr is a set of shell functions that makes it easy to run multiple AI coding agents (Claude Code, Codex, etc.) in parallel without conflicts. It uses Git worktrees to create isolated workspaces, allowing multiple agents to work on different tasks simultaneously.

## Why Git Worktrees?

Traditional workflow problems:
- Can't run multiple agents on different branches simultaneously
- Switching branches disrupts ongoing work
- Risk of agents interfering with each other's changes

Ratatoskr solution:
- Each task gets its own worktree (isolated directory)
- Each worktree has its own branch
- Multiple agents work in parallel without conflicts
- Main workspace remains untouched

## Installation

### For Bash/Zsh

```bash
# Add to ~/.bashrc or ~/.zshrc
echo "source ~/Documents/carl/ratatoskr/worktree-agent-functions.sh" >> ~/.bashrc
source ~/.bashrc
```

### For Fish Shell

```fish
# Add to ~/.config/fish/config.fish
echo "source ~/Documents/carl/ratatoskr/worktree-agent-functions.fish" >> ~/.config/fish/config.fish
source ~/.config/fish/config.fish
```

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

## Norse Mythology Reference

**Ratatoskr** (Old Norse: likely "drill-tooth" or "bore-tooth") is a squirrel in Norse mythology who runs up and down Yggdrasil (the world tree) carrying messages between the eagle perched atop and the dragon Níðhöggr beneath the roots.

Just as Ratatoskr coordinates between different realms of Yggdrasil, this tool helps you coordinate multiple AI agents working across different branches of your repository tree.

## License

MIT

## Contributing

See [CLAUDE.md](CLAUDE.md) for instructions on contributing with Claude Code.
