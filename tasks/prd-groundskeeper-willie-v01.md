# PRD: Groundskeeper Willie v0.1 - One-Line Installation

## Introduction

Transform Groundskeeper Willie from a manual shell function setup into a mainstream tool for individual developers. The current biggest pain point is installation difficulty - users must manually download files, source them in shell configs, and understand Git worktrees before getting started. This release eliminates installation friction with a one-line installer and improved onboarding, reducing setup time from 5+ minutes to under 30 seconds.

This positions the tool for broader adoption and sets the foundation for future agent monitoring capabilities.

## Goals

- Reduce installation time from 5+ minutes to under 30 seconds
- Support automatic detection of all major shells (bash/zsh/fish)
- Create foolproof installation that doesn't break existing shell configs
- Provide clear quick-start path to first worktree in under 5 minutes
- Lay foundation for future agent monitoring features (v0.2)
- Achieve initial community adoption (GitHub stars/forks)

## User Stories

### US-001: One-line installer script
**Description:** As a developer, I want to install Groundskeeper Willie with a single command so that I can start using it immediately without manual configuration.

**Acceptance Criteria:**
- [ ] Create `install.sh` that downloads and configures everything
- [ ] Works with single command: `curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash`
- [ ] Detects shell automatically (bash/zsh/fish)
- [ ] Downloads correct functions file for detected shell
- [ ] Adds source line to appropriate config file (~/.bashrc, ~/.zshrc, ~/.config/fish/config.fish)
- [ ] Creates backup of config file before modification
- [ ] Idempotent - safe to run multiple times (detects existing installation)
- [ ] Works on macOS and Linux
- [ ] Typecheck/shellcheck passes

### US-002: Shell detection logic
**Description:** As a user, I want the installer to automatically detect my shell so I don't need to specify it manually.

**Acceptance Criteria:**
- [ ] Check $SHELL environment variable as primary method
- [ ] Fallback to parent process inspection if $SHELL unavailable
- [ ] Correctly identifies bash, zsh, and fish
- [ ] Displays clear error message for unsupported shells
- [ ] Provides manual installation instructions when auto-detect fails
- [ ] Typecheck/shellcheck passes

### US-003: Safe config file modification
**Description:** As a user, I want the installer to safely modify my shell config without breaking existing setup so I can trust the installation process.

**Acceptance Criteria:**
- [ ] Create timestamped backup before modification (e.g., `.bashrc.backup.20260212-143022`)
- [ ] Append source line with clear comment markers
- [ ] Detect if source line already exists (avoid duplicates)
- [ ] Don't modify config if functions already sourced
- [ ] Show diff of changes to be made before applying
- [ ] Provide rollback instructions if something goes wrong
- [ ] Typecheck/shellcheck passes

### US-004: Installation verification
**Description:** As a user, I want confirmation that installation succeeded so I know the tool is ready to use.

**Acceptance Criteria:**
- [ ] Test that functions are loadable after installation
- [ ] Display success message with next steps
- [ ] Show command to verify: `type agent-worktree`
- [ ] Indicate if shell restart required
- [ ] Print example first command: `agent-worktree PCT-123`
- [ ] Include link to quick start guide
- [ ] Typecheck/shellcheck passes

### US-005: Uninstallation instructions
**Description:** As a user, I want clear instructions to uninstall so I can easily remove the tool if needed.

**Acceptance Criteria:**
- [ ] Print uninstall steps at end of installation
- [ ] Document how to remove source line from config
- [ ] Document how to restore from backup
- [ ] Include in README.md
- [ ] Test uninstall process on all shells
- [ ] Typecheck/shellcheck passes

### US-006: Quick start documentation
**Description:** As a new user, I want streamlined onboarding docs so I can create my first worktree in under 5 minutes.

**Acceptance Criteria:**
- [ ] Update README.md with installation one-liner as first step
- [ ] Add "Quick Start" section with 3-step workflow example
- [ ] Include visual ASCII diagram of worktree structure
- [ ] Add "Common Use Cases" section (parallel features, testing, refactoring)
- [ ] Create troubleshooting section for common issues
- [ ] Add table of contents for easy navigation
- [ ] Verify documentation is mobile-friendly

