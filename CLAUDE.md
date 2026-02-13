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

2. **Autonomous Launch** (`willie --next`):
   - Read `prd.json` in current directory
   - Parse with `jq` to find highest priority incomplete ticket
   - Extract ticket ID, title, description, acceptance criteria
   - Create worktree using ticket ID
   - Generate `TICKET.md` with full ticket details and Ralph Loop instructions
   - Launch Claude Code with autonomous prompt
   - Agent reads ticket, implements, updates prd.json, commits

3. **Status** (`willie --status`):
   - List all active worktrees
   - Wrapper around `git worktree list`

4. **Cleanup** (`willie --clean <task-id>`):
   - Remove worktree
   - Optionally delete branch
   - Support bulk cleanup with `--all`

5. **Help** (`willie --help`):
   - Show usage information

## Agent Monitoring Architecture

### Overview

Groundskeeper Willie includes infrastructure for monitoring autonomous AI agents working in parallel worktrees. Version 0.1 lays the foundation with metadata tracking, while v0.2 will implement active monitoring and notifications.

**Current State (v0.1):**
- Metadata foundation only (.gw-meta files created per worktree)
- No active monitoring or alerting
- Stub command (`willie --status`) placeholder for future functionality

**Future Vision (v0.2):**
- Real-time agent activity monitoring
- Desktop and terminal notifications for stuck agents
- Enhanced status dashboard with progress tracking
- Automatic detection of inactive or problematic worktrees

### .gw-meta File Format

Each worktree has a metadata file at `.worktrees/<task-id>/.gw-meta` containing JSON:

```json
{
  "created_at": "2026-02-12T14:30:22Z",
  "task_id": "PCT-123",
  "branch": "PCT-123",
  "shell": "bash",
  "claude_version": "v0.1.0"
}
```

**Fields:**
- `created_at` - ISO 8601 timestamp of worktree creation
- `task_id` - The task/ticket identifier (same as worktree directory name)
- `branch` - Git branch name (typically same as task_id)
- `shell` - Shell type that created the worktree (bash, zsh, or fish)
- `claude_version` - Groundskeeper Willie version used to create worktree

**Purpose:**
- Track worktree lifecycle for monitoring
- Enable activity detection and stuck agent alerts
- Support enhanced status reporting
- Provide audit trail for parallel development
- Foundation for future analytics and optimization

**Location:**
- Inside the worktree directory (`.worktrees/<task-id>/.gw-meta`)
- Git-ignored (never committed)
- Created immediately after successful worktree creation
- Persists until worktree cleanup

### Planned Monitoring Approach (v0.2)

**Activity Detection:**

Monitoring will track agent activity through multiple signals:
1. **Git activity** - Commits, branch updates, staged changes
2. **File modifications** - Watch worktree directory for file changes
3. **Process detection** - Check for running Claude Code instances
4. **Timestamp comparison** - Compare current time against creation/last activity

**Monitoring Triggers:**

Example conditions that will generate alerts:

- **Stuck Agent Detection:**
  - No commits for >30 minutes after worktree creation
  - No file changes for >15 minutes (using filesystem timestamps)
  - Claude Code process not found but worktree exists
  - Agent session terminated unexpectedly

- **Completion Detection:**
  - Branch merged to main/master
  - PR marked as closed
  - Worktree inactive for >2 hours with clean working directory

- **Error Conditions:**
  - Merge conflicts detected in worktree
  - Test failures (if CI integration available)
  - Uncommitted changes with no recent activity

**Monitoring Implementation Strategy:**

```bash
# Background monitoring daemon (v0.2)
willie-monitor --daemon

# Checks every N minutes:
# 1. List all .worktrees/*/.gw-meta files
# 2. For each worktree:
#    - Check git log for recent commits
#    - Check filesystem for recent modifications
#    - Check for running Claude Code process
#    - Compare against trigger conditions
# 3. Send notifications for alerts
```

### Notification System Design

**Desktop Notifications:**

Use OS-native notification systems:
- **macOS**: `osascript` or `terminal-notifier`
- **Linux**: `notify-send` (libnotify)
- **Fallback**: Terminal bell + message

**Notification Types:**

```bash
# Success notification
"✅ PCT-123: Agent completed task (3 commits, 45 minutes)"

# Warning notification
"⚠️ PCT-456: No activity for 30 minutes"

# Error notification
"❌ PCT-789: Merge conflicts detected"

# Info notification
"ℹ️ PCT-321: Agent started working on ticket"
```

**Notification Preferences (v0.2+):**

Users will be able to configure:
- Notification threshold (time before alert)
- Quiet hours (no notifications during sleep)
- Notification channels (desktop, terminal, none)
- Per-worktree notification settings

**Terminal Notifications:**

For users without desktop environment or who prefer terminal:
```bash
willie --status
# Displays:
# 📊 Active Worktrees (3)
# ✅ PCT-123  [master]  3h ago  ✓ 5 commits
# ⚠️ PCT-456  [master]  45m ago  ! No recent activity
# 🔴 PCT-789  [develop] 2h ago  ✗ Merge conflicts
```

### willie-status Command Vision

**Basic Usage (v0.2):**

```bash
# List all active worktrees with status
willie --status

# Show detailed view
willie --status --verbose

# Show only problematic worktrees
willie --status --warnings

# Watch mode (live updates)
willie --status --watch
```

**Output Format:**

