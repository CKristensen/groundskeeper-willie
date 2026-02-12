#!/bin/bash
# Git Worktree Agent Helper Functions
# Add these to your ~/.bashrc or ~/.zshrc

# Main function: Create worktree and launch agent
agent-worktree() {
  local task_id=""
  local agent="claude"  # default to claude
  local base_branch=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --claude)
        agent="claude"
        shift
        ;;
      --codex)
        agent="codex"
        shift
        ;;
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
    echo "Usage: agent-worktree <task-id> [--claude|--codex] [--from <base-branch>]"
    echo ""
    echo "Examples:"
    echo "  agent-worktree PCT-522"
    echo "  agent-worktree PCT-523 --codex"
    echo "  agent-worktree hotfix-123 --from main"
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
    echo "Remove it first with: agent-worktree-clean $task_id"
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
  echo "  Agent: $agent"
  echo ""

  # Create worktree with new branch
  if ! git worktree add -b "$branch_name" "$worktree_dir" "$base_branch"; then
    echo "Error: Failed to create worktree"
    return 1
  fi

  echo ""
  echo "Worktree created successfully!"
  echo "Launching $agent agent..."
  echo ""

  # Change to worktree directory and launch agent
  cd "$worktree_dir" || return 1

  if [[ "$agent" == "claude" ]]; then
    claude
  elif [[ "$agent" == "codex" ]]; then
    codex
  else
    echo "Error: Unknown agent '$agent'"
    return 1
  fi

  # After agent exits, return to original directory
  cd - > /dev/null
}

# List all worktrees
agent-worktree-list() {
  echo "Git worktrees:"
  git worktree list
}

# Cleanup/remove worktree
agent-worktree-clean() {
  local task_id="$1"

  if [[ -z "$task_id" ]]; then
    echo "Current worktrees:"
    echo ""
    git worktree list
    echo ""
    echo "Usage: agent-worktree-clean <task-id>"
    echo "   or: agent-worktree-clean --all  (remove all worktrees except main)"
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

# Show help
agent-worktree-help() {
  cat <<EOF
Git Worktree Agent Helper Functions

COMMANDS:
  agent-worktree <task-id> [options]
      Create a new worktree and launch an agent

      Options:
        --claude     Use Claude Code (default)
        --codex      Use Codex CLI
        --from <br>  Create branch from specified base branch

      Examples:
        agent-worktree PCT-522
        agent-worktree PCT-523 --codex
        agent-worktree hotfix --from main

  agent-worktree-list
      List all active worktrees

  agent-worktree-clean <task-id>
      Remove a worktree and optionally its branch

      Use --all to remove all worktrees

      Examples:
        agent-worktree-clean PCT-522
        agent-worktree-clean --all

  agent-worktree-help
      Show this help message

WORKFLOW:
  1. Run: agent-worktree PCT-522
  2. Work in the agent session (in .worktrees/PCT-522/)
  3. Exit the agent when done
  4. Clean up: agent-worktree-clean PCT-522

NOTES:
  - Worktrees are stored in .worktrees/ (add to .gitignore)
  - Each worktree gets its own branch named after the task ID
  - Multiple agents can work in different worktrees simultaneously
  - Branches are NOT auto-deleted (manual cleanup)
EOF
}