### US-007: Error handling and messaging
**Description:** As a user encountering installation issues, I want clear error messages so I can fix problems myself.

**Acceptance Criteria:**
- [ ] Specific error messages for each failure mode
- [ ] Suggest solutions for common problems (permissions, missing curl/git)
- [ ] Validate prerequisites (git installed, not in git repo)
- [ ] Graceful handling of network failures
- [ ] Log verbose output to temp file for debugging
- [ ] Include log file path in error messages
- [ ] Typecheck/shellcheck passes

### US-008: Foundation for agent monitoring
**Description:** As a developer, I want the infrastructure ready for future monitoring features so v0.2 can be implemented quickly.

**Acceptance Criteria:**
- [ ] Add timestamp tracking to worktree creation (store in hidden metadata file)
- [ ] Create `.worktrees/<task>/.gw-meta` file with creation time, branch, task ID
- [ ] Document monitoring architecture in CLAUDE.md
- [ ] Create stub `agent-worktree-status` command (prints "Coming in v0.2")
- [ ] Design notification system architecture (document only, no implementation)
- [ ] No user-facing changes beyond stub command
- [ ] Typecheck/shellcheck passes

## Functional Requirements

**FR-1: Installation**
- The installer must work on macOS and Linux with bash 4+, zsh 5+, fish 3+
- The installer must be idempotent (safe to run multiple times)
- The installer must create config file backups before modification
- The installer must not require sudo/admin privileges

**FR-2: Shell Detection**
- The installer must detect current shell from $SHELL variable
- The installer must fall back to process inspection if $SHELL unavailable
- The installer must support bash, zsh, and fish
- The installer must provide clear error for unsupported shells

**FR-3: Configuration**
- The installer must download shell-specific functions file
- The installer must add source line to correct config file
- The installer must not create duplicate source lines
- The installer must preserve existing config file content

**FR-4: Verification**
- The installer must verify functions are loadable after installation
- The installer must display success message with next steps
- The installer must indicate if shell restart required

**FR-5: Documentation**
- README must include one-line installation command
- README must include quick start guide (< 5 minute path to first worktree)
- README must include troubleshooting section
- README must include uninstall instructions

**FR-6: Metadata Foundation**
- Worktree creation must store timestamp in `.worktrees/<task>/.gw-meta`
- Metadata file must include: creation time, branch name, task ID, shell used
- Stub `agent-worktree-status` command must exist (no-op in v0.1)

## Non-Goals (Out of Scope for v0.1)

- **Package manager support** (brew, apt, npm) - deferred to v0.3
- **Agent process monitoring** - deferred to v0.2
- **Stuck agent detection/alerts** - deferred to v0.2
- **Integration tests** - deferred to v0.3
- **Windows/WSL support** - nice to have, not blocking
- **Support for agents other than Claude Code** - future consideration
- **GUI installer** - CLI only
- **Automatic updates** - manual reinstall for now
- **Configuration file** (e.g., ~/.gw-config) - sensible defaults only

## Technical Considerations

**Install Script Structure:**
```bash
install.sh
├── detect_shell()           # Identify bash/zsh/fish
├── validate_environment()   # Check git, curl, permissions
├── download_functions()     # Fetch shell-specific functions file
├── backup_config()          # Create timestamped backup
├── update_config()          # Add source line safely
├── verify_installation()    # Test functions loadable
└── print_success_message()  # Next steps + uninstall info
```

**Shell Config Locations:**
- Bash: `~/.bashrc` (Linux) or `~/.bash_profile` (macOS)
- Zsh: `~/.zshrc`
- Fish: `~/.config/fish/config.fish`

**Functions File URLs:**
- `https://raw.githubusercontent.com/USER/ratatoskr/master/worktree-agent-functions.sh`
- `https://raw.githubusercontent.com/USER/ratatoskr/master/worktree-agent-functions.fish`

