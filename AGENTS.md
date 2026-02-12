# Agent Workflows with Ratatoskr

This document describes best practices and workflows for using multiple AI agents with Ratatoskr.

## Philosophy

Ratatoskr enables a new way of working with AI coding agents:

- **Parallel Development**: Run multiple agents on different tasks simultaneously
- **Isolation**: Each agent has its own workspace and won't interfere with others
- **Flexibility**: Mix different AI tools (Claude Code, Codex, etc.) as needed
- **Safety**: Main workspace remains clean and stable

## Supported Agents

Currently supported AI CLI tools:

### Claude Code
```bash
agent-worktree <task-id> --claude
# or (default)
agent-worktree <task-id>
```

### Codex CLI
```bash
agent-worktree <task-id> --codex
```

### Future Agents

To add support for other agents, edit the shell functions and add additional cases to the agent selection logic.

## Workflow Patterns

### Pattern 1: Parallel Feature Development

Use when building multiple independent features:

```bash
# Terminal 1: Feature A
agent-worktree feature-auth --claude

# Terminal 2: Feature B
agent-worktree feature-payments --claude

# Terminal 3: Feature C
agent-worktree feature-notifications --codex
```

**Benefits:**
- Features developed in parallel
- No context switching
- Independent testing and validation

### Pattern 2: Test While Building

Use when you want one agent building while another tests:

```bash
# Terminal 1: Build feature
agent-worktree PCT-522 --claude

# Terminal 2: Write tests for existing feature
agent-worktree PCT-520-tests --claude --from PCT-520
```

**Benefits:**
- Tests don't block feature development
- Can test while building
- Quality assurance in parallel

### Pattern 3: Hotfix While Developing

Use when urgent fix needed while working on features:

```bash
# Terminal 1: Ongoing feature work
agent-worktree PCT-522 --claude

# Terminal 2: Urgent hotfix from production
agent-worktree hotfix-auth-bug --claude --from main
```

**Benefits:**
- Don't interrupt feature work
- Fix can be merged immediately
- Clean separation of concerns

### Pattern 4: Refactor + Feature

Use when refactoring while adding features:

```bash
# Terminal 1: Major refactor
agent-worktree refactor-api-layer --claude --from main

# Terminal 2: New feature on current code
agent-worktree PCT-523 --claude
```

**Benefits:**
- Explore refactoring without blocking features
- Compare approaches
- Merge refactor when stable

### Pattern 5: Multi-Agent Collaboration

Use when breaking down large tasks:

```bash
# Terminal 1: Backend API
agent-worktree PCT-522-backend --claude --from main

# Terminal 2: Frontend UI
agent-worktree PCT-522-frontend --claude --from main

# Terminal 3: Tests
agent-worktree PCT-522-tests --codex --from main
```

**Benefits:**
- Divide complex tasks
- Specialized agents per layer
- Faster completion

## Best Practices

### Task Naming

Use clear, consistent task IDs:

```bash
# Good
agent-worktree PCT-522           # Ticket number
agent-worktree hotfix-auth       # Descriptive hotfix
agent-worktree refactor-db       # Clear purpose

# Avoid
agent-worktree test              # Too generic
agent-worktree abc123            # Not meaningful
agent-worktree my-work           # Not specific
```

### Branch Management

**Base branches:**
```bash
# Feature from current branch (default)
agent-worktree PCT-522

# Feature from main
agent-worktree PCT-522 --from main

# Feature from another branch
agent-worktree PCT-522-v2 --from PCT-522
```

**Cleanup:**
- Clean worktrees after merging
- Delete branches that are merged
- Use `--all` for bulk cleanup

### Agent Selection

**When to use Claude Code:**
- Complex refactoring
- Architectural decisions
- Code review and analysis
- Full-stack development

**When to use Codex:**
- Focused implementations
- Test writing
- Quick fixes
- Specific algorithms

### Communication Between Agents

Agents don't directly communicate, but you can coordinate:

1. **Sequential tasks**: Finish one agent, then start next with `--from <branch>`
2. **Independent tasks**: Run in parallel, merge separately
3. **Dependent tasks**: Create first worktree, wait for completion, then create second from that branch

### Monitoring Progress

```bash
# Check all active worktrees
agent-worktree-list

# Check git status across worktrees
git worktree list

# View changes in specific worktree
cd .worktrees/PCT-522
git status
git diff
cd -
```

### Merging Work

After agent completes work:

```bash
# In main workspace
git checkout main
git pull origin main

# Merge the worktree branch
git merge PCT-522

# Clean up
agent-worktree-clean PCT-522
```

## Common Scenarios

### Scenario: Breaking Change Review

```bash
# Terminal 1: Implement breaking change
agent-worktree breaking-api-v2 --claude --from main

# Terminal 2: Update dependent code
agent-worktree update-clients --claude --from breaking-api-v2
```

### Scenario: A/B Testing Implementations

```bash
# Terminal 1: Approach A
agent-worktree solution-a --claude --from main

# Terminal 2: Approach B
agent-worktree solution-b --claude --from main

# Compare, pick winner, delete loser
```

### Scenario: Documentation While Coding

```bash
# Terminal 1: Implement feature
agent-worktree PCT-522 --claude

# Terminal 2: Update docs
agent-worktree docs-update --claude --from main
```

## Troubleshooting Agent Issues

### Agent Stuck or Hung

```bash
# Exit agent with Ctrl+C
# Clean up worktree
agent-worktree-clean <task-id>
```

### Agent Made Mistakes

```bash
# Don't merge the branch
# Clean up worktree
agent-worktree-clean <task-id>
# Delete branch when prompted: Y
```

### Need to Resume Agent Work

Worktree persists after agent exits:

```bash
# Manually enter worktree
cd .worktrees/PCT-522

# Start new agent session
claude
# or
codex

# Exit and return
cd -
```

### Merge Conflicts Between Agents

If two agent branches conflict:

```bash
# Merge one first
git checkout main
git merge PCT-522

# Then merge second (resolve conflicts)
git merge PCT-523
```

## Performance Tips

- **Limit concurrent agents**: 2-4 agents recommended
- **Clean up regularly**: Remove old worktrees
- **Monitor disk space**: Each worktree uses disk space
- **Use appropriate base branch**: Avoid unnecessary divergence

## Future Enhancements

Potential improvements:

- [ ] Auto-cleanup on merge
- [ ] Agent status dashboard
- [ ] Cross-agent messaging
- [ ] Worktree templates
- [ ] Integration with project management tools
- [ ] Support for more AI agents
- [ ] Agent task queuing
- [ ] Parallel merge handling

## See Also

- [README.md](README.md) - Setup and basic usage
- [CLAUDE.md](CLAUDE.md) - Contributing with Claude Code
