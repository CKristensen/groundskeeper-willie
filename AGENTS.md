# Agent Workflows with Groundskeeper Willie

This document describes best practices and workflows for using multiple AI agents with Groundskeeper Willie.

## Philosophy

Groundskeeper Willie enables a new way of working with AI coding agents:

- **Parallel Development**: Run multiple agents on different tasks simultaneously
- **Isolation**: Each agent has its own workspace and won't interfere with others
- **Flexibility**: Mix different AI tools (Claude Code, Codex, etc.) as needed
- **Safety**: Main workspace remains clean and stable

## Supported Agents

Currently supported AI CLI tools:

### Claude Code

By default, Groundskeeper Willie launches Claude Code:

```bash
willie <task-id>
```

### Future Agents

The current version focuses on Claude Code. Support for additional agents (Codex, Cursor, Aider, etc.) can be added by extending the shell functions.

## Workflow Patterns

### Pattern 1: Parallel Feature Development

Use when building multiple independent features:

```bash
# Terminal 1: Feature A
willie feature-auth

# Terminal 2: Feature B
willie feature-payments

# Terminal 3: Feature C
willie feature-notifications
```

**Benefits:**
- Features developed in parallel
- No context switching
- Independent testing and validation

### Pattern 2: Test While Building

Use when you want one agent building while another tests:

```bash
# Terminal 1: Build feature
willie PCT-522

# Terminal 2: Write tests for existing feature
willie PCT-520-tests --from PCT-520
```

**Benefits:**
- Tests don't block feature development
- Can test while building
- Quality assurance in parallel

### Pattern 3: Hotfix While Developing

Use when urgent fix needed while working on features:

```bash
# Terminal 1: Ongoing feature work
willie PCT-522

# Terminal 2: Urgent hotfix from production
willie hotfix-auth-bug --from main
```

**Benefits:**
- Don't interrupt feature work
- Fix can be merged immediately
- Clean separation of concerns

### Pattern 4: Refactor + Feature

Use when refactoring while adding features:

```bash
# Terminal 1: Major refactor
willie refactor-api-layer --from main

# Terminal 2: New feature on current code
willie PCT-523
```

**Benefits:**
- Explore refactoring without blocking features
- Compare approaches
- Merge refactor when stable

### Pattern 5: Multi-Agent Collaboration

Use when breaking down large tasks:

```bash
# Terminal 1: Backend API
willie PCT-522-backend --from main

# Terminal 2: Frontend UI
willie PCT-522-frontend --from main

# Terminal 3: Tests
willie PCT-522-tests --from main
```

**Benefits:**
- Divide complex tasks
- Specialized agents per layer
- Faster completion

### Pattern 6: Autonomous PRD-Driven Development

Use when working through a backlog of tickets defined in a PRD:

```bash
# Let Willie automatically pick the next highest priority ticket
willie --next

# Or run multiple autonomous agents in parallel
willie --next    # Terminal 1 - picks US-004
willie --next    # Terminal 2 - picks US-005
willie --next    # Terminal 3 - picks US-006
```

**What happens:**
1. Willie reads `prd.json` and finds highest priority incomplete ticket (not already in progress)
2. Marks ticket as `"status": "in_progress"` in `prd.json` to prevent other agents from selecting it
3. Creates worktree with ticket ID
4. Generates `TICKET.md` with full ticket details
5. Launches Claude with autonomous instructions (Ralph Loop style)
6. Agent reads ticket, implements all acceptance criteria, updates prd.json, commits

**Benefits:**
- Minimal manual intervention
- Agents work through backlog autonomously
- Structured ticket format ensures clarity
- Progress tracked in prd.json automatically
- Perfect for "set it and forget it" development
- **Multiple agents can run in parallel without working on the same ticket**

**Prerequisites:**
- `prd.json` file in Ralph format (see ralph-skills)
- `jq` installed (`sudo apt-get install jq` or `brew install jq`)
- Tickets with clear acceptance criteria

**Example prd.json structure:**
```json
{
  "userStories": [
    {
      "id": "US-001",
      "title": "Add user authentication",
      "description": "Implement JWT-based authentication",
      "acceptanceCriteria": [
        "Login endpoint accepts username/password",
        "Returns JWT token on success",
        "Token validates on protected routes"
      ],
      "priority": 1,
      "passes": false
    }
  ]
}
```

## Best Practices

### Task Naming

Use clear, consistent task IDs:

```bash
# Good
willie PCT-522           # Ticket number
willie hotfix-auth       # Descriptive hotfix
willie refactor-db       # Clear purpose

# Avoid
willie test              # Too generic
willie abc123            # Not meaningful
willie my-work           # Not specific
```

### Branch Management

**Base branches:**
```bash
# Feature from current branch (default)
willie PCT-522

# Feature from main
willie PCT-522 --from main

# Feature from another branch
willie PCT-522-v2 --from PCT-522
```

**Cleanup:**
- Clean worktrees after merging
- Delete branches that are merged
- Use `--all` for bulk cleanup

### Using Claude Code

Claude Code excels at:
- Complex refactoring
- Architectural decisions
- Code review and analysis
- Full-stack development
- Test writing
- Bug fixes and debugging

### Communication Between Agents

Agents don't directly communicate, but you can coordinate:

1. **Sequential tasks**: Finish one agent, then start next with `--from <branch>`
2. **Independent tasks**: Run in parallel, merge separately
3. **Dependent tasks**: Create first worktree, wait for completion, then create second from that branch

### Monitoring Progress

```bash
# Check all active worktrees
willie --status

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
willie --clean PCT-522
```

## Common Scenarios

### Scenario: Breaking Change Review

```bash
# Terminal 1: Implement breaking change
willie breaking-api-v2 --from main

# Terminal 2: Update dependent code
willie update-clients --from breaking-api-v2
```

### Scenario: A/B Testing Implementations

```bash
# Terminal 1: Approach A
willie solution-a --from main

# Terminal 2: Approach B
willie solution-b --from main

# Compare, pick winner, delete loser
```

### Scenario: Documentation While Coding

```bash
# Terminal 1: Implement feature
willie PCT-522

# Terminal 2: Update docs
willie docs-update --from main
```

## Troubleshooting Agent Issues

### Agent Stuck or Hung

```bash
# Exit agent with Ctrl+C
# Clean up worktree
willie --clean <task-id>
```

### Agent Made Mistakes

```bash
# Don't merge the branch
# Clean up worktree
willie --clean <task-id>
# Delete branch when prompted: Y
```

### Need to Resume Agent Work

Worktree persists after agent exits:

```bash
# Manually enter worktree
cd .worktrees/PCT-522

# Start new agent session
claude

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
