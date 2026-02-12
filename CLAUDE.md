# Working on Ratatoskr with Claude Code

This document provides context and guidelines for Claude Code (or any AI agent) working on the Ratatoskr project.

## Project Overview

**Name:** Ratatoskr (Norse mythology squirrel that runs up and down Yggdrasil)

**Purpose:** Enable multiple AI coding agents to work in parallel using Git worktrees

**Components:**
- `worktree-agent-functions.sh` - Bash/Zsh shell functions
- `worktree-agent-functions.fish` - Fish shell functions
- Documentation files (README.md, AGENTS.md, this file)

## Architecture

### Core Concept

Ratatoskr wraps Git's worktree functionality with AI agent lifecycle management:

```
Repository Root
├── .worktrees/          (git-ignored)
│   ├── PCT-522/         (worktree + branch PCT-522)
│   ├── PCT-523/         (worktree + branch PCT-523)
│   └── hotfix/          (worktree + branch hotfix)
└── main workspace       (original repo location)
```

### Shell Function Flow

1. **Creation** (`agent-worktree`):
   - Validate inputs
   - Check for conflicts (existing worktree/branch)
   - Create worktree with new branch
   - Launch agent in worktree
   - Return to original directory on exit

2. **Listing** (`agent-worktree-list`):
   - Wrapper around `git worktree list`

3. **Cleanup** (`agent-worktree-clean`):
   - Remove worktree
   - Optionally delete branch
   - Support bulk cleanup with `--all`

## Code Structure

### Bash Version (`worktree-agent-functions.sh`)

- Uses standard Bash syntax
- `[[` conditionals
- `$()` command substitution
- `read -p` for prompts
- POSIX-compatible where possible

### Fish Version (`worktree-agent-functions.fish`)

- Fish-specific `function` syntax
- `test` conditionals
- `set -l` for local variables
- `read -P` for prompts
- Array indexing with `$argv[N]`

### Feature Parity

Both versions must maintain identical functionality:
- Same command names
- Same arguments and options
- Same behavior
- Same error messages

## Making Changes

### When Adding Features

1. **Update both shell versions** (bash and fish)
2. **Update documentation**:
   - README.md (user-facing)
   - AGENTS.md (workflow patterns)
   - CLAUDE.md (this file, if architecture changes)
3. **Test both versions**:
   ```bash
   # Test bash version
   bash -c "source worktree-agent-functions.sh && agent-worktree-help"

   # Test fish version
   fish -c "source worktree-agent-functions.fish && agent-worktree-help"
   ```

### When Fixing Bugs

1. **Identify which version** has the bug (or both)
2. **Fix in both versions** to maintain parity
3. **Document the fix** in commit message
4. **Add example to troubleshooting** if user-facing

### Code Style

**Bash:**
```bash
# Good
if [[ -z "$var" ]]; then
    echo "Error: ..."
    return 1
fi

# Avoid
if [ "$var" = "" ]
then
    echo "Error: ..."
    exit 1  # Use return in functions
fi
```

**Fish:**
```fish
# Good
if test -z "$var"
    echo "Error: ..."
    return 1
end

# Avoid
if [ "$var" = "" ]
    echo "Error: ..."
    exit 1  # Use return in functions
end
```

## Design Decisions

### Why Manual Cleanup?

**Decision:** Don't auto-delete worktrees on agent exit

**Rationale:**
- User may want to review changes
- Agent might crash/exit unexpectedly
- User might want to restart agent in same worktree
- Explicit is better than implicit

### Why `.worktrees/` Inside Repo?

**Decision:** Store worktrees in `.worktrees/` inside repo root

**Alternatives considered:**
- `../worktrees/` (sibling directory)
- `~/worktrees/<repo-name>/` (home directory)

**Rationale:**
- Simpler mental model
- Easy to find and clean up
- Git-ignored, so won't be committed
- Works with any repo structure

### Why Task ID Naming?

**Decision:** Use task ID as both directory name and branch name

**Rationale:**
- Clear 1:1 mapping
- Easy to track
- Matches typical workflow (tickets, issues)
- No naming ambiguity

### Why Support Multiple Agents?

**Decision:** `--claude` and `--codex` flags with extensibility