```
📊 Groundskeeper Willie Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Active Worktrees: 3

✅ PCT-123  [master→feature/auth]
   Created: 3h ago  |  Last activity: 5m ago
   Status: Active - 5 commits, 12 files changed
   Agent: Claude Code (running)

⚠️ PCT-456  [master→bugfix/login]
   Created: 45m ago  |  Last activity: 30m ago
   Status: Inactive - 1 commit, no recent changes
   Agent: Claude Code (not found)
   → Warning: No activity detected for 30 minutes

🔴 PCT-789  [develop→feature/ui]
   Created: 2h ago  |  Last activity: 15m ago
   Status: Blocked - merge conflicts detected
   Agent: Claude Code (running)
   → Error: 3 files with merge conflicts

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Run 'willie --clean <task-id>' to remove completed worktrees
Run 'willie --status --watch' for live updates
```

**Verbose Mode:**

Shows additional details:
- Full commit history in worktree
- List of modified files
- Process IDs and resource usage
- prd.json ticket status (if using Ralph Loop)

**Integration with Ralph Loop:**

For autonomous agents using prd.json:
```bash
willie --status --ralph

# Shows:
# ✅ US-001 [Completed] - Install script created (3 commits)
# 🚧 US-002 [In Progress] - Config backup logic (1 commit, 30m active)
# ⏸️ US-003 [Not Started] - No worktree yet
```

### Example Monitoring Trigger Conditions

**Tier 1 - Immediate Alerts:**
- Merge conflicts detected → Desktop notification + terminal alert
- Process crashed (exit code != 0) → Desktop notification
- Disk space critically low in worktree → Desktop notification

**Tier 2 - Warning Alerts:**
- No commits for 30 minutes after creation → Desktop notification
- No file changes for 15 minutes → Terminal only (non-intrusive)
- Working directory has uncommitted changes + no activity 20 minutes → Terminal only

**Tier 3 - Info Alerts:**
- Agent completed work (branch merged) → Desktop notification (success)
- New worktree created → Terminal only
- Worktree idle for 2+ hours with clean state → Suggest cleanup

**Configurable Thresholds (v0.2):**

```bash
# ~/.groundskeeper-willie/config.json (future)
{
  "monitoring": {
    "stuck_threshold_minutes": 30,
    "file_activity_threshold_minutes": 15,
    "completion_idle_hours": 2,
    "enable_desktop_notifications": true,
    "quiet_hours": {
      "enabled": true,
      "start": "22:00",
      "end": "08:00"
    }
  }
}
```

### v0.1 Implementation Notes

**What's Included in v0.1:**

✅ Metadata file structure defined
✅ .gw-meta creation points identified in code
✅ Stub command framework (`willie --status` prints "Coming in v0.2")
✅ Architecture documented (this section)

**What's NOT Included in v0.1:**

❌ No active monitoring daemon
❌ No notification system
❌ No activity detection logic
❌ No dashboard/status display
❌ No trigger evaluation

**Rationale:**

v0.1 focuses on installation and basic workflow. The metadata foundation ensures v0.2 monitoring can be added without refactoring core functionality. This follows the principle: "build the foundation, then add the features."

**Future Implementation Path:**

1. **v0.2 (Monitoring):** Add active monitoring with basic notifications
2. **v0.3 (Intelligence):** Add ML-based stuck detection, pattern recognition
3. **v1.0 (Platform):** Full dashboard, multi-agent coordination, cloud sync

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

**Decision:** Use `willie` as the main command with flags (--status, --clean, --help, --next)

**Rationale:**
- Simpler mental model
- Task IDs never conflict with commands
- Easier to remember
- Cleaner namespace (no `willie-*` commands)
- Better discoverability through `willie --help`
- Flags are clearly distinguishable from task IDs

### Why --next for PRD Integration?

**Decision:** Add `willie --next` to auto-launch highest priority ticket from prd.json

**Rationale:**
- Enables autonomous agent workflows (Ralph Loop style)
- Reduces manual overhead of selecting and launching tickets
- Works naturally with PRD-driven development
- Supports parallel autonomous agents working through backlog
- Creates structured `TICKET.md` with full context for agent
- Agent can work independently: read ticket → implement → test → update prd.json → commit

## Testing

### Manual Testing Checklist

Before committing changes:

- [ ] Create worktree with default options
- [ ] Create worktree with `--from main` option
- [ ] Show help with `willie --help`
- [ ] List worktrees with `willie --status`
- [ ] Launch next ticket with `willie --next` (requires prd.json)
- [ ] Launch next ticket with `--from` option
- [ ] Verify `TICKET.md` is created in worktree
- [ ] Verify jq error handling (no jq installed)
- [ ] Verify prd.json error handling (no file found)
- [ ] Verify behavior when all tickets complete (passes: true)
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
4. Update documentation (README.md, CLAUDE.md, AGENTS.md if relevant)
5. Implement in both bash and fish versions
6. Test on both shell versions

Example (from `--next` implementation):
```bash
# In main willie() function, add:
case "$cmd" in
    --next)
        shift
        _willie_next "$@"
        ;;
esac

# Create the function:
_willie_next() {
    # 1. Validate prerequisites (prd.json, jq)
    # 2. Query prd.json for highest priority incomplete ticket
    # 3. Extract ticket details
    # 4. Create worktree
    # 5. Generate TICKET.md with full context
    # 6. Launch Claude with autonomous prompt
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
