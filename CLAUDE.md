# Working on Groundskeeper Willie with Claude Code

This document provides context and guidelines for Claude Code (or any AI agent) working on the Groundskeeper Willie project.

## Project Overview

**Name:** Groundskeeper Willie (The Simpsons character who maintains the school grounds and monitors the playground)

**Purpose:** Enable multiple AI coding agents to work in parallel using Git worktrees

**Components:**
- `worktree-agent-functions.sh` - Bash/Zsh shell functions
- `worktree-agent-functions.fish` - Fish shell functions
- Documentation files (README.md, AGENTS.md, this file)

## Architecture

### Core Concept

Groundskeeper Willie wraps Git's worktree functionality with AI agent lifecycle management:

```
Repository Root
├── .worktrees/          (git-ignored)
│   ├── PCT-522/         (worktree + branch PCT-522)
│   ├── PCT-523/         (worktree + branch PCT-523)
│   └── hotfix/          (worktree + branch hotfix)
└── main workspace       (original repo location)
```

### Shell Function Flow

1. **Creation** (`willie <task-id>`):
   - Validate inputs
   - Check for conflicts (existing worktree/branch)
   - Create worktree with new branch
   - Launch Claude Code in worktree
   - Return to original directory on exit

2. **Status** (`willie --status`):
   - List all active worktrees
   - Wrapper around `git worktree list`

3. **Cleanup** (`willie --clean <task-id>`):
   - Remove worktree
   - Optionally delete branch
   - Support bulk cleanup with `--all`

4. **Help** (`willie --help`):
   - Show usage information

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
   bash -c "source worktree-agent-functions.sh && willie --help"

   # Test fish version
   fish -c "source worktree-agent-functions.fish && willie --help"
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

### Function Naming

Internal helper functions are prefixed with `_`:
- `willie()` - main entry point
- `_willie_create()` - internal function for creating worktrees
- `_willie_status()` - internal function for listing worktrees
- `_willie_clean()` - internal function for cleanup
- `_willie_help()` - internal function for help

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

### Why Single Command Interface?

**Decision:** Use `willie` as the main command with flags (--status, --clean, --help)

**Rationale:**
- Simpler mental model
- Task IDs never conflict with commands
- Easier to remember
- Cleaner namespace (no `willie-*` commands)
- Better discoverability through `willie --help`
- Flags are clearly distinguishable from task IDs

## Testing

### Manual Testing Checklist

Before committing changes:

- [ ] Create worktree with default options
- [ ] Create worktree with `--from main` option
- [ ] Show help with `willie --help`
- [ ] List worktrees with `willie --status`
- [ ] Clean up worktree (keep branch)
- [ ] Clean up worktree (delete branch)
- [ ] Clean up all worktrees with `willie --clean --all`
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
- [ ] Enhanced status (show active sessions, commit counts)

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

What Groundskeeper Willie intentionally doesn't do:

- ❌ Manage agent conversations/state
- ❌ Direct agent-to-agent communication
- ❌ Project-specific configuration
- ❌ CI/CD integration
- ❌ GUI interface
- ❌ Multiple agent support in single command (focus on Claude Code)

## Common Tasks

### Add Support for New Flag

1. Create new internal function (e.g., `_willie_newcmd`)
2. Add case to main `willie()` function
3. Update help text in `_willie_help()`
4. Update documentation
5. Test on both shell versions

Example:
```bash
# In main willie() function, add:
case "$cmd" in
    --newcmd)
        shift
        _willie_newcmd "$@"
        ;;
esac

# Create the function:
_willie_newcmd() {
    # Implementation
}
```

### Change Worktree Location

1. Update `worktree_dir` construction in `willie`
2. Update documentation (README.md)
3. Update `.gitignore` examples

### Modify Existing Flag

1. Update the internal function (e.g., `_willie_clean`)
2. Update help text if behavior changes
3. Update documentation
4. Test on both shell versions

Note: Task ID handling is in the default case `*)` which calls `_willie_create`

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
- Check if function is sourced: `type willie`
- Verify shell config reload: `source ~/.bashrc`

**"Worktree already exists"**
- Check `willie --status` or `git worktree list`
- Orphaned worktree: `git worktree prune`

**"Permission denied"**
- Check repo permissions
- Verify `.worktrees/` is writable

**"Unknown option"**
- Use `willie --help` to see available options
- Make sure flags start with `--`

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
- [Groundskeeper Willie - Simpsons Wiki](https://simpsons.fandom.com/wiki/Groundskeeper_Willie)

## Meta: Improving This Document

This document should evolve as the project grows. When making changes:

- Keep it practical and example-focused
- Update decision rationale when decisions change
- Add new patterns as they emerge
- Remove outdated information
- Keep it concise - link to external resources for details

## Contact

For questions or contributions, refer to main project documentation or repository.