**Rationale:**
- Different agents have different strengths
- User flexibility
- Future-proof for new agents
- Easy to extend

## Testing

### Manual Testing Checklist

Before committing changes:

- [ ] Create worktree with default options
- [ ] Create worktree with `--codex` option
- [ ] Create worktree with `--from main` option
- [ ] List worktrees
- [ ] Clean up worktree (keep branch)
- [ ] Clean up worktree (delete branch)
- [ ] Clean up all worktrees
- [ ] Error handling: duplicate worktree
- [ ] Error handling: duplicate branch
- [ ] Error handling: invalid task ID
- [ ] Error handling: not in git repo
- [ ] Test on both Bash and Fish

### Edge Cases

- Non-git directory
- Detached HEAD state
- Worktree already exists
- Branch already exists
- Invalid characters in task ID
- No write permissions
- Disk space issues

## Feature Roadmap

### Potential Enhancements

**High Priority:**
- [ ] Add support for more agents (Cursor, Aider, etc.)
- [ ] Better error messages with suggestions
- [ ] Worktree status command (show which are active)

**Medium Priority:**
- [ ] Auto-cleanup merged worktrees
- [ ] Template support (initialize worktrees with boilerplate)
- [ ] Integration with GitHub CLI (create PR from worktree)
- [ ] Worktree history/logging

**Low Priority:**
- [ ] Interactive mode (wizard)
- [ ] Config file support
- [ ] Shell completion (bash/zsh/fish)
- [ ] Colorized output

### Non-Goals

What Ratatoskr intentionally doesn't do:

- ❌ Manage agent conversations/state
- ❌ Direct agent-to-agent communication
- ❌ Project-specific configuration
- ❌ CI/CD integration
- ❌ GUI interface

## Common Tasks

### Add Support for New Agent

1. Update argument parsing to accept new `--agent-name` flag
2. Add case in agent launch section
3. Update help text and documentation
4. Test on both shell versions

Example:
```bash
# In agent-worktree function, add:
case --aider)
    agent="aider"
    shift
    ;;

# In launch section, add:
elif [[ "$agent" == "aider" ]]; then
    aider
```

### Change Worktree Location

1. Update `worktree_dir` construction in `agent-worktree`
2. Update documentation (README.md)
3. Update `.gitignore` examples

### Add New Command

1. Create function in both shell versions
2. Add to help text
3. Document in README.md
4. Add workflow example to AGENTS.md if applicable

## Git Workflow

### Branch Strategy

- `main` - stable releases
- Feature branches for new features
- Hotfix branches for bugs

### Commit Messages

```
feat: add support for Aider agent
fix: handle detached HEAD state correctly
docs: update installation instructions
refactor: simplify argument parsing
test: add edge case for duplicate branches
```

### Pull Requests

- Include examples in description
- Update relevant documentation
- Ensure both shell versions tested
- Add to CHANGELOG if applicable

## Debugging

### Enable Shell Debugging

**Bash:**
```bash
bash -x worktree-agent-functions.sh
```

**Fish:**
```fish
fish --debug worktree-agent-functions.fish
```

### Common Issues

**"Command not found"**
- Check if function is sourced: `type agent-worktree`
- Verify shell config reload: `source ~/.bashrc`

**"Worktree already exists"**
- Check `git worktree list`
- Orphaned worktree: `git worktree prune`

**"Permission denied"**
- Check repo permissions
- Verify `.worktrees/` is writable

## Questions for Users

When users ask for changes, clarify:

1. **Scope**: Both shells or specific one?
2. **Backward compatibility**: Should old behavior still work?
3. **Documentation**: Which docs need updating?
4. **Testing**: How should this be tested?

## Resources

- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [Bash Scripting Guide](https://www.gnu.org/software/bash/manual/)
- [Fish Shell Documentation](https://fishshell.com/docs/current/)
- [Norse Mythology - Ratatoskr](https://en.wikipedia.org/wiki/Ratatoskr)

## Meta: Improving This Document

This document should evolve as the project grows. When making changes:

- Keep it practical and example-focused
- Update decision rationale when decisions change
- Add new patterns as they emerge
- Remove outdated information
- Keep it concise - link to external resources for details

## Contact

For questions or contributions, refer to main project documentation or repository.
