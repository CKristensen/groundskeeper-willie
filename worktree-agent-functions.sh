#!/bin/bash
# Git Worktree Agent Helper Functions
# Add these to your ~/.bashrc or ~/.zshrc

willie() {
  # Handle flags
  local cmd="$1"

  case "$cmd" in
    --help|-h)
      _willie_help
      ;;
    --status)
      _willie_status
      ;;
    --clean)
      shift
      _willie_clean "$@"
      ;;
    --next)
      shift
      _willie_next "$@"
      ;;
    "")
      _willie_help
      return 1
      ;;
    --*)
      echo "Error: Unknown option '$cmd'"
      echo "Use 'willie --help' for usage information"
      return 1
      ;;
    *)
      # Default: create worktree
      _willie_create "$@"
      ;;
  esac
}

# Create worktree and launch agent
_willie_create() {
  local task_id=""
  local base_branch=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --from)
        base_branch="$2"
        shift 2
        ;;
      *)
        if [[ -z "$task_id" ]]; then
          task_id="$1"
        else
          echo "Error: Unknown argument '$1'"
          return 1
        fi
        shift
        ;;
    esac
  done

  # Validate task ID
  if [[ -z "$task_id" ]]; then
    echo "Usage: willie <task-id> [--from <base-branch>]"
    echo ""
    echo "Examples:"
    echo "  willie PCT-522"
    echo "  willie hotfix-123 --from main"
    return 1
  fi

  # Check if we're in a git repo
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    return 1
  fi

  # Get repo root
  local repo_root=$(git rev-parse --show-toplevel)
  local worktree_dir="$repo_root/.worktrees/$task_id"

  # Check if worktree already exists
  if [[ -d "$worktree_dir" ]]; then
    echo "Error: Worktree already exists at $worktree_dir"
    echo "Remove it first with: willie --clean $task_id"
    return 1
  fi

  # Determine base branch
  if [[ -z "$base_branch" ]]; then
    base_branch=$(git branch --show-current)
    if [[ -z "$base_branch" ]]; then
      base_branch="main"
    fi
  fi

  # Create branch name
  local branch_name="$task_id"

  # Check if branch already exists
  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    echo "Error: Branch '$branch_name' already exists"
    echo "Use a different task ID or delete the existing branch first"
    return 1
  fi

  echo "Creating worktree..."
  echo "  Task ID: $task_id"
  echo "  Branch: $branch_name (from $base_branch)"
  echo "  Location: $worktree_dir"
  echo ""

  # Create worktree with new branch
  if ! git worktree add -b "$branch_name" "$worktree_dir" "$base_branch"; then
    echo "Error: Failed to create worktree"
    return 1
  fi

  echo ""
  echo "Worktree created successfully!"
  echo "Launching Claude Code..."
  echo ""

  # Change to worktree directory and launch Claude
  cd "$worktree_dir" || return 1
  claude

  # After Claude exits, return to original directory
  cd - > /dev/null
}

# List all worktrees
_willie_status() {
  echo "Git worktrees:"
  git worktree list
}