**Metadata File Format (.gw-meta):**
```json
{
  "created_at": "2026-02-12T14:30:22Z",
  "task_id": "PCT-123",
  "branch": "PCT-123",
  "shell": "bash",
  "claude_version": "v0.1.0"
}
```

**Dependencies:**
- `curl` or `wget` for downloading
- `git` version 2.5+ (worktree support)
- Standard UNIX tools: `cat`, `grep`, `sed`

**Compatibility:**
- macOS 10.15+
- Ubuntu 20.04+
- Debian 11+
- Other Linux distros (best effort)

## Success Metrics

**Installation Performance:**
- Installation time < 30 seconds (measured from curl to success message)
- 95% success rate on first attempt (macOS/Ubuntu with supported shells)

**Adoption Metrics:**
- GitHub stars > 50 within first week
- GitHub forks > 10 within first week
- At least 3 community issue reports or feature requests (engagement signal)

**User Experience:**
- New user can create first worktree in < 5 minutes (including install)
- Zero reported cases of broken shell configs from installation
- Uninstall successfully restores previous state

**Foundation Quality:**
- Metadata files created correctly for 100% of worktrees
- Architecture documented for v0.2 implementation
- No refactoring needed to add monitoring in v0.2

## Open Questions

**Resolved:**
- ✅ Should installer require sudo? → No, user-space only
- ✅ Support Windows WSL? → Nice to have, not blocking v0.1
- ✅ Which shells to support? → bash, zsh, fish

**Still Open:**
1. **Hosting:** Where to host install script?
   - Option A: GitHub raw URL (free, simple, requires trust in GitHub)
   - Option B: Dedicated domain like `install.groundskeeper.dev` (professional, costs money)
   - **Recommendation:** Start with GitHub raw, migrate to domain if successful

2. **Shell config edge cases:** How to handle Oh My Zsh, Prezto, etc.?
   - Option A: Detect and warn, provide manual instructions
   - Option B: Best-effort detection, add to plugin directories
   - **Recommendation:** Option A for v0.1, Option B for v1.0

3. **Installation location:** Where to store downloaded functions files?
   - Option A: Keep in shell config dir (e.g., `~/.bashrc.d/groundskeeper-willie.sh`)
   - Option B: Dedicated dir (e.g., `~/.groundskeeper-willie/functions.sh`)
   - **Recommendation:** Option B - cleaner, easier to uninstall

4. **Versioning:** How to handle updates?
   - Option A: Re-run install script (simple, no auto-update)
   - Option B: Add `agent-worktree-update` command
   - **Recommendation:** Option A for v0.1

5. **Analytics:** Should we collect anonymous usage stats?
   - Pros: Understand adoption, guide feature priorities
   - Cons: Privacy concerns, implementation complexity
   - **Recommendation:** No for v0.1, consider for v1.0 with opt-in

## Timeline

**Day 1-2 (Wed-Thu):**
- Create `install.sh` with shell detection logic
- Implement safe config modification with backups
- Add installation verification

**Day 3 (Fri):**
- Update README.md with quick start guide
- Add troubleshooting section
- Create worktree diagram

**Day 4 (Sat):**
- Manual testing on macOS (bash/zsh) and Ubuntu (bash/fish)
- Fix bugs from testing
- Add metadata foundation (.gw-meta files)

**Day 5 (Sun):**
- Final polish and documentation review
- Tag v0.1 release
- Share on relevant communities (Reddit r/commandline, Hacker News)

## Resources Needed

**Technical:**
- GitHub repository access (already have)
- Testing environments:
  - macOS 13+ with bash and zsh
  - Ubuntu 22.04 with bash and fish
  - Virtual machines or Docker for isolation

**Documentation:**
- ASCII diagram tool for worktree visualization
- Markdown linter for documentation quality

**Distribution:**
- GitHub Releases for version tagging
- GitHub Discussions for community feedback

**Optional:**
- Screen recording tool for demo video (future)
- Domain name for install URL (future)