# Cleanup/remove worktree
_willie_clean() {
  local task_id="$1"

  if [[ -z "$task_id" ]]; then
    echo "Current worktrees:"
    echo ""
    git worktree list
    echo ""
    echo "Usage: willie --clean <task-id>"
    echo "   or: willie --clean --all  (remove all worktrees)"
    return 0
  fi

  # Get repo root
  local repo_root=$(git rev-parse --show-toplevel)

  if [[ "$task_id" == "--all" ]]; then
    echo "Cleaning all worktrees in .worktrees/..."
    if [[ -d "$repo_root/.worktrees" ]]; then
      for worktree_dir in "$repo_root/.worktrees"/*; do
        if [[ -d "$worktree_dir" ]]; then
          local wt_name=$(basename "$worktree_dir")
          echo "Removing worktree: $wt_name"
          git worktree remove "$worktree_dir" --force
        fi
      done
      echo "All worktrees cleaned!"
    else
      echo "No .worktrees directory found"
    fi
    return 0
  fi

  local worktree_dir="$repo_root/.worktrees/$task_id"

  if [[ ! -d "$worktree_dir" ]]; then
    echo "Error: Worktree not found at $worktree_dir"
    echo ""
    echo "Available worktrees:"
    git worktree list
    return 1
  fi

  echo "Removing worktree: $task_id"
  echo "Location: $worktree_dir"

  # Remove the worktree
  if git worktree remove "$worktree_dir" --force; then
    echo "Worktree removed successfully!"

    # Ask about deleting the branch
    echo ""
    read -p "Delete branch '$task_id'? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      git branch -D "$task_id"
      echo "Branch deleted!"
    fi
  else
    echo "Error: Failed to remove worktree"
    return 1
  fi
}

# Launch next highest priority ticket from prd.json
_willie_next() {
  local base_branch=""

  # Parse optional --from argument
  if [[ "$1" == "--from" ]]; then
    base_branch="$2"
  fi

  # Check if prd.json exists
  if [[ ! -f "prd.json" ]]; then
    echo "Error: prd.json not found in current directory"
    echo "Make sure you're in a project with a PRD file"
    return 1
  fi

  # Check if jq is installed
  if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed"
    echo "Install with:"
    echo "  - Ubuntu/Debian: sudo apt-get install jq"
    echo "  - macOS: brew install jq"
    echo "  - Fedora: sudo dnf install jq"
    return 1
  fi

  # Get highest priority incomplete ticket that's not already being worked on
  local ticket_json=$(jq -c '
    .userStories
    | map(select(.passes == false and (.status // "not_started") != "in_progress"))
    | sort_by(.priority)
    | .[0]
  ' prd.json)

  # Check if any ticket found
  if [[ "$ticket_json" == "null" || -z "$ticket_json" ]]; then
    echo "No incomplete tickets found in prd.json"
    echo "All user stories are marked as passing!"
    return 0
  fi

  # Extract ticket details
  local task_id=$(echo "$ticket_json" | jq -r '.id')
  local title=$(echo "$ticket_json" | jq -r '.title')
  local description=$(echo "$ticket_json" | jq -r '.description')
  local criteria=$(echo "$ticket_json" | jq -r '.acceptanceCriteria | join("\n- ")')
  local priority=$(echo "$ticket_json" | jq -r '.priority')

  echo "========================================="
  echo "Next Ticket: $task_id (Priority $priority)"
  echo "========================================="
  echo "Title: $title"
  echo ""
  echo "Creating worktree and launching autonomous agent..."
  echo ""

  # Check if we're in a git repo
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    return 1
  fi

  # Get repo root
  local repo_root=$(git rev-parse --show-toplevel)
  local worktree_dir="$repo_root/.worktrees/$task_id"

  # Check if worktree already exists
  if [[ -d "$worktree_dir" ]]; then
    echo "Error: Worktree already exists at $worktree_dir"
    echo "Remove it first with: willie --clean $task_id"
    return 1
  fi

  # Determine base branch
  if [[ -z "$base_branch" ]]; then
    base_branch=$(git branch --show-current)
    if [[ -z "$base_branch" ]]; then
      base_branch="main"
    fi
  fi

  # Create branch name
  local branch_name="$task_id"

  # Check if branch already exists
  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    echo "Error: Branch '$branch_name' already exists"
    echo "Use a different task ID or delete the existing branch first"
    return 1
  fi

  echo "Creating worktree..."
  echo "  Task ID: $task_id"
  echo "  Branch: $branch_name (from $base_branch)"
  echo "  Location: $worktree_dir"
  echo ""

  # Mark ticket as in_progress in prd.json
  jq --arg id "$task_id" '
    .userStories |= map(
      if .id == $id then
        . + {status: "in_progress"}
      else
        .
      end
    )
  ' prd.json > prd.json.tmp && mv prd.json.tmp prd.json

  echo "Marked ticket $task_id as 'in_progress' in prd.json"
  echo ""

  # Create worktree with new branch
  if ! git worktree add -b "$branch_name" "$worktree_dir" "$base_branch"; then
    echo "Error: Failed to create worktree"
    # Revert status change on failure
    jq --arg id "$task_id" '
      .userStories |= map(
        if .id == $id then
          del(.status)
        else
          .
        end
      )
    ' prd.json > prd.json.tmp && mv prd.json.tmp prd.json
    return 1
  fi

  # Create TICKET.md file in worktree with full ticket details
  cat > "$worktree_dir/TICKET.md" <<EOF
# Ticket: $task_id

**Priority:** $priority
**Title:** $title

## Description

$description

## Acceptance Criteria

- $criteria

## Instructions for Autonomous Agent

You are working on this ticket autonomously. Your goals:

1. **Read and understand** all acceptance criteria above
2. **Explore the codebase** to understand the existing implementation
3. **Implement** all required functionality to meet the acceptance criteria
4. **Test** your changes thoroughly (run tests, manual testing, etc.)
5. **Update prd.json** when complete:
   - Set \`"passes": true\` for this ticket ($task_id)
   - Add detailed notes about what was implemented
6. **Commit your changes** with a clear commit message

## Ralph Loop Guidance

Work iteratively:
- Break the task into smaller steps if needed
- Test as you go
- Don't over-engineer - implement exactly what's needed
- Follow existing code patterns in the project
- If you encounter blockers, document them in the notes field

When you've met all acceptance criteria and tested thoroughly, update prd.json and commit your work.

---
*This ticket was generated by Willie's --next command*
EOF

  echo ""
  echo "Worktree created successfully!"
  echo "Ticket details written to TICKET.md"
  echo "Launching Claude Code in autonomous mode..."
  echo ""

  # Change to worktree directory and launch Claude with the ticket
  cd "$worktree_dir" || return 1
  claude "Read TICKET.md and work autonomously on ticket $task_id: $title. Follow the Ralph Loop guidance. When complete, update prd.json to mark this ticket as passing and commit your changes."

  # After Claude exits, return to original directory
  cd - > /dev/null
}

# Show help
_willie_help() {
  cat <<EOF
Groundskeeper Willie - Git Worktree Helper for Claude Code

USAGE:
  willie <task-id> [--from <branch>]    Create worktree and launch Claude
  willie --next [--from <branch>]       Auto-launch highest priority ticket from prd.json
  willie --status                        List all worktrees
  willie --clean <task-id>               Remove worktree
  willie --help                          Show this help

OPTIONS:
  --from <branch>    Create branch from specified base branch

EXAMPLES:
  willie PCT-522                Create worktree for task PCT-522
  willie hotfix --from main     Create worktree from main branch
  willie --next                 Launch next incomplete ticket from prd.json
  willie --status               List all active worktrees
  willie --clean PCT-522        Remove worktree for PCT-522
  willie --clean --all          Remove all worktrees

WORKFLOW:
  1. willie PCT-522             # Create worktree and launch Claude
  2. [Work in Claude session]   # Make changes in .worktrees/PCT-522/
  3. [Exit Claude]              # Return to main workspace
  4. willie --clean PCT-522     # Clean up when done

RALPH LOOP WORKFLOW (AUTONOMOUS):
  1. willie --next              # Auto-launch highest priority incomplete ticket
  2. [Claude works autonomously] # Agent reads TICKET.md and implements changes
  3. [Claude updates prd.json]  # Marks ticket as complete when done
  4. [Exit Claude]              # Return to main workspace

NOTES:
  - Worktrees are stored in .worktrees/ (add to .gitignore)
  - Each worktree gets its own branch named after the task ID
  - Multiple Claude sessions can work in different worktrees simultaneously
  - Branches are NOT auto-deleted (manual cleanup)
  - --next requires prd.json and jq to be installed
EOF
}
